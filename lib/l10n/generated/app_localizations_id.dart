// ignore_for_file: text_direction_code_point_in_literal, text_direction_code_point_in_comment

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get notesNewFromRetainedText => 'Catatan baru dari teks tersimpan';

  @override
  String get notesAccountThrottled =>
      'Nextcloud meminta jeda. Tunggu sebelum mulai masuk lagi.';

  @override
  String get notesSettingsRefreshing =>
      'Menyegarkan Notes setelah pembaruan pengaturan dikonfirmasi';

  @override
  String get notesExportOperationFailed =>
      'Ekspor gagal sebelum diterbitkan. Periksa sumber dan tujuan, lalu ekspor lagi.';

  @override
  String get notesRecoveryCreatedNotOpened =>
      'Catatan yang dipulihkan sudah tersimpan, tetapi gagal dibuka. Selesaikan perubahan editor atau properti yang tertunda, lalu buka catatan yang sudah ada ini.';

  @override
  String get notesSettingsPendingNotes =>
      'Catatan tertunda, konflik, atau pembuatan yang belum pasti menghalangi perubahan ini. Sinkronkan atau tinjau di Notes, lalu simpan lagi draf pengaturan yang dipertahankan.';

  @override
  String get notesSettingsPendingAttachments =>
      'Operasi lampiran tertunda menghalangi perubahan ini. Tinjau lampiran di Notes, lalu simpan lagi draf pengaturan yang dipertahankan.';

  @override
  String get notesAccountServerAddress =>
      'Gunakan alamat HTTPS kanonis Nextcloud, lalu masuk lagi. Alamat atau pengalihan tidak dapat diverifikasi.';

  @override
  String get notesAccountUnsupported =>
      'Notes tidak tersedia atau API tidak didukung. Aktifkan Nextcloud Notes dengan API versi utama 1, minor 4 atau lebih baru.';

  @override
  String get notesAccountAuthorizeAgain =>
      'Nextcloud menolak kredensial. Otorisasi ulang atau hubungkan kembali akun ini.';

  @override
  String get notesAccountCheckForbidden =>
      'Nextcloud melarang pemeriksaan kemampuan Notes. Minta administrator mengizinkannya, lalu coba lagi.';

  @override
  String get notesAccountMalformed =>
      'Respons Nextcloud tidak dapat diverifikasi. Periksa pemasangan server, lalu masuk lagi.';

  @override
  String get notesAccountTimedOut =>
      'Waktu masuk habis. Mulai lagi dan selesaikan otorisasi di peramban.';

  @override
  String get notesAccountBrowserUnavailable =>
      'Peramban sistem tidak dapat dibuka. Periksa peramban bawaan, lalu masuk lagi.';

  @override
  String get notesAccountNetwork =>
      'Nextcloud tidak dapat dijangkau. Periksa koneksi dan server, lalu masuk lagi.';

  @override
  String get notesAccountRejected =>
      'Nextcloud menolak permintaan kemampuan. Periksa akses bersama administrator, lalu coba lagi.';

  @override
  String get notesAccountFailed =>
      'Penyiapan akun tidak selesai. Coba masuk lagi.';

  @override
  String get notesTransferSourceChanged =>
      'Sumber berubah setelah ditinjau. Tinjau berkas saat ini atau buat snapshot baru sebelum mencoba lagi.';

  @override
  String get notesTransferUnreadable =>
      'Sumber tidak dapat dibaca. Periksa akses berkas atau folder, lalu tinjau lagi.';

  @override
  String get notesTransferInvalidSnapshot =>
      'Snapshot tidak valid atau tidak didukung. Pilih snapshot BusyMark Notes yang valid atau sumber Markdown.';

  @override
  String get notesTransferMediaLimit =>
      'Media melebihi batas impor. Perkecil media item terkait sebelum meninjaunya lagi.';

  @override
  String get notesTransferUnsafeSource =>
      'Sumber berisi jalur tidak aman. Pilih berkas di dalam folder sumber, lalu tinjau lagi.';

  @override
  String get notesTransferDestination =>
      'Ekspor tidak dapat ditulis. Periksa akses dan ruang kosong di tujuan, lalu ekspor lagi.';

  @override
  String get notesTransferOperationFailed =>
      'Transfer tidak selesai. Tinjau item terkait dan coba lagi. Item yang sudah diimpor tetap tersimpan.';

  @override
  String get notesExportPublishedWithOmissions =>
      'Ekspor tersedia dengan beberapa bagian terlewat';

  @override
  String get notesBatchUnchanged => 'Nilai yang diminta sudah ditetapkan.';

  @override
  String get notesBatchReadOnly =>
      'Catatan ini hanya-baca. Properti terlindungi tidak dapat diubah; Favorit tetap diizinkan.';

  @override
  String get notesBatchReviewChanged =>
      'Catatan berubah setelah ditinjau. Tinjau keadaan saat ini sebelum menerapkan tindakan lagi.';

  @override
  String get notesBatchMissing =>
      'Catatan ini tidak lagi tersedia. Segarkan daftar dan tinjau sasaran lagi.';

  @override
  String get notesBatchStorage =>
      'Penyimpanan lokal gagal. Periksa penyimpanan dan coba item ini lagi; item yang berhasil tetap tersimpan.';

  @override
  String get notesRemoteReviewChanged =>
      'Catatan server berubah. Draf penggabungan Anda dipertahankan. Tinjau perbandingan terbaru dan pilih penyelesaian lagi.';

  @override
  String get notesReviewRemote => 'Saya telah meninjau versi server saat ini';

  @override
  String get wsModuleCapsNotPublished =>
      'Kapitalisasi modul tidak diterbitkan.';

  @override
  String get wsTitleOverridesAction => 'Judul instans dan daftar isi…';

  @override
  String get wsHeadingNotPublished => 'Tidak diterbitkan oleh pembuat ini.';

  @override
  String get wsMarkdownInstanceTitleLimitation =>
      'Builder yang dipatok tidak menerbitkan judul instans pada topik Markdown. Markup yang ada tetap disimpan; periksa di Sumber.';

  @override
  String get wsTopicIdentity => 'ID topik';

  @override
  String get wsElementAnchor => 'Jangkar elemen';

  @override
  String get wsHeadingText => 'Teks judul';

  @override
  String get wsDefaultTitle => 'Judul bawaan';

  @override
  String get wsTopicNavigation => 'Navigasi topik';

  @override
  String get wsHeadingOptions => 'Atribut judul';

  @override
  String get wsDocumentOptions => 'Pengaturan dokumen';

  @override
  String get wsSettingsPresent => 'Ada pengaturan tertulis';

  @override
  String get wsTitleOverrideExplanation =>
      'Mengganti judul yang diterbitkan; teks judul tidak berubah.';

  @override
  String get wsIgnoreVariables => 'Perlakukan variabel sebagai teks literal';

  @override
  String get wsIgnoreVariablesExplanation =>
      'Jika diaktifkan, teks yang menyerupai variabel tidak diganti.';

  @override
  String get wsInstanceSelection => 'Instans bantuan';

  @override
  String get wsInstanceExplanation =>
      'Pilih keluaran bantuan dengan nama, grup, daftar, pengecualian, atau ekspresi.';

  @override
  String get wsFilterExplanation =>
      'Menyaring konten pakai ulang menurut kriteria; tidak memilih instans bantuan.';

  @override
  String get wsContextHelp => 'ID bantuan kontekstual';

  @override
  String get wsCapitalization => 'Kapitalisasi';

  @override
  String get wsLibraryTopic => 'Topik pustaka';

  @override
  String get wsLastModified => 'Terakhir diubah';

  @override
  String get wsMissingTopicHeading =>
      'Tidak ada H1 topik. Tambahkan di Sumber.';

  @override
  String get wsMultipleTopicHeadings =>
      'H1 pertama menentukan judul topik. H1 berikutnya adalah judul terpisah.';

  @override
  String get wsTopicIdentityMismatch =>
      'id akar berbeda dari ID berdasarkan nama berkas. Gunakan Ubah nama berkas topik atau periksa Sumber.';

  @override
  String get wsUnsupportedProperties =>
      'Atribut yang tidak didukung tetap disimpan. Periksa di Sumber.';

  @override
  String get wsGeneratedAnchor =>
      'Jangkar yang dihasilkan; memasukkan nilai membuat penimpaan.';

  @override
  String get wsHeadingBuilderLimitation =>
      'Builder yang dipatok tidak menerbitkan atribut H1. Atribut milik judul, bukan akar XML.';

  @override
  String get closeOtherTabs => 'Tutup tab lainnya';

  @override
  String get tocTopicFromTemplate => 'Topik dari Templat...';

  @override
  String get tocSaveAsTemplate => 'Simpan sebagai Templat';

  @override
  String get tocTemplateDialog => 'Buat Topik dari Templat';

  @override
  String get tocTemplatesEditor => 'Templat File dan Kode';

  @override
  String get tocEditTemplates => 'Edit templat...';

  @override
  String get tocCreateCustomTemplate => 'Buat templat khusus...';

  @override
  String get tocTemplateCreated => 'Templat dibuat';

  @override
  String get tocTemplateDefault => 'Bawaan';

  @override
  String get tocTemplateCustom => 'Khusus';

  @override
  String get tocTemplateFilename => 'Nama file:';

  @override
  String get tocTemplateMarkdown => 'Markdown (.md)';

  @override
  String get tocTemplateXml => 'XML (.topic)';

  @override
  String get tocTemplatesInternal => 'Internal';

  @override
  String get tocTemplateUnnamed => 'Tanpa nama';

  @override
  String get tocTemplateNew => 'Templat baru...';

  @override
  String get tocTemplateName => 'Nama:';

  @override
  String get tocTemplateExtension => 'Ekstensi:';

  @override
  String get tocTemplateLoadError =>
      'Tidak dapat memuat templat. Templat yang ada tidak diubah.';

  @override
  String get tocTemplateSaveError =>
      'Tidak dapat menyimpan templat. Edit Anda masih tersedia di sini.';

  @override
  String get tocTemplateConflict =>
      'Templat berubah di jendela lain. Batalkan dan buka kembali editor.';

  @override
  String get tocTemplateDuplicateName =>
      'Templat dengan nama dan ekstensi ini sudah ada.';

  @override
  String get tocTemplateFormat => 'Format:';

  @override
  String get tocTemplateReset => 'Atur ulang';

  @override
  String get tocTemplateRetry => 'Coba lagi';

  @override
  String tocRemoveElementsDialog(int count) {
    return 'Hapus $count Elemen Daftar Isi';
  }

  @override
  String get tocRemoveElementsRetainFiles =>
      'Berkas sumber yang terkait dengan elemen daftar isi ini tidak akan dihapus.';

  @override
  String get tocOk => 'OK';

  @override
  String get tocSelectExistingTopic =>
      'Pilih topik untuk ditambahkan ke instans saat ini';

  @override
  String get tocGroupName => 'Nama grup';

  @override
  String get tocMoveLineUp => 'Pindahkan baris ke atas';

  @override
  String get tocMoveLineDown => 'Pindahkan baris ke bawah';

  @override
  String get tocEmptyMdTopic => 'Topik MD kosong';

  @override
  String get tocEmptyXmlTopic => 'Topik XML kosong';

  @override
  String get tocCopySpecial => 'Salin khusus';

  @override
  String tocCopyFileName(String name) {
    return 'Nama berkas topik \'$name\'';
  }

  @override
  String get tocCopyFilePath => 'Jalur berkas topik';

  @override
  String tocCopyTopicTitle(String title) {
    return 'Judul topik \'$title\'';
  }

  @override
  String tocCopyElementId(String id) {
    return 'ID elemen daftar isi \'$id\'';
  }

  @override
  String get tocCopyFileNameUnavailable => 'Nama berkas topik';

  @override
  String get tocCopyTopicTitleUnavailable => 'Judul topik';

  @override
  String get tocCopyElementIdUnavailable => 'ID elemen daftar isi';

  @override
  String get tocEditTitleAction => 'Edit judul...';

  @override
  String get tocEditTitleDialog => 'Edit judul';

  @override
  String get tocRemoveElementAction => 'Hapus elemen daftar isi...';

  @override
  String get tocSetHomePage => 'Jadikan halaman utama';

  @override
  String tocGoToElement(String fileName) {
    return 'Buka elemen daftar isi di \'$fileName\'';
  }

  @override
  String get tocSynchronize => 'Sinkronkan daftar isi dan editor';

  @override
  String get tocEmptyGroupAction => 'Grup kosong';

  @override
  String get tocNewEmptyGroup => 'Grup kosong baru';

  @override
  String get tocGroupAction => 'Kelompokkan';

  @override
  String get tocNewGroup => 'Grup baru';

  @override
  String get tocSortChildren => 'Urutkan subtopik berdasarkan abjad';

  @override
  String get tocLinkTopicFiles => 'Tautkan berkas topik ke daftar isi...';

  @override
  String get addLocalMarkdownFiles => 'Tambahkan Berkas Markdown Lokal';

  @override
  String get tocTitleField => 'Judul daftar isi:';

  @override
  String get tocTopicTitleField => 'Judul topik:';

  @override
  String get tocAdvancedSettings => 'Pengaturan lanjutan';

  @override
  String tocInstanceTitleField(String instanceId) {
    return 'Judul untuk \'$instanceId\':';
  }

  @override
  String get tocOnlyTitleField => 'Judul khusus daftar isi:';

  @override
  String get tocInstanceTitleExplanation =>
      'Hanya digunakan untuk instance saat ini. Secara default, diwarisi dari judul topik.';

  @override
  String get tocOnlyTitleExplanation =>
      'Hanya digunakan dalam daftar isi. Secara default, diwarisi dari judul topik atau judul khusus instance jika ditetapkan. Penjelasan judul tersedia';

  @override
  String get tocTitleDocumentationLink => 'di sini';

  @override
  String get tocFindUsages => 'Cari';

  @override
  String get tocRefactorMenu => 'Refaktor';

  @override
  String get tocSafeDelete => 'Hapus dengan aman';

  @override
  String get tocDuplicate => 'Duplikat';

  @override
  String get tocDuplicateFilename => 'Nama berkas topik:';

  @override
  String get tocDuplicateDialog => 'Duplikat topik';

  @override
  String get pdfTitlePage => 'Halaman judul';

  @override
  String get pdfIncludeTitlePage => 'Sertakan halaman judul';

  @override
  String get pdfTitlePageNote =>
      'Halaman ini tidak memiliki header, footer, atau nomor halaman yang terlihat.';

  @override
  String get pdfTitlePageTitle => 'Judul';

  @override
  String get pdfTitlePageSubtitle => 'Subjudul';

  @override
  String get pdfTitlePageAuthor => 'Penulis';

  @override
  String get pdfTitlePageOrganization => 'Organisasi';

  @override
  String get pdfTitlePageVersion => 'Versi';

  @override
  String get pdfTitlePageDate => 'Tanggal';

  @override
  String get pdfTitlePageTitleRequired => 'Masukkan judul untuk halaman judul.';

  @override
  String get pdfTocSectionNote =>
      'Dimulai pada halaman terpisah dan dapat mencakup beberapa halaman.';

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
  String get copyPlainText => 'Salin sebagai teks biasa';

  @override
  String get clipboardCopyFailed =>
      'Konten yang dipilih tidak dapat disalin ke papan klip.';

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
      'Sesuaikan pintasan keyboard aplikasi';

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
  String get wordWrapDescription =>
      'Bungkus baris panjang agar sesuai dengan lebar editor alih-alih menggulir secara horizontal.';

  @override
  String get editorFontSize => 'Ukuran font editor';

  @override
  String get validateOnEdit => 'Validasi saat mengedit';

  @override
  String get clearRecentWorkspaces => 'Hapus riwayat terbaru';

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
  String get settingsEditingButtonsSectionTitle => 'Tombol pengeditan';

  @override
  String get spellingDictionaries => 'Kamus ejaan';

  @override
  String get spellingDictionariesDescription => 'Instal dan kelola kamus ejaan';

  @override
  String get settingsDictionariesSectionTitle => 'Kamus';

  @override
  String get availableSpellingDictionaries => 'Kamus yang tersedia';

  @override
  String get customSpellingDictionaries => 'Kamus kustom';

  @override
  String get spellingDictionaryProblems => 'Masalah kamus';

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
  String get insertBlankLine => 'Sisipkan baris kosong';

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
  String get toc => 'Daftar Isi';

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
  String get newSiblingTopic => 'Topik baru';

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
  String get removeTocElements => 'Hapus elemen TOC';

  @override
  String get reviewUsages => 'Tinjau penggunaan';

  @override
  String get deleteTopicFile => 'Hapus file topik';

  @override
  String get removeAction => 'Hapus';

  @override
  String topicRemovalSummary(String topic) {
    return 'Hapus elemen daftar isi “$topic”? File sumber yang terkait dengan daftar isi tidak akan dihapus.';
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
  String get topicIsHomePageRemovalWarning =>
      'Topik ini adalah halaman utama instance ini. Pilih halaman utama lain sebelum menghapusnya dari daftar isi.';

  @override
  String get newHomePage => 'Halaman utama baru';

  @override
  String get chooseHomePage => 'Pilih halaman utama';

  @override
  String get noHomePageReplacement =>
      'Tambahkan atau tautkan topik lain yang memenuhi syarat ke instance ini sebelum menghapus halaman utamanya.';

  @override
  String get topicIsStartPageRemovalWarning =>
      'Topik ini adalah halaman utama sebuah instance. Tetapkan halaman utama lain sebelum menghapus file sumbernya.';

  @override
  String topicUsagesCount(int count) {
    return '$count penggunaan ditemukan.';
  }

  @override
  String get noBreakingTopicUsages => 'Tidak ditemukan referensi yang rusak.';

  @override
  String get topicUsagesFound =>
      'BusyMark menemukan referensi berikut untuk topik ini.';

  @override
  String get topicUsageTocElements => 'elemen TOC';

  @override
  String get topicUsageStartPages => 'Halaman utama';

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
  String get setRedirectTo => 'Alihkan ke:';

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
  String get preview => 'Pratinjau';

  @override
  String get topicRenamePreviewTitle => 'Pratinjau penggantian nama';

  @override
  String topicRenamePathChange(String oldPath, String newPath) {
    return 'Jalur: $oldPath → $newPath';
  }

  @override
  String topicRenameIdChange(String oldId, String newId) {
    return 'ID topik: $oldId → $newId';
  }

  @override
  String topicRenameUrlChange(String instance, String oldName, String newName) {
    return 'Instans $instance: $oldName → $newName';
  }

  @override
  String get topicRenameAffectedFiles => 'File yang terpengaruh';

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
  String get workspaceSearchIncomplete =>
      'Hanya sebagian hasil yang ditampilkan. Tampilkan lebih banyak atau persempit pencarian.';

  @override
  String get workspaceSearchShowMore => 'Tampilkan lebih banyak hasil';

  @override
  String get workspaceSearchSkippedFiles =>
      'Pencarian belum lengkap. Berkas ini melebihi 1 MiB atau tidak dapat dibaca:';

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
  String workspaceErrorRecentWorkspaceUpdateFailed(String error) {
    return 'Tidak dapat memperbarui item terbaru: $error.';
  }

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
    return 'Halaman utama $topic tidak dapat dihapus. Pilih halaman utama lain terlebih dahulu.';
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
  String errorWritersideTopicRenameIncompleteProjectIndex(
    String module,
    String count,
    String paths,
  ) {
    return 'Penggantian nama tidak dapat memperbarui setiap referensi proyek dengan aman karena $count file topik di modul $module tidak diurai: $paths';
  }

  @override
  String get errorWritersideTopicRenameProjectBuffersDirty =>
      'File proyek Writerside memiliki perubahan yang belum disimpan. Selesaikan perubahan tersebut dan siapkan pratinjau penggantian nama baru.';

  @override
  String get errorWritersideTopicRenameProjectInventoryChanged =>
      'Kumpulan modul proyek Writerside berubah. Siapkan pratinjau penggantian nama baru sebelum melakukan refaktor.';

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
  String diagnosticWritersideWebFileNameInvalid(
    String instanceId,
    String webFileName,
    String topic,
  ) {
    return 'Instans \"$instanceId\" menerbitkan nama file web tidak valid \"$webFileName\" untuk topik \"$topic\".';
  }

  @override
  String diagnosticWritersideWebFileNameCollision(
    String instanceId,
    String webFileName,
    String firstTopic,
    String secondTopic,
  ) {
    return 'Instans \"$instanceId\" menerbitkan \"$firstTopic\" dan \"$secondTopic\" sebagai \"$webFileName\".';
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
  String get exportFormat => 'Format keluaran';

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
  String get openTocFile => 'Buka berkas daftar isi';

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
  String get goToDeclaration => 'Buka Deklarasi';

  @override
  String get findUsages => 'Cari Penggunaan';

  @override
  String get cannotRenameSymbol =>
      'Nama simbol tidak dapat diubah dengan aman. Periksa nama dan segarkan referensi sebelum mencoba lagi.';

  @override
  String get renameTopicFileInstead =>
      'ID topik berasal dari nama filenya. Gunakan Ganti Nama File Topik di daftar isi atau bilah samping File.';

  @override
  String get keyboardLayout => 'Tata letak papan ketik';

  @override
  String get diagnosticWritersideUnsupported =>
      'Konten yang tidak didukung atau salah format ditampilkan sebagai sumber.';

  @override
  String diagnosticWritersideSource(String reference, String reason) {
    return 'Tidak dapat menyelesaikan sumber “$reference”: $reason';
  }

  @override
  String diagnosticWritersideLink(String destination) {
    return 'Tujuan tautan tidak tersedia dalam instans ini: $destination';
  }

  @override
  String diagnosticWritersideSchema(
    String element,
    String attribute,
    String reason,
  ) {
    return 'Markup Writerside tidak valid: $element, $attribute. $reason';
  }

  @override
  String get diagnosticWritersideLlmsTxt =>
      'Gunakan <llms-txt>true</llms-txt> atau <llms-txt>false</llms-txt>; single-file tidak lagi didukung.';

  @override
  String diagnosticWritersideReference(String kind, String reference) {
    return 'Tidak dapat menyelesaikan $kind: $reference';
  }

  @override
  String get exportAsHtml => 'Ekspor sebagai HTML…';

  @override
  String get fileTypeHtml => 'Dokumen HTML';

  @override
  String get exportingHtml => 'Mengekspor HTML…';

  @override
  String get htmlExported => 'Ekspor HTML selesai';

  @override
  String get htmlExportFailed => 'Ekspor HTML gagal';

  @override
  String get htmlKeepAssetsTogether =>
      'Saat menyalin hasil ekspor, simpan berkas HTML bersama folder aset pendampingnya.';

  @override
  String get htmlInstanceDescription =>
      'Ekspor satu instans sebagai halaman luring yang saling tertaut. Pilih nama untuk folder keluaran khusus.';

  @override
  String get htmlInstance => 'Instans';

  @override
  String get htmlOwnedDirectoryOnly =>
      'Hanya folder yang dibuat oleh ekspor HTML BusyMark yang dapat diganti. Berkas yang diubah atau tidak terkait akan dipertahankan.';

  @override
  String get showInFolder => 'Tampilkan dalam Folder';

  @override
  String sortTableColumn(String column) {
    return 'Urutkan $column';
  }

  @override
  String get exportReset => 'Pulihkan nilai bawaan';

  @override
  String get exportToc => 'Sertakan daftar isi';

  @override
  String get exportTocDepth => 'Kedalaman daftar isi';

  @override
  String get exportNumberHeadings => 'Nomori judul';

  @override
  String get exportLegal => 'US Legal';

  @override
  String get exportCustom => 'Khusus';

  @override
  String get exportPageWidth => 'Lebar halaman (mm)';

  @override
  String get exportPageHeight => 'Tinggi halaman (mm)';

  @override
  String get exportMarginTop => 'Margin atas (mm)';

  @override
  String get exportMarginRight => 'Margin kanan (mm)';

  @override
  String get exportMarginBottom => 'Margin bawah (mm)';

  @override
  String get exportMarginLeft => 'Margin kiri (mm)';

  @override
  String get exportTypography => 'Tipografi';

  @override
  String get exportSans => 'Tanpa serif';

  @override
  String get exportSerif => 'Berserif';

  @override
  String get exportBodySize => 'Ukuran huruf isi';

  @override
  String get exportCodeSize => 'Ukuran huruf kode';

  @override
  String get exportRunningText => 'Kepala dan kaki halaman';

  @override
  String get exportHeader => 'Kepala halaman';

  @override
  String get exportFooter => 'Kaki halaman';

  @override
  String get exportNone => 'Tidak ada';

  @override
  String get exportDocumentTitle => 'Judul dokumen';

  @override
  String get exportBottomLeft => 'Kiri bawah';

  @override
  String get exportBottomCenter => 'Tengah bawah';

  @override
  String get exportBottomRight => 'Kanan bawah';

  @override
  String get exportFirstPage =>
      'Tampilkan kepala dan kaki pada halaman pertama';

  @override
  String get exportAccent => 'Warna aksen / tautan';

  @override
  String get exportTheme => 'Tema';

  @override
  String get exportAutomatic => 'Otomatis';

  @override
  String get exportLayout => 'Tata letak';

  @override
  String get exportContentWidth => 'Lebar isi maksimum';

  @override
  String get exportOutput => 'Keluaran';

  @override
  String get exportPackaging => 'Pengemasan';

  @override
  String get exportSingleFile => 'Satu berkas HTML';

  @override
  String get exportAssetsDirectory => 'HTML + folder aset';

  @override
  String get exportCustomCss => 'Lembar gaya khusus…';

  @override
  String get exportRemoveCss => 'Hapus lembar gaya khusus';

  @override
  String get exportCssNote =>
      'Pilih berkas CSS UTF-8 opsional (hingga 256 KiB). Impor, URL sumber daya, serta CSS yang dapat dieksekusi atau memakai escape ditolak. Gaya diterapkan setelah CSS BusyMark. Sumber daya jarak jauh tidak diunduh.';

  @override
  String get exportSitePackagingNote =>
      'Writerside mempertahankan halaman topik terpisah yang saling tertaut. Mode berkas tunggal menyematkan sumber daya di setiap halaman.';

  @override
  String get exportInvalidGeometry =>
      'Sisakan lebar dan tinggi isi minimal 20 mm setelah margin.';

  @override
  String get exportInvalidColor => 'Masukkan warna sebagai #RRGGBB.';

  @override
  String get exportInvalidCss =>
      'Pilih berkas .css UTF-8 yang dapat dibaca hingga 256 KiB, tanpa impor, URL sumber daya, HTML, atau CSS yang dapat dieksekusi atau memakai escape.';

  @override
  String get clipboardHistory => 'Sejarah Tempel';

  @override
  String get clipboardHistoryDescription => 'Buka riwayat tempel lokal sesi.';

  @override
  String get clipboardCurrent => 'Tempel saat ini';

  @override
  String get clipboardCurrentExternal => 'Tempel saat ini dari aplikasi lain';

  @override
  String clipboardDestination(String name) {
    return 'Tempel ke $name';
  }

  @override
  String get clipboardSessionOnly => 'Hanya disimpan untuk sesi BusyMark ini.';

  @override
  String get clipboardNoItems => 'Riwayat tempel kosong.';

  @override
  String get clipboardDisabled =>
      'Koleksi Riwayat Tempel dinonaktifkan di Pengaturan.';

  @override
  String get clipboardUnavailable =>
      'Konten tempel saat ini tidak tersedia atau tidak didukung.';

  @override
  String get clipboardTooLarge =>
      'Item clipboard ini terlalu besar untuk disimpan.';

  @override
  String get clipboardPastePlainText => 'Tempel sebagai Teks Biasa';

  @override
  String get clipboardClearAll => 'Hapus Riwayat Clipboard';

  @override
  String get clipboardEntryText => 'Teks';

  @override
  String get clipboardEntryRichText => 'Teks kaya';

  @override
  String get clipboardEntryImage => 'Gambar';

  @override
  String clipboardOrigin(String name) {
    return 'Disalin dari $name';
  }

  @override
  String get localHistory => 'Riwayat Lokal';

  @override
  String get localHistoryEllipsis => 'Riwayat Lokal…';

  @override
  String get localHistoryDescription =>
      'Tampilkan revisi lokal yang disimpan dan otomatis untuk dokumen saat ini.';

  @override
  String get findLocalHistoryEllipsis => 'Cari di Sejarah Lokal…';

  @override
  String get findLocalHistoryDescription =>
      'Cari dokumen dan isi revisi dalam Sejarah Lokal.';

  @override
  String get localHistoryNoDocuments =>
      'Tidak ada dokumen yang memiliki Sejarah Lokal.';

  @override
  String get localHistoryNoRevisions =>
      'Dokumen ini tidak memiliki revisi Sejarah Lokal.';

  @override
  String get localHistorySelectedRevision => 'Revisi yang dipilih';

  @override
  String get localHistoryCurrentEditor => 'Konten editor saat ini';

  @override
  String get localHistoryCurrentDisk => 'Konten saat ini di disk';

  @override
  String get localHistoryMissingFile => 'File asli hilang.';

  @override
  String get localHistoryRestoreRevision => 'Kembalikan Revisi';

  @override
  String get localHistoryRestoreOriginalLocation => 'Kembalikan ke Lokasi Asli';

  @override
  String get localHistoryRestoreNewLocation => 'Kembalikan ke Lokasi Baru…';

  @override
  String get localHistoryRestoreChange => 'Kembalikan Perubahan';

  @override
  String get localHistoryRestoreUnavailable =>
      'Perubahan ini tidak dapat dikembalikan karena perbandingan tidak lagi berlaku.';

  @override
  String get localHistoryComparisonSimplified =>
      'Perbandingan besar ini disederhanakan. Kembalikan perubahan individual tidak tersedia.';

  @override
  String localHistoryOlderChange(String text) {
    return 'Perubahan revisi yang lebih lama: $text';
  }

  @override
  String localHistoryCurrentChange(String text) {
    return 'Perubahan konten saat ini: $text';
  }

  @override
  String get localHistoryDeleted => 'Dihapus';

  @override
  String get localHistoryUntitled => 'Tanpa Judul';

  @override
  String get localHistoryClearDocument => 'Hapus Riwayat Dokumen Ini';

  @override
  String get localHistoryClearAll => 'Hapus Riwayat Lokal Seluruhnya';

  @override
  String get localHistoryClearDocumentTitle => 'Hapus riwayat dokumen?';

  @override
  String get localHistoryClearAllTitle => 'Hapus riwayat lokal seluruhnya?';

  @override
  String get localHistoryClearConfirmation =>
      'Ini secara permanen menghapus revisi yang tersimpan. Tindakan ini tidak dapat dibatalkan.';

  @override
  String get localHistoryWarningIndexRebuilt =>
      'Indeks Riwayat Lokal rusak dan dibangun kembali dari revisi yang utuh.';

  @override
  String localHistoryWarningUnsupportedFormat(String version) {
    return 'Penyimpanan Riwayat Lokal menggunakan format yang tidak didukung $version.';
  }

  @override
  String localHistoryWarningUnavailable(String detail) {
    return 'Riwayat Lokal tidak tersedia: $detail';
  }

  @override
  String get localHistoryWarningRecordingDisabled =>
      'Perekaman dinonaktifkan atau jalur ini dikecualikan. Aktifkan kembali perekaman sebelum memulihkan.';

  @override
  String localHistoryWarningPathChange(String detail) {
    return 'Riwayat Lokal tidak dapat mencatat perubahan jalur: $detail';
  }

  @override
  String localHistoryWarningDeletedPath(String detail) {
    return 'Sejarah Lokal tidak dapat menyimpan jalur yang dihapus: $detail';
  }

  @override
  String get localHistoryWarningRevisionMissing =>
      'Revisi yang dipilih hilang atau rusak.';

  @override
  String localHistoryWarningRevisionRead(String detail) {
    return 'Revisi yang dipilih tidak dapat dibaca: $detail';
  }

  @override
  String localHistoryWarningCapture(String detail) {
    return 'Sejarah Lokal tidak dapat menangkap revisi ini: $detail';
  }

  @override
  String localHistoryRevisionAt(String reason, String timestamp) {
    return '$reason – $timestamp';
  }

  @override
  String get localHistoryReasonBaseline => 'Versi dasar';

  @override
  String get localHistoryReasonSaved => 'Tersimpan';

  @override
  String get localHistoryReasonAutomaticCheckpoint => 'Checkpoint otomatis';

  @override
  String get localHistoryReasonBeforeReload => 'Sebelum memuat ulang';

  @override
  String get localHistoryReasonBeforeDiscard => 'Sebelum membuang';

  @override
  String get localHistoryReasonBeforeRestore => 'Sebelum pemulihan';

  @override
  String get localHistoryReasonBeforeDelete => 'Sebelum menghapus';

  @override
  String get localHistoryReasonExternalChange => 'Perubahan eksternal';

  @override
  String get settingsHistory => 'Riwayat';

  @override
  String get settingsClipboardHistoryTitle => 'Kumpulkan Riwayat Klip';

  @override
  String get settingsClipboardHistoryDescription =>
      'Simpan konten yang disalin dan berhasil ditempel hanya untuk sesi BusyMark ini.';

  @override
  String get settingsLocalHistoryTitle => 'Rekam Riwayat Lokal';

  @override
  String get settingsLocalHistoryDescription =>
      'Simpan revisi dokumen pada perangkat ini untuk pemulihan dan perbandingan.';

  @override
  String get settingsHistoryCheckpoint => 'Interval checkpoint otomatis';

  @override
  String get settingsHistoryRetention => 'Masa simpan';

  @override
  String get settingsHistoryStorage => 'Penyimpanan maksimum';

  @override
  String get settingsHistoryExcludedPaths => 'Jalur yang dikecualikan';

  @override
  String get settingsHistoryExcludedPathsHint => 'Satu jalur absolut per baris';

  @override
  String settingsSecondsValue(int value) {
    return '$value detik';
  }

  @override
  String settingsDaysValue(int value) {
    return '$value hari';
  }

  @override
  String settingsMebibytesValue(int value) {
    return '$value MiB';
  }

  @override
  String get spelling => 'Ejaan';

  @override
  String get automaticSpelling => 'Periksa ejaan secara otomatis';

  @override
  String get defaultSpellingLanguage => 'Bahasa ejaan bawaan';

  @override
  String get projectSpellingLanguage => 'Bahasa ejaan proyek';

  @override
  String get chooseSpellingLanguage => 'Pilih bahasa ejaan';

  @override
  String get spellingLanguageUnsetStatus => 'Bahasa…';

  @override
  String get spellingOffStatus => 'Ejaan Nonaktif';

  @override
  String get checkSpelling => 'Periksa Ejaan';

  @override
  String get ignoreSpellingOnce => 'Abaikan Sekali';

  @override
  String get ignoreSpellingDocument => 'Abaikan Semua di Dokumen Ini';

  @override
  String get addPersonalSpellingWord => 'Tambahkan ke Kamus Pribadi';

  @override
  String get addProjectSpellingWord => 'Tambahkan ke Kamus Proyek';

  @override
  String get inheritSpellingLanguage => 'Gunakan bahasa proyek atau aplikasi';

  @override
  String get disableDocumentSpelling => 'Jangan periksa ejaan';

  @override
  String get importSpellingDictionary => 'Impor Kamus';

  @override
  String get personalSpellingDictionary => 'Kamus Pribadi';

  @override
  String get projectSpellingDictionary => 'Kamus Proyek';

  @override
  String get noSpellingErrors => 'Tidak ada kesalahan ejaan';

  @override
  String get noSpellingSuggestions => 'Tidak ada saran ejaan';

  @override
  String get spellingWordCheckFailed => 'Kata ini tidak dapat diperiksa';

  @override
  String get spellingCheckFailed => 'Pemeriksaan ejaan gagal';

  @override
  String get spellingSettingsLoadFailed =>
      'Pengaturan pemeriksaan ejaan tidak dapat dimuat';

  @override
  String get retrySpellingSettings =>
      'Coba muat ulang pengaturan pemeriksaan ejaan';

  @override
  String get spellingCheckIncomplete => 'Pemeriksaan ejaan belum lengkap';

  @override
  String get spellingDictionaryNotInstalled => 'Kamus belum terpasang';

  @override
  String spellingDictionaryNotInstalledForLanguage(String dictionary) {
    return 'Kamus $dictionary belum terpasang';
  }

  @override
  String spellingDictionaryNotInstalledWithSize(String size) {
    return 'Belum terpasang · $size';
  }

  @override
  String get spellingDictionaryInstalled => 'Terpasang';

  @override
  String get installSpellingDictionary => 'Pasang kamus';

  @override
  String get removeSpellingDictionary => 'Hapus kamus';

  @override
  String get cancelSpellingDictionaryInstall => 'Batalkan unduhan kamus';

  @override
  String get retrySpellingDictionaryInstall => 'Coba lagi pemasangan kamus';

  @override
  String spellingDictionaryDownloading(String size) {
    return 'Mengunduh $size…';
  }

  @override
  String get spellingDictionaryValidating => 'Memvalidasi kamus…';

  @override
  String get spellingDictionaryInstallFailed =>
      'Pemasangan kamus gagal — pilih untuk mencoba lagi';

  @override
  String spellingDictionaryInstallPrompt(String dictionary, String size) {
    return 'Pasang $dictionary ($size)? Setelah dipasang, kamus tetap tersedia luring sampai Anda menghapusnya.';
  }

  @override
  String get spellingDictionaryUnavailable => 'Kamus tidak tersedia';

  @override
  String get spellingChecking => 'Memeriksa ejaan…';

  @override
  String exportInvalidRange(String field, String minimum, String maximum) {
    return '$field: masukkan angka antara $minimum dan $maximum.';
  }

  @override
  String get spellingDictionaryRecoveryConflict =>
      'Kamus ejaan diubah secara eksternal. Salinan pemulihan telah disimpan.';

  @override
  String get windowMinimize => 'Minimalkan';

  @override
  String get windowMaximize => 'Maksimalkan';

  @override
  String get windowRestore => 'Pulihkan';

  @override
  String get nextcloudNotes => 'Nextcloud Notes';

  @override
  String get nextcloudConnect => 'Hubungkan';

  @override
  String get nextcloudReconnect => 'Hubungkan kembali';

  @override
  String get nextcloudDisconnect => 'Putuskan koneksi';

  @override
  String get nextcloudServer => 'URL server';

  @override
  String get nextcloudSignInBrowser => 'Selesaikan masuk di peramban.';

  @override
  String get nextcloudFavorites => 'Favorit';

  @override
  String get nextcloudNewNote => 'Catatan baru';

  @override
  String get nextcloudSavedLocally => 'Disimpan lokal · sinkronisasi tertunda';

  @override
  String get nextcloudSyncing => 'Menyinkronkan';

  @override
  String get nextcloudSynced => 'Tersinkron';

  @override
  String get nextcloudOffline => 'Luring';

  @override
  String get nextcloudLocked => 'Dikunci server';

  @override
  String get nextcloudReconnectRequired => 'Perlu menghubungkan kembali';

  @override
  String get nextcloudCreationUncertain => 'Hasil pembuatan belum pasti';

  @override
  String get nextcloudReadOnly => 'Hanya baca';

  @override
  String get nextcloudTakeRemote => 'Gunakan versi server';

  @override
  String get nextcloudMerge => 'Gabungkan';

  @override
  String get nextcloudDeleteNote => 'Hapus catatan?';

  @override
  String get nextcloudWorkspaceReplaceUnavailable =>
      'Penggantian ruang kerja tidak tersedia untuk Nextcloud Notes. Ganti dalam setiap catatan.';

  @override
  String get nextcloudSaveLocalCopy => 'Simpan salinan lokal…';

  @override
  String get nextcloudDisconnectWarning =>
      'Menghapus akun ini menghapus catatan tersimpan dan perubahan tertunda dari perangkat. Sinkronkan dahulu untuk menyimpan pekerjaan di server.';

  @override
  String get nextcloudAttachmentRetryWarning =>
      'Jika unggahan sebelumnya berhasil, mencoba lagi dapat meninggalkan lampiran yang tidak digunakan di server.';

  @override
  String get nextcloudAttachmentReference => 'Referensi lampiran di server';

  @override
  String get nextcloudAddAttachment => 'Tambahkan lampiran…';

  @override
  String get nextcloudDeleteAttachmentWarning =>
      'Menghapus lampiran ini membuat tautannya dalam catatan tidak tersedia. Data yang disimpan dapat dipulihkan melalui riwayat lokal.';

  @override
  String get nextcloudChooseConflictingAttributes =>
      'Pilih setiap atribut yang berkonflik.';

  @override
  String get nextcloudUseServerNote => 'Gunakan catatan server ini';

  @override
  String get nextcloudUseServerNoteExplanation =>
      'Menautkan draf ini ke catatan server yang dipilih, lalu menyinkronkan perubahan lokal yang dipertahankan. Permintaan yang cocok tidak memastikan siapa yang membuat catatan.';

  @override
  String get nextcloudExactCandidate =>
      'Sama persis dengan permintaan; identitas belum dikonfirmasi.';

  @override
  String get nextcloudPossibleCandidate =>
      'Kemungkinan cocok setelah permintaan disanitasi; identitas belum dikonfirmasi.';

  @override
  String get nextcloudSelectCandidate => 'Pilih catatan server untuk ditinjau';

  @override
  String get nextcloudCreateSeparate => 'Buat catatan terpisah';

  @override
  String get nextcloudCreateSeparateWarning =>
      'Permintaan pertama mungkin sudah membuat catatan server. Ini membuat catatan terpisah dengan pekerjaan lokal yang dipertahankan. Tidak ada dugaan duplikat yang akan dihapus.';

  @override
  String get wsSemanticFormats => 'Pemformatan semantik';

  @override
  String get wsUiControl => 'Kontrol antarmuka';

  @override
  String get wsFilePath => 'Berkas / Jalur';

  @override
  String get wsUiPath => 'Jalur antarmuka';

  @override
  String get wsDefinitionList => 'Daftar definisi';

  @override
  String get wsIncludeContent => 'Sertakan konten yang dapat digunakan ulang';

  @override
  String get wsVariableReference => 'Referensi variabel';

  @override
  String get wsConvertList => 'Ubah daftar menjadi prosedur';

  @override
  String get wsElementProperties => 'Properti elemen';

  @override
  String get wsTopicProperties => 'Properti topik';

  @override
  String get wsCollapsible => 'Dapat diciutkan';

  @override
  String get wsPublishedState => 'Status awal publikasi';

  @override
  String get wsExpanded => 'Diperluas';

  @override
  String get wsCollapsed => 'Diciutkan';

  @override
  String get wsCollapsedTitle => 'Judul saat diciutkan';

  @override
  String get wsTerm => 'Istilah';

  @override
  String get wsListLayout => 'Tata letak daftar';

  @override
  String get wsSyncGroup => 'Grup sinkronisasi';

  @override
  String get wsTabKey => 'Kunci tab';

  @override
  String get wsSwitcherLabel => 'Label pengalih';

  @override
  String get wsNavigationElements => 'Elemen navigasi';

  @override
  String get wsNavigationDepth => 'Kedalaman navigasi';

  @override
  String get wsAddItem => 'Tambah item';

  @override
  String get wsStep => 'Langkah';

  @override
  String get wsPropertyInvalid => 'Nilai properti tidak valid';

  @override
  String get wsFilter => 'Filter konten';

  @override
  String get wsIdentifier => 'ID elemen';

  @override
  String get wsTldr => 'Ringkasan (TLDR)';

  @override
  String get wsFullLayout => 'Lebar penuh';

  @override
  String get wsMediumLayout => 'Sedang (1:2)';

  @override
  String get wsNarrowLayout => 'Kolom istilah sempit';

  @override
  String get wsTitle => 'Judul';

  @override
  String get wsSwitcherKey => 'Kunci pemilih';

  @override
  String get nextcloudServerSettings => 'Pengaturan Notes server';

  @override
  String get nextcloudNotesPath => 'Jalur folder catatan';

  @override
  String get nextcloudFileSuffix => 'Ekstensi berkas catatan baru';

  @override
  String get nextcloudServerSettingsExplanation =>
      'Pengaturan Notes server ini memengaruhi klien lain. Mengubah jalur tidak memindahkan berkas; mengubah ekstensi tidak mengganti nama catatan yang ada.';

  @override
  String get nextcloudSettingsSaved => 'Pengaturan server disimpan';

  @override
  String get nextcloudSettingsNormalized =>
      'Disimpan dengan nilai yang dinormalisasi server';

  @override
  String get nextcloudPendingUpload => 'Unggahan lampiran tertunda';

  @override
  String nextcloudServerCheck(String time) {
    return 'Pemeriksaan server terakhir: $time';
  }

  @override
  String get nextcloudSettingsLoading => 'Memuat pengaturan server';

  @override
  String get nextcloudSettingsSaving => 'Menyimpan pengaturan server';

  @override
  String get nextcloudPreviousLocalEdit => 'Edit lokal sebelumnya';

  @override
  String get nextcloudUsePreviousEdit => 'Gunakan edit sebelumnya';

  @override
  String get quickOpen => 'Buka cepat';

  @override
  String get notesAll => 'Semua catatan';

  @override
  String get notesUncategorized => 'Tanpa kategori';

  @override
  String get notesRecovery => 'Pemulihan';

  @override
  String get notesRecentlyEdited => 'Baru diedit';

  @override
  String get notesOldestEdited => 'Edit terlama';

  @override
  String get notesTitleAscending => 'Judul A–Z';

  @override
  String get notesTitleDescending => 'Judul Z–A';

  @override
  String get notesMove => 'Pindah ke kategori';

  @override
  String get notesRemoveFavorite => 'Hapus favorit';

  @override
  String get notesOffline => 'Sediakan secara luring';

  @override
  String get notesOfflineRemove => 'Hapus penyimpanan luring';

  @override
  String get notesIndexing => 'Mengindeks catatan…';

  @override
  String get notesSearchHelp =>
      'Istilah digabung dengan DAN. Gunakan \"frasa kutipan\", title: dan category:.';

  @override
  String get notesSourceLocation => 'Lokasi sumber';

  @override
  String get notesRecoveryHelp =>
      'Hanya catatan lokal tersimpan dan riwayat lokal. Sampah dan riwayat server tidak tersedia.';

  @override
  String get notesImport => 'Impor catatan';

  @override
  String get notesExport => 'Ekspor catatan';

  @override
  String get notesImportDistinct => 'Impor sebagai catatan terpisah';

  @override
  String get notesAvailableOffline => 'Tersedia secara luring';

  @override
  String get notesIncomplete => 'Tidak lengkap';

  @override
  String get notesSelected => 'Catatan terpilih';

  @override
  String get notesNoHistory =>
      'Tidak ada revisi tersimpan. Riwayat mungkin dinonaktifkan, kedaluwarsa atau dihapus.';

  @override
  String get notesTextAvailable => 'Teks tersedia secara lokal';

  @override
  String get notesLocalVersion => 'Versi kerja lokal';

  @override
  String get notesAttachments => 'Lampiran';

  @override
  String get notesSkipped => 'Dilewati';

  @override
  String get notesFailed => 'Gagal';

  @override
  String get notesCompleted => 'Selesai';

  @override
  String get notesImportNew => 'Mulai impor baru';

  @override
  String get notesImportResume => 'Lanjutkan impor yang terputus';

  @override
  String get notesImportAlreadyImported => 'Sudah diimpor dalam operasi ini';

  @override
  String get references => 'Referensi';

  @override
  String get referenceIncoming => 'Masuk';

  @override
  String get referenceOutgoing => 'Keluar';

  @override
  String get referenceChooseTarget => 'Pilih tujuan tautan';

  @override
  String get referenceWholeDocument => 'Seluruh dokumen';

  @override
  String get referenceSourceLocation => 'Lokasi sumber';

  @override
  String get referenceTargetLocation => 'Lokasi tujuan';

  @override
  String get referenceResolved => 'Terselesaikan';

  @override
  String get referenceMissing => 'Tidak ditemukan';

  @override
  String get referenceAmbiguous => 'Ambigu';

  @override
  String get referenceUnavailable => 'Tidak tersedia dalam konteks ini';

  @override
  String get referenceUnsupported => 'Tidak didukung';

  @override
  String get referenceNoPortableId =>
      'Tujuan ini tidak memiliki URL catatan portabel yang terverifikasi.';

  @override
  String get wsIncludeLines => 'Sertakan baris';

  @override
  String get wsIncludeSymbol => 'Sertakan simbol';

  @override
  String get wsEmphasizeLines => 'Sorot baris yang ditampilkan';

  @override
  String get wsPropertiesReadOnly => 'Properti hanya baca pada tampilan ini.';

  @override
  String get wsPropertiesProtected => 'Elemen dilindungi. Edit sumbernya.';

  @override
  String get wsPropertiesConflict =>
      'Dokumen atau elemen berubah. Kembalikan draf dan pilih lagi.';

  @override
  String get wsPropertiesUnresolved => 'Referensi belum dapat diselesaikan.';

  @override
  String get wsUseDefault => 'Gunakan bawaan';

  @override
  String get wsPropertiesSelection => 'Pilih satu elemen.';

  @override
  String get wsImageDisplay => 'Tampilan gambar';

  @override
  String get wsImageThumbnail => 'Thumbnail yang dapat diklik';

  @override
  String get wsEnabled => 'Aktif';

  @override
  String get wsDisabled => 'Nonaktif';

  @override
  String get wsWidth => 'Lebar';

  @override
  String get wsHeight => 'Tinggi';

  @override
  String get wsPropertiesInactive =>
      'Properti hanya berlaku saat penciutan publikasi diaktifkan.';

  @override
  String get wsNavigationAll => 'Semua elemen berjudul';

  @override
  String get wsNavigationNone => 'Tanpa navigasi';

  @override
  String get wsNavigationCustom => 'Navigasi khusus';

  @override
  String get wsTitleOverride => 'Timpa judul';

  @override
  String get wsCompactLayout => 'Ringkas';

  @override
  String get wsWideLayout => 'Lebar';

  @override
  String get wsCodeSourceConflict =>
      'Pindahkan atau hapus kode yang ditulis dalam blok ini sebelum menetapkan src. Writerside menolak blok kode yang tidak kosong dengan referensi sumber.';

  @override
  String get wsInherited => 'Warisi dari daftar';

  @override
  String get wsExternalImageSize =>
      'Writerside tidak mengatur ukuran gambar eksternal dengan andal. Ukuran yang ada dapat dilihat dan dihapus.';

  @override
  String get wsPropertiesNotSerialized =>
      'Perubahan ini tidak diterapkan ke sumber. Draf tetap disimpan.';

  @override
  String get wsListItem => 'Item daftar';

  @override
  String get wsSourceFile => 'Berkas sumber';

  @override
  String get wsLinkTarget => 'Tujuan tautan';

  @override
  String get wsPreviewImage => 'Gambar pratinjau';

  @override
  String get wsIncludedElement => 'Elemen yang disertakan';

  @override
  String get wsHelpModule => 'Modul bantuan';

  @override
  String get wsActionId => 'ID tindakan';

  @override
  String get wsKeymapHelpInstance => 'Instans bantuan peta tombol';

  @override
  String get wsShowInSource => 'Tampilkan di Sumber';

  @override
  String get wsOriginElement => 'Penggantian elemen';

  @override
  String get wsOriginAncestor => 'Elemen induk';

  @override
  String get wsOriginModule => 'Bawaan modul';

  @override
  String get wsOriginBuiltIn => 'Bawaan internal';

  @override
  String get wsOriginUnresolved => 'Belum teratasi';

  @override
  String wsEffectiveProperty(String value, String origin) {
    return 'Efektif: $value — $origin';
  }

  @override
  String get wsElementSelector => 'Elemen';

  @override
  String wsGeneratedAnchorValue(String anchor) {
    return 'Dihasilkan: $anchor';
  }

  @override
  String wsDefaultProperty(String value) {
    return 'Default: $value';
  }

  @override
  String wsDefaultPropertyOrigin(String value, String origin) {
    return 'Default: $value · $origin';
  }

  @override
  String wsResolvedProperty(String value) {
    return 'Diselesaikan: $value';
  }

  @override
  String get wsPropertyUnresolved => 'Belum diselesaikan';

  @override
  String get wsModule => 'Modul';

  @override
  String get wsParent => 'Induk';

  @override
  String get wsListType => 'Jenis daftar';

  @override
  String get wsStartingNumber => 'Nomor awal';

  @override
  String get wsListSorting => 'Pengurutan';

  @override
  String get wsLetteredList => 'Daftar huruf';

  @override
  String get wsCheckboxList => 'Daftar kotak centang';

  @override
  String get wsMarkerlessList => 'Daftar tanpa penanda';

  @override
  String get wsAscending => 'Menaik';

  @override
  String get wsDescending => 'Menurun';

  @override
  String get wsNoSorting => 'Tanpa pengurutan';

  @override
  String get wsAsWritten => 'Sesuai tulisan';

  @override
  String get wsSentenceCase => 'Kapitalisasi kalimat';

  @override
  String get wsTitleCase => 'Kapitalisasi judul';

  @override
  String get wsLowerCase => 'Huruf kecil';

  @override
  String get wsUpperCase => 'Huruf besar';

  @override
  String get wsNativeMarkers => 'Penanda Markdown';

  @override
  String wsListMarkerStart(String number) {
    return 'Penanda awal: $number';
  }

  @override
  String wsListLevel(String level) {
    return 'Tingkat $level';
  }

  @override
  String get wsModuleCapsIgnored =>
      'Builder yang dipatok mengabaikan aturan <caps> modul. Gunakan atribut caps lokal atau default-property.';

  @override
  String get wsInsertElements => 'Sisipkan elemen';

  @override
  String get wsAdmonitionsAndQuotes => 'Pemberitahuan dan kutipan';

  @override
  String get wsSemanticText => 'Teks semantik';

  @override
  String get wsPropertiesUnavailable =>
      'Elemen yang diperiksa tidak tersedia. Periksa elemen untuk melanjutkan.';

  @override
  String get searchDocumentsCategory => 'Dokumen';

  @override
  String get searchTopicsCategory => 'Topik';

  @override
  String get searchCurrentDocument => 'Dokumen saat ini';

  @override
  String get searchCurrentWorkspace => 'Ruang kerja saat ini';

  @override
  String get browseNotes => 'Jelajahi catatan';

  @override
  String get searchActionsCommand => 'Cari tindakan';

  @override
  String get searchDocumentsCommand => 'Cari dokumen';

  @override
  String get searchTopicsCommand => 'Cari topik';

  @override
  String get searchRecentCommand => 'Cari terbaru';

  @override
  String get searchResourceUnavailable => 'Sumber daya ini tidak tersedia.';

  @override
  String get notesSync => 'Sinkronkan catatan';

  @override
  String get searchInWorkspace => 'Cari dalam Ruang Kerja';

  @override
  String get searchCategory => 'Kategori pencarian';

  @override
  String get clearHistorySearchScope => 'Cari riwayat seluruh dokumen';

  @override
  String get searchInDocument => 'Cari dalam dokumen';

  @override
  String get searchDocumentHint => 'Cari dalam dokumen ini…';

  @override
  String get searchWorkspaceHint => 'Cari dalam ruang kerja ini…';

  @override
  String get searchOutlineHint => 'Cari judul bagian…';

  @override
  String get searchHistoryHint => 'Cari dalam riwayat lokal…';

  @override
  String get searchEnterText => 'Masukkan teks untuk mencari';

  @override
  String get searchAccountUnavailable => 'Akun tidak tersedia';

  @override
  String get searchDocumentsHint => 'Cari dokumen…';

  @override
  String get searchTopicsHint => 'Cari topik…';

  @override
  String get searchRecentHint => 'Cari terbaru…';

  @override
  String get searchActionsHint => 'Cari tindakan…';

  @override
  String get searchRequiresNotesWorkspace => 'Memerlukan ruang kerja Catatan';

  @override
  String get searchSidebarLabel => 'Cari:';

  @override
  String get searchDocumentTextCategory => 'Teks dokumen';

  @override
  String get searchWorkspaceTextCategory => 'Teks ruang kerja';

  @override
  String get searchHeadingsCategory => 'Judul';

  @override
  String get shortcutUnassigned => 'Belum ditetapkan';

  @override
  String get shortcutPressKeys => 'Tekan kombinasi tombol…';

  @override
  String get shortcutRecord => 'Rekam pintasan';

  @override
  String get shortcutRestoreAll => 'Pulihkan semua bawaan';

  @override
  String get shortcutRestoreAllQuestion =>
      'Pulihkan pintasan bawaan semua tindakan? Penetapan khusus akan dihapus.';

  @override
  String get shortcutSaveFailed =>
      'Pintasan aktif tetapi tidak dapat disimpan. Coba lagi agar tetap tersedia setelah mulai ulang.';

  @override
  String get shortcutRetry => 'Coba simpan lagi';

  @override
  String get shortcutChanged =>
      'Penetapan berubah. Tinjau pintasan saat ini dan coba lagi.';

  @override
  String get shortcutInvalid =>
      'Kombinasi ini tidak dapat ditetapkan dalam konteks ini.';

  @override
  String get shortcutSystemWarning =>
      'Desktop Anda mungkin memakai kombinasi ini. BusyMark tidak dapat mengganti pintasan sistem.';

  @override
  String get shortcutConflicts =>
      'Pintasan ini bertentangan dengan tindakan berikut:';

  @override
  String get shortcutRemove => 'Hapus penetapan';

  @override
  String get shortcutRestoreDefault => 'Pulihkan bawaan';

  @override
  String get shortcutAssign => 'Tetapkan';

  @override
  String get shortcutReassign => 'Tetapkan ulang';

  @override
  String get shortcutContextApplication => 'Aplikasi';

  @override
  String get shortcutContextDocument => 'Tampilan dokumen';

  @override
  String get shortcutContextEditor => 'Editor dan sumber';

  @override
  String get shortcutContextWritersideSource => 'Sumber Writerside';

  @override
  String get shortcutContextWorkspace => 'Navigasi ruang kerja';

  @override
  String get shortcutContextTree => 'Pohon bilah samping';

  @override
  String get searchHeadingsCommand => 'Cari judul';

  @override
  String get shortcutFixed =>
      'Dikelola oleh editor; tidak dapat dikonfigurasi.';

  @override
  String get shortcutDefaultConflict =>
      'Pintasan bawaan bertentangan dengan penetapan khusus.';

  @override
  String get shortcutCurrentBinding => 'Pintasan saat ini';

  @override
  String get shortcutProposedBinding => 'Pintasan yang diusulkan';

  @override
  String get notesActions => 'Tindakan catatan';

  @override
  String get noteActions => 'Tindakan untuk catatan';

  @override
  String get noteProperties => 'Properti Catatan';

  @override
  String get notesExportAll => 'Ekspor catatan · Semua catatan…';

  @override
  String get notesExportCategory => 'Ekspor catatan · Kategori…';

  @override
  String get notesOfflineAll => 'Sediakan secara luring · Semua catatan';

  @override
  String get notesOfflineCategory => 'Sediakan secara luring · Kategori';

  @override
  String get notesOfflineRemoveAll =>
      'Hapus penyimpanan luring · Semua catatan';

  @override
  String get notesOfflineRemoveCategory =>
      'Hapus penyimpanan luring · Kategori';

  @override
  String get notesOfflinePause => 'Jeda unduhan';

  @override
  String get notesOfflineResume => 'Lanjutkan unduhan';

  @override
  String get notesOfflineKeep => 'Sediakan secara luring';

  @override
  String get notesOfflineRetentionHelp =>
      'Menghapus persyaratan ini mempertahankan cache yang ada. Persyaratan kategori atau akun mungkin masih menyimpan catatan ini.';

  @override
  String get notesOfflineBroader =>
      'Catatan ini juga disimpan oleh persyaratan kategori atau akun.';

  @override
  String get notesOfflineExternal =>
      'Media eksternal memerlukan koneksi. BusyMark hanya menyimpan teks catatan dan lampiran terkelola.';

  @override
  String get notesEmptyAll => 'Belum ada catatan. Buat catatan untuk memulai.';

  @override
  String get notesEmptyFavorites => 'Tidak ada catatan favorit.';

  @override
  String get notesEmptyCategory => 'Tidak ada catatan dalam kategori ini.';

  @override
  String get notesEmptyUncategorized => 'Tidak ada catatan tanpa kategori.';

  @override
  String get notesEmptyRecovery =>
      'Tidak ada catatan tersimpan untuk dipulihkan.';

  @override
  String get notesLoadFailed => 'Nextcloud Notes · Gagal. Coba lagi';

  @override
  String get notesOperationFailed =>
      'Operasi tidak dapat diselesaikan. Draf Anda tetap disimpan. Tinjau penyimpanan dan konflik, lalu coba lagi.';

  @override
  String get notesInspectionFailed => 'Lampiran · Gagal. Coba lagi';

  @override
  String get notesStartingConnection => 'Memulai koneksi Nextcloud…';

  @override
  String get notesVerifyingConnection => 'Memverifikasi akses Catatan…';

  @override
  String get notesCancellingConnection => 'Membatalkan masuk dan membersihkan…';

  @override
  String get notesRemovingConnection => 'Menghapus akun lokal…';

  @override
  String get notesRemovedWarning =>
      'Akun Nextcloud lokal telah dihapus. Pencabutan kata sandi aplikasi tidak dikonfirmasi. Hapus kata sandi BusyMark di pengaturan Keamanan Nextcloud.';

  @override
  String get notesBuffersNotSaved =>
      'Tidak semua catatan terbuka dapat disimpan secara lokal. Tinjau penyimpanan, konflik, atau normalisasi di ruang kerja. Perubahan lokal mungkin masih perlu disinkronkan dengan Nextcloud.';

  @override
  String get notesSettingsLeave =>
      'Simpan perubahan pengaturan Nextcloud sebelum keluar?';

  @override
  String get notesSettingsLeaveHelp =>
      'Pengaturan Notes server · Perubahan yang belum disimpan';

  @override
  String get notesSettingsReload => 'Muat ulang pengaturan server…';

  @override
  String get notesSettingsReloadHelp =>
      'Memuat ulang mengganti draf dengan pengaturan Nextcloud saat ini. Buang draf dan muat ulang?';

  @override
  String get notesSettingsRefreshFailed =>
      'Nextcloud menerima pengaturan, tetapi penyegaran catatan gagal. Nilai yang ditampilkan telah dikonfirmasi server. Coba segarkan lagi dari Catatan.';

  @override
  String get notesUnavailable =>
      'Luring · Teks tersedia secara lokal · Disimpan lokal · sinkronisasi tertunda';

  @override
  String get notesStorageFull =>
      'Penyimpanan Nextcloud penuh. Kosongkan ruang di server, lalu coba lagi.';

  @override
  String get notesRejected =>
      'Nextcloud menolak perubahan ini. Tinjau catatan dan simpan salinan lokal sebelum mencoba lagi.';

  @override
  String get notesThrottled =>
      'Nextcloud meminta BusyMark menunggu. Sinkronisasi berlanjut setelah batas waktu percobaan ulang.';

  @override
  String get notesRecoveryRequired => 'Konflik · Bandingkan';

  @override
  String get notesScanning => 'Memindai berkas…';

  @override
  String get notesCancelling =>
      'Membatalkan… Menunggu operasi saat ini selesai.';

  @override
  String get notesCancelled => 'Dibatalkan';

  @override
  String get notesPartial => 'Selesai sebagian';

  @override
  String get notesTransferFailed => 'Gagal. Coba lagi';

  @override
  String get notesImportPartialHelp =>
      'Item sebelumnya mungkin telah disimpan secara lokal. Lanjutkan impor ini untuk meneruskan tanpa duplikat.';

  @override
  String get notesNotStarted => 'Belum dimulai';

  @override
  String get notesCreated => 'Dibuat';

  @override
  String get notesRemoteDeleteUnavailable =>
      'URL server · Tidak didukung · Hapus · Lampiran';

  @override
  String get notesCurrentText => 'Teks yang saat ini disimpan';

  @override
  String get notesRecovering => 'Memulihkan sebagai catatan baru…';

  @override
  String get notesReadOnlyHelp =>
      'Hanya baca · Favorit · Simpan salinan lokal…';

  @override
  String get notesSort => 'Urutkan catatan';

  @override
  String get notesPathRelative =>
      'Jalur folder catatan relatif terhadap penyimpanan Nextcloud Anda.';

  @override
  String get notesSettingsStale =>
      'Pengaturan berubah di Nextcloud. Muat ulang dan tinjau nilai server sebelum mengganti draf.';

  @override
  String get notesDownloadsPaused => 'Unduhan dijeda';

  @override
  String get notesExportNotPublished => 'Tidak ada ekspor yang dipublikasikan.';

  @override
  String get notesKeyringUnavailable =>
      'Buka kunci keyring desktop dan coba lagi.';

  @override
  String get notesConnectFailed =>
      'Tidak dapat terhubung ke Nextcloud Notes. Periksa alamat server dan coba lagi.';

  @override
  String get notesAccountMismatch =>
      'Masuk ke akun Nextcloud yang sama. Hapus akun ini terlebih dahulu untuk menghubungkan akun lain.';

  @override
  String get notesLocalRemovalFailed =>
      'Pembersihan akun lokal gagal. Akun dipertahankan agar penghapusan dapat dicoba lagi.';

  @override
  String get notesTransferring => 'Mentransfer catatan…';

  @override
  String get notesTechnicalDetails => 'Detail teknis';

  @override
  String get notesPauseRequirement => 'Jeda persyaratan luring';

  @override
  String get notesResumeRequirement => 'Lanjutkan persyaratan luring';

  @override
  String get gitReturnToDocument => 'Kembali ke dokumen';

  @override
  String gitSnapshotLabel(String revision, String path) {
    return 'Snapshot hanya baca · $revision · $path';
  }

  @override
  String get gitNonUtf8FilenameMessage =>
      'Nama berkas ini berisi byte non-UTF-8. Peninjauan dan staging Git tetap tersedia; editor dokumen memerlukan nama berkas UTF-8.';

  @override
  String get gitUiMergeInProgress => 'Gabung dalam proses';

  @override
  String get gitUiRebaseInProgress => 'Rebase dalam proses';

  @override
  String get gitUiCherryPickInProgress => 'Cherry-pick dalam proses';

  @override
  String get gitUiRevertInProgress => 'Revert sedang berlangsung';

  @override
  String get gitUiPatchApplicationInProgress =>
      'Aplikasi patch sedang berlangsung';

  @override
  String get gitUiSquashMergeResultAwaitingCommit =>
      'Squash merge hasil menunggu commit';

  @override
  String get gitUiUnresolvedIndexConflicts =>
      'Index konflik yang belum terpecahkan';

  @override
  String get gitUiUnresolvedConflicts => ' · konflik yang belum terselesaikan';

  @override
  String get gitUiReviewOperation => 'Operasi peninjauan';

  @override
  String get gitUiRefresh => 'Segarkan';

  @override
  String get gitUiCreateNamedStash => 'Buat stash bernama';

  @override
  String get gitUiCreateStash => 'Buat stash…';

  @override
  String get gitUiNoStashes => 'Tak ada stash';

  @override
  String get gitUiSelectAStashToInspectItsChanges =>
      'Pilih stash untuk memeriksa perubahannya';

  @override
  String get gitUiStashedUntrackedFiles =>
      'Berkas yang tidak di-stash-kan tidak ditrack';

  @override
  String get gitUiInspectStashedUntrackedFiles =>
      'Periksa berkas yang tidak di-stack-kan...';

  @override
  String get gitUiReinstateTheStashSStagedIndexStateWhenApplying =>
      'Mengembalikan stash yang dipentaskan/index ketika menerapkan';

  @override
  String get gitUiApplyAndRetain => 'Terapkan dan pertahankan';

  @override
  String get gitUiPop => 'Pop...';

  @override
  String get gitUiCreateBranch => 'Buat cabang…';

  @override
  String get gitUiDropStash => 'Hapus stash…';

  @override
  String get gitUiBranchFromStash => 'Buat cabang dari stash';

  @override
  String get gitUiCreateSwitchToABranchAtTheStashSOriginal =>
      'Buat/switch ke percabangan di pangkalan penyimpanan asli, lalu terapkan. Simpanan asli disimpan untuk eksplisit setelah dihapus.';

  @override
  String gitUiArg0ThisStash(String arg0) {
    return '$arg0 ini simpanan?';
  }

  @override
  String get gitUiTheOriginalStashIsRetainedIfApplyingConflicts =>
      'Simpanan asli dipertahankan jika menerapkan konflik.';

  @override
  String get gitUiDeletesThisStashEntryItsChangesAreNotApplied =>
      'Hapus entri stash ini. Perubahannya tidak diterapkan.';

  @override
  String get gitUiResolveTheUnmergedFilesGitHasNoStashContinueOr =>
      'Selesaikan berkas yang belum digabung. Git tidak memiliki perintah lanjut atau batal untuk stash; stash asli tetap ada.';

  @override
  String get gitUiStashNameMessage => 'Nama/pesan Stash';

  @override
  String get gitUiStashContentAndResultingIndex => 'Stash isi dan hasil indeks';

  @override
  String get gitUiStashTrackedWorkingAndStagedChanges =>
      'Stash melacak perubahan yang sedang bekerja dan dipentaskan';

  @override
  String get gitUiStashChangesLeaveStagedChangesInPlaceKeepIndex =>
      'Stash perubahan, biarkan perubahan dalam indeks tetap di tempat (--keep-index)';

  @override
  String get gitUiStashOnlyStagedChangesStaged =>
      'Stash hanya perubahan dalam indeks (--staged)';

  @override
  String get gitUiIncludeUntrackedFiles => 'Sertakan berkas yang tidak dilacak';

  @override
  String get gitUiAllEligiblePathsInThisRepository =>
      'Semua path yang dapat dipilih dalam repositori ini';

  @override
  String get gitUiNoEligibleChangesForTheseStashOptions =>
      'Tidak ada perubahan yang dapat dipilih untuk opsi stash ini.';

  @override
  String get gitUiSelectAtLeastOneEligiblePath =>
      'Pilih paling tidak satu path yang memenuhi syarat.';

  @override
  String get gitUiCreateStash2 => 'Buat stash';

  @override
  String get gitUiCreateWorktree => 'Buat tree kerja...';

  @override
  String get gitUiCreateACommitBeforeCreatingAWorktreeAtHEAD =>
      'Buat commit sebelum membuat worktree pada HEAD.';

  @override
  String get gitUiDetachedHEAD => 'HEAD terlepas';

  @override
  String get gitUiCurrent => 'Saat ini';

  @override
  String get gitUiLocked => 'Terkunci';

  @override
  String get gitUiOpenInBusyStack => 'Buka di Busy Stack';

  @override
  String get gitUiStatusNotInspected => 'Status tidak diperiksa';

  @override
  String get gitUiDirty => 'Kotor';

  @override
  String get gitUiClean => 'Tidak ada perubahan';

  @override
  String get gitUiOpenWorkingFolder => 'Buka folder kerja';

  @override
  String get gitUiMoveWorktree => 'Pindahkan worktree...';

  @override
  String get gitUiUnlock => 'Buka Kunci';

  @override
  String get gitUiLock => 'Kunci';

  @override
  String get gitUiRemoveCleanWorktree => 'Hapus worktree bersih...';

  @override
  String get gitUiReviewRemovalIncludingLocalChanges =>
      'Review penghapusan termasuk perubahan lokal...';

  @override
  String get gitUiNewWorktreeFolderName => 'Nama folder worktree baru';

  @override
  String get gitUiNewWorktreeBranch => 'Cabang worktree baru';

  @override
  String gitUiCreateArg0Arg1WithANewLocalBranchAtArg2(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return 'Buat $arg0/$arg1 dengan sebuah cabang lokal baru di $arg2 ($arg3).';
  }

  @override
  String get gitUiDestinationFolderName => 'Tujuan nama folder';

  @override
  String get gitUiRemoveWorktree => 'Hapus worktree?';

  @override
  String
  get gitUiExplicitlyDiscardAllLocalTrackedUntrackedChangesInThisWorktree =>
      'Secara eksplisit abaikan semua perubahan lokal yang dilacak/tak terlacak di tree kerja ini. Pohon kerja terkunci/di-gunakan tetap terlindungi.';

  @override
  String get gitUiGitRefusesRemovalIfThereAreLocalChangesUntrackedFiles =>
      'Git menolak penghapusan bila ada perubahan lokal, berkas yang tidak dilacak, atau kunci.';

  @override
  String get gitUiDiscardLocalWorktreeContentsAndRemove =>
      'Buang isi pohon kerja lokal dan hapus';

  @override
  String get gitUiRemoveCleanWorktree2 => 'Hapus worktree bersih';

  @override
  String
  get gitUiExplicitlyRecurseIntoNestedSubmodulesForUpdatesSynchronization =>
      'Eksplisit rekursi ke submodules nested untuk pemutakhiran/synchronisasi';

  @override
  String get gitUiNoRecordedSubmodules => 'Tidak ada submodules rekaman';

  @override
  String get gitUiNotInitialized => 'tidak terinisialisasi';

  @override
  String gitUiParentGitlinkArg0CheckedOutArg1(String arg0, String arg1) {
    return 'Parent gitlink: $arg0 Checked out: $arg1\n';
  }

  @override
  String get gitUiDirtyNestedRepository => 'Repositori nested kotor';

  @override
  String get gitUiCleanNestedRepository => 'Bersihkan repositori nested';

  @override
  String get gitUiNestedStatusUnavailable => 'Status nested tidak tersedia';

  @override
  String get gitUiEnterNestedRepository => 'Masukkan repositori nested';

  @override
  String get gitUiInitializeConfiguration => 'Inisialisasikan konfigurasi';

  @override
  String get gitUiUpdateToParentSRecordedCommit =>
      'Update ke commit induk yang direkam...';

  @override
  String get gitUiFollowConfiguredRemoteBranch =>
      'Ikuti konfigurasi branch jauh...';

  @override
  String get gitUiSynchronizeConfiguredURLs =>
      'Selaraskan URL yang dikonfigurasi...';

  @override
  String get gitUiStageCurrentSubmodulePointerInParent =>
      'Penunjuk submodule tahap kini pada induk';

  @override
  String get gitUiParentAndSubmoduleCommitsPushesAndDirtyStateRemainSeparate =>
      'Orang tua dan submodule berkomitmen, mendorong, dan keadaan kotor tetap terpisah. Meramban tidak menginisialisasi atau memperbaruinya.';

  @override
  String gitUiFetchAndCheckOutTheConfiguredRemoteBranchSCommit(String arg0) {
    return 'Ambil dan periksa komitmen branch jauh yang dikonfigurasi. Ini berbeda dari orang tua yang merekam gitlink. Rekursif: $arg0.';
  }

  @override
  String gitUiInitializeAsNeededAndCheckOutExactlyArg0RecursiveArg1(
    String arg0,
    String arg1,
  ) {
    return 'Inisialisasi seperti yang diperlukan dan periksa persis $arg0. Rekursif: $arg1.';
  }

  @override
  String gitUiApplyTheReviewedSubmoduleConfigurationOperationRecursiveArg0(
    String arg0,
  ) {
    return 'Terapkan operasi konfigurasi submodule yang ditinjau. Rekursif: $arg0.';
  }

  @override
  String get gitUiApplySubmoduleOperation => 'Terapkan operasi submodule';

  @override
  String get gitUiInspectARecordedRevisionOrCreateARecoveryBranchReflog =>
      'Inspeksi suatu revisi yang direkam atau buat suatu branch pemulihan. Reflog tidak memulihkan isi yang tidak disimpan atau tidak tertuntut secara sewenang-wenang.';

  @override
  String get gitUiSelectAReflogEntry => 'Pilih entri reflog';

  @override
  String get gitUiPreviousPage => 'Halaman sebelumnya';

  @override
  String get gitUiNextPage => 'Halaman berikutnya';

  @override
  String get gitUiRecoveryBranchName => 'Nama branch pemulihan';

  @override
  String gitUiCreatesABranchAtArg0WorkingFilesAndTheCurrent(String arg0) {
    return 'Membuat cabang di $arg0; berkas kerja dan cabang yang sekarang tidak berubah.';
  }

  @override
  String get gitUiCreateRecoveryBranch => 'Buat branch pemulihan...';

  @override
  String get gitUiReadOnlyRecoverySnapshot => 'Foto pemulihan hanya-baca';

  @override
  String get gitUiInspectSnapshot => 'Inspeksi foto...';

  @override
  String get gitUiReviewReset => 'Tinjau reset…';

  @override
  String gitUiPageArg0(String arg0) {
    return 'Halaman $arg0';
  }

  @override
  String get gitUiAGitTextHistoryMustOwnItsEditableField =>
      'Riwayat teks Git harus memiliki ruas yang dapat disunting.';

  @override
  String get gitUiEditHEADIndexWorkingTree =>
      'Edit HEAD | Indeks | Pohon kerja…';

  @override
  String
  get gitUiTheReviewedIndexOrWorkingContentChangedRefreshThisComparison =>
      'Indeks atau isi kerja yang ditinjau berubah. Segarkan perbandingan ini sebelum pementasan.';

  @override
  String get gitUiRefreshComparison => 'Perbarui perbandingan';

  @override
  String get gitUiPreviousChangedFile => 'Berkas sebelumnya berubah';

  @override
  String get gitUiNextChangedFile => 'Berkas berikutnya berubah';

  @override
  String get gitUiPreviousDifference => 'Perbedaan sebelumnya';

  @override
  String get gitUiNextDifference => 'Perbedaan berikutnya';

  @override
  String get gitUiComparisonMode => 'Mode perbandingan';

  @override
  String get gitUiSideBySide => '# Berdampingan #';

  @override
  String get gitUiUnified => 'unified';

  @override
  String get gitUiDiffDisplayOptions => 'Diff opsi tampilan';

  @override
  String get gitUiWrap => 'Lipat';

  @override
  String get gitUiWords => 'Kata';

  @override
  String get gitUiCollapseContext => 'Ciutkan konteks';

  @override
  String get gitUiIgnoreWhitespace => 'Abaikan whitespace';

  @override
  String get gitUiSearchComparison => 'Perbandingan pencarian';

  @override
  String get gitUiSearch => 'Cari';

  @override
  String get gitUiCloseSearch => 'Tutup pencarian';

  @override
  String get gitUiStagingActions => 'Tindakan indeks';

  @override
  String get gitUiStagingActions2 => 'Tindakan indeks…';

  @override
  String get gitUiUnstageSelectedChangedLines =>
      'Unstage baris perubahan terpilih';

  @override
  String get gitUiStageSelectedChangedLines => 'Stage baris perubahan terpilih';

  @override
  String get gitUiUnstageWholeFile => 'Unstage seluruh berkas';

  @override
  String get gitUiStageWholeFile => 'Stage seluruh berkas';

  @override
  String gitUiArg0WhitespaceOnlyChangedLinesHiddenShowExactChanges(
    String arg0,
  ) {
    return '$arg0 whitespace-only mengubah baris tersembunyi · Tampilkan perubahan yang tepat';
  }

  @override
  String gitUiArg0ChangedLinesSelectedDisplaySettingsNeverAlterTheStaged(
    String arg0,
  ) {
    return '$arg0 mengubah baris yang dipilih · Pengaturan Tampilan tidak pernah mengubah byte dipentaskan.';
  }

  @override
  String get gitUiReadOnlyComparisonCopyTextOrAdjustDisplaySettings =>
      'Perbandingan hanya baca · Salin teks atau sesuaikan tampilan.';

  @override
  String get gitUiNoFinalNewline => ' · tidak ada baris baru terakhir';

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
      'Perbandingan teks tidak tersedia bagi isi ini.';

  @override
  String get gitUiThisComparisonExceedsTheBoundedTextReviewLimitTheContents =>
      'Perbandingan ini melebihi batas tinjauan teks yang terbatas. Isi belum dinyatakan identik.';

  @override
  String get gitUiTheComparedContentsAreIdentical =>
      'Isi perbandingannya sama.';

  @override
  String get gitUiUnstage => 'Batalkan Men-stage';

  @override
  String get gitUiStage => 'Tahap';

  @override
  String gitUiArg0ChangedLine(String arg0) {
    return '$arg0 berubah baris';
  }

  @override
  String get gitUiContext => 'Konteks';

  @override
  String get gitUiExpandUnchangedContext => 'Perluas konteks tidak berubah';

  @override
  String get gitUiUnstageThisHunk => 'Unstage hunk ini';

  @override
  String get gitUiStageThisHunk => 'Stage hunk ini';

  @override
  String gitUiEditStagedContentArg0(String arg0) {
    return 'Sunting konten yang dipentaskan · $arg0';
  }

  @override
  String get gitUiWritingReviewedIndexResult =>
      'Menulis hasil indeks yang ditinjau';

  @override
  String get gitUiHead => 'HEAD';

  @override
  String get gitUiIndex => 'Indeks';

  @override
  String get gitUiWorkingTree => 'Pohon kerja';

  @override
  String gitUiHeadArg0(String arg0) {
    return 'HEAD · $arg0';
  }

  @override
  String get gitUiIndexEditableUTF8Blob => 'Indeks · disunting UTF-8 gumpalan';

  @override
  String get gitUiUndo => 'Urungkan';

  @override
  String get gitUiRedo => 'Ulangi';

  @override
  String get gitUiReloadIndexReview => 'Muat ulang indeks review?';

  @override
  String get gitUiReloadTheCurrentHEADIndexAndWorkingVersionsThisReplaces =>
      'Muat ulang versi HEAD, indeks, dan kerja saat ini. Ini mengganti draf editor indeks yang belum disimpan.';

  @override
  String get gitUiReplaceDraftAndReload => 'Gantikan draft dan muat ulang';

  @override
  String get gitUiReloadVersions => 'Muat ulang versi...';

  @override
  String get gitUiWriteEditedResultToThisIndexEntry =>
      'Tulis hasil yang disunting ke entri indeks ini';

  @override
  String get gitUiWorkingFilesRemainOnDiskReviewTheEditedIndexBefore =>
      'Berkas kerja tetap pada disk. Tinjau indeks yang diedit sebelum diterapkan.';

  @override
  String get gitUiReviewIndexTextFormatChanges =>
      'Tinjau perubahan format indeks teks';

  @override
  String gitUiUpdateOnlyTheReviewedIndexEntryForArg0Arg1(
    String arg0,
    String arg1,
  ) {
    return 'Perbarui hanya masukan indeks yang ditinjau untuk $arg0. $arg1';
  }

  @override
  String get gitUiWriteReviewedIndexResult =>
      'Tulis hasil indeks yang ditinjau';

  @override
  String get gitUiTheEditedResultChangedDuringFormatReviewReviewItAgain =>
      'Hasil yang disunting berubah selama tinjauan format. Tinjau lagi.';

  @override
  String get gitUiSynchronizeScrolling => 'Sinkronisasi penggulungan';

  @override
  String get gitUiReadOnlyRevisionContent => 'Isi revisi hanya-baca';

  @override
  String get gitUiEditableIndexContent => 'Isi indeks dapat disunting';

  @override
  String get gitUiTheRequestedRevisionIsOutsideTheCurrentFiltersResetFilters =>
      'Revisi yang diminta berada di luar penyaring saat ini. Reset penyaring untuk mengungkapkannya.';

  @override
  String get gitUiFilterLog => 'Filter riwayat';

  @override
  String get gitUiFilters => 'Filter...';

  @override
  String gitUiFiltersCount(String count) {
    return 'Filter ($count)...';
  }

  @override
  String get gitUiMessage => 'Pesan…';

  @override
  String get gitUiAuthor => 'Penulis…';

  @override
  String get gitUiPath => 'Path...';

  @override
  String get gitUiDate => 'Tanggal...';

  @override
  String get gitUiMessageFilter => 'Filter pesan';

  @override
  String get gitUiAuthorFilter => 'Filter penulis';

  @override
  String get gitUiPathFilter => 'Filter tapak';

  @override
  String get gitUiMessage2 => 'Pesan';

  @override
  String get gitUiAuthor2 => 'Penulis';

  @override
  String get gitUiPath2 => 'Jalur';

  @override
  String get gitUiDateFilter => 'Penyaring tanggal...';

  @override
  String get gitUiResetFilters => 'Reset penyaring';

  @override
  String get gitUiRefreshLog => 'Log Segarkan';

  @override
  String get gitUiGoToCommitReference => 'Pergi ke commit/referensi...';

  @override
  String get gitUiBackToHEAD => 'Kembali ke HEAD';

  @override
  String get gitUiOrderedCherryPick => 'Cherry-pick sesuai urutan yang dipilih';

  @override
  String gitUiReviewCherryPickArg0(String arg0) {
    return 'Tinjau cherry-pick ($arg0)...';
  }

  @override
  String get gitUiCompareTwoSelectedRevisions =>
      'Bandingkan dua revisi terpilih...';

  @override
  String get gitUiToggleBranchesPane => 'Jungkitkan panel percabangan';

  @override
  String get gitUiFilterBranchesAndTags => 'Filter branch dan tag';

  @override
  String gitUiCommitArg0(String arg0) {
    return 'Commit $arg0';
  }

  @override
  String get gitUiCommitDetails => 'Commit rincian...';

  @override
  String gitUiReferenceArg0(String arg0) {
    return 'Referensi: $arg0';
  }

  @override
  String get gitUiSelectThisCommit => 'Pilih commit ini';

  @override
  String get gitUiBranchOrTag => 'Branch atau tag';

  @override
  String get gitUiAllReferences => 'Semua referensi';

  @override
  String get gitUiLocal => 'Lokal';

  @override
  String get gitUiRemote => 'Remote';

  @override
  String get gitUiTags => 'Tag';

  @override
  String get gitUiNoCommitsMatchTheCurrentFilters =>
      'Tak ada commit yang cocok dengan penyaring saat ini.';

  @override
  String get gitUiObjectID => 'ID Obyek';

  @override
  String get gitUiSubjectReferences => 'Subjek / referensi';

  @override
  String get gitUiDate2 => 'Tanggal';

  @override
  String get gitUiGitCommits => 'Commit Git';

  @override
  String get gitUiParents => 'Commit induk';

  @override
  String gitUiArg0Parents(String arg0) {
    return '$arg0 orang tua';
  }

  @override
  String get gitUiLoadMoreCommits => 'Muat lebih banyak commit';

  @override
  String get gitUiLoadingChangedFiles => 'Memuat berkas yang berubah';

  @override
  String get gitUiNoChangedFiles => 'Tidak ada berkas yang berubah';

  @override
  String get gitUiSelectACommit => 'Pilih suatu commit';

  @override
  String gitUiCompareParentArg0Arg1(String arg0, String arg1) {
    return 'Bandingkan induk $arg0: $arg1';
  }

  @override
  String get gitUiChangedFiles => 'Berkas yang berubah';

  @override
  String gitUiAuthorArg0Arg1Arg2(String arg0, String arg1, String arg2) {
    return 'Penulis: $arg0 <$arg1> $arg2';
  }

  @override
  String gitUiCommitterArg0Arg1Arg2(String arg0, String arg1, String arg2) {
    return 'Committer: $arg0 <$arg1> $arg2';
  }

  @override
  String get gitUiShallowPartialBoundaryAParentObjectIsUnavailable =>
      'Batas shallow/partial: sebuah objek induk tidak tersedia.';

  @override
  String get gitUiParentIsOutsideThisPageOrAShallowBoundary =>
      'Orang tua berada di luar halaman ini atau batas yang dangkal.';

  @override
  String gitUiParentArg0(String arg0) {
    return 'Commit induk $arg0';
  }

  @override
  String get gitUiCommitActions => 'Commit tindakan...';

  @override
  String get gitUiEmptyTree => 'pohon kosong';

  @override
  String get gitUiCreateBranch2 => 'Buat cabang';

  @override
  String get gitUiCreateTag => 'Buat tag';

  @override
  String get gitUiCompareRevisions => 'Bandingkan revisi';

  @override
  String get gitUiOpenSnapshot => 'Buka snapshot';

  @override
  String get gitUiRevertCommit => 'Putar balik suatu commit';

  @override
  String get gitUiInteractiveRebaseAfterThisBoundary =>
      'Rebase interaktif setelah batas ini';

  @override
  String get gitUiResetCurrentBranch => 'Reset cabang saat ini';

  @override
  String get gitUiCopyFullObjectID => 'Salin ID objek penuh';

  @override
  String get gitUiGoToCommitReference2 => 'Pergi ke commit/referensi';

  @override
  String get gitUiEnterACommitIDOrReferenceToRevealInLog =>
      'Masukkan ID commit atau referensi untuk mengungkapkannya dalam Log.';

  @override
  String get gitUiTheRequestedRevisionIsUnavailable =>
      'Revisi yang diminta tidak tersedia.';

  @override
  String
  get gitUiRepositoryMetadataIsReadOnlyBranchInspectionAndComparisonRemain =>
      'Metadata repositori hanya dapat dibaca. Inspeksi dan perbandingan branch tetap tersedia.';

  @override
  String get gitUiWorkingFilesAreUnavailableOrReadOnlyBranchSwitchingAnd =>
      'Berkas kerja tidak tersedia atau hanya-baca. Pengalihan branch dan penggabungan tidak tersedia.';

  @override
  String get gitUiSearchBranchesAndTags => 'Cari cabang dan tag';

  @override
  String get gitUiNewBranch => 'Cabang baru…';

  @override
  String get gitUiLocalBranches => 'Cabang lokal';

  @override
  String get gitUiRemoteBranches => 'Cabang remote';

  @override
  String gitUiTracksArg0(String arg0) {
    return 'Trek $arg0';
  }

  @override
  String gitUiCheckedOutAtArg0(String arg0) {
    return 'Checked out di $arg0';
  }

  @override
  String get gitUiRefreshingBranchMetadata => 'Menyegarkan metadata branch';

  @override
  String gitUiSwitchToArg0(String arg0) {
    return 'Ganti ke $arg0';
  }

  @override
  String get gitUiOpenOccupiedWorktree => 'Buka worktree yang ditempati';

  @override
  String get gitUiCreateLocalTrackingBranch => 'Buat branch pelacakan lokal...';

  @override
  String get gitUiCompareToCurrentHEAD => 'Bandingkan dengan HEAD saat ini';

  @override
  String get gitUiMergeIntoCurrentBranch => 'Gabung ke branch kini...';

  @override
  String get gitUiRename => 'Ganti Nama...';

  @override
  String get gitUiChangeUpstream => 'Ubah hulu...';

  @override
  String get gitUiDelete => 'Hapus...';

  @override
  String get gitUiDeleteFromRemote => 'Hapus dari remote...';

  @override
  String gitUiActionsForArg0(String arg0) {
    return 'Aksi untuk $arg0';
  }

  @override
  String get gitUiLocalBranchName => 'Nama branch lokal';

  @override
  String gitUiCreateAtArg0TheNewBranchWillBeCheckedOut(String arg0) {
    return 'Buat di $arg0. Cabang baru akan diperiksa.';
  }

  @override
  String gitUiTheLocalBranchWillTrackArg0AndBeCheckedOut(String arg0) {
    return 'Kantor cabang lokal akan melacak $arg0 dan diperiksa.';
  }

  @override
  String get gitUiChooseRemoteForDeletion => 'Pilih remote untuk penghapusan';

  @override
  String get gitUiDeleteRemoteReference => 'Hapus referensi remote';

  @override
  String gitUiMergeArg0IntoArg1(String arg0, String arg1) {
    return 'Gabungkan $arg0 ke $arg1';
  }

  @override
  String gitUiRenameArg0(String arg0) {
    return 'Ubah nama $arg0';
  }

  @override
  String gitUiUpstreamForArg0(String arg0) {
    return 'Hulu untuk $arg0';
  }

  @override
  String get gitUiNoUpstream => 'Tanpa upstream';

  @override
  String gitUiDeleteArg0(String arg0) {
    return 'Hapus $arg0?';
  }

  @override
  String gitUiArg0TargetArg1LocalDeletionOnlyAnUnmergedBranchIs(
    String arg0,
    String arg1,
  ) {
    return '$arg0 Target $arg1 Pemusnahan Lokal saja. Sebuah cabang yang tidak dipangkas ditolak.';
  }

  @override
  String get gitUiDelete2 => 'Hapus';

  @override
  String gitUiDeleteUnmergedBranchArg0(String arg0) {
    return 'Hapus branch $arg0 yang tak tertanda?';
  }

  @override
  String gitUiArg0GitReportsThisBranchIsNotFullyMergedExplicitly(String arg0) {
    return '$arg0 Git melaporkan bahwa cabang ini tidak digabung secara penuh. Dengan eksplisit hapus referensi lokal setelah meninjau kembali komitmennya; salinan remote tidak berubah.';
  }

  @override
  String get gitUiDeleteUnmergedLocalBranch =>
      'Hapus branch lokal yang belum di-mergasikan';

  @override
  String gitUiDestinationArg0Arg1(String arg0, String arg1) {
    return 'Tujuan: $arg0 $arg1';
  }

  @override
  String get gitUiSourceBranchOrTag => 'Cabang sumber atau tag';

  @override
  String get gitUiMergePolicy => 'Gabung kebijakan';

  @override
  String get gitUiFastForwardWhenPossible => 'Percepat bila mungkin';

  @override
  String get gitUiAlwaysCreateAMergeCommit => 'Selalu buat suatu commit merge';

  @override
  String get gitUiFastForwardOnly => 'Hanya maju-cepat saja';

  @override
  String get gitUiSquashIntoStagedChanges =>
      'Squash ke perubahan yang dipentaskan';

  @override
  String get gitUiStopBeforeCreatingTheMergeCommit =>
      'Berhenti sebelum membuat komit merge';

  @override
  String get gitUiFastForwardIsDisabledSoHEADCannotMoveBeforeReview =>
      'Fast-forward dinonaktifkan agar HEAD tidak berpindah sebelum peninjauan.';

  @override
  String get gitUiLeavesStagedChangesForASeparateCommitThisIsNot =>
      'Dedaunan dipentaskan perubahan bagi suatu commit terpisah; ini bukan gabungan yang berkelanjutan.';

  @override
  String get gitUiConflictsRemainAvailableInTheSharedResolutionWorkspace =>
      'Konflik tetap tersedia dalam ruang kerja resolusi bersama.';

  @override
  String get gitUiAddRemote => 'Tambah remote...';

  @override
  String gitUiFetchArg0PushArg1(String arg0, String arg1) {
    return 'Fetch: $arg0 Push: $arg1';
  }

  @override
  String get gitUiRemoveRemote => 'Hapus remote...';

  @override
  String get gitUiChangeFetchURL => 'Ubah URL pengambilan...';

  @override
  String get gitUiAddPushDestination => 'Tambah tujuan push...';

  @override
  String get gitUiRemovePushDestination => 'Hapus tujuan push...';

  @override
  String gitUiManageArg0(String arg0) {
    return 'Kelola $arg0';
  }

  @override
  String get gitUiRemoteName => 'Nama remote';

  @override
  String get gitUiNewRemoteName => 'Nama remote baru';

  @override
  String get gitUiRepositoryURLOrLocalSource =>
      'URL repositori atau sumber lokal';

  @override
  String get gitUiEnterTheExactReviewedDestinationToRemove =>
      'Masukkan tujuan yang tepat untuk dihapus.';

  @override
  String get gitUiCredentialsAreSuppliedByConfiguredHelpersOrAPrivatePrompt =>
      'Kredensial disediakan oleh pembantu yang dikonfigurasi atau prompt pribadi.';

  @override
  String gitUiRemoveRemoteArg0(String arg0) {
    return 'Hapus $arg0 jauh?';
  }

  @override
  String
  get gitUiRemovesLocalRemoteConfigurationAndTrackingReferencesItDoesNot =>
      'Hapus konfigurasi lokal dan referensi pelacakan. Ini tidak menghapus repositori server.';

  @override
  String get gitUiRemoveRemote2 => 'Hapus remote';

  @override
  String get gitUiCommitScopeEntireRepository =>
      'Lingkup commit: seluruh repositori';

  @override
  String get gitUiCachedTracking => 'Pelacakan Cached';

  @override
  String get gitUiAmendLastCommit => 'Ubah commit terakhir';

  @override
  String get gitUiConfiguredHooksAndSigningAreRespected =>
      'Pengatur kait dan penandatanganan dihormati.';

  @override
  String get gitUiRewritesTheSelectedHEADCommitRemoteTrackingCannotProveIt =>
      'Menulis ulang commit HEAD yang dipilih. Pelacakan remote tidak membuktikan bahwa commit belum dipublikasikan.';

  @override
  String get gitUiRepository => 'Repositori';

  @override
  String gitUiDetachedArg0(String arg0) {
    return 'Dilepas $arg0';
  }

  @override
  String get gitUiLog => 'Riwayat';

  @override
  String get gitUiRepositoryActions => 'Tindakan repositori';

  @override
  String gitUiCachedTrackingUpstreamAheadAheadBehindBehind(
    String upstream,
    String ahead,
    String behind,
  ) {
    return 'Pelacakan tersimpan · $upstream · $ahead di depan · $behind di belakang';
  }

  @override
  String get gitUiBareRepositoryNoWorkingTreeOpenLogToInspectIts =>
      'Tak ada pohon yang berfungsi. Buka Log untuk memeriksa riwayatnya.';

  @override
  String get gitUiReadOnlyRepositoryStagingAndCommitsAreUnavailable =>
      'Repositori hanya-baca · pementasan dan commit tidak tersedia.';

  @override
  String get gitUiRepositoryStatusUnavailable =>
      'Status repositori tidak tersedia';

  @override
  String gitUiAmendRevision(String revision) {
    return 'Ubah $revision';
  }

  @override
  String get gitUiAddSignOffTrailer => 'Tambahkan baris persetujuan';

  @override
  String get gitUiUseConfiguredSigningPolicy =>
      'Gunakan kebijakan penandatanganan yang dikonfigurasi';

  @override
  String get gitUiCryptographicallySignThisCommit =>
      'Tanda tangani secara kriptografi commit ini';

  @override
  String get gitUiDoNotSignThisCommit => 'Jangan tanda tangani commit ini';

  @override
  String get gitUiRecentCommitMessages => 'Pesan commit baru-baru ini...';

  @override
  String get gitUiUseConfiguredCommitTemplate =>
      'Gunakan templat commit yang dikonfigurasi...';

  @override
  String get gitUiAuthorIdentityAndConfiguredHooks =>
      'Identitas penulis dan kait yang dikonfigurasi...';

  @override
  String get gitUiDraftMessage => 'Pesan singkat...';

  @override
  String get gitUiCommitOptions => 'Opsi commit';

  @override
  String gitUiDraftRetainedInMemorySavingItFailedArg0(String arg0) {
    return 'Draft dipertahankan dalam memori; menyimpannya gagal. $arg0';
  }

  @override
  String get gitUiCommitMessage => 'Pesan commit';

  @override
  String get gitUiGitOperationInProgress => 'Operasi git sedang berlangsung';

  @override
  String get gitUiCancel => 'Batal';

  @override
  String get gitUiAmendStaged => 'Amend dipentaskan';

  @override
  String gitUiCommitStagedCount(String count) {
    return 'Commit perubahan di indeks ($count)';
  }

  @override
  String get gitUiCommitAndPush => 'Commit dan push…';

  @override
  String get gitUiNoReadableCommitTemplateIsConfigured =>
      'Tidak ada templat commit yang dapat dibaca yang dikonfigurasi.';

  @override
  String get gitUiCommitIdentityAndHooks => 'Commit identitas dan kait';

  @override
  String get gitUiRecentMessages => 'Pesan baru-baru Ini';

  @override
  String get gitUiReplaceMessageDraft => 'Ganti draf pesan?';

  @override
  String get gitUiReplaceTheExistingCommitMessageWithTheSelectedMessage =>
      'Ganti pesan commit yang ada dengan pesan yang dipilih?';

  @override
  String get gitUiReplaceDraft => 'Ganti draft';

  @override
  String gitUiLocalCommitArg0Exists(String arg0) {
    return 'Komit lokal $arg0 ada.';
  }

  @override
  String gitUiLocalCommitArg0ExistsReviewLogBeforeAttemptingAnotherCommit(
    String arg0,
  ) {
    return 'Komit lokal $arg0 ada. Tinjau Log sebelum mencoba commit lain. draft pesan telah disimpan.';
  }

  @override
  String get gitUiCommitAuthorName => 'Commit nama penulis';

  @override
  String get gitUiCommitAuthorEmail => 'Commit surel penulis';

  @override
  String get gitUiConfiguredDefault => 'konfigurasi baku';

  @override
  String get gitUiOpenpgp => 'OpenPGP';

  @override
  String gitUiSigningArg0Arg1(String arg0, String arg1) {
    return 'Signing: $arg0 $arg1';
  }

  @override
  String gitUiConfiguredHooksArg0(String arg0) {
    return 'Kait yang dikonfigurasi: $arg0';
  }

  @override
  String get gitUiASignOffTrailerIsAStatementInTheMessage =>
      'Baris persetujuan adalah pernyataan dalam pesan, terpisah dari tanda tangan kriptografis. Identitas hanya disimpan pada konfigurasi lokal repositori ini; draf tetap tersimpan.';

  @override
  String get gitUiSaveRepositoryIdentity => 'Simpan identitas repositori';

  @override
  String get gitUiStaged => 'Sudah di-stage';

  @override
  String get gitUiUntracked => 'Tidak dilacak';

  @override
  String get gitUiUnstaged => 'Belum di-stage';

  @override
  String get gitUiConflicts => 'Konflik';

  @override
  String get gitUiNoChanges => 'Tidak ada perubahan';

  @override
  String get gitUiRepositoryChangeTree => 'tree perubahan repositori';

  @override
  String get gitUiChanges => 'Perubahan';

  @override
  String gitUiGroupCount(String group, String count) {
    return '$group ($count)';
  }

  @override
  String get gitUiExpand => 'Ekspansi';

  @override
  String get gitUiCollapse => 'Runtuh';

  @override
  String get gitUiUnstageFile => 'Unstage berkas';

  @override
  String get gitUiStageFile => 'Stage berkas';

  @override
  String get gitUiExpandGroup => 'Perluas grup';

  @override
  String get gitUiCollapseGroup => 'Runtuhkan kelompok';

  @override
  String get gitUiReviewDifference => 'Perbedaan ulasan';

  @override
  String get gitUiUnstageSelectedFiles => 'Unstage berkas terpilih';

  @override
  String get gitUiStageSelectedFiles => 'Stage berkas terpilih';

  @override
  String get gitUiFileHistoryAndBlame => 'Sejarah berkas dan menyalahkan...';

  @override
  String get gitUiDeleteUntrackedFile => 'Hapus berkas yang tidak dilacak...';

  @override
  String get gitUiDiscardUnstagedChange =>
      'Buang perubahan yang belum ter-stage...';

  @override
  String get gitUiFileHistory => 'Riwayat berkas';

  @override
  String gitUiDiscardUnstagedArg0(String arg0) {
    return 'Buang $arg0 yang tak ter-stage?';
  }

  @override
  String gitUiArg0BytesArg1ReplacesWorkingContentWithTheIndexOr(
    String arg0,
    String arg1,
  ) {
    return '$arg0 bytes · $arg1 Ganti konten kerja dengan indeks, atau hapus berkas yang tidak dilacak ini. Isi yang belum disimpan tetap. Dokumen host harus ditinjau terlebih dahulu.';
  }

  @override
  String get gitUiDeleteUntrackedFile2 => 'Hapus berkas yang tidak dilacak';

  @override
  String get gitUiDiscardWorkingChange => 'Buang perubahan kerja';

  @override
  String gitUiDeleteREMOTEReferenceArg0(String arg0) {
    return 'Hapus referensi REMOTE $arg0';
  }

  @override
  String get gitUiThisRemovesTheReferenceOnEveryActualPushDestinationListed =>
      'Ini menghapus referensi pada setiap tujuan push yang sebenarnya yang terdaftar di bawah ini. Branch/tag lokal dipertahankan. Tip yang diharapkan tetap oleh ulasan ini.';

  @override
  String get gitUiReferenceDoesNotExist => 'referensi tidak ada';

  @override
  String gitUiArg0ExpectedTipArg1(String arg0, String arg1) {
    return '$arg0 Diduga tip: $arg1';
  }

  @override
  String get gitUiRemoteDeletionCompleted => 'Penghapusan jarak jauh selesai.';

  @override
  String gitUiDeleteArg0FromTheRemote(String arg0) {
    return 'Hapus $arg0 dari remote?';
  }

  @override
  String get gitUiTheExactDestinationTipsShownAboveWillBeRemovedAny =>
      'Tips tujuan yang ditunjukkan di atas akan dihapus. Ujung remote yang diubah menghentikan operasi untuk ulasan lain.';

  @override
  String get gitUiReviewAndDeleteFromRemote =>
      'Tinjau dan hapus dari remote...';

  @override
  String get gitUiDestinationReference => 'Referensi tujuan';

  @override
  String get gitUiReviewDestinations => 'Meninjau tujuan';

  @override
  String get gitUiNewRemoteBranch => 'branch jauh baru';

  @override
  String gitUiArg0Arg1ExpectedArg2(String arg0, String arg1, String arg2) {
    return '$arg0\n$arg1 · diharapkan: $arg2';
  }

  @override
  String get gitUiADestinationHasCommitsThatAreUnavailableLocallyFetchThat =>
      'Sebuah tujuan memiliki komitmen yang tidak tersedia secara lokal. Ambil tujuan yang ditinjau sebelum meninjau sejarah keluar.';

  @override
  String get gitUiFetchReviewedDestination => 'Ambil tujuan yang ditinjau';

  @override
  String get gitUiChooseADestinationAndReviewTheOutgoingCommits =>
      'Pilih suatu tujuan dan tinjau kembali komitmen keluar.';

  @override
  String get gitUiNoOutgoingCommits => 'Tidak ada komitmen keluar';

  @override
  String get gitUiSelectAnOutgoingCommit => 'Pilih suatu commit keluar';

  @override
  String get gitUiLoadMoreOutgoingCommits => 'Muat lebih banyak commit keluar';

  @override
  String get gitUiSetThisDestinationAsUpstream =>
      'Atur tujuan ini sebagai hulu';

  @override
  String get gitUiChooseExactTagsToPublish =>
      'Pilih tag yang tepat untuk diterbitkan';

  @override
  String get gitUiTagsNone => 'Tag: kosong';

  @override
  String gitUiTagsArg0Selected(String arg0) {
    return 'Tag: $arg0 dipilih';
  }

  @override
  String gitUiPublishExactlyArg0(String arg0) {
    return 'Terbitkan persis: $arg0';
  }

  @override
  String get gitUiPushCompletedTheLocalCommitRemainsAvailableInLog =>
      'Push selesai. Commit lokal tetap tersedia dalam Log.';

  @override
  String get gitUiForceRequiresTheExactDestinationTipsShownInThisReview =>
      'Push paksa mensyaratkan ujung referensi tujuan sama persis dengan yang ditinjau di sini.';

  @override
  String get gitUiForceWithReviewedLease => 'Paksa sewa yang diperiksa...';

  @override
  String get gitUiPush => 'Push';

  @override
  String get gitUiForcePushWithReviewedLeases =>
      'Dorongan paksa dengan harga sewa yang ditinjau?';

  @override
  String gitUiRewriteArg0OnlyIfEveryRemoteDestinationStillHasThe(String arg0) {
    return 'Tulis ulang $arg0 hanya jika setiap tujuan jauh masih memiliki tip tepat yang ditampilkan di atas.\n';
  }

  @override
  String get gitUiOtherPeopleMayAlreadyUseThisHistoryABackgroundFetch =>
      'Orang lain mungkin sudah menggunakan riwayat ini. Fetch di latar belakang tidak memperbarui syarat keamanan ini.';

  @override
  String get gitUiForceWithLease => 'Paksa dengan sewa';

  @override
  String
  get gitUiTheRemoteOutcomeIsUncertainReviewDestinationsAgainBeforeAnother =>
      'Hasil yang jauh tidak pasti.';

  @override
  String gitUiParentArg0Arg1(String arg0, String arg1) {
    return 'Induk $arg0 $arg1';
  }

  @override
  String get gitUiRemoteToFetch => 'Jauh untuk mengambil';

  @override
  String get gitUiPruneDeletedRemoteTrackingBranches =>
      'Prune dihapus branch remote-tracking';

  @override
  String
  get gitUiFetchUpdatesRemoteTrackingInformationWithoutReplacingWorkingFiles =>
      'Ambil pemutakhiran informasi pelacakan jarak jauh tanpa mengganti berkas kerja.';

  @override
  String get gitUiFetch => 'Fetch';

  @override
  String get gitUiSourceRemote => 'Remote sumber';

  @override
  String get gitUiSourceBranch => 'Cabang sumber';

  @override
  String get gitUiReviewedStrategy => 'Strategi yang ditinjau';

  @override
  String get gitUiMerge => 'Gabung';

  @override
  String get gitUiRebase => 'Rebase';

  @override
  String get gitUiStopIfTheDestinationCannotFastForwardNeverMergeOr =>
      'Berhenti jika tujuan tidak dapat mempercepat; jangan menggabungkan atau rebase.';

  @override
  String get gitUiMergeWithAMergeCommitIncludingWhenFastForwardIs =>
      'Gabung dengan suatu commit gabungan, termasuk ketika maju-cepat mungkin.';

  @override
  String get gitUiMergeAllowFastForwardWhenPossible =>
      'Gabung; ijinkan maju-cepat bila memungkinkan.';

  @override
  String get gitUiRebaseLocalHistoryWhilePreservingLocalMergeCommits =>
      'Rebase sejarah lokal ketika melestarikan komit gabungan lokal.';

  @override
  String get gitUiRebaseLocalCommitsAsALinearHistory =>
      'Rebase lokal commits sebagai sejarah linear.';

  @override
  String get gitUiGitIsConfiguredForInteractiveRebaseSelectAPullStrategy =>
      'Git ditata untuk rebase interaktif. Pilih strategi tarik secara eksplisit di sini, atau ambil dan buka Rebase... untuk meninjau rencana.';

  @override
  String get gitUiUseReviewedOrdinaryRebaseForThisPull =>
      'Gunakan rebase biasa yang ditinjau untuk tarikan ini';

  @override
  String get gitUiOptions => 'Opsi';

  @override
  String get gitUiAlwaysCreateAMergeCommitNoFastForward =>
      'Selalu buat suatu commit merge (tidak maju-cepat)';

  @override
  String get gitUiPreserveLocalMergeCommits =>
      'Pertahankan commit gabungan lokal';

  @override
  String get gitUiLocalChangesMayPreventPullReviewCommitThemOrExplicitly =>
      'Perubahan lokal mungkin mencegah pull. Review/commit mereka atau secara eksplisit membuat suatu stash.';

  @override
  String get gitUiStashes => 'Stash';

  @override
  String get gitUiCreateOrReviewStash => 'Buat atau tinjau stash...';

  @override
  String get gitUiPullWithSelectedStrategy =>
      'Tarik dengan strategi yang dipilih';

  @override
  String get gitUiRepositoryURLOrLocalGitSource =>
      'URL repositori atau sumber lokal Git';

  @override
  String get gitUiHttpsSSHOrLocalPath => 'HTTPS, SSH, atau path lokal';

  @override
  String get gitUiFolderToInitialize => 'Folder untuk diinisialisasi';

  @override
  String get gitUiFinalCloneDestination => 'Tujuan klon akhir';

  @override
  String get gitUiChoose => 'Pilih...';

  @override
  String get gitUiCreatesGitMetadataOnlyExistingFilesAreNotStagedOr =>
      'Membuat metadata Git saja. Berkas yang telah ada tidak di-stage atau dikomit.';

  @override
  String get gitUiTheFinalDestinationMustBeAbsentOrEmptyExistingUser =>
      'Tujuan akhir harus belum ada atau kosong. Data pengguna yang sudah ada tidak pernah ditimpa.';

  @override
  String get gitUiInitialBranchBlankUsesEffectiveGitPolicy =>
      'Kebijakan Git menggunakan branch awal ·kosong';

  @override
  String get gitUiSelectedBranchOptional => 'Cabang terpilih · opsional';

  @override
  String get gitUiExplicitlyInitializeUpdateSubmodulesRecursively =>
      'Eksplisit inisialisasi/update submodules rekursif';

  @override
  String get gitUiPreparingGitOperation => 'Mempersiapkan operasi Git...';

  @override
  String get gitUiThisAttemptCreated => 'Upaya ini dibuat';

  @override
  String get gitUiTheDestinationExistedBeforeThisAttempt =>
      'Tujuan ada sebelum upaya ini:';

  @override
  String get gitUiTheDirectoryRemainsForInspectionReviewItBeforeAnotherClone =>
      'Direktori tetap untuk pemeriksaan. Tinjau sebelum percobaan kloning lain.';

  @override
  String get gitUiNoDestinationDirectoryRemains =>
      'Tak ada direktori tujuan yang tersisa.';

  @override
  String get gitUiCancelProcess => 'Batalkan proses';

  @override
  String get gitUiInitialize => 'Inisialisasi';

  @override
  String get gitUiClone => 'Klon';

  @override
  String get gitUiChooseNewBase => 'Pilih basis baru';

  @override
  String get gitUiChooseUpstreamBoundary => 'Pilih batas upstream';

  @override
  String get gitUiNewBase => 'Basis baru';

  @override
  String get gitUiUpstreamBoundaryExcluded => 'Batas upstream · dikecualikan';

  @override
  String get gitUiSameAsUpstreamBoundary => 'Sama dengan batas upstream';

  @override
  String get gitUiChooseBranchTagOrCommit => 'Pilih cabang, tag, atau commit…';

  @override
  String get gitUiUseUpstreamAsNewBase => 'Gunakan upstream sebagai basis baru';

  @override
  String get gitUiChooseAValidBranchTagOrCommitFromLog =>
      'Pilih suatu branch, tag, atau commit yang valid dari Log.';

  @override
  String get gitUiTheFirstRetainedCommitInABranchBlockCannotSquash =>
      'Commit pertama yang dipertahankan dalam blok cabang tidak dapat memakai squash atau fixup: tidak ada commit tujuan sebelumnya.';

  @override
  String gitUiBranchBlockArg0(String arg0) {
    return 'Blok cabang $arg0\n';
  }

  @override
  String get gitUiRewordWillRequestANewMessage =>
      '[Kembalikan kata akan meminta pesan baru]\n';

  @override
  String get gitUiPlannedCommitMessages => 'Merencanakan pesan commit';

  @override
  String
  get gitUiOriginalCombinedMessagePreviewGitRequestsTheFinalRewordSquash =>
      'Original/comberined preview pesan · Git meminta pesan akhir/squash';

  @override
  String gitUiResultArg0Arg1(String arg0, String arg1) {
    return 'Hasil $arg0 $arg1';
  }

  @override
  String gitUiCurrentBranchBranch(String branch) {
    return 'Cabang saat ini: $branch';
  }

  @override
  String get gitUiDetachedHEAD2 => 'HEAD terlepas';

  @override
  String
  get gitUiRebaseRewritesCommitIdentitiesRemoteTrackingInformationCannotProveHistory =>
      'Rebase menulis ulang identitas commit. Informasi pelacakan remote tidak membuktikan bahwa riwayat belum pernah dipublikasikan.';

  @override
  String get gitUiIncludeRootCommits => 'Sertakan commit akar';

  @override
  String get gitUiMergeCommits => 'Commit gabungan';

  @override
  String get gitUiFlattenHistory => 'Ratakan riwayat';

  @override
  String get gitUiPreserveBranchStructure => 'Pertahankan struktur cabang';

  @override
  String get gitUiAutosquash => 'Penggabungan otomatis';

  @override
  String get gitUiPrepareGitPlan => 'Siapkan rencana Git';

  @override
  String gitUiCommitsToReplayCount(String count) {
    return 'Commit yang akan diterapkan ulang: $count';
  }

  @override
  String get gitUiIncludesAllRootCommitsReachableFromThisBranch =>
      'Termasuk semua root commit yang dapat dicapai dari branch ini.';

  @override
  String gitUiCommitsAfterBoundaryWillBeReplayedOntoBaseTheBoundary(
    String boundary,
    String base,
  ) {
    return 'Commit setelah $boundary akan diterapkan ulang di atas $base; commit batas itu sendiri tidak disertakan.';
  }

  @override
  String get gitUiRoot => 'Akar';

  @override
  String get gitUiGitBranchLabelResetMergeStructure =>
      'Struktur branch/label/reset/merge Git';

  @override
  String get gitUiChooseAnExplicitOldBoundaryOrRootModeThenPrepare =>
      'Pilih batas atau mode root lama yang eksplisit, lalu siapkan rencana.';

  @override
  String get gitUiMoveUp => 'Pindah ke atas';

  @override
  String get gitUiMoveDown => 'Pindah ke bawah';

  @override
  String get gitUiResetPlan => 'Atur ulang rencana';

  @override
  String gitUiBranchBlockArg02(String arg0) {
    return ' · blok cabang $arg0';
  }

  @override
  String get gitUiSelectACommitForDetailsAndChangedFiles =>
      'Pilih suatu commit untuk rincian dan berkas yang berubah';

  @override
  String get gitUiPreviewCombinedCommitMessages =>
      'Pratilik gabungan surat commit...';

  @override
  String get gitUiAltMovesTheSelectedCommitUnrelatedBranchReferencesWillNot =>
      'Alt+↑/↓ memindahkan commit yang dipilih. Referensi cabang yang tidak terkait tidak akan diperbarui secara otomatis.';

  @override
  String get gitUiCancelPlan => 'Batalkan rencana';

  @override
  String get gitUiStartReviewedRebase => 'Mulai rebase yang telah ditinjau?';

  @override
  String gitUiRewriteArg0PlannedCommitsOnArg1DroppedCommitsRemainVisibly(
    String arg0,
    String arg1,
  ) {
    return 'Tulis ulang $arg0 yang direncanakan pada $arg1, menjatuhkan commit tetap terlihat dalam rencana ini sampai Anda mulai.';
  }

  @override
  String get gitUiStartRebase => 'Mulai rebase';

  @override
  String get gitUiNoContinuingGitOperation =>
      'Tak ada operasi git yang dilanjutkan';

  @override
  String get gitUiStoppedForEditingAmend =>
      ' · dihentikan untuk penyuntingan/amen';

  @override
  String get gitUiTheseAreUnmergedIndexEntriesPossiblyFromAStashApplication =>
      'Ini adalah masukan indeks yang tak terukur, mungkin dari aplikasi stash. Git tidak memiliki stash melanjutkan atau membatalkan perintah.';

  @override
  String get gitUiEditTheWorkingFilesStageAndAmendTheCurrentCommit =>
      'Sunting berkas kerja, panggung, dan ubah commit saat ini, lalu lanjutkan rebase ini.';

  @override
  String gitUiArg0Arg1UnmergedStagesArg2(
    String arg0,
    String arg1,
    String arg2,
  ) {
    return '$arg0$arg1 · tahap indeks belum digabung $arg2';
  }

  @override
  String get gitUiTheIndexHasNoUnresolvedEntries =>
      'Indeks tak memiliki entri yang tak terselesaikan.';

  @override
  String get gitUiKeepTheCurrentCommitAsAnEmptyCommit =>
      'Pertahankan commit ini sebagai commit kosong';

  @override
  String get gitUiTheRealIndexHasNoStagedChangesCreateAnExplicit =>
      'Indeks riil tidak memiliki perubahan yang distage. Buat suatu commit kosong eksplisit, lanjutkan urutan bila masih aktif.';

  @override
  String get gitUiKeepEmptyCommit => 'Simpan commit kosong...';

  @override
  String get gitUiGitWillTryToReturnToTheOperationSStarting =>
      'Git akan mencoba kembali ke awal operasi. Konten yang sudah ada sebelumnya di luar indeks, tidak dilacak, atau belum disimpan tidak dijamin dapat dipulihkan.';

  @override
  String get gitUiSkipTheCurrentCommitAndContinueWithTheNextPlanned =>
      'Lewati commit saat ini dan lanjutkan dengan commit yang direncanakan berikutnya.';

  @override
  String
  get gitUiForgetThisOperationSBookkeepingWhileRetainingTheCurrentFiles =>
      'Lupakan operasi ini pembukuan sambil menyimpan berkas dan indeks saat ini.';

  @override
  String gitUiContinueArg0(String arg0) {
    return 'Lanjutkan $arg0';
  }

  @override
  String get gitUiReloadConflictVersions => 'Isi ulang versi konflik?';

  @override
  String get gitUiReplaceTheUnsavedResultDraftWithTheCurrentWorkingFile =>
      'Ganti draft Hasil yang belum disimpan dengan berkas kerja saat ini. Isi kerja disimpan dipertahankan.';

  @override
  String get gitUiLoadingConflictVersions => 'Memuat versi konflik...';

  @override
  String get gitUiLoadingConflict => 'Memuat konflik';

  @override
  String get gitUiBaseLeft => 'Pangkalan → kiri';

  @override
  String get gitUiBaseRight => 'Markas → kanan';

  @override
  String get gitUiNoBaseEntryForThisConflict =>
      'Tidak ada entri dasar untuk konflik ini';

  @override
  String get gitUiAcceptEntireLeftFile => 'Terima seluruh berkas kiri...';

  @override
  String get gitUiAcceptEntireRightFile => 'Terima seluruh berkas kanan…';

  @override
  String get gitUiPreviousConflictRegion => 'Daerah konflik sebelumnya';

  @override
  String get gitUiNextConflictRegion => 'Daerah konflik berikutnya';

  @override
  String get gitUiManualResolution => 'Resolusi manual';

  @override
  String gitUiRegionArg0Arg1Arg2Reviewed(
    String arg0,
    String arg1,
    String arg2,
  ) {
    return 'Wilayah $arg0/$arg1 · $arg2 telah ditinjau';
  }

  @override
  String
  get gitUiSourceAlignmentExceededTheTextComparisonLimitSourcePanesRemain =>
      'Perataan sumber melebihi batas perbandingan teks; panel sumber tetap tersedia untuk tinjauan manual.';

  @override
  String get gitUiAcceptLeftRegion => 'Terima wilayah kiri';

  @override
  String get gitUiAcceptRightRegion => 'Terima daerah kanan';

  @override
  String get gitUiKeepManualResultForRegion =>
      'Pertahankan hasil manual bagi daerah';

  @override
  String get gitUiApplyGitSNonConflictingChanges =>
      'Terapkan perubahan git tanpa konflik?';

  @override
  String get gitUiReplaceTheCurrentResultDraftWithGitSMergePreview =>
      'Ganti draf hasil saat ini dengan pratinjau merge Gitås. Ini mengabaikan suntingan hasil manual yang belum disimpan; berkas kerja tidak berubah sampai Simpan.';

  @override
  String get gitUiUseMergePreview => 'Gunakan pratinjau gabungan';

  @override
  String get gitUiApplyNonConflictingChanges =>
      'Terapkan perubahan yang tidak menghubungkan...';

  @override
  String get gitUiLeftSource => 'Sumber kiri';

  @override
  String get gitUiResult => 'Hasil';

  @override
  String get gitUiRightSource => 'Sumber kanan';

  @override
  String get gitUiStage2 => 'Tahap 2';

  @override
  String get gitUiStage3 => 'Tahap 3';

  @override
  String
  get gitUiConflictVersionsAreUnavailableRefreshToReviewTheirCurrentState =>
      'Versi konflik tidak tersedia. Segarkan untuk meninjau keadaan mereka saat ini.';

  @override
  String get gitUiResultSavedToDiskTheIndexStillDeterminesWhetherThis =>
      'Hasil disimpan ke disk. Indeks masih menentukan apakah berkas ini diselesaikan.';

  @override
  String get gitUiSaveResultDraft => 'Simpan draf hasil';

  @override
  String get gitUiApplyResultAndStageResolution =>
      'Terapkan hasil dan stage penyelesaian';

  @override
  String get gitUiResultEditableUTF8WorkingContent =>
      'Hasil dari isi kerja UTF-8 yang dapat disunting';

  @override
  String get gitUiEditableConflictResult =>
      'Hasil konflik yang dapat disunting';

  @override
  String gitUiLeftArg0Arg1RightArg2Arg3(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return 'Kiri: $arg0 · $arg1\nKanan: $arg2 · $arg3';
  }

  @override
  String get gitUiChooseContentDeletionOrASubmoduleCommitExplicitlyNoBinary =>
      'Pilih isi, penghapusan, atau sebuah submodul commit secara eksplisit. Tidak ada data biner yang didekode sebagai teks yang dapat disunting.';

  @override
  String get gitUiUseEntireLeftContent => 'Gunakan seluruh isi kiri...';

  @override
  String get gitUiUseEntireRightContent => 'Gunakan seluruh konten kanan…';

  @override
  String get gitUiDeleteThisPath => 'vectors-action';

  @override
  String get gitUiResolvedSubmoduleCommit => 'Commit submodule terpecah';

  @override
  String get gitUiStageThisExactGitlinkInTheParentThisDoesNot =>
      'Tahap ini gitlink tepat dalam induk. Ini tidak memeriksa atau melakukan submodule tersebut.';

  @override
  String get gitUiSetResolvedGitlink => 'Atur gitlink yang terpecahkan...';

  @override
  String gitUiBaseStageArg0(String arg0) {
    return 'Basis → tahap $arg0';
  }

  @override
  String get gitUiTheResultWasEditedKeepTheManualResultOrSelect =>
      'Hasilnya diedit. Pertahankan hasil manual atau pilih daerah lain yang tidak berubah.';

  @override
  String gitUiApplyArg0Resolution(String arg0) {
    return 'Terapkan penyelesaian “$arg0”?';
  }

  @override
  String get gitUiStageTheChosenGitlinkCommitInTheParentTheSubmodule =>
      'Stage commit gitlink yang dipilih dalam induk. Checkout submodule dan berkas-berkasnya tidak diganti.';

  @override
  String gitUiReplacesTheEntireWorkingPathArg0AndStagesTheDecision(
    String arg0,
  ) {
    return 'Ganti seluruh jalur kerja $arg0 dan tahapkan keputusan. Isi kerja saat ini dan setiap rancangan hasil yang belum disimpan akan dibuang.';
  }

  @override
  String get gitUiApplyEntireFileDecision =>
      'Terapkan seluruh keputusan berkas';

  @override
  String get gitUiStageThisConflictResolution =>
      'Melakukan resolusi konflik ini?';

  @override
  String gitUiUseTheEntireEditedResultAsArg0GitRecordsThe(
    String arg0,
    String arg1,
  ) {
    return 'Gunakan seluruh hasil yang diedit sebagai $arg0. Git mencatat path yang diselesaikan ketika dipentaskan. Review semua isi yang diinginkan pertama.$arg1';
  }

  @override
  String get gitUiApplyAndStage => 'Terapkan dan stage';

  @override
  String get gitUiReviewResultTextFormatChanges =>
      'Tinjau perubahan format teks hasil';

  @override
  String get gitUiSaveReviewedResult => 'Simpan hasil yang ditinjau';

  @override
  String
  get gitUiNativeGitTableAccessibilityIsUnavailableRetryAfterReconnectingThe =>
      'Aksesibilitas tabel Git asli tidak tersedia. Coba lagi setelah menghubungkan kembali aplikasi.';

  @override
  String get gitUiSans => 'Sans';

  @override
  String get gitUiSelect => 'Pilih';

  @override
  String get gitUiContextMenu => 'Menu konteks';

  @override
  String get gitUiCopyText => 'Salin teks';

  @override
  String get gitUiLoadingRow => 'Memuat baris';

  @override
  String get gitUiRetry => 'Coba lagi';

  @override
  String get gitUiGitMessage => 'Pesan git';

  @override
  String get gitUiCancelPrompt => 'Batalkan prompt';

  @override
  String get gitUiUseMessageAndContinue => 'Gunakan pesan dan lanjutkan';

  @override
  String get gitUiRespondPrivately => 'Menanggapi secara pribadi';

  @override
  String gitUiViewPreferencesCouldNotBeSavedArg0(String arg0) {
    return 'Tilik preferensi tidak dapat disimpan: $arg0';
  }

  @override
  String gitUiCommitDraftStorageArg0(String arg0) {
    return 'Penyimpanan draft Commit: $arg0';
  }

  @override
  String gitUiViewPreferencesCouldNotBeReadArg0(String arg0) {
    return 'Tilik preferensi tidak dapat dibaca: $arg0';
  }

  @override
  String gitUiCommitDraftWasRetainedInMemoryButCouldNotBe(String arg0) {
    return 'draft Commit dipertahankan dalam memori tetapi tidak dapat disimpan: $arg0';
  }

  @override
  String get gitUiTheReviewedRepositoryIsReadOnlyForThisOperationHistory =>
      'Repositori yang ditinjau hanya dapat dibaca untuk operasi ini. Inspeksi riwayat dan isi tetap tersedia.';

  @override
  String gitUiGitReturnedArg0TheApplicationCouldNotRefreshItsDocuments(
    String arg0,
    String arg1,
  ) {
    return 'Git mengembalikan $arg0. Aplikasi tidak dapat menyegarkan dokumen-dokumennya: $arg1';
  }

  @override
  String get gitUiSelectCommitInLog => 'Pilih commit dari riwayat…';

  @override
  String get gitUiCurrentBranch => 'Cabang saat ini';

  @override
  String get gitUiNoMatchingBranchesOrTagsSelectACommitInLog =>
      'Tak ada branch atau tag yang cocok. Pilih suatu commit dalam Log.';

  @override
  String get gitUiBranches => 'Cabang';

  @override
  String get gitUiPushCommits => 'Push commit';

  @override
  String gitUiPullIntoArg0(String arg0) {
    return 'Tarik ke $arg0';
  }

  @override
  String gitUiResolveArg0(String arg0) {
    return 'Selesaikan $arg0';
  }

  @override
  String get gitUiCurrentOperation => 'Operasi saat ini';

  @override
  String get gitUiRebaseCommits => 'Rebase commit';

  @override
  String get gitUiFetch2 => 'Fetch…';

  @override
  String get gitUiPull => 'Pull…';

  @override
  String get gitUiPush2 => 'Push…';

  @override
  String get gitUiBranches2 => 'Cabang…';

  @override
  String get gitUiManageRemotes => 'Kelola remote…';

  @override
  String gitUiMergeIntoArg0(String arg0) {
    return 'Gabung ke $arg0...';
  }

  @override
  String get gitUiRebase2 => 'Rebase…';

  @override
  String get gitUiConflictsAndCurrentOperation =>
      'Konflik dan operasi saat ini...';

  @override
  String get gitUiStashes2 => 'Stash…';

  @override
  String get gitUiWorktrees => 'Worktree…';

  @override
  String get gitUiSubmodules => 'Submodul…';

  @override
  String get gitUiReflogAndRecovery => 'Reflog dan pemulihan…';

  @override
  String get gitUiCloneRepository => 'Klon repositori…';

  @override
  String get gitUiRevokeRepositoryTrust => 'Cabut kepercayaan repositori';

  @override
  String get gitUiWaitingForRepositoryStatus => 'Menunggu status repositori';

  @override
  String get gitUiRepositoryStatusUnavailableRefresh =>
      'Status repositori tidak tersedia; segarkan';

  @override
  String get gitUiManageRemotes2 => 'Kelola remote';

  @override
  String gitUiMergeIntoArg02(String arg0) {
    return 'Gabung ke $arg0';
  }

  @override
  String get gitUiWorktrees2 => 'Worktree';

  @override
  String get gitUiSubmodules2 => 'Submodul';

  @override
  String get gitUiReflogAndRecovery2 => 'Reflog dan pemulihan';

  @override
  String gitUiCloneRepositoryArg0(String arg0) {
    return 'Repositori clone · $arg0';
  }

  @override
  String get gitUiApply => 'Terapkan';

  @override
  String get gitUiResizeGitPanes => 'Ubah ukuran panel Git';

  @override
  String gitUiArg0Percent(String arg0) {
    return '$arg0 persen';
  }

  @override
  String gitUiExitStatusStatus(String status) {
    return 'Status keluaran: $status';
  }

  @override
  String get gitUiRepositoryChangedRefreshAndReviewBeforeTryingAgain =>
      'Repositori berubah. Segarkan dan tinjau sebelum mencoba lagi.';

  @override
  String get gitUiAnotherOperationHoldsTheRepositoryOrIndexLockWaitThen =>
      'Operasi lain memegang kunci repositori atau indeks. Tunggu, kemudian segarkan.';

  @override
  String get gitUiRepositoryTrustIsRequiredForThisOperation =>
      'Diperlukan kepercayaan repositori untuk operasi ini.';

  @override
  String get gitUiTheGitServiceDisconnectedReconnectAndReconcileTheRepository =>
      'Layanan Git terputus. Menyambung kembali dan mendamaikan repositori.';

  @override
  String
  get gitUiTheInstalledGitExecutableCannotSupportThisOperationReviewIts =>
      'Executable Git yang terpasang tidak dapat mendukung operasi ini. Tinjau ulang kebutuhan waktu berjalannya di bawah ini.';

  @override
  String get gitUiThisRepositoryIsReadOnlyForTheRequestedOperationReview =>
      'Repositori ini hanya dapat dibaca bagi operasi yang diminta. Tinjau dan riwayat tetap tersedia.';

  @override
  String
  get gitUiTheOperationNeedsReconciliationReviewTheResultingRepositoryOrRemote =>
      'Operasi perlu dirukunkan. Tinjau ulang repositori yang dihasilkan atau keadaan jauh sebelum mengulanginya.';

  @override
  String get gitUiGitAuthenticationFailedReviewTheCredentialHelperOrUnlockThe =>
      'Otentikasi git gagal. Review pembantu kredensial atau buka kunci ring kunci yang dikonfigurasi.';

  @override
  String get gitUiSshHostVerificationFailedReviewTheHostIdentityThroughYour =>
      'Verifikasi host SSH gagal. Review identitas host melalui perangkat SSH yang dikonfigurasi Anda.';

  @override
  String get gitUiCommitSigningFailedOrWasCancelledReviewTheSigningKey =>
      'Penyalaan commit gagal atau dibatalkan. Review kunci penandatanganan, agen dan mengkonfigurasi alat penandatanganan.';

  @override
  String get gitUiSetARepositoryAuthorNameAndEmailThenReturnTo =>
      'Tata nama penulis repositori dan surel, lalu kembali ke draft pesan yang diawetkan.';

  @override
  String get gitUiGitRejectedTheReviewedUpdateRefreshAndReviewTheActual =>
      'Git menolak pemutakhiran yang ditinjau. Segarkan dan tinjau tujuan sebenarnya sebelum mencoba lagi.';

  @override
  String get gitUiWorkingOrStagedChangesPreventThisOperationReviewCommitOr =>
      'Mengerjakan atau melakukan perubahan mencegah operasi ini. Review, lakukan atau secara eksplisit menyimpannya.';

  @override
  String get gitUiARequiredGitObjectIsUnavailableReviewShallowOrPartial =>
      'Objek Git yang diperlukan tidak tersedia. Tinjau batas dangkal atau repositori parsial dan ambil secara eksplisit bila diperlukan.';

  @override
  String gitUiGitOperationFailedArg0(String arg0) {
    return 'Operasi git gagal: $arg0';
  }

  @override
  String get gitUiDiagnostics => 'Diagnosa';

  @override
  String get gitUiAuthorizeGitInspection => 'Otorisasikan pemeriksaan Git...';

  @override
  String get gitUiCopyDiagnostics => 'Salin diagnostik';

  @override
  String get gitUiActions => 'Tindakan';

  @override
  String gitUiBranchAtArg0(String arg0) {
    return 'Branch di $arg0';
  }

  @override
  String get gitUiCreatesALocalBranchWithoutCheckingItOut =>
      'Membuat cabang lokal tanpa memeriksanya.';

  @override
  String gitUiTagArg0(String arg0) {
    return 'Tag $arg0';
  }

  @override
  String gitUiReadOnlySnapshotArg0(String arg0) {
    return 'Foto-foto hanya-baca · $arg0';
  }

  @override
  String get gitUiCherryPickCommits => 'Terapkan commit dengan cherry-pick';

  @override
  String get gitUiRevertCommits => 'Putar balik suatu commit';

  @override
  String get gitUiCompareToFullRevisionID => 'Bandingkan ke ID revisi penuh';

  @override
  String gitUiTreeComparisonDirectionArg0TheRevisionEnteredHere(String arg0) {
    return 'Arah perbandingan pohon: $arg0 → revisi masuk ke sini.';
  }

  @override
  String get gitUiEnterAFullValidObjectID =>
      'Masukkan sebuah ID objek yang valid penuh.';

  @override
  String gitUiArg0Arg1TreeComparison(String arg0, String arg1) {
    return '$arg0 → $arg1 · perbandingan pohon';
  }

  @override
  String gitUiResetArg0ToArg1(String arg0, String arg1) {
    return 'Reset $arg0 ke $arg1';
  }

  @override
  String
  get gitUiMovesHEADCurrentBranchReflogDoesNotRecoverArbitraryUntracked =>
      'Memindahkan HEAD/branch saat ini. Reflog tidak memulihkan sembarang konten yang tidak terlacak atau belum disimpan.';

  @override
  String get gitUiMoveHEADKeepIndexAndWorkingFiles =>
      'Pindahkan HEAD; pertahankan indeks dan berkas kerja.';

  @override
  String get gitUiMoveHEADAndReplaceIndexKeepWorkingFiles =>
      'Pindahkan HEAD dan ganti indeks; pertahankan berkas kerja.';

  @override
  String
  get gitUiReplaceHEADIndexAndTrackedWorkingFilesMayOverwriteObstructing =>
      'Ganti HEAD, indeks, dan berkas kerja terlacak; berkas tidak terlacak yang menghalangi dapat ditimpa.';

  @override
  String get gitUiReplaceHEADIndexAndEligibleFilesRefuseIfLocalChanges =>
      'Ganti HEAD, indeks, dan berkas yang sesuai; tolak jika perubahan lokal akan hilang.';

  @override
  String gitUiResetWithArg0(String arg0) {
    return 'Reset dengan $arg0?';
  }

  @override
  String gitUiArg0Arg1ReviewTheSelectedModeSEffectsBeforeApplying(
    String arg0,
    String arg1,
  ) {
    return '$arg0 → $arg1 Review efek mode yang dipilih sebelum diterapkan.';
  }

  @override
  String gitUiResetArg0(String arg0) {
    return 'Reset $arg0';
  }

  @override
  String gitUiTargetArg0(String arg0) {
    return 'Tujuan $arg0';
  }

  @override
  String get gitUiTagName => 'Nama tag';

  @override
  String get gitUiAnnotatedTag => 'Tag beranotasi';

  @override
  String get gitUiCryptographicSigning => 'Penandatanganan kriptografis';

  @override
  String get gitUiConfiguredPolicy => 'Kebijakan konfigurasi';

  @override
  String get gitUiSignThisTag => 'Tanda tangani tag ini';

  @override
  String get gitUiDoNotSign => 'Jangan tanda tangani';

  @override
  String get gitUiTagMessage => 'Pesan tag';

  @override
  String get gitUiCreatesTheTagLocallyPublishSelectedTagsExplicitlyInPush =>
      'Membuat tag lokal. Terbitkan tag yang dipilih secara eksplisit dalam review Push.';

  @override
  String gitUiCompleteTreesArg0Arg1(String arg0, String arg1) {
    return 'Pohon lengkap: $arg0 → $arg1';
  }

  @override
  String get gitUiNextChangedFilePage => 'Halaman berkas-ubah berikutnya';

  @override
  String get gitUiReadOnlyRepositorySnapshotOpeningAFileNeverChecksOut =>
      'Snapshot repositori baca-saja. Membuka suatu berkas tak pernah memeriksa revisi ini.';

  @override
  String get gitUiOpenReadOnlyVersion => 'Buka versi hanya-baca';

  @override
  String get gitUiRestoreThisPathWaitingForRepositoryStatus =>
      'Kembalikan path ini...· Waiting for repositori status';

  @override
  String get gitUiRestoreThisPath => 'Pulihkan jalur ini...';

  @override
  String gitUiHistoryArg0(String arg0) {
    return 'Sejarah · $arg0';
  }

  @override
  String gitUiRestoreArg0(String arg0) {
    return 'Mengembalikan $arg0?';
  }

  @override
  String gitUiReplaceThisWorkingPathWithRevisionArg0ExistingStagedContent(
    String arg0,
  ) {
    return 'Ganti path kerja ini dengan revisi $arg0. Isi dipentaskan yang ada masih dipertahankan.';
  }

  @override
  String get gitUiRestoreWorkingFile => 'Mengembalikan berkas kerja';

  @override
  String gitUiFileHistoryFollowsRenamesArg0(String arg0) {
    return 'Sejarah berkas mengikuti mengubah nama · $arg0';
  }

  @override
  String get gitUiBlameCommittedContent => 'Anotasi · konten commit';

  @override
  String get gitUiBlame => 'Anotasi…';

  @override
  String gitUiArg0WorkingTree(String arg0) {
    return '$arg0 → Pohon Kerja';
  }

  @override
  String get gitUiOpenReadOnlyHistoricalFile =>
      'Buka berkas sejarah hanya-baca';

  @override
  String get gitUiCompareToCurrentFile => 'Bandingkan dengan berkas kini';

  @override
  String get gitUiCompareToParent => 'Bandingkan dengan orang tua...';

  @override
  String gitUiCommittedArg0UnsavedEditorContentIsNotPartOfThese(String arg0) {
    return 'Isi penyunting $arg0 yang belum disimpan bukan bagian dari anotasi ini';
  }

  @override
  String gitUiHistoryFromArg0(String arg0) {
    return 'Sejarah dari $arg0';
  }

  @override
  String get gitUiBoundary => ' · Batas';

  @override
  String gitUiArg0Arg1OriginalLineArg2Arg3(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return '$arg0  $arg1\nBaris asli $arg2$arg3';
  }

  @override
  String get gitUiPreviousLines => 'Baris sebelumnya';

  @override
  String get gitUiNextLines => 'Baris berikutnya';

  @override
  String gitUiExplicitApplicationOrderDestinationArg0(String arg0) {
    return 'Urutan aplikasi eksplisit · tujuan $arg0';
  }

  @override
  String get gitUiAddFullCommitObjectID => 'Tambahkan ID objek commit penuh';

  @override
  String get gitUiAddReviewedCommit => 'Tambahkan commit yang ditinjau...';

  @override
  String get gitUiMoveEarlier => 'Pindah lebih awal';

  @override
  String get gitUiMoveLater => 'Bergerak kemudian';

  @override
  String get gitUiRemoveFromReviewedSequence =>
      'Hapus dari urutan yang ditinjau';

  @override
  String get gitUiApplyChangesWithoutCreatingCommits =>
      'Terapkan perubahan tanpa membuat commit';

  @override
  String get gitUiUseThisExplicitMainlineParentForMergeCommits =>
      'Gunakan induk mainline eksplisit ini untuk merge commits';

  @override
  String get gitUiEmptyOrAlreadyAppliedCommitsMayStopGitForAn =>
      'Commit yang telah terapan atau kosong dapat menghentikan Git untuk melewatkan eksplisit atau melanjutkan keputusan.';

  @override
  String get gitUiRevertInReviewedOrder => 'Revert sesuai urutan yang ditinjau';

  @override
  String get gitUiCherryPickInReviewedOrder =>
      'Cherry-pick dalam urutan yang ditinjau';

  @override
  String get gitUiReturnToFiles => 'Kembali ke Berkas';

  @override
  String get gitUiGit => 'Git';

  @override
  String get gitUiCommit => 'Commit';

  @override
  String get gitUiBackToCommit => 'Kembali ke Commit';

  @override
  String get gitUiSelectAChangeToReview => 'Pilih perubahan untuk ditinjau';

  @override
  String get gitUiLoadingBranch => 'Memuat branch...';

  @override
  String get gitUiBranchUnavailable => 'Branch tidak tersedia';

  @override
  String get gitUiUnbornHEAD => 'HEAD tanpa commit';

  @override
  String gitUiDetachedHEADRevision(String revision) {
    return 'HEAD terlepas · $revision';
  }

  @override
  String get gitUiContinueAction => 'Lanjutkan';

  @override
  String get gitUiPick => 'Ambil';

  @override
  String get gitUiReword => 'Ubah pesan';

  @override
  String get gitUiEdit => 'Edit';

  @override
  String get gitUiSquash => 'Gabungkan commit';

  @override
  String get gitUiFixup => 'Gabungkan tanpa pesan';

  @override
  String get gitUiDrop => 'Buang';

  @override
  String get gitUiAbort => 'Batalkan operasi';

  @override
  String get gitUiSkip => 'Lewati';

  @override
  String get gitUiQuit => 'Keluar dari operasi';

  @override
  String get gitUiSoft => 'Lunak';

  @override
  String get gitUiMixed => 'Campuran';

  @override
  String get gitUiHard => 'Keras';

  @override
  String get gitUiKeep => 'Pertahankan';

  @override
  String get gitUiCreate => 'Buat';

  @override
  String get gitUiApplyStash => 'Terapkan stash';

  @override
  String get gitUiPopStash => 'Terapkan stash dan hapus jika berhasil';

  @override
  String get gitUiDropStashAction => 'Hapus stash';

  @override
  String get gitUiEditedResult => 'Hasil yang diedit';

  @override
  String get gitUiLeftContent => 'Isi kiri';

  @override
  String get gitUiRightContent => 'Isi kanan';

  @override
  String get gitUiDeletePath => 'Hapus path';

  @override
  String get gitUiSubmoduleCommit => 'Commit submodule';

  @override
  String get gitUiPresentContent => 'Isi tersedia';

  @override
  String get gitUiAbsentContent => 'Absen';

  @override
  String get gitUiBinaryContent => 'Isi binari';

  @override
  String get gitUiTooLargeContent => 'Isi melebihi batas tampilan';

  @override
  String get gitUiUnavailableContent => 'Isi tidak tersedia';

  @override
  String get gitUiGitlinkContent => 'Pointer submodule';

  @override
  String get gitUiSymlinkContent => 'Link simbolik';

  @override
  String get gitUiNoOperation => 'Tak ada operasi';

  @override
  String get gitUiCherryPickOperation => 'Cherry-pick';

  @override
  String get gitUiRevertOperation => 'Revert';

  @override
  String get gitUiApplyMailboxOperation => 'Terapkan patch';

  @override
  String get gitUiSquashOperation => 'Gabung squash';

  @override
  String get gitUiUnmergedOperation => 'Indeks tak terukur';

  @override
  String get gitUiWaitingForPromptPhase => 'Menunggu tanggapan Anda';

  @override
  String get gitUiStoppedPhase => 'Dihentikan untuk ulasan';

  @override
  String get gitUiCompletedPhase => 'Selesai';

  @override
  String get gitUiFailedPhase => 'Gagal';

  @override
  String get gitUiCancelledPhase => 'Dibatalkan';

  @override
  String get gitUiUncertainPhase => 'Outcome membutuhkan rekonsiliasi';

  @override
  String gitUiStageVersion(String stage) {
    return 'Tahap konflik $stage';
  }

  @override
  String get gitUiGitMergePreview => 'Pratinjau merge Git';

  @override
  String get gitUiNormalizedWorking => 'Pohon Kerja · Git dinormalkan';

  @override
  String gitUiPercentValue(String value) {
    return '$value persen';
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
  String get gitUiUtf8Bom => 'UTF-8 dengan tanda byte-order (BOM)';

  @override
  String get gitUiUtf8NoBom => 'UTF-8 tanpa tanda batas byte (BOM)';

  @override
  String get gitUiAddsBom =>
      'Sunting ini menambahkan tanda UTF-8 byte-order (BOM) di awal berkas.';

  @override
  String get gitUiRemovesBom =>
      'Sunting ini menghapus tanda UTF-8 byte-order (BOM) dari awal berkas.';

  @override
  String get gitUiNoLineTerminators => 'Tak ada pengakhir baris';

  @override
  String gitUiLineEndings(String format) {
    return 'Akhir baris $format';
  }

  @override
  String gitUiMixedLineEndings(String formats) {
    return 'Akhir baris campuran ($formats)';
  }

  @override
  String gitUiNoFinalLf(String format) {
    return '$format · tidak ada LF akhir';
  }

  @override
  String gitUiLineEndingChange(String before, String after) {
    return 'Format akhir baris berubah dari $before menjadi $after. Teks papan klip dapat menggunakan akhir baris yang berbeda dari berkas asli.';
  }

  @override
  String get gitUiGitFailure =>
      'Operasi git gagal. Meninjau diagnosa di bawah ini.';

  @override
  String get gitUiAbortInline => 'Batalkan operasi';

  @override
  String get gitUiSkipInline => 'Lewati';

  @override
  String get gitUiQuitInline => 'berhenti';

  @override
  String get gitUiMergeInline => 'Gabung';

  @override
  String get gitUiRebaseInline => 'Rebase';

  @override
  String get gitUiCherryPickInline => 'Cherry-pick';

  @override
  String get gitUiRevertInline => 'Revert';

  @override
  String get gitUiApplyMailboxInline => 'kotak-surat terapan';

  @override
  String get gitUiSquashInline => 'Gabungkan commit';

  @override
  String get gitUiUnmergedInline => 'tak terukur';

  @override
  String get gitHostFetch => 'Fetch';

  @override
  String get gitHostRefreshGitStatus => 'Segarkan status Git';

  @override
  String get gitHostCommitStaged => 'Commit dipentaskan';

  @override
  String get gitHostGitBranches => 'Cabang git';

  @override
  String get gitHostReviewPush => 'Push review';

  @override
  String get gitHostGit => 'Git';

  @override
  String get gitHostGitOperationsApplyToThisEntireRepositoryAndMay =>
      'Operasi git berlaku untuk seluruh repositori ini dan mungkin mengeksekusi kaitnya yang dikonfigurasi, penyaring, kredensial, dan alat penandatanganannya.';

  @override
  String get gitHostContentUnavailable => 'Isi tidak tersedia';

  @override
  String get gitHostInitializeRepository => 'Inisialisasi repositori';

  @override
  String get gitHostCloneRepository => 'Klon repositori';

  @override
  String get gitHostInitializeHere => 'Inisialisasi di sini...';

  @override
  String get gitHostCloneRepository2 => 'Klon repositori…';

  @override
  String get gitHostGitLog => 'Log Git';

  @override
  String get gitUiAbsentPlaceholder => '(Absent)';

  @override
  String get gitUiUnborn => 'belum lahir';

  @override
  String gitUiRebasedHistoryRevision(String revision) {
    return 'Riwayat setelah rebase · $revision';
  }

  @override
  String gitUiCurrentHistoryRevision(String revision) {
    return 'Riwayat saat ini · $revision';
  }

  @override
  String gitUiReplayedCommitRevision(String revision) {
    return 'Commit yang diterapkan ulang · $revision';
  }

  @override
  String gitUiIncomingContentRevision(String revision) {
    return 'Konten masuk · $revision';
  }

  @override
  String get gitUiContentConflict => 'Konflik isi';

  @override
  String get gitUiSubmoduleConflict => 'Konflik submodule';

  @override
  String get gitUiSymlinkConflict => 'Konflik symbolic-link';

  @override
  String get gitUiAddAddConflict => 'Ditambahkan pada kedua sisi';

  @override
  String get gitUiModifyDeleteConflict => 'Diubah/hapus atau diubah nama/hapus';

  @override
  String gitUiConflictIdentity(String path, String kind) {
    return '$path $kind';
  }

  @override
  String get gitUiDiscardUnsavedIndexDraft =>
      'Buang draf indeks yang belum disimpan?';

  @override
  String get gitUiClosingTheIndexEditorDiscardsOnlyItsDraft =>
      'Menutup editor indeks hanya membuang drafnya. Indeks dan berkas kerja tetap tidak berubah.';

  @override
  String get gitUiDiscardIndexDraft => 'Buang draf indeks';

  @override
  String get gitUiDiscardUnsavedConflictDraft =>
      'Buang hasil konflik yang belum disimpan?';

  @override
  String get gitUiClosingTheConflictEditorDiscardsOnlyItsDraft =>
      'Menutup editor konflik hanya membuang draf hasil yang belum disimpan. Isi kerja yang telah disimpan dan indeks tetap sama.';

  @override
  String get gitUiDiscardConflictDraft => 'Buang draf konflik';

  @override
  String get gitUiOpenCurrentFile => 'Buka berkas saat ini';

  @override
  String get gitUiPreviousSearchMatch => 'Hasil pencarian sebelumnya';

  @override
  String get gitUiNextSearchMatch => 'Hasil pencarian berikutnya';

  @override
  String gitUiSearchMatchPosition(String current, String count) {
    return 'Hasil $current dari $count';
  }

  @override
  String gitUiSearchResultsLimited(String count) {
    return 'Menampilkan $count hasil pertama. Persempit pencarian untuk meninjau lebih banyak.';
  }

  @override
  String get gitUiRevealRevisionWithoutFilters =>
      'Tampilkan revisi tanpa filter';

  @override
  String get gitUiRestoreHistoryFilters => 'Pulihkan filter riwayat';

  @override
  String get gitUiShowAllAffectedFiles =>
      'Tampilkan semua berkas yang terpengaruh';

  @override
  String get gitUiGraphLanes => 'Jalur grafik';

  @override
  String gitUiRebaseArg0OntoArg1(String arg0, String arg1) {
    return 'Rebase $arg0 ke atas $arg1';
  }

  @override
  String get gitUiChangedLine => 'Baris berubah';

  @override
  String get gitUiCopyHeadRegionIntoIndexDraft =>
      'Salin bagian HEAD ke draf indeks';

  @override
  String get gitUiCopyWorkingRegionIntoIndexDraft =>
      'Salin bagian kerja ke draf indeks';

  @override
  String get gitUiUpdatingConflictRegions => 'Memperbarui bagian konflik';

  @override
  String gitUiRemainingConflictMarkers(String count) {
    return 'Bagian hasil dengan penanda konflik: $count';
  }

  @override
  String get gitUiIgnoreLeftRegion => 'Abaikan saran kiri';

  @override
  String get gitUiIgnoreRightRegion => 'Abaikan saran kanan';

  @override
  String get gitUiIndexAppliedNewerDraftPreserved =>
      'Draf yang dikirim telah ditulis ke indeks. Teks yang lebih baru masih ada di editor ini. Muat ulang dan tinjau versi saat ini sebelum menerapkannya.';

  @override
  String get gitUiNewerConflictDraftRetained =>
      'Hasil yang dikirim telah disimpan. Draf hasil Anda yang lebih baru masih belum disimpan.';

  @override
  String get gitUiNoFileHistoryForThisPathAndRevision =>
      'Riwayat berkas tidak tersedia untuk jalur dan revisi ini.';

  @override
  String get gitUiReviewSavedIndexAndKeepDraft =>
      'Tinjau indeks tersimpan dan pertahankan draf';

  @override
  String get gitUiIndexSourcesChangedSinceApply =>
      'Indeks tersimpan atau sumbernya telah berubah. Draf yang lebih baru dipertahankan; tinjau perubahan tersebut secara terpisah sebelum menerapkannya.';
}
