// ignore_for_file: text_direction_code_point_in_literal, text_direction_code_point_in_comment

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get notesNewFromRetainedText => 'Ghi chú mới từ văn bản được giữ lại';

  @override
  String get notesAccountThrottled =>
      'Nextcloud yêu cầu tạm dừng. Hãy đợi trước khi đăng nhập lại.';

  @override
  String get notesSettingsRefreshing =>
      'Đang làm mới Notes sau khi xác nhận cài đặt';

  @override
  String get notesExportOperationFailed =>
      'Xuất thất bại trước khi công bố. Kiểm tra nguồn và đích rồi xuất lại.';

  @override
  String get notesRecoveryCreatedNotOpened =>
      'Ghi chú khôi phục đã được lưu nhưng không mở được. Giải quyết thay đổi đang chờ trong trình soạn thảo hoặc thuộc tính rồi mở ghi chú hiện có này.';

  @override
  String get notesSettingsPendingNotes =>
      'Ghi chú đang chờ, xung đột hoặc lần tạo chưa rõ kết quả đang chặn thay đổi. Đồng bộ hoặc xem xét trong Notes rồi lưu lại bản nháp cài đặt được giữ.';

  @override
  String get notesSettingsPendingAttachments =>
      'Thao tác tệp đính kèm đang chờ đang chặn thay đổi. Xem xét tệp đính kèm trong Notes rồi lưu lại bản nháp cài đặt được giữ.';

  @override
  String get notesAccountServerAddress =>
      'Dùng địa chỉ HTTPS chuẩn của Nextcloud rồi đăng nhập lại. Không thể xác minh địa chỉ hoặc chuyển hướng.';

  @override
  String get notesAccountUnsupported =>
      'Notes không khả dụng hoặc API không được hỗ trợ. Bật Nextcloud Notes với API phiên bản chính 1, phụ từ 4 trở lên.';

  @override
  String get notesAccountAuthorizeAgain =>
      'Nextcloud từ chối thông tin xác thực. Cấp quyền lại hoặc kết nối lại tài khoản.';

  @override
  String get notesAccountCheckForbidden =>
      'Nextcloud cấm kiểm tra khả năng Notes. Nhờ quản trị viên cho phép rồi thử lại.';

  @override
  String get notesAccountMalformed =>
      'Không thể xác minh phản hồi Nextcloud. Kiểm tra cài đặt máy chủ rồi đăng nhập lại.';

  @override
  String get notesAccountTimedOut =>
      'Đăng nhập hết thời gian. Bắt đầu lại và hoàn tất cấp quyền trong trình duyệt.';

  @override
  String get notesAccountBrowserUnavailable =>
      'Không mở được trình duyệt hệ thống. Kiểm tra trình duyệt mặc định rồi đăng nhập lại.';

  @override
  String get notesAccountNetwork =>
      'Không thể kết nối Nextcloud. Kiểm tra kết nối và máy chủ rồi đăng nhập lại.';

  @override
  String get notesAccountRejected =>
      'Nextcloud từ chối yêu cầu khả năng. Kiểm tra quyền truy cập với quản trị viên rồi thử lại.';

  @override
  String get notesAccountFailed =>
      'Không hoàn tất thiết lập tài khoản. Hãy đăng nhập lại.';

  @override
  String get notesTransferSourceChanged =>
      'Nguồn đã đổi sau khi xem xét. Xem xét tệp hiện tại hoặc tạo ảnh chụp mới trước khi thử lại.';

  @override
  String get notesTransferUnreadable =>
      'Không thể đọc nguồn. Kiểm tra quyền truy cập tệp hoặc thư mục rồi xem xét lại.';

  @override
  String get notesTransferInvalidSnapshot =>
      'Ảnh chụp không hợp lệ hoặc không được hỗ trợ. Chọn ảnh chụp BusyMark Notes hợp lệ hoặc nguồn Markdown.';

  @override
  String get notesTransferMediaLimit =>
      'Nội dung đa phương tiện vượt giới hạn nhập. Giảm kích thước của mục liên quan rồi xem xét lại.';

  @override
  String get notesTransferUnsafeSource =>
      'Nguồn chứa đường dẫn không an toàn. Chọn tệp trong thư mục nguồn rồi xem xét lại.';

  @override
  String get notesTransferDestination =>
      'Không thể ghi bản xuất. Kiểm tra quyền truy cập và chỗ trống ở đích rồi xuất lại.';

  @override
  String get notesTransferOperationFailed =>
      'Không hoàn tất truyền. Xem xét các mục liên quan rồi thử lại. Các mục đã nhập vẫn được lưu.';

  @override
  String get notesExportPublishedWithOmissions =>
      'Bản xuất có sẵn nhưng có mục bị bỏ qua';

  @override
  String get notesBatchUnchanged => 'Các giá trị yêu cầu đã được đặt.';

  @override
  String get notesBatchReadOnly =>
      'Ghi chú này chỉ đọc. Không thể sửa thuộc tính được bảo vệ; vẫn có thể đổi Yêu thích.';

  @override
  String get notesBatchReviewChanged =>
      'Ghi chú đã đổi sau khi xem xét. Xem xét trạng thái hiện tại trước khi thực hiện lại.';

  @override
  String get notesBatchMissing =>
      'Ghi chú không còn khả dụng. Làm mới danh sách rồi xem xét lại các mục đích.';

  @override
  String get notesBatchStorage =>
      'Lưu cục bộ thất bại. Kiểm tra bộ nhớ rồi thử lại mục này; các mục thành công vẫn được lưu.';

  @override
  String get notesRemoteReviewChanged =>
      'Ghi chú trên máy chủ đã đổi. Bản nháp hợp nhất được giữ. Xem xét so sánh mới rồi chọn lại cách giải quyết.';

  @override
  String get notesReviewRemote => 'Tôi đã xem xét phiên bản máy chủ hiện tại';

  @override
  String get wsModuleCapsNotPublished =>
      'Quy tắc viết hoa của mô-đun không được xuất bản.';

  @override
  String get wsTitleOverridesAction => 'Tiêu đề phiên bản và mục lục…';

  @override
  String get wsHeadingNotPublished => 'Trình dựng này không xuất bản.';

  @override
  String get wsMarkdownInstanceTitleLimitation =>
      'Builder cố định không xuất bản tiêu đề phiên bản trong chủ đề Markdown. Giữ nguyên đánh dấu hiện có; kiểm tra trong Nguồn.';

  @override
  String get wsTopicIdentity => 'ID chủ đề';

  @override
  String get wsElementAnchor => 'Neo phần tử';

  @override
  String get wsHeadingText => 'Văn bản tiêu đề';

  @override
  String get wsDefaultTitle => 'Tiêu đề mặc định';

  @override
  String get wsTopicNavigation => 'Điều hướng chủ đề';

  @override
  String get wsHeadingOptions => 'Thuộc tính tiêu đề';

  @override
  String get wsDocumentOptions => 'Thiết lập tài liệu';

  @override
  String get wsSettingsPresent => 'Có thiết lập được ghi rõ';

  @override
  String get wsTitleOverrideExplanation =>
      'Ghi đè tiêu đề xuất bản; văn bản tiêu đề không đổi.';

  @override
  String get wsIgnoreVariables => 'Xử lý biến như văn bản nguyên dạng';

  @override
  String get wsIgnoreVariablesExplanation =>
      'Khi bật, văn bản giống biến không được thay thế.';

  @override
  String get wsInstanceSelection => 'Phiên bản trợ giúp';

  @override
  String get wsInstanceExplanation =>
      'Chọn đầu ra theo tên, nhóm, danh sách, loại trừ hoặc biểu thức.';

  @override
  String get wsFilterExplanation =>
      'Lọc nội dung tái sử dụng theo tiêu chí; không chọn phiên bản trợ giúp.';

  @override
  String get wsContextHelp => 'ID trợ giúp ngữ cảnh';

  @override
  String get wsCapitalization => 'Kiểu chữ hoa';

  @override
  String get wsLibraryTopic => 'Chủ đề thư viện';

  @override
  String get wsLastModified => 'Sửa đổi lần cuối';

  @override
  String get wsMissingTopicHeading => 'Chưa có H1 chủ đề. Thêm trong Nguồn.';

  @override
  String get wsMultipleTopicHeadings =>
      'H1 đầu tiên xác định tiêu đề chủ đề. Các H1 sau là tiêu đề riêng.';

  @override
  String get wsTopicIdentityMismatch =>
      'id gốc khác ID theo tên tệp. Dùng Đổi tên tệp chủ đề hoặc kiểm tra Nguồn.';

  @override
  String get wsUnsupportedProperties =>
      'Thuộc tính không hỗ trợ được giữ lại. Kiểm tra trong Nguồn.';

  @override
  String get wsGeneratedAnchor =>
      'Neo được tạo tự động; nhập giá trị để ghi đè.';

  @override
  String get wsHeadingBuilderLimitation =>
      'Builder cố định không xuất bản thuộc tính H1. Chúng thuộc tiêu đề, không thuộc gốc XML.';

  @override
  String get closeOtherTabs => 'Đóng các thẻ khác';

  @override
  String get tocTopicFromTemplate => 'Chủ đề từ mẫu...';

  @override
  String get tocSaveAsTemplate => 'Lưu thành mẫu';

  @override
  String get tocTemplateDialog => 'Tạo chủ đề từ mẫu';

  @override
  String get tocTemplatesEditor => 'Mẫu tệp và mã';

  @override
  String get tocEditTemplates => 'Chỉnh sửa mẫu...';

  @override
  String get tocCreateCustomTemplate => 'Tạo mẫu tùy chỉnh...';

  @override
  String get tocTemplateCreated => 'Đã tạo mẫu';

  @override
  String get tocTemplateDefault => 'Mặc định';

  @override
  String get tocTemplateCustom => 'Tùy chỉnh';

  @override
  String get tocTemplateFilename => 'Tên tệp:';

  @override
  String get tocTemplateMarkdown => 'Markdown (.md)';

  @override
  String get tocTemplateXml => 'XML (.topic)';

  @override
  String get tocTemplatesInternal => 'Nội bộ';

  @override
  String get tocTemplateUnnamed => 'Chưa đặt tên';

  @override
  String get tocTemplateNew => 'Mẫu mới...';

  @override
  String get tocTemplateName => 'Tên:';

  @override
  String get tocTemplateExtension => 'Phần mở rộng:';

  @override
  String get tocTemplateLoadError =>
      'Không thể tải mẫu. Các mẫu hiện có không bị thay đổi.';

  @override
  String get tocTemplateSaveError =>
      'Không thể lưu mẫu. Các chỉnh sửa của bạn vẫn còn ở đây.';

  @override
  String get tocTemplateConflict =>
      'Mẫu đã thay đổi trong cửa sổ khác. Hãy hủy và mở lại trình chỉnh sửa.';

  @override
  String get tocTemplateDuplicateName =>
      'Đã có mẫu với tên và phần mở rộng này.';

  @override
  String get tocTemplateFormat => 'Định dạng:';

  @override
  String get tocTemplateReset => 'Đặt lại';

  @override
  String get tocTemplateRetry => 'Thử lại';

  @override
  String tocRemoveElementsDialog(int count) {
    return 'Xóa $count phần tử mục lục';
  }

  @override
  String get tocRemoveElementsRetainFiles =>
      'Các tệp nguồn liên kết với những phần tử mục lục này sẽ không bị xóa.';

  @override
  String get tocOk => 'OK';

  @override
  String get tocSelectExistingTopic =>
      'Chọn chủ đề để thêm vào phiên bản hiện tại';

  @override
  String get tocGroupName => 'Tên nhóm';

  @override
  String get tocMoveLineUp => 'Di chuyển dòng lên';

  @override
  String get tocMoveLineDown => 'Di chuyển dòng xuống';

  @override
  String get tocEmptyMdTopic => 'Chủ đề MD trống';

  @override
  String get tocEmptyXmlTopic => 'Chủ đề XML trống';

  @override
  String get tocCopySpecial => 'Sao chép đặc biệt';

  @override
  String tocCopyFileName(String name) {
    return 'Tên tệp chủ đề \'$name\'';
  }

  @override
  String get tocCopyFilePath => 'Đường dẫn tệp chủ đề';

  @override
  String tocCopyTopicTitle(String title) {
    return 'Tiêu đề chủ đề \'$title\'';
  }

  @override
  String tocCopyElementId(String id) {
    return 'ID phần tử mục lục \'$id\'';
  }

  @override
  String get tocCopyFileNameUnavailable => 'Tên tệp chủ đề';

  @override
  String get tocCopyTopicTitleUnavailable => 'Tiêu đề chủ đề';

  @override
  String get tocCopyElementIdUnavailable => 'ID phần tử mục lục';

  @override
  String get tocEditTitleAction => 'Sửa tiêu đề...';

  @override
  String get tocEditTitleDialog => 'Sửa tiêu đề';

  @override
  String get tocRemoveElementAction => 'Xóa phần tử mục lục...';

  @override
  String get tocSetHomePage => 'Đặt làm trang chủ';

  @override
  String tocGoToElement(String fileName) {
    return 'Đi đến phần tử mục lục trong \'$fileName\'';
  }

  @override
  String get tocSynchronize => 'Đồng bộ mục lục và trình soạn thảo';

  @override
  String get tocEmptyGroupAction => 'Nhóm trống';

  @override
  String get tocNewEmptyGroup => 'Nhóm trống mới';

  @override
  String get tocGroupAction => 'Nhóm lại';

  @override
  String get tocNewGroup => 'Nhóm mới';

  @override
  String get tocSortChildren => 'Sắp xếp chủ đề con theo bảng chữ cái';

  @override
  String get tocLinkTopicFiles => 'Liên kết tệp chủ đề với mục lục...';

  @override
  String get addLocalMarkdownFiles => 'Thêm tệp Markdown cục bộ';

  @override
  String get tocTitleField => 'Tiêu đề mục lục:';

  @override
  String get tocTopicTitleField => 'Tiêu đề chủ đề:';

  @override
  String get tocAdvancedSettings => 'Cài đặt nâng cao';

  @override
  String tocInstanceTitleField(String instanceId) {
    return 'Tiêu đề cho \'$instanceId\':';
  }

  @override
  String get tocOnlyTitleField => 'Tiêu đề chỉ dành cho mục lục:';

  @override
  String get tocInstanceTitleExplanation =>
      'Chỉ dùng cho thực thể hiện tại. Theo mặc định, kế thừa từ tiêu đề chủ đề.';

  @override
  String get tocOnlyTitleExplanation =>
      'Chỉ dùng trong mục lục. Theo mặc định, kế thừa từ tiêu đề chủ đề hoặc tiêu đề riêng của thực thể nếu đã đặt. Phần giải thích về tiêu đề có';

  @override
  String get tocTitleDocumentationLink => 'tại đây';

  @override
  String get tocFindUsages => 'Tìm';

  @override
  String get tocRefactorMenu => 'Tái cấu trúc';

  @override
  String get tocSafeDelete => 'Xóa an toàn';

  @override
  String get tocDuplicate => 'Nhân bản';

  @override
  String get tocDuplicateFilename => 'Tên tệp chủ đề:';

  @override
  String get tocDuplicateDialog => 'Nhân bản chủ đề';

  @override
  String get pdfTitlePage => 'Trang tiêu đề';

  @override
  String get pdfIncludeTitlePage => 'Bao gồm trang tiêu đề';

  @override
  String get pdfTitlePageNote =>
      'Trang này không có đầu trang, chân trang hoặc số trang hiển thị.';

  @override
  String get pdfTitlePageTitle => 'Tiêu đề';

  @override
  String get pdfTitlePageSubtitle => 'Phụ đề';

  @override
  String get pdfTitlePageAuthor => 'Tác giả';

  @override
  String get pdfTitlePageOrganization => 'Tổ chức';

  @override
  String get pdfTitlePageVersion => 'Phiên bản';

  @override
  String get pdfTitlePageDate => 'Ngày';

  @override
  String get pdfTitlePageTitleRequired => 'Nhập tiêu đề cho trang tiêu đề.';

  @override
  String get pdfTocSectionNote =>
      'Bắt đầu trên trang riêng và có thể kéo dài nhiều trang.';

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
  String get feedbackReplyEmail => 'Email để trả lời (tùy chọn)';

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
  String get copyPlainText => 'Sao chép dưới dạng văn bản thuần';

  @override
  String get clipboardCopyFailed =>
      'Không thể sao chép nội dung đã chọn vào bảng nhớ tạm.';

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
  String get validation => 'Xác minh';

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
      'Tùy chỉnh phím tắt của ứng dụng';

  @override
  String get shortcutSyntaxReferenceDescription => 'Mở tham chiếu cú pháp';

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
  String get instanceName => 'Tên thực thể';

  @override
  String get instanceId => 'ID thực thể';

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
  String get wordWrapDescription =>
      'Ngắt các dòng dài cho vừa chiều rộng trình biên tập thay vì cuộn ngang.';

  @override
  String get editorFontSize => 'Cỡ chữ trình biên tập';

  @override
  String get validateOnEdit => 'Kiểm tra khi chỉnh sửa';

  @override
  String get clearRecentWorkspaces => 'Xóa lịch sử gần đây';

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
  String get settingsEditingButtonsSectionTitle => 'Nút chỉnh sửa';

  @override
  String get spellingDictionaries => 'Từ điển chính tả';

  @override
  String get spellingDictionariesDescription =>
      'Cài đặt và quản lý từ điển chính tả';

  @override
  String get settingsDictionariesSectionTitle => 'Từ điển';

  @override
  String get availableSpellingDictionaries => 'Từ điển có sẵn';

  @override
  String get customSpellingDictionaries => 'Từ điển tùy chỉnh';

  @override
  String get spellingDictionaryProblems => 'Sự cố từ điển';

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
  String get insertBlankLine => 'Chèn dòng trống';

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
  String get newSiblingTopic => 'Chủ đề mới';

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
  String get removeTocElements => 'Xóa các phần tử mục lục';

  @override
  String get reviewUsages => 'Xem lại các tham chiếu';

  @override
  String get deleteTopicFile => 'Xóa tệp chủ đề';

  @override
  String get removeAction => 'Xóa';

  @override
  String topicRemovalSummary(String topic) {
    return 'Xóa phần tử mục lục “$topic”? Tệp nguồn được liên kết với mục lục sẽ không bị xóa.';
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
  String get topicIsHomePageRemovalWarning =>
      'Chủ đề này là trang chủ của thực thể này. Chọn trang chủ khác trước khi xóa chủ đề khỏi mục lục.';

  @override
  String get newHomePage => 'Trang chủ mới';

  @override
  String get chooseHomePage => 'Chọn trang chủ';

  @override
  String get noHomePageReplacement =>
      'Thêm hoặc liên kết một chủ đề hợp lệ khác vào thực thể này trước khi xóa trang chủ của nó.';

  @override
  String get topicIsStartPageRemovalWarning =>
      'Chủ đề này là trang chủ của một thực thể. Chỉ định trang chủ khác trước khi xóa tệp nguồn của chủ đề.';

  @override
  String topicUsagesCount(int count) {
    return 'Tìm thấy $count lượt sử dụng.';
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
  String get topicUsageStartPages => 'Các trang chủ';

  @override
  String get topicUsageTopicLinks => 'Liên kết chủ đề';

  @override
  String get topicUsageIncludes => 'Các phần tử include';

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
  String get setRedirectTo => 'Đặt chuyển hướng đến:';

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
  String get outsideSelectedInstance => 'bên ngoài thực thể đã chọn';

  @override
  String get doRefactor => 'Tái cấu trúc';

  @override
  String get preview => 'Xem trước';

  @override
  String get topicRenamePreviewTitle => 'Xem trước việc đổi tên';

  @override
  String topicRenamePathChange(String oldPath, String newPath) {
    return 'Đường dẫn: $oldPath → $newPath';
  }

  @override
  String topicRenameIdChange(String oldId, String newId) {
    return 'ID chủ đề: $oldId → $newId';
  }

  @override
  String topicRenameUrlChange(String instance, String oldName, String newName) {
    return 'Phiên bản $instance: $oldName → $newName';
  }

  @override
  String get topicRenameAffectedFiles => 'Các tệp bị ảnh hưởng';

  @override
  String get orphanTopicTitle => 'Tệp chủ đề không còn được sử dụng';

  @override
  String get keepTopicFile => 'Giữ tệp chủ đề';

  @override
  String orphanTopicMessage(String topic) {
    return '“$topic” không còn được sử dụng ở đâu trong dự án Writerside này. Xóa tệp hoặc giữ lại để dùng trong thực thể khác.';
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
  String get workspaceSearchIncomplete =>
      'Chỉ hiển thị một phần kết quả. Hiển thị thêm hoặc thu hẹp tìm kiếm.';

  @override
  String get workspaceSearchShowMore => 'Hiển thị thêm kết quả';

  @override
  String get workspaceSearchSkippedFiles =>
      'Tìm kiếm chưa đầy đủ. Các tệp này vượt quá 1 MiB hoặc không thể đọc được:';

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
  String workspaceErrorRecentWorkspaceUpdateFailed(String error) {
    return 'Không thể cập nhật các mục gần đây: $error.';
  }

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
      'ID thực thể phải bắt đầu bằng chữ thường và chỉ gồm chữ thường, chữ số, dấu gạch dưới và dấu gạch nối.';

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
      'Mô-đun Writerside không có cây thực thể.';

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
    return 'Không thể xóa trang chủ $topic. Hãy chọn trang chủ khác trước.';
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
  String errorWritersideTopicRenameIncompleteProjectIndex(
    String module,
    String count,
    String paths,
  ) {
    return 'Không thể đổi tên và cập nhật an toàn mọi tham chiếu trong dự án vì $count tệp chủ đề trong mô-đun $module chưa được phân tích: $paths';
  }

  @override
  String get errorWritersideTopicRenameProjectBuffersDirty =>
      'Các tệp dự án Writerside có thay đổi chưa lưu. Hãy xử lý chúng và chuẩn bị bản xem trước đổi tên mới.';

  @override
  String get errorWritersideTopicRenameProjectInventoryChanged =>
      'Tập hợp mô-đun của dự án Writerside đã thay đổi. Hãy chuẩn bị bản xem trước đổi tên mới trước khi tái cấu trúc.';

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
      'writerside.cfg không đăng ký thực thể nào.';

  @override
  String get diagnosticWritersideTreeInvalidRoot =>
      'Gốc .tree phải là <instance-profile>.';

  @override
  String get diagnosticWritersideTreeMissingId => 'Hồ sơ thực thể thiếu id.';

  @override
  String diagnosticWritersideTreeIdMismatch(String id) {
    return 'Tên gốc của tệp cây không khớp với ID thực thể \"$id\".';
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
    return 'Chủ đề \"$topic\" xuất hiện nhiều hơn một lần trong mục lục của thực thể này.';
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
    return 'Tệp nhóm thực thể đã định không tồn tại: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceTree(String source) {
    return 'Cây thực thể đã đăng ký \"$source\" không tồn tại.';
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
  String diagnosticWritersideWebFileNameInvalid(
    String instanceId,
    String webFileName,
    String topic,
  ) {
    return 'Phiên bản \"$instanceId\" xuất bản tên tệp web không hợp lệ \"$webFileName\" cho chủ đề \"$topic\".';
  }

  @override
  String diagnosticWritersideWebFileNameCollision(
    String instanceId,
    String webFileName,
    String firstTopic,
    String secondTopic,
  ) {
    return 'Phiên bản \"$instanceId\" xuất bản cả \"$firstTopic\" và \"$secondTopic\" dưới tên \"$webFileName\".';
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
  String get gitClean => 'Không có thay đổi';

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
      'Có nhiều remote được cấu hình. Hãy chọn upstream bên ngoài thực thể BusyMark này.';

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
      'Nhánh đã phân kỳ. Hãy giải quyết thao tác merge hoặc rebase bên ngoài thực thể BusyMark này.';

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
  String get syntaxReference => 'Tham chiếu cú pháp';

  @override
  String get syntaxReferenceMarkdownBlocks => 'Khối Markdown';

  @override
  String get syntaxReferenceMarkdownBlocksDescription =>
      'Các cấu trúc khối được hỗ trợ trong mã nguồn và bản xem trước Markdown.';

  @override
  String get syntaxReferenceInlineFormatting => 'Định dạng Markdown nội tuyến';

  @override
  String get syntaxReferenceInlineFormattingDescription =>
      'Định dạng có thể xuất hiện trong đoạn văn, mục danh sách và ô bảng.';

  @override
  String get syntaxReferenceRawHtmlBlocks => 'Khối HTML thô';

  @override
  String get syntaxReferenceRawHtmlBlocksDescription =>
      'Các thẻ HTML cấp khối an toàn được kết xuất thông qua các tiện ích xem trước của BusyMark.';

  @override
  String get syntaxReferenceRawHtmlInline => 'Thẻ HTML nội tuyến thô';

  @override
  String get syntaxReferenceRawHtmlInlineDescription =>
      'Các thẻ HTML nội tuyến an toàn được kết xuất mà không hiển thị thẻ theo nghĩa đen.';

  @override
  String get syntaxReferenceHeadings => 'Tiêu đề';

  @override
  String get syntaxReferenceParagraphs => 'Đoạn văn';

  @override
  String get syntaxReferenceLists => 'Danh sách';

  @override
  String get syntaxReferenceHtmlContainers => 'Vùng chứa';

  @override
  String get syntaxReferenceHtmlTextBlocks => 'Khối văn bản';

  @override
  String get syntaxReferenceHtmlFigures => 'Figure và hình ảnh';

  @override
  String get syntaxReferenceHtmlPreformatted => 'Mã định dạng sẵn';

  @override
  String get syntaxReferenceHtmlDisclosure => 'Khối mở rộng';

  @override
  String get syntaxReferenceHtmlDescriptionLists => 'Danh sách mô tả';

  @override
  String get syntaxReferenceHtmlFormattingTags => 'Thẻ định dạng';

  @override
  String get syntaxReferenceHtmlInlineCodeTags => 'Thẻ mã nội tuyến';

  @override
  String get syntaxReferenceHtmlNeutralInlineTags => 'Thẻ văn bản ngữ nghĩa';

  @override
  String get syntaxReferenceSanitizedPreviewDescription =>
      'HTML được cho phép được chuyển thành các khối xem trước của BusyMark, không được kết xuất trong trình duyệt.';

  @override
  String get syntaxReferenceSourcePreservedDescription =>
      'HTML thô chưa chỉnh sửa được lưu lại chính xác như văn bản mã nguồn.';

  @override
  String get syntaxReferenceMarkdownInsideHtmlDescription =>
      'Các dấu Markdown bên trong HTML thô được kết xuất như văn bản theo nghĩa đen.';

  @override
  String get syntaxReferenceBlockedContentDescription =>
      'Script, style, frame, form, SVG, MathML, sự kiện và các thuộc tính không an toàn bị chặn.';

  @override
  String get syntaxReferenceSafeUrlsDescription =>
      'Liên kết cho phép URL http, https, mailto, tel, tương đối và fragment; các scheme không an toàn bị chặn.';

  @override
  String get syntaxReferenceCategory => 'Danh mục';

  @override
  String get syntaxReferenceCategoryHtml => 'HTML';

  @override
  String get syntaxReferenceCategoryDiagramsAndApi => 'Sơ đồ và API';

  @override
  String get syntaxReferenceCategoryMathematics => 'Toán học';

  @override
  String get syntaxReferenceExample => 'Ví dụ';

  @override
  String get syntaxReferenceIdentifiers => 'Định danh và bí danh';

  @override
  String get syntaxReferenceScope => 'Phạm vi';

  @override
  String get syntaxReferenceLimitation => 'Giới hạn của BusyMark';

  @override
  String get syntaxReferenceOfficialDocumentation => 'Tài liệu chính thức';

  @override
  String get syntaxReferenceScopeWritersideMarkdown =>
      'Chỉ Markdown Writerside';

  @override
  String get syntaxReferenceScopeWritersideMarkdownAndXml =>
      'Chỉ Markdown Writerside và XML Writerside';

  @override
  String get syntaxReferenceMarkdownDescription =>
      'Các dạng Markdown cốt lõi mà BusyMark có thể soạn và xem trước.';

  @override
  String get syntaxReferenceParagraphExample => 'Một đoạn văn bản.';

  @override
  String get syntaxReferenceTableLimitation =>
      'Bảng dùng cú pháp dấu gạch đứng của GitHub Flavored Markdown.';

  @override
  String get syntaxReferenceHardBreakIdentifiers =>
      'hai dấu cách ở cuối dòng, \\, <br>';

  @override
  String get syntaxReferenceHtmlDescription =>
      'BusyMark chấp nhận một tập con HTML thô an toàn, có giới hạn trong mã nguồn Markdown.';

  @override
  String get syntaxReferenceDiagramsDescription =>
      'Các khối có hàng rào Mermaid, PlantUML, D2 và OpenAPI hoạt động trong mã nguồn Markdown. Định danh hàng rào không phân biệt hoa thường và BusyMark giữ nguyên cách viết ban đầu.';

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
      'Dùng nội dung YAML hoặc JSON có hàng rào. BusyMark không coi một tài liệu YAML hoặc JSON toàn tệp bất kỳ là tham chiếu OpenAPI.';

  @override
  String get syntaxReferenceSemanticDiagramBlocks =>
      'Khối mã ngữ nghĩa cho sơ đồ';

  @override
  String get syntaxReferenceSemanticDiagramLimitation =>
      'Dạng ngữ nghĩa code-block và src hỗ trợ Mermaid, PlantUML và D2, không hỗ trợ OpenAPI, và chỉ dùng trong dự án Writerside.';

  @override
  String get syntaxReferenceReferencedDiagramSource =>
      'Nguồn sơ đồ được tham chiếu';

  @override
  String get syntaxReferenceReferencedDiagramLimitation =>
      'Đường dẫn phải tương đối và nằm trong dự án Writerside đang mở; dạng hàng rào kèm src chỉ dành cho Markdown Writerside.';

  @override
  String get syntaxReferenceMathematicsDescription =>
      'BusyMark hỗ trợ biểu thức TeX, không hỗ trợ tài liệu TeX hoặc LaTeX hoàn chỉnh.';

  @override
  String get syntaxReferenceInlineMath => 'Toán học nội dòng';

  @override
  String get syntaxReferenceGithubMath =>
      'Toán học GitHub với dấu đô la và dấu huyền';

  @override
  String get syntaxReferenceDisplayMath => 'Toán học dạng khối';

  @override
  String get syntaxReferenceMathFence => 'Hàng rào math';

  @override
  String get syntaxReferenceTexFence => 'Hàng rào tex';

  @override
  String get syntaxReferenceMathDelimitersLimitation =>
      'BusyMark không nhận dạng \\(...\\) hoặc \\[...\\] là dấu phân cách toán học Markdown.';

  @override
  String get syntaxReferenceTexFenceLimitation =>
      'Ngoài chế độ Writerside, hàng rào tex vẫn là khối mã thông thường.';

  @override
  String get syntaxReferenceWritersideMathElement =>
      'Phần tử math của Writerside';

  @override
  String get syntaxReferenceWritersideMathElementLimitation =>
      'Phần tử math là cú pháp Writerside ngữ nghĩa, không phải HTML MathML thô được phép.';

  @override
  String get syntaxReferenceSemanticTexBlock => 'Khối mã TeX ngữ nghĩa';

  @override
  String get syntaxReferenceWritersideDescription =>
      'Các phần mở rộng trọng tâm này chỉ được diễn giải trong dự án Writerside đang mở.';

  @override
  String get syntaxReferenceAdmonitionBlockquote => 'Trích dẫn khối lưu ý';

  @override
  String get syntaxReferenceAdmonitionLimitation =>
      'Trích dẫn khối thuần là mẹo trong Markdown Writerside; trong Markdown thông thường, nó vẫn là trích dẫn thường.';

  @override
  String get syntaxReferenceSemanticAdmonitions => 'Lưu ý ngữ nghĩa';

  @override
  String get syntaxReferenceSemanticMarkupLimitation =>
      'Markdown thông thường không diễn giải các phần tử Writerside ngữ nghĩa này.';

  @override
  String get syntaxReferenceCollapsibleHeading => 'Tiêu đề có thể thu gọn';

  @override
  String get syntaxReferenceCollapsibleCode => 'Hàng rào mã có thể thu gọn';

  @override
  String get syntaxReferenceSemanticCollapsibles =>
      'Nội dung ngữ nghĩa có thể thu gọn';

  @override
  String get syntaxReferenceSemanticCollapsiblesLimitation =>
      'BusyMark hỗ trợ các dạng chapter, procedure, code-block và danh sách định nghĩa có thể thu gọn, không hỗ trợ toàn bộ danh mục Writerside.';

  @override
  String get syntaxReferenceSemanticCodeBlocks =>
      'Khối mã ngữ nghĩa cho toán học và sơ đồ';

  @override
  String get syntaxReferenceVideo => 'Video Writerside';

  @override
  String get syntaxReferenceVideoLimitation =>
      'Video cục bộ dùng ảnh preview-src cục bộ; nguồn lưu trữ phải là URL HTTPS YouTube hoặc Vimeo được hỗ trợ.';

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
  String get exportFormat => 'Định dạng đầu ra';

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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cảnh báo',
      one: '1 cảnh báo',
    );
    return 'Đã xuất $fileName với $_temp0.';
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
  String get instances => 'Các thực thể';

  @override
  String get newInstance => 'Thực thể mới';

  @override
  String get newTocLibrary => 'Thư viện mục lục mới';

  @override
  String get editInstance => 'Chỉnh sửa thực thể';

  @override
  String get openTocFile => 'Mở tệp mục lục';

  @override
  String get createInstance => 'Tạo thực thể';

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
  String get instanceIdRenameWarningTitle => 'Đổi tên ID thực thể?';

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
  String get errorWritersideInstanceNameRequired => 'Nhập tên thực thể.';

  @override
  String errorWritersideInstanceIdExists(String id) {
    return 'Đã có thực thể với ID “$id”.';
  }

  @override
  String errorWritersideInstanceTreeExists(String path) {
    return 'Cây thực thể đã tồn tại: $path';
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
      'Các tệp thực thể đã thay đổi trên đĩa. Hãy xem lại và thử lại.';

  @override
  String errorWritersideInstanceRollbackFailed(String paths) {
    return 'BusyMark không thể khôi phục hoàn toàn thay đổi của thực thể. Hãy xem lại các tệp này trước khi tiếp tục: $paths';
  }

  @override
  String get errorWritersideInstanceLibraryImport =>
      'Thư viện mục lục không thể nhập các chủ đề Markdown.';

  @override
  String get errorWritersideInstanceWebPathInvalid =>
      'Đường dẫn web phải nằm trên một dòng duy nhất.';

  @override
  String get errorWritersideInstanceConfigurationInvalid =>
      'Cấu hình thực thể Writerside không hợp lệ. Hãy sửa các chẩn đoán rồi thử lại.';

  @override
  String get errorWritersideInstanceTemporaryFile =>
      'BusyMark không thể đưa các thay đổi của thực thể vào stage một cách an toàn.';

  @override
  String diagnosticWritersideTreeInvalidStatus(String status) {
    return 'Trạng thái thực thể không xác định “$status”. Sử dụng release, eap hoặc deprecated.';
  }

  @override
  String diagnosticWritersideDuplicateInstanceId(String id) {
    return 'ID thực thể “$id” được nhiều tệp cây sử dụng.';
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
      'Phần tử <build-profile> phải chỉ định ID thực thể.';

  @override
  String get diagnosticWritersideTreeInvalidInclude =>
      '<include> trong cây phải chỉ định cả from và element-id.';

  @override
  String get diagnosticWritersideTreeMissingSnippetId =>
      '<snippet> trong cây phải chỉ định id.';

  @override
  String get diagnosticWritersideTreeInvalidCrossInstanceReference =>
      'Tham chiếu mục lục giữa các thực thể phải chỉ định cả ref và in.';

  @override
  String get diagnosticWritersideTreeConflictingTargets =>
      'Một phần tử mục lục không thể nhắm đến nhiều hơn một chủ đề, tham chiếu, liên kết hoặc chuyển hướng.';

  @override
  String diagnosticWritersideTreeDuplicateElementId(String id) {
    return 'ID phần tử cây “$id” được khai báo nhiều hơn một lần.';
  }

  @override
  String get diagnosticWritersideInstanceGroupsInvalidRoot =>
      'Tệp nhóm thực thể phải có phần tử gốc <instance-groups>.';

  @override
  String get diagnosticWritersideInstanceGroupInvalid =>
      'Một nhóm thực thể phải chỉ định id không trống và danh sách thực thể.';

  @override
  String diagnosticWritersideInstanceGroupDuplicateId(String id) {
    return 'ID nhóm thực thể “$id” được khai báo nhiều hơn một lần.';
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
    return 'Điều kiện thực thể tham chiếu đến nhóm không xác định “@$group”.';
  }

  @override
  String diagnosticWritersideReferenceInstanceMissing(String instance) {
    return 'Tham chiếu giữa các thực thể nhắm đến thực thể không xác định “$instance”.';
  }

  @override
  String diagnosticWritersideReferenceTopicMissing(
    String topic,
    String instance,
  ) {
    return 'Chủ đề “$topic” không nằm trong thực thể được tham chiếu “$instance”.';
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
  String get aiExplicitEditingDescription =>
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

  @override
  String get goToDeclaration => 'Đi đến khai báo';

  @override
  String get findUsages => 'Tìm nơi sử dụng';

  @override
  String get cannotRenameSymbol =>
      'Không thể đổi tên ký hiệu một cách an toàn. Kiểm tra tên và làm mới tham chiếu trước khi thử lại.';

  @override
  String get renameTopicFileInstead =>
      'ID chủ đề được tạo từ tên tệp. Hãy dùng Đổi tên tệp chủ đề trong mục lục hoặc thanh bên Tệp.';

  @override
  String get keyboardLayout => 'Bố cục bàn phím';

  @override
  String get diagnosticWritersideUnsupported =>
      'Nội dung không được hỗ trợ hoặc sai định dạng được hiển thị dưới dạng mã nguồn.';

  @override
  String diagnosticWritersideSource(String reference, String reason) {
    return 'Không thể phân giải nguồn “$reference”: $reason';
  }

  @override
  String diagnosticWritersideLink(String destination) {
    return 'Đích liên kết không khả dụng trong phiên bản này: $destination';
  }

  @override
  String diagnosticWritersideSchema(
    String element,
    String attribute,
    String reason,
  ) {
    return 'Đánh dấu Writerside không hợp lệ: $element, $attribute. $reason';
  }

  @override
  String get diagnosticWritersideLlmsTxt =>
      'Dùng <llms-txt>true</llms-txt> hoặc <llms-txt>false</llms-txt>; single-file không còn được hỗ trợ.';

  @override
  String diagnosticWritersideReference(String kind, String reference) {
    return 'Không thể phân giải $kind: $reference';
  }

  @override
  String get exportAsHtml => 'Xuất dưới dạng HTML…';

  @override
  String get fileTypeHtml => 'Tài liệu HTML';

  @override
  String get exportingHtml => 'Đang xuất HTML…';

  @override
  String get htmlExported => 'Xuất HTML hoàn tất';

  @override
  String get htmlExportFailed => 'Xuất HTML thất bại';

  @override
  String get htmlKeepAssetsTogether =>
      'Khi sao chép bản xuất, hãy giữ tệp HTML và thư mục tài nguyên đi kèm ở cùng nhau.';

  @override
  String get htmlInstanceDescription =>
      'Xuất một phiên bản thành các trang ngoại tuyến có liên kết. Chọn tên cho thư mục đầu ra riêng.';

  @override
  String get htmlInstance => 'Phiên bản';

  @override
  String get htmlOwnedDirectoryOnly =>
      'Chỉ có thể thay thế thư mục được tạo bởi chức năng xuất HTML của BusyMark. Các tệp đã sửa đổi hoặc không liên quan sẽ được giữ lại.';

  @override
  String get showInFolder => 'Hiển thị trong thư mục';

  @override
  String sortTableColumn(String column) {
    return 'Sắp xếp $column';
  }

  @override
  String get exportReset => 'Khôi phục mặc định';

  @override
  String get exportToc => 'Bao gồm mục lục';

  @override
  String get exportTocDepth => 'Độ sâu mục lục';

  @override
  String get exportNumberHeadings => 'Đánh số tiêu đề';

  @override
  String get exportLegal => 'US Legal';

  @override
  String get exportCustom => 'Tùy chỉnh';

  @override
  String get exportPageWidth => 'Chiều rộng trang (mm)';

  @override
  String get exportPageHeight => 'Chiều cao trang (mm)';

  @override
  String get exportMarginTop => 'Lề trên (mm)';

  @override
  String get exportMarginRight => 'Lề phải (mm)';

  @override
  String get exportMarginBottom => 'Lề dưới (mm)';

  @override
  String get exportMarginLeft => 'Lề trái (mm)';

  @override
  String get exportTypography => 'Kiểu chữ';

  @override
  String get exportSans => 'Không chân';

  @override
  String get exportSerif => 'Có chân';

  @override
  String get exportBodySize => 'Cỡ chữ nội dung';

  @override
  String get exportCodeSize => 'Cỡ chữ mã';

  @override
  String get exportRunningText => 'Đầu trang và chân trang';

  @override
  String get exportHeader => 'Đầu trang';

  @override
  String get exportFooter => 'Chân trang';

  @override
  String get exportNone => 'Không có';

  @override
  String get exportDocumentTitle => 'Tiêu đề tài liệu';

  @override
  String get exportBottomLeft => 'Dưới bên trái';

  @override
  String get exportBottomCenter => 'Dưới ở giữa';

  @override
  String get exportBottomRight => 'Dưới bên phải';

  @override
  String get exportFirstPage => 'Hiện đầu trang và chân trang ở trang đầu';

  @override
  String get exportAccent => 'Màu nhấn / liên kết';

  @override
  String get exportTheme => 'Giao diện';

  @override
  String get exportAutomatic => 'Tự động';

  @override
  String get exportLayout => 'Bố cục';

  @override
  String get exportContentWidth => 'Chiều rộng nội dung tối đa';

  @override
  String get exportOutput => 'Đầu ra';

  @override
  String get exportPackaging => 'Đóng gói';

  @override
  String get exportSingleFile => 'Một tệp HTML';

  @override
  String get exportAssetsDirectory => 'HTML + thư mục tài nguyên';

  @override
  String get exportCustomCss => 'Biểu định kiểu tùy chỉnh…';

  @override
  String get exportRemoveCss => 'Xóa biểu định kiểu tùy chỉnh';

  @override
  String get exportCssNote =>
      'Chọn tệp CSS UTF-8 tùy chọn (tối đa 256 KiB). Không chấp nhận nhập tài nguyên, URL tài nguyên, CSS thực thi hoặc có ký tự thoát. Kiểu được áp dụng sau CSS của BusyMark. Không tải tài nguyên từ xa.';

  @override
  String get exportSitePackagingNote =>
      'Writerside giữ các trang chủ đề riêng có liên kết. Chế độ một tệp nhúng tài nguyên vào từng trang.';

  @override
  String get exportInvalidGeometry =>
      'Sau khi trừ lề, hãy để nội dung rộng và cao ít nhất 20 mm.';

  @override
  String get exportInvalidColor => 'Nhập màu theo dạng #RRGGBB.';

  @override
  String get exportInvalidCss =>
      'Chọn tệp .css UTF-8 đọc được tối đa 256 KiB, không có nhập tài nguyên, URL tài nguyên, HTML, CSS thực thi hoặc ký tự thoát.';

  @override
  String get clipboardHistory => 'Lịch sử sao chép';

  @override
  String get clipboardHistoryDescription => 'Mở lịch sử sao chép cục bộ phiên.';

  @override
  String get clipboardCurrent => 'Lịch sử sao chép hiện tại';

  @override
  String get clipboardCurrentExternal =>
      'Lịch sử sao chép từ một ứng dụng khác';

  @override
  String clipboardDestination(String name) {
    return 'Dán vào $name';
  }

  @override
  String get clipboardSessionOnly => 'Chỉ lưu trong phiên BusyMark này.';

  @override
  String get clipboardNoItems => 'Lịch sử sao chép trống.';

  @override
  String get clipboardDisabled =>
      'Bộ sưu tập Lịch sử sao chép bị vô hiệu hóa trong Cài đặt.';

  @override
  String get clipboardUnavailable =>
      'Nội dung sao chép hiện tại không khả dụng hoặc không được hỗ trợ.';

  @override
  String get clipboardTooLarge => 'Mục này trong clipboard quá lớn để lưu.';

  @override
  String get clipboardPastePlainText => 'Dán dưới dạng văn bản thuần túy';

  @override
  String get clipboardClearAll => 'Xóa lịch sử clipboard';

  @override
  String get clipboardEntryText => 'Văn bản';

  @override
  String get clipboardEntryRichText => 'Văn bản phong phú';

  @override
  String get clipboardEntryImage => 'Hình ảnh';

  @override
  String clipboardOrigin(String name) {
    return 'Sao chép từ $name';
  }

  @override
  String get localHistory => 'Lịch sử cục bộ';

  @override
  String get localHistoryEllipsis => 'Lịch sử cục bộ…';

  @override
  String get localHistoryDescription =>
      'Hiển thị các phiên bản cục bộ đã lưu và tự động cho tài liệu hiện tại.';

  @override
  String get findLocalHistoryEllipsis => 'Tìm trong Lịch sử cục bộ…';

  @override
  String get findLocalHistoryDescription =>
      'Tìm kiếm các tài liệu và nội dung phiên bản trong Lịch sử cục bộ.';

  @override
  String get localHistoryNoDocuments =>
      'Chưa có tài liệu nào có Lịch sử cục bộ.';

  @override
  String get localHistoryNoRevisions =>
      'Tài liệu này không có các phiên bản Lịch sử cục bộ.';

  @override
  String get localHistorySelectedRevision => 'Phiên bản đã chọn';

  @override
  String get localHistoryCurrentEditor => 'Nội dung trình soạn thảo hiện tại';

  @override
  String get localHistoryCurrentDisk => 'Nội dung hiện tại trên ổ đĩa';

  @override
  String get localHistoryMissingFile => 'Tệp gốc bị thiếu.';

  @override
  String get localHistoryRestoreRevision => 'Khôi phục Phiên bản';

  @override
  String get localHistoryRestoreOriginalLocation =>
      'Khôi phục về Vị trí Ban đầu';

  @override
  String get localHistoryRestoreNewLocation => 'Khôi phục về Vị trí Mới…';

  @override
  String get localHistoryRestoreChange => 'Khôi phục Thay đổi';

  @override
  String get localHistoryRestoreUnavailable =>
      'Thay đổi này không thể khôi phục vì so sánh không còn hợp lệ.';

  @override
  String get localHistoryComparisonSimplified =>
      'So sánh này rất lớn, khôi phục thay đổi riêng không khả thi.';

  @override
  String localHistoryOlderChange(String text) {
    return 'Thay đổi phiên bản cũ: $text';
  }

  @override
  String localHistoryCurrentChange(String text) {
    return 'Thay đổi nội dung hiện tại: $text';
  }

  @override
  String get localHistoryDeleted => 'Xóa';

  @override
  String get localHistoryUntitled => 'Không có tiêu đề';

  @override
  String get localHistoryClearDocument => 'Xóa Lịch Sử Của Tài Liệu Này';

  @override
  String get localHistoryClearAll => 'Xóa Lịch Sử Địa Phương';

  @override
  String get localHistoryClearDocumentTitle => 'Xóa lịch sử tài liệu?';

  @override
  String get localHistoryClearAllTitle => 'Xóa lịch sử địa phương?';

  @override
  String get localHistoryClearConfirmation =>
      'Điều này sẽ xóa vĩnh viễn các phiên bản đã lưu. Hành động này không thể hoàn tác.';

  @override
  String get localHistoryWarningIndexRebuilt =>
      'Chỉ mục Lịch Sử Địa Phương bị hỏng và được xây dựng lại từ các phiên bản còn nguyên vẹn.';

  @override
  String localHistoryWarningUnsupportedFormat(String version) {
    return 'Kho Lịch Sử Địa Phương sử dụng định dạng không được hỗ trợ $version.';
  }

  @override
  String localHistoryWarningUnavailable(String detail) {
    return 'Lịch Sử Địa Phương không khả dụng: $detail';
  }

  @override
  String get localHistoryWarningRecordingDisabled =>
      'Ghi âm bị tắt hoặc đường dẫn này bị loại trừ. Vui lòng bật lại ghi âm trước khi khôi phục.';

  @override
  String localHistoryWarningPathChange(String detail) {
    return 'Lịch Sử Địa Phương không thể ghi lại thay đổi đường dẫn: $detail';
  }

  @override
  String localHistoryWarningDeletedPath(String detail) {
    return 'Lịch sử cục bộ không thể lưu trữ đường dẫn đã xóa: $detail';
  }

  @override
  String get localHistoryWarningRevisionMissing =>
      'Phiên bản đã chọn bị thiếu hoặc bị hỏng.';

  @override
  String localHistoryWarningRevisionRead(String detail) {
    return 'Phiên bản đã chọn không thể đọc: $detail';
  }

  @override
  String localHistoryWarningCapture(String detail) {
    return 'Lịch sử cục bộ không thể ghi lại phiên bản này: $detail';
  }

  @override
  String localHistoryRevisionAt(String reason, String timestamp) {
    return '$reason – $timestamp';
  }

  @override
  String get localHistoryReasonBaseline => 'Mốc cơ sở';

  @override
  String get localHistoryReasonSaved => 'Lưu';

  @override
  String get localHistoryReasonAutomaticCheckpoint => 'Tự động lưu';

  @override
  String get localHistoryReasonBeforeReload => 'Trước khi tải lại';

  @override
  String get localHistoryReasonBeforeDiscard => 'Trước khi vứt';

  @override
  String get localHistoryReasonBeforeRestore => 'Trước khi khôi phục';

  @override
  String get localHistoryReasonBeforeDelete => 'Trước khi xóa';

  @override
  String get localHistoryReasonExternalChange => 'Thay đổi từ bên ngoài';

  @override
  String get settingsHistory => 'Lịch sử';

  @override
  String get settingsClipboardHistoryTitle => 'Thu thập lịch sử sao chép';

  @override
  String get settingsClipboardHistoryDescription =>
      'Giữ nội dung đã sao chép và dán thành công chỉ cho phiên BusyMark này.';

  @override
  String get settingsLocalHistoryTitle => 'Ghi lại lịch sử cục bộ';

  @override
  String get settingsLocalHistoryDescription =>
      'Lưu các phiên bản tài liệu trên thiết bị để khôi phục và so sánh.';

  @override
  String get settingsHistoryCheckpoint => 'Khoảng thời gian kiểm tra tự động';

  @override
  String get settingsHistoryRetention => 'Thời gian lưu';

  @override
  String get settingsHistoryStorage => 'Dung lượng tối đa';

  @override
  String get settingsHistoryExcludedPaths => 'Đường dẫn bị loại trừ';

  @override
  String get settingsHistoryExcludedPathsHint =>
      'Một đường dẫn tuyệt đối trên mỗi dòng';

  @override
  String settingsSecondsValue(int value) {
    return '$value giây';
  }

  @override
  String settingsDaysValue(int value) {
    return '$value ngày';
  }

  @override
  String settingsMebibytesValue(int value) {
    return '$value MiB';
  }

  @override
  String get spelling => 'Chính tả';

  @override
  String get automaticSpelling => 'Tự động kiểm tra chính tả';

  @override
  String get defaultSpellingLanguage => 'Ngôn ngữ chính tả mặc định';

  @override
  String get projectSpellingLanguage => 'Ngôn ngữ kiểm tra chính tả của dự án';

  @override
  String get chooseSpellingLanguage => 'Chọn ngôn ngữ chính tả';

  @override
  String get spellingLanguageUnsetStatus => 'Ngôn ngữ…';

  @override
  String get spellingOffStatus => 'Tắt chính tả';

  @override
  String get checkSpelling => 'Kiểm tra chính tả';

  @override
  String get ignoreSpellingOnce => 'Bỏ qua một lần';

  @override
  String get ignoreSpellingDocument => 'Bỏ qua tất cả trong tài liệu này';

  @override
  String get addPersonalSpellingWord => 'Thêm vào từ điển cá nhân';

  @override
  String get addProjectSpellingWord => 'Thêm vào từ điển dự án';

  @override
  String get inheritSpellingLanguage => 'Dùng ngôn ngữ dự án hoặc ứng dụng';

  @override
  String get disableDocumentSpelling => 'Không kiểm tra chính tả';

  @override
  String get importSpellingDictionary => 'Nhập từ điển';

  @override
  String get personalSpellingDictionary => 'Từ điển cá nhân';

  @override
  String get projectSpellingDictionary => 'Từ điển dự án';

  @override
  String get noSpellingErrors => 'Không có lỗi chính tả';

  @override
  String get noSpellingSuggestions => 'Không có đề xuất chính tả';

  @override
  String get spellingWordCheckFailed => 'Không thể kiểm tra từ này';

  @override
  String get spellingCheckFailed => 'Kiểm tra chính tả thất bại';

  @override
  String get spellingSettingsLoadFailed =>
      'Không thể tải cài đặt kiểm tra chính tả';

  @override
  String get retrySpellingSettings => 'Thử tải lại cài đặt kiểm tra chính tả';

  @override
  String get spellingCheckIncomplete => 'Kiểm tra chính tả chưa hoàn tất';

  @override
  String get spellingDictionaryNotInstalled => 'Từ điển chưa được cài đặt';

  @override
  String spellingDictionaryNotInstalledForLanguage(String dictionary) {
    return 'Từ điển $dictionary chưa được cài đặt';
  }

  @override
  String spellingDictionaryNotInstalledWithSize(String size) {
    return 'Chưa cài đặt · $size';
  }

  @override
  String get spellingDictionaryInstalled => 'Đã cài đặt';

  @override
  String get installSpellingDictionary => 'Cài đặt từ điển';

  @override
  String get removeSpellingDictionary => 'Gỡ từ điển';

  @override
  String get cancelSpellingDictionaryInstall => 'Hủy tải từ điển';

  @override
  String get retrySpellingDictionaryInstall => 'Thử cài đặt lại từ điển';

  @override
  String spellingDictionaryDownloading(String size) {
    return 'Đang tải $size…';
  }

  @override
  String get spellingDictionaryValidating => 'Đang xác thực từ điển…';

  @override
  String get spellingDictionaryInstallFailed =>
      'Cài đặt từ điển thất bại — chọn để thử lại';

  @override
  String spellingDictionaryInstallPrompt(String dictionary, String size) {
    return 'Cài đặt $dictionary ($size)? Sau khi cài đặt, từ điển sẽ dùng được ngoại tuyến cho đến khi bạn gỡ bỏ.';
  }

  @override
  String get spellingDictionaryUnavailable => 'Từ điển không khả dụng';

  @override
  String get spellingChecking => 'Đang kiểm tra chính tả…';

  @override
  String exportInvalidRange(String field, String minimum, String maximum) {
    return '$field: nhập số từ $minimum đến $maximum.';
  }

  @override
  String get spellingDictionaryRecoveryConflict =>
      'Từ điển chính tả đã được thay đổi từ bên ngoài. Một bản sao khôi phục đã được giữ lại.';

  @override
  String get windowMinimize => 'Thu nhỏ';

  @override
  String get windowMaximize => 'Phóng to';

  @override
  String get windowRestore => 'Khôi phục';

  @override
  String get nextcloudNotes => 'Nextcloud Notes';

  @override
  String get nextcloudConnect => 'Kết nối';

  @override
  String get nextcloudReconnect => 'Kết nối lại';

  @override
  String get nextcloudDisconnect => 'Ngắt kết nối';

  @override
  String get nextcloudServer => 'Địa chỉ máy chủ';

  @override
  String get nextcloudSignInBrowser => 'Hoàn tất đăng nhập trong trình duyệt.';

  @override
  String get nextcloudFavorites => 'Yêu thích';

  @override
  String get nextcloudNewNote => 'Ghi chú mới';

  @override
  String get nextcloudSavedLocally => 'Đã lưu cục bộ · chờ đồng bộ';

  @override
  String get nextcloudSyncing => 'Đang đồng bộ';

  @override
  String get nextcloudSynced => 'Đã đồng bộ';

  @override
  String get nextcloudOffline => 'Ngoại tuyến';

  @override
  String get nextcloudLocked => 'Máy chủ đã khóa';

  @override
  String get nextcloudReconnectRequired => 'Cần kết nối lại';

  @override
  String get nextcloudCreationUncertain => 'Kết quả tạo chưa rõ';

  @override
  String get nextcloudReadOnly => 'Chỉ đọc';

  @override
  String get nextcloudTakeRemote => 'Dùng bản trên máy chủ';

  @override
  String get nextcloudMerge => 'Hợp nhất';

  @override
  String get nextcloudDeleteNote => 'Xóa ghi chú?';

  @override
  String get nextcloudWorkspaceReplaceUnavailable =>
      'Không thể thay thế toàn bộ không gian làm việc với Nextcloud Notes. Hãy thay thế trong từng ghi chú.';

  @override
  String get nextcloudSaveLocalCopy => 'Lưu bản sao cục bộ…';

  @override
  String get nextcloudDisconnectWarning =>
      'Xóa tài khoản này sẽ xóa ghi chú đã lưu và thay đổi đang chờ trên thiết bị. Hãy đồng bộ trước để giữ công việc trên máy chủ.';

  @override
  String get nextcloudAttachmentRetryWarning =>
      'Nếu lần tải lên trước đã thành công, thử lại có thể để lại tệp đính kèm không dùng trên máy chủ.';

  @override
  String get nextcloudAttachmentReference =>
      'Tham chiếu tệp đính kèm trên máy chủ';

  @override
  String get nextcloudAddAttachment => 'Thêm tệp đính kèm…';

  @override
  String get nextcloudDeleteAttachmentWarning =>
      'Xóa tệp đính kèm này sẽ khiến các liên kết đến tệp trong ghi chú không còn khả dụng. Dữ liệu được giữ lại có thể khôi phục qua lịch sử cục bộ.';

  @override
  String get nextcloudChooseConflictingAttributes =>
      'Chọn giá trị cho từng thuộc tính xung đột.';

  @override
  String get nextcloudUseServerNote => 'Dùng ghi chú trên máy chủ này';

  @override
  String get nextcloudUseServerNoteExplanation =>
      'Liên kết bản nháp này với ghi chú đã chọn trên máy chủ, rồi đồng bộ các thay đổi cục bộ được giữ lại. Yêu cầu trùng khớp không xác nhận ai đã tạo ghi chú.';

  @override
  String get nextcloudExactCandidate =>
      'Khớp chính xác với yêu cầu; chưa xác nhận danh tính.';

  @override
  String get nextcloudPossibleCandidate =>
      'Có thể khớp sau khi chuẩn hóa yêu cầu; chưa xác nhận danh tính.';

  @override
  String get nextcloudSelectCandidate => 'Chọn ghi chú trên máy chủ để xem xét';

  @override
  String get nextcloudCreateSeparate => 'Tạo ghi chú riêng';

  @override
  String get nextcloudCreateSeparateWarning =>
      'Yêu cầu đầu tiên có thể đã tạo ghi chú trên máy chủ. Thao tác này tạo ghi chú riêng với công việc cục bộ được giữ lại. Không xóa ghi chú nào bị nghi trùng lặp.';

  @override
  String get wsSemanticFormats => 'Định dạng ngữ nghĩa';

  @override
  String get wsUiControl => 'Điều khiển giao diện';

  @override
  String get wsFilePath => 'Tệp / Đường dẫn';

  @override
  String get wsUiPath => 'Đường dẫn giao diện';

  @override
  String get wsDefinitionList => 'Danh sách định nghĩa';

  @override
  String get wsIncludeContent => 'Chèn nội dung tái sử dụng';

  @override
  String get wsVariableReference => 'Tham chiếu biến';

  @override
  String get wsConvertList => 'Chuyển danh sách thành quy trình';

  @override
  String get wsElementProperties => 'Thuộc tính phần tử';

  @override
  String get wsTopicProperties => 'Thuộc tính chủ đề';

  @override
  String get wsCollapsible => 'Có thể thu gọn';

  @override
  String get wsPublishedState => 'Trạng thái ban đầu khi xuất bản';

  @override
  String get wsExpanded => 'Mở rộng';

  @override
  String get wsCollapsed => 'Thu gọn';

  @override
  String get wsCollapsedTitle => 'Tiêu đề thu gọn';

  @override
  String get wsTerm => 'Thuật ngữ';

  @override
  String get wsListLayout => 'Bố cục danh sách';

  @override
  String get wsSyncGroup => 'Nhóm đồng bộ';

  @override
  String get wsTabKey => 'Khóa thẻ';

  @override
  String get wsSwitcherLabel => 'Nhãn bộ chuyển';

  @override
  String get wsNavigationElements => 'Phần tử điều hướng';

  @override
  String get wsNavigationDepth => 'Độ sâu điều hướng';

  @override
  String get wsAddItem => 'Thêm mục';

  @override
  String get wsStep => 'Bước';

  @override
  String get wsPropertyInvalid => 'Giá trị thuộc tính không hợp lệ';

  @override
  String get wsFilter => 'Bộ lọc';

  @override
  String get wsIdentifier => 'ID phần tử';

  @override
  String get wsTldr => 'Tóm tắt (TLDR)';

  @override
  String get wsFullLayout => 'Toàn chiều rộng';

  @override
  String get wsMediumLayout => 'Trung bình (1:2)';

  @override
  String get wsNarrowLayout => 'Cột thuật ngữ hẹp';

  @override
  String get wsTitle => 'Tiêu đề';

  @override
  String get wsSwitcherKey => 'Khóa chuyển đổi';

  @override
  String get nextcloudServerSettings => 'Cài đặt Notes trên máy chủ';

  @override
  String get nextcloudNotesPath => 'Đường dẫn thư mục ghi chú';

  @override
  String get nextcloudFileSuffix => 'Phần mở rộng của ghi chú mới';

  @override
  String get nextcloudServerSettingsExplanation =>
      'Các cài đặt Notes này ảnh hưởng đến các ứng dụng khách khác. Đổi đường dẫn không di chuyển tệp; đổi phần mở rộng không đổi tên ghi chú hiện có.';

  @override
  String get nextcloudSettingsSaved => 'Đã lưu cài đặt máy chủ';

  @override
  String get nextcloudSettingsNormalized =>
      'Đã lưu các giá trị được máy chủ chuẩn hóa';

  @override
  String get nextcloudPendingUpload => 'Đang chờ tải tệp đính kèm lên';

  @override
  String nextcloudServerCheck(String time) {
    return 'Lần kiểm tra máy chủ gần nhất: $time';
  }

  @override
  String get nextcloudSettingsLoading => 'Đang tải cài đặt máy chủ';

  @override
  String get nextcloudSettingsSaving => 'Đang lưu cài đặt máy chủ';

  @override
  String get nextcloudPreviousLocalEdit => 'Chỉnh sửa cục bộ trước';

  @override
  String get nextcloudUsePreviousEdit => 'Dùng chỉnh sửa trước';

  @override
  String get quickOpen => 'Mở nhanh';

  @override
  String get notesAll => 'Tất cả ghi chú';

  @override
  String get notesUncategorized => 'Chưa phân loại';

  @override
  String get notesRecovery => 'Khôi phục';

  @override
  String get notesRecentlyEdited => 'Sửa gần đây';

  @override
  String get notesOldestEdited => 'Sửa lâu nhất';

  @override
  String get notesTitleAscending => 'Tiêu đề A–Z';

  @override
  String get notesTitleDescending => 'Tiêu đề Z–A';

  @override
  String get notesMove => 'Chuyển tới danh mục';

  @override
  String get notesRemoveFavorite => 'Bỏ yêu thích';

  @override
  String get notesOffline => 'Cho phép dùng ngoại tuyến';

  @override
  String get notesOfflineRemove => 'Bỏ yêu cầu lưu ngoại tuyến';

  @override
  String get notesIndexing => 'Đang lập chỉ mục ghi chú…';

  @override
  String get notesSearchHelp =>
      'Các từ kết hợp bằng VÀ. Dùng \"cụm từ trích dẫn\", title: và category:.';

  @override
  String get notesSourceLocation => 'Vị trí mã nguồn';

  @override
  String get notesRecoveryHelp =>
      'Chỉ gồm ghi chú cục bộ được giữ và lịch sử cục bộ. Không có thùng rác hoặc lịch sử máy chủ.';

  @override
  String get notesImport => 'Nhập ghi chú';

  @override
  String get notesExport => 'Xuất ghi chú';

  @override
  String get notesImportDistinct => 'Nhập thành ghi chú riêng';

  @override
  String get notesAvailableOffline => 'Có sẵn ngoại tuyến';

  @override
  String get notesIncomplete => 'Chưa đầy đủ';

  @override
  String get notesSelected => 'Ghi chú đã chọn';

  @override
  String get notesNoHistory =>
      'Không có phiên bản được giữ. Lịch sử có thể bị tắt, hết hạn hoặc bị xóa.';

  @override
  String get notesTextAvailable => 'Văn bản có sẵn cục bộ';

  @override
  String get notesLocalVersion => 'Phiên bản làm việc cục bộ';

  @override
  String get notesAttachments => 'Tệp đính kèm';

  @override
  String get notesSkipped => 'Đã bỏ qua';

  @override
  String get notesFailed => 'Thất bại';

  @override
  String get notesCompleted => 'Hoàn tất';

  @override
  String get notesImportNew => 'Bắt đầu nhập mới';

  @override
  String get notesImportResume => 'Tiếp tục lần nhập bị gián đoạn';

  @override
  String get notesImportAlreadyImported => 'Đã nhập trong thao tác này';

  @override
  String get references => 'Tham chiếu';

  @override
  String get referenceIncoming => 'Đến';

  @override
  String get referenceOutgoing => 'Đi';

  @override
  String get referenceChooseTarget => 'Chọn đích liên kết';

  @override
  String get referenceWholeDocument => 'Toàn bộ tài liệu';

  @override
  String get referenceSourceLocation => 'Vị trí nguồn';

  @override
  String get referenceTargetLocation => 'Vị trí đích';

  @override
  String get referenceResolved => 'Đã phân giải';

  @override
  String get referenceMissing => 'Không tìm thấy';

  @override
  String get referenceAmbiguous => 'Không rõ ràng';

  @override
  String get referenceUnavailable => 'Không khả dụng trong ngữ cảnh này';

  @override
  String get referenceUnsupported => 'Không được hỗ trợ';

  @override
  String get referenceNoPortableId =>
      'Đích này không có URL ghi chú di động đã xác minh.';

  @override
  String get wsIncludeLines => 'Gồm các dòng';

  @override
  String get wsIncludeSymbol => 'Gồm ký hiệu';

  @override
  String get wsEmphasizeLines => 'Tô nổi các dòng hiển thị';

  @override
  String get wsPropertiesReadOnly => 'Thuộc tính chỉ đọc trong chế độ này.';

  @override
  String get wsPropertiesProtected => 'Phần tử được bảo vệ. Hãy sửa mã nguồn.';

  @override
  String get wsPropertiesConflict =>
      'Tài liệu hoặc phần tử đã đổi. Hoàn nguyên bản nháp và chọn lại.';

  @override
  String get wsPropertiesUnresolved => 'Hiện không thể phân giải tham chiếu.';

  @override
  String get wsUseDefault => 'Dùng mặc định';

  @override
  String get wsPropertiesSelection => 'Chọn một phần tử.';

  @override
  String get wsImageDisplay => 'Hiển thị ảnh';

  @override
  String get wsImageThumbnail => 'Ảnh thu nhỏ có thể nhấp';

  @override
  String get wsEnabled => 'Bật';

  @override
  String get wsDisabled => 'Tắt';

  @override
  String get wsWidth => 'Chiều rộng';

  @override
  String get wsHeight => 'Chiều cao';

  @override
  String get wsPropertiesInactive =>
      'Thuộc tính chỉ có tác dụng khi bật thu gọn lúc xuất bản.';

  @override
  String get wsNavigationAll => 'Mọi phần tử có tiêu đề';

  @override
  String get wsNavigationNone => 'Không điều hướng';

  @override
  String get wsNavigationCustom => 'Điều hướng tùy chỉnh';

  @override
  String get wsTitleOverride => 'Ghi đè tiêu đề';

  @override
  String get wsCompactLayout => 'Gọn';

  @override
  String get wsWideLayout => 'Rộng';

  @override
  String get wsCodeSourceConflict =>
      'Di chuyển hoặc xóa mã được viết trong khối này trước khi đặt src. Writerside từ chối khối mã không trống có tham chiếu nguồn.';

  @override
  String get wsInherited => 'Kế thừa từ danh sách';

  @override
  String get wsExternalImageSize =>
      'Writerside không đặt kích thước ảnh bên ngoài một cách tin cậy. Có thể xem và xóa kích thước hiện có.';

  @override
  String get wsPropertiesNotSerialized =>
      'Thay đổi này chưa được ghi vào nguồn. Bản nháp đã được giữ lại.';

  @override
  String get wsListItem => 'Mục danh sách';

  @override
  String get wsSourceFile => 'Tệp nguồn';

  @override
  String get wsLinkTarget => 'Đích liên kết';

  @override
  String get wsPreviewImage => 'Ảnh xem trước';

  @override
  String get wsIncludedElement => 'Phần tử được đưa vào';

  @override
  String get wsHelpModule => 'Mô-đun trợ giúp';

  @override
  String get wsActionId => 'ID hành động';

  @override
  String get wsKeymapHelpInstance => 'Phiên bản trợ giúp sơ đồ phím';

  @override
  String get wsShowInSource => 'Hiện trong Nguồn';

  @override
  String get wsOriginElement => 'Giá trị ghi đè của phần tử';

  @override
  String get wsOriginAncestor => 'Phần tử cha';

  @override
  String get wsOriginModule => 'Mặc định của mô-đun';

  @override
  String get wsOriginBuiltIn => 'Mặc định tích hợp';

  @override
  String get wsOriginUnresolved => 'Chưa phân giải';

  @override
  String wsEffectiveProperty(String value, String origin) {
    return 'Hiệu lực: $value — $origin';
  }

  @override
  String get wsElementSelector => 'Phần tử';

  @override
  String wsGeneratedAnchorValue(String anchor) {
    return 'Được tạo: $anchor';
  }

  @override
  String wsDefaultProperty(String value) {
    return 'Mặc định: $value';
  }

  @override
  String wsDefaultPropertyOrigin(String value, String origin) {
    return 'Mặc định: $value · $origin';
  }

  @override
  String wsResolvedProperty(String value) {
    return 'Đã phân giải: $value';
  }

  @override
  String get wsPropertyUnresolved => 'Chưa phân giải';

  @override
  String get wsModule => 'Mô-đun';

  @override
  String get wsParent => 'Phần tử cha';

  @override
  String get wsListType => 'Loại danh sách';

  @override
  String get wsStartingNumber => 'Số bắt đầu';

  @override
  String get wsListSorting => 'Sắp xếp';

  @override
  String get wsLetteredList => 'Danh sách chữ cái';

  @override
  String get wsCheckboxList => 'Danh sách hộp kiểm';

  @override
  String get wsMarkerlessList => 'Danh sách không dấu đầu dòng';

  @override
  String get wsAscending => 'Tăng dần';

  @override
  String get wsDescending => 'Giảm dần';

  @override
  String get wsNoSorting => 'Không sắp xếp';

  @override
  String get wsAsWritten => 'Theo văn bản gốc';

  @override
  String get wsSentenceCase => 'Viết hoa kiểu câu';

  @override
  String get wsTitleCase => 'Viết hoa kiểu tiêu đề';

  @override
  String get wsLowerCase => 'Chữ thường';

  @override
  String get wsUpperCase => 'Chữ hoa';

  @override
  String get wsNativeMarkers => 'Dấu Markdown';

  @override
  String wsListMarkerStart(String number) {
    return 'Dấu bắt đầu: $number';
  }

  @override
  String wsListLevel(String level) {
    return 'Cấp $level';
  }

  @override
  String get wsModuleCapsIgnored =>
      'Trình dựng cố định bỏ qua quy tắc <caps> của mô-đun. Dùng thuộc tính caps cục bộ hoặc default-property.';

  @override
  String get wsInsertElements => 'Chèn phần tử';

  @override
  String get wsAdmonitionsAndQuotes => 'Lưu ý và trích dẫn';

  @override
  String get wsSemanticText => 'Văn bản ngữ nghĩa';

  @override
  String get wsPropertiesUnavailable =>
      'Phần tử đang kiểm tra không khả dụng. Kiểm tra một phần tử để tiếp tục.';

  @override
  String get searchDocumentsCategory => 'Tài liệu';

  @override
  String get searchTopicsCategory => 'Chủ đề';

  @override
  String get searchCurrentDocument => 'Tài liệu hiện tại';

  @override
  String get searchCurrentWorkspace => 'Không gian làm việc hiện tại';

  @override
  String get browseNotes => 'Duyệt ghi chú';

  @override
  String get searchActionsCommand => 'Tìm thao tác';

  @override
  String get searchDocumentsCommand => 'Tìm tài liệu';

  @override
  String get searchTopicsCommand => 'Tìm chủ đề';

  @override
  String get searchRecentCommand => 'Tìm mục gần đây';

  @override
  String get searchResourceUnavailable => 'Tài nguyên này không khả dụng.';

  @override
  String get notesSync => 'Đồng bộ ghi chú';

  @override
  String get searchInWorkspace => 'Tìm trong không gian làm việc';

  @override
  String get searchCategory => 'Danh mục tìm kiếm';

  @override
  String get clearHistorySearchScope => 'Tìm trong lịch sử tài liệu';

  @override
  String get searchInDocument => 'Tìm trong tài liệu';

  @override
  String get searchDocumentHint => 'Tìm trong tài liệu này…';

  @override
  String get searchWorkspaceHint => 'Tìm trong không gian làm việc này…';

  @override
  String get searchOutlineHint => 'Tìm tiêu đề…';

  @override
  String get searchHistoryHint => 'Tìm trong lịch sử cục bộ…';

  @override
  String get searchEnterText => 'Nhập văn bản để tìm kiếm';

  @override
  String get searchAccountUnavailable => 'Tài khoản không khả dụng';

  @override
  String get searchDocumentsHint => 'Tìm tài liệu…';

  @override
  String get searchTopicsHint => 'Tìm chủ đề…';

  @override
  String get searchRecentHint => 'Tìm mục gần đây…';

  @override
  String get searchActionsHint => 'Tìm thao tác…';

  @override
  String get searchRequiresNotesWorkspace =>
      'Yêu cầu không gian làm việc Ghi chú';

  @override
  String get searchSidebarLabel => 'Tìm kiếm:';

  @override
  String get searchDocumentTextCategory => 'Văn bản tài liệu';

  @override
  String get searchWorkspaceTextCategory => 'Văn bản không gian làm việc';

  @override
  String get searchHeadingsCategory => 'Tiêu đề';

  @override
  String get shortcutUnassigned => 'Chưa gán';

  @override
  String get shortcutPressKeys => 'Nhấn tổ hợp phím…';

  @override
  String get shortcutRecord => 'Ghi phím tắt';

  @override
  String get shortcutRestoreAll => 'Khôi phục tất cả mặc định';

  @override
  String get shortcutRestoreAllQuestion =>
      'Khôi phục phím tắt mặc định của mọi thao tác? Các gán tùy chỉnh sẽ bị xóa.';

  @override
  String get shortcutSaveFailed =>
      'Phím tắt đang có hiệu lực nhưng chưa lưu được. Thử lưu lại để giữ chúng sau khi khởi động lại.';

  @override
  String get shortcutRetry => 'Thử lưu lại';

  @override
  String get shortcutChanged =>
      'Các gán đã thay đổi. Xem lại phím tắt hiện tại và thử lại.';

  @override
  String get shortcutInvalid => 'Không thể gán tổ hợp này trong ngữ cảnh này.';

  @override
  String get shortcutSystemWarning =>
      'Môi trường màn hình có thể dùng tổ hợp này. BusyMark không thể ghi đè phím tắt hệ thống.';

  @override
  String get shortcutConflicts => 'Phím tắt này xung đột với các thao tác sau:';

  @override
  String get shortcutRemove => 'Xóa gán';

  @override
  String get shortcutRestoreDefault => 'Khôi phục mặc định';

  @override
  String get shortcutAssign => 'Gán';

  @override
  String get shortcutReassign => 'Gán lại';

  @override
  String get shortcutContextApplication => 'Ứng dụng';

  @override
  String get shortcutContextDocument => 'Chế độ xem tài liệu';

  @override
  String get shortcutContextEditor => 'Trình sửa và mã nguồn';

  @override
  String get shortcutContextWritersideSource => 'Mã nguồn Writerside';

  @override
  String get shortcutContextWorkspace => 'Điều hướng không gian làm việc';

  @override
  String get shortcutContextTree => 'Cây thanh bên';

  @override
  String get searchHeadingsCommand => 'Tìm tiêu đề';

  @override
  String get shortcutFixed => 'Do trình soạn thảo quản lý; không thể cấu hình.';

  @override
  String get shortcutDefaultConflict =>
      'Phím tắt mặc định xung đột với gán tùy chỉnh.';

  @override
  String get shortcutCurrentBinding => 'Phím tắt hiện tại';

  @override
  String get shortcutProposedBinding => 'Phím tắt đề xuất';

  @override
  String get notesActions => 'Thao tác ghi chú';

  @override
  String get noteActions => 'Thao tác với ghi chú';

  @override
  String get noteProperties => 'Thuộc tính ghi chú';

  @override
  String get notesExportAll => 'Xuất ghi chú · Tất cả ghi chú…';

  @override
  String get notesExportCategory => 'Xuất ghi chú · Danh mục…';

  @override
  String get notesOfflineAll => 'Cho phép dùng ngoại tuyến · Tất cả ghi chú';

  @override
  String get notesOfflineCategory => 'Cho phép dùng ngoại tuyến · Danh mục';

  @override
  String get notesOfflineRemoveAll =>
      'Bỏ yêu cầu lưu ngoại tuyến · Tất cả ghi chú';

  @override
  String get notesOfflineRemoveCategory =>
      'Bỏ yêu cầu lưu ngoại tuyến · Danh mục';

  @override
  String get notesOfflinePause => 'Tạm dừng tải xuống';

  @override
  String get notesOfflineResume => 'Tiếp tục tải xuống';

  @override
  String get notesOfflineKeep => 'Cho phép dùng ngoại tuyến';

  @override
  String get notesOfflineRetentionHelp =>
      'Bỏ yêu cầu này vẫn giữ nội dung đã lưu đệm. Yêu cầu của danh mục hoặc tài khoản có thể vẫn giữ ghi chú này.';

  @override
  String get notesOfflineBroader =>
      'Ghi chú này cũng được giữ theo yêu cầu của danh mục hoặc tài khoản.';

  @override
  String get notesOfflineExternal =>
      'Nội dung đa phương tiện bên ngoài cần kết nối. BusyMark chỉ giữ văn bản ghi chú và tệp đính kèm được quản lý.';

  @override
  String get notesEmptyAll => 'Chưa có ghi chú. Hãy tạo ghi chú đầu tiên.';

  @override
  String get notesEmptyFavorites => 'Không có ghi chú yêu thích.';

  @override
  String get notesEmptyCategory => 'Không có ghi chú trong danh mục này.';

  @override
  String get notesEmptyUncategorized => 'Không có ghi chú chưa phân loại.';

  @override
  String get notesEmptyRecovery =>
      'Không có ghi chú được giữ lại để khôi phục.';

  @override
  String get notesLoadFailed => 'Nextcloud Notes · Thất bại. Thử lại';

  @override
  String get notesOperationFailed =>
      'Không thể hoàn tất thao tác. Bản nháp vẫn được giữ. Kiểm tra việc lưu và xung đột rồi thử lại.';

  @override
  String get notesInspectionFailed => 'Tệp đính kèm · Thất bại. Thử lại';

  @override
  String get notesStartingConnection => 'Đang bắt đầu kết nối Nextcloud…';

  @override
  String get notesVerifyingConnection =>
      'Đang xác minh quyền truy cập ghi chú…';

  @override
  String get notesCancellingConnection => 'Đang hủy đăng nhập và dọn dẹp…';

  @override
  String get notesRemovingConnection => 'Đang xóa tài khoản cục bộ…';

  @override
  String get notesRemovedWarning =>
      'Đã xóa tài khoản Nextcloud cục bộ. Chưa xác nhận thu hồi mật khẩu ứng dụng. Hãy xóa mật khẩu BusyMark trong cài đặt Bảo mật Nextcloud.';

  @override
  String get notesBuffersNotSaved =>
      'Không thể lưu cục bộ tất cả ghi chú đang mở. Kiểm tra việc lưu, xung đột hoặc chuẩn hóa trong không gian làm việc. Thay đổi cục bộ có thể vẫn cần đồng bộ với Nextcloud.';

  @override
  String get notesSettingsLeave =>
      'Lưu thay đổi cài đặt Nextcloud trước khi rời đi?';

  @override
  String get notesSettingsLeaveHelp =>
      'Cài đặt Notes trên máy chủ · Thay đổi chưa lưu';

  @override
  String get notesSettingsReload => 'Tải lại cài đặt máy chủ…';

  @override
  String get notesSettingsReloadHelp =>
      'Tải lại sẽ thay bản nháp bằng cài đặt Nextcloud hiện tại. Bỏ bản nháp và tải lại?';

  @override
  String get notesSettingsRefreshFailed =>
      'Nextcloud đã nhận cài đặt nhưng không làm mới được ghi chú. Giá trị hiển thị đã được máy chủ xác nhận. Hãy thử làm mới từ Ghi chú.';

  @override
  String get notesUnavailable =>
      'Ngoại tuyến · Văn bản có sẵn cục bộ · Đã lưu cục bộ · chờ đồng bộ';

  @override
  String get notesStorageFull =>
      'Bộ nhớ Nextcloud đã đầy. Giải phóng dung lượng máy chủ rồi thử lại.';

  @override
  String get notesRejected =>
      'Nextcloud từ chối thay đổi này. Kiểm tra ghi chú và lưu bản sao cục bộ trước khi thử lại.';

  @override
  String get notesThrottled =>
      'Nextcloud yêu cầu chờ. Đồng bộ sẽ tiếp tục sau thời hạn thử lại.';

  @override
  String get notesRecoveryRequired => 'Xung đột · So sánh';

  @override
  String get notesScanning => 'Đang quét tệp…';

  @override
  String get notesCancelling => 'Đang hủy… Đợi thao tác hiện tại kết thúc.';

  @override
  String get notesCancelled => 'Đã hủy';

  @override
  String get notesPartial => 'Hoàn tất một phần';

  @override
  String get notesTransferFailed => 'Thất bại. Thử lại';

  @override
  String get notesImportPartialHelp =>
      'Các mục trước có thể đã được lưu cục bộ. Tiếp tục lần nhập này để tránh tạo bản trùng.';

  @override
  String get notesNotStarted => 'Chưa bắt đầu';

  @override
  String get notesCreated => 'Đã tạo';

  @override
  String get notesRemoteDeleteUnavailable =>
      'Địa chỉ máy chủ · Không được hỗ trợ · Xóa · Tệp đính kèm';

  @override
  String get notesCurrentText => 'Văn bản hiện đang được giữ lại';

  @override
  String get notesRecovering => 'Đang khôi phục thành ghi chú mới…';

  @override
  String get notesReadOnlyHelp => 'Chỉ đọc · Yêu thích · Lưu bản sao cục bộ…';

  @override
  String get notesSort => 'Sắp xếp ghi chú';

  @override
  String get notesPathRelative =>
      'Đường dẫn thư mục ghi chú tương đối với bộ nhớ Nextcloud của bạn.';

  @override
  String get notesSettingsStale =>
      'Cài đặt trên Nextcloud đã thay đổi. Tải lại và kiểm tra giá trị máy chủ trước khi thay bản nháp.';

  @override
  String get notesDownloadsPaused => 'Đã tạm dừng tải xuống';

  @override
  String get notesExportNotPublished => 'Không có bản xuất nào được công bố.';

  @override
  String get notesKeyringUnavailable =>
      'Mở khóa kho khóa của máy tính rồi thử lại.';

  @override
  String get notesConnectFailed =>
      'Không thể kết nối Nextcloud Notes. Kiểm tra địa chỉ máy chủ rồi thử lại.';

  @override
  String get notesAccountMismatch =>
      'Đăng nhập cùng tài khoản Nextcloud. Xóa tài khoản này trước để kết nối tài khoản khác.';

  @override
  String get notesLocalRemovalFailed =>
      'Dọn dẹp tài khoản cục bộ thất bại. Tài khoản được giữ để bạn thử xóa lại.';

  @override
  String get notesTransferring => 'Đang chuyển ghi chú…';

  @override
  String get notesTechnicalDetails => 'Chi tiết kỹ thuật';

  @override
  String get notesPauseRequirement => 'Tạm dừng yêu cầu giữ ngoại tuyến';

  @override
  String get notesResumeRequirement => 'Tiếp tục yêu cầu giữ ngoại tuyến';

  @override
  String get gitReturnToDocument => 'Quay lại tài liệu';

  @override
  String gitSnapshotLabel(String revision, String path) {
    return 'Ảnh chụp chỉ đọc · $revision · $path';
  }

  @override
  String get gitNonUtf8FilenameMessage =>
      'Tên tệp này chứa byte không phải UTF-8. Vẫn có thể xem xét và đưa vào vùng đệm Git; trình soạn thảo tài liệu yêu cầu tên tệp UTF-8.';

  @override
  String get gitUiMergeInProgress => 'Đang trộn';

  @override
  String get gitUiRebaseInProgress => 'Comment';

  @override
  String get gitUiCherryPickInProgress => 'Đang lựa chọn Cherry.';

  @override
  String get gitUiRevertInProgress => 'Hoàn nguyên trong tiến trình';

  @override
  String get gitUiPatchApplicationInProgress =>
      'Đắp vá ứng dụng đang tiến hành';

  @override
  String get gitUiSquashMergeResultAwaitingCommit =>
      'Kết quả hợp nhất Squash đang chờ cam kết';

  @override
  String get gitUiUnresolvedIndexConflicts =>
      'Xung đột phụ lục chưa được giải quyết';

  @override
  String get gitUiUnresolvedConflicts => ' · xung đột chưa được giải quyết';

  @override
  String get gitUiReviewOperation => 'Thao tác ôn lại';

  @override
  String get gitUiRefresh => 'Làm mới';

  @override
  String get gitUiCreateNamedStash => 'Tạo nơi lưu tên';

  @override
  String get gitUiCreateStash => 'Tạo bản cất tạm…';

  @override
  String get gitUiNoStashes => 'Không giấu';

  @override
  String get gitUiSelectAStashToInspectItsChanges =>
      'Chọn nơi lưu trữ cần kiểm tra các thay đổi của nó';

  @override
  String get gitUiStashedUntrackedFiles => 'Comment';

  @override
  String get gitUiInspectStashedUntrackedFiles =>
      'Đang kiểm tra các tập tin chưa được ghi rõ...';

  @override
  String get gitUiReinstateTheStashSStagedIndexStateWhenApplying =>
      'Tăng cường trạng thái của nơi ẩn náu khi nộp đơn';

  @override
  String get gitUiApplyAndRetain => 'Áp dụng và ghi lại';

  @override
  String get gitUiPop => 'Bố...';

  @override
  String get gitUiCreateBranch => 'Tạo nhánh…';

  @override
  String get gitUiDropStash => 'Xóa bản cất tạm…';

  @override
  String get gitUiBranchFromStash => 'Tạo nhánh từ bản cất tạm';

  @override
  String get gitUiCreateSwitchToABranchAtTheStashSOriginal =>
      'Tạo ra/sction to a chi nhánh tại căn cứ gốc của kho, sau đó áp dụng nó.';

  @override
  String gitUiArg0ThisStash(String arg0) {
    return '$arg0 nơi này?';
  }

  @override
  String get gitUiTheOriginalStashIsRetainedIfApplyingConflicts =>
      'Nếu áp dụng xung đột, người ta giữ lại chỗ cất giấu gốc.';

  @override
  String get gitUiDeletesThisStashEntryItsChangesAreNotApplied =>
      'Xoá mục này. Thay đổi của nó không được áp dụng.';

  @override
  String get gitUiResolveTheUnmergedFilesGitHasNoStashContinueOr =>
      'Giải quyết các tệp chưa hợp nhất. Git không có lệnh tiếp tục hay hủy thao tác stash; bản cất tạm gốc vẫn được giữ.';

  @override
  String get gitUiStashNameMessage => 'Tên giả/ Thông báo';

  @override
  String get gitUiStashContentAndResultingIndex => 'Comment';

  @override
  String get gitUiStashTrackedWorkingAndStagedChanges => 'Name';

  @override
  String get gitUiStashChangesLeaveStagedChangesInPlaceKeepIndex =>
      'Cất tạm thay đổi, giữ nguyên thay đổi đã đưa vào chỉ mục (--keep-index)';

  @override
  String get gitUiStashOnlyStagedChangesStaged =>
      'Chỉ cất tạm các thay đổi đã đưa vào chỉ mục (--staged)';

  @override
  String get gitUiIncludeUntrackedFiles => 'Gồm tập tin chưa được đánh dấu';

  @override
  String get gitUiAllEligiblePathsInThisRepository =>
      'Tất cả các đường dẫn thích hợp trong kho chứa này';

  @override
  String get gitUiNoEligibleChangesForTheseStashOptions =>
      'Không có thay đổi thích hợp cho các tùy chọn ẩn giấu này.';

  @override
  String get gitUiSelectAtLeastOneEligiblePath =>
      'Chọn ít nhất một đường thích hợp.';

  @override
  String get gitUiCreateStash2 => 'Tạo bản cất tạm';

  @override
  String get gitUiCreateWorktree => 'Tạo cây làm việc...';

  @override
  String get gitUiCreateACommitBeforeCreatingAWorktreeAtHEAD =>
      'Tạo commit trước khi tạo cây làm việc tại HEAD.';

  @override
  String get gitUiDetachedHEAD => 'HEAD tách rời';

  @override
  String get gitUiCurrent => 'Hiện tại';

  @override
  String get gitUiLocked => 'Bị khóa e·';

  @override
  String get gitUiOpenInBusyStack => 'Mở trong stack · bận rộn';

  @override
  String get gitUiStatusNotInspected => 'Trạng thái chưa được kiểm tra';

  @override
  String get gitUiDirty => 'Đồ bẩn thỉu';

  @override
  String get gitUiClean => 'Không có thay đổi';

  @override
  String get gitUiOpenWorkingFolder => 'Mở thư mục làm việc';

  @override
  String get gitUiMoveWorktree => 'Di chuyển cây lao động...';

  @override
  String get gitUiUnlock => 'Bỏ khoá';

  @override
  String get gitUiLock => 'Khoá';

  @override
  String get gitUiRemoveCleanWorktree => 'Gỡ bỏ cây làm việc sạch...';

  @override
  String get gitUiReviewRemovalIncludingLocalChanges =>
      'Xem lại việc gỡ bỏ bao gồm các thay đổi cục bộ...';

  @override
  String get gitUiNewWorktreeFolderName => 'Tên thư mục làm việc mới';

  @override
  String get gitUiNewWorktreeBranch => 'Chi nhánh cây làm việc mới';

  @override
  String gitUiCreateArg0Arg1WithANewLocalBranchAtArg2(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return 'Tạo $arg0/$arg1 với một chi nhánh cục bộ mới tại $arg2 ($arg3).';
  }

  @override
  String get gitUiDestinationFolderName => 'Tên thư mục đích';

  @override
  String get gitUiRemoveWorktree => 'Loại bỏ cây lao động?';

  @override
  String
  get gitUiExplicitlyDiscardAllLocalTrackedUntrackedChangesInThisWorktree =>
      'Bỏ qua hoàn toàn tất cả các thay đổi theo dõi/không theo dõi cục bộ trong cây làm việc này. Các cây lao động khóa/ trong sử dụng vẫn còn được bảo vệ.';

  @override
  String get gitUiGitRefusesRemovalIfThereAreLocalChangesUntrackedFiles =>
      'Git từ chối gỡ bỏ nếu có thay đổi cục bộ, tập tin chưa được đánh dấu, hoặc khóa.';

  @override
  String get gitUiDiscardLocalWorktreeContentsAndRemove =>
      'Bỏ qua nội dung của cây làm việc cục bộ và gỡ bỏ';

  @override
  String get gitUiRemoveCleanWorktree2 => 'Gỡ bỏ cây làm việc sạch';

  @override
  String
  get gitUiExplicitlyRecurseIntoNestedSubmodulesForUpdatesSynchronization =>
      'Tự động lặp lại thành các tiểu trang được làm tổ để cập nhật/ phù hợp';

  @override
  String get gitUiNoRecordedSubmodules => 'Không ghi âm các tập tin phụ';

  @override
  String get gitUiNotInitialized => 'chưa khởi động';

  @override
  String gitUiParentGitlinkArg0CheckedOutArg1(String arg0, String arg1) {
    return 'Phụ huynh gitlink: $arg0 đã kiểm tra: $arg1\n';
  }

  @override
  String get gitUiDirtyNestedRepository => 'Kho chứa tổ nhơ bẩn';

  @override
  String get gitUiCleanNestedRepository => 'kho chứa đã làm sạch';

  @override
  String get gitUiNestedStatusUnavailable =>
      'Trạng thái tổ chức không sẵn sàng';

  @override
  String get gitUiEnterNestedRepository => 'Nhập kho chứa tổ';

  @override
  String get gitUiInitializeConfiguration => 'Đang khởi tạo cấu hình';

  @override
  String get gitUiUpdateToParentSRecordedCommit =>
      'Cập nhật cho cha mẹ ghi chép về bản cam kết...';

  @override
  String get gitUiFollowConfiguredRemoteBranch =>
      'Theo chi nhánh được cấu hình từ xa...';

  @override
  String get gitUiSynchronizeConfiguredURLs => 'Đồng bộ hoá URL đã cấu hình...';

  @override
  String get gitUiStageCurrentSubmodulePointerInParent =>
      'Chuyển động con trỏ con dưới màn hình nền hiện tại trong cha mẹ';

  @override
  String get gitUiParentAndSubmoduleCommitsPushesAndDirtyStateRemainSeparate =>
      'Cha mẹ và tiểu học cam kết, thúc đẩy và trạng thái dơ bẩn vẫn còn tách biệt. Duyệt không khởi tạo hay cập nhật chúng.';

  @override
  String gitUiFetchAndCheckOutTheConfiguredRemoteBranchSCommit(String arg0) {
    return 'Hãy lấy và kiểm tra lại sự kết hợp của chi nhánh được cấu hình từ xa, khác với lời ghi chép của cha mẹ, đệ trình lại: $arg0.';
  }

  @override
  String gitUiInitializeAsNeededAndCheckOutExactlyArg0RecursiveArg1(
    String arg0,
    String arg1,
  ) {
    return 'Khởi tạo nếu cần và chuyển đến chính xác $arg0. Đệ quy: $arg1.';
  }

  @override
  String gitUiApplyTheReviewedSubmoduleConfigurationOperationRecursiveArg0(
    String arg0,
  ) {
    return 'Áp dụng thao tác cấu hình phụ đã duyệt. Đệ quy: $arg0.';
  }

  @override
  String get gitUiApplySubmoduleOperation => 'Áp dụng thao tác phụ';

  @override
  String get gitUiInspectARecordedRevisionOrCreateARecoveryBranchReflog =>
      'Xem xét một bản sửa đổi được ghi lại hoặc tạo một chi nhánh phục hồi. Không lấy lại nội dung không được lưu trữ tùy ý hoặc không bị theo dõi.';

  @override
  String get gitUiSelectAReflogEntry => 'Chọn mục nhập thay đổi tên';

  @override
  String get gitUiPreviousPage => 'Trang trước';

  @override
  String get gitUiNextPage => 'Trang kế';

  @override
  String get gitUiRecoveryBranchName => 'Tên chi nhánh phục hồi';

  @override
  String gitUiCreatesABranchAtArg0WorkingFilesAndTheCurrent(String arg0) {
    return 'Tạo một chi nhánh ở $arg0; làm việc tập tin và chi nhánh hiện tại không thay đổi.';
  }

  @override
  String get gitUiCreateRecoveryBranch => 'Tạo chi nhánh phục hồi...';

  @override
  String get gitUiReadOnlyRecoverySnapshot => 'Ảnh chụp phục hồi chỉ đọc';

  @override
  String get gitUiInspectSnapshot => 'Kiểm tra hình chụp...';

  @override
  String get gitUiReviewReset => 'Xem lại việc đặt lại…';

  @override
  String gitUiPageArg0(String arg0) {
    return 'Trang $arg0';
  }

  @override
  String get gitUiAGitTextHistoryMustOwnItsEditableField =>
      'Một lịch sử văn bản Git phải sở hữu trường hiệu chỉnh của nó.';

  @override
  String get gitUiEditHEADIndexWorkingTree =>
      'Chỉnh sửa HEAD | Chỉ mục | Cây làm việc…';

  @override
  String
  get gitUiTheReviewedIndexOrWorkingContentChangedRefreshThisComparison =>
      'Chỉ mục ôn lại hoặc nội dung hoạt động đã thay đổi. Hãy làm tươi sáng so sánh này trước khi thiết lập lại.';

  @override
  String get gitUiRefreshComparison => 'So sánh cập nhật';

  @override
  String get gitUiPreviousChangedFile => 'Tập tin đã thay đổi trước';

  @override
  String get gitUiNextChangedFile => 'Tập tin thay đổi tiếp theo';

  @override
  String get gitUiPreviousDifference => 'Hiệu ứng trước';

  @override
  String get gitUiNextDifference => 'Hiệu ứng tiếp theo';

  @override
  String get gitUiComparisonMode => 'Chế độ so sánh';

  @override
  String get gitUiSideBySide => 'Bên cạnh';

  @override
  String get gitUiUnified => 'Hợp nhất';

  @override
  String get gitUiDiffDisplayOptions => 'Tùy chọn hiển thị khác nhau';

  @override
  String get gitUiWrap => 'Gói';

  @override
  String get gitUiWords => 'Các từ';

  @override
  String get gitUiCollapseContext => 'Thu gọn ngữ cảnh';

  @override
  String get gitUiIgnoreWhitespace => 'Bỏ qua khoảng trắng';

  @override
  String get gitUiSearchComparison => 'So sánh tìm kiếm';

  @override
  String get gitUiSearch => 'Tìm kiếm';

  @override
  String get gitUiCloseSearch => 'Đóng tìm kiếm';

  @override
  String get gitUiStagingActions => 'Thao tác với chỉ mục';

  @override
  String get gitUiStagingActions2 => 'Thao tác với chỉ mục…';

  @override
  String get gitUiUnstageSelectedChangedLines =>
      'Bỏ dòng thay đổi đã chọn khỏi chỉ mục';

  @override
  String get gitUiStageSelectedChangedLines =>
      'Đưa dòng thay đổi đã chọn vào chỉ mục';

  @override
  String get gitUiUnstageWholeFile => 'Bỏ toàn bộ tệp khỏi chỉ mục';

  @override
  String get gitUiStageWholeFile => 'Đưa toàn bộ tệp vào chỉ mục';

  @override
  String gitUiArg0WhitespaceOnlyChangedLinesHiddenShowExactChanges(
    String arg0,
  ) {
    return '$arg0-Chỉ thay đổi dòng ẩn · Hiển thị các thay đổi chính xác';
  }

  @override
  String gitUiArg0ChangedLinesSelectedDisplaySettingsNeverAlterTheStaged(
    String arg0,
  ) {
    return '$arg0 đã thay đổi dòng · Hiển thị không bao giờ thay đổi các byte được sắp xếp.';
  }

  @override
  String get gitUiReadOnlyComparisonCopyTextOrAdjustDisplaySettings =>
      'So sánh chỉ đọc · Sao chép văn bản hoặc chỉnh cách hiển thị.';

  @override
  String get gitUiNoFinalNewline => ' · Không có dòng mới cuối';

  @override
  String gitUiArg0Arg1Arg2BytesArg3(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return '$arg0 · $arg1 · $arg2 byte$arg3';
  }

  @override
  String get gitUiTextComparisonIsUnavailableForTheseContents =>
      'So sánh văn bản không sẵn sàng cho nội dung này.';

  @override
  String get gitUiThisComparisonExceedsTheBoundedTextReviewLimitTheContents =>
      'Sự so sánh này vượt quá giới hạn xem xét văn bản bị giới hạn. Nội dung chưa được tuyên bố giống hệt nhau.';

  @override
  String get gitUiTheComparedContentsAreIdentical =>
      'Nội dung so sánh giống hệt nhau.';

  @override
  String get gitUiUnstage => 'Mở màn';

  @override
  String get gitUiStage => 'Giai đoạn';

  @override
  String gitUiArg0ChangedLine(String arg0) {
    return '$arg0 thay đổi dòng';
  }

  @override
  String get gitUiContext => 'Văn cảnh';

  @override
  String get gitUiExpandUnchangedContext => 'Mở rộng văn cảnh không thay đổi';

  @override
  String get gitUiUnstageThisHunk => 'Bỏ khối này khỏi chỉ mục';

  @override
  String get gitUiStageThisHunk => 'Đưa khối này vào chỉ mục';

  @override
  String gitUiEditStagedContentArg0(String arg0) {
    return 'Sửa đổi nội dung giai đoạn e. $arg0';
  }

  @override
  String get gitUiWritingReviewedIndexResult =>
      'Đang ghi kết quả xem xét chỉ mục';

  @override
  String get gitUiHead => 'HEAD';

  @override
  String get gitUiIndex => 'Chỉ mục';

  @override
  String get gitUiWorkingTree => 'Cây làm việc';

  @override
  String gitUiHeadArg0(String arg0) {
    return 'HEAD · $arg0';
  }

  @override
  String get gitUiIndexEditableUTF8Blob => 'Chỉ mục · sửa được UTF- 8 chấm';

  @override
  String get gitUiUndo => 'Hoàn tác';

  @override
  String get gitUiRedo => 'Làm lại';

  @override
  String get gitUiReloadIndexReview => 'Xem xét lại chỉ mục?';

  @override
  String get gitUiReloadTheCurrentHEADIndexAndWorkingVersionsThisReplaces =>
      'Tải lại phiên bản HEAD, chỉ mục và làm việc hiện tại. Thao tác này thay bản nháp chưa lưu trong trình sửa chỉ mục.';

  @override
  String get gitUiReplaceDraftAndReload => 'Thay thế bản nháp và nạp lại';

  @override
  String get gitUiReloadVersions => 'Tải lại phiên bản...';

  @override
  String get gitUiWriteEditedResultToThisIndexEntry =>
      'Ghi kết quả đã biên tập vào mục nhập chỉ mục này';

  @override
  String get gitUiWorkingFilesRemainOnDiskReviewTheEditedIndexBefore =>
      'Làm việc tập tin còn lại trên đĩa. Xem lại chỉ mục đã sửa trước khi áp dụng.';

  @override
  String get gitUiReviewIndexTextFormatChanges =>
      'Xem lại định dạng văn bản phụ lục';

  @override
  String gitUiUpdateOnlyTheReviewedIndexEntryForArg0Arg1(
    String arg0,
    String arg1,
  ) {
    return 'Cập nhật chỉ mục ghi chú $arg0. $arg1';
  }

  @override
  String get gitUiWriteReviewedIndexResult => 'Ghi kết quả đã ôn lại chỉ mục';

  @override
  String get gitUiTheEditedResultChangedDuringFormatReviewReviewItAgain =>
      'Kết quả đã thay đổi trong quá trình xem xét định dạng. Xem lại lần nữa.';

  @override
  String get gitUiSynchronizeScrolling => 'Đồng bộ hoá cuộn';

  @override
  String get gitUiReadOnlyRevisionContent => 'Chỉ đọc nội dung sửa đổi';

  @override
  String get gitUiEditableIndexContent => 'Nội dung chỉ mục có thể sửa';

  @override
  String get gitUiTheRequestedRevisionIsOutsideTheCurrentFiltersResetFilters =>
      'Việc sửa đổi đã yêu cầu nằm ngoài bộ lọc hiện thời. Đặt lại bộ lọc để hiển thị nó.';

  @override
  String get gitUiFilterLog => 'Bản ghi bộ lọc';

  @override
  String get gitUiFilters => 'Bộ lọc...';

  @override
  String gitUiFiltersCount(String count) {
    return 'Bộ lọc ($count)...';
  }

  @override
  String get gitUiMessage => 'Thông điệp…';

  @override
  String get gitUiAuthor => 'Tác giả…';

  @override
  String get gitUiPath => 'Đường dẫn...';

  @override
  String get gitUiDate => 'Ngày...';

  @override
  String get gitUiMessageFilter => 'Bộ lọc thông điệp';

  @override
  String get gitUiAuthorFilter => 'Bộ lọc Tác giả';

  @override
  String get gitUiPathFilter => 'Bộ lọc đường dẫn';

  @override
  String get gitUiMessage2 => 'Thông điệp';

  @override
  String get gitUiAuthor2 => 'Tác giả';

  @override
  String get gitUiPath2 => 'Đường dẫn';

  @override
  String get gitUiDateFilter => 'Lọc ngày...';

  @override
  String get gitUiResetFilters => 'Đặt lại bộ lọc';

  @override
  String get gitUiRefreshLog => 'Bản ghi cập nhật';

  @override
  String get gitUiGoToCommitReference => 'Tới để xác nhận/ tham chiếu...';

  @override
  String get gitUiBackToHEAD => 'Trở về HEAD';

  @override
  String get gitUiOrderedCherryPick => 'Cherry-pick theo thứ tự đã chọn';

  @override
  String gitUiReviewCherryPickArg0(String arg0) {
    return 'Xem xét lại việc hái anh đào ($arg0)...';
  }

  @override
  String get gitUiCompareTwoSelectedRevisions =>
      'So sánh hai hiệu chỉnh đã chọn...';

  @override
  String get gitUiToggleBranchesPane => 'Bật/ tắt ô ô chi nhánh';

  @override
  String get gitUiFilterBranchesAndTags => 'Chi nhánh và thẻ lọc';

  @override
  String gitUiCommitArg0(String arg0) {
    return 'Nhấn $arg0';
  }

  @override
  String get gitUiCommitDetails => 'Ghi rõ chi tiết...';

  @override
  String gitUiReferenceArg0(String arg0) {
    return 'Tham khảo: $arg0';
  }

  @override
  String get gitUiSelectThisCommit => 'Chọn commit này';

  @override
  String get gitUiBranchOrTag => 'Chi nhánh hay Thẻ';

  @override
  String get gitUiAllReferences => 'Mọi tham chiếu';

  @override
  String get gitUiLocal => 'Cục bộ';

  @override
  String get gitUiRemote => 'Từ xa';

  @override
  String get gitUiTags => 'Thẻ';

  @override
  String get gitUiNoCommitsMatchTheCurrentFilters =>
      'Không có cam kết phù hợp với bộ lọc hiện thời.';

  @override
  String get gitUiObjectID => 'ID đối tượng';

  @override
  String get gitUiSubjectReferences => 'Đối tượng / tham chiếu';

  @override
  String get gitUiDate2 => 'Ngày';

  @override
  String get gitUiGitCommits => 'Các commit Git';

  @override
  String get gitUiParents => 'Các commit cha';

  @override
  String gitUiArg0Parents(String arg0) {
    return '$arg0 bậc cha mẹ';
  }

  @override
  String get gitUiLoadMoreCommits => 'Tải thêm cam kết';

  @override
  String get gitUiLoadingChangedFiles => 'Đang tải tập tin đã thay đổi';

  @override
  String get gitUiNoChangedFiles => 'Không có tập tin thay đổi';

  @override
  String get gitUiSelectACommit => 'Chọn một cam kết';

  @override
  String gitUiCompareParentArg0Arg1(String arg0, String arg1) {
    return 'So sánh phụ huynh $arg0: $arg1';
  }

  @override
  String get gitUiChangedFiles => 'Tệp đã thay đổi';

  @override
  String gitUiAuthorArg0Arg1Arg2(String arg0, String arg1, String arg2) {
    return 'Tác giả: $arg0 <$arg1> $arg2';
  }

  @override
  String gitUiCommitterArg0Arg1Arg2(String arg0, String arg1, String arg2) {
    return 'Bản cam kết: $arg0 <$arg1> $arg2';
  }

  @override
  String get gitUiShallowPartialBoundaryAParentObjectIsUnavailable =>
      'Giới hạn dưới: không có đối tượng phụ huynh.';

  @override
  String get gitUiParentIsOutsideThisPageOrAShallowBoundary =>
      'Cha mẹ ở ngoài trang này hoặc là một giới hạn nông cạn.';

  @override
  String gitUiParentArg0(String arg0) {
    return 'Commit cha $arg0';
  }

  @override
  String get gitUiCommitActions => 'Hành động & lặp lại';

  @override
  String get gitUiEmptyTree => 'Cây trống';

  @override
  String get gitUiCreateBranch2 => 'Tạo nhánh';

  @override
  String get gitUiCreateTag => 'Tạo thẻ';

  @override
  String get gitUiCompareRevisions => 'So sánh hiệu chỉnh';

  @override
  String get gitUiOpenSnapshot => 'Mở hình chụp';

  @override
  String get gitUiRevertCommit => 'Hoàn nguyên';

  @override
  String get gitUiInteractiveRebaseAfterThisBoundary => 'Comment';

  @override
  String get gitUiResetCurrentBranch => 'Đặt lại nhánh hiện tại';

  @override
  String get gitUiCopyFullObjectID => 'Chép toàn bộ ID đối tượng';

  @override
  String get gitUiGoToCommitReference2 => 'Tới để xác nhận/ truy cập';

  @override
  String get gitUiEnterACommitIDOrReferenceToRevealInLog =>
      'Hãy nhập vào tên người dùng hoặc tham chiếu để tiết lộ trong bản ghi.';

  @override
  String get gitUiTheRequestedRevisionIsUnavailable =>
      'Việc sửa đổi đã yêu cầu không sẵn sàng.';

  @override
  String
  get gitUiRepositoryMetadataIsReadOnlyBranchInspectionAndComparisonRemain =>
      'Thư mục siêu dữ liệu cục bộ chỉ được đọc. Kiểm tra chi nhánh và so sánh sẵn sàng.';

  @override
  String get gitUiWorkingFilesAreUnavailableOrReadOnlyBranchSwitchingAnd =>
      'Tập tin làm việc không sẵn sàng hay chỉ đọc. Không có khả năng chuyển đổi và trộn các nhánh.';

  @override
  String get gitUiSearchBranchesAndTags => 'Tìm nhánh và thẻ';

  @override
  String get gitUiNewBranch => 'Nhánh mới…';

  @override
  String get gitUiLocalBranches => 'Nhánh cục bộ';

  @override
  String get gitUiRemoteBranches => 'Nhánh từ xa';

  @override
  String gitUiTracksArg0(String arg0) {
    return 'Theo dõi $arg0';
  }

  @override
  String gitUiCheckedOutAtArg0(String arg0) {
    return 'Đã kiểm tra tại $arg0';
  }

  @override
  String get gitUiRefreshingBranchMetadata =>
      'Đang cập nhật siêu dữ liệu chi nhánh';

  @override
  String gitUiSwitchToArg0(String arg0) {
    return 'Chuyển sang $arg0';
  }

  @override
  String get gitUiOpenOccupiedWorktree => 'Mở cây lao động bận';

  @override
  String get gitUiCreateLocalTrackingBranch =>
      'Tạo chi nhánh theo dõi cục bộ...';

  @override
  String get gitUiCompareToCurrentHEAD => 'So sánh với HEAD hiện tại';

  @override
  String get gitUiMergeIntoCurrentBranch => 'Nhập vào nhánh hiện tại...';

  @override
  String get gitUiRename => 'Thay tên...';

  @override
  String get gitUiChangeUpstream => 'Thay đổi ngược dòng...';

  @override
  String get gitUiDelete => 'Xoá...';

  @override
  String get gitUiDeleteFromRemote => 'Xoá từ xa...';

  @override
  String gitUiActionsForArg0(String arg0) {
    return 'Hành động cho $arg0';
  }

  @override
  String get gitUiLocalBranchName => 'Tên chi nhánh cục bộ';

  @override
  String gitUiCreateAtArg0TheNewBranchWillBeCheckedOut(String arg0) {
    return 'Tạo tại $arg0. Chi nhánh mới sẽ được kiểm tra.';
  }

  @override
  String gitUiTheLocalBranchWillTrackArg0AndBeCheckedOut(String arg0) {
    return 'Chi nhánh địa phương sẽ theo dõi $arg0 và được kiểm tra.';
  }

  @override
  String get gitUiChooseRemoteForDeletion => 'Chọn từ xa để xoá';

  @override
  String get gitUiDeleteRemoteReference => 'Xoá tham chiếu từ xa';

  @override
  String gitUiMergeArg0IntoArg1(String arg0, String arg1) {
    return 'Nhập $arg0 vào $arg1';
  }

  @override
  String gitUiRenameArg0(String arg0) {
    return 'Thay tên $arg0';
  }

  @override
  String gitUiUpstreamForArg0(String arg0) {
    return 'Lên ngược dòng cho $arg0';
  }

  @override
  String get gitUiNoUpstream => 'Chưa có nhánh thượng nguồn';

  @override
  String gitUiDeleteArg0(String arg0) {
    return 'Xoá $arg0?';
  }

  @override
  String gitUiArg0TargetArg1LocalDeletionOnlyAnUnmergedBranchIs(
    String arg0,
    String arg1,
  ) {
    return '$arg0 Target $arg1 địa phương chỉ bị xóa bỏ.';
  }

  @override
  String get gitUiDelete2 => 'Xóa';

  @override
  String gitUiDeleteUnmergedBranchArg0(String arg0) {
    return 'Xóa bỏ nhánh $arg0?';
  }

  @override
  String gitUiArg0GitReportsThisBranchIsNotFullyMergedExplicitly(String arg0) {
    return '$arg0 Git báo cáo chi nhánh này chưa được hợp nhất hoàn toàn. Rõ ràng xóa mục tham khảo cục bộ sau khi xem lại những việc đã làm; các bản sao từ xa không thay đổi.';
  }

  @override
  String get gitUiDeleteUnmergedLocalBranch => 'Xoá( delete)';

  @override
  String gitUiDestinationArg0Arg1(String arg0, String arg1) {
    return 'Đích: $arg0 · $arg1';
  }

  @override
  String get gitUiSourceBranchOrTag => 'Chi nhánh hay thẻ nguồn';

  @override
  String get gitUiMergePolicy => 'Chính sách trộn';

  @override
  String get gitUiFastForwardWhenPossible => 'tua nhanh khi có thể';

  @override
  String get gitUiAlwaysCreateAMergeCommit =>
      'Luôn luôn tạo ra một cam kết nhập';

  @override
  String get gitUiFastForwardOnly => 'Chỉ tua nhanh';

  @override
  String get gitUiSquashIntoStagedChanges =>
      'Squash thành các thay đổi đã dàn dựng';

  @override
  String get gitUiStopBeforeCreatingTheMergeCommit =>
      'Dừng lại trước khi tạo ra sự hợp nhất';

  @override
  String get gitUiFastForwardIsDisabledSoHEADCannotMoveBeforeReview =>
      'Tua nhanh bị tắt để HEAD không di chuyển trước khi xem xét.';

  @override
  String get gitUiLeavesStagedChangesForASeparateCommitThisIsNot =>
      'Để lại những thay đổi được sắp xếp cho một cam kết riêng biệt; đây không phải là một sự kết hợp liên tục.';

  @override
  String get gitUiConflictsRemainAvailableInTheSharedResolutionWorkspace =>
      'Các cuộc xung đột vẫn còn trong vùng làm việc giải quyết chung.';

  @override
  String get gitUiAddRemote => 'Thêm từ xa...';

  @override
  String gitUiFetchArg0PushArg1(String arg0, String arg1) {
    return 'Thu thập: $arg0 Push: $arg1';
  }

  @override
  String get gitUiRemoveRemote => 'Gỡ bỏ từ xa...';

  @override
  String get gitUiChangeFetchURL => 'Đổi URL...';

  @override
  String get gitUiAddPushDestination => 'Thêm mục tiêu đẩy...';

  @override
  String get gitUiRemovePushDestination => 'Gỡ bỏ đích đẩy...';

  @override
  String gitUiManageArg0(String arg0) {
    return 'Quản lý $arg0';
  }

  @override
  String get gitUiRemoteName => 'Tên từ xa';

  @override
  String get gitUiNewRemoteName => 'Tên từ xa mới';

  @override
  String get gitUiRepositoryURLOrLocalSource => 'Thư điện tử hoặc nguồn cục bộ';

  @override
  String get gitUiEnterTheExactReviewedDestinationToRemove =>
      'Hãy nhập đích xem lại chính xác cần gỡ bỏ.';

  @override
  String get gitUiCredentialsAreSuppliedByConfiguredHelpersOrAPrivatePrompt =>
      'Tài liệu nhận diện được cung cấp bởi những người giúp việc đã cấu hình hoặc một dấu nhắc riêng.';

  @override
  String gitUiRemoveRemoteArg0(String arg0) {
    return 'Loại bỏ điều khiển $arg0?';
  }

  @override
  String
  get gitUiRemovesLocalRemoteConfigurationAndTrackingReferencesItDoesNot =>
      'Gỡ bỏ các cấu hình và tham chiếu theo từ xa cục bộ. Nó không xóa bỏ kho phần mềm của máy phục vụ.';

  @override
  String get gitUiRemoveRemote2 => 'Gỡ bỏ từ xa';

  @override
  String get gitUiCommitScopeEntireRepository => 'Phạm vị độ sâu:';

  @override
  String get gitUiCachedTracking => 'Theo dõi sự rối loạn';

  @override
  String get gitUiAmendLastCommit => 'Sửa commit cuối';

  @override
  String get gitUiConfiguredHooksAndSigningAreRespected =>
      'Những cái móc được cấu hình và ký được tôn trọng.';

  @override
  String get gitUiRewritesTheSelectedHEADCommitRemoteTrackingCannotProveIt =>
      'Viết lại commit HEAD đã chọn. Theo dõi từ xa không chứng minh commit chưa được công bố.';

  @override
  String get gitUiRepository => 'Kho lưu trữ';

  @override
  String gitUiDetachedArg0(String arg0) {
    return '$arg0 đã tách rời';
  }

  @override
  String get gitUiLog => 'Lịch sử';

  @override
  String get gitUiRepositoryActions => 'Thao tác kho lưu trữ';

  @override
  String gitUiCachedTrackingUpstreamAheadAheadBehindBehind(
    String upstream,
    String ahead,
    String behind,
  ) {
    return 'Thông tin theo dõi đã lưu · $upstream · đi trước $ahead · đi sau $behind';
  }

  @override
  String get gitUiBareRepositoryNoWorkingTreeOpenLogToInspectIts =>
      'Kho lưu trữ · không có cây lao động mở bản ghi để kiểm tra lịch sử của nó.';

  @override
  String get gitUiReadOnlyRepositoryStagingAndCommitsAreUnavailable =>
      'Không có kho phần mềm đọc e· deciting và cam kết.';

  @override
  String get gitUiRepositoryStatusUnavailable =>
      'Không thể tạo thư mục home% 1. Lỗi:% 2';

  @override
  String gitUiAmendRevision(String revision) {
    return 'Sửa $revision';
  }

  @override
  String get gitUiAddSignOffTrailer => 'Thêm dòng xác nhận';

  @override
  String get gitUiUseConfiguredSigningPolicy =>
      'Dùng chính sách ký tự đã cấu hình';

  @override
  String get gitUiCryptographicallySignThisCommit => 'Mật mã ký cam kết này';

  @override
  String get gitUiDoNotSignThisCommit => 'Đừng ký cam kết này.';

  @override
  String get gitUiRecentCommitMessages => 'Đang gửi tin nhắn...';

  @override
  String get gitUiUseConfiguredCommitTemplate => 'Dùng mẫu đã cấu hình...';

  @override
  String get gitUiAuthorIdentityAndConfiguredHooks =>
      'Tác giả và móc đã cấu hình...';

  @override
  String get gitUiDraftMessage => 'Đang cập nhật thông điệp...';

  @override
  String get gitUiCommitOptions => 'Tùy chọn commit';

  @override
  String gitUiDraftRetainedInMemorySavingItFailedArg0(String arg0) {
    return 'Nháp giữ lại trong bộ nhớ; lưu nó thất bại. $arg0';
  }

  @override
  String get gitUiCommitMessage => 'Thông điệp commit';

  @override
  String get gitUiGitOperationInProgress => 'Thao tác Git đang tiến hành';

  @override
  String get gitUiCancel => 'Hủy';

  @override
  String get gitUiAmendStaged => 'Đã chỉnh sửa';

  @override
  String gitUiCommitStagedCount(String count) {
    return 'Commit nội dung trong chỉ mục ($count)';
  }

  @override
  String get gitUiCommitAndPush => 'Commit rồi đẩy lên…';

  @override
  String get gitUiNoReadableCommitTemplateIsConfigured =>
      'Không có mẫu nhập có khả năng đọc.';

  @override
  String get gitUiCommitIdentityAndHooks => 'Tạo danh tính và móc';

  @override
  String get gitUiRecentMessages => 'Tin nhắn gần đây';

  @override
  String get gitUiReplaceMessageDraft => 'Bản nháp thông điệp thay thế?';

  @override
  String get gitUiReplaceTheExistingCommitMessageWithTheSelectedMessage =>
      'Thay thế thông điệp cam kết tồn tại bằng thông điệp đã chọn?';

  @override
  String get gitUiReplaceDraft => 'Bản nháp thay thế';

  @override
  String gitUiLocalCommitArg0Exists(String arg0) {
    return 'Địa phương cam kết $arg0 tồn tại.';
  }

  @override
  String gitUiLocalCommitArg0ExistsReviewLogBeforeAttemptingAnotherCommit(
    String arg0,
  ) {
    return 'Địa phương thông báo $arg0 tồn tại. Xem lại bản ghi trước khi cố thực hiện một nhiệm vụ khác. Bản nháp thông điệp đã được giữ lại.';
  }

  @override
  String get gitUiCommitAuthorName => 'Nhấn để thêm chú thích...';

  @override
  String get gitUiCommitAuthorEmail => 'Thư điện tử tác giả cam kết';

  @override
  String get gitUiConfiguredDefault => 'Đã cấu hình mặc định';

  @override
  String get gitUiOpenpgp => 'OpenPGP';

  @override
  String gitUiSigningArg0Arg1(String arg0, String arg1) {
    return 'Ký tên: $arg0 ·$arg1';
  }

  @override
  String gitUiConfiguredHooksArg0(String arg0) {
    return 'Các móc đã cấu hình: $arg0';
  }

  @override
  String get gitUiASignOffTrailerIsAStatementInTheMessage =>
      'Dòng xác nhận là tuyên bố trong thông điệp, khác với chữ ký mật mã. Danh tính chỉ được lưu vào cấu hình cục bộ của kho này; bản nháp được giữ lại.';

  @override
  String get gitUiSaveRepositoryIdentity => 'Lưu tên kho phần mềm';

  @override
  String get gitUiStaged => 'Đã đưa vào chỉ mục';

  @override
  String get gitUiUntracked => 'Chưa được theo dõi';

  @override
  String get gitUiUnstaged => 'Chưa đưa vào chỉ mục';

  @override
  String get gitUiConflicts => 'Xung đột';

  @override
  String get gitUiNoChanges => 'Không có thay đổi';

  @override
  String get gitUiRepositoryChangeTree => 'Thư mục homeName';

  @override
  String get gitUiChanges => 'Thay đổi';

  @override
  String gitUiGroupCount(String group, String count) {
    return '$group ($count)';
  }

  @override
  String get gitUiExpand => 'Mở rộng';

  @override
  String get gitUiCollapse => 'Co lại';

  @override
  String get gitUiUnstageFile => 'Bỏ tệp khỏi chỉ mục';

  @override
  String get gitUiStageFile => 'Đưa tệp vào chỉ mục';

  @override
  String get gitUiExpandGroup => 'Mở rộng nhóm';

  @override
  String get gitUiCollapseGroup => 'Nhóm co lại';

  @override
  String get gitUiReviewDifference => 'Sự khác biệt ôn lại';

  @override
  String get gitUiUnstageSelectedFiles => 'Bỏ tệp đã chọn khỏi chỉ mục';

  @override
  String get gitUiStageSelectedFiles => 'Đưa tệp đã chọn vào chỉ mục';

  @override
  String get gitUiFileHistoryAndBlame => 'Tập tin lịch sử và trách nhiệm...';

  @override
  String get gitUiDeleteUntrackedFile => 'Xoá tập tin chưa được theo dõi...';

  @override
  String get gitUiDiscardUnstagedChange =>
      'Bỏ qua những thay đổi chưa được chuẩn bị...';

  @override
  String get gitUiFileHistory => 'Lịch sử tệp';

  @override
  String gitUiDiscardUnstagedArg0(String arg0) {
    return 'Bỏ lá bài $arg0?';
  }

  @override
  String gitUiArg0BytesArg1ReplacesWorkingContentWithTheIndexOr(
    String arg0,
    String arg1,
  ) {
    return '$arg0 byte· $arg1 thay thế nội dung hoạt động bằng chỉ mục, hoặc xoá tập tin chưa được theo dõi này. Nội dung cơ bản đã được giữ lại. Cần phải xem lại tài liệu máy chủ chưa được lưu trước tiên.';
  }

  @override
  String get gitUiDeleteUntrackedFile2 => 'Xoá tập tin chưa được theo dõi';

  @override
  String get gitUiDiscardWorkingChange => 'Bỏ qua các thay đổi làm việc';

  @override
  String gitUiDeleteREMOTEReferenceArg0(String arg0) {
    return 'Xoá tham chiếu REMTE $arg0';
  }

  @override
  String get gitUiThisRemovesTheReferenceOnEveryActualPushDestinationListed =>
      'Việc này xóa bỏ tham chiếu về mỗi đích thực được liệt kê bên dưới. Các nhánh/g địa phương được giữ lại. Các mẹo được mong đợi sẽ được cố định bởi đánh giá này.';

  @override
  String get gitUiReferenceDoesNotExist => 'tham chiếu không tồn tại';

  @override
  String gitUiArg0ExpectedTipArg1(String arg0, String arg1) {
    return '$arg0 mong đợi tiền boa: $arg1';
  }

  @override
  String get gitUiRemoteDeletionCompleted => 'Việc xóa từ xa hoàn tất.';

  @override
  String gitUiDeleteArg0FromTheRemote(String arg0) {
    return 'Xoá $arg0 từ xa?';
  }

  @override
  String get gitUiTheExactDestinationTipsShownAboveWillBeRemovedAny =>
      'Các lời mách đích đích chính xác được hiển thị ở trên sẽ bị gỡ bỏ. Bất kỳ mẹo nào thay đổi từ xa sẽ dừng thao tác này lại để xem xét lại một lần nữa.';

  @override
  String get gitUiReviewAndDeleteFromRemote => 'Xem lại và xoá từ xa...';

  @override
  String get gitUiDestinationReference => 'Tham chiếu đích';

  @override
  String get gitUiReviewDestinations => 'Điểm đến ôn lại';

  @override
  String get gitUiNewRemoteBranch => 'Chi nhánh mới từ xa';

  @override
  String gitUiArg0Arg1ExpectedArg2(String arg0, String arg1, String arg2) {
    return '$arg0\n$arg1 · dự kiến: $arg2';
  }

  @override
  String get gitUiADestinationHasCommitsThatAreUnavailableLocallyFetchThat =>
      'Một điểm đến đã cam kết không sẵn sàng tại địa phương. Hãy tìm điểm đến đó trước khi xem lại lịch sử đi.';

  @override
  String get gitUiFetchReviewedDestination => 'Lấy điểm đến đã ôn lại';

  @override
  String get gitUiChooseADestinationAndReviewTheOutgoingCommits =>
      'Chọn một đích và xem lại các cam kết đi.';

  @override
  String get gitUiNoOutgoingCommits => 'Không ai được phép ra tay';

  @override
  String get gitUiSelectAnOutgoingCommit => 'Chọn một việc đi ra';

  @override
  String get gitUiLoadMoreOutgoingCommits => 'Tải thêm thông tin đi';

  @override
  String get gitUiSetThisDestinationAsUpstream =>
      'Đặt đích này là thượng nguồn';

  @override
  String get gitUiChooseExactTagsToPublish => 'Chọn thẻ chính xác cần xuất';

  @override
  String get gitUiTagsNone => 'Thẻ: không có';

  @override
  String gitUiTagsArg0Selected(String arg0) {
    return 'Thẻ: %s: $arg0 được chọn';
  }

  @override
  String gitUiPublishExactlyArg0(String arg0) {
    return 'Xuất bản chính xác: $arg0';
  }

  @override
  String get gitUiPushCompletedTheLocalCommitRemainsAvailableInLog =>
      'Nhấn hoàn tất.';

  @override
  String get gitUiForceRequiresTheExactDestinationTipsShownInThisReview =>
      'Đẩy cưỡng bức yêu cầu đầu các tham chiếu đích trùng khớp chính xác với những gì được xem xét ở đây.';

  @override
  String get gitUiForceWithReviewedLease =>
      'Lực lượng đã xem xét lại hợp đồng thuê...';

  @override
  String get gitUiPush => 'Đẩy lên';

  @override
  String get gitUiForcePushWithReviewedLeases =>
      'Bắt buộc phải tăng giá hợp đồng thuê?';

  @override
  String gitUiRewriteArg0OnlyIfEveryRemoteDestinationStillHasThe(String arg0) {
    return 'Viết lại $arg0 chỉ khi mọi điểm đến từ xa vẫn có điểm bùng phát chính xác ở trên.\n';
  }

  @override
  String get gitUiOtherPeopleMayAlreadyUseThisHistoryABackgroundFetch =>
      'Người khác có thể đã dùng lịch sử này. Việc tải về trong nền không gia hạn điều kiện bảo vệ này.';

  @override
  String get gitUiForceWithLease => 'Buộc phải thuê nhà';

  @override
  String
  get gitUiTheRemoteOutcomeIsUncertainReviewDestinationsAgainBeforeAnother =>
      'Kết quả từ xa không chắc chắn. Xem lại đích đến trước khi đẩy.';

  @override
  String gitUiParentArg0Arg1(String arg0, String arg1) {
    return 'Phụ huynh $arg0 · $arg1';
  }

  @override
  String get gitUiRemoteToFetch => '♪ Từ xa để lấy ♪';

  @override
  String get gitUiPruneDeletedRemoteTrackingBranches =>
      'Prune xoá các nhánh theo dõi từ xa';

  @override
  String
  get gitUiFetchUpdatesRemoteTrackingInformationWithoutReplacingWorkingFiles =>
      'Lấy cập nhật cho các thông tin theo dõi từ xa mà không thay thế tập tin hoạt động.';

  @override
  String get gitUiFetch => 'Tải về';

  @override
  String get gitUiSourceRemote => 'Từ xa nguồn';

  @override
  String get gitUiSourceBranch => 'Chi nhánh Nguồn';

  @override
  String get gitUiReviewedStrategy => 'Phương pháp ôn lại';

  @override
  String get gitUiMerge => 'Hợp nhất';

  @override
  String get gitUiRebase => 'Đổi gốc';

  @override
  String get gitUiStopIfTheDestinationCannotFastForwardNeverMergeOr =>
      'Dừng lại nếu đích không thể tua lại nhanh; không bao giờ hợp nhất hoặc rease.';

  @override
  String get gitUiMergeWithAMergeCommitIncludingWhenFastForwardIs =>
      'Nhập với sự hợp nhất, bao gồm cả khi có thể.';

  @override
  String get gitUiMergeAllowFastForwardWhenPossible =>
      'Nhập; cho phép tua nhanh khi có thể.';

  @override
  String get gitUiRebaseLocalHistoryWhilePreservingLocalMergeCommits =>
      'Hãy xây dựng lại lịch sử địa phương trong khi bảo tồn việc hợp nhất địa phương.';

  @override
  String get gitUiRebaseLocalCommitsAsALinearHistory =>
      'Căn cứ vào địa phương như một lịch sử tuyến tính.';

  @override
  String get gitUiGitIsConfiguredForInteractiveRebaseSelectAPullStrategy =>
      'Git được cấu hình cho cơ sở dữ liệu tương tác. Hãy chọn một chiến lược kéo rõ ràng ở đây, hoặc lấy và mở khung... để xem xét một kế hoạch.';

  @override
  String get gitUiUseReviewedOrdinaryRebaseForThisPull =>
      'Dùng cơ số xem xét lại thường cho kéo này';

  @override
  String get gitUiOptions => 'Tùy chọn';

  @override
  String get gitUiAlwaysCreateAMergeCommitNoFastForward =>
      'Luôn luôn tạo một thực hiện hợp nhất (không tua nhanh)';

  @override
  String get gitUiPreserveLocalMergeCommits => 'Bảo tồn hợp nhất cục bộ';

  @override
  String get gitUiLocalChangesMayPreventPullReviewCommitThemOrExplicitly =>
      'Thay đổi cục bộ có thể ngăn cản kéo. Xem lại/ hứa hẹn hoặc tạo ra một nơi cất giấu rõ ràng.';

  @override
  String get gitUiStashes => 'Các bản cất tạm';

  @override
  String get gitUiCreateOrReviewStash => 'Tạo hay duyệt lại ổ lưu trữ...';

  @override
  String get gitUiPullWithSelectedStrategy => 'Kéo với chiến lược đã chọn';

  @override
  String get gitUiRepositoryURLOrLocalGitSource =>
      'Thư điện tử hoặc nguồn Git cục bộ';

  @override
  String get gitUiHttpsSSHOrLocalPath => 'HTTPS, SSH, hoặc đường dẫn cục bộ';

  @override
  String get gitUiFolderToInitialize => 'Thư mục để khởi chạy';

  @override
  String get gitUiFinalCloneDestination => 'Điểm đến nhân bản cuối cùng';

  @override
  String get gitUiChoose => 'Chọn...';

  @override
  String get gitUiCreatesGitMetadataOnlyExistingFilesAreNotStagedOr =>
      'Tạo chỉ siêu dữ liệu Git. Không tạo hay thực hiện tập tin tồn tại.';

  @override
  String get gitUiTheFinalDestinationMustBeAbsentOrEmptyExistingUser =>
      'Đích cuối cùng phải chưa tồn tại hoặc phải trống. Dữ liệu sẵn có của người dùng không bao giờ bị ghi đè.';

  @override
  String get gitUiInitialBranchBlankUsesEffectiveGitPolicy =>
      'Ban đầu, nhánh · trống sử dụng chính sách Git hiệu quả';

  @override
  String get gitUiSelectedBranchOptional => 'Chi nhánh đã chọn · tùy chọn';

  @override
  String get gitUiExplicitlyInitializeUpdateSubmodulesRecursively =>
      'Hoàn toàn khởi động/ cập nhật phụ thuộc vào đệ quy';

  @override
  String get gitUiPreparingGitOperation => 'Đang chuẩn bị hoạt động Git...';

  @override
  String get gitUiThisAttemptCreated => 'Thử ra';

  @override
  String get gitUiTheDestinationExistedBeforeThisAttempt =>
      'Địa điểm đã tồn tại trước khi thử nghiệm này:';

  @override
  String get gitUiTheDirectoryRemainsForInspectionReviewItBeforeAnotherClone =>
      'Thư mục còn lại để kiểm tra.';

  @override
  String get gitUiNoDestinationDirectoryRemains =>
      'Không còn thư mục đích nào còn lại.';

  @override
  String get gitUiCancelProcess => 'Hủy tiến trình';

  @override
  String get gitUiInitialize => 'Khởi tạo';

  @override
  String get gitUiClone => 'Nhân bản';

  @override
  String get gitUiChooseNewBase => 'Chọn gốc mới';

  @override
  String get gitUiChooseUpstreamBoundary => 'Chọn ranh giới thượng nguồn';

  @override
  String get gitUiNewBase => 'Gốc mới';

  @override
  String get gitUiUpstreamBoundaryExcluded =>
      'Ranh giới thượng nguồn · không bao gồm';

  @override
  String get gitUiSameAsUpstreamBoundary => 'Giống ranh giới thượng nguồn';

  @override
  String get gitUiChooseBranchTagOrCommit => 'Chọn nhánh, thẻ hoặc commit…';

  @override
  String get gitUiUseUpstreamAsNewBase => 'Dùng dòng lên làm cơ sở mới';

  @override
  String get gitUiChooseAValidBranchTagOrCommitFromLog =>
      'Chọn một nhánh hợp lệ, thẻ hoặc tác vụ từ bản ghi.';

  @override
  String get gitUiTheFirstRetainedCommitInABranchBlockCannotSquash =>
      'Commit đầu tiên được giữ trong khối nhánh không thể dùng squash hay fixup vì chưa có commit đích đứng trước.';

  @override
  String gitUiBranchBlockArg0(String arg0) {
    return 'Khu vực chi nhánh $arg0\n';
  }

  @override
  String get gitUiRewordWillRequestANewMessage =>
      '[Từ ngữ sẽ yêu cầu một thông điệp mới]\n';

  @override
  String get gitUiPlannedCommitMessages => 'Comment';

  @override
  String
  get gitUiOriginalCombinedMessagePreviewGitRequestsTheFinalRewordSquash =>
      'Xem thử thông điệp gốc/ tổ hợp · Git yêu cầu tin nhắn cuối cùng';

  @override
  String gitUiResultArg0Arg1(String arg0, String arg1) {
    return 'Kết quả $arg0 $arg1';
  }

  @override
  String gitUiCurrentBranchBranch(String branch) {
    return 'Nhánh hiện tại: $branch';
  }

  @override
  String get gitUiDetachedHEAD2 => 'HEAD tách rời';

  @override
  String
  get gitUiRebaseRewritesCommitIdentitiesRemoteTrackingInformationCannotProveHistory =>
      'Đổi gốc sẽ viết lại định danh commit. Thông tin theo dõi từ xa không chứng minh rằng lịch sử chưa từng được công bố.';

  @override
  String get gitUiIncludeRootCommits => 'Bao gồm commit gốc';

  @override
  String get gitUiMergeCommits => 'Hợp nhất';

  @override
  String get gitUiFlattenHistory => 'Làm phẳng lịch sử';

  @override
  String get gitUiPreserveBranchStructure => 'Giữ cấu trúc nhánh';

  @override
  String get gitUiAutosquash => 'Tự động gộp';

  @override
  String get gitUiPrepareGitPlan => 'Chuẩn bị kế hoạch Git';

  @override
  String gitUiCommitsToReplayCount(String count) {
    return 'Các commit sẽ áp dụng lại: $count';
  }

  @override
  String get gitUiIncludesAllRootCommitsReachableFromThisBranch =>
      'Bao gồm tất cả các gốc cây cam kết có thể đạt được từ chi nhánh này.';

  @override
  String gitUiCommitsAfterBoundaryWillBeReplayedOntoBaseTheBoundary(
    String boundary,
    String base,
  ) {
    return 'Các commit sau $boundary sẽ được áp dụng lại lên $base; bản thân commit ranh giới không được bao gồm.';
  }

  @override
  String get gitUiRoot => 'Gốc';

  @override
  String get gitUiGitBranchLabelResetMergeStructure =>
      'Cấu trúc chi nhánh/ Nhãn/reset/merge';

  @override
  String get gitUiChooseAnExplicitOldBoundaryOrRootModeThenPrepare =>
      'Chọn một giới hạn cũ rõ ràng hoặc chế độ gốc, sau đó chuẩn bị kế hoạch.';

  @override
  String get gitUiMoveUp => 'Chuyển lên';

  @override
  String get gitUiMoveDown => 'Chuyển xuống';

  @override
  String get gitUiResetPlan => 'Đặt lại kế hoạch';

  @override
  String gitUiBranchBlockArg02(String arg0) {
    return ' · 12 khu chi nhánh $arg0';
  }

  @override
  String get gitUiSelectACommitForDetailsAndChangedFiles =>
      'Chọn một cam kết để tìm chi tiết và thay đổi tập tin';

  @override
  String get gitUiPreviewCombinedCommitMessages =>
      'Xem thử tổng hợp gửi tin nhắn...';

  @override
  String get gitUiAltMovesTheSelectedCommitUnrelatedBranchReferencesWillNot =>
      'Alt+At/ cấu hình di chuyển các cam kết đã chọn. Những tham khảo chi nhánh không liên quan sẽ không được cập nhật tự động.';

  @override
  String get gitUiCancelPlan => 'Hủy kế hoạch';

  @override
  String get gitUiStartReviewedRebase => 'Bắt đầu đổi gốc đã xem lại?';

  @override
  String gitUiRewriteArg0PlannedCommitsOnArg1DroppedCommitsRemainVisibly(
    String arg0,
    String arg1,
  ) {
    return 'Viết lại kế hoạch $arg0 thực hiện trên $arg1. rơi xuống các cam kết vẫn còn được đánh dấu trong kế hoạch này cho đến khi bạn bắt đầu.';
  }

  @override
  String get gitUiStartRebase => 'Bắt đầu đổi gốc';

  @override
  String get gitUiNoContinuingGitOperation => 'Không tiếp tục thao tác Git';

  @override
  String get gitUiStoppedForEditingAmend => ' · dừng lại để biên tập/amend';

  @override
  String get gitUiTheseAreUnmergedIndexEntriesPossiblyFromAStashApplication =>
      'Đây là mục nhập chỉ mục chưa được sửa đổi, có thể từ ứng dụng ẩn. Git không có lệnh cất giữ hay hủy bỏ.';

  @override
  String get gitUiEditTheWorkingFilesStageAndAmendTheCurrentCommit =>
      'Sửa chữa các tập tin hoạt động, sân khấu và sửa đổi các cam kết hiện thời, sau đó tiếp tục cơ sở hạ tầng này.';

  @override
  String gitUiArg0Arg1UnmergedStagesArg2(
    String arg0,
    String arg1,
    String arg2,
  ) {
    return '$arg0$arg1 · các giai đoạn chỉ mục chưa hợp nhất $arg2';
  }

  @override
  String get gitUiTheIndexHasNoUnresolvedEntries =>
      'Chỉ mục này không có mục nhập chưa được giải quyết.';

  @override
  String get gitUiKeepTheCurrentCommitAsAnEmptyCommit =>
      'Giữ tác vụ hiện thời là một nhiệm vụ trống';

  @override
  String get gitUiTheRealIndexHasNoStagedChangesCreateAnExplicit =>
      'Chỉ mục thật không có thay đổi sắp xếp. Tạo một cam kết trống rõ ràng, sau đó tiếp tục trình sắp xếp lại nếu nó còn hoạt động.';

  @override
  String get gitUiKeepEmptyCommit => 'Giữ nguyên sự cam kết rỗng...';

  @override
  String get gitUiGitWillTryToReturnToTheOperationSStarting =>
      'Git sẽ cố trở về điểm bắt đầu thao tác. Không bảo đảm khôi phục nội dung vốn có chưa đưa vào chỉ mục, chưa được theo dõi hoặc chưa được lưu.';

  @override
  String get gitUiSkipTheCurrentCommitAndContinueWithTheNextPlanned =>
      'Bỏ qua cam kết hiện thời và tiếp tục với kế hoạch tiếp theo.';

  @override
  String
  get gitUiForgetThisOperationSBookkeepingWhileRetainingTheCurrentFiles =>
      'Hãy quên việc ghi sổ trong khi lưu các tập tin và chỉ mục hiện thời.';

  @override
  String gitUiContinueArg0(String arg0) {
    return 'Tiếp tục $arg0';
  }

  @override
  String get gitUiReloadConflictVersions => 'Nạp lại phiên bản xung đột?';

  @override
  String get gitUiReplaceTheUnsavedResultDraftWithTheCurrentWorkingFile =>
      'Thay thế bản nháp kết quả chưa lưu bằng tập tin hoạt động hiện thời. Vẫn còn lưu nội dung hoạt động.';

  @override
  String get gitUiLoadingConflictVersions => 'Đang tải phiên bản xung đột...';

  @override
  String get gitUiLoadingConflict => 'Đang nạp xung đột';

  @override
  String get gitUiBaseLeft => 'Cơ sở dữ liệu';

  @override
  String get gitUiBaseRight => 'Cơ sở dữ liệu';

  @override
  String get gitUiNoBaseEntryForThisConflict =>
      'Không có mục nhập cơ bản cho xung đột này';

  @override
  String get gitUiAcceptEntireLeftFile =>
      'Chấp nhận toàn bộ tập tin bên trái...';

  @override
  String get gitUiAcceptEntireRightFile => 'Chấp nhận toàn bộ tệp bên phải…';

  @override
  String get gitUiPreviousConflictRegion => 'Vùng xung đột trước';

  @override
  String get gitUiNextConflictRegion => 'Vùng xung đột tiếp theo';

  @override
  String get gitUiManualResolution => 'Độ phân giải thủ công';

  @override
  String gitUiRegionArg0Arg1Arg2Reviewed(
    String arg0,
    String arg1,
    String arg2,
  ) {
    return 'Khu vực $arg0/$arg1 · $arg2 đã xem xét';
  }

  @override
  String
  get gitUiSourceAlignmentExceededTheTextComparisonLimitSourcePanesRemain =>
      'Việc sắp xếp các nguồn vượt quá giới hạn so sánh văn bản; vẫn còn sẵn sàng cho việc ôn lại bằng tay.';

  @override
  String get gitUiAcceptLeftRegion => 'Chấp nhận vùng bên trái';

  @override
  String get gitUiAcceptRightRegion => 'Chấp nhận vùng bên phải';

  @override
  String get gitUiKeepManualResultForRegion => 'Giữ kết quả thủ công cho vùng';

  @override
  String get gitUiApplyGitSNonConflictingChanges =>
      'Áp dụng thay đổi không gây hấn của Giut?';

  @override
  String get gitUiReplaceTheCurrentResultDraftWithGitSMergePreview =>
      'Thay thế bản nháp kết quả hiện thời bằng ô xem thử hợp nhất của Git. Bỏ đi việc bỏ đi những hiệu quả sửa đổi bằng tay chưa lưu; tập tin làm việc không thay đổi cho đến khi lưu.';

  @override
  String get gitUiUseMergePreview => 'Dùng ô xem thử trộn';

  @override
  String get gitUiApplyNonConflictingChanges =>
      'Áp dụng thay đổi không gây nhiễu...';

  @override
  String get gitUiLeftSource => 'Nguồn trái';

  @override
  String get gitUiResult => 'Kết quả';

  @override
  String get gitUiRightSource => 'Nguồn phải';

  @override
  String get gitUiStage2 => 'Giai đoạn 2';

  @override
  String get gitUiStage3 => 'Giai đoạn 3';

  @override
  String
  get gitUiConflictVersionsAreUnavailableRefreshToReviewTheirCurrentState =>
      'Không có phiên bản xung đột. Hãy ôn lại tình trạng hiện thời của chúng.';

  @override
  String get gitUiResultSavedToDiskTheIndexStillDeterminesWhetherThis =>
      'Kết quả được lưu vào đĩa. Chỉ mục vẫn quyết định tập tin này có được giải quyết hay không.';

  @override
  String get gitUiSaveResultDraft => 'Lưu bản nháp kết quả';

  @override
  String get gitUiApplyResultAndStageResolution =>
      'Áp dụng kết quả và đưa cách giải quyết vào chỉ mục';

  @override
  String get gitUiResultEditableUTF8WorkingContent =>
      'Kết quả là UTF- 8 có khả năng sửa đổi nội dung hoạt động';

  @override
  String get gitUiEditableConflictResult => 'Kết quả xung đột có thể sửa';

  @override
  String gitUiLeftArg0Arg1RightArg2Arg3(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return 'Trái: $arg0 · $arg1\nPhải: $arg2 · $arg3';
  }

  @override
  String get gitUiChooseContentDeletionOrASubmoduleCommitExplicitlyNoBinary =>
      'Chọn nội dung, xoá, hoặc một tiểu cầu rõ ràng. Không có dữ liệu nhị phân được giải mã như văn bản có thể sửa đổi.';

  @override
  String get gitUiUseEntireLeftContent => 'Dùng toàn bộ nội dung bên trái...';

  @override
  String get gitUiUseEntireRightContent => 'Dùng toàn bộ nội dung bên phải…';

  @override
  String get gitUiDeleteThisPath => 'Xoá đường này...';

  @override
  String get gitUiResolvedSubmoduleCommit =>
      'Đã giải quyết tiểu cầu đã cam kết';

  @override
  String get gitUiStageThisExactGitlinkInTheParentThisDoesNot =>
      'Giai đoạn này chính xác trong cha. Không kiểm tra hay thực hiện tiểu cầu.';

  @override
  String get gitUiSetResolvedGitlink => 'Đặt liên kết gitlink đã giải quyết...';

  @override
  String gitUiBaseStageArg0(String arg0) {
    return 'Cơ sở dữ liệu $arg0';
  }

  @override
  String get gitUiTheResultWasEditedKeepTheManualResultOrSelect =>
      'Kết quả đã được biên soạn. Giữ kết quả thủ công hoặc chọn vùng không thay đổi khác.';

  @override
  String gitUiApplyArg0Resolution(String arg0) {
    return 'Áp dụng cách giải quyết “$arg0”?';
  }

  @override
  String get gitUiStageTheChosenGitlinkCommitInTheParentTheSubmodule =>
      'Giai đoạn mà gitlink đã chọn cam kết trong cha. Việc kiểm tra tiểu cầu và tập tin của nó chưa được thay thế.';

  @override
  String gitUiReplacesTheEntireWorkingPathArg0AndStagesTheDecision(
    String arg0,
  ) {
    return 'Thay thế toàn bộ con đường làm việc $arg0 và đưa ra quyết định. nội dung làm việc hiện tại và kết quả chưa được lưu sẽ bị hủy bỏ.';
  }

  @override
  String get gitUiApplyEntireFileDecision =>
      'Áp dụng toàn bộ quyết định tập tin';

  @override
  String get gitUiStageThisConflictResolution =>
      'Giai đoạn giải quyết xung đột này?';

  @override
  String gitUiUseTheEntireEditedResultAsArg0GitRecordsThe(
    String arg0,
    String arg1,
  ) {
    return 'Sử dụng toàn bộ kết quả biên tập là $arg0. Git ghi lại đường dẫn đã được giải quyết khi nó được thiết lập. ôn lại tất cả nội dung đã định trước đầu tiên.$arg1';
  }

  @override
  String get gitUiApplyAndStage => 'Áp dụng và đưa vào chỉ mục';

  @override
  String get gitUiReviewResultTextFormatChanges =>
      'Xem lại định dạng văn bản thay đổi';

  @override
  String get gitUiSaveReviewedResult => 'Lưu kết quả đã xem xét';

  @override
  String
  get gitUiNativeGitTableAccessibilityIsUnavailableRetryAfterReconnectingThe =>
      'Không có khả năng truy cập bảng bản địa. Hãy thử lại sau khi kết nối lại ứng dụng.';

  @override
  String get gitUiSans => 'Sans';

  @override
  String get gitUiSelect => 'Chọn';

  @override
  String get gitUiContextMenu => 'Trình đơn ngữ cảnh';

  @override
  String get gitUiCopyText => 'Chép đoạn';

  @override
  String get gitUiLoadingRow => 'Đang nạp hàng';

  @override
  String get gitUiRetry => 'Thử lại';

  @override
  String get gitUiGitMessage => 'Thông điệp Git';

  @override
  String get gitUiCancelPrompt => 'Thôi nhắc';

  @override
  String get gitUiUseMessageAndContinue => 'Dùng thông điệp và tiếp tục';

  @override
  String get gitUiRespondPrivately => 'Trả lời riêng đi.';

  @override
  String gitUiViewPreferencesCouldNotBeSavedArg0(String arg0) {
    return 'Không thể lưu sự ưu tiên xem: $arg0';
  }

  @override
  String gitUiCommitDraftStorageArg0(String arg0) {
    return 'Ghi nhớ bản nháp: $arg0';
  }

  @override
  String gitUiViewPreferencesCouldNotBeReadArg0(String arg0) {
    return 'Không thể đọc được sự ưu tiên xem: $arg0';
  }

  @override
  String gitUiCommitDraftWasRetainedInMemoryButCouldNotBe(String arg0) {
    return 'Bản nháp cam kết đã được duy trì trong bộ nhớ nhưng không thể lưu: $arg0';
  }

  @override
  String get gitUiTheReviewedRepositoryIsReadOnlyForThisOperationHistory =>
      'Kho được duyệt chỉ được đọc trong thao tác này. Lịch sử và kiểm tra nội dung vẫn còn tồn tại.';

  @override
  String gitUiGitReturnedArg0TheApplicationCouldNotRefreshItsDocuments(
    String arg0,
    String arg1,
  ) {
    return 'Git trả lại $arg0. Ứng dụng này không thể phục hồi tài liệu: $arg1';
  }

  @override
  String get gitUiSelectCommitInLog => 'Chọn commit trong lịch sử…';

  @override
  String get gitUiCurrentBranch => 'Nhánh hiện tại';

  @override
  String get gitUiNoMatchingBranchesOrTagsSelectACommitInLog =>
      'Không có chi nhánh hay thẻ tương ứng. Hãy chọn sự ghi lưu.';

  @override
  String get gitUiBranches => 'Nhánh';

  @override
  String get gitUiPushCommits => 'Đẩy các commit';

  @override
  String gitUiPullIntoArg0(String arg0) {
    return 'Kéo vào $arg0';
  }

  @override
  String gitUiResolveArg0(String arg0) {
    return 'Giải quyết $arg0';
  }

  @override
  String get gitUiCurrentOperation => 'Thao tác hiện thời';

  @override
  String get gitUiRebaseCommits => 'Đổi gốc các commit';

  @override
  String get gitUiFetch2 => 'Tải về…';

  @override
  String get gitUiPull => 'Kéo về…';

  @override
  String get gitUiPush2 => 'Đẩy lên…';

  @override
  String get gitUiBranches2 => 'Nhánh…';

  @override
  String get gitUiManageRemotes => 'Quản lý kho từ xa…';

  @override
  String gitUiMergeIntoArg0(String arg0) {
    return 'Nhập vào $arg0...';
  }

  @override
  String get gitUiRebase2 => 'Đổi gốc…';

  @override
  String get gitUiConflictsAndCurrentOperation =>
      'Xung đột và thao tác hiện thời...';

  @override
  String get gitUiStashes2 => 'Các bản cất tạm…';

  @override
  String get gitUiWorktrees => 'Các cây làm việc…';

  @override
  String get gitUiSubmodules => 'Mô-đun con…';

  @override
  String get gitUiReflogAndRecovery => 'Reflog và khôi phục…';

  @override
  String get gitUiCloneRepository => 'Nhân bản kho lưu trữ…';

  @override
  String get gitUiRevokeRepositoryTrust => 'Thu hồi sự tin cậy đối với kho';

  @override
  String get gitUiWaitingForRepositoryStatus =>
      'Đang chờ trạng thái kho phần mềm';

  @override
  String get gitUiRepositoryStatusUnavailableRefresh =>
      'Không thể lưu cục bộ; cập nhật';

  @override
  String get gitUiManageRemotes2 => 'Quản lý kho từ xa';

  @override
  String gitUiMergeIntoArg02(String arg0) {
    return 'Nhập vào $arg0';
  }

  @override
  String get gitUiWorktrees2 => 'Các cây làm việc';

  @override
  String get gitUiSubmodules2 => 'Mô-đun con';

  @override
  String get gitUiReflogAndRecovery2 => 'Reflog và khôi phục';

  @override
  String gitUiCloneRepositoryArg0(String arg0) {
    return 'Kho lưu trữ 3$arg0';
  }

  @override
  String get gitUiApply => 'Áp dụng';

  @override
  String get gitUiResizeGitPanes => 'Đổi cỡ ô Git';

  @override
  String gitUiArg0Percent(String arg0) {
    return '$arg0%';
  }

  @override
  String gitUiExitStatusStatus(String status) {
    return 'Trạng thái thoát: $status';
  }

  @override
  String get gitUiRepositoryChangedRefreshAndReviewBeforeTryingAgain =>
      'Thư mục đã thay đổi. Cập nhật và xem lại trước khi thử lại.';

  @override
  String get gitUiAnotherOperationHoldsTheRepositoryOrIndexLockWaitThen =>
      'Một thao tác khác giữ kho phần mềm hoặc khóa chỉ mục. Đợi, sau đó cập nhật lại.';

  @override
  String get gitUiRepositoryTrustIsRequiredForThisOperation =>
      'Cần thiết sự tin tưởng cục bộ cho chiến dịch này.';

  @override
  String get gitUiTheGitServiceDisconnectedReconnectAndReconcileTheRepository =>
      'Dịch vụ Git đã ngắt kết nối và dung hòa kho lưu.';

  @override
  String
  get gitUiTheInstalledGitExecutableCannotSupportThisOperationReviewIts =>
      'Tập tin thực hiện được Git không thể hỗ trợ thao tác này. Xem lại yêu cầu thời gian chạy bên dưới.';

  @override
  String get gitUiThisRepositoryIsReadOnlyForTheRequestedOperationReview =>
      'Kho phần mềm này chỉ được đọc cho thao tác đã yêu cầu. Xem lại và lịch sử còn lại.';

  @override
  String
  get gitUiTheOperationNeedsReconciliationReviewTheResultingRepositoryOrRemote =>
      'Thao tác này cần phải hòa giải. Xem xét lại kết quả kho hoặc trạng thái từ xa trước khi lặp lại nó.';

  @override
  String get gitUiGitAuthenticationFailedReviewTheCredentialHelperOrUnlockThe =>
      'Việc xác thực Git bị lỗi. Xem lại trình trợ giúp nhận diện hay bỏ khoá đã cấu hình.';

  @override
  String get gitUiSshHostVerificationFailedReviewTheHostIdentityThroughYour =>
      'Việc kiểm tra tên máy SSH bị lỗi. Hãy kiểm tra lại tên máy qua các công cụ của bạn đã cấu hình.';

  @override
  String get gitUiCommitSigningFailedOrWasCancelledReviewTheSigningKey =>
      'Việc ký cam kết bị lỗi hoặc bị thôi. Xem lại phím ký, tác vụ và công cụ đã cấu hình.';

  @override
  String get gitUiSetARepositoryAuthorNameAndEmailThenReturnTo =>
      'Đặt tên tác giả và thư điện tử kho phần mềm, rồi trở lại bản nháp thông điệp đã lưu.';

  @override
  String get gitUiGitRejectedTheReviewedUpdateRefreshAndReviewTheActual =>
      'Git từ chối cập nhật đã duyệt. Cập nhật và xem lại đích thật trước khi thử lại.';

  @override
  String get gitUiWorkingOrStagedChangesPreventThisOperationReviewCommitOr =>
      'Những thay đổi làm việc hoặc sắp xếp để ngăn chặn hoạt động này. Xem lại, cam kết hoặc giấu chúng đi.';

  @override
  String get gitUiARequiredGitObjectIsUnavailableReviewShallowOrPartial =>
      'Một đối tượng Git cần thiết không sẵn sàng. Xem lại các ranh giới nông hoặc một phần của nó và lấy ra rõ ràng nếu cần thiết.';

  @override
  String gitUiGitOperationFailedArg0(String arg0) {
    return 'Thao tác Git thất bại: $arg0';
  }

  @override
  String get gitUiDiagnostics => 'Chẩn đoán';

  @override
  String get gitUiAuthorizeGitInspection => 'Cho phép kiểm tra Git...';

  @override
  String get gitUiCopyDiagnostics => 'Chép chẩn đoán';

  @override
  String get gitUiActions => 'Thao tác';

  @override
  String gitUiBranchAtArg0(String arg0) {
    return 'Chi nhánh tại $arg0';
  }

  @override
  String get gitUiCreatesALocalBranchWithoutCheckingItOut =>
      'Tạo ra một chi nhánh địa phương mà không cần kiểm tra.';

  @override
  String gitUiTagArg0(String arg0) {
    return 'Thẻ $arg0';
  }

  @override
  String gitUiReadOnlySnapshotArg0(String arg0) {
    return 'Chỉ đọc hình chụp e· $arg0';
  }

  @override
  String get gitUiCherryPickCommits => 'Áp dụng các commit bằng cherry-pick';

  @override
  String get gitUiRevertCommits => 'Hoàn nguyên';

  @override
  String get gitUiCompareToFullRevisionID => 'So sánh với ID sửa đổi đầy đủ';

  @override
  String gitUiTreeComparisonDirectionArg0TheRevisionEnteredHere(String arg0) {
    return 'Hướng so sánh cây: $arg0 _BAR_ mà bản hiệu đính đã nhập vào đây.';
  }

  @override
  String get gitUiEnterAFullValidObjectID =>
      'Nhập một ID đối tượng hợp lệ đầy đủ.';

  @override
  String gitUiArg0Arg1TreeComparison(String arg0, String arg1) {
    return '$arg0 → $arg1 · so sánh cây';
  }

  @override
  String gitUiResetArg0ToArg1(String arg0, String arg1) {
    return 'Đặt lại $arg0 để $arg1';
  }

  @override
  String
  get gitUiMovesHEADCurrentBranchReflogDoesNotRecoverArbitraryUntracked =>
      'Di chuyển HEAD/nhánh hiện tại. Reflog không phục hồi mọi nội dung chưa được theo dõi hoặc chưa lưu.';

  @override
  String get gitUiMoveHEADKeepIndexAndWorkingFiles =>
      'Di chuyển HEAD; giữ nguyên chỉ mục và tệp làm việc.';

  @override
  String get gitUiMoveHEADAndReplaceIndexKeepWorkingFiles =>
      'Di chuyển HEAD và thay chỉ mục; giữ nguyên tệp làm việc.';

  @override
  String
  get gitUiReplaceHEADIndexAndTrackedWorkingFilesMayOverwriteObstructing =>
      'Thay HEAD, chỉ mục và tệp làm việc được theo dõi; có thể ghi đè các tệp chưa được theo dõi đang cản trở.';

  @override
  String get gitUiReplaceHEADIndexAndEligibleFilesRefuseIfLocalChanges =>
      'Thay HEAD, chỉ mục và tệp phù hợp; từ chối nếu sẽ làm mất thay đổi cục bộ.';

  @override
  String gitUiResetWithArg0(String arg0) {
    return 'Đặt lại với $arg0?';
  }

  @override
  String gitUiArg0Arg1ReviewTheSelectedModeSEffectsBeforeApplying(
    String arg0,
    String arg1,
  ) {
    return '$arg0 _ $arg1 ôn lại các hiệu ứng của chế độ đã chọn trước khi áp dụng.';
  }

  @override
  String gitUiResetArg0(String arg0) {
    return 'Đặt lại $arg0';
  }

  @override
  String gitUiTargetArg0(String arg0) {
    return 'Mục tiêu $arg0';
  }

  @override
  String get gitUiTagName => 'Tên thẻ';

  @override
  String get gitUiAnnotatedTag => 'Thẻ có chú thích';

  @override
  String get gitUiCryptographicSigning => 'Ký mật mã';

  @override
  String get gitUiConfiguredPolicy => 'Chính sách đã cấu hình';

  @override
  String get gitUiSignThisTag => 'Ký vào thẻ này';

  @override
  String get gitUiDoNotSign => 'Đừng ký tên';

  @override
  String get gitUiTagMessage => 'Tin nhắn thẻ';

  @override
  String get gitUiCreatesTheTagLocallyPublishSelectedTagsExplicitlyInPush =>
      'Tạo thẻ cục bộ. Xuất bản các thẻ đã chọn một cách rõ ràng trong việc duyệt.';

  @override
  String gitUiCompleteTreesArg0Arg1(String arg0, String arg1) {
    return 'Cây hoàn chỉnh: $arg0 $arg1';
  }

  @override
  String get gitUiNextChangedFilePage => 'Trang đã thay đổi kế';

  @override
  String get gitUiReadOnlyRepositorySnapshotOpeningAFileNeverChecksOut =>
      'Ảnh chụp kho chứa chỉ đọc. Mở tập tin không bao giờ kiểm tra bản sửa đổi này.';

  @override
  String get gitUiOpenReadOnlyVersion => 'Mở phiên bản chỉ đọc';

  @override
  String get gitUiRestoreThisPathWaitingForRepositoryStatus =>
      'Phục hồi đường dẫn này... v. chờ trạng thái kho lưu';

  @override
  String get gitUiRestoreThisPath => 'Phục hồi đường này...';

  @override
  String gitUiHistoryArg0(String arg0) {
    return 'Lịch sử · $arg0';
  }

  @override
  String gitUiRestoreArg0(String arg0) {
    return 'Phục hồi $arg0?';
  }

  @override
  String gitUiReplaceThisWorkingPathWithRevisionArg0ExistingStagedContent(
    String arg0,
  ) {
    return 'Thay thế đường dẫn làm việc này bằng việc sửa đổi $arg0. Đang chạy lại nội dung đã cài đặt.';
  }

  @override
  String get gitUiRestoreWorkingFile => 'Phục hồi tập tin làm việc';

  @override
  String gitUiFileHistoryFollowsRenamesArg0(String arg0) {
    return 'Lịch sử tập tin theo sau thay đổi tên của e· $arg0';
  }

  @override
  String get gitUiBlameCommittedContent =>
      'Tác giả từng dòng · nội dung đã commit';

  @override
  String get gitUiBlame => 'Tác giả từng dòng…';

  @override
  String gitUiArg0WorkingTree(String arg0) {
    return 'Cây làm việc $arg0';
  }

  @override
  String get gitUiOpenReadOnlyHistoricalFile => 'Mở tập tin lịch sử chỉ đọc';

  @override
  String get gitUiCompareToCurrentFile => 'So sánh với tập tin hiện thời';

  @override
  String get gitUiCompareToParent => 'So sánh với phụ huynh...';

  @override
  String gitUiCommittedArg0UnsavedEditorContentIsNotPartOfThese(String arg0) {
    return 'Đã cam kết $arg0 e· chưa lưu nội dung trình soạn thảo không phải là một phần của những chú thích này';
  }

  @override
  String gitUiHistoryFromArg0(String arg0) {
    return 'Lịch sử từ $arg0';
  }

  @override
  String get gitUiBoundary => ' · giới hạn ·';

  @override
  String gitUiArg0Arg1OriginalLineArg2Arg3(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return '$arg0  $arg1\nDòng gốc $arg2$arg3';
  }

  @override
  String get gitUiPreviousLines => 'Đường lùi';

  @override
  String get gitUiNextLines => 'Dòng kế';

  @override
  String gitUiExplicitApplicationOrderDestinationArg0(String arg0) {
    return 'Thứ tự · đích $arg0';
  }

  @override
  String get gitUiAddFullCommitObjectID => 'Thêm chứng minh đối tượng đầy đủ';

  @override
  String get gitUiAddReviewedCommit => 'Thêm mục nhập ôn lại...';

  @override
  String get gitUiMoveEarlier => 'Tránh ra';

  @override
  String get gitUiMoveLater => 'Di chuyển sau';

  @override
  String get gitUiRemoveFromReviewedSequence => 'Gỡ bỏ khỏi chuỗi đã duyệt';

  @override
  String get gitUiApplyChangesWithoutCreatingCommits =>
      'Áp dụng các thay đổi mà không tạo ra mật khẩu';

  @override
  String get gitUiUseThisExplicitMainlineParentForMergeCommits =>
      'Sử dụng cha chính rõ ràng này để hợp nhất cam kết';

  @override
  String get gitUiEmptyOrAlreadyAppliedCommitsMayStopGitForAn =>
      'Những cam kết rỗng hoặc đã được áp dụng có thể ngăn cản Git để một quyết định nhảy qua hay tiếp tục tiếp tục.';

  @override
  String get gitUiRevertInReviewedOrder => 'Hoàn nguyên theo thứ tự ôn lại';

  @override
  String get gitUiCherryPickInReviewedOrder => 'Chọn qua một bên';

  @override
  String get gitUiReturnToFiles => 'Trở về tập tin';

  @override
  String get gitUiGit => 'Git';

  @override
  String get gitUiCommit => 'Tạo commit';

  @override
  String get gitUiBackToCommit => 'Trở lại bản cam kết';

  @override
  String get gitUiSelectAChangeToReview => 'Chọn một thay đổi cần xem xét';

  @override
  String get gitUiLoadingBranch => 'Đang nạp chi nhánh...';

  @override
  String get gitUiBranchUnavailable => 'Chi nhánh không sẵn sàng';

  @override
  String get gitUiUnbornHEAD => 'HEAD chưa có commit';

  @override
  String gitUiDetachedHEADRevision(String revision) {
    return 'HEAD tách rời · $revision';
  }

  @override
  String get gitUiContinueAction => 'Tiếp tục';

  @override
  String get gitUiPick => 'Giữ';

  @override
  String get gitUiReword => 'Sửa thông điệp';

  @override
  String get gitUiEdit => 'Chỉnh sửa';

  @override
  String get gitUiSquash => 'Gộp commit';

  @override
  String get gitUiFixup => 'Gộp bỏ thông điệp';

  @override
  String get gitUiDrop => 'Loại bỏ';

  @override
  String get gitUiAbort => 'Hủy thao tác';

  @override
  String get gitUiSkip => 'Bỏ qua';

  @override
  String get gitUiQuit => 'Thao tác Thoát';

  @override
  String get gitUiSoft => 'Mềm';

  @override
  String get gitUiMixed => 'Hỗn hợp';

  @override
  String get gitUiHard => 'Cứng';

  @override
  String get gitUiKeep => 'Giữ';

  @override
  String get gitUiCreate => 'Tạo';

  @override
  String get gitUiApplyStash => 'Áp dụng bản cất tạm';

  @override
  String get gitUiPopStash => 'Áp dụng và xóa bản cất tạm nếu thành công';

  @override
  String get gitUiDropStashAction => 'Xóa bản cất tạm';

  @override
  String get gitUiEditedResult => 'Đã sửa kết quả';

  @override
  String get gitUiLeftContent => 'Nội dung trái';

  @override
  String get gitUiRightContent => 'Nội dung phải';

  @override
  String get gitUiDeletePath => 'Xoá đường';

  @override
  String get gitUiSubmoduleCommit => 'Conmodule cam kết';

  @override
  String get gitUiPresentContent => 'Nội dung sẵn sàng';

  @override
  String get gitUiAbsentContent => 'Không có';

  @override
  String get gitUiBinaryContent => 'Nội dung nhị phân';

  @override
  String get gitUiTooLargeContent => 'Nội dung vượt quá giới hạn hiển thị';

  @override
  String get gitUiUnavailableContent => 'Nội dung không sẵn sàng';

  @override
  String get gitUiGitlinkContent => 'Con trỏ con';

  @override
  String get gitUiSymlinkContent => 'Liên kết tượng trưng';

  @override
  String get gitUiNoOperation => 'Không có thao tác';

  @override
  String get gitUiCherryPickOperation => 'Chọn áp dụng commit';

  @override
  String get gitUiRevertOperation => 'Hoàn tác bằng commit';

  @override
  String get gitUiApplyMailboxOperation => 'Áp dụng đắp vá';

  @override
  String get gitUiSquashOperation => 'Hợp nhất Squash';

  @override
  String get gitUiUnmergedOperation => 'Chỉ mục chưa được xác định';

  @override
  String get gitUiWaitingForPromptPhase => 'Đang chờ câu trả lời của bạn';

  @override
  String get gitUiStoppedPhase => 'Bị dừng lại để xem xét';

  @override
  String get gitUiCompletedPhase => 'Hoàn tất';

  @override
  String get gitUiFailedPhase => 'Thất bại';

  @override
  String get gitUiCancelledPhase => 'Đã hủy';

  @override
  String get gitUiUncertainPhase => 'Sinh ra đòi hỏi phải hòa giải.';

  @override
  String gitUiStageVersion(String stage) {
    return 'Xung đột giai đoạn $stage';
  }

  @override
  String get gitUiGitMergePreview => 'Xem thử hợp nhất Git';

  @override
  String get gitUiNormalizedWorking =>
      'Làm việc với cây_ cập · Git bình thường';

  @override
  String gitUiPercentValue(String value) {
    return '$value%';
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
  String get gitUiUtf8Bom => 'UTF- 8 với dấu xếp theo thứ tự (BOM)';

  @override
  String get gitUiUtf8NoBom => 'UTF- 8 mà không có dấu xếp theo thứ tự (BOM)';

  @override
  String get gitUiAddsBom =>
      'Bộ sửa đổi thêm một dấu hiệu UTF- thứ tự (BOM) ở đầu tập tin.';

  @override
  String get gitUiRemovesBom =>
      'Bộ sửa đổi này gỡ bỏ đánh dấu UTF- theo thứ tự (BOM) từ đầu tập tin.';

  @override
  String get gitUiNoLineTerminators => 'Không có tổ hợp phím tắt';

  @override
  String gitUiLineEndings(String format) {
    return 'Kết thúc dòng $format';
  }

  @override
  String gitUiMixedLineEndings(String formats) {
    return 'Kết thúc dòng trộn ($formats)';
  }

  @override
  String gitUiNoFinalLf(String format) {
    return '$format · không có LF cuối cùng';
  }

  @override
  String gitUiLineEndingChange(String before, String after) {
    return 'Định dạng kết thúc dòng đổi từ $before sang $after. Văn bản trong bảng nhớ tạm có thể có kiểu kết thúc dòng khác với tệp gốc.';
  }

  @override
  String get gitUiGitFailure =>
      'Thao tác Git thất bại. Xem lại các chẩn đoán bên dưới.';

  @override
  String get gitUiAbortInline => 'Hủy thao tác';

  @override
  String get gitUiSkipInline => 'Bỏ qua';

  @override
  String get gitUiQuitInline => 'Thoát';

  @override
  String get gitUiMergeInline => 'Hợp nhất';

  @override
  String get gitUiRebaseInline => 'Đổi gốc';

  @override
  String get gitUiCherryPickInline => 'Chọn áp dụng commit';

  @override
  String get gitUiRevertInline => 'Hoàn tác bằng commit';

  @override
  String get gitUiApplyMailboxInline => 'áp dụngMailbox';

  @override
  String get gitUiSquashInline => 'Gộp commit';

  @override
  String get gitUiUnmergedInline => 'chưa kết nối';

  @override
  String get gitHostFetch => 'Tải về';

  @override
  String get gitHostRefreshGitStatus => 'Cập nhật trạng thái Git';

  @override
  String get gitHostCommitStaged => 'Nhấn để thêm chú thích...';

  @override
  String get gitHostGitBranches => 'Các nhánh Git';

  @override
  String get gitHostReviewPush => 'Đẩy lại';

  @override
  String get gitHostGit => 'Git';

  @override
  String get gitHostGitOperationsApplyToThisEntireRepositoryAndMay =>
      'Các thao tác Git áp dụng cho toàn bộ kho này và có thể thực hiện các móc đã cấu hình, bộ lọc, văn bản và các công cụ ký hiệu.';

  @override
  String get gitHostContentUnavailable => 'Nội dung không sẵn sàng';

  @override
  String get gitHostInitializeRepository => 'Khởi tạo kho';

  @override
  String get gitHostCloneRepository => 'Nhân bản kho lưu trữ';

  @override
  String get gitHostInitializeHere => 'Bắt đầu từ đây...';

  @override
  String get gitHostCloneRepository2 => 'Nhân bản kho lưu trữ…';

  @override
  String get gitHostGitLog => 'Bản ghi Git';

  @override
  String get gitUiAbsentPlaceholder => '(Tiếng súng)';

  @override
  String get gitUiUnborn => 'Chưa sinh';

  @override
  String gitUiRebasedHistoryRevision(String revision) {
    return 'Lịch sử đã đổi gốc · $revision';
  }

  @override
  String gitUiCurrentHistoryRevision(String revision) {
    return 'Lịch sử hiện tại · $revision';
  }

  @override
  String gitUiReplayedCommitRevision(String revision) {
    return 'Commit được áp dụng lại · $revision';
  }

  @override
  String gitUiIncomingContentRevision(String revision) {
    return 'Nội dung đến · $revision';
  }

  @override
  String get gitUiContentConflict => 'Xung đột nội dung';

  @override
  String get gitUiSubmoduleConflict => 'Xung đột tiểu cầu';

  @override
  String get gitUiSymlinkConflict => 'Xung đột liên kết tượng trưng';

  @override
  String get gitUiAddAddConflict => 'Đã thêm vào cả hai bên';

  @override
  String get gitUiModifyDeleteConflict =>
      'Sửa đổi/ tắt đã thay đổi hoặc bị tắt';

  @override
  String gitUiConflictIdentity(String path, String kind) {
    return '$path · $kind';
  }
}
