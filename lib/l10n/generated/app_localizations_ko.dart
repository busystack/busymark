// ignore_for_file: text_direction_code_point_in_literal, text_direction_code_point_in_comment

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get notesNewFromRetainedText => '보관된 텍스트로 새 노트 만들기';

  @override
  String get notesAccountThrottled =>
      'Nextcloud가 일시 중지를 요청했습니다. 기다린 뒤 다시 로그인하세요.';

  @override
  String get notesSettingsRefreshing => '확인된 설정 변경 후 Notes 새로 고치는 중';

  @override
  String get notesExportOperationFailed =>
      '게시 전에 내보내기가 실패했습니다. 원본과 대상을 확인하고 다시 내보내세요.';

  @override
  String get notesRecoveryCreatedNotOpened =>
      '복구한 노트는 저장되었지만 열지 못했습니다. 보류 중인 편집 또는 속성 변경을 해결한 뒤 이 기존 노트를 여세요.';

  @override
  String get notesSettingsPendingNotes =>
      '보류 중인 노트, 충돌 또는 생성 결과가 불확실한 노트가 변경을 막고 있습니다. Notes에서 동기화하거나 검토한 뒤 보존된 설정 초안을 다시 저장하세요.';

  @override
  String get notesSettingsPendingAttachments =>
      '보류 중인 첨부 작업이 변경을 막고 있습니다. Notes에서 첨부를 검토한 뒤 보존된 설정 초안을 다시 저장하세요.';

  @override
  String get notesAccountServerAddress =>
      'Nextcloud의 정식 HTTPS 주소로 다시 로그인하세요. 주소 또는 리디렉션을 확인할 수 없었습니다.';

  @override
  String get notesAccountUnsupported =>
      'Notes를 사용할 수 없거나 API가 지원되지 않습니다. 주 버전 1, 부 버전 4 이상의 API를 제공하는 Nextcloud Notes를 활성화하세요.';

  @override
  String get notesAccountAuthorizeAgain =>
      'Nextcloud가 인증 정보를 거부했습니다. 계정을 다시 인증하거나 연결하세요.';

  @override
  String get notesAccountCheckForbidden =>
      'Nextcloud가 Notes 기능 확인을 거부했습니다. 관리자에게 허용을 요청한 뒤 다시 시도하세요.';

  @override
  String get notesAccountMalformed =>
      'Nextcloud 응답을 검증할 수 없었습니다. 서버 설치를 확인하고 다시 로그인하세요.';

  @override
  String get notesAccountTimedOut =>
      '로그인 시간이 초과되었습니다. 다시 시작하고 브라우저에서 인증을 완료하세요.';

  @override
  String get notesAccountBrowserUnavailable =>
      '시스템 브라우저를 열지 못했습니다. 기본 브라우저를 확인하고 다시 로그인하세요.';

  @override
  String get notesAccountNetwork =>
      'Nextcloud에 연결하지 못했습니다. 연결과 서버를 확인하고 다시 로그인하세요.';

  @override
  String get notesAccountRejected =>
      'Nextcloud가 기능 요청을 거부했습니다. 관리자와 접근 권한을 확인하고 다시 시도하세요.';

  @override
  String get notesAccountFailed => '계정 설정을 완료하지 못했습니다. 다시 로그인하세요.';

  @override
  String get notesTransferSourceChanged =>
      '검토 후 원본이 변경되었습니다. 현재 파일을 다시 검토하거나 새 스냅샷을 만든 뒤 재시도하세요.';

  @override
  String get notesTransferUnreadable =>
      '원본을 읽을 수 없습니다. 파일 또는 폴더 접근 권한을 확인하고 다시 검토하세요.';

  @override
  String get notesTransferInvalidSnapshot =>
      '스냅샷이 올바르지 않거나 지원되지 않습니다. 유효한 BusyMark Notes 스냅샷 또는 Markdown 원본을 선택하세요.';

  @override
  String get notesTransferMediaLimit =>
      '미디어가 가져오기 크기 제한을 초과합니다. 해당 항목의 미디어를 줄이고 다시 검토하세요.';

  @override
  String get notesTransferUnsafeSource =>
      '원본에 안전하지 않은 경로가 있습니다. 원본 폴더 안의 파일을 선택하고 다시 검토하세요.';

  @override
  String get notesTransferDestination =>
      '내보내기를 기록하지 못했습니다. 대상의 접근 권한과 여유 공간을 확인하고 다시 내보내세요.';

  @override
  String get notesTransferOperationFailed =>
      '전송을 완료하지 못했습니다. 해당 항목을 검토하고 다시 시도하세요. 이전에 가져온 항목은 저장되어 있습니다.';

  @override
  String get notesExportPublishedWithOmissions => '누락된 항목이 있는 내보내기 사용 가능';

  @override
  String get notesBatchUnchanged => '요청한 값이 이미 설정되어 있습니다.';

  @override
  String get notesBatchReadOnly =>
      '이 노트는 읽기 전용입니다. 보호된 속성은 바꿀 수 없지만 즐겨찾기는 변경할 수 있습니다.';

  @override
  String get notesBatchReviewChanged =>
      '검토 후 노트가 변경되었습니다. 현재 상태를 검토한 뒤 작업을 다시 적용하세요.';

  @override
  String get notesBatchMissing =>
      '이 노트를 더 이상 사용할 수 없습니다. 목록을 새로 고치고 대상을 다시 검토하세요.';

  @override
  String get notesBatchStorage =>
      '로컬 저장에 실패했습니다. 저장소를 확인하고 이 항목을 다시 시도하세요. 성공한 항목은 저장되어 있습니다.';

  @override
  String get notesRemoteReviewChanged =>
      '서버 노트가 변경되었습니다. 병합 초안은 보존됩니다. 새 비교를 검토하고 해결 방법을 다시 선택하세요.';

  @override
  String get notesReviewRemote => '현재 서버 버전을 검토했습니다';

  @override
  String get wsModuleCapsNotPublished => '모듈의 대소문자 설정은 게시되지 않습니다.';

  @override
  String get wsTitleOverridesAction => '인스턴스 및 목차 제목…';

  @override
  String get wsHeadingNotPublished => '이 빌더에서는 게시되지 않습니다.';

  @override
  String get wsMarkdownInstanceTitleLimitation =>
      '고정된 빌더는 Markdown 주제의 인스턴스 제목을 게시하지 않습니다. 기존 마크업은 보존됩니다. 소스에서 확인하세요.';

  @override
  String get wsTopicIdentity => '주제 ID';

  @override
  String get wsElementAnchor => '요소 앵커';

  @override
  String get wsHeadingText => '제목 텍스트';

  @override
  String get wsDefaultTitle => '기본 제목';

  @override
  String get wsTopicNavigation => '주제 탐색';

  @override
  String get wsHeadingOptions => '제목 속성';

  @override
  String get wsDocumentOptions => '문서 설정';

  @override
  String get wsSettingsPresent => '작성된 설정 있음';

  @override
  String get wsTitleOverrideExplanation => '게시 제목을 재정의하며 제목 텍스트는 변경하지 않습니다.';

  @override
  String get wsIgnoreVariables => '변수를 리터럴 텍스트로 처리';

  @override
  String get wsIgnoreVariablesExplanation => '활성화하면 변수처럼 보이는 텍스트를 치환하지 않습니다.';

  @override
  String get wsInstanceSelection => '도움말 인스턴스';

  @override
  String get wsInstanceExplanation => '이름, 그룹, 목록, 제외 또는 식으로 도움말 출력을 선택합니다.';

  @override
  String get wsFilterExplanation =>
      '조건에 따라 재사용 콘텐츠를 필터링하며 도움말 인스턴스를 선택하지 않습니다.';

  @override
  String get wsContextHelp => '상황별 도움말 ID';

  @override
  String get wsCapitalization => '대소문자';

  @override
  String get wsLibraryTopic => '라이브러리 주제';

  @override
  String get wsLastModified => '최종 수정';

  @override
  String get wsMissingTopicHeading => '주제 H1이 없습니다. 소스에서 추가하세요.';

  @override
  String get wsMultipleTopicHeadings => '첫 H1이 주제 제목을 결정합니다. 이후 H1은 별도 제목입니다.';

  @override
  String get wsTopicIdentityMismatch =>
      '루트 id가 파일명 기반 주제 ID와 다릅니다. 주제 파일 이름 바꾸기 또는 소스를 사용하세요.';

  @override
  String get wsUnsupportedProperties => '지원하지 않는 속성은 보존됩니다. 소스에서 확인하세요.';

  @override
  String get wsGeneratedAnchor => '생성된 앵커이며 값을 입력하면 재정의됩니다.';

  @override
  String get wsHeadingBuilderLimitation =>
      '고정된 빌더는 H1 속성을 게시하지 않습니다. 속성은 XML 루트가 아닌 제목에 속합니다.';

  @override
  String get closeOtherTabs => '다른 탭 닫기';

  @override
  String get tocTopicFromTemplate => '템플릿에서 토픽...';

  @override
  String get tocSaveAsTemplate => '템플릿으로 저장';

  @override
  String get tocTemplateDialog => '템플릿에서 토픽 만들기';

  @override
  String get tocTemplatesEditor => '파일 및 코드 템플릿';

  @override
  String get tocEditTemplates => '템플릿 편집...';

  @override
  String get tocCreateCustomTemplate => '사용자 지정 템플릿 만들기...';

  @override
  String get tocTemplateCreated => '템플릿 생성됨';

  @override
  String get tocTemplateDefault => '기본';

  @override
  String get tocTemplateCustom => '사용자 지정';

  @override
  String get tocTemplateFilename => '파일 이름:';

  @override
  String get tocTemplateMarkdown => 'Markdown (.md)';

  @override
  String get tocTemplateXml => 'XML (.topic)';

  @override
  String get tocTemplatesInternal => '내부';

  @override
  String get tocTemplateUnnamed => '이름 없음';

  @override
  String get tocTemplateNew => '새 템플릿...';

  @override
  String get tocTemplateName => '이름:';

  @override
  String get tocTemplateExtension => '확장자:';

  @override
  String get tocTemplateLoadError => '템플릿을 불러올 수 없습니다. 기존 템플릿은 변경되지 않았습니다.';

  @override
  String get tocTemplateSaveError => '템플릿을 저장할 수 없습니다. 편집 내용은 여기에 유지됩니다.';

  @override
  String get tocTemplateConflict => '다른 창에서 템플릿이 변경되었습니다. 취소하고 편집기를 다시 여세요.';

  @override
  String get tocTemplateDuplicateName => '이 이름과 확장자를 가진 템플릿이 이미 있습니다.';

  @override
  String get tocTemplateFormat => '형식:';

  @override
  String get tocTemplateReset => '초기화';

  @override
  String get tocTemplateRetry => '다시 시도';

  @override
  String tocRemoveElementsDialog(int count) {
    return '목차 요소 $count개 제거';
  }

  @override
  String get tocRemoveElementsRetainFiles => '이 목차 요소와 연결된 소스 파일은 삭제되지 않습니다.';

  @override
  String get tocOk => '확인';

  @override
  String get tocSelectExistingTopic => '현재 인스턴스에 추가할 토픽 선택';

  @override
  String get tocGroupName => '그룹 이름';

  @override
  String get tocMoveLineUp => '줄 위로 이동';

  @override
  String get tocMoveLineDown => '줄 아래로 이동';

  @override
  String get tocEmptyMdTopic => '빈 MD 토픽';

  @override
  String get tocEmptyXmlTopic => '빈 XML 토픽';

  @override
  String get tocCopySpecial => '특수 복사';

  @override
  String tocCopyFileName(String name) {
    return '토픽 파일 이름 \'$name\'';
  }

  @override
  String get tocCopyFilePath => '토픽 파일 경로';

  @override
  String tocCopyTopicTitle(String title) {
    return '토픽 제목 \'$title\'';
  }

  @override
  String tocCopyElementId(String id) {
    return '목차 요소 ID \'$id\'';
  }

  @override
  String get tocCopyFileNameUnavailable => '토픽 파일 이름';

  @override
  String get tocCopyTopicTitleUnavailable => '토픽 제목';

  @override
  String get tocCopyElementIdUnavailable => '목차 요소 ID';

  @override
  String get tocEditTitleAction => '제목 편집...';

  @override
  String get tocEditTitleDialog => '제목 편집';

  @override
  String get tocRemoveElementAction => '목차 요소 제거...';

  @override
  String get tocSetHomePage => '홈 페이지로 설정';

  @override
  String tocGoToElement(String fileName) {
    return '\'$fileName\'의 목차 요소로 이동';
  }

  @override
  String get tocSynchronize => '목차와 편집기 동기화';

  @override
  String get tocEmptyGroupAction => '빈 그룹';

  @override
  String get tocNewEmptyGroup => '새 빈 그룹';

  @override
  String get tocGroupAction => '그룹화';

  @override
  String get tocNewGroup => '새 그룹';

  @override
  String get tocSortChildren => '하위 토픽을 알파벳순으로 정렬';

  @override
  String get tocLinkTopicFiles => '토픽 파일을 목차에 연결...';

  @override
  String get addLocalMarkdownFiles => '로컬 Markdown 파일 추가';

  @override
  String get tocTitleField => '목차 제목:';

  @override
  String get tocTopicTitleField => '토픽 제목:';

  @override
  String get tocAdvancedSettings => '고급 설정';

  @override
  String tocInstanceTitleField(String instanceId) {
    return '\'$instanceId\'의 제목:';
  }

  @override
  String get tocOnlyTitleField => '목차 전용 제목:';

  @override
  String get tocInstanceTitleExplanation =>
      '현재 인스턴스에만 사용됩니다. 기본적으로 토픽 제목을 상속합니다.';

  @override
  String get tocOnlyTitleExplanation =>
      '목차에만 사용됩니다. 기본적으로 토픽 제목 또는 설정된 인스턴스별 제목을 상속합니다. 제목에 대한 설명:';

  @override
  String get tocTitleDocumentationLink => '여기';

  @override
  String get tocFindUsages => '찾기';

  @override
  String get tocRefactorMenu => '리팩터링';

  @override
  String get tocSafeDelete => '안전하게 삭제';

  @override
  String get tocDuplicate => '복제';

  @override
  String get tocDuplicateFilename => '토픽 파일 이름:';

  @override
  String get tocDuplicateDialog => '토픽 복제';

  @override
  String get pdfTitlePage => '제목 페이지';

  @override
  String get pdfIncludeTitlePage => '제목 페이지 포함';

  @override
  String get pdfTitlePageNote => '이 페이지에는 머리글, 바닥글 또는 페이지 번호가 표시되지 않습니다.';

  @override
  String get pdfTitlePageTitle => '제목';

  @override
  String get pdfTitlePageSubtitle => '부제';

  @override
  String get pdfTitlePageAuthor => '작성자';

  @override
  String get pdfTitlePageOrganization => '조직';

  @override
  String get pdfTitlePageVersion => '버전';

  @override
  String get pdfTitlePageDate => '날짜';

  @override
  String get pdfTitlePageTitleRequired => '제목 페이지의 제목을 입력하세요.';

  @override
  String get pdfTocSectionNote => '별도 페이지에서 시작하며 여러 페이지에 걸칠 수 있습니다.';

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
  String get copyPlainText => '일반 텍스트로 복사';

  @override
  String get clipboardCopyFailed => '선택한 내용을 클립보드에 복사할 수 없습니다.';

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
  String get shortcutKeyboardShortcutsDescription => '애플리케이션 키보드 단축키 사용자 지정';

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
  String get wordWrapDescription => '긴 줄을 가로로 스크롤하지 않고 편집기 너비에 맞게 줄 바꿈합니다.';

  @override
  String get editorFontSize => '편집기 글꼴 크기';

  @override
  String get validateOnEdit => '편집할 때 검증';

  @override
  String get clearRecentWorkspaces => '최근 기록 지우기';

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
  String get settingsEditingButtonsSectionTitle => '편집 버튼';

  @override
  String get spellingDictionaries => '맞춤법 검사 사전';

  @override
  String get spellingDictionariesDescription => '맞춤법 검사 사전 설치 및 관리';

  @override
  String get settingsDictionariesSectionTitle => '사전';

  @override
  String get availableSpellingDictionaries => '사용 가능한 사전';

  @override
  String get customSpellingDictionaries => '사용자 지정 사전';

  @override
  String get spellingDictionaryProblems => '사전 문제';

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
  String get insertBlankLine => '빈 줄 삽입';

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
  String get newSiblingTopic => '새 토픽';

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
  String get removeTocElements => 'TOC 요소 제거';

  @override
  String get reviewUsages => '사용 검토';

  @override
  String get deleteTopicFile => '토픽 파일 삭제';

  @override
  String get removeAction => '제거';

  @override
  String topicRemovalSummary(String topic) {
    return '목차 요소 “$topic”을(를) 제거하시겠습니까? 목차에 연결된 소스 파일은 삭제되지 않습니다.';
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
  String get topicIsHomePageRemovalWarning =>
      '이 토픽은 이 인스턴스의 홈 페이지입니다. 목차에서 제거하기 전에 다른 홈 페이지를 선택하세요.';

  @override
  String get newHomePage => '새 홈 페이지';

  @override
  String get chooseHomePage => '홈 페이지 선택';

  @override
  String get noHomePageReplacement =>
      '홈 페이지를 제거하기 전에 이 인스턴스에 다른 적합한 토픽을 추가하거나 연결하세요.';

  @override
  String get topicIsStartPageRemovalWarning =>
      '이 토픽은 인스턴스의 홈 페이지입니다. 소스 파일을 삭제하기 전에 다른 홈 페이지를 지정하세요.';

  @override
  String topicUsagesCount(int count) {
    return '사용처 $count개를 찾았습니다.';
  }

  @override
  String get noBreakingTopicUsages => '깨질 수 있는 참조가 발견되지 않았습니다.';

  @override
  String get topicUsagesFound => 'BusyMark에서 이 토픽에 대한 다음 참조를 찾았습니다.';

  @override
  String get topicUsageTocElements => '목차 요소';

  @override
  String get topicUsageStartPages => '홈 페이지';

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
  String get setRedirectTo => '다음으로 리디렉션 설정:';

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
  String get preview => '미리 보기';

  @override
  String get topicRenamePreviewTitle => '이름 바꾸기 미리 보기';

  @override
  String topicRenamePathChange(String oldPath, String newPath) {
    return '경로: $oldPath → $newPath';
  }

  @override
  String topicRenameIdChange(String oldId, String newId) {
    return '토픽 ID: $oldId → $newId';
  }

  @override
  String topicRenameUrlChange(String instance, String oldName, String newName) {
    return '인스턴스 $instance: $oldName → $newName';
  }

  @override
  String get topicRenameAffectedFiles => '영향을 받는 파일';

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
  String get workspaceSearchIncomplete => '일부 결과만 표시됩니다. 더 표시하거나 검색 범위를 좁히세요.';

  @override
  String get workspaceSearchShowMore => '결과 더 보기';

  @override
  String get workspaceSearchSkippedFiles =>
      '검색이 완료되지 않았습니다. 다음 파일은 1 MiB를 초과하거나 읽을 수 없습니다:';

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
  String workspaceErrorRecentWorkspaceUpdateFailed(String error) {
    return '최근 항목을 업데이트하지 못했습니다: $error.';
  }

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
    return '홈 페이지 $topic을(를) 삭제할 수 없습니다. 먼저 다른 홈 페이지를 선택하세요.';
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
  String errorWritersideTopicRenameIncompleteProjectIndex(
    String module,
    String count,
    String paths,
  ) {
    return '모듈 $module의 토픽 파일 $count개가 구문 분석되지 않아 이름 바꾸기로 모든 프로젝트 참조를 안전하게 업데이트할 수 없습니다: $paths';
  }

  @override
  String get errorWritersideTopicRenameProjectBuffersDirty =>
      'Writerside 프로젝트 파일에 저장되지 않은 변경 사항이 있습니다. 이를 해결하고 새 이름 바꾸기 미리보기를 준비하세요.';

  @override
  String get errorWritersideTopicRenameProjectInventoryChanged =>
      'Writerside 프로젝트의 모듈 집합이 변경되었습니다. 리팩터링하기 전에 새 이름 바꾸기 미리보기를 준비하세요.';

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
  String diagnosticWritersideWebFileNameInvalid(
    String instanceId,
    String webFileName,
    String topic,
  ) {
    return '인스턴스 \"$instanceId\"에서 토픽 \"$topic\"의 웹 파일 이름 \"$webFileName\"이 올바르지 않습니다.';
  }

  @override
  String diagnosticWritersideWebFileNameCollision(
    String instanceId,
    String webFileName,
    String firstTopic,
    String secondTopic,
  ) {
    return '인스턴스 \"$instanceId\"에서 \"$firstTopic\"과 \"$secondTopic\"이 모두 \"$webFileName\"으로 게시됩니다.';
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
  String get exportFormat => '출력 형식';

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
  String get aiDraftCommitMessage => '커밋 메시지 초안 작성';

  @override
  String get aiDrafting => '작성 중…';

  @override
  String get aiDraftWithAi => 'AI를 활용한 초안';

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

  @override
  String get goToDeclaration => '선언으로 이동';

  @override
  String get findUsages => '사용 위치 찾기';

  @override
  String get cannotRenameSymbol =>
      '기호 이름을 안전하게 바꿀 수 없습니다. 이름을 확인하고 참조를 새로 고친 후 다시 시도하세요.';

  @override
  String get renameTopicFileInstead =>
      '토픽 ID는 파일 이름에서 생성됩니다. 목차 또는 파일 사이드바에서 토픽 파일 이름 바꾸기를 사용하세요.';

  @override
  String get keyboardLayout => '키보드 배열';

  @override
  String get diagnosticWritersideUnsupported =>
      '지원하지 않거나 잘못된 형식의 내용은 소스로 표시됩니다.';

  @override
  String diagnosticWritersideSource(String reference, String reason) {
    return '소스 “$reference”를 확인할 수 없습니다: $reason';
  }

  @override
  String diagnosticWritersideLink(String destination) {
    return '이 인스턴스에서 링크 대상을 사용할 수 없습니다: $destination';
  }

  @override
  String diagnosticWritersideSchema(
    String element,
    String attribute,
    String reason,
  ) {
    return '잘못된 Writerside 마크업: $element, $attribute. $reason';
  }

  @override
  String get diagnosticWritersideLlmsTxt =>
      '<llms-txt>true</llms-txt> 또는 <llms-txt>false</llms-txt>를 사용하세요. single-file은 더 이상 지원되지 않습니다.';

  @override
  String diagnosticWritersideReference(String kind, String reference) {
    return '$kind을(를) 확인할 수 없습니다: $reference';
  }

  @override
  String get exportAsHtml => 'HTML로 내보내기…';

  @override
  String get fileTypeHtml => 'HTML 문서';

  @override
  String get exportingHtml => 'HTML 내보내는 중…';

  @override
  String get htmlExported => 'HTML 내보내기 완료';

  @override
  String get htmlExportFailed => 'HTML 내보내기 실패';

  @override
  String get htmlKeepAssetsTogether =>
      '내보낸 결과를 복사할 때 HTML 파일과 관련 리소스 폴더를 함께 유지하세요.';

  @override
  String get htmlInstanceDescription =>
      '인스턴스 하나를 연결된 오프라인 페이지로 내보냅니다. 전용 출력 폴더의 이름을 선택하세요.';

  @override
  String get htmlInstance => '인스턴스';

  @override
  String get htmlOwnedDirectoryOnly =>
      'BusyMark HTML 내보내기로 만든 폴더만 교체할 수 있습니다. 수정되거나 관련 없는 파일은 보존됩니다.';

  @override
  String get showInFolder => '폴더에서 보기';

  @override
  String sortTableColumn(String column) {
    return '$column 정렬';
  }

  @override
  String get exportReset => '기본값으로 재설정';

  @override
  String get exportToc => '목차 포함';

  @override
  String get exportTocDepth => '목차 깊이';

  @override
  String get exportNumberHeadings => '제목 번호 매기기';

  @override
  String get exportLegal => 'US Legal';

  @override
  String get exportCustom => '사용자 지정';

  @override
  String get exportPageWidth => '페이지 너비 (mm)';

  @override
  String get exportPageHeight => '페이지 높이 (mm)';

  @override
  String get exportMarginTop => '위쪽 여백 (mm)';

  @override
  String get exportMarginRight => '오른쪽 여백 (mm)';

  @override
  String get exportMarginBottom => '아래쪽 여백 (mm)';

  @override
  String get exportMarginLeft => '왼쪽 여백 (mm)';

  @override
  String get exportTypography => '글꼴';

  @override
  String get exportSans => '고딕체';

  @override
  String get exportSerif => '명조체';

  @override
  String get exportBodySize => '본문 글꼴 크기';

  @override
  String get exportCodeSize => '코드 글꼴 크기';

  @override
  String get exportRunningText => '머리글 및 바닥글';

  @override
  String get exportHeader => '머리글';

  @override
  String get exportFooter => '바닥글';

  @override
  String get exportNone => '없음';

  @override
  String get exportDocumentTitle => '문서 제목';

  @override
  String get exportBottomLeft => '왼쪽 아래';

  @override
  String get exportBottomCenter => '가운데 아래';

  @override
  String get exportBottomRight => '오른쪽 아래';

  @override
  String get exportFirstPage => '첫 페이지에 머리글과 바닥글 표시';

  @override
  String get exportAccent => '강조 / 링크 색상';

  @override
  String get exportTheme => '테마';

  @override
  String get exportAutomatic => '자동';

  @override
  String get exportLayout => '레이아웃';

  @override
  String get exportContentWidth => '최대 콘텐츠 너비';

  @override
  String get exportOutput => '출력';

  @override
  String get exportPackaging => '패키징';

  @override
  String get exportSingleFile => '단일 HTML 파일';

  @override
  String get exportAssetsDirectory => 'HTML + 리소스 폴더';

  @override
  String get exportCustomCss => '사용자 지정 스타일시트…';

  @override
  String get exportRemoveCss => '사용자 지정 스타일시트 제거';

  @override
  String get exportCssNote =>
      '선택적으로 UTF-8 CSS 파일을 지정하세요(최대 256 KiB). 가져오기, 리소스 URL, 실행 가능하거나 이스케이프된 CSS는 허용되지 않습니다. BusyMark 스타일 뒤에 적용됩니다. 원격 리소스를 가져오지 않습니다.';

  @override
  String get exportSitePackagingNote =>
      'Writerside는 별도로 연결된 주제 페이지를 유지합니다. 단일 파일 모드는 각 페이지에 리소스를 포함합니다.';

  @override
  String get exportInvalidGeometry => '여백을 제외한 콘텐츠 너비와 높이를 각각 20 mm 이상 확보하세요.';

  @override
  String get exportInvalidColor => '#RRGGBB 형식으로 색상을 입력하세요.';

  @override
  String get exportInvalidCss =>
      '가져오기, 리소스 URL, HTML, 실행 가능하거나 이스케이프된 CSS가 없는 읽기 가능한 UTF-8 .css 파일(최대 256 KiB)을 선택하세요.';

  @override
  String get clipboardHistory => '클립보드 기록';

  @override
  String get clipboardHistoryDescription => '세션별 클립보드 기록을 엽니다.';

  @override
  String get clipboardCurrent => '현재 클립보드';

  @override
  String get clipboardCurrentExternal => '다른 애플리케이션의 현재 클립보드';

  @override
  String clipboardDestination(String name) {
    return '$name에 붙여넣기';
  }

  @override
  String get clipboardSessionOnly => '이 BusyMark 세션에만 저장됩니다.';

  @override
  String get clipboardNoItems => '클립보드 기록이 비어 있습니다.';

  @override
  String get clipboardDisabled => '클립보드 기록 컬렉션이 설정에서 비활성화되었습니다.';

  @override
  String get clipboardUnavailable => '현재 클립보드 내용은 사용할 수 없거나 지원되지 않습니다.';

  @override
  String get clipboardTooLarge => '이 클립보드 항목은 저장할 수 없을 정도로 큽니다.';

  @override
  String get clipboardPastePlainText => '일반 텍스트로 붙여넣기';

  @override
  String get clipboardClearAll => '클립보드 기록 지우기';

  @override
  String get clipboardEntryText => '텍스트';

  @override
  String get clipboardEntryRichText => '풍부한 텍스트';

  @override
  String get clipboardEntryImage => '이미지';

  @override
  String clipboardOrigin(String name) {
    return '$name에서 복사됨';
  }

  @override
  String get localHistory => '로컬 기록';

  @override
  String get localHistoryEllipsis => '로컬 기록…';

  @override
  String get localHistoryDescription => '현재 문서에 저장된 자동 로컬 변경 사항을 표시합니다.';

  @override
  String get findLocalHistoryEllipsis => '로컬 히스토리에서 찾기…';

  @override
  String get findLocalHistoryDescription => '로컬 히스토리 문서 및 수정 내용 검색.';

  @override
  String get localHistoryNoDocuments => '아직 로컬 히스토리가 있는 문서는 없습니다.';

  @override
  String get localHistoryNoRevisions => '이 문서는 로컬 히스토리 수정 사항이 없습니다.';

  @override
  String get localHistorySelectedRevision => '선택된 수정';

  @override
  String get localHistoryCurrentEditor => '현재 편집 내용';

  @override
  String get localHistoryCurrentDisk => '디스크에 있는 현재 내용';

  @override
  String get localHistoryMissingFile => '원본 파일이 없습니다.';

  @override
  String get localHistoryRestoreRevision => '이전 버전 복원';

  @override
  String get localHistoryRestoreOriginalLocation => '원래 위치로 복원';

  @override
  String get localHistoryRestoreNewLocation => '새로운 위치로 복원…';

  @override
  String get localHistoryRestoreChange => '변경 사항 복원';

  @override
  String get localHistoryRestoreUnavailable => '이 변경 사항은 더 이상 비교가 불가능합니다.';

  @override
  String get localHistoryComparisonSimplified =>
      '이 큰 비교는 단순화되었습니다. 개별 변경 사항 복원은 불가능합니다.';

  @override
  String localHistoryOlderChange(String text) {
    return '이전 버전의 변경: $text';
  }

  @override
  String localHistoryCurrentChange(String text) {
    return '현재 콘텐츠의 변경: $text';
  }

  @override
  String get localHistoryDeleted => '삭제됨';

  @override
  String get localHistoryUntitled => '제목 없음';

  @override
  String get localHistoryClearDocument => '이 문서의 기록 삭제';

  @override
  String get localHistoryClearAll => '모든 로컬 기록 삭제';

  @override
  String get localHistoryClearDocumentTitle => '문서 기록 삭제?';

  @override
  String get localHistoryClearAllTitle => '모든 로컬 기록 삭제?';

  @override
  String get localHistoryClearConfirmation =>
      '이로 인해 저장된 버전이 영구적으로 삭제됩니다. 이 작업은 취소할 수 없습니다.';

  @override
  String get localHistoryWarningIndexRebuilt =>
      '로컬 기록 인덱스가 손상되어 정상적인 버전에서 재구성되었습니다.';

  @override
  String localHistoryWarningUnsupportedFormat(String version) {
    return '이 로컬 기록 저장소는 지원되지 않는 형식 $version을 사용합니다.';
  }

  @override
  String localHistoryWarningUnavailable(String detail) {
    return '로컬 기록은 사용할 수 없습니다: $detail';
  }

  @override
  String get localHistoryWarningRecordingDisabled =>
      '녹음이 비활성화되었거나 이 경로가 제외되었습니다. 복원하기 전에 녹음을 다시 활성화하십시오.';

  @override
  String localHistoryWarningPathChange(String detail) {
    return '로컬 기록이 경로 변경을 기록할 수 없습니다: $detail';
  }

  @override
  String localHistoryWarningDeletedPath(String detail) {
    return '로컬 히스토리에서 삭제된 경로를 저장할 수 없습니다: $detail';
  }

  @override
  String get localHistoryWarningRevisionMissing => '선택된 버전이 누락되었거나 손상되었습니다.';

  @override
  String localHistoryWarningRevisionRead(String detail) {
    return '선택된 버전을 읽을 수 없습니다: $detail';
  }

  @override
  String localHistoryWarningCapture(String detail) {
    return '로컬 히스토리가 이 버전을 캡처할 수 없습니다: $detail';
  }

  @override
  String localHistoryRevisionAt(String reason, String timestamp) {
    return '$reason – $timestamp';
  }

  @override
  String get localHistoryReasonBaseline => '기본 버전';

  @override
  String get localHistoryReasonSaved => '저장됨';

  @override
  String get localHistoryReasonAutomaticCheckpoint => '자동 체크포인트';

  @override
  String get localHistoryReasonBeforeReload => '재로드 전';

  @override
  String get localHistoryReasonBeforeDiscard => '버리기 전';

  @override
  String get localHistoryReasonBeforeRestore => '복원 전';

  @override
  String get localHistoryReasonBeforeDelete => '삭제 전';

  @override
  String get localHistoryReasonExternalChange => '외부 변경';

  @override
  String get settingsHistory => '버전 기록';

  @override
  String get settingsClipboardHistoryTitle => '클립보드 기록 수집';

  @override
  String get settingsClipboardHistoryDescription =>
      '이 BusyMark 세션에만 복사 및 성공적으로 붙여넣은 콘텐츠를 유지합니다.';

  @override
  String get settingsLocalHistoryTitle => '로컬 버전 기록';

  @override
  String get settingsLocalHistoryDescription =>
      '복구 및 비교를 위해 이 장치에 문서 버전을 저장합니다.';

  @override
  String get settingsHistoryCheckpoint => '자동 체크포인트 간격';

  @override
  String get settingsHistoryRetention => '보관 기간';

  @override
  String get settingsHistoryStorage => '최대 저장 공간';

  @override
  String get settingsHistoryExcludedPaths => '제외된 경로';

  @override
  String get settingsHistoryExcludedPathsHint => '한 줄에 하나의 절대 경로';

  @override
  String settingsSecondsValue(int value) {
    return '$value 초';
  }

  @override
  String settingsDaysValue(int value) {
    return '$value 일';
  }

  @override
  String settingsMebibytesValue(int value) {
    return '$value MiB';
  }

  @override
  String get spelling => '맞춤법';

  @override
  String get automaticSpelling => '자동 맞춤법 검사';

  @override
  String get defaultSpellingLanguage => '기본 맞춤법 언어';

  @override
  String get projectSpellingLanguage => '프로젝트 맞춤법 검사 언어';

  @override
  String get chooseSpellingLanguage => '맞춤법 언어 선택';

  @override
  String get spellingLanguageUnsetStatus => '언어…';

  @override
  String get spellingOffStatus => '맞춤법 검사 끄기';

  @override
  String get checkSpelling => '맞춤법 검사';

  @override
  String get ignoreSpellingOnce => '한 번 무시';

  @override
  String get ignoreSpellingDocument => '이 문서에서 모두 무시';

  @override
  String get addPersonalSpellingWord => '개인 사전에 추가';

  @override
  String get addProjectSpellingWord => '프로젝트 사전에 추가';

  @override
  String get inheritSpellingLanguage => '프로젝트 또는 앱 언어 사용';

  @override
  String get disableDocumentSpelling => '맞춤법 검사 안 함';

  @override
  String get importSpellingDictionary => '사전 가져오기';

  @override
  String get personalSpellingDictionary => '개인 사전';

  @override
  String get projectSpellingDictionary => '프로젝트 사전';

  @override
  String get noSpellingErrors => '맞춤법 오류가 없습니다';

  @override
  String get noSpellingSuggestions => '맞춤법 제안이 없습니다';

  @override
  String get spellingWordCheckFailed => '이 단어를 확인할 수 없습니다';

  @override
  String get spellingCheckFailed => '맞춤법 검사에 실패했습니다';

  @override
  String get spellingSettingsLoadFailed => '맞춤법 검사 설정을 불러올 수 없습니다';

  @override
  String get retrySpellingSettings => '맞춤법 검사 설정 다시 불러오기';

  @override
  String get spellingCheckIncomplete => '맞춤법 검사가 완료되지 않았습니다';

  @override
  String get spellingDictionaryNotInstalled => '사전이 설치되지 않음';

  @override
  String spellingDictionaryNotInstalledForLanguage(String dictionary) {
    return '$dictionary 사전이 설치되지 않았습니다';
  }

  @override
  String spellingDictionaryNotInstalledWithSize(String size) {
    return '설치되지 않음 · $size';
  }

  @override
  String get spellingDictionaryInstalled => '설치됨';

  @override
  String get installSpellingDictionary => '사전 설치';

  @override
  String get removeSpellingDictionary => '사전 제거';

  @override
  String get cancelSpellingDictionaryInstall => '사전 다운로드 취소';

  @override
  String get retrySpellingDictionaryInstall => '사전 설치 다시 시도';

  @override
  String spellingDictionaryDownloading(String size) {
    return '$size 다운로드 중…';
  }

  @override
  String get spellingDictionaryValidating => '사전 검증 중…';

  @override
  String get spellingDictionaryInstallFailed => '사전 설치 실패 — 선택하여 다시 시도';

  @override
  String spellingDictionaryInstallPrompt(String dictionary, String size) {
    return '$dictionary($size)을 설치하시겠습니까? 설치 후 제거할 때까지 오프라인에서 사용할 수 있습니다.';
  }

  @override
  String get spellingDictionaryUnavailable => '사전을 사용할 수 없습니다';

  @override
  String get spellingChecking => '맞춤법 검사 중…';

  @override
  String exportInvalidRange(String field, String minimum, String maximum) {
    return '$field: $minimum에서 $maximum 사이의 숫자를 입력하세요.';
  }

  @override
  String get spellingDictionaryRecoveryConflict =>
      '맞춤법 사전이 외부에서 변경되었습니다. 복구 사본을 보존했습니다.';

  @override
  String get windowMinimize => '최소화';

  @override
  String get windowMaximize => '최대화';

  @override
  String get windowRestore => '복원';

  @override
  String get nextcloudNotes => 'Nextcloud Notes';

  @override
  String get nextcloudConnect => '연결';

  @override
  String get nextcloudReconnect => '다시 연결';

  @override
  String get nextcloudDisconnect => '연결 해제';

  @override
  String get nextcloudServer => '서버 주소';

  @override
  String get nextcloudSignInBrowser => '브라우저에서 로그인을 완료하세요.';

  @override
  String get nextcloudFavorites => '즐겨찾기';

  @override
  String get nextcloudNewNote => '새 노트';

  @override
  String get nextcloudSavedLocally => '로컬에 저장됨 · 동기화 대기';

  @override
  String get nextcloudSyncing => '동기화 중';

  @override
  String get nextcloudSynced => '동기화됨';

  @override
  String get nextcloudOffline => '오프라인';

  @override
  String get nextcloudLocked => '서버에서 잠김';

  @override
  String get nextcloudReconnectRequired => '다시 연결 필요';

  @override
  String get nextcloudCreationUncertain => '생성 결과 불확실';

  @override
  String get nextcloudReadOnly => '읽기 전용';

  @override
  String get nextcloudTakeRemote => '서버 버전 사용';

  @override
  String get nextcloudMerge => '병합';

  @override
  String get nextcloudDeleteNote => '노트를 삭제할까요?';

  @override
  String get nextcloudWorkspaceReplaceUnavailable =>
      'Nextcloud Notes에서는 작업 공간 전체 바꾸기를 사용할 수 없습니다. 각 노트에서 바꾸세요.';

  @override
  String get nextcloudSaveLocalCopy => '로컬 사본 저장…';

  @override
  String get nextcloudDisconnectWarning =>
      '이 계정을 제거하면 이 기기의 캐시된 노트와 보류 중인 변경 사항이 삭제됩니다. 작업을 서버에 보관하려면 먼저 동기화하세요.';

  @override
  String get nextcloudAttachmentRetryWarning =>
      '이전 업로드가 성공했다면 다시 시도할 때 사용하지 않는 첨부 파일이 서버에 남을 수 있습니다.';

  @override
  String get nextcloudAttachmentReference => '서버의 첨부 파일 참조';

  @override
  String get nextcloudAddAttachment => '첨부 파일 추가…';

  @override
  String get nextcloudDeleteAttachmentWarning =>
      '이 첨부 파일을 삭제하면 노트 안의 해당 링크를 사용할 수 없습니다. 보관된 데이터는 로컬 기록에서 복구할 수 있습니다.';

  @override
  String get nextcloudChooseConflictingAttributes => '충돌하는 각 속성의 값을 선택하세요.';

  @override
  String get nextcloudUseServerNote => '이 서버 노트 사용';

  @override
  String get nextcloudUseServerNoteExplanation =>
      '이 초안을 선택한 서버 노트에 연결한 다음 보존된 로컬 변경 사항을 동기화합니다. 요청이 일치해도 누가 노트를 만들었는지는 확인되지 않습니다.';

  @override
  String get nextcloudExactCandidate => '요청과 정확히 일치합니다. 동일한 노트인지 확인되지 않았습니다.';

  @override
  String get nextcloudPossibleCandidate =>
      '정리된 요청과 일치할 수 있습니다. 동일한 노트인지 확인되지 않았습니다.';

  @override
  String get nextcloudSelectCandidate => '검토할 서버 노트 선택';

  @override
  String get nextcloudCreateSeparate => '별도 노트 만들기';

  @override
  String get nextcloudCreateSeparateWarning =>
      '첫 요청으로 서버 노트가 이미 만들어졌을 수 있습니다. 보존된 로컬 작업으로 별도 노트를 만듭니다. 중복으로 의심되는 노트는 삭제하지 않습니다.';

  @override
  String get wsSemanticFormats => '의미 기반 서식';

  @override
  String get wsUiControl => 'UI 컨트롤';

  @override
  String get wsFilePath => '파일 / 경로';

  @override
  String get wsUiPath => 'UI 경로';

  @override
  String get wsDefinitionList => '정의 목록';

  @override
  String get wsIncludeContent => '재사용 가능한 콘텐츠 포함';

  @override
  String get wsVariableReference => '변수 참조';

  @override
  String get wsConvertList => '목록을 절차로 변환';

  @override
  String get wsElementProperties => '요소 속성';

  @override
  String get wsTopicProperties => '주제 속성';

  @override
  String get wsCollapsible => '접기 가능';

  @override
  String get wsPublishedState => '게시 시 초기 상태';

  @override
  String get wsExpanded => '펼침';

  @override
  String get wsCollapsed => '접힘';

  @override
  String get wsCollapsedTitle => '접힌 제목';

  @override
  String get wsTerm => '용어';

  @override
  String get wsListLayout => '목록 레이아웃';

  @override
  String get wsSyncGroup => '동기화 그룹';

  @override
  String get wsTabKey => '탭 키';

  @override
  String get wsSwitcherLabel => '전환 레이블';

  @override
  String get wsNavigationElements => '탐색 요소';

  @override
  String get wsNavigationDepth => '탐색 깊이';

  @override
  String get wsAddItem => '항목 추가';

  @override
  String get wsStep => '단계';

  @override
  String get wsPropertyInvalid => '잘못된 속성 값';

  @override
  String get wsFilter => '필터';

  @override
  String get wsIdentifier => '요소 ID';

  @override
  String get wsTldr => '요약 (TLDR)';

  @override
  String get wsFullLayout => '전체 너비';

  @override
  String get wsMediumLayout => '중간 (1:2)';

  @override
  String get wsNarrowLayout => '좁은 용어 열';

  @override
  String get wsTitle => '제목';

  @override
  String get wsSwitcherKey => '전환 키';

  @override
  String get nextcloudServerSettings => '서버 Notes 설정';

  @override
  String get nextcloudNotesPath => '노트 폴더 경로';

  @override
  String get nextcloudFileSuffix => '새 노트의 파일 확장자';

  @override
  String get nextcloudServerSettingsExplanation =>
      '이 서버 Notes 설정은 다른 클라이언트에도 적용됩니다. 경로를 변경해도 파일이 이동하지 않으며 확장자를 변경해도 기존 노트의 이름이 바뀌지 않습니다.';

  @override
  String get nextcloudSettingsSaved => '서버 설정 저장됨';

  @override
  String get nextcloudSettingsNormalized => '서버에서 정규화한 값으로 저장됨';

  @override
  String get nextcloudPendingUpload => '첨부 파일 업로드 대기 중';

  @override
  String nextcloudServerCheck(String time) {
    return '마지막 서버 확인: $time';
  }

  @override
  String get nextcloudSettingsLoading => '서버 설정을 불러오는 중';

  @override
  String get nextcloudSettingsSaving => '서버 설정을 저장하는 중';

  @override
  String get nextcloudPreviousLocalEdit => '이전 로컬 편집';

  @override
  String get nextcloudUsePreviousEdit => '이전 편집 사용';

  @override
  String get quickOpen => '빠른 열기';

  @override
  String get notesAll => '모든 노트';

  @override
  String get notesUncategorized => '미분류';

  @override
  String get notesRecovery => '복구';

  @override
  String get notesRecentlyEdited => '최근 편집순';

  @override
  String get notesOldestEdited => '오래된 편집순';

  @override
  String get notesTitleAscending => '제목 오름차순';

  @override
  String get notesTitleDescending => '제목 내림차순';

  @override
  String get notesMove => '범주로 이동';

  @override
  String get notesRemoveFavorite => '즐겨찾기 해제';

  @override
  String get notesOffline => '오프라인 사용 설정';

  @override
  String get notesOfflineRemove => '오프라인 보존 해제';

  @override
  String get notesIndexing => '노트 색인 생성 중…';

  @override
  String get notesSearchHelp =>
      '검색어는 AND로 결합합니다. \"인용 구문\", title:, category:를 사용하세요.';

  @override
  String get notesSourceLocation => '소스 위치';

  @override
  String get notesRecoveryHelp =>
      '보존된 로컬 노트와 로컬 기록만 표시합니다. 서버 휴지통과 기록은 사용할 수 없습니다.';

  @override
  String get notesImport => '노트 가져오기';

  @override
  String get notesExport => '노트 내보내기';

  @override
  String get notesImportDistinct => '별도 노트로 가져오기';

  @override
  String get notesAvailableOffline => '오프라인 사용 가능';

  @override
  String get notesIncomplete => '불완전';

  @override
  String get notesSelected => '선택한 노트';

  @override
  String get notesNoHistory => '보존된 버전이 없습니다. 기록이 비활성화되었거나 만료 또는 삭제되었을 수 있습니다.';

  @override
  String get notesTextAvailable => '텍스트를 로컬에서 사용 가능';

  @override
  String get notesLocalVersion => '로컬 작업 버전';

  @override
  String get notesAttachments => '첨부 파일';

  @override
  String get notesSkipped => '건너뜀';

  @override
  String get notesFailed => '실패';

  @override
  String get notesCompleted => '완료';

  @override
  String get notesImportNew => '새 가져오기 시작';

  @override
  String get notesImportResume => '중단된 가져오기 재개';

  @override
  String get notesImportAlreadyImported => '이 작업에서 이미 가져옴';

  @override
  String get references => '참조';

  @override
  String get referenceIncoming => '들어오는 참조';

  @override
  String get referenceOutgoing => '나가는 참조';

  @override
  String get referenceChooseTarget => '링크 대상 선택';

  @override
  String get referenceWholeDocument => '전체 문서';

  @override
  String get referenceSourceLocation => '원본 위치';

  @override
  String get referenceTargetLocation => '대상 위치';

  @override
  String get referenceResolved => '해결됨';

  @override
  String get referenceMissing => '없음';

  @override
  String get referenceAmbiguous => '모호함';

  @override
  String get referenceUnavailable => '이 맥락에서 사용할 수 없음';

  @override
  String get referenceUnsupported => '지원되지 않음';

  @override
  String get referenceNoPortableId => '이 대상에는 확인된 이식 가능한 노트 URL이 없습니다.';

  @override
  String get wsIncludeLines => '줄 포함';

  @override
  String get wsIncludeSymbol => '기호 포함';

  @override
  String get wsEmphasizeLines => '표시된 줄 강조';

  @override
  String get wsPropertiesReadOnly => '이 보기에서 속성은 읽기 전용입니다.';

  @override
  String get wsPropertiesProtected => '보호된 요소입니다. 소스를 편집하세요.';

  @override
  String get wsPropertiesConflict => '문서 또는 요소가 변경되었습니다. 초안을 되돌리고 다시 선택하세요.';

  @override
  String get wsPropertiesUnresolved => '현재 참조를 확인할 수 없습니다.';

  @override
  String get wsUseDefault => '기본값 사용';

  @override
  String get wsPropertiesSelection => '요소 하나를 선택하세요.';

  @override
  String get wsImageDisplay => '이미지 표시';

  @override
  String get wsImageThumbnail => '클릭 가능한 미리 보기';

  @override
  String get wsEnabled => '사용';

  @override
  String get wsDisabled => '사용 안 함';

  @override
  String get wsWidth => '너비';

  @override
  String get wsHeight => '높이';

  @override
  String get wsPropertiesInactive => '게시된 접기가 꺼져 있으면 이 속성은 적용되지 않습니다.';

  @override
  String get wsNavigationAll => '제목이 있는 모든 요소';

  @override
  String get wsNavigationNone => '탐색 없음';

  @override
  String get wsNavigationCustom => '사용자 지정 탐색';

  @override
  String get wsTitleOverride => '제목 재정의';

  @override
  String get wsCompactLayout => '간결';

  @override
  String get wsWideLayout => '넓게';

  @override
  String get wsCodeSourceConflict =>
      'src를 설정하기 전에 이 블록에 작성된 코드를 이동하거나 제거하세요. Writerside는 소스 참조가 있는 비어 있지 않은 코드 블록을 허용하지 않습니다.';

  @override
  String get wsInherited => '목록에서 상속';

  @override
  String get wsExternalImageSize =>
      'Writerside는 외부 이미지 크기를 안정적으로 설정하지 못합니다. 기존 크기는 확인하거나 제거할 수 있습니다.';

  @override
  String get wsPropertiesNotSerialized => '이 변경 사항은 소스에 반영되지 않았습니다. 초안은 유지됩니다.';

  @override
  String get wsListItem => '목록 항목';

  @override
  String get wsSourceFile => '소스 파일';

  @override
  String get wsLinkTarget => '링크 대상';

  @override
  String get wsPreviewImage => '미리보기 이미지';

  @override
  String get wsIncludedElement => '포함할 요소';

  @override
  String get wsHelpModule => '도움말 모듈';

  @override
  String get wsActionId => '액션 ID';

  @override
  String get wsKeymapHelpInstance => '키맵 도움말 인스턴스';

  @override
  String get wsShowInSource => '소스에서 표시';

  @override
  String get wsOriginElement => '요소 재정의';

  @override
  String get wsOriginAncestor => '상위 요소';

  @override
  String get wsOriginModule => '모듈 기본값';

  @override
  String get wsOriginBuiltIn => '내장 기본값';

  @override
  String get wsOriginUnresolved => '확인되지 않음';

  @override
  String wsEffectiveProperty(String value, String origin) {
    return '적용 값: $value — $origin';
  }

  @override
  String get wsElementSelector => '요소';

  @override
  String wsGeneratedAnchorValue(String anchor) {
    return '생성된 값: $anchor';
  }

  @override
  String wsDefaultProperty(String value) {
    return '기본값: $value';
  }

  @override
  String wsDefaultPropertyOrigin(String value, String origin) {
    return '기본값: $value · $origin';
  }

  @override
  String wsResolvedProperty(String value) {
    return '해석된 값: $value';
  }

  @override
  String get wsPropertyUnresolved => '미해결';

  @override
  String get wsModule => '모듈';

  @override
  String get wsParent => '부모 요소';

  @override
  String get wsListType => '목록 유형';

  @override
  String get wsStartingNumber => '시작 번호';

  @override
  String get wsListSorting => '정렬';

  @override
  String get wsLetteredList => '알파벳 목록';

  @override
  String get wsCheckboxList => '체크박스 목록';

  @override
  String get wsMarkerlessList => '표시 없는 목록';

  @override
  String get wsAscending => '오름차순';

  @override
  String get wsDescending => '내림차순';

  @override
  String get wsNoSorting => '정렬 안 함';

  @override
  String get wsAsWritten => '작성된 대로';

  @override
  String get wsSentenceCase => '문장 형식';

  @override
  String get wsTitleCase => '제목 형식';

  @override
  String get wsLowerCase => '소문자';

  @override
  String get wsUpperCase => '대문자';

  @override
  String get wsNativeMarkers => 'Markdown 표시';

  @override
  String wsListMarkerStart(String number) {
    return '시작 표시: $number';
  }

  @override
  String wsListLevel(String level) {
    return '수준 $level';
  }

  @override
  String get wsModuleCapsIgnored =>
      '고정된 빌더는 모듈의 <caps> 규칙을 무시합니다. 로컬 caps 속성 또는 default-property를 사용하세요.';

  @override
  String get wsInsertElements => '요소 삽입';

  @override
  String get wsAdmonitionsAndQuotes => '안내 및 인용';

  @override
  String get wsSemanticText => '의미 텍스트';

  @override
  String get wsPropertiesUnavailable =>
      '검사 중인 요소를 사용할 수 없습니다. 계속하려면 요소를 검사하세요.';

  @override
  String get searchDocumentsCategory => '문서';

  @override
  String get searchTopicsCategory => '주제';

  @override
  String get searchCurrentDocument => '현재 문서';

  @override
  String get searchCurrentWorkspace => '현재 작업 공간';

  @override
  String get browseNotes => '노트 찾아보기';

  @override
  String get searchActionsCommand => '작업 검색';

  @override
  String get searchDocumentsCommand => '문서 검색';

  @override
  String get searchTopicsCommand => '주제 검색';

  @override
  String get searchRecentCommand => '최근 항목 검색';

  @override
  String get searchResourceUnavailable => '이 리소스를 사용할 수 없습니다.';

  @override
  String get notesSync => '노트 동기화';

  @override
  String get searchInWorkspace => '작업 공간에서 검색';

  @override
  String get searchCategory => '검색 범주';

  @override
  String get clearHistorySearchScope => '문서 기록 전체 검색';

  @override
  String get searchInDocument => '문서에서 검색';

  @override
  String get searchDocumentHint => '이 문서에서 검색…';

  @override
  String get searchWorkspaceHint => '이 작업 공간에서 검색…';

  @override
  String get searchOutlineHint => '제목 검색…';

  @override
  String get searchHistoryHint => '로컬 기록 검색…';

  @override
  String get searchEnterText => '검색할 텍스트 입력';

  @override
  String get searchAccountUnavailable => '계정을 사용할 수 없음';

  @override
  String get searchDocumentsHint => '문서 검색…';

  @override
  String get searchTopicsHint => '주제 검색…';

  @override
  String get searchRecentHint => '최근 항목 검색…';

  @override
  String get searchActionsHint => '작업 검색…';

  @override
  String get searchRequiresNotesWorkspace => '노트 작업 공간 필요';

  @override
  String get searchSidebarLabel => '검색:';

  @override
  String get searchDocumentTextCategory => '문서 텍스트';

  @override
  String get searchWorkspaceTextCategory => '작업 공간 텍스트';

  @override
  String get searchHeadingsCategory => '제목';

  @override
  String get shortcutUnassigned => '할당되지 않음';

  @override
  String get shortcutPressKeys => '키 조합을 누르세요…';

  @override
  String get shortcutRecord => '단축키 기록';

  @override
  String get shortcutRestoreAll => '모든 기본값 복원';

  @override
  String get shortcutRestoreAllQuestion =>
      '모든 동작의 기본 단축키를 복원할까요? 사용자 지정 할당이 제거됩니다.';

  @override
  String get shortcutSaveFailed =>
      '단축키가 활성화되었지만 저장하지 못했습니다. 다시 시작 후에도 유지하려면 저장을 다시 시도하세요.';

  @override
  String get shortcutRetry => '저장 다시 시도';

  @override
  String get shortcutChanged => '할당이 변경되었습니다. 현재 단축키를 확인하고 다시 시도하세요.';

  @override
  String get shortcutInvalid => '이 조합은 이 문맥에서 할당할 수 없습니다.';

  @override
  String get shortcutSystemWarning =>
      '데스크톱에서 이 조합을 사용할 수 있습니다. BusyMark는 시스템 단축키를 재정의할 수 없습니다.';

  @override
  String get shortcutConflicts => '이 단축키는 다음 동작과 충돌합니다:';

  @override
  String get shortcutRemove => '할당 제거';

  @override
  String get shortcutRestoreDefault => '기본값 복원';

  @override
  String get shortcutAssign => '할당';

  @override
  String get shortcutReassign => '다시 할당';

  @override
  String get shortcutContextApplication => '애플리케이션';

  @override
  String get shortcutContextDocument => '문서 보기';

  @override
  String get shortcutContextEditor => '편집기 및 소스';

  @override
  String get shortcutContextWritersideSource => 'Writerside 소스';

  @override
  String get shortcutContextWorkspace => '작업 공간 탐색';

  @override
  String get shortcutContextTree => '사이드바 트리';

  @override
  String get searchHeadingsCommand => '제목 검색';

  @override
  String get shortcutFixed => '편집기에서 관리하므로 설정할 수 없습니다.';

  @override
  String get shortcutDefaultConflict => '기본 단축키가 사용자 지정 할당과 충돌합니다.';

  @override
  String get shortcutCurrentBinding => '현재 단축키';

  @override
  String get shortcutProposedBinding => '제안된 단축키';

  @override
  String get notesActions => '노트 작업';

  @override
  String get noteActions => '이 노트의 작업';

  @override
  String get noteProperties => '노트 속성';

  @override
  String get notesExportAll => '노트 내보내기 · 모든 노트…';

  @override
  String get notesExportCategory => '노트 내보내기 · 범주…';

  @override
  String get notesOfflineAll => '오프라인 사용 설정 · 모든 노트';

  @override
  String get notesOfflineCategory => '오프라인 사용 설정 · 범주';

  @override
  String get notesOfflineRemoveAll => '오프라인 보존 해제 · 모든 노트';

  @override
  String get notesOfflineRemoveCategory => '오프라인 보존 해제 · 범주';

  @override
  String get notesOfflinePause => '다운로드 일시 중지';

  @override
  String get notesOfflineResume => '다운로드 재개';

  @override
  String get notesOfflineKeep => '오프라인 사용 설정';

  @override
  String get notesOfflineRetentionHelp =>
      '이 요구 사항을 제거해도 기존 캐시 내용은 유지됩니다. 범주나 계정 요구 사항에 따라 노트가 계속 보관될 수 있습니다.';

  @override
  String get notesOfflineBroader => '이 노트는 범주 또는 계정 요구 사항에 따라서도 보관됩니다.';

  @override
  String get notesOfflineExternal =>
      '외부 미디어에는 연결이 필요합니다. BusyMark는 노트 텍스트와 관리되는 첨부 파일만 보관합니다.';

  @override
  String get notesEmptyAll => '아직 노트가 없습니다. 새 노트를 만드세요.';

  @override
  String get notesEmptyFavorites => '즐겨찾는 노트가 없습니다.';

  @override
  String get notesEmptyCategory => '이 범주에 노트가 없습니다.';

  @override
  String get notesEmptyUncategorized => '분류되지 않은 노트가 없습니다.';

  @override
  String get notesEmptyRecovery => '복구할 보관 노트가 없습니다.';

  @override
  String get notesLoadFailed => 'Nextcloud Notes · 실패. 다시 시도';

  @override
  String get notesOperationFailed =>
      '작업을 완료하지 못했습니다. 초안은 보관됩니다. 저장과 충돌을 검토한 뒤 다시 시도하세요.';

  @override
  String get notesInspectionFailed => '첨부 파일 · 실패. 다시 시도';

  @override
  String get notesStartingConnection => 'Nextcloud 연결 시작 중…';

  @override
  String get notesVerifyingConnection => '노트 접근 확인 중…';

  @override
  String get notesCancellingConnection => '로그인을 취소하고 정리 중…';

  @override
  String get notesRemovingConnection => '로컬 계정 제거 중…';

  @override
  String get notesRemovedWarning =>
      '로컬 Nextcloud 계정을 제거했습니다. 앱 암호 해지를 확인하지 못했습니다. Nextcloud 보안 설정에서 BusyMark의 앱 암호를 제거하세요.';

  @override
  String get notesBuffersNotSaved =>
      '열린 노트를 모두 로컬에 저장하지 못했습니다. 작업 공간에서 저장, 충돌 또는 정규화를 검토하세요. 로컬 변경 사항은 아직 Nextcloud와 동기화해야 할 수 있습니다.';

  @override
  String get notesSettingsLeave => '나가기 전에 Nextcloud 설정 변경 사항을 저장할까요?';

  @override
  String get notesSettingsLeaveHelp => '서버 Notes 설정 · 저장되지 않은 변경 사항';

  @override
  String get notesSettingsReload => '서버 설정 다시 불러오기…';

  @override
  String get notesSettingsReloadHelp =>
      '다시 불러오면 초안이 현재 Nextcloud 설정으로 대체됩니다. 초안을 버리고 다시 불러올까요?';

  @override
  String get notesSettingsRefreshFailed =>
      'Nextcloud가 설정을 수락했지만 노트 새로 고침에 실패했습니다. 표시된 값은 서버에서 확인한 값입니다. 노트에서 새로 고침을 다시 시도하세요.';

  @override
  String get notesUnavailable => '오프라인 · 텍스트를 로컬에서 사용 가능 · 로컬에 저장됨 · 동기화 대기';

  @override
  String get notesStorageFull =>
      'Nextcloud 저장 공간이 가득 찼습니다. 서버 공간을 확보한 뒤 다시 시도하세요.';

  @override
  String get notesRejected =>
      'Nextcloud가 이 변경을 거부했습니다. 노트를 검토하고 로컬 사본을 저장한 뒤 다시 시도하세요.';

  @override
  String get notesThrottled => 'Nextcloud가 대기를 요청했습니다. 재시도 기한이 지나면 동기화가 재개됩니다.';

  @override
  String get notesRecoveryRequired => '충돌 · 비교';

  @override
  String get notesScanning => '파일 검색 중…';

  @override
  String get notesCancelling => '취소 중… 현재 작업이 끝나기를 기다리는 중입니다.';

  @override
  String get notesCancelled => '취소됨';

  @override
  String get notesPartial => '부분 완료';

  @override
  String get notesTransferFailed => '실패. 다시 시도';

  @override
  String get notesImportPartialHelp =>
      '이전 항목은 이미 로컬에 저장되었을 수 있습니다. 중복을 방지하려면 이 가져오기를 재개하세요.';

  @override
  String get notesNotStarted => '시작하지 않음';

  @override
  String get notesCreated => '생성됨';

  @override
  String get notesRemoteDeleteUnavailable => '서버 주소 · 지원되지 않음 · 삭제 · 첨부 파일';

  @override
  String get notesCurrentText => '현재 보관된 텍스트';

  @override
  String get notesRecovering => '새 노트로 복구 중…';

  @override
  String get notesReadOnlyHelp => '읽기 전용 · 즐겨찾기 · 로컬 사본 저장…';

  @override
  String get notesSort => '노트 정렬';

  @override
  String get notesPathRelative => '노트 폴더 경로는 Nextcloud 저장소 기준의 상대 경로입니다.';

  @override
  String get notesSettingsStale =>
      'Nextcloud에서 설정이 변경되었습니다. 초안을 대체하기 전에 서버 값을 다시 불러와 검토하세요.';

  @override
  String get notesDownloadsPaused => '다운로드 일시 중지됨';

  @override
  String get notesExportNotPublished => '내보내기가 게시되지 않았습니다.';

  @override
  String get notesKeyringUnavailable => '데스크톱 키링을 잠금 해제한 뒤 다시 시도하세요.';

  @override
  String get notesConnectFailed =>
      'Nextcloud Notes에 연결하지 못했습니다. 서버 주소를 확인하고 다시 시도하세요.';

  @override
  String get notesAccountMismatch =>
      '같은 Nextcloud 계정으로 로그인하세요. 다른 계정을 연결하려면 이 계정을 먼저 제거하세요.';

  @override
  String get notesLocalRemovalFailed =>
      '로컬 계정 정리에 실패했습니다. 제거를 다시 시도할 수 있도록 계정을 유지합니다.';

  @override
  String get notesTransferring => '노트 전송 중…';

  @override
  String get notesTechnicalDetails => '기술 정보';

  @override
  String get notesPauseRequirement => '오프라인 보관 요구 사항 일시 중지';

  @override
  String get notesResumeRequirement => '오프라인 보관 요구 사항 재개';

  @override
  String get gitReturnToDocument => '문서로 돌아가기';

  @override
  String gitSnapshotLabel(String revision, String path) {
    return '읽기 전용 스냅샷 · $revision · $path';
  }

  @override
  String get gitNonUtf8FilenameMessage =>
      '이 파일 이름에는 UTF-8이 아닌 바이트가 있습니다. Git 검토와 스테이징은 사용할 수 있지만 문서 편집기에는 UTF-8 파일 이름이 필요합니다.';

  @override
  String get gitUiMergeInProgress => '병합 진행 중';

  @override
  String get gitUiRebaseInProgress => '리베이스 진행 중';

  @override
  String get gitUiCherryPickInProgress => '체리픽 진행 중';

  @override
  String get gitUiRevertInProgress => '되돌리기 진행 중';

  @override
  String get gitUiPatchApplicationInProgress => '패치 적용 중';

  @override
  String get gitUiSquashMergeResultAwaitingCommit => '스쿼시 병합 결과가 커밋을 기다리고 있습니다';

  @override
  String get gitUiUnresolvedIndexConflicts => '인덱스에 해결되지 않은 충돌이 있습니다';

  @override
  String get gitUiUnresolvedConflicts => ' · 해결되지 않은 충돌';

  @override
  String get gitUiReviewOperation => '작업 검토';

  @override
  String get gitUiRefresh => '새로 고침';

  @override
  String get gitUiCreateNamedStash => '이름 있는 스태시 만들기';

  @override
  String get gitUiCreateStash => '스태시 생성…';

  @override
  String get gitUiNoStashes => '스태시 없음';

  @override
  String get gitUiSelectAStashToInspectItsChanges => '변경 내용을 확인할 스태시를 선택하세요';

  @override
  String get gitUiStashedUntrackedFiles => '스태시에 저장된 추적되지 않는 파일';

  @override
  String get gitUiInspectStashedUntrackedFiles => '스태시의 추적되지 않는 파일 검토…';

  @override
  String get gitUiReinstateTheStashSStagedIndexStateWhenApplying =>
      '적용할 때 스태시의 스테이징 및 인덱스 상태도 복원';

  @override
  String get gitUiApplyAndRetain => '적용 후 유지';

  @override
  String get gitUiPop => '적용 후 삭제…';

  @override
  String get gitUiCreateBranch => '브랜치 생성…';

  @override
  String get gitUiDropStash => '스태시 삭제…';

  @override
  String get gitUiBranchFromStash => '스태시에서 브랜치 생성';

  @override
  String get gitUiCreateSwitchToABranchAtTheStashSOriginal =>
      '스태시의 원래 기준점에 브랜치를 만들고 전환한 다음 적용합니다. 원래 스태시는 나중에 명시적으로 삭제할 때까지 유지됩니다.';

  @override
  String gitUiArg0ThisStash(String arg0) {
    return '이 스태시를 $arg0하시겠습니까?';
  }

  @override
  String get gitUiTheOriginalStashIsRetainedIfApplyingConflicts =>
      '적용 중 충돌이 발생하면 원래 스태시가 유지됩니다.';

  @override
  String get gitUiDeletesThisStashEntryItsChangesAreNotApplied =>
      '이 스태시 항목을 삭제합니다. 변경 내용은 적용되지 않습니다.';

  @override
  String get gitUiResolveTheUnmergedFilesGitHasNoStashContinueOr =>
      '병합되지 않은 파일을 해결하세요. Git에는 stash 계속 또는 중단 명령이 없으며 원래 스태시는 남아 있습니다.';

  @override
  String get gitUiStashNameMessage => '스태시 이름/메시지';

  @override
  String get gitUiStashContentAndResultingIndex => '스태시에 저장할 내용 및 결과 인덱스';

  @override
  String get gitUiStashTrackedWorkingAndStagedChanges =>
      '추적 중인 작업 변경 및 스테이징된 변경 저장';

  @override
  String get gitUiStashChangesLeaveStagedChangesInPlaceKeepIndex =>
      '변경을 스태시하고 스테이징된 변경은 그대로 유지 (--keep-index)';

  @override
  String get gitUiStashOnlyStagedChangesStaged => '스테이징된 변경만 스태시 (--staged)';

  @override
  String get gitUiIncludeUntrackedFiles => '추적되지 않는 파일 포함';

  @override
  String get gitUiAllEligiblePathsInThisRepository => '이 저장소의 모든 대상 경로';

  @override
  String get gitUiNoEligibleChangesForTheseStashOptions =>
      '이 스태시 옵션에 해당하는 변경 내용이 없습니다.';

  @override
  String get gitUiSelectAtLeastOneEligiblePath => '대상 경로를 하나 이상 선택하세요.';

  @override
  String get gitUiCreateStash2 => '스태시 생성';

  @override
  String get gitUiCreateWorktree => '워크트리 만들기…';

  @override
  String get gitUiCreateACommitBeforeCreatingAWorktreeAtHEAD =>
      'HEAD에 워크트리를 만들기 전에 커밋하세요.';

  @override
  String get gitUiDetachedHEAD => '분리된 HEAD';

  @override
  String get gitUiCurrent => '현재 · ';

  @override
  String get gitUiLocked => '잠김 · ';

  @override
  String get gitUiOpenInBusyStack => 'BusyStack에서 열림 · ';

  @override
  String get gitUiStatusNotInspected => '상태를 확인하지 않았습니다';

  @override
  String get gitUiDirty => '변경 있음';

  @override
  String get gitUiClean => '변경 없음';

  @override
  String get gitUiOpenWorkingFolder => '작업 폴더 열기';

  @override
  String get gitUiMoveWorktree => '워크트리 이동…';

  @override
  String get gitUiUnlock => '잠금 해제';

  @override
  String get gitUiLock => '잠금';

  @override
  String get gitUiRemoveCleanWorktree => '변경 없는 워크트리 제거…';

  @override
  String get gitUiReviewRemovalIncludingLocalChanges => '로컬 변경을 포함한 제거 검토…';

  @override
  String get gitUiNewWorktreeFolderName => '새 워크트리 폴더 이름';

  @override
  String get gitUiNewWorktreeBranch => '새 워크트리 브랜치';

  @override
  String gitUiCreateArg0Arg1WithANewLocalBranchAtArg2(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return '$arg2($arg3)에 새 로컬 브랜치를 만들고 $arg0/$arg1을 만듭니다.';
  }

  @override
  String get gitUiDestinationFolderName => '대상 폴더 이름';

  @override
  String get gitUiRemoveWorktree => '워크트리를 제거하시겠습니까?';

  @override
  String
  get gitUiExplicitlyDiscardAllLocalTrackedUntrackedChangesInThisWorktree =>
      '이 워크트리의 추적 중이거나 추적되지 않는 모든 로컬 변경을 명시적으로 버립니다. 잠겼거나 사용 중인 워크트리는 계속 보호됩니다.';

  @override
  String get gitUiGitRefusesRemovalIfThereAreLocalChangesUntrackedFiles =>
      '로컬 변경, 추적되지 않는 파일 또는 잠금이 있으면 Git이 제거를 거부합니다.';

  @override
  String get gitUiDiscardLocalWorktreeContentsAndRemove => '로컬 워크트리 내용을 버리고 제거';

  @override
  String get gitUiRemoveCleanWorktree2 => '변경 없는 워크트리 제거';

  @override
  String
  get gitUiExplicitlyRecurseIntoNestedSubmodulesForUpdatesSynchronization =>
      '업데이트/동기화할 때 중첩 서브모듈도 명시적으로 재귀 처리';

  @override
  String get gitUiNoRecordedSubmodules => '기록된 서브모듈 없음';

  @override
  String get gitUiNotInitialized => '초기화되지 않음';

  @override
  String gitUiParentGitlinkArg0CheckedOutArg1(String arg0, String arg1) {
    return '상위 gitlink: $arg0\n체크아웃: $arg1\n';
  }

  @override
  String get gitUiDirtyNestedRepository => '중첩 저장소에 변경 있음';

  @override
  String get gitUiCleanNestedRepository => '중첩 저장소에 변경 없음';

  @override
  String get gitUiNestedStatusUnavailable => '중첩 상태를 확인할 수 없습니다';

  @override
  String get gitUiEnterNestedRepository => '중첩 저장소 열기';

  @override
  String get gitUiInitializeConfiguration => '구성 초기화';

  @override
  String get gitUiUpdateToParentSRecordedCommit => '상위에 기록된 커밋으로 업데이트…';

  @override
  String get gitUiFollowConfiguredRemoteBranch => '구성된 원격 브랜치 따르기…';

  @override
  String get gitUiSynchronizeConfiguredURLs => '구성된 URL 동기화…';

  @override
  String get gitUiStageCurrentSubmodulePointerInParent =>
      '현재 서브모듈 포인터를 상위에서 스테이징';

  @override
  String get gitUiParentAndSubmoduleCommitsPushesAndDirtyStateRemainSeparate =>
      '상위와 서브모듈의 커밋, 푸시 및 변경 상태는 각각 독립적입니다. 탐색만으로 초기화하거나 업데이트하지 않습니다.';

  @override
  String gitUiFetchAndCheckOutTheConfiguredRemoteBranchSCommit(String arg0) {
    return '구성된 원격 브랜치의 커밋을 가져와 체크아웃합니다. 상위에 기록된 gitlink와 다릅니다. 재귀: $arg0.';
  }

  @override
  String gitUiInitializeAsNeededAndCheckOutExactlyArg0RecursiveArg1(
    String arg0,
    String arg1,
  ) {
    return '필요하면 초기화하고 정확히 $arg0을 체크아웃합니다. 재귀: $arg1.';
  }

  @override
  String gitUiApplyTheReviewedSubmoduleConfigurationOperationRecursiveArg0(
    String arg0,
  ) {
    return '검토한 서브모듈 구성 작업을 적용합니다. 재귀: $arg0.';
  }

  @override
  String get gitUiApplySubmoduleOperation => '서브모듈 작업 적용';

  @override
  String get gitUiInspectARecordedRevisionOrCreateARecoveryBranchReflog =>
      '기록된 리비전을 확인하거나 복구 브랜치를 만듭니다. reflog는 임의의 저장되지 않았거나 추적되지 않는 내용을 복구하지 못합니다.';

  @override
  String get gitUiSelectAReflogEntry => 'reflog 항목 선택';

  @override
  String get gitUiPreviousPage => '이전 페이지';

  @override
  String get gitUiNextPage => '다음 페이지';

  @override
  String get gitUiRecoveryBranchName => '복구 브랜치 이름';

  @override
  String gitUiCreatesABranchAtArg0WorkingFilesAndTheCurrent(String arg0) {
    return '$arg0에 브랜치를 만듭니다. 작업 파일과 현재 브랜치는 변경되지 않습니다.';
  }

  @override
  String get gitUiCreateRecoveryBranch => '복구 브랜치 만들기…';

  @override
  String get gitUiReadOnlyRecoverySnapshot => '읽기 전용 복구 스냅샷';

  @override
  String get gitUiInspectSnapshot => '스냅샷 검토…';

  @override
  String get gitUiReviewReset => '재설정 검토…';

  @override
  String gitUiPageArg0(String arg0) {
    return '$arg0 페이지';
  }

  @override
  String get gitUiAGitTextHistoryMustOwnItsEditableField =>
      'Git 텍스트 기록에는 자체 편집 필드가 필요합니다.';

  @override
  String get gitUiEditHEADIndexWorkingTree => '편집 HEAD | 인덱스 | 작업 트리…';

  @override
  String
  get gitUiTheReviewedIndexOrWorkingContentChangedRefreshThisComparison =>
      '검토한 인덱스 또는 작업 내용이 변경되었습니다. 스테이징하기 전에 비교를 새로 고치세요.';

  @override
  String get gitUiRefreshComparison => '비교 새로 고침';

  @override
  String get gitUiPreviousChangedFile => '이전 변경 파일';

  @override
  String get gitUiNextChangedFile => '다음 변경 파일';

  @override
  String get gitUiPreviousDifference => '이전 차이';

  @override
  String get gitUiNextDifference => '다음 차이';

  @override
  String get gitUiComparisonMode => '비교 모드';

  @override
  String get gitUiSideBySide => '나란히 보기';

  @override
  String get gitUiUnified => '통합 보기';

  @override
  String get gitUiDiffDisplayOptions => '차이 표시 옵션';

  @override
  String get gitUiWrap => '줄 바꿈';

  @override
  String get gitUiWords => '단어';

  @override
  String get gitUiCollapseContext => '변경 없는 문맥 접기';

  @override
  String get gitUiIgnoreWhitespace => '공백 무시';

  @override
  String get gitUiSearchComparison => '비교 내용 검색';

  @override
  String get gitUiSearch => '검색';

  @override
  String get gitUiCloseSearch => '검색 닫기';

  @override
  String get gitUiStagingActions => '스테이징 작업';

  @override
  String get gitUiStagingActions2 => '스테이징 작업…';

  @override
  String get gitUiUnstageSelectedChangedLines => '선택한 변경 줄 스테이징 해제';

  @override
  String get gitUiStageSelectedChangedLines => '선택한 변경 줄 스테이징';

  @override
  String get gitUiUnstageWholeFile => '파일 전체 스테이징 해제';

  @override
  String get gitUiStageWholeFile => '파일 전체 스테이징';

  @override
  String gitUiArg0WhitespaceOnlyChangedLinesHiddenShowExactChanges(
    String arg0,
  ) {
    return '공백만 변경된 $arg0개 행 숨김 · 정확한 변경 표시';
  }

  @override
  String gitUiArg0ChangedLinesSelectedDisplaySettingsNeverAlterTheStaged(
    String arg0,
  ) {
    return '변경된 $arg0개 행 선택 · 표시 설정은 스테이징되는 바이트를 바꾸지 않습니다.';
  }

  @override
  String get gitUiReadOnlyComparisonCopyTextOrAdjustDisplaySettings =>
      '읽기 전용 비교 · 텍스트를 복사하거나 표시 설정을 조정하세요.';

  @override
  String get gitUiNoFinalNewline => ' · 마지막 줄 바꿈 없음';

  @override
  String gitUiArg0Arg1Arg2BytesArg3(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return '$arg0 · $arg1 · $arg2바이트$arg3';
  }

  @override
  String get gitUiTextComparisonIsUnavailableForTheseContents =>
      '이 내용은 텍스트로 비교할 수 없습니다.';

  @override
  String get gitUiThisComparisonExceedsTheBoundedTextReviewLimitTheContents =>
      '이 비교는 제한된 텍스트 검토 한도를 초과합니다. 내용이 같다고 판단한 것은 아닙니다.';

  @override
  String get gitUiTheComparedContentsAreIdentical => '비교한 내용이 같습니다.';

  @override
  String get gitUiUnstage => '스테이징 해제';

  @override
  String get gitUiStage => '스테이징';

  @override
  String gitUiArg0ChangedLine(String arg0) {
    return '변경된 행 $arg0';
  }

  @override
  String get gitUiContext => '문맥';

  @override
  String get gitUiExpandUnchangedContext => '변경 없는 문맥 펼치기';

  @override
  String get gitUiUnstageThisHunk => '이 덩어리 스테이징 해제';

  @override
  String get gitUiStageThisHunk => '이 덩어리 스테이징';

  @override
  String gitUiEditStagedContentArg0(String arg0) {
    return '스테이징된 내용 편집 · $arg0';
  }

  @override
  String get gitUiWritingReviewedIndexResult => '검토한 인덱스 결과를 쓰는 중';

  @override
  String get gitUiHead => 'HEAD';

  @override
  String get gitUiIndex => '인덱스';

  @override
  String get gitUiWorkingTree => '작업 트리';

  @override
  String gitUiHeadArg0(String arg0) {
    return 'HEAD · $arg0';
  }

  @override
  String get gitUiIndexEditableUTF8Blob => '인덱스 · 편집 가능한 UTF-8 blob';

  @override
  String get gitUiUndo => '실행 취소';

  @override
  String get gitUiRedo => '다시 실행';

  @override
  String get gitUiReloadIndexReview => '인덱스 검토를 다시 불러오시겠습니까?';

  @override
  String get gitUiReloadTheCurrentHEADIndexAndWorkingVersionsThisReplaces =>
      '현재 HEAD, 인덱스 및 작업 버전을 다시 불러옵니다. 저장하지 않은 인덱스 편집 초안이 대체됩니다.';

  @override
  String get gitUiReplaceDraftAndReload => '초안을 대체하고 다시 불러오기';

  @override
  String get gitUiReloadVersions => '버전 다시 불러오기…';

  @override
  String get gitUiWriteEditedResultToThisIndexEntry => '편집한 결과를 이 인덱스 항목에 쓰기';

  @override
  String get gitUiWorkingFilesRemainOnDiskReviewTheEditedIndexBefore =>
      '작업 파일은 디스크에 유지됩니다. 적용하기 전에 편집한 인덱스를 검토하세요.';

  @override
  String get gitUiReviewIndexTextFormatChanges => '인덱스 텍스트 형식 변경 검토';

  @override
  String gitUiUpdateOnlyTheReviewedIndexEntryForArg0Arg1(
    String arg0,
    String arg1,
  ) {
    return '검토한 $arg0의 인덱스 항목만 업데이트합니다.\n\n$arg1';
  }

  @override
  String get gitUiWriteReviewedIndexResult => '검토한 인덱스 결과 쓰기';

  @override
  String get gitUiTheEditedResultChangedDuringFormatReviewReviewItAgain =>
      '형식 검토 중 편집 결과가 변경되었습니다. 다시 검토하세요.';

  @override
  String get gitUiSynchronizeScrolling => '스크롤 동기화';

  @override
  String get gitUiReadOnlyRevisionContent => '읽기 전용 리비전 내용';

  @override
  String get gitUiEditableIndexContent => '편집 가능한 인덱스 내용';

  @override
  String get gitUiTheRequestedRevisionIsOutsideTheCurrentFiltersResetFilters =>
      '요청한 리비전이 현재 필터 범위 밖에 있습니다. 표시하려면 필터를 재설정하세요.';

  @override
  String get gitUiFilterLog => '로그 필터';

  @override
  String get gitUiFilters => '필터…';

  @override
  String gitUiFiltersCount(String count) {
    return '필터($count)…';
  }

  @override
  String get gitUiMessage => '메시지…';

  @override
  String get gitUiAuthor => '작성자…';

  @override
  String get gitUiPath => '경로…';

  @override
  String get gitUiDate => '날짜…';

  @override
  String get gitUiMessageFilter => '메시지 필터';

  @override
  String get gitUiAuthorFilter => '작성자 필터';

  @override
  String get gitUiPathFilter => '경로 필터';

  @override
  String get gitUiMessage2 => '메시지';

  @override
  String get gitUiAuthor2 => '작성자';

  @override
  String get gitUiPath2 => '경로';

  @override
  String get gitUiDateFilter => '날짜 필터…';

  @override
  String get gitUiResetFilters => '필터 재설정';

  @override
  String get gitUiRefreshLog => '로그 새로 고침';

  @override
  String get gitUiGoToCommitReference => '커밋/참조로 이동…';

  @override
  String get gitUiBackToHEAD => 'HEAD로 돌아가기';

  @override
  String get gitUiOrderedCherryPick => '순서 지정 체리픽';

  @override
  String gitUiReviewCherryPickArg0(String arg0) {
    return '체리픽 검토($arg0)…';
  }

  @override
  String get gitUiCompareTwoSelectedRevisions => '선택한 두 리비전 비교…';

  @override
  String get gitUiToggleBranchesPane => '브랜치 창 표시 전환';

  @override
  String get gitUiFilterBranchesAndTags => '브랜치 및 태그 필터';

  @override
  String gitUiCommitArg0(String arg0) {
    return '커밋 $arg0';
  }

  @override
  String get gitUiCommitDetails => '커밋 세부 정보…';

  @override
  String gitUiReferenceArg0(String arg0) {
    return '참조: $arg0';
  }

  @override
  String get gitUiSelectThisCommit => '이 커밋 선택';

  @override
  String get gitUiBranchOrTag => '브랜치 또는 태그';

  @override
  String get gitUiAllReferences => '모든 참조';

  @override
  String get gitUiLocal => '로컬';

  @override
  String get gitUiRemote => '원격';

  @override
  String get gitUiTags => '태그';

  @override
  String get gitUiNoCommitsMatchTheCurrentFilters => '현재 필터와 일치하는 커밋이 없습니다.';

  @override
  String get gitUiObjectID => '객체 ID';

  @override
  String get gitUiSubjectReferences => '제목 / 참조';

  @override
  String get gitUiDate2 => '날짜';

  @override
  String get gitUiGitCommits => 'Git 커밋';

  @override
  String get gitUiParents => '부모 커밋';

  @override
  String gitUiArg0Parents(String arg0) {
    return '부모 $arg0개';
  }

  @override
  String get gitUiLoadMoreCommits => '커밋 더 불러오기';

  @override
  String get gitUiLoadingChangedFiles => '변경 파일을 불러오는 중';

  @override
  String get gitUiNoChangedFiles => '변경 파일 없음';

  @override
  String get gitUiSelectACommit => '커밋 선택';

  @override
  String gitUiCompareParentArg0Arg1(String arg0, String arg1) {
    return '부모 $arg0 비교: $arg1';
  }

  @override
  String get gitUiChangedFiles => '변경된 파일';

  @override
  String gitUiAuthorArg0Arg1Arg2(String arg0, String arg1, String arg2) {
    return '작성자: $arg0 <$arg1>\n$arg2';
  }

  @override
  String gitUiCommitterArg0Arg1Arg2(String arg0, String arg1, String arg2) {
    return '커미터: $arg0 <$arg1>\n$arg2';
  }

  @override
  String get gitUiShallowPartialBoundaryAParentObjectIsUnavailable =>
      '얕은/부분 저장소 경계: 부모 객체를 사용할 수 없습니다.';

  @override
  String get gitUiParentIsOutsideThisPageOrAShallowBoundary =>
      '부모가 이 페이지 또는 얕은 저장소 경계 밖에 있습니다.';

  @override
  String gitUiParentArg0(String arg0) {
    return '부모 커밋 $arg0';
  }

  @override
  String get gitUiCommitActions => '커밋 작업…';

  @override
  String get gitUiEmptyTree => '빈 트리';

  @override
  String get gitUiCreateBranch2 => '브랜치 생성';

  @override
  String get gitUiCreateTag => '태그 생성';

  @override
  String get gitUiCompareRevisions => '리비전 비교';

  @override
  String get gitUiOpenSnapshot => '스냅샷 열기';

  @override
  String get gitUiRevertCommit => '커밋 되돌리기';

  @override
  String get gitUiInteractiveRebaseAfterThisBoundary => '이 경계 이후 대화형 리베이스';

  @override
  String get gitUiResetCurrentBranch => '현재 브랜치 재설정';

  @override
  String get gitUiCopyFullObjectID => '전체 객체 ID 복사';

  @override
  String get gitUiGoToCommitReference2 => '커밋/참조로 이동';

  @override
  String get gitUiEnterACommitIDOrReferenceToRevealInLog =>
      '로그에 표시할 커밋 ID 또는 참조를 입력하세요.';

  @override
  String get gitUiTheRequestedRevisionIsUnavailable => '요청한 리비전을 사용할 수 없습니다.';

  @override
  String
  get gitUiRepositoryMetadataIsReadOnlyBranchInspectionAndComparisonRemain =>
      '저장소 메타데이터가 읽기 전용입니다. 브랜치 확인과 비교는 사용할 수 있습니다.';

  @override
  String get gitUiWorkingFilesAreUnavailableOrReadOnlyBranchSwitchingAnd =>
      '작업 파일을 사용할 수 없거나 읽기 전용입니다. 브랜치 전환과 병합을 사용할 수 없습니다.';

  @override
  String get gitUiSearchBranchesAndTags => '브랜치 및 태그 검색';

  @override
  String get gitUiNewBranch => '새 브랜치…';

  @override
  String get gitUiLocalBranches => '로컬 브랜치';

  @override
  String get gitUiRemoteBranches => '원격 브랜치';

  @override
  String gitUiTracksArg0(String arg0) {
    return '추적 대상 $arg0';
  }

  @override
  String gitUiCheckedOutAtArg0(String arg0) {
    return '체크아웃 위치 $arg0';
  }

  @override
  String get gitUiRefreshingBranchMetadata => '브랜치 메타데이터 새로 고치는 중';

  @override
  String gitUiSwitchToArg0(String arg0) {
    return '$arg0(으)로 전환';
  }

  @override
  String get gitUiOpenOccupiedWorktree => '사용 중인 워크트리 열기';

  @override
  String get gitUiCreateLocalTrackingBranch => '로컬 추적 브랜치 만들기…';

  @override
  String get gitUiCompareToCurrentHEAD => '현재 HEAD와 비교';

  @override
  String get gitUiMergeIntoCurrentBranch => '현재 브랜치로 병합…';

  @override
  String get gitUiRename => '이름 바꾸기…';

  @override
  String get gitUiChangeUpstream => '업스트림 변경…';

  @override
  String get gitUiDelete => '삭제…';

  @override
  String get gitUiDeleteFromRemote => '원격에서 삭제…';

  @override
  String gitUiActionsForArg0(String arg0) {
    return '$arg0 작업';
  }

  @override
  String get gitUiLocalBranchName => '로컬 브랜치 이름';

  @override
  String gitUiCreateAtArg0TheNewBranchWillBeCheckedOut(String arg0) {
    return '$arg0에 만듭니다. 새 브랜치를 체크아웃합니다.';
  }

  @override
  String gitUiTheLocalBranchWillTrackArg0AndBeCheckedOut(String arg0) {
    return '로컬 브랜치가 $arg0을(를) 추적하며 체크아웃됩니다.';
  }

  @override
  String get gitUiChooseRemoteForDeletion => '삭제할 원격 선택';

  @override
  String get gitUiDeleteRemoteReference => '원격 참조 삭제';

  @override
  String gitUiMergeArg0IntoArg1(String arg0, String arg1) {
    return '$arg0을(를) $arg1(으)로 병합';
  }

  @override
  String gitUiRenameArg0(String arg0) {
    return '$arg0 이름 바꾸기';
  }

  @override
  String gitUiUpstreamForArg0(String arg0) {
    return '$arg0의 업스트림';
  }

  @override
  String get gitUiNoUpstream => '업스트림 없음';

  @override
  String gitUiDeleteArg0(String arg0) {
    return '$arg0을(를) 삭제하시겠습니까?';
  }

  @override
  String gitUiArg0TargetArg1LocalDeletionOnlyAnUnmergedBranchIs(
    String arg0,
    String arg1,
  ) {
    return '$arg0\n대상 $arg1\n로컬에서만 삭제합니다. 병합되지 않은 브랜치는 거부됩니다.';
  }

  @override
  String get gitUiDelete2 => '삭제';

  @override
  String gitUiDeleteUnmergedBranchArg0(String arg0) {
    return '병합되지 않은 브랜치 $arg0을(를) 삭제하시겠습니까?';
  }

  @override
  String gitUiArg0GitReportsThisBranchIsNotFullyMergedExplicitly(String arg0) {
    return '$arg0\nGit에 따르면 이 브랜치는 완전히 병합되지 않았습니다. 커밋을 검토한 후 로컬 참조를 명시적으로 삭제하세요. 원격 복사본은 변경되지 않습니다.';
  }

  @override
  String get gitUiDeleteUnmergedLocalBranch => '병합되지 않은 로컬 브랜치 삭제';

  @override
  String gitUiDestinationArg0Arg1(String arg0, String arg1) {
    return '대상: $arg0 · $arg1';
  }

  @override
  String get gitUiSourceBranchOrTag => '원본 브랜치 또는 태그';

  @override
  String get gitUiMergePolicy => '병합 정책';

  @override
  String get gitUiFastForwardWhenPossible => '가능하면 빨리 감기';

  @override
  String get gitUiAlwaysCreateAMergeCommit => '항상 병합 커밋 만들기';

  @override
  String get gitUiFastForwardOnly => '빨리 감기만';

  @override
  String get gitUiSquashIntoStagedChanges => '스테이징된 변경으로 스쿼시';

  @override
  String get gitUiStopBeforeCreatingTheMergeCommit => '병합 커밋을 만들기 전에 중지';

  @override
  String get gitUiFastForwardIsDisabledSoHEADCannotMoveBeforeReview =>
      '검토 전에 HEAD가 이동하지 않도록 빨리 감기가 비활성화됩니다.';

  @override
  String get gitUiLeavesStagedChangesForASeparateCommitThisIsNot =>
      '별도로 커밋할 스테이징된 변경을 남깁니다. 계속해야 하는 병합 상태는 아닙니다.';

  @override
  String get gitUiConflictsRemainAvailableInTheSharedResolutionWorkspace =>
      '공유 충돌 해결 작업 공간에서 충돌을 확인할 수 있습니다.';

  @override
  String get gitUiAddRemote => '원격 추가…';

  @override
  String gitUiFetchArg0PushArg1(String arg0, String arg1) {
    return '가져오기: $arg0\n푸시: $arg1';
  }

  @override
  String get gitUiRemoveRemote => '원격 제거…';

  @override
  String get gitUiChangeFetchURL => '가져오기 URL 변경…';

  @override
  String get gitUiAddPushDestination => '푸시 대상 추가…';

  @override
  String get gitUiRemovePushDestination => '푸시 대상 제거…';

  @override
  String gitUiManageArg0(String arg0) {
    return '$arg0 관리';
  }

  @override
  String get gitUiRemoteName => '원격 이름';

  @override
  String get gitUiNewRemoteName => '새 원격 이름';

  @override
  String get gitUiRepositoryURLOrLocalSource => '저장소 URL 또는 로컬 원본';

  @override
  String get gitUiEnterTheExactReviewedDestinationToRemove =>
      '제거할 검토된 대상을 정확히 입력하세요.';

  @override
  String get gitUiCredentialsAreSuppliedByConfiguredHelpersOrAPrivatePrompt =>
      '자격 증명은 구성된 도우미 또는 비공개 프롬프트로 제공됩니다.';

  @override
  String gitUiRemoveRemoteArg0(String arg0) {
    return '원격 $arg0을(를) 제거하시겠습니까?';
  }

  @override
  String
  get gitUiRemovesLocalRemoteConfigurationAndTrackingReferencesItDoesNot =>
      '로컬 원격 구성과 추적 참조를 제거합니다. 서버 저장소는 삭제하지 않습니다.';

  @override
  String get gitUiRemoveRemote2 => '원격 제거';

  @override
  String get gitUiCommitScopeEntireRepository => '커밋 범위: 전체 저장소';

  @override
  String get gitUiCachedTracking => '캐시된 추적 정보';

  @override
  String get gitUiAmendLastCommit => '마지막 커밋 수정';

  @override
  String get gitUiConfiguredHooksAndSigningAreRespected =>
      '구성된 훅 및 서명 설정을 따릅니다.';

  @override
  String get gitUiRewritesTheSelectedHEADCommitRemoteTrackingCannotProveIt =>
      '선택한 HEAD 커밋을 다시 씁니다. 원격 추적 정보로는 미공개임을 증명할 수 없습니다.';

  @override
  String get gitUiRepository => '저장소';

  @override
  String gitUiDetachedArg0(String arg0) {
    return '분리된 $arg0';
  }

  @override
  String get gitUiLog => '로그';

  @override
  String get gitUiRepositoryActions => '저장소 작업';

  @override
  String gitUiCachedTrackingUpstreamAheadAheadBehindBehind(
    String upstream,
    String ahead,
    String behind,
  ) {
    return '캐시된 추적 정보 · $upstream · $ahead개 앞섬 · $behind개 뒤처짐';
  }

  @override
  String get gitUiBareRepositoryNoWorkingTreeOpenLogToInspectIts =>
      '베어 저장소 · 작업 트리가 없습니다. 기록을 확인하려면 로그를 여세요.';

  @override
  String get gitUiReadOnlyRepositoryStagingAndCommitsAreUnavailable =>
      '읽기 전용 저장소 · 스테이징과 커밋을 사용할 수 없습니다.';

  @override
  String get gitUiRepositoryStatusUnavailable => '저장소 상태를 확인할 수 없습니다';

  @override
  String gitUiAmendRevision(String revision) {
    return '$revision 수정';
  }

  @override
  String get gitUiAddSignOffTrailer => '승인 꼬리말 추가';

  @override
  String get gitUiUseConfiguredSigningPolicy => '구성된 서명 정책 사용';

  @override
  String get gitUiCryptographicallySignThisCommit => '이 커밋에 암호학적 서명 추가';

  @override
  String get gitUiDoNotSignThisCommit => '이 커밋에 서명하지 않음';

  @override
  String get gitUiRecentCommitMessages => '최근 커밋 메시지…';

  @override
  String get gitUiUseConfiguredCommitTemplate => '구성된 커밋 템플릿 사용…';

  @override
  String get gitUiAuthorIdentityAndConfiguredHooks => '작성자 신원 및 구성된 훅…';

  @override
  String get gitUiDraftMessage => '메시지 초안 작성…';

  @override
  String get gitUiCommitOptions => '커밋 옵션';

  @override
  String gitUiDraftRetainedInMemorySavingItFailedArg0(String arg0) {
    return '초안이 메모리에 유지됩니다. 저장하지 못했습니다. $arg0';
  }

  @override
  String get gitUiCommitMessage => '커밋 메시지';

  @override
  String get gitUiGitOperationInProgress => 'Git 작업 진행 중';

  @override
  String get gitUiCancel => '취소';

  @override
  String get gitUiAmendStaged => '스테이징된 내용으로 수정';

  @override
  String gitUiCommitStagedCount(String count) {
    return '스테이징된 내용 커밋($count)';
  }

  @override
  String get gitUiCommitAndPush => '커밋 후 푸시…';

  @override
  String get gitUiNoReadableCommitTemplateIsConfigured =>
      '읽을 수 있는 커밋 템플릿이 구성되어 있지 않습니다.';

  @override
  String get gitUiCommitIdentityAndHooks => '커밋 신원 및 훅';

  @override
  String get gitUiRecentMessages => '최근 메시지';

  @override
  String get gitUiReplaceMessageDraft => '메시지 초안을 대체하시겠습니까?';

  @override
  String get gitUiReplaceTheExistingCommitMessageWithTheSelectedMessage =>
      '현재 커밋 메시지를 선택한 메시지로 바꾸시겠습니까?';

  @override
  String get gitUiReplaceDraft => '초안 대체';

  @override
  String gitUiLocalCommitArg0Exists(String arg0) {
    return '로컬 커밋 $arg0이(가) 있습니다.';
  }

  @override
  String gitUiLocalCommitArg0ExistsReviewLogBeforeAttemptingAnotherCommit(
    String arg0,
  ) {
    return '로컬 커밋 $arg0이(가) 있습니다. 다시 커밋하기 전에 로그를 검토하세요. 메시지 초안은 유지됩니다.';
  }

  @override
  String get gitUiCommitAuthorName => '커밋 작성자 이름';

  @override
  String get gitUiCommitAuthorEmail => '커밋 작성자 이메일';

  @override
  String get gitUiConfiguredDefault => '구성된 기본값';

  @override
  String get gitUiOpenpgp => 'OpenPGP';

  @override
  String gitUiSigningArg0Arg1(String arg0, String arg1) {
    return '서명: $arg0 · $arg1';
  }

  @override
  String gitUiConfiguredHooksArg0(String arg0) {
    return '구성된 훅: $arg0';
  }

  @override
  String get gitUiASignOffTrailerIsAStatementInTheMessage =>
      '승인 꼬리말은 메시지에 포함하는 진술이며 암호학적 서명과는 다릅니다. 작성자 정보는 이 저장소의 로컬 설정에만 저장되고 초안은 유지됩니다.';

  @override
  String get gitUiSaveRepositoryIdentity => '저장소 신원 저장';

  @override
  String get gitUiStaged => '스테이징됨';

  @override
  String get gitUiUntracked => '추적되지 않음';

  @override
  String get gitUiUnstaged => '스테이징되지 않음';

  @override
  String get gitUiConflicts => '충돌';

  @override
  String get gitUiNoChanges => '변경 내용 없음';

  @override
  String get gitUiRepositoryChangeTree => '저장소 변경 트리';

  @override
  String get gitUiChanges => '변경 사항';

  @override
  String gitUiGroupCount(String group, String count) {
    return '$group($count)';
  }

  @override
  String get gitUiExpand => '펼치기';

  @override
  String get gitUiCollapse => '접기';

  @override
  String get gitUiUnstageFile => '파일 스테이징 해제';

  @override
  String get gitUiStageFile => '파일 스테이징';

  @override
  String get gitUiExpandGroup => '그룹 펼치기';

  @override
  String get gitUiCollapseGroup => '그룹 접기';

  @override
  String get gitUiReviewDifference => '차이 검토';

  @override
  String get gitUiUnstageSelectedFiles => '선택한 파일 스테이징 해제';

  @override
  String get gitUiStageSelectedFiles => '선택한 파일 스테이징';

  @override
  String get gitUiFileHistoryAndBlame => '파일 기록 및 블레임…';

  @override
  String get gitUiDeleteUntrackedFile => '추적되지 않는 파일 삭제…';

  @override
  String get gitUiDiscardUnstagedChange => '스테이징되지 않은 변경 버리기…';

  @override
  String get gitUiFileHistory => '파일 이력';

  @override
  String gitUiDiscardUnstagedArg0(String arg0) {
    return '스테이징되지 않은 $arg0 변경을 버리시겠습니까?';
  }

  @override
  String gitUiArg0BytesArg1ReplacesWorkingContentWithTheIndexOr(
    String arg0,
    String arg1,
  ) {
    return '$arg0바이트 · $arg1\n작업 내용을 인덱스로 대체하거나 이 추적되지 않는 파일을 삭제합니다. 스테이징된 내용은 유지됩니다. 먼저 앱에서 저장하지 않은 문서를 검토해야 합니다.';
  }

  @override
  String get gitUiDeleteUntrackedFile2 => '추적되지 않는 파일 삭제';

  @override
  String get gitUiDiscardWorkingChange => '작업 변경 버리기';

  @override
  String gitUiDeleteREMOTEReferenceArg0(String arg0) {
    return '원격 참조 $arg0 삭제';
  }

  @override
  String get gitUiThisRemovesTheReferenceOnEveryActualPushDestinationListed =>
      '아래 나열된 모든 실제 푸시 대상에서 참조를 제거합니다. 로컬 브랜치/태그는 유지됩니다. 예상 끝점은 이 검토에 고정됩니다.';

  @override
  String get gitUiReferenceDoesNotExist => '참조가 없습니다';

  @override
  String gitUiArg0ExpectedTipArg1(String arg0, String arg1) {
    return '$arg0\n예상 끝점: $arg1';
  }

  @override
  String get gitUiRemoteDeletionCompleted => '원격 삭제가 완료되었습니다.';

  @override
  String gitUiDeleteArg0FromTheRemote(String arg0) {
    return '원격에서 $arg0을(를) 삭제하시겠습니까?';
  }

  @override
  String get gitUiTheExactDestinationTipsShownAboveWillBeRemovedAny =>
      '위에 표시된 정확한 대상 끝점을 제거합니다. 원격 끝점이 변경되면 작업을 중지하고 다시 검토합니다.';

  @override
  String get gitUiReviewAndDeleteFromRemote => '원격 삭제 검토…';

  @override
  String get gitUiDestinationReference => '대상 참조';

  @override
  String get gitUiReviewDestinations => '대상 검토';

  @override
  String get gitUiNewRemoteBranch => '새 원격 브랜치';

  @override
  String gitUiArg0Arg1ExpectedArg2(String arg0, String arg1, String arg2) {
    return '$arg0\n$arg1 · 예상값: $arg2';
  }

  @override
  String get gitUiADestinationHasCommitsThatAreUnavailableLocallyFetchThat =>
      '대상에 로컬에서 사용할 수 없는 커밋이 있습니다. 보낼 기록을 검토하기 전에 검토한 대상에서 가져오세요.';

  @override
  String get gitUiFetchReviewedDestination => '검토한 대상에서 가져오기';

  @override
  String get gitUiChooseADestinationAndReviewTheOutgoingCommits =>
      '대상을 선택하고 보낼 커밋을 검토하세요.';

  @override
  String get gitUiNoOutgoingCommits => '보낼 커밋 없음';

  @override
  String get gitUiSelectAnOutgoingCommit => '보낼 커밋 선택';

  @override
  String get gitUiLoadMoreOutgoingCommits => '보낼 커밋 더 불러오기';

  @override
  String get gitUiSetThisDestinationAsUpstream => '이 대상을 업스트림으로 설정';

  @override
  String get gitUiChooseExactTagsToPublish => '게시할 정확한 태그 선택';

  @override
  String get gitUiTagsNone => '태그: 없음';

  @override
  String gitUiTagsArg0Selected(String arg0) {
    return '태그: $arg0개 선택';
  }

  @override
  String gitUiPublishExactlyArg0(String arg0) {
    return '게시 대상: $arg0';
  }

  @override
  String get gitUiPushCompletedTheLocalCommitRemainsAvailableInLog =>
      '푸시가 완료되었습니다. 로컬 커밋은 로그에서 계속 확인할 수 있습니다.';

  @override
  String get gitUiForceRequiresTheExactDestinationTipsShownInThisReview =>
      '강제 푸시에는 이 검토에 표시된 대상 참조의 끝 리비전과 정확히 일치해야 합니다.';

  @override
  String get gitUiForceWithReviewedLease => '검토한 리스로 강제 푸시…';

  @override
  String get gitUiPush => '푸시';

  @override
  String get gitUiForcePushWithReviewedLeases => '검토한 리스로 강제 푸시하시겠습니까?';

  @override
  String gitUiRewriteArg0OnlyIfEveryRemoteDestinationStillHasThe(String arg0) {
    return '모든 원격 대상에 위에 표시된 정확한 끝점이 남아 있을 때만 $arg0을(를) 다시 씁니다.\n';
  }

  @override
  String get gitUiOtherPeopleMayAlreadyUseThisHistoryABackgroundFetch =>
      '다른 사람이 이미 이 이력을 사용하고 있을 수 있습니다. 백그라운드 가져오기는 이 보호 조건을 갱신하지 않습니다.';

  @override
  String get gitUiForceWithLease => '리스로 강제 푸시';

  @override
  String
  get gitUiTheRemoteOutcomeIsUncertainReviewDestinationsAgainBeforeAnother =>
      '원격 결과가 불확실합니다. 다시 푸시하기 전에 대상을 다시 검토하세요.';

  @override
  String gitUiParentArg0Arg1(String arg0, String arg1) {
    return '부모 $arg0 · $arg1';
  }

  @override
  String get gitUiRemoteToFetch => '가져올 원격';

  @override
  String get gitUiPruneDeletedRemoteTrackingBranches => '삭제된 원격 추적 브랜치 정리';

  @override
  String
  get gitUiFetchUpdatesRemoteTrackingInformationWithoutReplacingWorkingFiles =>
      '가져오기는 작업 파일을 대체하지 않고 원격 추적 정보를 업데이트합니다.';

  @override
  String get gitUiFetch => '가져오기';

  @override
  String get gitUiSourceRemote => '원본 원격';

  @override
  String get gitUiSourceBranch => '원본 브랜치';

  @override
  String get gitUiReviewedStrategy => '검토한 전략';

  @override
  String get gitUiMerge => '병합';

  @override
  String get gitUiRebase => '리베이스';

  @override
  String get gitUiStopIfTheDestinationCannotFastForwardNeverMergeOr =>
      '대상을 빨리 감기할 수 없으면 중지하며 병합하거나 리베이스하지 않습니다.';

  @override
  String get gitUiMergeWithAMergeCommitIncludingWhenFastForwardIs =>
      '빨리 감기가 가능해도 병합 커밋을 만들어 병합합니다.';

  @override
  String get gitUiMergeAllowFastForwardWhenPossible =>
      '병합하며 가능하면 빨리 감기를 허용합니다.';

  @override
  String get gitUiRebaseLocalHistoryWhilePreservingLocalMergeCommits =>
      '로컬 병합 커밋을 유지하며 로컬 기록을 리베이스합니다.';

  @override
  String get gitUiRebaseLocalCommitsAsALinearHistory =>
      '로컬 커밋을 선형 기록으로 리베이스합니다.';

  @override
  String get gitUiGitIsConfiguredForInteractiveRebaseSelectAPullStrategy =>
      'Git이 대화형 리베이스로 구성되어 있습니다. 여기서 풀 전략을 명시적으로 선택하거나 가져온 후 리베이스를 열어 계획을 검토하세요.';

  @override
  String get gitUiUseReviewedOrdinaryRebaseForThisPull => '이 풀에 검토한 일반 리베이스 사용';

  @override
  String get gitUiOptions => '옵션';

  @override
  String get gitUiAlwaysCreateAMergeCommitNoFastForward =>
      '항상 병합 커밋 만들기(빨리 감기 안 함)';

  @override
  String get gitUiPreserveLocalMergeCommits => '로컬 병합 커밋 유지';

  @override
  String get gitUiLocalChangesMayPreventPullReviewCommitThemOrExplicitly =>
      '로컬 변경으로 풀이 차단될 수 있습니다. 검토/커밋하거나 명시적으로 스태시를 만드세요.';

  @override
  String get gitUiStashes => '스태시';

  @override
  String get gitUiCreateOrReviewStash => '스태시 만들기 또는 검토…';

  @override
  String get gitUiPullWithSelectedStrategy => '선택한 전략으로 풀';

  @override
  String get gitUiRepositoryURLOrLocalGitSource => '저장소 URL 또는 로컬 Git 원본';

  @override
  String get gitUiHttpsSSHOrLocalPath => 'HTTPS, SSH 또는 로컬 경로';

  @override
  String get gitUiFolderToInitialize => '초기화할 폴더';

  @override
  String get gitUiFinalCloneDestination => '최종 복제 대상';

  @override
  String get gitUiChoose => '선택…';

  @override
  String get gitUiCreatesGitMetadataOnlyExistingFilesAreNotStagedOr =>
      'Git 메타데이터만 만듭니다. 기존 파일을 스테이징하거나 커밋하지 않습니다.';

  @override
  String get gitUiTheFinalDestinationMustBeAbsentOrEmptyExistingUser =>
      '최종 대상은 존재하지 않거나 비어 있어야 합니다. 기존 사용자 데이터는 절대 덮어쓰지 않습니다.';

  @override
  String get gitUiInitialBranchBlankUsesEffectiveGitPolicy =>
      '초기 브랜치 · 비워 두면 유효한 Git 정책 사용';

  @override
  String get gitUiSelectedBranchOptional => '선택한 브랜치 · 선택 사항';

  @override
  String get gitUiExplicitlyInitializeUpdateSubmodulesRecursively =>
      '서브모듈을 명시적으로 재귀 초기화/업데이트';

  @override
  String get gitUiPreparingGitOperation => 'Git 작업 준비 중…';

  @override
  String get gitUiThisAttemptCreated => '이번 시도에서 생성됨';

  @override
  String get gitUiTheDestinationExistedBeforeThisAttempt =>
      '대상이 이번 시도 이전부터 존재했습니다:';

  @override
  String get gitUiTheDirectoryRemainsForInspectionReviewItBeforeAnotherClone =>
      '확인할 수 있도록 디렉터리를 유지합니다. 다시 복제하기 전에 검토하세요.';

  @override
  String get gitUiNoDestinationDirectoryRemains => '남아 있는 대상 디렉터리가 없습니다.';

  @override
  String get gitUiCancelProcess => '프로세스 취소';

  @override
  String get gitUiInitialize => '초기화';

  @override
  String get gitUiClone => '복제';

  @override
  String get gitUiChooseNewBase => '새 기준 선택';

  @override
  String get gitUiChooseUpstreamBoundary => '업스트림 경계 선택';

  @override
  String get gitUiNewBase => '새 기준';

  @override
  String get gitUiUpstreamBoundaryExcluded => '업스트림 경계 · 제외됨';

  @override
  String get gitUiSameAsUpstreamBoundary => '업스트림 경계와 같음';

  @override
  String get gitUiChooseBranchTagOrCommit => '브랜치, 태그 또는 커밋 선택…';

  @override
  String get gitUiUseUpstreamAsNewBase => '업스트림을 새 기준으로 사용';

  @override
  String get gitUiChooseAValidBranchTagOrCommitFromLog =>
      '유효한 브랜치, 태그 또는 로그의 커밋을 선택하세요.';

  @override
  String get gitUiTheFirstRetainedCommitInABranchBlockCannotSquash =>
      '브랜치 블록에서 처음 유지하는 커밋에는 squash나 fixup을 사용할 수 없습니다. 앞에 대상 커밋이 없습니다.';

  @override
  String gitUiBranchBlockArg0(String arg0) {
    return '브랜치 블록 $arg0\n';
  }

  @override
  String get gitUiRewordWillRequestANewMessage => '[메시지 변경 시 새 메시지를 요청합니다]\n';

  @override
  String get gitUiPlannedCommitMessages => '예정된 커밋 메시지';

  @override
  String
  get gitUiOriginalCombinedMessagePreviewGitRequestsTheFinalRewordSquash =>
      '원본/결합 메시지 미리 보기 · 최종 메시지 변경/스쿼시 메시지는 Git이 요청합니다';

  @override
  String gitUiResultArg0Arg1(String arg0, String arg1) {
    return '결과 $arg0\n$arg1';
  }

  @override
  String gitUiCurrentBranchBranch(String branch) {
    return '현재 브랜치: $branch';
  }

  @override
  String get gitUiDetachedHEAD2 => '분리된 HEAD';

  @override
  String
  get gitUiRebaseRewritesCommitIdentitiesRemoteTrackingInformationCannotProveHistory =>
      '리베이스는 커밋 식별자를 다시 만듭니다. 원격 추적 정보만으로 이력이 한 번도 공개되지 않았음을 보장할 수 없습니다.';

  @override
  String get gitUiIncludeRootCommits => '루트 커밋 포함';

  @override
  String get gitUiMergeCommits => '병합 커밋';

  @override
  String get gitUiFlattenHistory => '이력 평탄화';

  @override
  String get gitUiPreserveBranchStructure => '브랜치 구조 유지';

  @override
  String get gitUiAutosquash => '자동 스쿼시';

  @override
  String get gitUiPrepareGitPlan => 'Git 계획 준비';

  @override
  String gitUiCommitsToReplayCount(String count) {
    return '재적용할 커밋: $count';
  }

  @override
  String get gitUiIncludesAllRootCommitsReachableFromThisBranch =>
      '이 브랜치에서 도달할 수 있는 모든 루트 커밋을 포함합니다.';

  @override
  String gitUiCommitsAfterBoundaryWillBeReplayedOntoBaseTheBoundary(
    String boundary,
    String base,
  ) {
    return '$boundary 이후의 커밋을 $base 위에 재적용합니다. 경계 커밋 자체는 제외됩니다.';
  }

  @override
  String get gitUiRoot => '루트';

  @override
  String get gitUiGitBranchLabelResetMergeStructure => 'Git 브랜치/레이블/재설정/병합 구조';

  @override
  String get gitUiChooseAnExplicitOldBoundaryOrRootModeThenPrepare =>
      '이전 경계 또는 루트 모드를 명시적으로 선택한 후 계획을 준비하세요.';

  @override
  String get gitUiMoveUp => '위로 이동';

  @override
  String get gitUiMoveDown => '아래로 이동';

  @override
  String get gitUiResetPlan => '계획 초기화';

  @override
  String gitUiBranchBlockArg02(String arg0) {
    return ' · 브랜치 블록 $arg0';
  }

  @override
  String get gitUiSelectACommitForDetailsAndChangedFiles =>
      '세부 정보와 변경 파일을 볼 커밋 선택';

  @override
  String get gitUiPreviewCombinedCommitMessages => '결합할 커밋 메시지 미리 보기…';

  @override
  String get gitUiAltMovesTheSelectedCommitUnrelatedBranchReferencesWillNot =>
      'Alt+↑/↓로 선택한 커밋을 이동합니다. 관련 없는 브랜치 참조를 자동으로 업데이트하지 않습니다.';

  @override
  String get gitUiCancelPlan => '계획 취소';

  @override
  String get gitUiStartReviewedRebase => '검토한 리베이스를 시작하시겠습니까?';

  @override
  String gitUiRewriteArg0PlannedCommitsOnArg1DroppedCommitsRemainVisibly(
    String arg0,
    String arg1,
  ) {
    return '$arg1에서 계획한 $arg0개 커밋을 다시 씁니다. 제외할 커밋은 시작할 때까지 계획에 표시됩니다.';
  }

  @override
  String get gitUiStartRebase => '리베이스 시작';

  @override
  String get gitUiNoContinuingGitOperation => '진행 중인 Git 작업 없음';

  @override
  String get gitUiStoppedForEditingAmend => ' · 편집/커밋 수정을 위해 중지됨';

  @override
  String get gitUiTheseAreUnmergedIndexEntriesPossiblyFromAStashApplication =>
      '인덱스의 병합되지 않은 항목이며 스태시 적용으로 생겼을 수 있습니다. Git에는 스태시 계속 또는 중단 명령이 없습니다.';

  @override
  String get gitUiEditTheWorkingFilesStageAndAmendTheCurrentCommit =>
      '작업 파일을 편집하고 스테이징하여 현재 커밋을 수정한 후 이 리베이스를 계속하세요.';

  @override
  String gitUiArg0Arg1UnmergedStagesArg2(
    String arg0,
    String arg1,
    String arg2,
  ) {
    return '$arg0$arg1 · 병합되지 않은 인덱스 단계 $arg2';
  }

  @override
  String get gitUiTheIndexHasNoUnresolvedEntries => '인덱스에 해결되지 않은 항목이 없습니다.';

  @override
  String get gitUiKeepTheCurrentCommitAsAnEmptyCommit => '현재 커밋을 빈 커밋으로 유지';

  @override
  String get gitUiTheRealIndexHasNoStagedChangesCreateAnExplicit =>
      '실제 인덱스에 스테이징된 변경이 없습니다. 명시적으로 빈 커밋을 만든 다음 시퀀서가 활성 상태이면 계속하세요.';

  @override
  String get gitUiKeepEmptyCommit => '빈 커밋 유지…';

  @override
  String get gitUiGitWillTryToReturnToTheOperationSStarting =>
      'Git은 작업 시작 지점으로 돌아가려고 합니다. 작업 전부터 있던 스테이징되지 않은 변경, 추적되지 않는 파일, 저장하지 않은 내용의 복구는 보장되지 않습니다.';

  @override
  String get gitUiSkipTheCurrentCommitAndContinueWithTheNextPlanned =>
      '현재 커밋을 건너뛰고 다음 예정된 커밋을 계속합니다.';

  @override
  String
  get gitUiForgetThisOperationSBookkeepingWhileRetainingTheCurrentFiles =>
      '현재 파일과 인덱스를 유지하며 이 작업의 관리 정보를 지웁니다.';

  @override
  String gitUiContinueArg0(String arg0) {
    return '$arg0 계속';
  }

  @override
  String get gitUiReloadConflictVersions => '충돌 버전을 다시 불러오시겠습니까?';

  @override
  String get gitUiReplaceTheUnsavedResultDraftWithTheCurrentWorkingFile =>
      '저장하지 않은 결과 초안을 현재 작업 파일로 대체합니다. 저장된 작업 내용은 유지됩니다.';

  @override
  String get gitUiLoadingConflictVersions => '충돌 버전을 불러오는 중…';

  @override
  String get gitUiLoadingConflict => '충돌 불러오는 중';

  @override
  String get gitUiBaseLeft => '기준 → 왼쪽';

  @override
  String get gitUiBaseRight => '기준 → 오른쪽';

  @override
  String get gitUiNoBaseEntryForThisConflict => '이 충돌에는 기준 항목이 없습니다';

  @override
  String get gitUiAcceptEntireLeftFile => '왼쪽 파일 전체 수락…';

  @override
  String get gitUiAcceptEntireRightFile => '오른쪽 파일 전체 수락…';

  @override
  String get gitUiPreviousConflictRegion => '이전 충돌 영역';

  @override
  String get gitUiNextConflictRegion => '다음 충돌 영역';

  @override
  String get gitUiManualResolution => '수동 해결';

  @override
  String gitUiRegionArg0Arg1Arg2Reviewed(
    String arg0,
    String arg1,
    String arg2,
  ) {
    return '영역 $arg0/$arg1 · $arg2개 검토됨';
  }

  @override
  String
  get gitUiSourceAlignmentExceededTheTextComparisonLimitSourcePanesRemain =>
      '원본 정렬이 텍스트 비교 한도를 초과했습니다. 원본 창에서 수동으로 검토할 수 있습니다.';

  @override
  String get gitUiAcceptLeftRegion => '왼쪽 영역 수락';

  @override
  String get gitUiAcceptRightRegion => '오른쪽 영역 수락';

  @override
  String get gitUiKeepManualResultForRegion => '영역의 수동 결과 유지';

  @override
  String get gitUiApplyGitSNonConflictingChanges => 'Git의 충돌 없는 변경을 적용하시겠습니까?';

  @override
  String get gitUiReplaceTheCurrentResultDraftWithGitSMergePreview =>
      '현재 결과 초안을 Git 병합 미리 보기로 대체합니다. 저장하지 않은 수동 편집을 버립니다. 저장할 때까지 작업 파일은 변경되지 않습니다.';

  @override
  String get gitUiUseMergePreview => '병합 미리 보기 사용';

  @override
  String get gitUiApplyNonConflictingChanges => '충돌 없는 변경 적용…';

  @override
  String get gitUiLeftSource => '왼쪽 원본';

  @override
  String get gitUiResult => '결과';

  @override
  String get gitUiRightSource => '오른쪽 원본';

  @override
  String get gitUiStage2 => '스테이지 2';

  @override
  String get gitUiStage3 => '스테이지 3';

  @override
  String
  get gitUiConflictVersionsAreUnavailableRefreshToReviewTheirCurrentState =>
      '충돌 버전을 사용할 수 없습니다. 새로 고쳐 현재 상태를 검토하세요.';

  @override
  String get gitUiResultSavedToDiskTheIndexStillDeterminesWhetherThis =>
      '결과를 디스크에 저장했습니다. 파일의 해결 여부는 여전히 인덱스로 판단합니다.';

  @override
  String get gitUiSaveResultDraft => '결과 초안 저장';

  @override
  String get gitUiApplyResultAndStageResolution => '결과 적용 및 해결 스테이징';

  @override
  String get gitUiResultEditableUTF8WorkingContent => '결과 · 편집 가능한 UTF-8 작업 내용';

  @override
  String get gitUiEditableConflictResult => '편집 가능한 충돌 결과';

  @override
  String gitUiLeftArg0Arg1RightArg2Arg3(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return '왼쪽: $arg0 · $arg1\n오른쪽: $arg2 · $arg3';
  }

  @override
  String get gitUiChooseContentDeletionOrASubmoduleCommitExplicitlyNoBinary =>
      '내용, 삭제 또는 서브모듈 커밋을 명시적으로 선택하세요. 바이너리 데이터를 편집 가능한 텍스트로 해석하지 않습니다.';

  @override
  String get gitUiUseEntireLeftContent => '왼쪽 내용 전체 사용…';

  @override
  String get gitUiUseEntireRightContent => '오른쪽 내용 전체 사용…';

  @override
  String get gitUiDeleteThisPath => '이 경로 삭제…';

  @override
  String get gitUiResolvedSubmoduleCommit => '해결된 서브모듈 커밋';

  @override
  String get gitUiStageThisExactGitlinkInTheParentThisDoesNot =>
      '이 정확한 gitlink를 상위에서 스테이징합니다. 서브모듈을 체크아웃하거나 커밋하지 않습니다.';

  @override
  String get gitUiSetResolvedGitlink => '해결된 gitlink 설정…';

  @override
  String gitUiBaseStageArg0(String arg0) {
    return '기준 → 스테이지 $arg0';
  }

  @override
  String get gitUiTheResultWasEditedKeepTheManualResultOrSelect =>
      '결과가 편집되었습니다. 수동 결과를 유지하거나 다른 변경되지 않은 영역을 선택하세요.';

  @override
  String gitUiApplyArg0Resolution(String arg0) {
    return '‘$arg0’ 해결을 적용할까요?';
  }

  @override
  String get gitUiStageTheChosenGitlinkCommitInTheParentTheSubmodule =>
      '선택한 gitlink 커밋을 상위에서 스테이징합니다. 서브모듈 체크아웃과 파일은 대체하지 않습니다.';

  @override
  String gitUiReplacesTheEntireWorkingPathArg0AndStagesTheDecision(
    String arg0,
  ) {
    return '작업 경로 $arg0 전체를 대체하고 결정을 스테이징합니다. 현재 작업 내용과 저장하지 않은 결과 초안을 버립니다.';
  }

  @override
  String get gitUiApplyEntireFileDecision => '전체 파일 결정 적용';

  @override
  String get gitUiStageThisConflictResolution => '이 충돌 해결을 스테이징하시겠습니까?';

  @override
  String gitUiUseTheEntireEditedResultAsArg0GitRecordsThe(
    String arg0,
    String arg1,
  ) {
    return '편집한 결과 전체를 $arg0(으)로 사용합니다. Git은 스테이징할 때 경로가 해결되었다고 기록합니다. 먼저 의도한 모든 내용을 검토하세요.$arg1';
  }

  @override
  String get gitUiApplyAndStage => '적용 및 스테이징';

  @override
  String get gitUiReviewResultTextFormatChanges => '결과 텍스트 형식 변경 검토';

  @override
  String get gitUiSaveReviewedResult => '검토한 결과 저장';

  @override
  String
  get gitUiNativeGitTableAccessibilityIsUnavailableRetryAfterReconnectingThe =>
      '네이티브 Git 표 접근성을 사용할 수 없습니다. 앱을 다시 연결한 후 재시도하세요.';

  @override
  String get gitUiSans => '고딕체';

  @override
  String get gitUiSelect => '선택';

  @override
  String get gitUiContextMenu => '상황에 맞는 메뉴';

  @override
  String get gitUiCopyText => '텍스트 복사';

  @override
  String get gitUiLoadingRow => '행 불러오는 중';

  @override
  String get gitUiRetry => '다시 시도';

  @override
  String get gitUiGitMessage => 'Git 메시지';

  @override
  String get gitUiCancelPrompt => '프롬프트 취소';

  @override
  String get gitUiUseMessageAndContinue => '메시지 사용 후 계속';

  @override
  String get gitUiRespondPrivately => '비공개로 응답';

  @override
  String gitUiViewPreferencesCouldNotBeSavedArg0(String arg0) {
    return '보기 환경설정을 저장하지 못했습니다: $arg0';
  }

  @override
  String gitUiCommitDraftStorageArg0(String arg0) {
    return '커밋 초안 저장소: $arg0';
  }

  @override
  String gitUiViewPreferencesCouldNotBeReadArg0(String arg0) {
    return '보기 환경설정을 읽지 못했습니다: $arg0';
  }

  @override
  String gitUiCommitDraftWasRetainedInMemoryButCouldNotBe(String arg0) {
    return '커밋 초안이 메모리에 유지되지만 저장하지 못했습니다: $arg0';
  }

  @override
  String get gitUiTheReviewedRepositoryIsReadOnlyForThisOperationHistory =>
      '검토한 저장소는 이 작업에 대해 읽기 전용입니다. 기록과 내용 검토는 사용할 수 있습니다.';

  @override
  String gitUiGitReturnedArg0TheApplicationCouldNotRefreshItsDocuments(
    String arg0,
    String arg1,
  ) {
    return 'Git이 $arg0을(를) 반환했습니다. 앱이 문서를 새로 고치지 못했습니다: $arg1';
  }

  @override
  String get gitUiSelectCommitInLog => '로그에서 커밋 선택…';

  @override
  String get gitUiCurrentBranch => '현재 브랜치';

  @override
  String get gitUiNoMatchingBranchesOrTagsSelectACommitInLog =>
      '일치하는 브랜치나 태그가 없습니다. 로그에서 커밋을 선택하세요.';

  @override
  String get gitUiBranches => '브랜치';

  @override
  String get gitUiPushCommits => '커밋 푸시';

  @override
  String gitUiPullIntoArg0(String arg0) {
    return '$arg0(으)로 풀';
  }

  @override
  String gitUiResolveArg0(String arg0) {
    return '$arg0 해결';
  }

  @override
  String get gitUiCurrentOperation => '현재 작업';

  @override
  String get gitUiRebaseCommits => '커밋 리베이스';

  @override
  String get gitUiFetch2 => '가져오기…';

  @override
  String get gitUiPull => '풀…';

  @override
  String get gitUiPush2 => '푸시…';

  @override
  String get gitUiBranches2 => '브랜치…';

  @override
  String get gitUiManageRemotes => '원격 저장소 관리…';

  @override
  String gitUiMergeIntoArg0(String arg0) {
    return '$arg0(으)로 병합…';
  }

  @override
  String get gitUiRebase2 => '리베이스…';

  @override
  String get gitUiConflictsAndCurrentOperation => '충돌 및 현재 작업…';

  @override
  String get gitUiStashes2 => '스태시…';

  @override
  String get gitUiWorktrees => '작업 트리…';

  @override
  String get gitUiSubmodules => '서브모듈…';

  @override
  String get gitUiReflogAndRecovery => 'Reflog 및 복구…';

  @override
  String get gitUiCloneRepository => '저장소 복제…';

  @override
  String get gitUiRevokeRepositoryTrust => '저장소 신뢰 취소';

  @override
  String get gitUiWaitingForRepositoryStatus => '저장소 상태를 기다리는 중';

  @override
  String get gitUiRepositoryStatusUnavailableRefresh =>
      '저장소 상태를 확인할 수 없습니다. 새로 고치세요';

  @override
  String get gitUiManageRemotes2 => '원격 저장소 관리';

  @override
  String gitUiMergeIntoArg02(String arg0) {
    return '$arg0(으)로 병합';
  }

  @override
  String get gitUiWorktrees2 => '작업 트리';

  @override
  String get gitUiSubmodules2 => '서브모듈';

  @override
  String get gitUiReflogAndRecovery2 => 'Reflog 및 복구';

  @override
  String gitUiCloneRepositoryArg0(String arg0) {
    return '저장소 복제 · $arg0';
  }

  @override
  String get gitUiApply => '적용';

  @override
  String get gitUiResizeGitPanes => 'Git 창 크기 조정';

  @override
  String gitUiArg0Percent(String arg0) {
    return '$arg0퍼센트';
  }

  @override
  String gitUiExitStatusStatus(String status) {
    return '종료 상태: $status';
  }

  @override
  String get gitUiRepositoryChangedRefreshAndReviewBeforeTryingAgain =>
      '저장소가 변경되었습니다. 다시 시도하기 전에 새로 고치고 검토하세요.';

  @override
  String get gitUiAnotherOperationHoldsTheRepositoryOrIndexLockWaitThen =>
      '다른 작업이 저장소 또는 인덱스 잠금을 보유하고 있습니다. 기다린 후 새로 고치세요.';

  @override
  String get gitUiRepositoryTrustIsRequiredForThisOperation =>
      '이 작업에는 저장소 신뢰가 필요합니다.';

  @override
  String get gitUiTheGitServiceDisconnectedReconnectAndReconcileTheRepository =>
      'Git 서비스 연결이 끊어졌습니다. 다시 연결하고 저장소 상태를 확인하세요.';

  @override
  String
  get gitUiTheInstalledGitExecutableCannotSupportThisOperationReviewIts =>
      '설치된 Git 실행 파일은 이 작업을 지원하지 않습니다. 아래 실행 환경 요구 사항을 검토하세요.';

  @override
  String get gitUiThisRepositoryIsReadOnlyForTheRequestedOperationReview =>
      '이 저장소는 요청한 작업에 대해 읽기 전용입니다. 검토와 기록은 사용할 수 있습니다.';

  @override
  String
  get gitUiTheOperationNeedsReconciliationReviewTheResultingRepositoryOrRemote =>
      '작업 상태를 확인해야 합니다. 반복하기 전에 결과 저장소 또는 원격 상태를 검토하세요.';

  @override
  String get gitUiGitAuthenticationFailedReviewTheCredentialHelperOrUnlockThe =>
      'Git 인증에 실패했습니다. 자격 증명 도우미를 검토하거나 구성된 키 모음의 잠금을 해제하세요.';

  @override
  String get gitUiSshHostVerificationFailedReviewTheHostIdentityThroughYour =>
      'SSH 호스트 확인에 실패했습니다. 구성된 SSH 도구로 호스트 신원을 검토하세요.';

  @override
  String get gitUiCommitSigningFailedOrWasCancelledReviewTheSigningKey =>
      '커밋 서명에 실패했거나 취소되었습니다. 서명 키, 에이전트 및 구성된 서명 도구를 검토하세요.';

  @override
  String get gitUiSetARepositoryAuthorNameAndEmailThenReturnTo =>
      '저장소 작성자 이름과 이메일을 설정한 후 보존된 메시지 초안으로 돌아가세요.';

  @override
  String get gitUiGitRejectedTheReviewedUpdateRefreshAndReviewTheActual =>
      'Git이 검토한 업데이트를 거부했습니다. 다시 시도하기 전에 새로 고치고 실제 대상을 검토하세요.';

  @override
  String get gitUiWorkingOrStagedChangesPreventThisOperationReviewCommitOr =>
      '작업 또는 스테이징된 변경으로 이 작업이 차단됩니다. 검토, 커밋하거나 명시적으로 스태시하세요.';

  @override
  String get gitUiARequiredGitObjectIsUnavailableReviewShallowOrPartial =>
      '필요한 Git 객체를 사용할 수 없습니다. 얕은/부분 저장소 경계를 검토하고 필요하면 명시적으로 가져오세요.';

  @override
  String gitUiGitOperationFailedArg0(String arg0) {
    return 'Git 작업 실패: $arg0';
  }

  @override
  String get gitUiDiagnostics => '진단 정보';

  @override
  String get gitUiAuthorizeGitInspection => 'Git 검사 승인…';

  @override
  String get gitUiCopyDiagnostics => '진단 정보 복사';

  @override
  String get gitUiActions => '작업';

  @override
  String gitUiBranchAtArg0(String arg0) {
    return '$arg0에서 브랜치 생성';
  }

  @override
  String get gitUiCreatesALocalBranchWithoutCheckingItOut =>
      '체크아웃하지 않고 로컬 브랜치를 만듭니다.';

  @override
  String gitUiTagArg0(String arg0) {
    return '$arg0에서 태그 생성';
  }

  @override
  String gitUiReadOnlySnapshotArg0(String arg0) {
    return '읽기 전용 스냅샷 · $arg0';
  }

  @override
  String get gitUiCherryPickCommits => '커밋 체리픽';

  @override
  String get gitUiRevertCommits => '커밋 되돌리기';

  @override
  String get gitUiCompareToFullRevisionID => '전체 리비전 ID와 비교';

  @override
  String gitUiTreeComparisonDirectionArg0TheRevisionEnteredHere(String arg0) {
    return '트리 비교 방향: $arg0 → 여기에 입력한 리비전.';
  }

  @override
  String get gitUiEnterAFullValidObjectID => '유효한 전체 객체 ID를 입력하세요.';

  @override
  String gitUiArg0Arg1TreeComparison(String arg0, String arg1) {
    return '$arg0 → $arg1 · 트리 비교';
  }

  @override
  String gitUiResetArg0ToArg1(String arg0, String arg1) {
    return '$arg0을(를) $arg1(으)로 재설정';
  }

  @override
  String
  get gitUiMovesHEADCurrentBranchReflogDoesNotRecoverArbitraryUntracked =>
      'HEAD/현재 브랜치를 이동합니다. reflog는 임의의 추적되지 않거나 저장되지 않은 내용을 복구하지 못합니다.';

  @override
  String get gitUiMoveHEADKeepIndexAndWorkingFiles =>
      'HEAD를 이동하고 인덱스와 작업 파일은 유지합니다.';

  @override
  String get gitUiMoveHEADAndReplaceIndexKeepWorkingFiles =>
      'HEAD를 이동하고 인덱스를 바꾸며 작업 파일은 유지합니다.';

  @override
  String
  get gitUiReplaceHEADIndexAndTrackedWorkingFilesMayOverwriteObstructing =>
      'HEAD, 인덱스, 추적 중인 작업 파일을 바꿉니다. 방해가 되는 추적되지 않는 파일은 덮어쓸 수 있습니다.';

  @override
  String get gitUiReplaceHEADIndexAndEligibleFilesRefuseIfLocalChanges =>
      'HEAD, 인덱스, 해당 파일을 바꿉니다. 로컬 변경이 손실되면 작업을 거부합니다.';

  @override
  String gitUiResetWithArg0(String arg0) {
    return '$arg0(으)로 재설정하시겠습니까?';
  }

  @override
  String gitUiArg0Arg1ReviewTheSelectedModeSEffectsBeforeApplying(
    String arg0,
    String arg1,
  ) {
    return '$arg0 → $arg1\n적용하기 전에 선택한 모드의 효과를 검토하세요.';
  }

  @override
  String gitUiResetArg0(String arg0) {
    return '$arg0 재설정';
  }

  @override
  String gitUiTargetArg0(String arg0) {
    return '대상 $arg0';
  }

  @override
  String get gitUiTagName => '태그 이름';

  @override
  String get gitUiAnnotatedTag => '주석 태그';

  @override
  String get gitUiCryptographicSigning => '암호학적 서명';

  @override
  String get gitUiConfiguredPolicy => '구성된 정책';

  @override
  String get gitUiSignThisTag => '이 태그에 서명';

  @override
  String get gitUiDoNotSign => '서명하지 않음';

  @override
  String get gitUiTagMessage => '태그 메시지';

  @override
  String get gitUiCreatesTheTagLocallyPublishSelectedTagsExplicitlyInPush =>
      '태그를 로컬에 만듭니다. 선택한 태그는 푸시 검토에서 명시적으로 게시하세요.';

  @override
  String gitUiCompleteTreesArg0Arg1(String arg0, String arg1) {
    return '전체 트리: $arg0 → $arg1';
  }

  @override
  String get gitUiNextChangedFilePage => '다음 변경 파일 페이지';

  @override
  String get gitUiReadOnlyRepositorySnapshotOpeningAFileNeverChecksOut =>
      '읽기 전용 저장소 스냅샷입니다. 파일을 열어도 이 리비전을 체크아웃하지 않습니다.';

  @override
  String get gitUiOpenReadOnlyVersion => '읽기 전용 버전 열기';

  @override
  String get gitUiRestoreThisPathWaitingForRepositoryStatus =>
      '이 경로 복원… · 저장소 상태를 기다리는 중';

  @override
  String get gitUiRestoreThisPath => '이 경로 복원…';

  @override
  String gitUiHistoryArg0(String arg0) {
    return '기록 · $arg0';
  }

  @override
  String gitUiRestoreArg0(String arg0) {
    return '$arg0을(를) 복원하시겠습니까?';
  }

  @override
  String gitUiReplaceThisWorkingPathWithRevisionArg0ExistingStagedContent(
    String arg0,
  ) {
    return '이 작업 경로를 리비전 $arg0(으)로 대체합니다. 기존 스테이징된 내용은 유지됩니다.';
  }

  @override
  String get gitUiRestoreWorkingFile => '작업 파일 복원';

  @override
  String gitUiFileHistoryFollowsRenamesArg0(String arg0) {
    return '이름 변경을 따르는 파일 기록 · $arg0';
  }

  @override
  String get gitUiBlameCommittedContent => '줄 이력 · 커밋된 내용';

  @override
  String get gitUiBlame => '줄 이력…';

  @override
  String gitUiArg0WorkingTree(String arg0) {
    return '$arg0 → 작업 트리';
  }

  @override
  String get gitUiOpenReadOnlyHistoricalFile => '읽기 전용 과거 파일 열기';

  @override
  String get gitUiCompareToCurrentFile => '현재 파일과 비교';

  @override
  String get gitUiCompareToParent => '부모와 비교…';

  @override
  String gitUiCommittedArg0UnsavedEditorContentIsNotPartOfThese(String arg0) {
    return '커밋된 $arg0 · 저장되지 않은 편집기 내용은 이 주석에 포함되지 않습니다';
  }

  @override
  String gitUiHistoryFromArg0(String arg0) {
    return '$arg0부터의 기록';
  }

  @override
  String get gitUiBoundary => ' · 경계';

  @override
  String gitUiArg0Arg1OriginalLineArg2Arg3(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return '$arg0  $arg1\n원래 줄 $arg2$arg3';
  }

  @override
  String get gitUiPreviousLines => '이전 행';

  @override
  String get gitUiNextLines => '다음 행';

  @override
  String gitUiExplicitApplicationOrderDestinationArg0(String arg0) {
    return '명시적 적용 순서 · 대상 $arg0';
  }

  @override
  String get gitUiAddFullCommitObjectID => '전체 커밋 객체 ID 추가';

  @override
  String get gitUiAddReviewedCommit => '검토한 커밋 추가…';

  @override
  String get gitUiMoveEarlier => '앞으로 이동';

  @override
  String get gitUiMoveLater => '뒤로 이동';

  @override
  String get gitUiRemoveFromReviewedSequence => '검토한 순서에서 제거';

  @override
  String get gitUiApplyChangesWithoutCreatingCommits => '커밋을 만들지 않고 변경 적용';

  @override
  String get gitUiUseThisExplicitMainlineParentForMergeCommits =>
      '병합 커밋에 이 명시적 메인라인 부모 사용';

  @override
  String get gitUiEmptyOrAlreadyAppliedCommitsMayStopGitForAn =>
      '비어 있거나 이미 적용된 커밋으로 Git이 중지되어 명시적으로 건너뛰기 또는 계속을 결정해야 할 수 있습니다.';

  @override
  String get gitUiRevertInReviewedOrder => '검토한 순서로 되돌리기';

  @override
  String get gitUiCherryPickInReviewedOrder => '검토한 순서로 체리픽';

  @override
  String get gitUiReturnToFiles => '파일로 돌아가기';

  @override
  String get gitUiGit => 'Git';

  @override
  String get gitUiCommit => '커밋';

  @override
  String get gitUiBackToCommit => '커밋으로 돌아가기';

  @override
  String get gitUiSelectAChangeToReview => '검토할 변경 선택';

  @override
  String get gitUiLoadingBranch => '브랜치 불러오는 중…';

  @override
  String get gitUiBranchUnavailable => '브랜치를 사용할 수 없습니다';

  @override
  String get gitUiUnbornHEAD => '커밋 없는 HEAD';

  @override
  String gitUiDetachedHEADRevision(String revision) {
    return '분리된 HEAD · $revision';
  }

  @override
  String get gitUiContinueAction => '계속';

  @override
  String get gitUiPick => '선택 적용';

  @override
  String get gitUiReword => '메시지 변경';

  @override
  String get gitUiEdit => '편집';

  @override
  String get gitUiSquash => '스쿼시';

  @override
  String get gitUiFixup => '메시지 없이 합치기';

  @override
  String get gitUiDrop => '제외';

  @override
  String get gitUiAbort => '중단';

  @override
  String get gitUiSkip => '건너뛰기';

  @override
  String get gitUiQuit => '작업 관리 종료';

  @override
  String get gitUiSoft => '소프트';

  @override
  String get gitUiMixed => '혼합';

  @override
  String get gitUiHard => '하드';

  @override
  String get gitUiKeep => '유지';

  @override
  String get gitUiCreate => '만들기';

  @override
  String get gitUiApplyStash => '스태시 적용';

  @override
  String get gitUiPopStash => '적용 후 성공 시 스태시 삭제';

  @override
  String get gitUiDropStashAction => '스태시 삭제';

  @override
  String get gitUiEditedResult => '편집한 결과';

  @override
  String get gitUiLeftContent => '왼쪽 내용';

  @override
  String get gitUiRightContent => '오른쪽 내용';

  @override
  String get gitUiDeletePath => '경로 삭제';

  @override
  String get gitUiSubmoduleCommit => '서브모듈 커밋';

  @override
  String get gitUiPresentContent => '사용 가능한 내용';

  @override
  String get gitUiAbsentContent => '없음';

  @override
  String get gitUiBinaryContent => '바이너리 내용';

  @override
  String get gitUiTooLargeContent => '내용이 표시 한도를 초과합니다';

  @override
  String get gitUiUnavailableContent => '사용할 수 없는 내용';

  @override
  String get gitUiGitlinkContent => '서브모듈 포인터';

  @override
  String get gitUiSymlinkContent => '심볼릭 링크';

  @override
  String get gitUiNoOperation => '작업 없음';

  @override
  String get gitUiCherryPickOperation => '체리픽';

  @override
  String get gitUiRevertOperation => '되돌리기 커밋';

  @override
  String get gitUiApplyMailboxOperation => '패치 적용';

  @override
  String get gitUiSquashOperation => '스쿼시 병합';

  @override
  String get gitUiUnmergedOperation => '병합되지 않은 인덱스';

  @override
  String get gitUiWaitingForPromptPhase => '응답을 기다리는 중';

  @override
  String get gitUiStoppedPhase => '검토를 위해 중지됨';

  @override
  String get gitUiCompletedPhase => '완료';

  @override
  String get gitUiFailedPhase => '실패';

  @override
  String get gitUiCancelledPhase => '취소됨';

  @override
  String get gitUiUncertainPhase => '결과 확인 필요';

  @override
  String gitUiStageVersion(String stage) {
    return '충돌 스테이지 $stage';
  }

  @override
  String get gitUiGitMergePreview => 'Git 병합 미리 보기';

  @override
  String get gitUiNormalizedWorking => '작업 트리 · Git으로 정규화됨';

  @override
  String gitUiPercentValue(String value) {
    return '$value퍼센트';
  }

  @override
  String gitUiOperationActionQuestion(String action, String operation) {
    return '$operation · $action하시겠습니까?';
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
  String get gitUiUtf8Bom => '바이트 순서 표시(BOM)가 있는 UTF-8';

  @override
  String get gitUiUtf8NoBom => '바이트 순서 표시(BOM)가 없는 UTF-8';

  @override
  String get gitUiAddsBom => '이 편집은 파일 시작 부분에 UTF-8 바이트 순서 표시(BOM)를 추가합니다.';

  @override
  String get gitUiRemovesBom => '이 편집은 파일 시작 부분의 UTF-8 바이트 순서 표시(BOM)를 제거합니다.';

  @override
  String get gitUiNoLineTerminators => '줄 종료 문자 없음';

  @override
  String gitUiLineEndings(String format) {
    return '$format 줄바꿈';
  }

  @override
  String gitUiMixedLineEndings(String formats) {
    return '혼합 줄 바꿈($formats)';
  }

  @override
  String gitUiNoFinalLf(String format) {
    return '$format · 마지막 LF 없음';
  }

  @override
  String gitUiLineEndingChange(String before, String after) {
    return '줄 바꿈 형식이 $before에서 $after(으)로 변경됩니다. 클립보드 텍스트는 원본 파일과 다른 줄 바꿈을 사용할 수 있습니다.';
  }

  @override
  String get gitUiGitFailure => 'Git 작업에 실패했습니다. 아래 진단 정보를 검토하세요.';

  @override
  String get gitUiAbortInline => '중단';

  @override
  String get gitUiSkipInline => '건너뛰기';

  @override
  String get gitUiQuitInline => '관리 종료';

  @override
  String get gitUiMergeInline => '병합';

  @override
  String get gitUiRebaseInline => '리베이스';

  @override
  String get gitUiCherryPickInline => '체리픽';

  @override
  String get gitUiRevertInline => '되돌리기 커밋';

  @override
  String get gitUiApplyMailboxInline => '메일박스 패치 적용';

  @override
  String get gitUiSquashInline => '스쿼시';

  @override
  String get gitUiUnmergedInline => '병합되지 않음';

  @override
  String get gitHostFetch => '가져오기';

  @override
  String get gitHostRefreshGitStatus => 'Git 상태 새로 고침';

  @override
  String get gitHostCommitStaged => '스테이징된 내용 커밋';

  @override
  String get gitHostGitBranches => 'Git 브랜치';

  @override
  String get gitHostReviewPush => '푸시 검토';

  @override
  String get gitHostGit => 'Git';

  @override
  String get gitHostGitOperationsApplyToThisEntireRepositoryAndMay =>
      'Git 작업은 전체 저장소에 적용되며 구성된 훅, 필터, 자격 증명 및 서명 도구를 실행할 수 있습니다.';

  @override
  String get gitHostContentUnavailable => '내용을 사용할 수 없습니다';

  @override
  String get gitHostInitializeRepository => '저장소 초기화';

  @override
  String get gitHostCloneRepository => '저장소 복제';

  @override
  String get gitHostInitializeHere => '여기에 초기화…';

  @override
  String get gitHostCloneRepository2 => '저장소 복제…';

  @override
  String get gitHostGitLog => 'Git 로그';

  @override
  String get gitUiAbsentPlaceholder => '(없음)';

  @override
  String get gitUiUnborn => '첫 커밋 이전';

  @override
  String gitUiRebasedHistoryRevision(String revision) {
    return '리베이스된 이력 · $revision';
  }

  @override
  String gitUiCurrentHistoryRevision(String revision) {
    return '현재 이력 · $revision';
  }

  @override
  String gitUiReplayedCommitRevision(String revision) {
    return '재적용되는 커밋 · $revision';
  }

  @override
  String gitUiIncomingContentRevision(String revision) {
    return '들어오는 내용 · $revision';
  }

  @override
  String get gitUiContentConflict => '내용 충돌';

  @override
  String get gitUiSubmoduleConflict => '서브모듈 충돌';

  @override
  String get gitUiSymlinkConflict => '심볼릭 링크 충돌';

  @override
  String get gitUiAddAddConflict => '양쪽에서 추가됨';

  @override
  String get gitUiModifyDeleteConflict => '수정/삭제 또는 이름 변경/삭제';

  @override
  String gitUiConflictIdentity(String path, String kind) {
    return '$path · $kind';
  }
}
