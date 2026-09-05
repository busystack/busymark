// ignore_for_file: text_direction_code_point_in_literal, text_direction_code_point_in_comment

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'BusyMark';

  @override
  String get appSubtitle =>
      'Editor untuk file Markdown dan proyek dokumentasi yang kompatibel dengan Writerside.';

  @override
  String get aboutBusyMark => 'Tentang BusyMark';

  @override
  String get aboutTagline =>
      'Editor untuk file Markdown dan proyek dokumentasi yang kompatibel dengan Writerside';

  @override
  String get aboutLicenseLabel => 'Lisensi';

  @override
  String get aboutLicenseName => 'Apache License 2.0';

  @override
  String get aboutWebsite => 'Situs web';

  @override
  String get aboutSourceCode => 'Kode sumber';

  @override
  String get reportIssue => 'Laporkan masalah';

  @override
  String get feedbackCategory => 'Kategori';

  @override
  String get feedbackChooseCategory => 'Pilih kategori';

  @override
  String get feedbackCategoryProblem => 'Masalah atau bug';

  @override
  String get feedbackCategoryFeature => 'Permintaan fitur';

  @override
  String get feedbackCategoryPrivacySecurity => 'Masalah privasi atau keamanan';

  @override
  String get feedbackCategoryUsability => 'Masalah kegunaan';

  @override
  String get feedbackCategoryOther => 'Lainnya';

  @override
  String get feedbackSubject => 'Subjek';

  @override
  String get feedbackMessage => 'Pesan terperinci';

  @override
  String get feedbackReplyEmail => 'Alamat email balasan (opsional)';

  @override
  String get feedbackIncludeTechnicalDetails => 'Sertakan detail teknis';

  @override
  String get feedbackTechnicalDetailsDisclosure =>
      'Jika diaktifkan, ini hanya menambahkan versi sistem operasi Linux dan lokal aplikasi BusyMark Anda. Tidak ada log, file, data akun, atau diagnostik lainnya yang dilampirkan.';

  @override
  String get feedbackSubmit => 'Kirim';

  @override
  String get feedbackSubmitting => 'Mengirimkan…';

  @override
  String get feedbackCategoryRequired => 'Pilih kategori.';

  @override
  String get feedbackSubjectLength => 'Subjek harus antara 3 dan 120 karakter.';

  @override
  String get feedbackMessageLength =>
      'Pesan harus antara 10 dan 5.000 karakter.';

  @override
  String get feedbackReplyEmailInvalid =>
      'Masukkan alamat email yang valid atau biarkan kolom ini kosong.';

  @override
  String get feedbackConnectionFailure =>
      'BusyMark tidak dapat terhubung. Periksa koneksi internet Anda dan coba lagi.';

  @override
  String get feedbackTimeoutFailure =>
      'Waktu permintaan telah habis. Coba lagi.';

  @override
  String get feedbackRateLimitedFailure =>
      'Terlalu banyak laporan yang dikirim dari koneksi ini. Tunggu dan coba lagi.';

  @override
  String get feedbackRejectedFailure =>
      'Server menolak laporan ini. Periksa kolom formulir dan coba lagi.';

  @override
  String get feedbackServerFailure =>
      'Server tidak dapat menerima laporan tersebut. Coba lagi nanti.';

  @override
  String feedbackSuccess(String id) {
    return 'Umpan balik dikirim. ID Referensi: $id';
  }

  @override
  String get advanced => 'Lanjutan';

  @override
  String get addToGit => 'Tambahkan ke Git';

  @override
  String get appearance => 'Penampilan';

  @override
  String get apply => 'Terapkan';

  @override
  String get back => 'Kembali';

  @override
  String get bottomLeft => 'Kiri bawah';

  @override
  String get bottomRight => 'Kanan bawah';

  @override
  String get cancel => 'Batal';

  @override
  String get choose => 'Pilih';

  @override
  String get chooseLocation => 'Pilih lokasi';

  @override
  String get copy => 'Salin';

  @override
  String get copyName => 'Salin nama';

  @override
  String get copyFileName => 'Salin nama file';

  @override
  String get copyPath => 'Salin jalur';

  @override
  String get create => 'Buat';

  @override
  String get creating => 'Membuat...';

  @override
  String get cut => 'Potong';

  @override
  String get promoteSection => 'Naikkan bagian';

  @override
  String get demoteSection => 'Turunkan bagian';

  @override
  String get moveSectionUp => 'Pindahkan bagian ke atas';

  @override
  String get moveSectionDown => 'Pindahkan bagian ke bawah';

  @override
  String get confirmDeleteSectionTitle => 'Hapus bagian?';

  @override
  String confirmDeleteSectionMessage(String name) {
    return 'Hapus “$name” dan semua konten di bagiannya? Hal ini tidak dapat dibatalkan.';
  }

  @override
  String get darkTheme => 'Gelap';

  @override
  String get delete => 'Hapus';

  @override
  String get discard => 'Buang';

  @override
  String get editor => 'Editor';

  @override
  String get file => 'File';

  @override
  String get fileHistory => 'Riwayat File';

  @override
  String get folder => 'Folder';

  @override
  String get insert => 'Sisipkan';

  @override
  String get keyboardShortcuts => 'Pintasan keyboard';

  @override
  String get commandPalette => 'Palet perintah';

  @override
  String get commandPaletteHint => 'Ketikkan perintah';

  @override
  String get commandPaletteEmpty => 'Tidak ada perintah yang cocok';

  @override
  String get commandUnavailableInContext =>
      'Tidak tersedia dalam konteks editor saat ini';

  @override
  String get lightTheme => 'Terang';

  @override
  String get mainMenu => 'Menu utama';

  @override
  String get fullScreen => 'Layar penuh';

  @override
  String get markdown => 'Markdown';

  @override
  String get open => 'Buka';

  @override
  String get openInFiles => 'Buka di File';

  @override
  String get pathActions => 'Tindakan jalur';

  @override
  String get outline => 'Garis besar';

  @override
  String get overwrite => 'Timpa';

  @override
  String get paste => 'Tempel';

  @override
  String get pasteWithoutFormatting => 'Tempel tanpa memformat';

  @override
  String get reading => 'Membaca';

  @override
  String get removeFromRecent => 'Hapus dari Terbaru';

  @override
  String get recent => 'Terbaru';

  @override
  String get redo => 'Ulangi';

  @override
  String get save => 'Simpan';

  @override
  String get search => 'Cari';

  @override
  String get selectAll => 'Pilih semua';

  @override
  String get settings => 'Pengaturan';

  @override
  String get source => 'Sumber';

  @override
  String get split => 'Pisahkan';

  @override
  String get systemTheme => 'Sistem';

  @override
  String get theme => 'Tema';

  @override
  String get appLanguage => 'Bahasa';

  @override
  String get systemLanguage => 'Sistem';

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
  String get toggleSidebar => 'Panel bilah sisi';

  @override
  String get topLeft => 'Kiri atas';

  @override
  String get topRight => 'Kanan atas';

  @override
  String get undo => 'Urungkan';

  @override
  String get validate => 'Validasi';

  @override
  String get validation => 'Validasi';

  @override
  String get viewMode => 'Modus tampilan';

  @override
  String get welcome => 'Selamat datang';

  @override
  String get writerside => 'Writerside';

  @override
  String get xml => 'XML';

  @override
  String get fileTypeMarkdown => 'Markdown';

  @override
  String get fileTypeImages => 'Gambar';

  @override
  String get openMarkdownFile => 'Buka File Markdown';

  @override
  String get markdownFileExtensions => '.md atau .markdown';

  @override
  String get openFolderOrWritersideProject =>
      'Buka Folder atau Proyek Writerside';

  @override
  String get markdownFolderOrWritersideProject =>
      'Folder Markdown atau proyek yang kompatibel dengan Writerside';

  @override
  String get noOpenFile => 'Tidak ada file yang terbuka';

  @override
  String get shortcutDeleteTreeItemDescription =>
      'Hapus item File yang dipilih, atau hapus topik yang dipilih dari daftar isi';

  @override
  String get shortcutGroupGeneral => 'Umum';

  @override
  String get shortcutNewDocument => 'Buat';

  @override
  String get shortcutNewDocumentDescription =>
      'Buat file Markdown atau proyek Writerside';

  @override
  String get shortcutOpenDescription =>
      'Buka file Markdown, folder, atau proyek Writerside';

  @override
  String get shortcutSaveDescription => 'Simpan dokumen saat ini';

  @override
  String get shortcutSearchDescription => 'Cari ruang kerja saat ini';

  @override
  String get shortcutKeyboardShortcutsDescription =>
      'Tampilkan referensi pintasan keyboard ini';

  @override
  String get shortcutSyntaxReferenceDescription => 'Buka referensi sintaks';

  @override
  String get shortcutSettingsDescription => 'Buka pengaturan BusyMark';

  @override
  String get shortcutNextTab => 'Tab berikutnya';

  @override
  String get shortcutNextTabDescription => 'Pindah ke tab terbuka berikutnya';

  @override
  String get shortcutPreviousTab => 'Tab sebelumnya';

  @override
  String get shortcutPreviousTabDescription =>
      'Pindah ke tab terbuka sebelumnya';

  @override
  String get shortcutCloseTab => 'Tutup tab';

  @override
  String get shortcutCloseTabDescription => 'Tutup tab aktif';

  @override
  String get shortcutCloseAllTabs => 'Tutup semua tab';

  @override
  String get shortcutCloseAllTabsDescription => 'Tutup semua tab yang terbuka';

  @override
  String get shortcutGroupTextEditing => 'Pengeditan teks';

  @override
  String get shortcutSelectAllDescription =>
      'Dalam mode Sumber, pilih semua teks; dalam mode Editor, tekan dua kali untuk memilih setiap blok';

  @override
  String get shortcutCutDescription => 'Potong teks yang dipilih';

  @override
  String get shortcutCopyDescription => 'Salin teks yang dipilih';

  @override
  String get shortcutPasteDescription => 'Tempel dari papan klip';

  @override
  String get shortcutPastePlainTextDescription =>
      'Tempel teks papan klip tanpa memformat';

  @override
  String get shortcutUndoDescription => 'Urungkan pengeditan terakhir';

  @override
  String get shortcutRedoDescription => 'Ulangi tindakan terakhir';

  @override
  String get shortcutInsertIndentation => 'Masukkan lekukan';

  @override
  String get shortcutInsertIndentationDescription =>
      'Sisipkan lekukan pada kursor';

  @override
  String get shortcutOutdentSource => 'Kurangi inden sumber';

  @override
  String get shortcutOutdentSourceDescription =>
      'Hapus satu tingkat lekukan dalam mode Sumber';

  @override
  String get shortcutEscape => 'Tutup pencarian atau hapus pilihan blok';

  @override
  String get shortcutEscapeDescription =>
      'Tutup pencarian ruang kerja atau hapus pilihan blok dalam mode Editor';

  @override
  String get shortcutGroupFormatting => 'Pemformatan';

  @override
  String get shortcutBoldDescription =>
      'Alihkan huruf tebal pada teks yang dipilih';

  @override
  String get shortcutItalicDescription =>
      'Alihkan huruf miring pada teks yang dipilih';

  @override
  String get shortcutUnderlineDescription =>
      'Alihkan garis bawah pada teks yang dipilih';

  @override
  String get shortcutLinkDescription => 'Sisipkan atau edit tautan';

  @override
  String get shortcutInlineCodeDescription =>
      'Alihkan kode sebaris pada teks yang dipilih';

  @override
  String get shortcutStrikethroughDescription =>
      'Alihkan coretan pada teks yang dipilih';

  @override
  String get shortcutGroupBlocks => 'Blok';

  @override
  String get shortcutParagraphDescription => 'Atur blok saat ini ke paragraf';

  @override
  String get shortcutHeading1Description =>
      'Atur blok saat ini sebagai judul 1';

  @override
  String get shortcutHeading2Description =>
      'Atur blok saat ini sebagai judul 2';

  @override
  String get shortcutHeading3Description =>
      'Atur blok saat ini sebagai judul 3';

  @override
  String get shortcutHeading4Description =>
      'Atur blok saat ini sebagai judul 4';

  @override
  String get shortcutHeading5Description =>
      'Atur blok saat ini sebagai judul 5';

  @override
  String get shortcutHeading6Description =>
      'Atur blok saat ini sebagai judul 6';

  @override
  String get shortcutGroupLists => 'Daftar';

  @override
  String get numberedList => 'Daftar bernomor';

  @override
  String get shortcutNumberedListDescription =>
      'Alihkan pemformatan daftar bernomor';

  @override
  String get bulletedList => 'Daftar berpoin';

  @override
  String get shortcutBulletedListDescription =>
      'Alihkan pemformatan daftar berpoin';

  @override
  String get checklist => 'Daftar periksa';

  @override
  String get shortcutChecklistDescription =>
      'Alihkan pemformatan daftar periksa';

  @override
  String get shortcutGroupSidebar => 'Bilah samping';

  @override
  String get sidebarViewMenu => 'Tampilan bilah sisi';

  @override
  String get createMarkdownFile => 'Buat File Markdown';

  @override
  String get createMarkdownFileDescription =>
      'Mulai dokumen Markdown lokal yang belum disimpan';

  @override
  String get createWritersideProject => 'Buat Proyek Writerside';

  @override
  String get createWritersideProjectDescription =>
      'Mulai proyek lokal yang kompatibel dengan Writerside';

  @override
  String get defaultProjectName => 'Dokumentasi';

  @override
  String get defaultInstanceName => 'Panduan Pengguna';

  @override
  String get defaultStartTopicTitle => 'Memulai';

  @override
  String get projectName => 'Nama proyek';

  @override
  String get directoryName => 'Nama direktori';

  @override
  String get instanceName => 'Nama instance';

  @override
  String get instanceId => 'ID instance';

  @override
  String get startTopicTitle => 'Topik awal';

  @override
  String get location => 'Lokasi';

  @override
  String get projectNameRequired => 'Nama proyek wajib diisi.';

  @override
  String get directoryNameRequired => 'Nama direktori wajib diisi.';

  @override
  String get useSingleSafeDirectoryName => 'Gunakan satu nama direktori aman.';

  @override
  String get useLowercaseIdentifier =>
      'Gunakan pengenal huruf kecil dengan huruf, angka, garis bawah, atau tanda hubung.';

  @override
  String get startTopicTitleRequired => 'Judul topik awal wajib diisi.';

  @override
  String get createWritersideProjectFailed =>
      'Tidak dapat membuat proyek Writerside.';

  @override
  String get settingsTitle => 'Pengaturan BusyMark';

  @override
  String get autoSave => 'Simpan otomatis';

  @override
  String get autoSaveDescription =>
      'Simpan perubahan file secara otomatis setelah jeda singkat.';

  @override
  String get wordWrap => 'Pindah baris otomatis';

  @override
  String get editorFontSize => 'Ukuran font editor';

  @override
  String get validateOnEdit => 'Validasi saat mengedit';

  @override
  String get clearRecentWorkspaces => 'Hapus ruang kerja terbaru';

  @override
  String get editingButtonsPosition => 'Posisi tombol pengeditan';

  @override
  String get editingButtonsPositionDescription =>
      'Pilih di mana tombol pengeditan WYSIWYG mengambang muncul.';

  @override
  String get editingButtonsDirection => 'Arah tombol pengeditan';

  @override
  String get editingButtonsDirectionDescription =>
      'Pilih apakah tombol pengeditan WYSIWYG mengambang disusun secara horizontal atau vertikal.';

  @override
  String get horizontal => 'Horizontal';

  @override
  String get vertical => 'Vertikal';

  @override
  String get privacy => 'Privasi';

  @override
  String get allowRemoteImages => 'Muat gambar jarak jauh';

  @override
  String get allowRemoteImagesDescription =>
      'Izinkan pratinjau Markdown dan gambar editor dimuat dari URL http dan https.';

  @override
  String get clearRemoteImagePermissions => 'Hapus izin gambar jarak jauh';

  @override
  String get clearRemoteImagePermissionsDescription =>
      'Lupakan ruang kerja yang diizinkan memuat gambar jarak jauh.';

  @override
  String get clearGitWorkspaceTrust => 'Hapus ruang kerja Git yang tepercaya';

  @override
  String get clearGitWorkspaceTrustDescription =>
      'Tanyakan sebelum mengaktifkan fitur Git untuk ruang kerja tepercaya sebelumnya.';

  @override
  String get settingsWindowSectionTitle => 'Jendela';

  @override
  String get settingsReopenWorkspaceOnStartupTitle =>
      'Buka kembali ruang kerja sebelumnya saat startup';

  @override
  String get settingsReopenWorkspaceOnStartupDescription =>
      'Buka ruang kerja dan tab dari sesi sebelumnya saat BusyMark dimulai.';

  @override
  String get settingsConfirmCloseWithUnsavedChangesTitle =>
      'Konfirmasikan sebelum menutup dengan perubahan yang belum disimpan';

  @override
  String get settingsConfirmCloseWithUnsavedChangesDescription =>
      'Tanyakan sebelum menutup BusyMark jika ada perubahan yang belum disimpan pada dokumen.';

  @override
  String get closeUnsavedChangesTitle => 'Perubahan yang belum disimpan';

  @override
  String get closeUnsavedChangesSingleMessage =>
      'Dokumen ini memiliki perubahan yang belum disimpan. Simpan perubahan sebelum menutup BusyMark?';

  @override
  String closeUnsavedChangesMultipleMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Ada $count dokumen dengan perubahan yang belum disimpan. Simpan perubahan sebelum menutup BusyMark?',
      one:
          'Ada 1 dokumen dengan perubahan yang belum disimpan. Simpan perubahan sebelum menutup BusyMark?',
      zero: 'Simpan perubahan sebelum menutup BusyMark?',
    );
    return '$_temp0';
  }

  @override
  String get closeUnsavedChangesCancel => 'Batal';

  @override
  String get closeUnsavedChangesDiscard => 'Buang';

  @override
  String get closeUnsavedChangesSave => 'Simpan';

  @override
  String get currentFile => 'File saat ini';

  @override
  String get unsavedChanges => 'Perubahan yang belum disimpan';

  @override
  String unsavedChangesMessage(String fileName) {
    return 'Anda memiliki perubahan yang belum disimpan di $fileName. Simpan sebelum melanjutkan?';
  }

  @override
  String unsavedChangesMultipleMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Ada $count dokumen dengan perubahan yang belum disimpan. Simpan sebelum melanjutkan?',
      one:
          'Ada 1 dokumen dengan perubahan yang belum disimpan. Simpan sebelum melanjutkan?',
    );
    return '$_temp0';
  }

  @override
  String get fileChangedOnDisk => 'File diubah pada disk';

  @override
  String get fileChangedOnDiskMessage =>
      'File ini berubah pada disk sejak Anda membukanya. Timpa itu?';

  @override
  String get untitledMarkdownFileName => 'Tanpa judul.md';

  @override
  String get unorderedList => 'Daftar tidak berurutan';

  @override
  String get orderedList => 'Daftar bernomor';

  @override
  String get taskList => 'Daftar tugas';

  @override
  String get toggleTaskChecked => 'Alihkan status tugas';

  @override
  String get indentListItem => 'Tambah inden item daftar';

  @override
  String get outdentListItem => 'Kurangi inden item daftar';

  @override
  String get blockquote => 'Kutipan blok';

  @override
  String get codeBlock => 'Blok kode';

  @override
  String get codeBlockLanguage => 'Bahasa blok kode';

  @override
  String get image => 'Gambar';

  @override
  String get video => 'Video';

  @override
  String get openVideo => 'Putar video';

  @override
  String get pauseVideo => 'Jeda video';

  @override
  String get videoUnavailable => 'Video tidak tersedia';

  @override
  String get videoPreview => 'Pratinjau video';

  @override
  String get diagnosticWritersideVideoMissingSource =>
      'Video tidak memiliki atribut src-nya.';

  @override
  String diagnosticWritersideVideoUnsupportedSource(String source) {
    return 'Sumber video tidak didukung: $source';
  }

  @override
  String diagnosticWritersideVideoMissingFile(String source) {
    return 'File video tidak ada: $source';
  }

  @override
  String diagnosticWritersideVideoMissingPreview(String preview) {
    return 'Gambar pratinjau video tidak ada: $preview';
  }

  @override
  String get inlineImage => 'Gambar sebaris';

  @override
  String get table => 'Tabel';

  @override
  String get htmlBlock => 'Blok HTML';

  @override
  String get htmlContentDefault => 'Konten HTML';

  @override
  String get shortcutHtmlBlockDescription => 'Sisipkan atau edit blok HTML';

  @override
  String get renderedHtml => 'HTML yang dirender';

  @override
  String get editHtml => 'Edit HTML';

  @override
  String get htmlSource => 'Sumber HTML';

  @override
  String get thematicBreak => 'Pemisah tematik';

  @override
  String get bold => 'Tebal';

  @override
  String get italic => 'Miring';

  @override
  String get underline => 'Garis bawah';

  @override
  String get strikethrough => 'Dicoret';

  @override
  String get inlineCode => 'Kode sebaris';

  @override
  String get link => 'Link';

  @override
  String get hardLineBreak => 'Pemisah baris keras';

  @override
  String get textStyle => 'Gaya teks';

  @override
  String get paragraph => 'Paragraf';

  @override
  String get heading1 => 'Judul 1';

  @override
  String get heading2 => 'Judul 2';

  @override
  String get heading3 => 'Judul 3';

  @override
  String get heading4 => 'Judul 4';

  @override
  String get heading5 => 'Judul 5';

  @override
  String get heading6 => 'Judul 6';

  @override
  String headingLevelAbbreviation(int level) {
    return 'H$level';
  }

  @override
  String get deleteTable => 'Hapus tabel';

  @override
  String tableColumnNumber(int columnNumber) {
    return 'Kolom $columnNumber';
  }

  @override
  String get insertColumnLeft => 'Sisipkan kolom ke kiri';

  @override
  String get insertColumnRight => 'Sisipkan kolom ke kanan';

  @override
  String get deleteColumn => 'Hapus kolom';

  @override
  String get tableAlignmentUnspecified => 'Perataan: Tidak ditentukan';

  @override
  String get tableAlignmentLeft => 'Perataan: Kiri';

  @override
  String get tableAlignmentCenter => 'Perataan: Tengah';

  @override
  String get tableAlignmentRight => 'Perataan: Kanan';

  @override
  String tableRowNumber(int rowNumber) {
    return 'Baris $rowNumber';
  }

  @override
  String get insertRowAbove => 'Sisipkan baris di atas';

  @override
  String get insertRowBelow => 'Sisipkan baris di bawah';

  @override
  String get deleteRow => 'Hapus baris';

  @override
  String get tableHeaderHint => 'Header';

  @override
  String get tableCellHint => 'Sel';

  @override
  String get language => 'Bahasa';

  @override
  String get hideEditingButtons => 'Sembunyikan tombol pengeditan';

  @override
  String get showEditingButtons => 'Tampilkan tombol pengeditan';

  @override
  String get altText => 'Teks alternatif';

  @override
  String get editorPlaceholderText => 'teks';

  @override
  String get editorPlaceholderCode => 'kode';

  @override
  String get editorPlaceholderAltText => 'teks alternatif';

  @override
  String get describeTheImage => 'Jelaskan gambarnya';

  @override
  String get columns => 'Kolom';

  @override
  String get rows => 'Baris';

  @override
  String tableHeaderNumber(int columnNumber) {
    return 'Header $columnNumber';
  }

  @override
  String get tableCellDefault => 'Sel';

  @override
  String get noImageSource => 'Tidak ada sumber gambar';

  @override
  String get remoteImageBlocked => 'Gambar jarak jauh diblokir';

  @override
  String get remoteImageBlockedTooltip =>
      'Pilih apakah BusyMark dapat memuat gambar jarak jauh.';

  @override
  String get remoteImagesBlockedTitle => 'Gambar jarak jauh diblokir';

  @override
  String get remoteImagesBlockedMessage =>
      'Dokumen ini merujuk pada gambar dari internet. Memuatnya dapat mengungkapkan informasi jaringan ke host gambar.';

  @override
  String get loadRemoteImagesForWorkspace => 'Muat untuk ruang kerja ini';

  @override
  String get alwaysLoadRemoteImages => 'Selalu muat gambar jarak jauh';

  @override
  String get hideSidebar => 'Sembunyikan panel bilah sisi';

  @override
  String get showSidebar => 'Tampilkan panel bilah sisi';

  @override
  String get showPreview => 'Tampilkan pratinjau';

  @override
  String get hidePreview => 'Sembunyikan pratinjau';

  @override
  String get workspaceKindUnsavedMarkdown =>
      'File Markdown yang belum disimpan';

  @override
  String get workspaceKindSingleMarkdown => 'File Markdown tunggal';

  @override
  String get workspaceKindMarkdownFolder => 'Folder Markdown';

  @override
  String get workspaceKindWritersideModule => 'Modul Writerside';

  @override
  String get problems => 'Masalah';

  @override
  String diagnosticCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count diagnostik',
      one: '1 diagnostik',
      zero: 'Tidak ada diagnostik',
    );
    return '$_temp0';
  }

  @override
  String get files => 'File';

  @override
  String get toc => 'Daftar isi';

  @override
  String get tocActions => 'Tindakan TOC';

  @override
  String get markdownUnsaved => 'Markdown - belum disimpan';

  @override
  String workspaceDetail(String kind, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count file',
      one: '1 file',
    );
    return '$kind - $_temp0';
  }

  @override
  String get noFiles => 'Tidak ada file';

  @override
  String get newFile => 'File baru';

  @override
  String get noWritersideToc => 'Tidak ada TOC Writerside';

  @override
  String get tocSection => 'Bagian daftar isi';

  @override
  String get newTopic => 'Topik baru';

  @override
  String get newChildTopic => 'Topik anak baru';

  @override
  String get newSiblingTopic => 'Topik saudara baru';

  @override
  String get renameTopicFile => 'Ganti nama file topik';

  @override
  String get topicPlacement => 'Penempatan TOC';

  @override
  String get tocRoot => 'Di akar TOC';

  @override
  String get afterSelectedTopic => 'Setelah topik dipilih';

  @override
  String get insideSelectedTopic => 'Di dalam topik yang dipilih';

  @override
  String get pasteAfterTopic => 'Tempel setelah';

  @override
  String get pasteAsChildTopic => 'Tempel sebagai anak';

  @override
  String get removeFromToc => 'Hapus dari TOC';

  @override
  String get confirmRemoveFromTocTitle => 'Hapus dari TOC?';

  @override
  String confirmRemoveFromTocMessage(String name) {
    return 'Hapus $name dari daftar isi ini? File topik akan disimpan.';
  }

  @override
  String get confirmDeleteTopicTitle => 'Hapus file topik?';

  @override
  String confirmDeleteTopicMessage(String name) {
    return 'Hapus $name dan hapus dari setiap daftar isi? Hal ini tidak dapat dibatalkan.';
  }

  @override
  String get safeDeleteTopicFile => 'Hapus file topik dengan aman…';

  @override
  String get removeTocElement => 'Hapus elemen TOC';

  @override
  String get reviewUsages => 'Tinjau penggunaan';

  @override
  String get deleteTopicFile => 'Hapus file topik';

  @override
  String get removeAction => 'Hapus';

  @override
  String topicRemovalSummary(String topic) {
    return 'Hapus “$topic” dari instance yang dipilih. File topik akan disimpan.';
  }

  @override
  String safeDeleteTopicSummary(String topic) {
    return 'Hapus “$topic” dan perbarui referensinya dengan aman di seluruh proyek Writerside ini.';
  }

  @override
  String childTopicsPromoted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count topik anak akan naik satu tingkat.',
      one: '1 topik anak akan naik satu tingkat.',
    );
    return '$_temp0';
  }

  @override
  String get topicIsStartPageRemovalWarning =>
      'Topik ini digunakan sebagai halaman awal instance. Tinjau penggunaannya dan tetapkan halaman awal lain sebelum melanjutkan.';

  @override
  String topicUsagesCount(int count) {
    return 'Penggunaan ($count)';
  }

  @override
  String get noBreakingTopicUsages => 'Tidak ditemukan referensi yang rusak.';

  @override
  String get topicUsagesFound =>
      'BusyMark menemukan referensi berikut untuk topik ini.';

  @override
  String get topicUsageTocElements => 'elemen TOC';

  @override
  String get topicUsageStartPages => 'Halaman awal';

  @override
  String get topicUsageTopicLinks => 'Tautan topik';

  @override
  String get topicUsageIncludes => 'Elemen include';

  @override
  String usageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count penggunaan',
      one: '1 penggunaan',
    );
    return '$_temp0';
  }

  @override
  String get refactoringOptions => 'Opsi refaktor';

  @override
  String get updateUsagesAutomatically => 'Perbarui penggunaan secara otomatis';

  @override
  String get updateUsagesAutomaticallyDescription =>
      'Hapus referensi dan include TOC, serta pertahankan teks tautan.';

  @override
  String get manualUsageUpdatesRequired =>
      'Beberapa penggunaan memerlukan perubahan manual sebelum pemfaktoran ulang ini.';

  @override
  String get setRedirectTo => 'Alihkan ke';

  @override
  String get noRedirectDescription =>
      'Jangan mengalihkan halaman lama yang diterbitkan.';

  @override
  String get redirectTarget => 'Target pengalihan';

  @override
  String get remainingUsagesBlockRemoval =>
      'Tinjau dan perbarui sisa penggunaan sebelum melanjutkan, atau aktifkan pembaruan otomatis bila tersedia.';

  @override
  String usagesOfTopic(String topic) {
    return 'Penggunaan $topic';
  }

  @override
  String get noUsagesFound => 'Tidak ada penggunaan yang ditemukan';

  @override
  String get outsideSelectedInstance => 'di luar instance yang dipilih';

  @override
  String get doRefactor => 'Lakukan refaktor';

  @override
  String get orphanTopicTitle => 'File topik tidak lagi digunakan';

  @override
  String get keepTopicFile => 'Simpan file topik';

  @override
  String orphanTopicMessage(String topic) {
    return '“$topic” tidak lagi digunakan di mana pun dalam proyek Writerside ini. Hapus file, atau simpan agar dapat digunakan pada instance lain.';
  }

  @override
  String get defaultNewTopicTitle => 'Topik baru';

  @override
  String get topicTitle => 'Judul topik';

  @override
  String get fileName => 'Nama file';

  @override
  String get topicTitleRequired => 'Judul topik wajib diisi.';

  @override
  String get fileNameRequired => 'Nama file wajib diisi.';

  @override
  String get rename => 'Ganti nama';

  @override
  String get confirmDeleteFileTitle => 'Hapus file?';

  @override
  String get confirmDeleteFolderTitle => 'Hapus folder?';

  @override
  String confirmDeleteFileMessage(String name) {
    return 'Hapus $name? Hal ini tidak dapat dibatalkan.';
  }

  @override
  String confirmDeleteFolderMessage(String name) {
    return 'Hapus $name dan semua file di dalamnya? Hal ini tidak dapat dibatalkan.';
  }

  @override
  String get useSingleSafeFileName => 'Gunakan satu nama file yang aman.';

  @override
  String useExpectedExtension(String extension) {
    return 'Gunakan ekstensi $extension untuk format yang dipilih.';
  }

  @override
  String get useIdentifierCharacters =>
      'Gunakan huruf, angka, garis bawah, atau tanda hubung sebelum ekstensi.';

  @override
  String get topicIdAlreadyExists => 'ID Topik sudah ada.';

  @override
  String get createWritersideTopicFailed =>
      'Tidak dapat membuat topik Writerside.';

  @override
  String get noOutline => 'Tidak ada garis besar';

  @override
  String expandKind(String kind) {
    return 'Perluas $kind';
  }

  @override
  String collapseKind(String kind) {
    return 'Ciutkan $kind';
  }

  @override
  String get foldKindSection => 'bagian';

  @override
  String get foldKindList => 'daftar';

  @override
  String get foldKindQuote => 'kutipan';

  @override
  String get foldKindTag => 'tag';

  @override
  String get sourceSearchPreviousMatch => 'Kecocokan sebelumnya';

  @override
  String get sourceSearchNextMatch => 'Kecocokan berikutnya';

  @override
  String get sourceSearchCaseSensitive => 'Peka huruf besar-kecil';

  @override
  String get sourceSearchWholeWord => 'Seluruh kata';

  @override
  String get sourceSearchRegex => 'Regex';

  @override
  String get sourceSearchReplacement => 'Ganti dengan';

  @override
  String get sourceSearchReplaceCurrent => 'Ganti kecocokan saat ini';

  @override
  String get sourceSearchReplaceAndFindNext => 'Ganti dan temukan selanjutnya';

  @override
  String get sourceSearchReplaceAll => 'Ganti semua';

  @override
  String get workspaceReplace => 'Ganti di Ruang Kerja';

  @override
  String get reviewReplacements => 'Tinjau penggantian';

  @override
  String get applyReplacements => 'Terapkan penggantian';

  @override
  String get skippedFiles => 'File yang dilewati';

  @override
  String get workspaceReplaceDirtyBuffer => 'Konten editor belum disimpan';

  @override
  String get workspaceReplaceDiskContent => 'Konten disk yang disimpan';

  @override
  String selectFileMatches(int count) {
    return 'Pilih semua kecocokan $count';
  }

  @override
  String workspaceReplaceApplied(int matches, int files, int skipped) {
    return 'Mengganti $matches kecocokan di $files file; melewati $skipped.';
  }

  @override
  String documentFormatWithFinalNewline(String encoding, String lineEnding) {
    return '$encoding · $lineEnding · Baris baru di akhir';
  }

  @override
  String documentFormatWithoutFinalNewline(String encoding, String lineEnding) {
    return '$encoding · $lineEnding · Tidak ada baris baru di akhir';
  }

  @override
  String get normalizeLineEndings => 'Normalisasi akhir baris';

  @override
  String get mixedLineEndingsSavePrompt =>
      'Dokumen ini berisi akhiran baris campuran. Pilih format.';

  @override
  String workspaceReplaceMixedLineEndings(String fileName) {
    return '$fileName menggunakan akhiran baris campuran. Pilih format yang akan digunakan sebelum mengganti.';
  }

  @override
  String get workspaceReplaceIssueOversized =>
      'Melewatkan file berukuran besar.';

  @override
  String get workspaceReplaceIssueUnreadable =>
      'Melewatkan file yang tidak dapat dibaca.';

  @override
  String get workspaceReplaceIssueInvalidUtf8 =>
      'Melewatkan file yang tidak valid UTF-8.';

  @override
  String get workspaceReplaceIssueTruncated => 'Pratinjau pengganti terpotong.';

  @override
  String get workspaceReplaceIssueFileChanged =>
      'Melewatkan file yang berubah setelah pratinjau.';

  @override
  String get workspaceReplaceIssueBufferChanged =>
      'Melewati buffer editor yang berubah setelah pratinjau.';

  @override
  String get workspaceReplaceIssueNormalizationRequired =>
      'Pilih normalisasi LF atau CRLF sebelum mengganti.';

  @override
  String get workspaceReplaceIssuePartialConflict =>
      'Rollback terhenti karena file berubah secara bersamaan. Beberapa penggantian mungkin tetap ada; konten yang dipindahkan dipertahankan di jalur di bawah ini.';

  @override
  String get workspaceReplaceIssueApplyFailed =>
      'Penggantian yang ditinjau tidak dapat dilakukan; tidak ada file yang diubah.';

  @override
  String externalChangesTitle(String fileName) {
    return 'Perubahan eksternal — $fileName';
  }

  @override
  String get externalFileDeleted => 'File ini telah dihapus pada disk.';

  @override
  String get externalFileChanged =>
      'File ini diubah pada disk saat Anda memiliki hasil edit yang belum disimpan.';

  @override
  String recoveredDocumentReview(String fileName) {
    return 'Konten belum disimpan yang dipulihkan untuk $fileName. Tinjau, kemudian simpan, simpan sebagai, atau buang.';
  }

  @override
  String get compare => 'Bandingkan';

  @override
  String get reloadFromDisk => 'Muat ulang dari disk';

  @override
  String get keepMine => 'Pertahankan milik saya';

  @override
  String get saveAs => 'Simpan sebagai';

  @override
  String get sourceSearchInvalidRegex => 'Ekspresi reguler tidak valid';

  @override
  String get sourceLargeFileFeaturesPaused =>
      'File besar: penyorotan dan pelipatan dijeda';

  @override
  String get nothingToRead => 'Tidak ada yang perlu dibaca';

  @override
  String get admonition => 'Kotak keterangan';

  @override
  String get quote => 'Kutipan';

  @override
  String get note => 'Catatan';

  @override
  String get tip => 'Tip';

  @override
  String get warning => 'Peringatan';

  @override
  String get tabs => 'tab';

  @override
  String get tab => 'tab';

  @override
  String get procedure => 'Prosedur';

  @override
  String get step => 'Langkah';

  @override
  String get topic => 'Topik';

  @override
  String get chapter => 'Bab';

  @override
  String couldNotOpenTarget(String target) {
    return 'Tidak dapat membuka $target';
  }

  @override
  String linkTargetNotFound(String targetPath) {
    return 'Target tautan tidak ditemukan: $targetPath';
  }

  @override
  String get cannotOpenFileTypeInEditor =>
      'Tidak dapat membuka jenis file ini di editor';

  @override
  String anchorNotFound(String anchor) {
    return 'Jangkar tidak ditemukan: $anchor';
  }

  @override
  String get noProblemsFound => 'Tidak ada masalah yang ditemukan';

  @override
  String get noResults => 'Tidak ada hasil';

  @override
  String searchResultLine(String relativePath, int lineNumber) {
    return '$relativePath - Baris $lineNumber';
  }

  @override
  String get untitledResult => 'Hasil tanpa judul';

  @override
  String get documentKindMarkdownFile => 'File Markdown';

  @override
  String get documentKindWritersideMarkdownTopic => 'Topik Markdown Writerside';

  @override
  String get documentKindWritersideXmlTopic => 'Topik XML Writerside';

  @override
  String get documentKindWritersideTree => 'Pohon Writerside';

  @override
  String get documentKindConfigurationFile => 'File konfigurasi';

  @override
  String get documentKindVariablesFile => 'File variabel';

  @override
  String get documentKindCategoriesFile => 'File kategori';

  @override
  String get documentKindResourceFile => 'File sumber daya';

  @override
  String workspaceErrorOpenFailed(String error) {
    return 'Gagal dibuka: $error';
  }

  @override
  String workspaceErrorCreateWritersideProjectFailed(String error) {
    return 'Tidak dapat membuat proyek Writerside: $error';
  }

  @override
  String workspaceErrorCreateWritersideTopicFailed(String error) {
    return 'Tidak dapat membuat topik Writerside: $error';
  }

  @override
  String workspaceErrorCouldNotOpenFile(String error) {
    return 'Tidak dapat membuka file: $error';
  }

  @override
  String get workspaceErrorChooseWhereToSaveMarkdown =>
      'Pilih tempat untuk menyimpan file Markdown ini.';

  @override
  String get workspaceErrorSaveBlockedFileChangedOnDisk =>
      'Penyimpanan diblokir: file diubah pada disk.';

  @override
  String workspaceErrorSaveFailed(String error) {
    return 'Gagal menyimpan: $error';
  }

  @override
  String workspaceErrorFileOperationFailed(String error) {
    return 'Operasi file gagal: $error';
  }

  @override
  String workspaceErrorValidationFailed(String error) {
    return 'Validasi gagal: $error';
  }

  @override
  String workspaceRecoveryRestored(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count dokumen yang belum disimpan berhasil dipulihkan. Tinjau masing-masing sebelum menyimpan atau membuangnya.',
      one:
          '1 dokumen yang belum disimpan berhasil dipulihkan. Tinjau sebelum menyimpan atau membuangnya.',
    );
    return '$_temp0';
  }

  @override
  String workspaceRecoveryDamaged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count catatan pemulihan yang rusak tidak dapat dipulihkan. Catatan pemulihan yang valid tetap tersedia.',
      one:
          '1 catatan pemulihan yang rusak tidak dapat dipulihkan. File pemulihan asli dipertahankan untuk diperiksa.',
    );
    return '$_temp0';
  }

  @override
  String errorPathDoesNotExist(String path) {
    return 'Jalur tidak ada: $path';
  }

  @override
  String errorTargetDirectoryNotEmpty(String path) {
    return 'Direktori tujuan sudah ada dan berisi file: $path';
  }

  @override
  String errorTargetPathNotDirectory(String path) {
    return 'Jalur tujuan sudah ada tetapi bukan direktori: $path';
  }

  @override
  String errorGeneratedFileAlreadyExists(String path) {
    return 'File yang dihasilkan sudah ada: $path';
  }

  @override
  String get errorParentDirectoryRequired => 'Direktori induk diperlukan.';

  @override
  String errorParentDirectoryMissing(String path) {
    return 'Direktori induk tidak ada: $path';
  }

  @override
  String errorDirectoryMissing(String path) {
    return 'Direktori tidak ada: $path';
  }

  @override
  String errorPathAlreadyExists(String path) {
    return 'Jalur sudah ada: $path';
  }

  @override
  String get errorFileNameRequired => 'Nama file wajib diisi.';

  @override
  String get errorFileNameUnsafe =>
      'Nama file harus berupa satu segmen jalur aman.';

  @override
  String get errorFileOperationInvalidTarget =>
      'Tidak dapat memindahkan folder ke dalam folder itu sendiri.';

  @override
  String get errorFileOperationOutsideRoot =>
      'Operasi file harus tetap berada di dalam ruang kerja.';

  @override
  String get errorFileOperationRoot =>
      'Akar ruang kerja tidak dapat diubah dari pohon file.';

  @override
  String get errorProjectNameRequired => 'Nama proyek wajib diisi.';

  @override
  String get errorDirectoryNameRequired => 'Nama direktori wajib diisi.';

  @override
  String get errorDirectoryNameUnsafe =>
      'Nama direktori harus berupa satu segmen jalur aman.';

  @override
  String get errorInstanceIdInvalid =>
      'ID instance harus diawali huruf kecil dan hanya boleh berisi huruf kecil, angka, garis bawah, dan tanda hubung.';

  @override
  String get errorTopicFileInvalid =>
      'Nama file topik harus berupa nama file Markdown tanpa pemisah jalur.';

  @override
  String get errorTopicTitleRequired => 'Judul topik wajib diisi.';

  @override
  String errorWritersideModuleRootMissing(String path) {
    return 'Root modul Writerside tidak ada: $path';
  }

  @override
  String get errorWritersideModuleNotOpen =>
      'Modul Writerside harus terbuka untuk membuat topik.';

  @override
  String get errorWritersideInstanceTreeMissing =>
      'Modul Writerside tidak memiliki pohon instance.';

  @override
  String errorWritersideTreeFileMissing(String path) {
    return 'File pohon Writerside tidak ada: $path';
  }

  @override
  String errorTopicIdAlreadyExists(String topicId) {
    return 'ID topik \"$topicId\" sudah ada di modul bantuan ini.';
  }

  @override
  String errorTopicFileAlreadyExists(String path) {
    return 'File topik sudah ada: $path';
  }

  @override
  String errorReferenceTopicMissing(String topic) {
    return 'Topik referensi tidak ada di pohon yang dipilih: $topic';
  }

  @override
  String get errorWritersideTocNodeMissing =>
      'Entri TOC yang dipilih sudah tidak ada lagi.';

  @override
  String get errorWritersideTocInvalidMove =>
      'Entri TOC tidak dapat dipindahkan ke dirinya sendiri atau ke salah satu turunannya.';

  @override
  String errorWritersideStartTopicDelete(String topic) {
    return 'Topik awal $topic tidak dapat dihapus. Pilih halaman awal lain terlebih dahulu.';
  }

  @override
  String get errorWritersideSafeDeleteRequired =>
      'Gunakan Safe Delete untuk file topik Writerside.';

  @override
  String get errorWritersideTopicUsageScanFailed =>
      'Tidak dapat menyelesaikan pemindaian penggunaan topik. Tidak ada file yang diubah.';

  @override
  String get errorWritersideTopicUsagesRemain =>
      'Beberapa penggunaan topik masih memerlukan perhatian. Tinjaulah sebelum melanjutkan.';

  @override
  String get errorWritersideRedirectInvalid =>
      'Target pengalihan yang dipilih tidak valid lagi. Pilih lagi.';

  @override
  String errorWritersideRollbackFailed(String paths) {
    return 'Penghapusan topik tidak dapat dibatalkan sepenuhnya. Tinjau jalur ini sebelum melanjutkan: $paths';
  }

  @override
  String get errorTopicsRootUnsafe =>
      'Akar topik harus berupa direktori relatif yang aman.';

  @override
  String get errorTopicFileNameUnsafe =>
      'Nama file topik harus berupa segmen jalur aman tunggal.';

  @override
  String errorTopicFileExtensionMismatch(String extension) {
    return 'Ekstensi file topik harus sesuai dengan format yang dipilih ($extension).';
  }

  @override
  String get errorTopicFileNameInvalid =>
      'Nama file topik hanya boleh berisi huruf, angka, garis bawah, dan tanda hubung.';

  @override
  String errorUnknown(String code) {
    return 'Kesalahan tidak diketahui: $code';
  }

  @override
  String diagnosticWorkspaceFileStatFailed(String error) {
    return 'Tidak dapat membaca metadata file: $error';
  }

  @override
  String get diagnosticWorkspaceScanSkipped =>
      'Ruang kerja besar terdeteksi. Beberapa file dilewati agar aplikasi tetap responsif.';

  @override
  String diagnosticWorkspaceScanInspectFailed(String error) {
    return 'Tidak dapat memeriksa entri ruang kerja: $error';
  }

  @override
  String get diagnosticWorkspaceFileTooLarge =>
      'File lebih besar dari batas penguraian otomatis beta.';

  @override
  String diagnosticWorkspaceFileReadFailed(String error) {
    return 'Tidak dapat membaca file Markdown: $error';
  }

  @override
  String get diagnosticMarkdownAttributeMalformed =>
      'Blok atribut judul Writerside salah format.';

  @override
  String diagnosticMarkdownHeadingDuplicateId(String id) {
    return 'ID judul duplikat \"$id\".';
  }

  @override
  String get diagnosticWritersideTopicH1ConvertedToChapter =>
      'Judul H1 tingkat atas tambahan diperlakukan sebagai bab.';

  @override
  String get diagnosticWritersideMarkdownTopicMissingTitle =>
      'Topik Markdown Writerside tidak memiliki judul H1 atau front matter.';

  @override
  String get diagnosticWritersideXmlTopicMissingTitle =>
      'Judul topik XML tidak ada.';

  @override
  String diagnosticWritersideTopicFileMissingTitle(String fileName) {
    return 'Topik \"$fileName\" tidak memiliki judul.';
  }

  @override
  String get diagnosticMarkdownFrontMatterMalformed =>
      'Front matter tidak tertutup.';

  @override
  String get diagnosticMarkdownRawHtmlUnsafe => 'Elemen HTML tidak aman.';

  @override
  String diagnosticMarkdownLinkUnresolvedTarget(String targetPath) {
    return 'Target tautan tidak ada: $targetPath';
  }

  @override
  String diagnosticMarkdownLinkUnresolvedAnchor(String anchor) {
    return 'Jangkar \"$anchor\" tidak ada.';
  }

  @override
  String diagnosticMarkdownImageMissingAlt(String destination) {
    return 'Teks alternatif pada gambar \"$destination\" tidak ada.';
  }

  @override
  String diagnosticMarkdownImageMissingFile(String destination) {
    return 'Gambar tidak ada: $destination';
  }

  @override
  String diagnosticInvalidXml(String message) {
    return 'XML tidak valid: $message';
  }

  @override
  String get diagnosticWritersideConfigInvalidRoot =>
      'Elemen akar writerside.cfg harus berupa <ihp>.';

  @override
  String get diagnosticWritersideConfigMissingSnippetsSrc =>
      'Deklarasi snippets tidak memiliki atribut src.';

  @override
  String get diagnosticWritersideConfigMissingInstanceGroupsSrc =>
      'Deklarasi instance-groups tidak memiliki src.';

  @override
  String diagnosticWritersideConfigInvalidKeymapsMode(String mode) {
    return 'Mode peta kunci tidak didukung: $mode';
  }

  @override
  String get diagnosticWritersideConfigMissingInstanceSrc =>
      'Deklarasi instance tidak memiliki src.';

  @override
  String get diagnosticWritersideConfigMissingInstance =>
      'writerside.cfg tidak mendaftarkan sebuah instance.';

  @override
  String get diagnosticWritersideTreeInvalidRoot =>
      'Akar .tree harus <instance-profile>.';

  @override
  String get diagnosticWritersideTreeMissingId =>
      'Profil instance tidak memiliki id.';

  @override
  String diagnosticWritersideTreeIdMismatch(String id) {
    return 'Batang file pohon tidak cocok dengan id instance \"$id\".';
  }

  @override
  String get diagnosticWritersideTreeMissingStartPage =>
      'Instance non-library tidak memiliki start-page.';

  @override
  String diagnosticWritersideStartPageMissing(String startPage) {
    return 'Halaman awal \"$startPage\" tidak ada.';
  }

  @override
  String diagnosticWritersideTreeDuplicateTopic(String topic) {
    return 'Topik \"$topic\" muncul lebih dari sekali dalam TOC instance ini.';
  }

  @override
  String get diagnosticWritersideVariableMalformedDeclaration =>
      'Deklarasi variabel harus mempunyai nama dan nilai.';

  @override
  String diagnosticWritersideVariableDuplicateName(String name) {
    return 'Variabel \"$name\" dideklarasikan lebih dari satu kali.';
  }

  @override
  String get diagnosticWritersideCategoryMissingId =>
      'Kategori tidak memiliki id.';

  @override
  String diagnosticWritersideCategoryDuplicateId(String id) {
    return 'Kategori \"$id\" dideklarasikan lebih dari satu kali.';
  }

  @override
  String diagnosticWritersideCategoryDuplicateOrder(String order) {
    return 'Pesanan kategori \"$order\" dideklarasikan lebih dari satu kali.';
  }

  @override
  String get diagnosticWritersideTopicInvalidRoot =>
      'Akar .topic harus <topic>.';

  @override
  String get diagnosticWritersideTopicMissingRootId =>
      'Topik XML tidak memiliki id root.';

  @override
  String diagnosticWritersideTopicRootIdMismatch(String id, String expectedId) {
    return 'Id akar topik XML \"$id\" harus cocok dengan nama file \"$expectedId\".';
  }

  @override
  String diagnosticWritersideTopicDuplicateElementId(String elementId) {
    return 'ID elemen \"$elementId\" muncul lebih dari sekali.';
  }

  @override
  String get diagnosticWritersideTopicAnchorMissingHref =>
      '<a> tidak ada href.';

  @override
  String get diagnosticWritersideConfigMissing =>
      'Mode Writerside memerlukan writerside.cfg.';

  @override
  String diagnosticWritersideConfigMissingBuildConfigDirectory(
    String relativePath,
  ) {
    return 'Direktori konfigurasi build yang dikonfigurasi tidak ada: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingApiSpecificationsDirectory(
    String relativePath,
  ) {
    return 'Direktori spesifikasi API yang dikonfigurasi tidak ada: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingSnippetsDirectory(
    String relativePath,
  ) {
    return 'Direktori cuplikan yang dikonfigurasi tidak ada: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingVarsFile(String relativePath) {
    return 'File variabel yang dikonfigurasi tidak ada: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingCategoriesFile(String relativePath) {
    return 'File kategori yang dikonfigurasi tidak ada: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceGroupsFile(
    String relativePath,
  ) {
    return 'File grup instance yang dikonfigurasi tidak ada: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceTree(String source) {
    return 'Pohon instance terdaftar \"$source\" tidak ada.';
  }

  @override
  String diagnosticWritersideTopicReadFailed(String error) {
    return 'Tidak dapat membaca file topik: $error';
  }

  @override
  String diagnosticWritersideDefaultTopicsDirectoryMissing(
    String relativePath,
  ) {
    return 'Direktori topik default tidak ada: $relativePath.';
  }

  @override
  String diagnosticWritersideTopicsDirectoryMissing(String relativePath) {
    return 'Direktori topik yang dikonfigurasi tidak ada: $relativePath';
  }

  @override
  String diagnosticWritersideImagesDirectoryMissing(String relativePath) {
    return 'Direktori gambar yang dikonfigurasi tidak ada: $relativePath';
  }

  @override
  String diagnosticWritersideTopicDuplicateId(String id) {
    return 'ID elemen \"$id\" muncul lebih dari sekali.';
  }

  @override
  String diagnosticWritersideTreeMissingTopic(String topic) {
    return 'TOC mereferensikan topik \"$topic\" yang hilang.';
  }

  @override
  String diagnosticWritersideTreeInvalidHref(String href) {
    return 'Href eksternal \"$href\" tidak valid.';
  }

  @override
  String diagnosticWritersideVariableUnresolved(String name) {
    return 'Variabel \"%$name%\" tidak dideklarasikan.';
  }

  @override
  String diagnosticWritersideTopicLinkUnresolved(String destination) {
    return 'Tautan topik \"$destination\" tidak terselesaikan.';
  }

  @override
  String diagnosticWritersideAnchorUnresolved(
    String anchor,
    String targetName,
  ) {
    return 'Jangkar \"$anchor\" tidak ada di \"$targetName\".';
  }

  @override
  String get diagnosticWritersideIncludeMissingFrom =>
      '<include> tidak memiliki atribut from.';

  @override
  String diagnosticWritersideIncludeSourceMissing(String from) {
    return 'Sumber include \"$from\" tidak ada.';
  }

  @override
  String diagnosticWritersideIncludeElementMissing(
    String elementId,
    String from,
  ) {
    return 'Elemen include \"$elementId\" tidak ada di \"$from\".';
  }

  @override
  String diagnosticWritersideCategoryUnresolved(String ref) {
    return 'Lihat juga kategori \"$ref\" tidak dideklarasikan.';
  }

  @override
  String diagnosticWritersideTopicAmbiguousReference(String reference) {
    return 'Referensi topik \"$reference\" bersifat ambigu.';
  }

  @override
  String diagnosticUnknown(String code) {
    return 'Diagnostik tidak diketahui: $code';
  }

  @override
  String get close => 'Tutup';

  @override
  String get git => 'Git';

  @override
  String get gitDiff => 'Git diff';

  @override
  String get gitShowDiff => 'Tunjukkan perbedaan';

  @override
  String gitDiffHunkRange(String oldRange, String newRange) {
    return 'lama $oldRange → baru $newRange';
  }

  @override
  String get gitDiffNoLines => 'tidak ada baris';

  @override
  String get gitUnavailableTitle => 'Git tidak tersedia';

  @override
  String gitUnavailableMessage(String reason) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'other':
          'Instal Git atau konfigurasikan BusyMark untuk menggunakan executable Git yang tersedia. $reason',
    });
    return '$_temp0';
  }

  @override
  String get gitTrustRequiredTitle => 'Percayai ruang kerja ini untuk Git?';

  @override
  String get gitTrustRequiredMessage =>
      'Repositori Git dapat menjalankan program melalui hook, filter, dan konfigurasi lainnya. Percayai ruang kerja ini sebelum BusyMark membaca data repositori atau mengaktifkan tindakan Git.';

  @override
  String get gitTrustWorkspace => 'Percayai ruang kerja';

  @override
  String get gitNotRepositoryTitle => 'Bukan repositori Git';

  @override
  String get gitNotRepositoryMessage =>
      'Ruang kerja ini tidak berada di dalam repositori Git.';

  @override
  String get gitInitializeRepository => 'Inisialisasi repositori';

  @override
  String get gitDetachedHead => 'HEAD terpisah';

  @override
  String gitDetachedHeadAt(String commit) {
    return 'Terpisah di $commit';
  }

  @override
  String get gitNoUpstream => 'Tidak ada upstream';

  @override
  String gitAheadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commit yang belum di-push',
      one: '1 commit yang belum di-push',
    );
    return '$_temp0';
  }

  @override
  String gitBehindCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commit yang perlu di-pull',
      one: '1 commit yang perlu di-pull',
    );
    return '$_temp0';
  }

  @override
  String get gitClean => 'Tidak ada perubahan';

  @override
  String get gitConflicts => 'Konflik';

  @override
  String get gitChanges => 'Perubahan';

  @override
  String get gitStaged => 'Di-stage';

  @override
  String get gitUnstaged => 'Belum di-stage';

  @override
  String get gitHistory => 'Riwayat';

  @override
  String get gitBranches => 'Cabang';

  @override
  String get gitActions => 'Tindakan Git';

  @override
  String get gitPull => 'Pull';

  @override
  String get gitFetch => 'Fetch';

  @override
  String get gitPush => 'Push';

  @override
  String get gitCommit => 'Commit';

  @override
  String get gitSelectForCommit => 'Siapkan file untuk commit';

  @override
  String get gitRemoveFromCommit => 'Batalkan stage file';

  @override
  String get gitDiscard => 'Kembalikan';

  @override
  String get gitOpenFile => 'Buka file';

  @override
  String get gitMarkResolved => 'Tandai sebagai terselesaikan';

  @override
  String get gitUntracked => 'Tidak terlacak';

  @override
  String get gitCommitMessage => 'Pesan komit';

  @override
  String get gitCommitSelectedFiles => 'File yang dipilih';

  @override
  String get gitCommitNoSelectedFiles =>
      'Stage setidaknya satu file sebelum melakukan commit.';

  @override
  String gitStagedFileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count file yang di-stage',
      one: '1 file yang di-stage',
    );
    return '$_temp0';
  }

  @override
  String get gitOutsideWorkspace => 'Di luar ruang kerja';

  @override
  String get gitCommitMessageRequired => 'Masukkan pesan komit.';

  @override
  String get gitCreateBranch => 'Buat cabang';

  @override
  String get gitNewBranch => 'Cabang baru';

  @override
  String get gitBranchName => 'Nama cabang';

  @override
  String get gitSwitchBranch => 'Beralih';

  @override
  String get gitNoChanges => 'Tidak ada perubahan';

  @override
  String get gitNoHistory => 'Tidak ada riwayat';

  @override
  String get gitNoBranches => 'Tidak ada cabang';

  @override
  String get gitNoDiff => 'Tidak ada perbedaan untuk ditampilkan';

  @override
  String get gitBinaryFile =>
      'File biner. BusyMark tidak merender patch biner.';

  @override
  String gitBinaryFileInfo(int size) {
    return 'File biner ($size byte). BusyMark tidak merender patch biner.';
  }

  @override
  String get gitUnsavedChangesBanner =>
      'Perubahan editor yang belum disimpan tidak disertakan sampai disimpan.';

  @override
  String get gitConfirmDiscardTitle => 'Buang perubahan Git?';

  @override
  String gitConfirmDiscardTracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Semua perubahan yang di-stage dan tidak di-stage pada file terlacak yang dipilih akan dipulihkan ke HEAD.',
      one:
          'Semua perubahan yang di-stage dan tidak di-stage pada file terlacak yang dipilih akan dipulihkan ke HEAD.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardUntracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'File tak terlacak yang dipilih akan dihapus.',
      one: 'File tak terlacak yang dipilih akan dihapus.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardMixed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'File yang dipilih akan dipulihkan atau dihapus berdasarkan status Git-nya.',
      one:
          'File yang dipilih akan dipulihkan atau dihapus berdasarkan status Git-nya.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmSwitchBranchTitle(String branch) {
    return 'Beralih ke $branch?';
  }

  @override
  String get gitConfirmSwitchBranchMessage =>
      'BusyMark akan memuat ulang ruang kerja dari disk setelah Git berpindah cabang.';

  @override
  String get gitConfirmPushSetUpstreamTitle => 'Siapkan upstream branch?';

  @override
  String gitConfirmPushSetUpstreamMessage(String branch) {
    return 'Cabang ini tidak memiliki upstream. BusyMark dapat melakukan push $branch dan mengatur upstream-nya saat tepat satu remote dikonfigurasi.';
  }

  @override
  String get gitProjectHistory => 'Riwayat proyek';

  @override
  String get gitFileHistory => 'Riwayat file';

  @override
  String get gitFileHistoryRequiresOpenFile =>
      'Riwayat file memerlukan file Markdown yang terbuka.';

  @override
  String get gitLoadMore => 'Muat lebih banyak';

  @override
  String get gitChangesInCommit => 'Perubahan dalam commit ini';

  @override
  String get gitCompareWithCurrent => 'Bandingkan dengan versi saat ini';

  @override
  String get gitRestoreVersion => 'Pulihkan versi ini';

  @override
  String get gitConfirmRestoreTitle => 'Pulihkan versi file ini?';

  @override
  String get gitConfirmRestoreMessage =>
      'BusyMark akan mengganti file working tree saat ini dengan versi commit yang dipilih. File yang dipulihkan akan tetap belum di-stage.';

  @override
  String get gitCommitActions => 'Tindakan commit';

  @override
  String get gitResetCurrentBranchToHere =>
      'Setel ulang cabang saat ini ke sini…';

  @override
  String gitResetCurrentBranchTitle(String branch, String commit) {
    return 'Setel ulang $branch ke $commit?';
  }

  @override
  String gitResetCurrentBranchMessage(String branch, String commit) {
    return 'Ini memindahkan branch $branch ke commit $commit. Pilih cara Git memperbarui index dan working tree.';
  }

  @override
  String get gitReset => 'Reset';

  @override
  String get gitResetModeSoft => 'Soft';

  @override
  String get gitResetModeSoftDescription =>
      'Pindahkan cabang saja. Pertahankan indeks dan working tree tanpa perubahan; perbedaan dari commit yang dipilih tetap di-stage.';

  @override
  String get gitResetModeMixed => 'Mixed';

  @override
  String get gitResetModeMixedDescription =>
      'Pindahkan cabang dan reset indeks. Pertahankan working tree tanpa perubahan; perbedaan tetap belum di-stage.';

  @override
  String get gitResetModeHard => 'Hard';

  @override
  String get gitResetModeHardDescription =>
      'Pindahkan cabang dan reset indeks serta working tree. Perubahan tracked akan dibuang; file untracked yang menghalangi dapat dihapus.';

  @override
  String get gitResetModeKeep => 'Keep';

  @override
  String get gitResetModeKeepDescription =>
      'Pindahkan cabang dan reset file tracked sambil mempertahankan perubahan lokal. Git membatalkan reset jika perubahan tersebut bertentangan.';

  @override
  String gitAdditionsDeletions(int additions, int deletions) {
    return '+$additions -$deletions';
  }

  @override
  String get fileActions => 'Tindakan file';

  @override
  String get actions => 'Tindakan';

  @override
  String get gitStatusAdded => 'Ditambahkan';

  @override
  String get gitStatusDeleted => 'Dihapus';

  @override
  String get gitStatusRenamed => 'Berganti nama';

  @override
  String get gitStatusCopied => 'Disalin';

  @override
  String get gitStatusUntracked => 'Tidak terlacak';

  @override
  String get gitStatusConflicted => 'Berkonflik';

  @override
  String get gitStatusIgnored => 'Diabaikan';

  @override
  String get gitStatusTypeChanged => 'Jenis diubah';

  @override
  String get gitStatusModified => 'Dimodifikasi';

  @override
  String get gitStatusUnknown => 'Tidak dikenal';

  @override
  String get gitErrorUnavailable => 'Git tidak tersedia.';

  @override
  String get gitErrorNotRepository => 'Ruang kerja ini bukan repositori Git.';

  @override
  String get gitErrorUnsafePath =>
      'BusyMark memblokir jalur Git yang tidak aman.';

  @override
  String get gitErrorInvalidBranchName => 'Masukkan nama cabang yang valid.';

  @override
  String get gitErrorNoRemote => 'Tidak ada remote Git yang dikonfigurasi.';

  @override
  String get gitErrorNoUpstream =>
      'Tidak ada upstream cabang yang dikonfigurasi.';

  @override
  String get gitErrorMultipleRemotes =>
      'Beberapa remote dikonfigurasi. Pilih upstream di luar versi BusyMark ini.';

  @override
  String get gitErrorDirtyWorkspace =>
      'Simpan atau buang perubahan editor BusyMark sebelum berpindah cabang.';

  @override
  String get gitErrorResetDirtyWorkspace =>
      'Simpan atau buang perubahan editor BusyMark sebelum mengatur ulang cabang saat ini.';

  @override
  String get gitErrorRestoreStagedFile =>
      'Batalkan stage file ini sebelum memulihkan versi historis.';

  @override
  String get gitErrorResetDetachedHead =>
      'Checkout branch terlebih dahulu sebelum melakukan reset.';

  @override
  String get gitErrorDiverged =>
      'Cabang telah menyimpang. Selesaikan penggabungan atau rebase di luar versi BusyMark ini.';

  @override
  String get gitErrorAuthorIdentity =>
      'Git memerlukan nama penulis dan alamat email sebelum dapat melakukan commit.';

  @override
  String get gitAuthorIdentityTitle => 'Identitas Penulis Git';

  @override
  String get gitAuthorIdentityMessage =>
      'Masukkan identitas yang harus dicatat Git saat melakukan commit. BusyMark akan menyimpannya dan mencoba kembali commit ini.';

  @override
  String get gitAuthorName => 'Nama';

  @override
  String get gitAuthorEmail => 'E-mail';

  @override
  String get gitAuthorIdentityGlobal => 'Gunakan untuk semua repositori';

  @override
  String get gitAuthorIdentityGlobalDescription =>
      'Saat dipasang sebagai Snap, ini berlaku untuk repositori yang dibuka di BusyMark.';

  @override
  String get gitSaveIdentityAndCommit => 'Simpan dan commit';

  @override
  String get gitErrorAuthentication => 'Otentikasi Git gagal.';

  @override
  String get gitErrorNetwork => 'Operasi jaringan Git gagal.';

  @override
  String get gitErrorConflict =>
      'Git melaporkan konflik yang belum terselesaikan.';

  @override
  String get gitErrorCommandFailed => 'Perintah Git gagal.';

  @override
  String get syntaxReference => 'Referensi Sintaks';

  @override
  String get syntaxReferenceMarkdownBlocks => 'Blok Markdown';

  @override
  String get syntaxReferenceMarkdownBlocksDescription =>
      'Struktur blok didukung dalam sumber Markdown dan pratinjau.';

  @override
  String get syntaxReferenceInlineFormatting => 'Markdown Sebaris';

  @override
  String get syntaxReferenceInlineFormattingDescription =>
      'Pemformatan yang bisa muncul di dalam paragraf, item daftar, dan sel tabel.';

  @override
  String get syntaxReferenceRawHtmlBlocks => 'Blok HTML Mentah';

  @override
  String get syntaxReferenceRawHtmlBlocksDescription =>
      'Tag HTML tingkat blok yang aman dirender melalui widget pratinjau BusyMark.';

  @override
  String get syntaxReferenceRawHtmlInline => 'Tag Sebaris HTML Mentah';

  @override
  String get syntaxReferenceRawHtmlInlineDescription =>
      'Tag HTML sebaris aman dirender tanpa menampilkan tag literal.';

  @override
  String get syntaxReferenceHeadings => 'Judul';

  @override
  String get syntaxReferenceParagraphs => 'Paragraf';

  @override
  String get syntaxReferenceLists => 'Daftar';

  @override
  String get syntaxReferenceHtmlContainers => 'Kontainer';

  @override
  String get syntaxReferenceHtmlTextBlocks => 'Blok teks';

  @override
  String get syntaxReferenceHtmlFigures => 'Gambar dan ilustrasi';

  @override
  String get syntaxReferenceHtmlPreformatted =>
      'Kode yang telah diformat sebelumnya';

  @override
  String get syntaxReferenceHtmlDisclosure => 'Blok detail yang dapat dibuka';

  @override
  String get syntaxReferenceHtmlDescriptionLists => 'Daftar deskripsi';

  @override
  String get syntaxReferenceHtmlFormattingTags => 'Tag pemformatan';

  @override
  String get syntaxReferenceHtmlInlineCodeTags => 'Tag kode sebaris';

  @override
  String get syntaxReferenceHtmlNeutralInlineTags => 'Tag teks semantik';

  @override
  String get syntaxReferenceSanitizedPreviewDescription =>
      'HTML yang diizinkan diubah menjadi blok pratinjau BusyMark, tidak dirender di browser.';

  @override
  String get syntaxReferenceSourcePreservedDescription =>
      'HTML mentah yang belum diedit disimpan kembali persis seperti teks sumber.';

  @override
  String get syntaxReferenceMarkdownInsideHtmlDescription =>
      'Penanda Markdown di dalam HTML mentah dirender sebagai teks literal.';

  @override
  String get syntaxReferenceBlockedContentDescription =>
      'Skrip, gaya, bingkai, formulir, SVG, MathML, peristiwa, dan atribut tidak aman diblokir.';

  @override
  String get syntaxReferenceSafeUrlsDescription =>
      'Tautan mengizinkan URL http, https, mailto, tel, relatif, dan fragmen; skema yang tidak aman diblokir.';

  @override
  String get syntaxReferenceCategory => 'Kategori';

  @override
  String get syntaxReferenceCategoryHtml => 'HTML';

  @override
  String get syntaxReferenceCategoryDiagramsAndApi => 'Diagram dan API';

  @override
  String get syntaxReferenceCategoryMathematics => 'Matematika';

  @override
  String get syntaxReferenceExample => 'Contoh';

  @override
  String get syntaxReferenceIdentifiers => 'Pengenal dan alias';

  @override
  String get syntaxReferenceScope => 'Cakupan';

  @override
  String get syntaxReferenceLimitation => 'Batasan BusyMark';

  @override
  String get syntaxReferenceOfficialDocumentation => 'Dokumentasi resmi';

  @override
  String get syntaxReferenceScopeWritersideMarkdown =>
      'Hanya Markdown Writerside';

  @override
  String get syntaxReferenceScopeWritersideMarkdownAndXml =>
      'Hanya Markdown Writerside dan XML Writerside';

  @override
  String get syntaxReferenceMarkdownDescription =>
      'Bentuk Markdown utama yang dapat ditulis dan dipratinjau BusyMark.';

  @override
  String get syntaxReferenceParagraphExample => 'Sebuah paragraf teks.';

  @override
  String get syntaxReferenceTableLimitation =>
      'Tabel memakai sintaks garis vertikal GitHub Flavored Markdown.';

  @override
  String get syntaxReferenceHardBreakIdentifiers =>
      'dua spasi di akhir baris, \\, <br>';

  @override
  String get syntaxReferenceHtmlDescription =>
      'BusyMark menerima subset HTML mentah yang terbatas dan aman dalam sumber Markdown.';

  @override
  String get syntaxReferenceDiagramsDescription =>
      'Blok berpagar Mermaid, PlantUML, D2, dan OpenAPI berfungsi dalam sumber Markdown. Pengenal pagar tidak peka huruf besar-kecil dan BusyMark mempertahankan ejaan sumber.';

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
      'Gunakan konten YAML atau JSON berpagar. BusyMark tidak memperlakukan sembarang dokumen YAML atau JSON utuh sebagai referensi OpenAPI.';

  @override
  String get syntaxReferenceSemanticDiagramBlocks =>
      'Blok kode semantik untuk diagram';

  @override
  String get syntaxReferenceSemanticDiagramLimitation =>
      'Bentuk semantik code-block dan src mendukung Mermaid, PlantUML, dan D2, bukan OpenAPI, dan hanya dalam proyek Writerside.';

  @override
  String get syntaxReferenceReferencedDiagramSource =>
      'Sumber diagram yang dirujuk';

  @override
  String get syntaxReferenceReferencedDiagramLimitation =>
      'Jalur harus relatif dan tetap di dalam proyek Writerside yang dibuka; bentuk pagar dengan src hanya untuk Markdown Writerside.';

  @override
  String get syntaxReferenceMathematicsDescription =>
      'BusyMark mendukung ekspresi TeX, bukan dokumen TeX atau LaTeX lengkap.';

  @override
  String get syntaxReferenceInlineMath => 'Matematika sebaris';

  @override
  String get syntaxReferenceGithubMath =>
      'Matematika GitHub dengan dolar dan tanda petik balik';

  @override
  String get syntaxReferenceDisplayMath => 'Matematika tampilan';

  @override
  String get syntaxReferenceMathFence => 'Pagar math';

  @override
  String get syntaxReferenceTexFence => 'Pagar tex';

  @override
  String get syntaxReferenceMathDelimitersLimitation =>
      'BusyMark tidak mengenali \\(...\\) atau \\[...\\] sebagai pembatas matematika Markdown.';

  @override
  String get syntaxReferenceTexFenceLimitation =>
      'Di luar mode Writerside, pagar tex tetap menjadi blok kode biasa.';

  @override
  String get syntaxReferenceWritersideMathElement => 'Elemen math Writerside';

  @override
  String get syntaxReferenceWritersideMathElementLimitation =>
      'Elemen math adalah sintaks semantik Writerside, bukan HTML MathML mentah yang diizinkan.';

  @override
  String get syntaxReferenceSemanticTexBlock => 'Blok kode TeX semantik';

  @override
  String get syntaxReferenceWritersideDescription =>
      'Ekstensi terpilih ini hanya ditafsirkan di dalam proyek Writerside yang dibuka.';

  @override
  String get syntaxReferenceAdmonitionBlockquote => 'Kutipan blok keterangan';

  @override
  String get syntaxReferenceAdmonitionLimitation =>
      'Kutipan blok biasa menjadi tip dalam Markdown Writerside; dalam Markdown biasa tetap menjadi kutipan biasa.';

  @override
  String get syntaxReferenceSemanticAdmonitions => 'Keterangan semantik';

  @override
  String get syntaxReferenceSemanticMarkupLimitation =>
      'Markdown biasa tidak menafsirkan elemen semantik Writerside ini.';

  @override
  String get syntaxReferenceCollapsibleHeading => 'Judul yang dapat diciutkan';

  @override
  String get syntaxReferenceCollapsibleCode =>
      'Pagar kode yang dapat diciutkan';

  @override
  String get syntaxReferenceSemanticCollapsibles =>
      'Konten semantik yang dapat diciutkan';

  @override
  String get syntaxReferenceSemanticCollapsiblesLimitation =>
      'BusyMark mendukung bentuk chapter, procedure, code-block, dan daftar definisi yang dapat diciutkan, bukan seluruh katalog Writerside.';

  @override
  String get syntaxReferenceSemanticCodeBlocks =>
      'Blok kode semantik untuk matematika dan diagram';

  @override
  String get syntaxReferenceVideo => 'Video Writerside';

  @override
  String get syntaxReferenceVideoLimitation =>
      'Video lokal memakai gambar preview-src lokal; sumber yang dihosting harus berupa URL HTTPS YouTube atau Vimeo yang didukung.';

  @override
  String get exportAsPdf => 'Ekspor sebagai PDF';

  @override
  String get pdfExportDescription =>
      'Pilih tata letak halaman untuk PDF yang lengkap dan sempurna.';

  @override
  String get pdfRemoteImagesNote =>
      'Gambar jarak jauh tidak diunduh selama ekspor. Gambar lokal disertakan bila tersedia.';

  @override
  String get pdfPageSize => 'Ukuran halaman';

  @override
  String get pdfPageSizeA4 => 'A4';

  @override
  String get pdfPageSizeLetter => 'Letter';

  @override
  String get pdfOrientation => 'Orientasi';

  @override
  String get pdfPortrait => 'Potret';

  @override
  String get pdfLandscape => 'Lanskap';

  @override
  String get pdfMargins => 'Margin';

  @override
  String get pdfMarginNarrow => 'Sempit';

  @override
  String get pdfMarginNormal => 'Normal';

  @override
  String get pdfMarginWide => 'Lebar';

  @override
  String get pdfIncludePageNumbers => 'Sertakan nomor halaman';

  @override
  String get export => 'Ekspor';

  @override
  String get exportingPdf => 'Mengekspor PDF…';

  @override
  String get fileTypePdf => 'dokumen PDF';

  @override
  String pdfExported(String fileName) {
    return '$fileName telah diekspor.';
  }

  @override
  String pdfExportedWithWarnings(String fileName, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count peringatan',
      one: '1 peringatan',
    );
    return '$fileName diekspor dengan $_temp0.';
  }

  @override
  String get pdfExportUnavailable =>
      'Komponen ekspor PDF tidak ada. Instal ulang BusyMark dan coba lagi.';

  @override
  String get pdfExportTimedOut =>
      'Ekspor PDF memakan waktu terlalu lama dan dihentikan.';

  @override
  String get pdfExportFailed =>
      'BusyMark tidak dapat mengekspor dokumen ini sebagai PDF.';

  @override
  String get visualizationRendering => 'Merender…';

  @override
  String get visualizationStale => 'Menampilkan render terakhir yang valid';

  @override
  String get visualizationShowSource => 'Tampilkan sumber';

  @override
  String get visualizationShowRender => 'Tampilkan render';

  @override
  String get visualizationFitWidth => 'Sesuaikan dengan lebar tampilan';

  @override
  String get visualizationSaveImage => 'Simpan gambar';

  @override
  String get visualizationCopyImage => 'Salin gambar';

  @override
  String get visualizationImageCopied => 'Gambar disalin';

  @override
  String get visualizationOpenApiReference => 'Buka Referensi API';

  @override
  String get visualizationValid => 'Valid';

  @override
  String get visualizationInvalid => 'Tidak valid';

  @override
  String get visualizationServers => 'Server';

  @override
  String get visualizationPaths => 'Jalur';

  @override
  String get visualizationOperations => 'Operasi';

  @override
  String get visualizationTags => 'Tag';

  @override
  String get visualizationNoOperations => 'Tidak ada operasi yang cocok';

  @override
  String get visualizationSearchOperations => 'Cari operasi';

  @override
  String get visualizationRenderFailed =>
      'Visualisasi ini tidak dapat dirender.';

  @override
  String get visualizationRetry => 'Coba lagi';

  @override
  String visualizationSaved(String fileName) {
    return '$fileName disimpan';
  }

  @override
  String get shortcutExportPdfDescription =>
      'Ekspor dokumen aktif atau modul Writerside sebagai PDF.';

  @override
  String get instances => 'Instance';

  @override
  String get newInstance => 'Instance baru';

  @override
  String get newTocLibrary => 'Pustaka TOC baru';

  @override
  String get editInstance => 'Ubah instance';

  @override
  String get openTocFile => 'Buka file TOC';

  @override
  String get createInstance => 'Buat instance';

  @override
  String get createTocLibrary => 'Buat pustaka TOC';

  @override
  String get instanceContent => 'Isi';

  @override
  String get instanceContentSource => 'Buat dari';

  @override
  String get emptyInstance => 'Instance kosong';

  @override
  String get markdownFiles => 'File Markdown lokal';

  @override
  String get chooseMarkdownFolder => 'Pilih folder Markdown';

  @override
  String get errorWritersideInstanceImportSourceRequired =>
      'Pilih folder yang berisi file Markdown.';

  @override
  String get instanceAppearance => 'Tampilan';

  @override
  String get instanceColor => 'Warna ikon';

  @override
  String get instanceVersion => 'Versi';

  @override
  String instanceVersionInherited(String version) {
    return 'Versi proyek adalah $version jika kolom ini kosong.';
  }

  @override
  String get instanceWebPath => 'Jalur web';

  @override
  String get instanceStatus => 'Status';

  @override
  String get instanceStatusRelease => 'Rilis';

  @override
  String get instanceStatusEap => 'Akses awal';

  @override
  String get instanceStatusDeprecated => 'Tidak digunakan lagi';

  @override
  String get allowSearchEngineIndexing => 'Izinkan pengindeksan mesin pencari';

  @override
  String get allowSearchEngineIndexingDescription =>
      'Izinkan mesin pencari eksternal mengindeks keluaran ini.';

  @override
  String get offlineArtifact => 'Artefak offline';

  @override
  String get offlineArtifactDescription =>
      'Gabungkan sumber daya sehingga dokumentasi yang dibuat bersifat mandiri.';

  @override
  String get instanceOutputSettings => 'Pengaturan keluaran';

  @override
  String get markdownImportSource => 'Sumber Markdown';

  @override
  String get markdownImportFiles => 'File Markdown';

  @override
  String get selectNone => 'Jangan pilih apa pun';

  @override
  String markdownFilesFound(int count) {
    return 'Ditemukan $count file Markdown';
  }

  @override
  String get noMarkdownFilesFound =>
      'Tidak ada file Markdown yang ditemukan di direktori ini.';

  @override
  String get copyReferencedMedia => 'Salin media yang dirujuk';

  @override
  String get copyReferencedMediaDescription =>
      'Salin gambar dan video lokal yang direferensikan oleh file yang dipilih sambil mempertahankan jalur relatif.';

  @override
  String get instanceIdRenameWarningTitle => 'Ganti nama ID instance?';

  @override
  String instanceIdRenameWarning(String oldId, String newId) {
    return 'BusyMark akan mengganti nama file .tree dan memperbarui referensi proyek Writerside dari “$oldId” menjadi “$newId”. Skrip publikasi tidak diubah dan harus diperbarui secara terpisah.';
  }

  @override
  String get renameAndUpdateReferences => 'Ganti nama dan perbarui referensi';

  @override
  String get tocLibraryDescription =>
      'Pustaka TOC menyimpan bagian yang dapat digunakan kembali dan tidak menghasilkan keluarannya sendiri.';

  @override
  String get defaultTocLibraryName => 'TOC yang dibagikan';

  @override
  String get instanceColorAutomatic => 'Otomatis';

  @override
  String get instanceColorBlue => 'Biru';

  @override
  String get instanceColorGreen => 'Hijau';

  @override
  String get instanceColorOrange => 'Oranye';

  @override
  String get instanceColorPurple => 'Ungu';

  @override
  String get instanceColorRed => 'Merah';

  @override
  String get instanceColorTeal => 'Teal';

  @override
  String get instanceColorYellow => 'Kuning';

  @override
  String get errorWritersideInstanceNameRequired => 'Masukkan nama instance.';

  @override
  String errorWritersideInstanceIdExists(String id) {
    return 'Sebuah instance dengan ID “$id” sudah ada.';
  }

  @override
  String errorWritersideInstanceTreeExists(String path) {
    return 'Pohon instance sudah ada: $path';
  }

  @override
  String errorWritersideInstanceImportSourceMissing(String path) {
    return 'Direktori sumber Markdown tidak ada: $path';
  }

  @override
  String get errorWritersideInstanceImportSelectionRequired =>
      'Pilih setidaknya satu file Markdown untuk diimpor.';

  @override
  String errorWritersideInstanceImportFileInvalid(String path) {
    return 'Ini bukan file Markdown yang dapat dibaca di dalam sumber yang dipilih: $path';
  }

  @override
  String errorWritersideInstanceImportTargetExists(String path) {
    return 'Impor akan menimpa file proyek yang sudah ada: $path';
  }

  @override
  String get errorWritersideInstanceFilesChanged =>
      'File instance diubah pada disk. Tinjau dan coba lagi.';

  @override
  String errorWritersideInstanceRollbackFailed(String paths) {
    return 'BusyMark tidak dapat sepenuhnya mengembalikan perubahan instance. Tinjau file ini sebelum melanjutkan: $paths';
  }

  @override
  String get errorWritersideInstanceLibraryImport =>
      'Pustaka TOC tidak dapat mengimpor topik Markdown.';

  @override
  String get errorWritersideInstanceWebPathInvalid =>
      'Jalur web harus berupa satu baris.';

  @override
  String get errorWritersideInstanceConfigurationInvalid =>
      'Konfigurasi instance Writerside tidak valid. Perbaiki diagnosisnya dan coba lagi.';

  @override
  String get errorWritersideInstanceTemporaryFile =>
      'BusyMark tidak dapat melakukan perubahan instance dengan aman.';

  @override
  String diagnosticWritersideTreeInvalidStatus(String status) {
    return 'Status instance “$status” tidak dikenal. Gunakan release, eap, atau deprecated.';
  }

  @override
  String diagnosticWritersideDuplicateInstanceId(String id) {
    return 'ID instance “$id” digunakan oleh lebih dari satu file pohon.';
  }

  @override
  String get diagnosticWritersideBuildProfilesInvalidRoot =>
      'buildprofiles.xml harus memiliki elemen root <buildprofiles>.';

  @override
  String diagnosticWritersideBuildProfilesInvalidBoolean(
    String name,
    String value,
  ) {
    return 'Nilai $name “$value” harus true atau false.';
  }

  @override
  String get diagnosticWritersideBuildProfileMissingInstance =>
      'Elemen <build-profile> harus menentukan ID instance.';

  @override
  String get diagnosticWritersideTreeInvalidInclude =>
      'Pohon <include> harus menentukan atribut from dan element-id.';

  @override
  String get diagnosticWritersideTreeMissingSnippetId =>
      'Pohon <snippet> harus menentukan id.';

  @override
  String get diagnosticWritersideTreeInvalidCrossInstanceReference =>
      'Referensi TOC lintas instance harus menentukan ref dan in.';

  @override
  String get diagnosticWritersideTreeConflictingTargets =>
      'Elemen TOC tidak dapat menargetkan lebih dari satu topik, referensi, tautan, atau pengalihan.';

  @override
  String diagnosticWritersideTreeDuplicateElementId(String id) {
    return 'ID elemen pohon “$id” dideklarasikan lebih dari satu kali.';
  }

  @override
  String get diagnosticWritersideInstanceGroupsInvalidRoot =>
      'File grup instance harus memiliki elemen root <instance-groups>.';

  @override
  String get diagnosticWritersideInstanceGroupInvalid =>
      'Grup instance harus menentukan id dan daftar instance yang tidak kosong.';

  @override
  String diagnosticWritersideInstanceGroupDuplicateId(String id) {
    return 'ID grup instance “$id” dideklarasikan lebih dari satu kali.';
  }

  @override
  String diagnosticWritersideExternalTreeInclude(
    String source,
    String id,
    String origin,
  ) {
    return 'TOC menyertakan “$source#$id” milik modul eksternal “$origin” dan tidak dapat diperluas di ruang kerja ini.';
  }

  @override
  String diagnosticWritersideTreeIncludeElementMissing(
    String source,
    String id,
  ) {
    return 'Elemen pohon “$id” tidak ada di pohon terdaftar “$source”.';
  }

  @override
  String diagnosticWritersideTreeCircularInclude(String source, String id) {
    return 'Include tree “$source#$id” membuat siklus.';
  }

  @override
  String diagnosticWritersideUnknownInstanceGroup(String group) {
    return 'Kondisi instance mereferensikan grup yang tidak diketahui “@$group”.';
  }

  @override
  String diagnosticWritersideReferenceInstanceMissing(String instance) {
    return 'Referensi lintas-instance menargetkan instance yang tidak diketahui “$instance”.';
  }

  @override
  String diagnosticWritersideReferenceTopicMissing(
    String topic,
    String instance,
  ) {
    return 'Topik “$topic” tidak ada dalam instance yang dirujuk “$instance”.';
  }

  @override
  String get download => 'Unduh';

  @override
  String get exportWritersideAsPdf => 'Ekspor Writerside sebagai PDF';

  @override
  String get writersidePdfContent => 'Ekspor konten';

  @override
  String get writersidePdfPage => 'Halaman';

  @override
  String get exportingWritersidePdf => 'Mengekspor PDF Writerside…';

  @override
  String get ai => 'AI';

  @override
  String get aiLocalOllama => 'Ollama lokal';

  @override
  String get aiDisabled => 'Dinonaktifkan';

  @override
  String get aiExplicitEditingDescription =>
      'Pengeditan AI bersifat eksplisit. BusyMark hanya mengirimkan konteks yang ditampilkan untuk penyedia yang dipilih dan tidak pernah menerapkan proposal tanpa peninjauan.';

  @override
  String get aiProvider => 'Penyedia AI';

  @override
  String get aiDefaultProvider => 'Penyedia bawaan';

  @override
  String get aiConfigureProvider => 'Konfigurasikan penyedia';

  @override
  String get aiChooseProvider => 'Pilih penyedia AI';

  @override
  String get aiOllamaEndpoint => 'Titik akhir Ollama';

  @override
  String get aiOllamaModel => 'Model Ollama';

  @override
  String get aiTestConnection => 'Uji koneksi';

  @override
  String get aiTestingConnection => 'Menguji…';

  @override
  String aiConnectionReady(int count) {
    return 'Terhubung. $count model terinstal ditemukan.';
  }

  @override
  String get aiNoModels => 'Tidak ada model yang dipilih.';

  @override
  String get aiConnectionFailed =>
      'BusyMark tidak dapat memverifikasi pembuatan teks AI.';

  @override
  String get aiConfigureFirst =>
      'Aktifkan penyedia AI dan verifikasi model di Pengaturan → AI.';

  @override
  String get aiEditWithAi => 'Edit dengan AI';

  @override
  String get aiRefineWithAi => 'Sempurnakan dengan AI';

  @override
  String get aiInstruction => 'Petunjuk';

  @override
  String get aiChangeTarget => 'Apa yang mungkin berubah';

  @override
  String get aiSharedContext => 'Konteks dibagikan dengan AI';

  @override
  String get aiTargetSelection => 'Konten yang dipilih';

  @override
  String get aiTargetInsertAfterBlock => 'Sisipkan setelah blok saat ini';

  @override
  String get aiTargetCurrentBlock => 'Blok saat ini';

  @override
  String get aiTargetCurrentSection => 'Bagian saat ini';

  @override
  String get aiTargetCompleteDocument => 'Dokumen lengkap';

  @override
  String get aiContextNone => 'Tidak ada konteks dokumen';

  @override
  String get aiContextSelection => 'Konten yang dipilih';

  @override
  String get aiContextCurrentBlock => 'Blok saat ini';

  @override
  String get aiContextCurrentSection => 'Bagian saat ini';

  @override
  String get aiContextCompleteDocument => 'Dokumen lengkap';

  @override
  String get aiGenerating => 'Membuat proposal…';

  @override
  String get aiProposal => 'Proposal AI';

  @override
  String get aiGenerateProposal => 'Hasilkan proposal';

  @override
  String aiContextDisclosure(int count) {
    return 'Penyedia yang dipilih akan menerima $count karakter dari konteks yang ditampilkan.';
  }

  @override
  String get aiOriginal => 'Asli';

  @override
  String get aiSuggested => 'Disarankan';

  @override
  String get aiApplyProposal => 'Terapkan proposal';

  @override
  String aiTokenUsage(int input, int output) {
    return '$input token masukan · $output token keluaran';
  }

  @override
  String get aiStaleProposal =>
      'Dokumen berubah saat proposal ini dibuat. Jalankan aksinya lagi.';

  @override
  String get gitAiStagedChangesChanged =>
      'Perubahan yang di-stage berubah saat pesan commit ini dibuat. Jalankan aksinya lagi.';

  @override
  String get aiViewContext => 'Lihat konteks yang dikirim';

  @override
  String get aiReviewExactContent => 'Tinjau konten yang sebenarnya';

  @override
  String get aiContentToChange => 'Konten untuk diubah';

  @override
  String get aiContentSentToAi => 'Konten dikirim ke AI';

  @override
  String get aiApiKey => 'Kunci API';

  @override
  String get aiApiKeyStoredHint =>
      'Kunci disimpan di penyimpanan kredensial sistem';

  @override
  String get aiApiKeyEnterHint => 'Masukkan kunci API penyedia';

  @override
  String get aiReplaceApiKey => 'Ganti kunci API';

  @override
  String get aiSaveApiKey => 'Simpan kunci API dengan aman';

  @override
  String get aiRemoveApiKey => 'Hapus kunci API yang disimpan';

  @override
  String get aiCredentialSaved =>
      'Kunci API disimpan di penyimpanan kredensial sistem.';

  @override
  String get aiCredentialRemoved => 'Kunci API yang disimpan telah dihapus.';

  @override
  String get aiModelRouting => 'Perutean model';

  @override
  String get aiAutomaticRouting => 'Otomatis berdasarkan tugas';

  @override
  String get aiFixedModelRouting => 'Gunakan model yang dipilih';

  @override
  String get aiPreferredModel => 'Model pilihan';

  @override
  String get aiModel => 'Model';

  @override
  String aiUsageThisMonth(int requests, int input, int output) {
    return '$requests permintaan · $input token masukan · $output token keluaran';
  }

  @override
  String aiCloudConsentTitle(String provider) {
    return 'Kirim konten ke $provider?';
  }

  @override
  String aiCloudConsentEnable(String provider) {
    return 'Aktifkan $provider';
  }

  @override
  String get aiCloudConsentMessage =>
      'Hanya konten yang ditampilkan di setiap dialog tinjauan AI yang dikirim. Permintaan tidak disimpan, proposal memerlukan peninjauan, dan kunci API disimpan di penyimpanan kredensial sistem Linux.';

  @override
  String aiCloudConsentRequired(String provider) {
    return 'Konfirmasikan pembagian data $provider di Pengaturan → AI terlebih dahulu.';
  }

  @override
  String aiGenerationVerified(String model, int count) {
    return 'Pembuatan teks diverifikasi dengan $model. Tersedia $count model yang kompatibel.';
  }

  @override
  String get aiColdStartObserved => 'Cold start model lokal terdeteksi.';

  @override
  String get aiNoCompatibleModels =>
      'Tidak tersedia model pembuatan teks yang kompatibel.';

  @override
  String get aiEnableProvider => 'Aktifkan penyedia AI terlebih dahulu.';

  @override
  String get aiDraftCommitMessage => 'Draf pesan commit';

  @override
  String get aiDrafting => 'Menyusun…';

  @override
  String get aiDraftWithAi => 'Draf dengan AI';

  @override
  String get generateOrUpdateMarkdownToc =>
      'Menghasilkan/memperbarui daftar isi';

  @override
  String get markdownTocTitle => 'Daftar isi';

  @override
  String markdownTocUpdated(int count) {
    return 'Daftar isi diperbarui dengan $count entri.';
  }

  @override
  String get markdownTocNoHeadings =>
      'Tambahkan setidaknya satu judul bagian sebelum membuat daftar isi.';

  @override
  String get markdownTocMalformedMarkers =>
      'Penanda daftar isi BusyMark hilang, duplikat, atau tidak berurutan.';

  @override
  String diagnosticMarkdownHeadingSkippedLevel(int level, int previousLevel) {
    return 'Tingkat judul $level mengikuti tingkat $previousLevel; tinjau bagian yang bersarang.';
  }

  @override
  String get diagnosticMarkdownLinkEmptyText =>
      'Teks tautan kosong; berikan nama yang dapat diakses yang menjelaskan tujuannya.';

  @override
  String diagnosticMarkdownLinkReviewText(String text) {
    return 'Tinjau apakah teks tautan “$text” menjelaskan tujuannya dalam konteks.';
  }

  @override
  String get diagnosticMarkdownTableEmptyHeader =>
      'Sel header tabel harus mengidentifikasi kolomnya; lengkapi setiap header kosong.';

  @override
  String get mathRenderFailed => 'Ekspresi matematika tidak dapat dirender.';

  @override
  String get inlineMath => 'Matematika sebaris';

  @override
  String get displayMath => 'Matematika tampilan';

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
