// ignore_for_file: text_direction_code_point_in_literal, text_direction_code_point_in_comment

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'BusyMark';

  @override
  String get appSubtitle =>
      'Trình biên tập tệp Markdown và các dự án tài liệu tương thích với Writerside.';

  @override
  String get aboutBusyMark => 'Giới thiệu BusyMark';

  @override
  String get aboutTagline => 'Trình biên tập Markdown và Writerside';

  @override
  String get aboutLicenseLabel => 'Giấy phép';

  @override
  String get aboutLicenseName => 'Apache License 2.0';

  @override
  String get aboutWebsite => 'Trang web';

  @override
  String get aboutSourceCode => 'Mã nguồn';

  @override
  String get reportIssue => 'Báo cáo sự cố';

  @override
  String get feedbackCategory => 'Danh mục';

  @override
  String get feedbackChooseCategory => 'Chọn một danh mục';

  @override
  String get feedbackCategoryProblem => 'Vấn đề hoặc lỗi';

  @override
  String get feedbackCategoryFeature => 'Đề xuất tính năng';

  @override
  String get feedbackCategoryPrivacySecurity =>
      'Mối lo ngại về quyền riêng tư hoặc bảo mật';

  @override
  String get feedbackCategoryUsability => 'Mối lo ngại về khả năng sử dụng';

  @override
  String get feedbackCategoryOther => 'Khác';

  @override
  String get feedbackSubject => 'Chủ đề';

  @override
  String get feedbackMessage => 'Nội dung chi tiết';

  @override
  String get feedbackReplyEmail => 'Email nhận phản hồi (tùy chọn)';

  @override
  String get feedbackIncludeTechnicalDetails => 'Bao gồm thông tin kỹ thuật';

  @override
  String get feedbackTechnicalDetailsDisclosure =>
      'Khi bật, tùy chọn này chỉ thêm phiên bản hệ điều hành Linux và ngôn ngữ của ứng dụng BusyMark. Không có nhật ký, tệp, dữ liệu tài khoản hoặc thông tin chẩn đoán nào khác được đính kèm.';

  @override
  String get feedbackSubmit => 'Gửi';

  @override
  String get feedbackSubmitting => 'Đang gửi…';

  @override
  String get feedbackCategoryRequired => 'Hãy chọn một danh mục.';

  @override
  String get feedbackSubjectLength => 'Chủ đề phải có từ 3 đến 120 ký tự.';

  @override
  String get feedbackMessageLength => 'Nội dung phải có từ 10 đến 5.000 ký tự.';

  @override
  String get feedbackReplyEmailInvalid =>
      'Nhập địa chỉ email hợp lệ hoặc để trống trường này.';

  @override
  String get feedbackConnectionFailure =>
      'BusyMark không thể kết nối. Hãy kiểm tra kết nối Internet rồi thử lại.';

  @override
  String get feedbackTimeoutFailure =>
      'Yêu cầu đã hết thời gian chờ. Hãy thử lại.';

  @override
  String get feedbackRateLimitedFailure =>
      'Quá nhiều báo cáo đã được gửi từ kết nối này. Hãy chờ rồi thử lại.';

  @override
  String get feedbackRejectedFailure =>
      'Máy chủ đã từ chối báo cáo này. Hãy kiểm tra các trường trong biểu mẫu rồi thử lại.';

  @override
  String get feedbackServerFailure =>
      'Máy chủ không thể tiếp nhận báo cáo. Hãy thử lại sau.';

  @override
  String feedbackSuccess(String id) {
    return 'Đã gửi phản hồi. Mã tham chiếu: $id';
  }

  @override
  String get advanced => 'Nâng cao';

  @override
  String get addToGit => 'Thêm vào Git';

  @override
  String get appearance => 'Giao diện';

  @override
  String get apply => 'Áp dụng';

  @override
  String get back => 'Quay lại';

  @override
  String get bottomLeft => 'Dưới cùng bên trái';

  @override
  String get bottomRight => 'Dưới cùng bên phải';

  @override
  String get cancel => 'Hủy';

  @override
  String get choose => 'Chọn';

  @override
  String get chooseLocation => 'Chọn vị trí';

  @override
  String get copy => 'Sao chép';

  @override
  String get copyName => 'Sao chép tên';

  @override
  String get copyFileName => 'Sao chép tên tệp';

  @override
  String get copyPath => 'Sao chép đường dẫn';

  @override
  String get create => 'Tạo';

  @override
  String get creating => 'Đang tạo…';

  @override
  String get cut => 'Cắt';

  @override
  String get promoteSection => 'Đưa phần lên một cấp';

  @override
  String get demoteSection => 'Đưa phần xuống một cấp';

  @override
  String get moveSectionUp => 'Di chuyển phần lên trên';

  @override
  String get moveSectionDown => 'Di chuyển phần xuống dưới';

  @override
  String get confirmDeleteSectionTitle => 'Xóa phần này?';

  @override
  String confirmDeleteSectionMessage(String name) {
    return 'Xóa “$name” và toàn bộ nội dung trong phần này? Không thể hoàn tác.';
  }

  @override
  String get darkTheme => 'Tối';

  @override
  String get delete => 'Xóa';

  @override
  String get discard => 'Loại bỏ';

  @override
  String get editor => 'Trình biên tập';

  @override
  String get file => 'Tệp';

  @override
  String get fileHistory => 'Lịch sử tệp';

  @override
  String get folder => 'Thư mục';

  @override
  String get insert => 'Chèn';

  @override
  String get keyboardShortcuts => 'Phím tắt';

  @override
  String get commandPalette => 'Bảng lệnh';

  @override
  String get commandPaletteHint => 'Nhập lệnh';

  @override
  String get commandPaletteEmpty => 'Không có lệnh phù hợp';

  @override
  String get commandUnavailableInContext =>
      'Lệnh không khả dụng trong ngữ cảnh trình biên tập hiện tại';

  @override
  String get lightTheme => 'Sáng';

  @override
  String get mainMenu => 'Menu chính';

  @override
  String get fullScreen => 'Toàn màn hình';

  @override
  String get markdown => 'Markdown';

  @override
  String get open => 'Mở';

  @override
  String get openInFiles => 'Mở trong Tệp';

  @override
  String get pathActions => 'Thao tác với đường dẫn';

  @override
  String get outline => 'Đề cương';

  @override
  String get overwrite => 'Ghi đè';

  @override
  String get paste => 'Dán';

  @override
  String get pasteWithoutFormatting => 'Dán không định dạng';

  @override
  String get reading => 'Đọc';

  @override
  String get removeFromRecent => 'Xóa khỏi mục Gần đây';

  @override
  String get recent => 'Gần đây';

  @override
  String get redo => 'Làm lại';

  @override
  String get save => 'Lưu';

  @override
  String get search => 'Tìm kiếm';

  @override
  String get selectAll => 'Chọn tất cả';

  @override
  String get settings => 'Cài đặt';

  @override
  String get source => 'Mã nguồn';

  @override
  String get split => 'Chia đôi';

  @override
  String get systemTheme => 'Hệ thống';

  @override
  String get theme => 'Chủ đề';

  @override
  String get appLanguage => 'Ngôn ngữ';

  @override
  String get systemLanguage => 'Hệ thống';

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
  String get toggleSidebar => 'Bảng điều khiển thanh bên';

  @override
  String get topLeft => 'Trên cùng bên trái';

  @override
  String get topRight => 'Trên cùng bên phải';

  @override
  String get undo => 'Hoàn tác';

  @override
  String get validate => 'Kiểm tra';

  @override
  String get validation => 'Xác thực';

  @override
  String get viewMode => 'Chế độ xem';

  @override
  String get welcome => 'Chào mừng';

  @override
  String get writerside => 'Writerside';

  @override
  String get xml => 'XML';

  @override
  String get fileTypeMarkdown => 'Markdown';

  @override
  String get fileTypeImages => 'Hình ảnh';

  @override
  String get openMarkdownFile => 'Mở tệp Markdown';

  @override
  String get markdownFileExtensions => '.md hoặc .markdown';

  @override
  String get openFolderOrWritersideProject =>
      'Mở thư mục hoặc dự án Writerside';

  @override
  String get markdownFolderOrWritersideProject =>
      'Thư mục Markdown hoặc dự án tương thích với Writerside';

  @override
  String get noOpenFile => 'Không có tệp nào đang mở';

  @override
  String get shortcutDeleteTreeItemDescription =>
      'Xóa mục Tệp đã chọn hoặc xóa chủ đề đã chọn khỏi mục lục';

  @override
  String get shortcutGroupGeneral => 'Chung';

  @override
  String get shortcutNewDocument => 'Tạo';

  @override
  String get shortcutNewDocumentDescription =>
      'Tạo tệp Markdown hoặc dự án Writerside';

  @override
  String get shortcutOpenDescription =>
      'Mở tệp Markdown, thư mục hoặc dự án Writerside';

  @override
  String get shortcutSaveDescription => 'Lưu tài liệu hiện tại';

  @override
  String get shortcutSearchDescription =>
      'Tìm kiếm trong không gian làm việc hiện tại';

  @override
  String get shortcutKeyboardShortcutsDescription =>
      'Hiển thị tham chiếu phím tắt này';

  @override
  String get shortcutMarkdownAndHtmlDescription =>
      'Mở tham chiếu Markdown và HTML';

  @override
  String get shortcutSettingsDescription => 'Mở cài đặt BusyMark';

  @override
  String get shortcutNextTab => 'Tab tiếp theo';

  @override
  String get shortcutNextTabDescription => 'Chuyển đến tab đang mở tiếp theo';

  @override
  String get shortcutPreviousTab => 'Tab trước';

  @override
  String get shortcutPreviousTabDescription =>
      'Chuyển đến tab đang mở trước đó';

  @override
  String get shortcutCloseTab => 'Đóng tab';

  @override
  String get shortcutCloseTabDescription => 'Đóng tab đang hoạt động';

  @override
  String get shortcutCloseAllTabs => 'Đóng tất cả tab';

  @override
  String get shortcutCloseAllTabsDescription => 'Đóng tất cả các tab đang mở';

  @override
  String get shortcutGroupTextEditing => 'Chỉnh sửa văn bản';

  @override
  String get shortcutSelectAllDescription =>
      'Trong chế độ Mã nguồn, chọn toàn bộ văn bản; trong chế độ Trình biên tập, nhấn hai lần để chọn mọi khối';

  @override
  String get shortcutCutDescription => 'Cắt văn bản đã chọn';

  @override
  String get shortcutCopyDescription => 'Sao chép văn bản đã chọn';

  @override
  String get shortcutPasteDescription => 'Dán từ bảng nhớ tạm';

  @override
  String get shortcutPastePlainTextDescription =>
      'Dán văn bản trong bảng nhớ tạm không định dạng';

  @override
  String get shortcutUndoDescription => 'Hoàn tác chỉnh sửa gần nhất';

  @override
  String get shortcutRedoDescription => 'Làm lại chỉnh sửa vừa hoàn tác';

  @override
  String get shortcutInsertIndentation => 'Chèn thụt lề';

  @override
  String get shortcutInsertIndentationDescription =>
      'Chèn thụt lề tại vị trí con trỏ';

  @override
  String get shortcutOutdentSource => 'Bỏ thụt lề mã nguồn';

  @override
  String get shortcutOutdentSourceDescription =>
      'Xóa một cấp thụt lề trong chế độ Mã nguồn';

  @override
  String get shortcutEscape => 'Đóng tìm kiếm hoặc xóa lựa chọn khối';

  @override
  String get shortcutEscapeDescription =>
      'Đóng tìm kiếm trong không gian làm việc hoặc xóa lựa chọn khối trong chế độ Trình biên tập';

  @override
  String get shortcutGroupFormatting => 'Định dạng';

  @override
  String get shortcutBoldDescription =>
      'Bật hoặc tắt chữ đậm cho văn bản đã chọn';

  @override
  String get shortcutItalicDescription =>
      'Bật hoặc tắt chữ nghiêng cho văn bản đã chọn';

  @override
  String get shortcutUnderlineDescription =>
      'Bật hoặc tắt gạch chân cho văn bản đã chọn';

  @override
  String get shortcutLinkDescription => 'Chèn hoặc chỉnh sửa liên kết';

  @override
  String get shortcutInlineCodeDescription =>
      'Bật hoặc tắt mã nội tuyến cho văn bản đã chọn';

  @override
  String get shortcutStrikethroughDescription =>
      'Bật hoặc tắt gạch ngang cho văn bản đã chọn';

  @override
  String get shortcutGroupBlocks => 'Khối';

  @override
  String get shortcutParagraphDescription => 'Đặt khối hiện tại thành đoạn văn';

  @override
  String get shortcutHeading1Description => 'Đặt khối hiện tại thành Tiêu đề 1';

  @override
  String get shortcutHeading2Description => 'Đặt khối hiện tại thành Tiêu đề 2';

  @override
  String get shortcutHeading3Description => 'Đặt khối hiện tại thành Tiêu đề 3';

  @override
  String get shortcutHeading4Description => 'Đặt khối hiện tại thành Tiêu đề 4';

  @override
  String get shortcutHeading5Description => 'Đặt khối hiện tại thành Tiêu đề 5';

  @override
  String get shortcutHeading6Description => 'Đặt khối hiện tại thành Tiêu đề 6';

  @override
  String get shortcutGroupLists => 'Danh sách';

  @override
  String get numberedList => 'Danh sách đánh số';

  @override
  String get shortcutNumberedListDescription =>
      'Bật hoặc tắt định dạng danh sách đánh số';

  @override
  String get bulletedList => 'Danh sách dấu đầu dòng';

  @override
  String get shortcutBulletedListDescription =>
      'Bật hoặc tắt định dạng danh sách dấu đầu dòng';

  @override
  String get checklist => 'Danh sách kiểm tra';

  @override
  String get shortcutChecklistDescription =>
      'Bật hoặc tắt định dạng danh sách kiểm tra';

  @override
  String get shortcutGroupSidebar => 'Thanh bên';

  @override
  String get sidebarViewMenu => 'Chế độ xem thanh bên';

  @override
  String get createMarkdownFile => 'Tạo tệp Markdown';

  @override
  String get createMarkdownFileDescription =>
      'Bắt đầu một tài liệu Markdown cục bộ chưa lưu';

  @override
  String get createWritersideProject => 'Tạo dự án Writerside';

  @override
  String get createWritersideProjectDescription =>
      'Bắt đầu một dự án tương thích với Writerside trên máy';

  @override
  String get defaultProjectName => 'Tài liệu';

  @override
  String get defaultInstanceName => 'Hướng dẫn sử dụng';

  @override
  String get defaultStartTopicTitle => 'Bắt đầu';

  @override
  String get projectName => 'Tên dự án';

  @override
  String get directoryName => 'Tên thư mục';

  @override
  String get instanceName => 'Tên phiên bản';

  @override
  String get instanceId => 'ID phiên bản';

  @override
  String get startTopicTitle => 'Tiêu đề chủ đề bắt đầu';

  @override
  String get location => 'Vị trí';

  @override
  String get projectNameRequired => 'Tên dự án là bắt buộc.';

  @override
  String get directoryNameRequired => 'Tên thư mục là bắt buộc.';

  @override
  String get useSingleSafeDirectoryName =>
      'Sử dụng một tên thư mục an toàn duy nhất.';

  @override
  String get useLowercaseIdentifier =>
      'Sử dụng mã định danh viết thường, chỉ gồm chữ cái, chữ số, dấu gạch dưới hoặc dấu gạch nối.';

  @override
  String get startTopicTitleRequired => 'Tiêu đề chủ đề bắt đầu là bắt buộc.';

  @override
  String get createWritersideProjectFailed => 'Không thể tạo dự án Writerside.';

  @override
  String get settingsTitle => 'Cài đặt BusyMark';

  @override
  String get autoSave => 'Tự động lưu';

  @override
  String get autoSaveDescription =>
      'Tự động lưu các thay đổi của tệp sau một khoảng thời gian ngắn không hoạt động.';

  @override
  String get wordWrap => 'Tự động xuống dòng';

  @override
  String get editorFontSize => 'Cỡ chữ trình biên tập';

  @override
  String get validateOnEdit => 'Kiểm tra khi chỉnh sửa';

  @override
  String get clearRecentWorkspaces => 'Xóa không gian làm việc gần đây';

  @override
  String get editingButtonsPosition => 'Vị trí các nút chỉnh sửa';

  @override
  String get editingButtonsPositionDescription =>
      'Chọn nơi hiển thị các nút chỉnh sửa WYSIWYG nổi.';

  @override
  String get editingButtonsDirection => 'Hướng của các nút chỉnh sửa';

  @override
  String get editingButtonsDirectionDescription =>
      'Chọn sắp xếp các nút chỉnh sửa WYSIWYG nổi theo chiều ngang hay chiều dọc.';

  @override
  String get horizontal => 'Ngang';

  @override
  String get vertical => 'Dọc';

  @override
  String get privacy => 'Quyền riêng tư';

  @override
  String get allowRemoteImages => 'Tải hình ảnh từ xa';

  @override
  String get allowRemoteImagesDescription =>
      'Cho phép hình ảnh trong phần xem trước và trình biên tập Markdown được tải từ các URL http và https.';

  @override
  String get clearRemoteImagePermissions => 'Xóa quyền hình ảnh từ xa';

  @override
  String get clearRemoteImagePermissionsDescription =>
      'Quên các không gian làm việc đã được cho phép tải hình ảnh từ xa.';

  @override
  String get clearGitWorkspaceTrust =>
      'Xóa các không gian làm việc Git đáng tin cậy';

  @override
  String get clearGitWorkspaceTrustDescription =>
      'Hỏi trước khi bật các tính năng Git cho những không gian làm việc đã từng được tin cậy.';

  @override
  String get settingsWindowSectionTitle => 'Cửa sổ';

  @override
  String get settingsReopenWorkspaceOnStartupTitle =>
      'Mở lại không gian làm việc trước đó khi khởi động';

  @override
  String get settingsReopenWorkspaceOnStartupDescription =>
      'Mở không gian làm việc và các tab từ phiên trước khi BusyMark khởi động.';

  @override
  String get settingsConfirmCloseWithUnsavedChangesTitle =>
      'Xác nhận trước khi đóng khi có thay đổi chưa lưu';

  @override
  String get settingsConfirmCloseWithUnsavedChangesDescription =>
      'Hỏi trước khi đóng BusyMark nếu tài liệu có thay đổi chưa lưu.';

  @override
  String get closeUnsavedChangesTitle => 'Thay đổi chưa lưu';

  @override
  String get closeUnsavedChangesSingleMessage =>
      'Tài liệu này có thay đổi chưa lưu. Lưu thay đổi trước khi đóng BusyMark?';

  @override
  String closeUnsavedChangesMultipleMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count tài liệu có thay đổi chưa lưu. Lưu thay đổi trước khi đóng BusyMark?',
      one:
          '1 tài liệu có thay đổi chưa lưu. Lưu thay đổi trước khi đóng BusyMark?',
      zero: 'Lưu thay đổi trước khi đóng BusyMark?',
    );
    return '$_temp0';
  }

  @override
  String get closeUnsavedChangesCancel => 'Hủy';

  @override
  String get closeUnsavedChangesDiscard => 'Loại bỏ';

  @override
  String get closeUnsavedChangesSave => 'Lưu';

  @override
  String get currentFile => 'tệp hiện tại';

  @override
  String get unsavedChanges => 'Thay đổi chưa lưu';

  @override
  String unsavedChangesMessage(String fileName) {
    return 'Bạn có thay đổi chưa lưu trong $fileName. Lưu trước khi tiếp tục?';
  }

  @override
  String unsavedChangesMultipleMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count tài liệu có thay đổi chưa lưu. Lưu các tài liệu trước khi tiếp tục?',
      one: '1 tài liệu có thay đổi chưa lưu. Lưu tài liệu trước khi tiếp tục?',
    );
    return '$_temp0';
  }

  @override
  String get fileChangedOnDisk => 'Tệp đã thay đổi trên đĩa';

  @override
  String get fileChangedOnDiskMessage =>
      'Tệp này đã thay đổi trên đĩa kể từ khi bạn mở. Ghi đè tệp?';

  @override
  String get untitledMarkdownFileName => 'Chưa có tên.md';

  @override
  String get unorderedList => 'Danh sách không có thứ tự';

  @override
  String get orderedList => 'Danh sách có thứ tự';

  @override
  String get taskList => 'Danh sách nhiệm vụ';

  @override
  String get toggleTaskChecked => 'Đánh dấu hoặc bỏ đánh dấu nhiệm vụ';

  @override
  String get indentListItem => 'Thụt lề mục danh sách';

  @override
  String get outdentListItem => 'Bỏ thụt lề mục danh sách';

  @override
  String get blockquote => 'Trích dẫn';

  @override
  String get codeBlock => 'Khối mã';

  @override
  String get codeBlockLanguage => 'Ngôn ngữ khối mã';

  @override
  String get image => 'Hình ảnh';

  @override
  String get video => 'Video';

  @override
  String get openVideo => 'Phát video';

  @override
  String get pauseVideo => 'Tạm dừng video';

  @override
  String get videoUnavailable => 'Video không khả dụng';

  @override
  String get videoPreview => 'Xem trước video';

  @override
  String get diagnosticWritersideVideoMissingSource =>
      'Video thiếu thuộc tính src.';

  @override
  String diagnosticWritersideVideoUnsupportedSource(String source) {
    return 'Nguồn video không được hỗ trợ: $source';
  }

  @override
  String diagnosticWritersideVideoMissingFile(String source) {
    return 'Tệp video không tồn tại: $source';
  }

  @override
  String diagnosticWritersideVideoMissingPreview(String preview) {
    return 'Hình ảnh xem trước video không tồn tại: $preview';
  }

  @override
  String get inlineImage => 'Hình ảnh nội tuyến';

  @override
  String get table => 'Bảng';

  @override
  String get htmlBlock => 'Khối HTML';

  @override
  String get htmlContentDefault => 'Nội dung HTML';

  @override
  String get shortcutHtmlBlockDescription => 'Chèn hoặc chỉnh sửa khối HTML';

  @override
  String get renderedHtml => 'HTML đã kết xuất';

  @override
  String get editHtml => 'Chỉnh sửa HTML';

  @override
  String get htmlSource => 'Mã nguồn HTML';

  @override
  String get thematicBreak => 'Đường phân cách';

  @override
  String get bold => 'Đậm';

  @override
  String get italic => 'Nghiêng';

  @override
  String get underline => 'Gạch chân';

  @override
  String get strikethrough => 'Gạch ngang';

  @override
  String get inlineCode => 'Mã nội tuyến';

  @override
  String get link => 'Liên kết';

  @override
  String get hardLineBreak => 'Ngắt dòng cứng';

  @override
  String get textStyle => 'Kiểu văn bản';

  @override
  String get paragraph => 'Đoạn văn';

  @override
  String get heading1 => 'Tiêu đề 1';

  @override
  String get heading2 => 'Tiêu đề 2';

  @override
  String get heading3 => 'Tiêu đề 3';

  @override
  String get heading4 => 'Tiêu đề 4';

  @override
  String get heading5 => 'Tiêu đề 5';

  @override
  String get heading6 => 'Tiêu đề 6';

  @override
  String headingLevelAbbreviation(int level) {
    return 'H$level';
  }

  @override
  String get deleteTable => 'Xóa bảng';

  @override
  String tableColumnNumber(int columnNumber) {
    return 'Cột $columnNumber';
  }

  @override
  String get insertColumnLeft => 'Chèn cột bên trái';

  @override
  String get insertColumnRight => 'Chèn cột bên phải';

  @override
  String get deleteColumn => 'Xóa cột';

  @override
  String get tableAlignmentUnspecified => 'Căn chỉnh: Chưa chỉ định';

  @override
  String get tableAlignmentLeft => 'Căn chỉnh: Trái';

  @override
  String get tableAlignmentCenter => 'Căn chỉnh: Giữa';

  @override
  String get tableAlignmentRight => 'Căn chỉnh: Phải';

  @override
  String tableRowNumber(int rowNumber) {
    return 'Hàng $rowNumber';
  }

  @override
  String get insertRowAbove => 'Chèn hàng phía trên';

  @override
  String get insertRowBelow => 'Chèn hàng phía dưới';

  @override
  String get deleteRow => 'Xóa hàng';

  @override
  String get tableHeaderHint => 'Tiêu đề';

  @override
  String get tableCellHint => 'Ô';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get hideEditingButtons => 'Ẩn các nút chỉnh sửa';

  @override
  String get showEditingButtons => 'Hiện các nút chỉnh sửa';

  @override
  String get altText => 'Văn bản thay thế';

  @override
  String get editorPlaceholderText => 'văn bản';

  @override
  String get editorPlaceholderCode => 'mã';

  @override
  String get editorPlaceholderAltText => 'văn bản thay thế';

  @override
  String get describeTheImage => 'Mô tả hình ảnh';

  @override
  String get columns => 'Cột';

  @override
  String get rows => 'Hàng';

  @override
  String tableHeaderNumber(int columnNumber) {
    return 'Tiêu đề $columnNumber';
  }

  @override
  String get tableCellDefault => 'Ô';

  @override
  String get noImageSource => 'Không có nguồn hình ảnh';

  @override
  String get remoteImageBlocked => 'Hình ảnh từ xa bị chặn';

  @override
  String get remoteImageBlockedTooltip =>
      'Chọn xem BusyMark có thể tải hình ảnh từ xa hay không.';

  @override
  String get remoteImagesBlockedTitle => 'Hình ảnh từ xa bị chặn';

  @override
  String get remoteImagesBlockedMessage =>
      'Tài liệu này tham chiếu đến hình ảnh trên Internet. Việc tải chúng có thể tiết lộ thông tin mạng cho máy chủ lưu trữ hình ảnh.';

  @override
  String get loadRemoteImagesForWorkspace => 'Tải cho không gian làm việc này';

  @override
  String get alwaysLoadRemoteImages => 'Luôn tải hình ảnh từ xa';

  @override
  String get hideSidebar => 'Ẩn bảng điều khiển thanh bên';

  @override
  String get showSidebar => 'Hiện bảng điều khiển thanh bên';

  @override
  String get showPreview => 'Hiện bản xem trước';

  @override
  String get hidePreview => 'Ẩn bản xem trước';

  @override
  String get workspaceKindUnsavedMarkdown => 'Tệp Markdown chưa lưu';

  @override
  String get workspaceKindSingleMarkdown => 'Tệp Markdown đơn';

  @override
  String get workspaceKindMarkdownFolder => 'Thư mục Markdown';

  @override
  String get workspaceKindWritersideModule => 'Mô-đun Writerside';

  @override
  String get problems => 'Vấn đề';

  @override
  String diagnosticCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chẩn đoán',
      one: '1 chẩn đoán',
      zero: 'Không có chẩn đoán',
    );
    return '$_temp0';
  }

  @override
  String get files => 'Tệp';

  @override
  String get toc => 'Mục lục';

  @override
  String get tocActions => 'Thao tác với mục lục';

  @override
  String get markdownUnsaved => 'Markdown - chưa lưu';

  @override
  String workspaceDetail(String kind, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tệp',
      one: '1 tệp',
    );
    return '$kind - $_temp0';
  }

  @override
  String get noFiles => 'Không có tệp';

  @override
  String get newFile => 'Tệp mới';

  @override
  String get noWritersideToc => 'Không có mục lục Writerside';

  @override
  String get tocSection => 'Phần mục lục';

  @override
  String get newTopic => 'Chủ đề mới';

  @override
  String get newChildTopic => 'Chủ đề con mới';

  @override
  String get newSiblingTopic => 'Chủ đề cùng cấp mới';

  @override
  String get renameTopicFile => 'Đổi tên tệp chủ đề';

  @override
  String get topicPlacement => 'Vị trí trong mục lục';

  @override
  String get tocRoot => 'Tại gốc mục lục';

  @override
  String get afterSelectedTopic => 'Sau chủ đề đã chọn';

  @override
  String get insideSelectedTopic => 'Bên trong chủ đề đã chọn';

  @override
  String get pasteAfterTopic => 'Dán sau chủ đề';

  @override
  String get pasteAsChildTopic => 'Dán làm chủ đề con';

  @override
  String get removeFromToc => 'Xóa khỏi mục lục';

  @override
  String get confirmRemoveFromTocTitle => 'Xóa khỏi mục lục?';

  @override
  String confirmRemoveFromTocMessage(String name) {
    return 'Xóa $name khỏi mục lục này? Tệp chủ đề sẽ được giữ lại.';
  }

  @override
  String get confirmDeleteTopicTitle => 'Xóa tệp chủ đề?';

  @override
  String confirmDeleteTopicMessage(String name) {
    return 'Xóa $name và xóa tệp đó khỏi mọi mục lục? Không thể hoàn tác.';
  }

  @override
  String get safeDeleteTopicFile => 'Xóa an toàn tệp chủ đề…';

  @override
  String get removeTocElement => 'Xóa phần tử mục lục';

  @override
  String get reviewUsages => 'Xem lại cách sử dụng';

  @override
  String get deleteTopicFile => 'Xóa tệp chủ đề';

  @override
  String get removeAction => 'Xóa';

  @override
  String topicRemovalSummary(String topic) {
    return 'Xóa “$topic” khỏi phiên bản đã chọn. Tệp chủ đề sẽ được giữ lại.';
  }

  @override
  String safeDeleteTopicSummary(String topic) {
    return 'Xóa “$topic” và cập nhật an toàn các tham chiếu đến tệp đó trong toàn bộ dự án Writerside này.';
  }

  @override
  String childTopicsPromoted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chủ đề con sẽ được đưa lên một cấp.',
      one: '1 chủ đề con sẽ được đưa lên một cấp.',
    );
    return '$_temp0';
  }

  @override
  String get topicIsStartPageRemovalWarning =>
      'Chủ đề này đang được dùng làm trang bắt đầu của một phiên bản. Hãy xem lại cách sử dụng và chỉ định trang bắt đầu khác trước khi tiếp tục.';

  @override
  String topicUsagesCount(int count) {
    return 'Cách sử dụng ($count)';
  }

  @override
  String get noBreakingTopicUsages =>
      'Không tìm thấy tham chiếu nào có thể bị hỏng.';

  @override
  String get topicUsagesFound =>
      'BusyMark đã tìm thấy các tham chiếu sau đến chủ đề này.';

  @override
  String get topicUsageTocElements => 'Phần tử mục lục';

  @override
  String get topicUsageStartPages => 'Trang bắt đầu';

  @override
  String get topicUsageTopicLinks => 'Liên kết chủ đề';

  @override
  String get topicUsageIncludes => 'Nội dung bao gồm';

  @override
  String usageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lượt sử dụng',
      one: '1 lượt sử dụng',
    );
    return '$_temp0';
  }

  @override
  String get refactoringOptions => 'Tùy chọn tái cấu trúc';

  @override
  String get updateUsagesAutomatically => 'Tự động cập nhật cách sử dụng';

  @override
  String get updateUsagesAutomaticallyDescription =>
      'Xóa các tham chiếu mục lục và nội dung bao gồm, đồng thời giữ nguyên văn bản liên kết.';

  @override
  String get manualUsageUpdatesRequired =>
      'Một số cách sử dụng cần được thay đổi thủ công trước khi thực hiện tái cấu trúc này.';

  @override
  String get setRedirectTo => 'Đặt chuyển hướng đến';

  @override
  String get noRedirectDescription =>
      'Không chuyển hướng trang đã xuất bản cũ.';

  @override
  String get redirectTarget => 'Đích chuyển hướng';

  @override
  String get remainingUsagesBlockRemoval =>
      'Xem lại và cập nhật các cách sử dụng còn lại trước khi tiếp tục hoặc bật cập nhật tự động nếu có.';

  @override
  String usagesOfTopic(String topic) {
    return 'Cách sử dụng $topic';
  }

  @override
  String get noUsagesFound => 'Không tìm thấy cách sử dụng nào';

  @override
  String get outsideSelectedInstance => 'bên ngoài phiên bản đã chọn';

  @override
  String get doRefactor => 'Tái cấu trúc';

  @override
  String get orphanTopicTitle => 'Tệp chủ đề không còn được sử dụng';

  @override
  String get keepTopicFile => 'Giữ tệp chủ đề';

  @override
  String orphanTopicMessage(String topic) {
    return '“$topic” không còn được sử dụng ở đâu trong dự án Writerside này. Xóa tệp hoặc giữ lại để dùng trong phiên bản khác.';
  }

  @override
  String get defaultNewTopicTitle => 'Chủ đề mới';

  @override
  String get topicTitle => 'Tiêu đề chủ đề';

  @override
  String get fileName => 'Tên tệp';

  @override
  String get topicTitleRequired => 'Tiêu đề chủ đề là bắt buộc.';

  @override
  String get fileNameRequired => 'Tên tệp là bắt buộc.';

  @override
  String get rename => 'Đổi tên';

  @override
  String get confirmDeleteFileTitle => 'Xóa tệp?';

  @override
  String get confirmDeleteFolderTitle => 'Xóa thư mục?';

  @override
  String confirmDeleteFileMessage(String name) {
    return 'Xóa $name? Không thể hoàn tác.';
  }

  @override
  String confirmDeleteFolderMessage(String name) {
    return 'Xóa $name và tất cả tệp bên trong? Không thể hoàn tác.';
  }

  @override
  String get useSingleSafeFileName => 'Sử dụng một tên tệp an toàn duy nhất.';

  @override
  String useExpectedExtension(String extension) {
    return 'Sử dụng phần mở rộng $extension cho định dạng đã chọn.';
  }

  @override
  String get useIdentifierCharacters =>
      'Sử dụng chữ cái, chữ số, dấu gạch dưới hoặc dấu gạch nối trước phần mở rộng.';

  @override
  String get topicIdAlreadyExists => 'ID chủ đề đã tồn tại.';

  @override
  String get createWritersideTopicFailed => 'Không thể tạo chủ đề Writerside.';

  @override
  String get noOutline => 'Không có đề cương';

  @override
  String expandKind(String kind) {
    return 'Mở rộng $kind';
  }

  @override
  String collapseKind(String kind) {
    return 'Thu gọn $kind';
  }

  @override
  String get foldKindSection => 'phần';

  @override
  String get foldKindList => 'danh sách';

  @override
  String get foldKindQuote => 'trích dẫn';

  @override
  String get foldKindTag => 'thẻ';

  @override
  String get sourceSearchPreviousMatch => 'Kết quả khớp trước';

  @override
  String get sourceSearchNextMatch => 'Kết quả khớp tiếp theo';

  @override
  String get sourceSearchCaseSensitive => 'Phân biệt chữ hoa, chữ thường';

  @override
  String get sourceSearchWholeWord => 'Toàn bộ từ';

  @override
  String get sourceSearchRegex => 'Biểu thức chính quy';

  @override
  String get sourceSearchReplacement => 'Thay thế bằng';

  @override
  String get sourceSearchReplaceCurrent => 'Thay thế kết quả hiện tại';

  @override
  String get sourceSearchReplaceAndFindNext => 'Thay thế và tìm tiếp';

  @override
  String get sourceSearchReplaceAll => 'Thay thế tất cả';

  @override
  String get workspaceReplace => 'Thay thế trong không gian làm việc';

  @override
  String get reviewReplacements => 'Xem lại các thay thế';

  @override
  String get applyReplacements => 'Áp dụng các thay thế';

  @override
  String get skippedFiles => 'Tệp bị bỏ qua';

  @override
  String get workspaceReplaceDirtyBuffer => 'Nội dung trình biên tập chưa lưu';

  @override
  String get workspaceReplaceDiskContent => 'Nội dung đã lưu trên đĩa';

  @override
  String selectFileMatches(int count) {
    return 'Chọn tất cả $count kết quả khớp';
  }

  @override
  String workspaceReplaceApplied(int matches, int files, int skipped) {
    return 'Đã thay thế $matches kết quả khớp trong $files tệp; bỏ qua $skipped.';
  }

  @override
  String documentFormatWithFinalNewline(String encoding, String lineEnding) {
    return '$encoding · $lineEnding · Có ký tự xuống dòng ở cuối';
  }

  @override
  String documentFormatWithoutFinalNewline(String encoding, String lineEnding) {
    return '$encoding · $lineEnding · Không có ký tự xuống dòng ở cuối';
  }

  @override
  String get normalizeLineEndings => 'Chuẩn hóa kết thúc dòng';

  @override
  String get mixedLineEndingsSavePrompt =>
      'Tài liệu này chứa các kiểu kết thúc dòng khác nhau. Hãy chọn một định dạng.';

  @override
  String workspaceReplaceMixedLineEndings(String fileName) {
    return '$fileName sử dụng các kiểu kết thúc dòng khác nhau. Hãy chọn định dạng sẽ dùng trước khi thay thế.';
  }

  @override
  String get workspaceReplaceIssueOversized => 'Đã bỏ qua một tệp quá lớn.';

  @override
  String get workspaceReplaceIssueUnreadable =>
      'Đã bỏ qua một tệp không thể đọc.';

  @override
  String get workspaceReplaceIssueInvalidUtf8 =>
      'Đã bỏ qua một tệp không phải UTF-8 hợp lệ.';

  @override
  String get workspaceReplaceIssueTruncated =>
      'Bản xem trước thay thế đã bị cắt bớt.';

  @override
  String get workspaceReplaceIssueFileChanged =>
      'Đã bỏ qua một tệp đã thay đổi sau khi xem trước.';

  @override
  String get workspaceReplaceIssueBufferChanged =>
      'Đã bỏ qua một bộ đệm trình biên tập đã thay đổi sau khi xem trước.';

  @override
  String get workspaceReplaceIssueNormalizationRequired =>
      'Chọn chuẩn hóa LF hoặc CRLF trước khi thay thế.';

  @override
  String get workspaceReplaceIssuePartialConflict =>
      'Đã dừng khôi phục vì tệp bị thay đổi đồng thời. Một số thay thế có thể vẫn còn; nội dung bị di dời đã được giữ lại tại đường dẫn bên dưới.';

  @override
  String get workspaceReplaceIssueApplyFailed =>
      'Không thể ghi nhận thay thế đã xem lại; không có tệp nào bị thay đổi.';

  @override
  String externalChangesTitle(String fileName) {
    return 'Thay đổi bên ngoài — $fileName';
  }

  @override
  String get externalFileDeleted => 'Tệp này đã bị xóa trên đĩa.';

  @override
  String get externalFileChanged =>
      'Tệp này đã thay đổi trên đĩa trong khi bạn có các chỉnh sửa chưa lưu.';

  @override
  String recoveredDocumentReview(String fileName) {
    return 'Đã khôi phục nội dung chưa lưu cho $fileName. Hãy kiểm tra, sau đó lưu, lưu thành hoặc loại bỏ nội dung đó.';
  }

  @override
  String get compare => 'So sánh';

  @override
  String get reloadFromDisk => 'Tải lại từ đĩa';

  @override
  String get keepMine => 'Giữ phiên bản của tôi';

  @override
  String get saveAs => 'Lưu thành';

  @override
  String get sourceSearchInvalidRegex => 'Biểu thức chính quy không hợp lệ';

  @override
  String get sourceLargeFileFeaturesPaused =>
      'Tệp lớn: đã tạm dừng tô sáng và thu gọn';

  @override
  String get nothingToRead => 'Không có nội dung để đọc';

  @override
  String get admonition => 'Khối lưu ý';

  @override
  String get quote => 'Trích dẫn';

  @override
  String get note => 'Ghi chú';

  @override
  String get tip => 'Mẹo';

  @override
  String get warning => 'Cảnh báo';

  @override
  String get tabs => 'Tab';

  @override
  String get tab => 'Tab';

  @override
  String get procedure => 'Quy trình';

  @override
  String get step => 'Bước';

  @override
  String get topic => 'Chủ đề';

  @override
  String get chapter => 'Chương';

  @override
  String couldNotOpenTarget(String target) {
    return 'Không thể mở $target';
  }

  @override
  String linkTargetNotFound(String targetPath) {
    return 'Không tìm thấy đích liên kết: $targetPath';
  }

  @override
  String get cannotOpenFileTypeInEditor =>
      'Không thể mở loại tệp này trong trình biên tập';

  @override
  String anchorNotFound(String anchor) {
    return 'Không tìm thấy neo: $anchor';
  }

  @override
  String get noProblemsFound => 'Không tìm thấy vấn đề';

  @override
  String get noResults => 'Không có kết quả';

  @override
  String searchResultLine(String relativePath, int lineNumber) {
    return '$relativePath - Dòng $lineNumber';
  }

  @override
  String get untitledResult => 'Kết quả chưa có tên';

  @override
  String get documentKindMarkdownFile => 'Tệp Markdown';

  @override
  String get documentKindWritersideMarkdownTopic =>
      'Chủ đề Markdown Writerside';

  @override
  String get documentKindWritersideXmlTopic => 'Chủ đề XML Writerside';

  @override
  String get documentKindWritersideTree => 'Cây Writerside';

  @override
  String get documentKindConfigurationFile => 'Tệp cấu hình';

  @override
  String get documentKindVariablesFile => 'Tệp biến';

  @override
  String get documentKindCategoriesFile => 'Tệp danh mục';

  @override
  String get documentKindResourceFile => 'Tệp tài nguyên';

  @override
  String workspaceErrorOpenFailed(String error) {
    return 'Mở không thành công: $error';
  }

  @override
  String workspaceErrorCreateWritersideProjectFailed(String error) {
    return 'Không thể tạo dự án Writerside: $error';
  }

  @override
  String workspaceErrorCreateWritersideTopicFailed(String error) {
    return 'Không thể tạo chủ đề Writerside: $error';
  }

  @override
  String workspaceErrorCouldNotOpenFile(String error) {
    return 'Không thể mở tệp: $error';
  }

  @override
  String get workspaceErrorChooseWhereToSaveMarkdown =>
      'Chọn nơi lưu tệp Markdown này.';

  @override
  String get workspaceErrorSaveBlockedFileChangedOnDisk =>
      'Đã chặn lưu: tệp đã thay đổi trên đĩa.';

  @override
  String workspaceErrorSaveFailed(String error) {
    return 'Lưu không thành công: $error';
  }

  @override
  String workspaceErrorFileOperationFailed(String error) {
    return 'Thao tác với tệp không thành công: $error';
  }

  @override
  String workspaceErrorValidationFailed(String error) {
    return 'Kiểm tra không thành công: $error';
  }

  @override
  String workspaceRecoveryRestored(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Đã khôi phục $count tài liệu chưa lưu. Hãy xem lại từng tài liệu trước khi lưu hoặc loại bỏ.',
      one:
          'Đã khôi phục 1 tài liệu chưa lưu. Hãy xem lại trước khi lưu hoặc loại bỏ.',
    );
    return '$_temp0';
  }

  @override
  String workspaceRecoveryDamaged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Không thể khôi phục $count bản ghi khôi phục bị hỏng. Các bản ghi khôi phục hợp lệ vẫn còn khả dụng.',
      one:
          'Không thể khôi phục một bản ghi khôi phục bị hỏng. Tệp khôi phục gốc đã được giữ lại để kiểm tra.',
    );
    return '$_temp0';
  }

  @override
  String errorPathDoesNotExist(String path) {
    return 'Đường dẫn không tồn tại: $path';
  }

  @override
  String errorTargetDirectoryNotEmpty(String path) {
    return 'Thư mục đích đã tồn tại và không trống: $path';
  }

  @override
  String errorTargetPathNotDirectory(String path) {
    return 'Đường dẫn đích đã tồn tại nhưng không phải là thư mục: $path';
  }

  @override
  String errorGeneratedFileAlreadyExists(String path) {
    return 'Tệp được tạo đã tồn tại: $path';
  }

  @override
  String get errorParentDirectoryRequired => 'Cần có thư mục cha.';

  @override
  String errorParentDirectoryMissing(String path) {
    return 'Thư mục cha không tồn tại: $path';
  }

  @override
  String errorDirectoryMissing(String path) {
    return 'Thư mục không tồn tại: $path';
  }

  @override
  String errorPathAlreadyExists(String path) {
    return 'Đường dẫn đã tồn tại: $path';
  }

  @override
  String get errorFileNameRequired => 'Tên tệp là bắt buộc.';

  @override
  String get errorFileNameUnsafe =>
      'Tên tệp phải là một phần đường dẫn an toàn duy nhất.';

  @override
  String get errorFileOperationInvalidTarget =>
      'Không thể di chuyển thư mục vào chính nó.';

  @override
  String get errorFileOperationOutsideRoot =>
      'Thao tác với tệp phải nằm trong không gian làm việc.';

  @override
  String get errorFileOperationRoot =>
      'Không thể thay đổi thư mục gốc của không gian làm việc từ cây tệp.';

  @override
  String get errorProjectNameRequired => 'Tên dự án là bắt buộc.';

  @override
  String get errorDirectoryNameRequired => 'Tên thư mục là bắt buộc.';

  @override
  String get errorDirectoryNameUnsafe =>
      'Tên thư mục phải là một phần đường dẫn an toàn duy nhất.';

  @override
  String get errorInstanceIdInvalid =>
      'ID phiên bản phải bắt đầu bằng chữ thường và chỉ gồm chữ thường, chữ số, dấu gạch dưới và dấu gạch nối.';

  @override
  String get errorTopicFileInvalid =>
      'Tên tệp chủ đề phải là tên tệp Markdown không có dấu phân cách đường dẫn.';

  @override
  String get errorTopicTitleRequired => 'Tiêu đề chủ đề là bắt buộc.';

  @override
  String errorWritersideModuleRootMissing(String path) {
    return 'Gốc mô-đun Writerside không tồn tại: $path';
  }

  @override
  String get errorWritersideModuleNotOpen =>
      'Phải mở một mô-đun Writerside để tạo chủ đề.';

  @override
  String get errorWritersideInstanceTreeMissing =>
      'Mô-đun Writerside không có cây phiên bản.';

  @override
  String errorWritersideTreeFileMissing(String path) {
    return 'Tệp cây Writerside không tồn tại: $path';
  }

  @override
  String errorTopicIdAlreadyExists(String topicId) {
    return 'ID chủ đề \"$topicId\" đã tồn tại trong mô-đun trợ giúp này.';
  }

  @override
  String errorTopicFileAlreadyExists(String path) {
    return 'Tệp chủ đề đã tồn tại: $path';
  }

  @override
  String errorReferenceTopicMissing(String topic) {
    return 'Chủ đề tham chiếu không có trong cây đã chọn: $topic';
  }

  @override
  String get errorWritersideTocNodeMissing =>
      'Mục nhập mục lục đã chọn không còn tồn tại.';

  @override
  String get errorWritersideTocInvalidMove =>
      'Không thể di chuyển mục nhập mục lục vào chính nó hoặc một mục con của nó.';

  @override
  String errorWritersideStartTopicDelete(String topic) {
    return 'Không thể xóa chủ đề bắt đầu $topic. Hãy chọn một trang bắt đầu khác trước.';
  }

  @override
  String get errorWritersideSafeDeleteRequired =>
      'Sử dụng Xóa an toàn cho các tệp chủ đề Writerside.';

  @override
  String get errorWritersideTopicUsageScanFailed =>
      'Không thể hoàn tất quá trình quét cách sử dụng chủ đề. Không có tệp nào bị thay đổi.';

  @override
  String get errorWritersideTopicUsagesRemain =>
      'Một số cách sử dụng chủ đề vẫn cần được xử lý. Hãy xem lại trước khi tiếp tục.';

  @override
  String get errorWritersideRedirectInvalid =>
      'Đích chuyển hướng đã chọn không còn hợp lệ. Hãy chọn lại.';

  @override
  String errorWritersideRollbackFailed(String paths) {
    return 'Không thể khôi phục hoàn toàn việc xóa chủ đề. Hãy xem lại các đường dẫn này trước khi tiếp tục: $paths';
  }

  @override
  String get errorTopicsRootUnsafe =>
      'Gốc chủ đề phải là một thư mục tương đối an toàn.';

  @override
  String get errorTopicFileNameUnsafe =>
      'Tên tệp chủ đề phải là một phần đường dẫn an toàn duy nhất.';

  @override
  String errorTopicFileExtensionMismatch(String extension) {
    return 'Phần mở rộng tệp chủ đề phải khớp với định dạng đã chọn ($extension).';
  }

  @override
  String get errorTopicFileNameInvalid =>
      'Tên tệp chủ đề chỉ được chứa chữ cái, chữ số, dấu gạch dưới và dấu gạch nối.';

  @override
  String errorUnknown(String code) {
    return 'Lỗi không xác định: $code';
  }

  @override
  String diagnosticWorkspaceFileStatFailed(String error) {
    return 'Không thể đọc siêu dữ liệu tệp: $error';
  }

  @override
  String get diagnosticWorkspaceScanSkipped =>
      'Đã phát hiện không gian làm việc lớn. Một số tệp đã được bỏ qua để ứng dụng vẫn phản hồi nhanh.';

  @override
  String diagnosticWorkspaceScanInspectFailed(String error) {
    return 'Không thể kiểm tra mục trong không gian làm việc: $error';
  }

  @override
  String get diagnosticWorkspaceFileTooLarge =>
      'Tệp vượt quá giới hạn phân tích tự động beta.';

  @override
  String diagnosticWorkspaceFileReadFailed(String error) {
    return 'Không thể đọc tệp Markdown: $error';
  }

  @override
  String get diagnosticMarkdownAttributeMalformed =>
      'Khối thuộc tính tiêu đề Writerside không đúng định dạng.';

  @override
  String diagnosticMarkdownHeadingDuplicateId(String id) {
    return 'ID tiêu đề bị trùng \"$id\".';
  }

  @override
  String get diagnosticWritersideTopicH1ConvertedToChapter =>
      'Các tiêu đề H1 cấp cao nhất bổ sung được xử lý như các chương.';

  @override
  String get diagnosticWritersideMarkdownTopicMissingTitle =>
      'Chủ đề Markdown Writerside không có H1 hoặc tiêu đề trong front matter.';

  @override
  String get diagnosticWritersideXmlTopicMissingTitle =>
      'Chủ đề XML thiếu tiêu đề.';

  @override
  String diagnosticWritersideTopicFileMissingTitle(String fileName) {
    return 'Chủ đề \"$fileName\" thiếu tiêu đề.';
  }

  @override
  String get diagnosticMarkdownFrontMatterMalformed =>
      'Front matter chưa được đóng.';

  @override
  String get diagnosticMarkdownRawHtmlUnsafe => 'Phần tử HTML không an toàn.';

  @override
  String diagnosticMarkdownLinkUnresolvedTarget(String targetPath) {
    return 'Đích liên kết không tồn tại: $targetPath';
  }

  @override
  String diagnosticMarkdownLinkUnresolvedAnchor(String anchor) {
    return 'Neo \"$anchor\" không tồn tại.';
  }

  @override
  String diagnosticMarkdownImageMissingAlt(String destination) {
    return 'Hình ảnh \"$destination\" thiếu văn bản thay thế.';
  }

  @override
  String diagnosticMarkdownImageMissingFile(String destination) {
    return 'Hình ảnh không tồn tại: $destination';
  }

  @override
  String diagnosticInvalidXml(String message) {
    return 'XML không hợp lệ: $message';
  }

  @override
  String get diagnosticWritersideConfigInvalidRoot =>
      'Gốc writerside.cfg phải là <ihp>.';

  @override
  String get diagnosticWritersideConfigMissingSnippetsSrc =>
      'Khai báo snippets thiếu src.';

  @override
  String get diagnosticWritersideConfigMissingInstanceGroupsSrc =>
      'Khai báo instance-groups thiếu src.';

  @override
  String diagnosticWritersideConfigInvalidKeymapsMode(String mode) {
    return 'Chế độ keymaps không được hỗ trợ: $mode';
  }

  @override
  String get diagnosticWritersideConfigMissingInstanceSrc =>
      'Khai báo instance thiếu src.';

  @override
  String get diagnosticWritersideConfigMissingInstance =>
      'writerside.cfg không đăng ký phiên bản nào.';

  @override
  String get diagnosticWritersideTreeInvalidRoot =>
      'Gốc .tree phải là <instance-profile>.';

  @override
  String get diagnosticWritersideTreeMissingId => 'Hồ sơ phiên bản thiếu id.';

  @override
  String diagnosticWritersideTreeIdMismatch(String id) {
    return 'Tên gốc của tệp cây không khớp với ID phiên bản \"$id\".';
  }

  @override
  String get diagnosticWritersideTreeMissingStartPage =>
      'Phiên bản không phải thư viện thiếu start-page.';

  @override
  String diagnosticWritersideStartPageMissing(String startPage) {
    return 'Trang bắt đầu \"$startPage\" không tồn tại.';
  }

  @override
  String diagnosticWritersideTreeDuplicateTopic(String topic) {
    return 'Chủ đề \"$topic\" xuất hiện nhiều hơn một lần trong mục lục của phiên bản này.';
  }

  @override
  String get diagnosticWritersideVariableMalformedDeclaration =>
      'Khai báo biến phải có tên và giá trị.';

  @override
  String diagnosticWritersideVariableDuplicateName(String name) {
    return 'Biến \"$name\" được khai báo nhiều hơn một lần.';
  }

  @override
  String get diagnosticWritersideCategoryMissingId => 'Danh mục thiếu id.';

  @override
  String diagnosticWritersideCategoryDuplicateId(String id) {
    return 'Danh mục \"$id\" được khai báo nhiều hơn một lần.';
  }

  @override
  String diagnosticWritersideCategoryDuplicateOrder(String order) {
    return 'Thứ tự danh mục \"$order\" được khai báo nhiều hơn một lần.';
  }

  @override
  String get diagnosticWritersideTopicInvalidRoot =>
      'Gốc .topic phải là <topic>.';

  @override
  String get diagnosticWritersideTopicMissingRootId =>
      'Chủ đề XML thiếu id ở gốc.';

  @override
  String diagnosticWritersideTopicRootIdMismatch(String id, String expectedId) {
    return 'ID gốc của chủ đề XML \"$id\" phải khớp với tên tệp \"$expectedId\".';
  }

  @override
  String diagnosticWritersideTopicDuplicateElementId(String elementId) {
    return 'ID phần tử \"$elementId\" xuất hiện nhiều hơn một lần.';
  }

  @override
  String get diagnosticWritersideTopicAnchorMissingHref => '<a> thiếu href.';

  @override
  String get diagnosticWritersideConfigMissing =>
      'Chế độ Writerside yêu cầu writerside.cfg.';

  @override
  String diagnosticWritersideConfigMissingBuildConfigDirectory(
    String relativePath,
  ) {
    return 'Thư mục cấu hình build đã định không tồn tại: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingApiSpecificationsDirectory(
    String relativePath,
  ) {
    return 'Thư mục đặc tả API đã định không tồn tại: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingSnippetsDirectory(
    String relativePath,
  ) {
    return 'Thư mục snippets đã định không tồn tại: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingVarsFile(String relativePath) {
    return 'Tệp biến đã định không tồn tại: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingCategoriesFile(String relativePath) {
    return 'Tệp danh mục đã định không tồn tại: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceGroupsFile(
    String relativePath,
  ) {
    return 'Tệp nhóm phiên bản đã định không tồn tại: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceTree(String source) {
    return 'Cây phiên bản đã đăng ký \"$source\" không tồn tại.';
  }

  @override
  String diagnosticWritersideTopicReadFailed(String error) {
    return 'Không thể đọc tệp chủ đề: $error';
  }

  @override
  String diagnosticWritersideDefaultTopicsDirectoryMissing(
    String relativePath,
  ) {
    return 'Thư mục chủ đề mặc định không tồn tại: $relativePath';
  }

  @override
  String diagnosticWritersideTopicsDirectoryMissing(String relativePath) {
    return 'Thư mục chủ đề đã định không tồn tại: $relativePath';
  }

  @override
  String diagnosticWritersideImagesDirectoryMissing(String relativePath) {
    return 'Thư mục hình ảnh đã định không tồn tại: $relativePath';
  }

  @override
  String diagnosticWritersideTopicDuplicateId(String id) {
    return 'ID phần tử \"$id\" xuất hiện nhiều hơn một lần.';
  }

  @override
  String diagnosticWritersideTreeMissingTopic(String topic) {
    return 'Mục lục tham chiếu đến chủ đề còn thiếu \"$topic\".';
  }

  @override
  String diagnosticWritersideTreeInvalidHref(String href) {
    return 'href bên ngoài \"$href\" không hợp lệ.';
  }

  @override
  String diagnosticWritersideVariableUnresolved(String name) {
    return 'Biến \"%$name%\" chưa được khai báo.';
  }

  @override
  String diagnosticWritersideTopicLinkUnresolved(String destination) {
    return 'Liên kết chủ đề \"$destination\" không thể phân giải.';
  }

  @override
  String diagnosticWritersideAnchorUnresolved(
    String anchor,
    String targetName,
  ) {
    return 'Neo \"$anchor\" không tồn tại trong \"$targetName\".';
  }

  @override
  String get diagnosticWritersideIncludeMissingFrom => '<include> thiếu from.';

  @override
  String diagnosticWritersideIncludeSourceMissing(String from) {
    return 'Nguồn include \"$from\" không tồn tại.';
  }

  @override
  String diagnosticWritersideIncludeElementMissing(
    String elementId,
    String from,
  ) {
    return 'Phần tử include \"$elementId\" không tồn tại trong \"$from\".';
  }

  @override
  String diagnosticWritersideCategoryUnresolved(String ref) {
    return 'Danh mục seealso \"$ref\" chưa được khai báo.';
  }

  @override
  String diagnosticWritersideTopicAmbiguousReference(String reference) {
    return 'Tham chiếu chủ đề \"$reference\" không rõ ràng.';
  }

  @override
  String diagnosticUnknown(String code) {
    return 'Chẩn đoán không xác định: $code';
  }

  @override
  String get close => 'Đóng';

  @override
  String get git => 'Git';

  @override
  String get gitDiff => 'Khác biệt Git';

  @override
  String get gitShowDiff => 'Hiện khác biệt';

  @override
  String gitDiffHunkRange(String oldRange, String newRange) {
    return 'cũ $oldRange → mới $newRange';
  }

  @override
  String get gitDiffNoLines => 'không có dòng';

  @override
  String get gitUnavailableTitle => 'Git không khả dụng';

  @override
  String gitUnavailableMessage(String reason) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'other':
          'Cài đặt Git hoặc cấu hình BusyMark để sử dụng một tệp thực thi Git khả dụng. $reason',
    });
    return '$_temp0';
  }

  @override
  String get gitTrustRequiredTitle =>
      'Tin cậy không gian làm việc này cho Git?';

  @override
  String get gitTrustRequiredMessage =>
      'Kho Git có thể chạy chương trình thông qua hook, bộ lọc và các cấu hình khác. Hãy tin cậy không gian làm việc này trước khi BusyMark đọc dữ liệu kho hoặc bật các thao tác Git.';

  @override
  String get gitTrustWorkspace => 'Tin cậy không gian làm việc';

  @override
  String get gitNotRepositoryTitle => 'Không phải kho Git';

  @override
  String get gitNotRepositoryMessage =>
      'Không gian làm việc này không nằm trong kho Git.';

  @override
  String get gitInitializeRepository => 'Khởi tạo kho';

  @override
  String get gitDetachedHead => 'HEAD tách rời';

  @override
  String gitDetachedHeadAt(String commit) {
    return 'Đang tách rời tại $commit';
  }

  @override
  String get gitNoUpstream => 'Không có nhánh upstream';

  @override
  String gitAheadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commit chưa đẩy',
      one: '1 commit chưa đẩy',
    );
    return '$_temp0';
  }

  @override
  String gitBehindCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commit cần kéo về',
      one: '1 commit cần kéo về',
    );
    return '$_temp0';
  }

  @override
  String get gitClean => 'Sạch';

  @override
  String get gitConflicts => 'Xung đột';

  @override
  String get gitChanges => 'Thay đổi';

  @override
  String get gitStaged => 'Đã đưa vào stage';

  @override
  String get gitUnstaged => 'Chưa đưa vào stage';

  @override
  String get gitHistory => 'Lịch sử';

  @override
  String get gitBranches => 'Nhánh';

  @override
  String get gitActions => 'Thao tác Git';

  @override
  String get gitPull => 'Pull';

  @override
  String get gitFetch => 'Fetch';

  @override
  String get gitPush => 'Push';

  @override
  String get gitCommit => 'Commit';

  @override
  String get gitSelectForCommit => 'Đưa tệp vào stage';

  @override
  String get gitRemoveFromCommit => 'Bỏ tệp khỏi stage';

  @override
  String get gitDiscard => 'Hoàn nguyên';

  @override
  String get gitOpenFile => 'Mở tệp';

  @override
  String get gitMarkResolved => 'Đánh dấu đã giải quyết';

  @override
  String get gitUntracked => 'Chưa được theo dõi';

  @override
  String get gitCommitMessage => 'Thông điệp commit';

  @override
  String get gitCommitSelectedFiles => 'Tệp đã chọn';

  @override
  String get gitCommitNoSelectedFiles =>
      'Đưa ít nhất một tệp vào stage trước khi commit.';

  @override
  String gitStagedFileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tệp đã đưa vào stage',
      one: '1 tệp đã đưa vào stage',
    );
    return '$_temp0';
  }

  @override
  String get gitOutsideWorkspace => 'Bên ngoài không gian làm việc';

  @override
  String get gitCommitMessageRequired => 'Nhập thông điệp commit.';

  @override
  String get gitCreateBranch => 'Tạo nhánh';

  @override
  String get gitNewBranch => 'Nhánh mới';

  @override
  String get gitBranchName => 'Tên nhánh';

  @override
  String get gitSwitchBranch => 'Chuyển nhánh';

  @override
  String get gitNoChanges => 'Không có thay đổi';

  @override
  String get gitNoHistory => 'Không có lịch sử';

  @override
  String get gitNoBranches => 'Không có nhánh';

  @override
  String get gitNoDiff => 'Không có khác biệt để hiển thị';

  @override
  String get gitBinaryFile =>
      'Tệp nhị phân. BusyMark không kết xuất bản vá nhị phân.';

  @override
  String gitBinaryFileInfo(int size) {
    return 'Tệp nhị phân ($size byte). BusyMark không kết xuất bản vá nhị phân.';
  }

  @override
  String get gitUnsavedChangesBanner =>
      'Các thay đổi trong trình biên tập chưa lưu sẽ không được đưa vào cho đến khi lưu.';

  @override
  String get gitConfirmDiscardTitle => 'Loại bỏ các thay đổi Git?';

  @override
  String gitConfirmDiscardTracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Tất cả thay đổi đã đưa và chưa đưa vào stage trong các tệp được theo dõi đã chọn sẽ được khôi phục về HEAD.',
      one:
          'Tất cả thay đổi đã đưa và chưa đưa vào stage trong tệp được theo dõi đã chọn sẽ được khôi phục về HEAD.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardUntracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Các tệp chưa được theo dõi đã chọn sẽ bị xóa.',
      one: 'Tệp chưa được theo dõi đã chọn sẽ bị xóa.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardMixed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Các tệp đã chọn sẽ được khôi phục hoặc xóa tùy theo trạng thái Git.',
      one: 'Tệp đã chọn sẽ được khôi phục hoặc xóa tùy theo trạng thái Git.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmSwitchBranchTitle(String branch) {
    return 'Chuyển sang $branch?';
  }

  @override
  String get gitConfirmSwitchBranchMessage =>
      'BusyMark sẽ tải lại không gian làm việc từ đĩa sau khi Git chuyển nhánh.';

  @override
  String get gitConfirmPushSetUpstreamTitle => 'Đặt nhánh upstream?';

  @override
  String gitConfirmPushSetUpstreamMessage(String branch) {
    return 'Nhánh này không có upstream. BusyMark có thể push $branch và đặt upstream cho nhánh đó khi chỉ có một remote được cấu hình.';
  }

  @override
  String get gitProjectHistory => 'Lịch sử dự án';

  @override
  String get gitFileHistory => 'Lịch sử tệp';

  @override
  String get gitFileHistoryRequiresOpenFile =>
      'Lịch sử tệp yêu cầu một tệp Markdown đang mở.';

  @override
  String get gitLoadMore => 'Tải thêm';

  @override
  String get gitChangesInCommit => 'Thay đổi trong commit này';

  @override
  String get gitCompareWithCurrent => 'So sánh với hiện tại';

  @override
  String get gitRestoreVersion => 'Khôi phục phiên bản này';

  @override
  String get gitConfirmRestoreTitle => 'Khôi phục phiên bản tệp này?';

  @override
  String get gitConfirmRestoreMessage =>
      'BusyMark sẽ thay thế tệp trong cây làm việc hiện tại bằng phiên bản đã commit được chọn. Tệp đã khôi phục sẽ vẫn ở trạng thái chưa đưa vào stage.';

  @override
  String get gitCommitActions => 'Thao tác commit';

  @override
  String get gitResetCurrentBranchToHere => 'Đặt lại nhánh hiện tại về đây…';

  @override
  String gitResetCurrentBranchTitle(String branch, String commit) {
    return 'Đặt lại $branch về $commit?';
  }

  @override
  String gitResetCurrentBranchMessage(String branch, String commit) {
    return 'Thao tác này sẽ đưa nhánh $branch về commit $commit. Chọn cách Git cập nhật index và cây làm việc.';
  }

  @override
  String get gitReset => 'Đặt lại';

  @override
  String get gitResetModeSoft => 'Mềm';

  @override
  String get gitResetModeSoftDescription =>
      'Chỉ di chuyển nhánh. Giữ nguyên index và cây làm việc; các khác biệt so với commit đã chọn vẫn được đưa vào stage.';

  @override
  String get gitResetModeMixed => 'Hỗn hợp';

  @override
  String get gitResetModeMixedDescription =>
      'Di chuyển nhánh và đặt lại index. Giữ nguyên cây làm việc, để lại các khác biệt ở trạng thái chưa đưa vào stage.';

  @override
  String get gitResetModeHard => 'Cứng';

  @override
  String get gitResetModeHardDescription =>
      'Di chuyển nhánh và đặt lại index cùng cây làm việc. Các thay đổi được theo dõi sẽ bị loại bỏ; các tệp chưa được theo dõi gây cản trở có thể bị xóa.';

  @override
  String get gitResetModeKeep => 'Giữ';

  @override
  String get gitResetModeKeepDescription =>
      'Di chuyển nhánh và đặt lại các tệp được theo dõi nhưng giữ lại các thay đổi cục bộ. Git sẽ hủy nếu các thay đổi đó xung đột với thao tác đặt lại.';

  @override
  String gitAdditionsDeletions(int additions, int deletions) {
    return '+$additions -$deletions';
  }

  @override
  String get fileActions => 'Thao tác với tệp';

  @override
  String get actions => 'Thao tác';

  @override
  String get gitStatusAdded => 'Đã thêm';

  @override
  String get gitStatusDeleted => 'Đã xóa';

  @override
  String get gitStatusRenamed => 'Đã đổi tên';

  @override
  String get gitStatusCopied => 'Đã sao chép';

  @override
  String get gitStatusUntracked => 'Chưa được theo dõi';

  @override
  String get gitStatusConflicted => 'Có xung đột';

  @override
  String get gitStatusIgnored => 'Bị bỏ qua';

  @override
  String get gitStatusTypeChanged => 'Đã thay đổi loại';

  @override
  String get gitStatusModified => 'Đã sửa đổi';

  @override
  String get gitStatusUnknown => 'Không xác định';

  @override
  String get gitErrorUnavailable => 'Git không khả dụng.';

  @override
  String get gitErrorNotRepository =>
      'Không gian làm việc này không phải là kho Git.';

  @override
  String get gitErrorUnsafePath =>
      'BusyMark đã chặn một đường dẫn Git không an toàn.';

  @override
  String get gitErrorInvalidBranchName => 'Nhập tên nhánh hợp lệ.';

  @override
  String get gitErrorNoRemote => 'Chưa cấu hình remote Git nào.';

  @override
  String get gitErrorNoUpstream => 'Chưa cấu hình nhánh upstream.';

  @override
  String get gitErrorMultipleRemotes =>
      'Có nhiều remote được cấu hình. Hãy chọn upstream bên ngoài phiên bản BusyMark này.';

  @override
  String get gitErrorDirtyWorkspace =>
      'Lưu hoặc loại bỏ các thay đổi trong trình biên tập BusyMark trước khi chuyển nhánh.';

  @override
  String get gitErrorResetDirtyWorkspace =>
      'Lưu hoặc loại bỏ các thay đổi trong trình biên tập BusyMark trước khi đặt lại nhánh hiện tại.';

  @override
  String get gitErrorRestoreStagedFile =>
      'Bỏ tệp khỏi stage trước khi khôi phục phiên bản trong lịch sử.';

  @override
  String get gitErrorResetDetachedHead =>
      'Chuyển sang một nhánh trước khi đặt lại.';

  @override
  String get gitErrorDiverged =>
      'Nhánh đã phân kỳ. Hãy giải quyết thao tác merge hoặc rebase bên ngoài phiên bản BusyMark này.';

  @override
  String get gitErrorAuthorIdentity =>
      'Git cần tên và địa chỉ email tác giả trước khi có thể commit.';

  @override
  String get gitAuthorIdentityTitle => 'Danh tính tác giả Git';

  @override
  String get gitAuthorIdentityMessage =>
      'Nhập danh tính Git sẽ ghi vào các commit. BusyMark sẽ lưu danh tính đó và thử lại commit này.';

  @override
  String get gitAuthorName => 'Tên';

  @override
  String get gitAuthorEmail => 'Email';

  @override
  String get gitAuthorIdentityGlobal => 'Dùng cho tất cả kho';

  @override
  String get gitAuthorIdentityGlobalDescription =>
      'Khi được cài đặt dưới dạng Snap, tùy chọn này áp dụng cho các kho được mở trong BusyMark.';

  @override
  String get gitSaveIdentityAndCommit => 'Lưu và commit';

  @override
  String get gitErrorAuthentication => 'Xác thực Git không thành công.';

  @override
  String get gitErrorNetwork => 'Thao tác mạng Git không thành công.';

  @override
  String get gitErrorConflict =>
      'Git báo cáo các xung đột chưa được giải quyết.';

  @override
  String get gitErrorCommandFailed => 'Lệnh Git không thành công.';

  @override
  String get markdownAndHtml => 'Markdown và HTML';

  @override
  String get markdownHtmlMarkdownBlocks => 'Khối Markdown';

  @override
  String get markdownHtmlMarkdownBlocksDescription =>
      'Các cấu trúc khối được hỗ trợ trong mã nguồn và bản xem trước Markdown.';

  @override
  String get markdownHtmlInlineFormatting => 'Định dạng Markdown nội tuyến';

  @override
  String get markdownHtmlInlineFormattingDescription =>
      'Định dạng có thể xuất hiện trong đoạn văn, mục danh sách và ô bảng.';

  @override
  String get markdownHtmlRawHtmlBlocks => 'Khối HTML thô';

  @override
  String get markdownHtmlRawHtmlBlocksDescription =>
      'Các thẻ HTML cấp khối an toàn được kết xuất thông qua các tiện ích xem trước của BusyMark.';

  @override
  String get markdownHtmlRawHtmlInline => 'Thẻ HTML nội tuyến thô';

  @override
  String get markdownHtmlRawHtmlInlineDescription =>
      'Các thẻ HTML nội tuyến an toàn được kết xuất mà không hiển thị thẻ theo nghĩa đen.';

  @override
  String get markdownHtmlSafety => 'Quy tắc an toàn';

  @override
  String get markdownHtmlSafetyDescription =>
      'HTML thô được phân tích cú pháp và làm sạch trước khi kết xuất bản xem trước.';

  @override
  String get markdownHtmlHeadings => 'Tiêu đề';

  @override
  String get markdownHtmlParagraphs => 'Đoạn văn';

  @override
  String get markdownHtmlLists => 'Danh sách';

  @override
  String get markdownHtmlHtmlContainers => 'Vùng chứa';

  @override
  String get markdownHtmlHtmlTextBlocks => 'Khối văn bản';

  @override
  String get markdownHtmlHtmlFigures => 'Hình và hình ảnh';

  @override
  String get markdownHtmlHtmlPreformatted => 'Mã định dạng sẵn';

  @override
  String get markdownHtmlHtmlDisclosure => 'Khối mở rộng';

  @override
  String get markdownHtmlHtmlDescriptionLists => 'Danh sách mô tả';

  @override
  String get markdownHtmlHtmlFormattingTags => 'Thẻ định dạng';

  @override
  String get markdownHtmlHtmlInlineCodeTags => 'Thẻ mã nội tuyến';

  @override
  String get markdownHtmlHtmlNeutralInlineTags => 'Thẻ văn bản ngữ nghĩa';

  @override
  String get markdownHtmlSanitizedPreview => 'Bản xem trước đã làm sạch';

  @override
  String get markdownHtmlSanitizedPreviewDescription =>
      'HTML được cho phép được chuyển thành các khối xem trước của BusyMark, không được kết xuất trong trình duyệt.';

  @override
  String get markdownHtmlSourcePreserved => 'Giữ nguyên mã nguồn';

  @override
  String get markdownHtmlSourcePreservedDescription =>
      'HTML thô chưa chỉnh sửa được lưu lại chính xác như văn bản mã nguồn.';

  @override
  String get markdownHtmlMarkdownInsideHtml => 'Markdown bên trong HTML';

  @override
  String get markdownHtmlMarkdownInsideHtmlDescription =>
      'Các dấu Markdown bên trong HTML thô được kết xuất như văn bản theo nghĩa đen.';

  @override
  String get markdownHtmlBlockedContent => 'Nội dung hoạt động bị chặn';

  @override
  String get markdownHtmlBlockedContentDescription =>
      'Script, style, frame, form, SVG, MathML, sự kiện và các thuộc tính không an toàn bị chặn.';

  @override
  String get markdownHtmlSafeUrls => 'Chỉ URL an toàn';

  @override
  String get markdownHtmlSafeUrlsDescription =>
      'Liên kết cho phép URL http, https, mailto, tel, tương đối và fragment; các scheme không an toàn bị chặn.';

  @override
  String get exportAsPdf => 'Xuất dưới dạng PDF';

  @override
  String get pdfExportDescription =>
      'Chọn bố cục trang cho tệp PDF hoàn chỉnh, được trình bày chuyên nghiệp.';

  @override
  String get pdfRemoteImagesNote =>
      'Hình ảnh từ xa không được tải xuống trong quá trình xuất. Hình ảnh cục bộ sẽ được đưa vào khi có thể.';

  @override
  String get pdfPageSize => 'Cỡ trang';

  @override
  String get pdfPageSizeA4 => 'A4';

  @override
  String get pdfPageSizeLetter => 'Letter';

  @override
  String get pdfOrientation => 'Hướng trang';

  @override
  String get pdfPortrait => 'Dọc';

  @override
  String get pdfLandscape => 'Ngang';

  @override
  String get pdfMargins => 'Lề';

  @override
  String get pdfMarginNarrow => 'Hẹp';

  @override
  String get pdfMarginNormal => 'Bình thường';

  @override
  String get pdfMarginWide => 'Rộng';

  @override
  String get pdfIncludePageNumbers => 'Bao gồm số trang';

  @override
  String get export => 'Xuất';

  @override
  String get exportingPdf => 'Đang xuất PDF…';

  @override
  String get fileTypePdf => 'Tài liệu PDF';

  @override
  String pdfExported(String fileName) {
    return 'Đã xuất $fileName.';
  }

  @override
  String pdfExportedWithWarnings(String fileName, int count) {
    return 'Đã xuất $fileName với $count cảnh báo.';
  }

  @override
  String get pdfExportUnavailable =>
      'Thiếu thành phần xuất PDF. Hãy cài đặt lại BusyMark và thử lại.';

  @override
  String get pdfExportTimedOut =>
      'Quá trình xuất PDF mất quá nhiều thời gian và đã bị dừng.';

  @override
  String get pdfExportFailed =>
      'BusyMark không thể xuất tài liệu này dưới dạng PDF.';

  @override
  String get visualizationRendering => 'Đang kết xuất…';

  @override
  String get visualizationStale => 'Đang hiển thị bản kết xuất hợp lệ gần nhất';

  @override
  String get visualizationShowSource => 'Hiện mã nguồn';

  @override
  String get visualizationShowRender => 'Hiện bản kết xuất';

  @override
  String get visualizationFitWidth => 'Vừa theo chiều rộng';

  @override
  String get visualizationSaveImage => 'Lưu hình ảnh';

  @override
  String get visualizationCopyImage => 'Sao chép hình ảnh';

  @override
  String get visualizationImageCopied => 'Đã sao chép hình ảnh';

  @override
  String get visualizationOpenApiReference => 'Mở tham chiếu API';

  @override
  String get visualizationValid => 'Hợp lệ';

  @override
  String get visualizationInvalid => 'Không hợp lệ';

  @override
  String get visualizationServers => 'Máy chủ';

  @override
  String get visualizationPaths => 'Đường dẫn';

  @override
  String get visualizationOperations => 'Thao tác';

  @override
  String get visualizationTags => 'Thẻ';

  @override
  String get visualizationNoOperations => 'Không có thao tác phù hợp';

  @override
  String get visualizationSearchOperations => 'Tìm kiếm thao tác';

  @override
  String get visualizationRenderFailed =>
      'Không thể kết xuất hình minh họa này.';

  @override
  String get visualizationRetry => 'Thử lại';

  @override
  String visualizationSaved(String fileName) {
    return 'Đã lưu $fileName';
  }

  @override
  String get shortcutExportPdfDescription =>
      'Xuất tài liệu hiện tại hoặc mô-đun Writerside dưới dạng PDF.';

  @override
  String get instances => 'Các phiên bản';

  @override
  String get newInstance => 'Phiên bản mới';

  @override
  String get newTocLibrary => 'Thư viện mục lục mới';

  @override
  String get editInstance => 'Chỉnh sửa phiên bản';

  @override
  String get openTocFile => 'Mở tệp mục lục';

  @override
  String get createInstance => 'Tạo phiên bản';

  @override
  String get createTocLibrary => 'Tạo thư viện mục lục';

  @override
  String get instanceContent => 'Nội dung';

  @override
  String get instanceContentSource => 'Tạo từ';

  @override
  String get emptyInstance => 'Phiên bản trống';

  @override
  String get markdownFiles => 'Tệp Markdown cục bộ';

  @override
  String get chooseMarkdownFolder => 'Chọn thư mục Markdown';

  @override
  String get errorWritersideInstanceImportSourceRequired =>
      'Chọn một thư mục chứa các tệp Markdown.';

  @override
  String get instanceAppearance => 'Giao diện';

  @override
  String get instanceColor => 'Màu biểu tượng';

  @override
  String get instanceVersion => 'Phiên bản';

  @override
  String instanceVersionInherited(String version) {
    return 'Phiên bản dự án là $version khi trường này để trống.';
  }

  @override
  String get instanceWebPath => 'Đường dẫn web';

  @override
  String get instanceStatus => 'Trạng thái';

  @override
  String get instanceStatusRelease => 'Bản phát hành';

  @override
  String get instanceStatusEap => 'Truy cập sớm';

  @override
  String get instanceStatusDeprecated => 'Không còn được dùng';

  @override
  String get allowSearchEngineIndexing =>
      'Cho phép công cụ tìm kiếm lập chỉ mục';

  @override
  String get allowSearchEngineIndexingDescription =>
      'Cho phép các công cụ tìm kiếm bên ngoài lập chỉ mục đầu ra này.';

  @override
  String get offlineArtifact => 'Gói ngoại tuyến';

  @override
  String get offlineArtifactDescription =>
      'Đóng gói tài nguyên để tài liệu được xây dựng có thể hoạt động độc lập.';

  @override
  String get instanceOutputSettings => 'Cài đặt đầu ra';

  @override
  String get markdownImportSource => 'Nguồn Markdown';

  @override
  String get markdownImportFiles => 'Tệp Markdown';

  @override
  String get selectNone => 'Bỏ chọn tất cả';

  @override
  String markdownFilesFound(int count) {
    return 'Đã tìm thấy $count tệp Markdown';
  }

  @override
  String get noMarkdownFilesFound =>
      'Không tìm thấy tệp Markdown nào trong thư mục này.';

  @override
  String get copyReferencedMedia => 'Sao chép phương tiện được tham chiếu';

  @override
  String get copyReferencedMediaDescription =>
      'Sao chép hình ảnh và video cục bộ được các tệp đã chọn tham chiếu, đồng thời giữ nguyên đường dẫn tương đối.';

  @override
  String get instanceIdRenameWarningTitle => 'Đổi tên ID phiên bản?';

  @override
  String instanceIdRenameWarning(String oldId, String newId) {
    return 'BusyMark sẽ đổi tên tệp .tree và cập nhật các tham chiếu dự án Writerside từ “$oldId” thành “$newId”. Các script xuất bản không được thay đổi và phải cập nhật riêng.';
  }

  @override
  String get renameAndUpdateReferences => 'Đổi tên và cập nhật tham chiếu';

  @override
  String get tocLibraryDescription =>
      'Thư viện mục lục lưu trữ các phần có thể tái sử dụng và không tạo đầu ra riêng.';

  @override
  String get defaultTocLibraryName => 'Mục lục dùng chung';

  @override
  String get instanceColorAutomatic => 'Tự động';

  @override
  String get instanceColorBlue => 'Xanh dương';

  @override
  String get instanceColorGreen => 'Xanh lá';

  @override
  String get instanceColorOrange => 'Cam';

  @override
  String get instanceColorPurple => 'Tím';

  @override
  String get instanceColorRed => 'Đỏ';

  @override
  String get instanceColorTeal => 'Xanh mòng két';

  @override
  String get instanceColorYellow => 'Vàng';

  @override
  String get errorWritersideInstanceNameRequired => 'Nhập tên phiên bản.';

  @override
  String errorWritersideInstanceIdExists(String id) {
    return 'Đã có phiên bản với ID “$id”.';
  }

  @override
  String errorWritersideInstanceTreeExists(String path) {
    return 'Cây phiên bản đã tồn tại: $path';
  }

  @override
  String errorWritersideInstanceImportSourceMissing(String path) {
    return 'Thư mục nguồn Markdown không tồn tại: $path';
  }

  @override
  String get errorWritersideInstanceImportSelectionRequired =>
      'Chọn ít nhất một tệp Markdown để nhập.';

  @override
  String errorWritersideInstanceImportFileInvalid(String path) {
    return 'Đây không phải là tệp Markdown có thể đọc bên trong nguồn đã chọn: $path';
  }

  @override
  String errorWritersideInstanceImportTargetExists(String path) {
    return 'Việc nhập sẽ ghi đè một tệp dự án hiện có: $path';
  }

  @override
  String get errorWritersideInstanceFilesChanged =>
      'Các tệp phiên bản đã thay đổi trên đĩa. Hãy xem lại và thử lại.';

  @override
  String errorWritersideInstanceRollbackFailed(String paths) {
    return 'BusyMark không thể khôi phục hoàn toàn thay đổi phiên bản. Hãy xem lại các tệp này trước khi tiếp tục: $paths';
  }

  @override
  String get errorWritersideInstanceLibraryImport =>
      'Thư viện mục lục không thể nhập các chủ đề Markdown.';

  @override
  String get errorWritersideInstanceWebPathInvalid =>
      'Đường dẫn web phải nằm trên một dòng duy nhất.';

  @override
  String get errorWritersideInstanceConfigurationInvalid =>
      'Cấu hình phiên bản Writerside không hợp lệ. Hãy sửa các chẩn đoán rồi thử lại.';

  @override
  String get errorWritersideInstanceTemporaryFile =>
      'BusyMark không thể đưa các thay đổi phiên bản vào stage một cách an toàn.';

  @override
  String diagnosticWritersideTreeInvalidStatus(String status) {
    return 'Trạng thái phiên bản không xác định “$status”. Sử dụng release, eap hoặc deprecated.';
  }

  @override
  String diagnosticWritersideDuplicateInstanceId(String id) {
    return 'ID phiên bản “$id” được nhiều tệp cây sử dụng.';
  }

  @override
  String get diagnosticWritersideBuildProfilesInvalidRoot =>
      'buildprofiles.xml phải có phần tử gốc <buildprofiles>.';

  @override
  String diagnosticWritersideBuildProfilesInvalidBoolean(
    String name,
    String value,
  ) {
    return 'Giá trị $name “$value” phải là true hoặc false.';
  }

  @override
  String get diagnosticWritersideBuildProfileMissingInstance =>
      'Phần tử <build-profile> phải chỉ định ID phiên bản.';

  @override
  String get diagnosticWritersideTreeInvalidInclude =>
      '<include> trong cây phải chỉ định cả from và element-id.';

  @override
  String get diagnosticWritersideTreeMissingSnippetId =>
      '<snippet> trong cây phải chỉ định id.';

  @override
  String get diagnosticWritersideTreeInvalidCrossInstanceReference =>
      'Tham chiếu mục lục giữa các phiên bản phải chỉ định cả ref và in.';

  @override
  String get diagnosticWritersideTreeConflictingTargets =>
      'Một phần tử mục lục không thể nhắm đến nhiều hơn một chủ đề, tham chiếu, liên kết hoặc chuyển hướng.';

  @override
  String diagnosticWritersideTreeDuplicateElementId(String id) {
    return 'ID phần tử cây “$id” được khai báo nhiều hơn một lần.';
  }

  @override
  String get diagnosticWritersideInstanceGroupsInvalidRoot =>
      'Tệp nhóm phiên bản phải có phần tử gốc <instance-groups>.';

  @override
  String get diagnosticWritersideInstanceGroupInvalid =>
      'Một nhóm phiên bản phải chỉ định id không trống và danh sách phiên bản.';

  @override
  String diagnosticWritersideInstanceGroupDuplicateId(String id) {
    return 'ID nhóm phiên bản “$id” được khai báo nhiều hơn một lần.';
  }

  @override
  String diagnosticWritersideExternalTreeInclude(
    String source,
    String id,
    String origin,
  ) {
    return 'Include mục lục “$source#$id” thuộc mô-đun bên ngoài “$origin” và không thể mở rộng trong không gian làm việc này.';
  }

  @override
  String diagnosticWritersideTreeIncludeElementMissing(
    String source,
    String id,
  ) {
    return 'Phần tử cây “$id” không tồn tại trong cây đã đăng ký “$source”.';
  }

  @override
  String diagnosticWritersideTreeCircularInclude(String source, String id) {
    return 'Include cây “$source#$id” tạo ra một vòng lặp.';
  }

  @override
  String diagnosticWritersideUnknownInstanceGroup(String group) {
    return 'Điều kiện phiên bản tham chiếu đến nhóm không xác định “@$group”.';
  }

  @override
  String diagnosticWritersideReferenceInstanceMissing(String instance) {
    return 'Tham chiếu giữa các phiên bản nhắm đến phiên bản không xác định “$instance”.';
  }

  @override
  String diagnosticWritersideReferenceTopicMissing(
    String topic,
    String instance,
  ) {
    return 'Chủ đề “$topic” không nằm trong phiên bản được tham chiếu “$instance”.';
  }

  @override
  String get download => 'Tải xuống';

  @override
  String get exportWritersideAsPdf => 'Xuất Writerside dưới dạng PDF';

  @override
  String get writersidePdfContent => 'Nội dung xuất';

  @override
  String get writersidePdfPage => 'Trang';

  @override
  String get exportingWritersidePdf => 'Đang xuất PDF Writerside…';

  @override
  String get ai => 'AI';

  @override
  String get aiLocalOllama => 'Ollama cục bộ';

  @override
  String get aiDisabled => 'Đã tắt';

  @override
  String get aiLocalOnlyDescription =>
      'Chỉnh sửa bằng AI chỉ được thực hiện theo yêu cầu rõ ràng. BusyMark chỉ gửi ngữ cảnh được hiển thị cho nhà cung cấp đã chọn và không bao giờ áp dụng đề xuất khi chưa xem lại.';

  @override
  String get aiProvider => 'Nhà cung cấp AI';

  @override
  String get aiDefaultProvider => 'Nhà cung cấp mặc định';

  @override
  String get aiConfigureProvider => 'Cấu hình nhà cung cấp';

  @override
  String get aiChooseProvider => 'Chọn nhà cung cấp AI';

  @override
  String get aiOllamaEndpoint => 'Điểm cuối Ollama';

  @override
  String get aiOllamaModel => 'Mô hình Ollama';

  @override
  String get aiTestConnection => 'Kiểm tra kết nối';

  @override
  String get aiTestingConnection => 'Đang kiểm tra…';

  @override
  String aiConnectionReady(int count) {
    return 'Đã kết nối. Tìm thấy $count mô hình đã cài đặt.';
  }

  @override
  String get aiNoModels => 'Chưa chọn mô hình nào.';

  @override
  String get aiConnectionFailed =>
      'BusyMark không thể xác minh việc tạo văn bản bằng AI.';

  @override
  String get aiConfigureFirst =>
      'Bật một nhà cung cấp AI và xác minh mô hình trong Cài đặt → AI.';

  @override
  String get aiEditWithAi => 'Chỉnh sửa bằng AI';

  @override
  String get aiRefineWithAi => 'Tinh chỉnh bằng AI';

  @override
  String get aiInstruction => 'Hướng dẫn';

  @override
  String get aiChangeTarget => 'Có thể thay đổi gì';

  @override
  String get aiSharedContext => 'Ngữ cảnh được chia sẻ với AI';

  @override
  String get aiTargetSelection => 'Nội dung đã chọn';

  @override
  String get aiTargetInsertAfterBlock => 'Chèn sau khối hiện tại';

  @override
  String get aiTargetCurrentBlock => 'Khối hiện tại';

  @override
  String get aiTargetCurrentSection => 'Phần hiện tại';

  @override
  String get aiTargetCompleteDocument => 'Toàn bộ tài liệu';

  @override
  String get aiContextNone => 'Không có ngữ cảnh tài liệu';

  @override
  String get aiContextSelection => 'Nội dung đã chọn';

  @override
  String get aiContextCurrentBlock => 'Khối hiện tại';

  @override
  String get aiContextCurrentSection => 'Phần hiện tại';

  @override
  String get aiContextCompleteDocument => 'Toàn bộ tài liệu';

  @override
  String get aiGenerating => 'Đang tạo đề xuất…';

  @override
  String get aiProposal => 'Đề xuất của AI';

  @override
  String get aiGenerateProposal => 'Tạo đề xuất';

  @override
  String aiContextDisclosure(int count) {
    return 'Nhà cung cấp đã chọn sẽ nhận $count ký tự từ ngữ cảnh được hiển thị.';
  }

  @override
  String get aiOriginal => 'Bản gốc';

  @override
  String get aiSuggested => 'Đề xuất';

  @override
  String get aiApplyProposal => 'Áp dụng đề xuất';

  @override
  String aiTokenUsage(int input, int output) {
    return '$input token đầu vào · $output token đầu ra';
  }

  @override
  String get aiStaleProposal =>
      'Tài liệu đã thay đổi trong khi đề xuất này được tạo. Hãy thực hiện lại thao tác.';

  @override
  String get gitAiStagedChangesChanged =>
      'Các thay đổi trong stage đã thay đổi trong khi thông điệp commit này được tạo. Hãy thực hiện lại thao tác.';

  @override
  String get aiViewContext => 'Xem ngữ cảnh đã gửi';

  @override
  String get aiReviewExactContent => 'Xem lại nội dung chính xác';

  @override
  String get aiContentToChange => 'Nội dung cần thay đổi';

  @override
  String get aiContentSentToAi => 'Nội dung đã gửi cho AI';

  @override
  String get aiApiKey => 'Khóa API';

  @override
  String get aiApiKeyStoredHint =>
      'Khóa đã được lưu trong kho thông tin xác thực của hệ thống';

  @override
  String get aiApiKeyEnterHint => 'Nhập khóa API của nhà cung cấp';

  @override
  String get aiReplaceApiKey => 'Thay thế khóa API';

  @override
  String get aiSaveApiKey => 'Lưu an toàn khóa API';

  @override
  String get aiRemoveApiKey => 'Xóa khóa API đã lưu';

  @override
  String get aiCredentialSaved =>
      'Đã lưu khóa API trong kho thông tin xác thực của hệ thống.';

  @override
  String get aiCredentialRemoved => 'Đã xóa khóa API đã lưu.';

  @override
  String get aiModelRouting => 'Định tuyến mô hình';

  @override
  String get aiAutomaticRouting => 'Tự động theo tác vụ';

  @override
  String get aiFixedModelRouting => 'Sử dụng mô hình đã chọn';

  @override
  String get aiPreferredModel => 'Mô hình ưu tiên';

  @override
  String get aiModel => 'Mô hình';

  @override
  String aiUsageThisMonth(int requests, int input, int output) {
    return '$requests yêu cầu · $input token đầu vào · $output token đầu ra';
  }

  @override
  String aiCloudConsentTitle(String provider) {
    return 'Gửi nội dung đến $provider?';
  }

  @override
  String aiCloudConsentEnable(String provider) {
    return 'Bật $provider';
  }

  @override
  String get aiCloudConsentMessage =>
      'Chỉ nội dung hiển thị trong mỗi hộp thoại xem lại AI được gửi đi. Yêu cầu không được lưu trạng thái, đề xuất cần được xem lại và khóa API được lưu trong kho thông tin xác thực hệ thống Linux.';

  @override
  String aiCloudConsentRequired(String provider) {
    return 'Trước tiên, hãy xác nhận việc chia sẻ dữ liệu với $provider trong Cài đặt → AI.';
  }

  @override
  String aiGenerationVerified(String model, int count) {
    return 'Đã xác minh việc tạo bằng $model. Có sẵn $count mô hình tương thích.';
  }

  @override
  String get aiColdStartObserved =>
      'Đã phát hiện khởi động nguội của mô hình cục bộ.';

  @override
  String get aiNoCompatibleModels =>
      'Không có mô hình tạo văn bản tương thích nào khả dụng.';

  @override
  String get aiEnableProvider => 'Trước tiên, hãy bật một nhà cung cấp AI.';

  @override
  String get aiDraftCommitMessage => 'Soạn thông điệp commit';

  @override
  String get aiDrafting => 'Đang soạn…';

  @override
  String get aiDraftWithAi => 'Soạn bằng AI';

  @override
  String get generateOrUpdateMarkdownToc => 'Tạo/cập nhật mục lục';

  @override
  String get markdownTocTitle => 'Mục lục';

  @override
  String markdownTocUpdated(int count) {
    return 'Đã cập nhật mục lục với $count mục.';
  }

  @override
  String get markdownTocNoHeadings =>
      'Thêm ít nhất một tiêu đề phần trước khi tạo mục lục.';

  @override
  String get markdownTocMalformedMarkers =>
      'Các dấu đánh dấu mục lục BusyMark bị thiếu, trùng lặp hoặc không đúng thứ tự.';

  @override
  String diagnosticMarkdownHeadingSkippedLevel(int level, int previousLevel) {
    return 'Tiêu đề cấp $level theo sau cấp $previousLevel; hãy xem lại cấu trúc lồng ghép của các phần.';
  }

  @override
  String get diagnosticMarkdownLinkEmptyText =>
      'Văn bản liên kết trống; hãy cung cấp tên có khả năng truy cập mô tả mục đích của liên kết.';

  @override
  String diagnosticMarkdownLinkReviewText(String text) {
    return 'Xem lại liệu văn bản liên kết “$text” có mô tả mục đích của liên kết trong ngữ cảnh hay không.';
  }

  @override
  String get diagnosticMarkdownTableEmptyHeader =>
      'Các ô tiêu đề bảng phải xác định cột của chúng; hãy hoàn thành từng tiêu đề trống.';

  @override
  String get mathRenderFailed => 'Không thể kết xuất biểu thức toán học.';

  @override
  String get inlineMath => 'Toán nội tuyến';

  @override
  String get displayMath => 'Toán hiển thị';
}
