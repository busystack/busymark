// ignore_for_file: text_direction_code_point_in_literal, text_direction_code_point_in_comment

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'BusyMark';

  @override
  String get appSubtitle =>
      'Markdown dosyaları ve Writerside uyumlu dokümantasyon projeleri için düzenleyici.';

  @override
  String get aboutBusyMark => 'BusyMark Hakkında';

  @override
  String get aboutTagline => 'Markdown ve Writerside Düzenleyicisi';

  @override
  String get aboutLicenseLabel => 'Lisans';

  @override
  String get aboutLicenseName => 'Apache License 2.0';

  @override
  String get aboutWebsite => 'Web sitesi';

  @override
  String get aboutSourceCode => 'Kaynak kodu';

  @override
  String get reportIssue => 'Bir sorunu bildirin';

  @override
  String get feedbackCategory => 'Kategori';

  @override
  String get feedbackChooseCategory => 'Bir kategori seçin';

  @override
  String get feedbackCategoryProblem => 'Sorun veya hata';

  @override
  String get feedbackCategoryFeature => 'Özellik isteği';

  @override
  String get feedbackCategoryPrivacySecurity =>
      'Gizlilik veya güvenlik endişesi';

  @override
  String get feedbackCategoryUsability => 'Kullanılabilirlik endişesi';

  @override
  String get feedbackCategoryOther => 'Diğer';

  @override
  String get feedbackSubject => 'Konu';

  @override
  String get feedbackMessage => 'Ayrıntılı mesaj';

  @override
  String get feedbackReplyEmail => 'Yanıt e-postası adresi (isteğe bağlı)';

  @override
  String get feedbackIncludeTechnicalDetails => 'Teknik ayrıntıları ekleyin';

  @override
  String get feedbackTechnicalDetailsDisclosure =>
      'Etkinleştirildiğinde bu, yalnızca Linux işletim sistemi sürümünüzü ve BusyMark uygulama yerel ayarını ekler. Hiçbir günlük, dosya, hesap verisi veya başka tanılama eklenmez.';

  @override
  String get feedbackSubmit => 'Gönder';

  @override
  String get feedbackSubmitting => 'Gönderiliyor…';

  @override
  String get feedbackCategoryRequired => 'Bir kategori seçin.';

  @override
  String get feedbackSubjectLength =>
      'Konu 3 ila 120 karakter arasında olmalıdır.';

  @override
  String get feedbackMessageLength =>
      'Mesaj 10 ila 5.000 karakter arasında olmalıdır.';

  @override
  String get feedbackReplyEmailInvalid =>
      'Geçerli bir e-posta adresi girin veya bu alanı boş bırakın.';

  @override
  String get feedbackConnectionFailure =>
      'BusyMark bağlanamadı. İnternet bağlantınızı kontrol edip tekrar deneyin.';

  @override
  String get feedbackTimeoutFailure =>
      'İstek zaman aşımına uğradı. Tekrar deneyin.';

  @override
  String get feedbackRateLimitedFailure =>
      'Bu bağlantıdan çok fazla rapor gönderildi. Bekleyin ve tekrar deneyin.';

  @override
  String get feedbackRejectedFailure =>
      'Sunucu bu raporu reddetti. Form alanlarını kontrol edip tekrar deneyin.';

  @override
  String get feedbackServerFailure =>
      'Sunucu raporu kabul edemedi. Daha sonra tekrar deneyin.';

  @override
  String feedbackSuccess(String id) {
    return 'Geri bildirim gönderildi. Referans Kimliği: $id';
  }

  @override
  String get advanced => 'Gelişmiş';

  @override
  String get addToGit => 'Git\'e ekle';

  @override
  String get appearance => 'Görünüm';

  @override
  String get apply => 'Uygula';

  @override
  String get back => 'Geri';

  @override
  String get bottomLeft => 'Sol alt';

  @override
  String get bottomRight => 'Sağ alt';

  @override
  String get cancel => 'İptal';

  @override
  String get choose => 'Seç';

  @override
  String get chooseLocation => 'Konum seçin';

  @override
  String get copy => 'Kopyala';

  @override
  String get copyName => 'Adı kopyala';

  @override
  String get copyFileName => 'Dosya adını kopyala';

  @override
  String get copyPath => 'Yolu kopyala';

  @override
  String get create => 'Oluştur';

  @override
  String get creating => 'Oluşturuluyor...';

  @override
  String get cut => 'Kes';

  @override
  String get promoteSection => 'Bölümü yükselt';

  @override
  String get demoteSection => 'Bölümü düşür';

  @override
  String get moveSectionUp => 'Bölümü yukarı taşı';

  @override
  String get moveSectionDown => 'Bölümü aşağı taşı';

  @override
  String get confirmDeleteSectionTitle => 'Bölüm silinsin mi?';

  @override
  String confirmDeleteSectionMessage(String name) {
    return '“$name” ve bölümündeki tüm içerik silinsin mi? Bu geri alınamaz.';
  }

  @override
  String get darkTheme => 'Karanlık';

  @override
  String get delete => 'Sil';

  @override
  String get discard => 'Değişiklikleri yok say';

  @override
  String get editor => 'Editör';

  @override
  String get file => 'Dosya';

  @override
  String get fileHistory => 'Dosya Geçmişi';

  @override
  String get folder => 'Klasör';

  @override
  String get insert => 'Ekle';

  @override
  String get keyboardShortcuts => 'Klavye Kısayolları';

  @override
  String get commandPalette => 'Komut Paleti';

  @override
  String get commandPaletteHint => 'Bir komut yazın';

  @override
  String get commandPaletteEmpty => 'Eşleşen komut yok';

  @override
  String get commandUnavailableInContext =>
      'Mevcut düzenleyici bağlamında kullanılamıyor';

  @override
  String get lightTheme => 'Açık';

  @override
  String get mainMenu => 'Ana menü';

  @override
  String get fullScreen => 'Tam ekran';

  @override
  String get markdown => 'Markdown';

  @override
  String get open => 'Aç';

  @override
  String get openInFiles => 'Dosya yöneticisinde aç';

  @override
  String get pathActions => 'Yol eylemleri';

  @override
  String get outline => 'Anahat';

  @override
  String get overwrite => 'Üzerine yaz';

  @override
  String get paste => 'Yapıştır';

  @override
  String get pasteWithoutFormatting => 'Biçimlendirmeden yapıştır';

  @override
  String get reading => 'Okuma';

  @override
  String get removeFromRecent => 'Son kullanılanlardan kaldır';

  @override
  String get recent => 'Son öğeler';

  @override
  String get redo => 'Yinele';

  @override
  String get save => 'Kaydet';

  @override
  String get search => 'Ara';

  @override
  String get selectAll => 'Tümünü seç';

  @override
  String get settings => 'Ayarlar';

  @override
  String get source => 'Kaynak';

  @override
  String get split => 'Bölünmüş görünüm';

  @override
  String get systemTheme => 'Sistem';

  @override
  String get theme => 'Tema';

  @override
  String get appLanguage => 'Dil';

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
  String get toggleSidebar => 'Kenar çubuğu paneli';

  @override
  String get topLeft => 'Sol üst';

  @override
  String get topRight => 'Sağ üst';

  @override
  String get undo => 'Geri al';

  @override
  String get validate => 'Doğrula';

  @override
  String get validation => 'Doğrulama';

  @override
  String get viewMode => 'Görünüm modu';

  @override
  String get welcome => 'Hoş geldiniz';

  @override
  String get writerside => 'Writerside';

  @override
  String get xml => 'XML';

  @override
  String get fileTypeMarkdown => 'Markdown';

  @override
  String get fileTypeImages => 'Görseller';

  @override
  String get openMarkdownFile => 'Markdown Dosyasını Aç';

  @override
  String get markdownFileExtensions => '.md veya .markdown';

  @override
  String get openFolderOrWritersideProject =>
      'Klasör veya Writerside projesi aç';

  @override
  String get markdownFolderOrWritersideProject =>
      'Markdown klasörü veya Writerside uyumlu proje';

  @override
  String get noOpenFile => 'Açık dosya yok';

  @override
  String get shortcutDeleteTreeItemDescription =>
      'Seçilen Dosyalar öğesini silin veya seçilen konuyu içindekiler tablosundan kaldırın';

  @override
  String get shortcutGroupGeneral => 'Genel';

  @override
  String get shortcutNewDocument => 'Oluştur';

  @override
  String get shortcutNewDocumentDescription =>
      'Markdown dosyası veya Writerside projesi oluştur';

  @override
  String get shortcutOpenDescription =>
      'Markdown dosyasını, klasörünü veya Writerside projesini açın';

  @override
  String get shortcutSaveDescription => 'Geçerli belgeyi kaydet';

  @override
  String get shortcutSearchDescription => 'Mevcut çalışma alanında arama yapın';

  @override
  String get shortcutKeyboardShortcutsDescription =>
      'Bu klavye kısayolu referansını göster';

  @override
  String get shortcutMarkdownAndHtmlDescription =>
      'Markdown ve HTML referansını açın';

  @override
  String get shortcutSettingsDescription => 'BusyMark ayarlarını aç';

  @override
  String get shortcutNextTab => 'Sonraki sekme';

  @override
  String get shortcutNextTabDescription => 'Sonraki açık sekmeye git';

  @override
  String get shortcutPreviousTab => 'Önceki sekme';

  @override
  String get shortcutPreviousTabDescription => 'Önceki açık sekmeye git';

  @override
  String get shortcutCloseTab => 'Sekmeyi kapat';

  @override
  String get shortcutCloseTabDescription => 'Etkin sekmeyi kapat';

  @override
  String get shortcutCloseAllTabs => 'Tüm sekmeleri kapat';

  @override
  String get shortcutCloseAllTabsDescription => 'Tüm açık sekmeleri kapat';

  @override
  String get shortcutGroupTextEditing => 'Metin Düzenleme';

  @override
  String get shortcutSelectAllDescription =>
      'Kaynak modunda tüm metni seçin; Editör modunda her bloğu seçmek için iki kez basın';

  @override
  String get shortcutCutDescription => 'Seçilen metni kes';

  @override
  String get shortcutCopyDescription => 'Seçilen metni kopyala';

  @override
  String get shortcutPasteDescription => 'Panodan yapıştır';

  @override
  String get shortcutPastePlainTextDescription =>
      'Panodan biçimlendirme olmadan yapıştır';

  @override
  String get shortcutUndoDescription => 'Son düzenlemeyi geri al';

  @override
  String get shortcutRedoDescription =>
      'Geri alınan son düzenlemeyi yeniden yap';

  @override
  String get shortcutInsertIndentation => 'Girinti ekle';

  @override
  String get shortcutInsertIndentationDescription =>
      'İmlecin bulunduğu yere girinti ekle';

  @override
  String get shortcutOutdentSource => 'Kaynakta girintiyi azalt';

  @override
  String get shortcutOutdentSourceDescription =>
      'Kaynak modunda bir girinti düzeyini kaldırın';

  @override
  String get shortcutEscape => 'Aramayı kapat veya blok seçimini temizle';

  @override
  String get shortcutEscapeDescription =>
      'Editör modunda çalışma alanı aramasını kapatın veya bir blok seçimini temizleyin';

  @override
  String get shortcutGroupFormatting => 'Biçimlendirme';

  @override
  String get shortcutBoldDescription => 'Seçili metinde kalın yazıya geçiş yap';

  @override
  String get shortcutItalicDescription =>
      'Seçilen metinde italik özelliğini aç/kapat';

  @override
  String get shortcutUnderlineDescription =>
      'Seçili metnin altını çizmeyi aç/kapat';

  @override
  String get shortcutLinkDescription => 'Bağlantı ekleme veya düzenleme';

  @override
  String get shortcutInlineCodeDescription =>
      'Seçilen metinde satır içi kodu değiştir';

  @override
  String get shortcutStrikethroughDescription =>
      'Seçili metnin üstü çizili özelliğini aç/kapat';

  @override
  String get shortcutGroupBlocks => 'Bloklar';

  @override
  String get shortcutParagraphDescription => 'Geçerli bloğu paragrafa ayarla';

  @override
  String get shortcutHeading1Description =>
      'Geçerli bloğu Başlık 1 olarak ayarlayın';

  @override
  String get shortcutHeading2Description =>
      'Geçerli bloğu Başlık 2\'ye ayarlayın';

  @override
  String get shortcutHeading3Description =>
      'Geçerli bloğu Başlık 3\'e ayarlayın';

  @override
  String get shortcutHeading4Description =>
      'Geçerli bloğu Başlık 4\'e ayarlayın';

  @override
  String get shortcutHeading5Description =>
      'Geçerli bloğu Başlık 5\'e ayarlayın';

  @override
  String get shortcutHeading6Description =>
      'Geçerli bloğu Başlık 6\'ya ayarlayın';

  @override
  String get shortcutGroupLists => 'Listeler';

  @override
  String get numberedList => 'Numaralı liste';

  @override
  String get shortcutNumberedListDescription =>
      'Numaralı liste formatını değiştir';

  @override
  String get bulletedList => 'Madde işaretli liste';

  @override
  String get shortcutBulletedListDescription =>
      'Madde işaretli liste biçimlendirmesini değiştir';

  @override
  String get checklist => 'Kontrol listesi';

  @override
  String get shortcutChecklistDescription =>
      'Denetim listesi biçimlendirmesini değiştir';

  @override
  String get shortcutGroupSidebar => 'Kenar çubuğu';

  @override
  String get sidebarViewMenu => 'Kenar çubuğu görünümü';

  @override
  String get createMarkdownFile => 'Markdown dosyası oluştur';

  @override
  String get createMarkdownFileDescription =>
      'Kaydedilmemiş bir yerel Markdown belgesi başlatın';

  @override
  String get createWritersideProject => 'Writerside projesi oluştur';

  @override
  String get createWritersideProjectDescription =>
      'Yerel, Writerside uyumlu bir proje başlat';

  @override
  String get defaultProjectName => 'Dokümantasyon';

  @override
  String get defaultInstanceName => 'Kullanım Kılavuzu';

  @override
  String get defaultStartTopicTitle => 'Başlarken';

  @override
  String get projectName => 'Proje adı';

  @override
  String get directoryName => 'Klasör adı';

  @override
  String get instanceName => 'Örnek adı';

  @override
  String get instanceId => 'Örnek kimliği';

  @override
  String get startTopicTitle => 'Başlangıç konusu başlığı';

  @override
  String get location => 'Konum';

  @override
  String get projectNameRequired => 'Proje adı gerekli.';

  @override
  String get directoryNameRequired => 'Klasör adı gerekli.';

  @override
  String get useSingleSafeDirectoryName =>
      'Tek bir güvenli klasör adı kullanın.';

  @override
  String get useLowercaseIdentifier =>
      'Harfler, sayılar, alt çizgiler veya kısa çizgiler içeren küçük harfli bir tanımlayıcı kullanın.';

  @override
  String get startTopicTitleRequired => 'Başlangıç konusu başlığı gerekli.';

  @override
  String get createWritersideProjectFailed =>
      'Writerside projesi oluşturulamadı.';

  @override
  String get settingsTitle => 'BusyMark Ayarları';

  @override
  String get autoSave => 'Otomatik Kaydet';

  @override
  String get autoSaveDescription =>
      'Kısa bir bekleme gecikmesinden sonra dosya değişikliklerini otomatik olarak kaydedin.';

  @override
  String get wordWrap => 'Satır kaydırma';

  @override
  String get editorFontSize => 'Düzenleyici yazı tipi boyutu';

  @override
  String get validateOnEdit => 'Düzenlemede doğrula';

  @override
  String get clearRecentWorkspaces => 'Son çalışma alanlarını temizle';

  @override
  String get editingButtonsPosition => 'Düzenleme düğmelerinin konumu';

  @override
  String get editingButtonsPositionDescription =>
      'Kayan WYSIWYG düzenleme düğmelerinin nerede görüneceğini seçin.';

  @override
  String get editingButtonsDirection => 'Düzenleme düğmelerinin yönü';

  @override
  String get editingButtonsDirectionDescription =>
      'Kayan WYSIWYG düzenleme düğmelerinin yatay mı yoksa dikey mi düzenleneceğini seçin.';

  @override
  String get horizontal => 'Yatay';

  @override
  String get vertical => 'Dikey';

  @override
  String get privacy => 'Gizlilik';

  @override
  String get allowRemoteImages => 'Harici görselleri yükle';

  @override
  String get allowRemoteImagesDescription =>
      'Markdown önizleme ve düzenleme görsellerinin http ve https URL\'lerinden yüklenmesine izin verin.';

  @override
  String get clearRemoteImagePermissions => 'Harici görsel izinlerini temizle';

  @override
  String get clearRemoteImagePermissionsDescription =>
      'Harici görsellerin yüklenmesine izin verilen çalışma alanlarını unutun.';

  @override
  String get clearGitWorkspaceTrust =>
      'Güvenilir Git çalışma alanlarını temizleyin';

  @override
  String get clearGitWorkspaceTrustDescription =>
      'Daha önce güvenilen çalışma alanları için Git özelliklerini etkinleştirmeden önce sorun.';

  @override
  String get settingsWindowSectionTitle => 'Pencere';

  @override
  String get settingsReopenWorkspaceOnStartupTitle =>
      'Başlangıçta önceki çalışma alanını yeniden aç';

  @override
  String get settingsReopenWorkspaceOnStartupDescription =>
      'BusyMark başladığında önceki oturumdaki çalışma alanını ve sekmeleri açın.';

  @override
  String get settingsConfirmCloseWithUnsavedChangesTitle =>
      'Kaydedilmemiş değişikliklerle kapatmadan önce onaylayın';

  @override
  String get settingsConfirmCloseWithUnsavedChangesDescription =>
      'Belgelerde kaydedilmemiş değişiklikler olduğunda BusyMark\'ı kapatmadan önce sorun.';

  @override
  String get closeUnsavedChangesTitle => 'Kaydedilmemiş değişiklikler';

  @override
  String get closeUnsavedChangesSingleMessage =>
      'Bu belgede kaydedilmemiş değişiklikler var. BusyMark\'ı kapatmadan önce değişiklikler kaydedilsin mi?';

  @override
  String closeUnsavedChangesMultipleMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count belgede kaydedilmemiş değişiklik var. BusyMark kapatılmadan önce değişiklikler kaydedilsin mi?',
      one:
          '1 belgede kaydedilmemiş değişiklik var. BusyMark kapatılmadan önce değişiklikler kaydedilsin mi?',
      zero: 'BusyMark kapatılmadan önce değişiklikler kaydedilsin mi?',
    );
    return '$_temp0';
  }

  @override
  String get closeUnsavedChangesCancel => 'İptal';

  @override
  String get closeUnsavedChangesDiscard => 'Değişiklikleri yok say';

  @override
  String get closeUnsavedChangesSave => 'Kaydet';

  @override
  String get currentFile => 'geçerli dosya';

  @override
  String get unsavedChanges => 'Kaydedilmemiş değişiklikler';

  @override
  String unsavedChangesMessage(String fileName) {
    return '$fileName\'te kaydedilmemiş değişiklikleriniz var. Devam etmeden önce kaydedilsin mi?';
  }

  @override
  String unsavedChangesMultipleMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count belgede kaydedilmemiş değişiklik var. Devam etmeden önce kaydedilsin mi?',
      one:
          '1 belgede kaydedilmemiş değişiklik var. Devam etmeden önce kaydedilsin mi?',
    );
    return '$_temp0';
  }

  @override
  String get fileChangedOnDisk => 'Diskteki dosya değiştirildi';

  @override
  String get fileChangedOnDiskMessage =>
      'Bu dosya, siz onu açtığınızdan beri diskte değişti. Üzerine yazılsın mı?';

  @override
  String get untitledMarkdownFileName => 'İsimsiz.md';

  @override
  String get unorderedList => 'Sırasız liste';

  @override
  String get orderedList => 'Sıralı liste';

  @override
  String get taskList => 'Görev listesi';

  @override
  String get toggleTaskChecked => 'Görevi işaretle veya işaretini kaldır';

  @override
  String get indentListItem => 'Liste öğesine girinti ekle';

  @override
  String get outdentListItem => 'Liste öğesinin çıkıntısı';

  @override
  String get blockquote => 'Blok alıntı';

  @override
  String get codeBlock => 'Kod bloğu';

  @override
  String get codeBlockLanguage => 'Kod bloğu dili';

  @override
  String get image => 'Resim';

  @override
  String get video => 'Video';

  @override
  String get openVideo => 'Videoyu oynat';

  @override
  String get pauseVideo => 'Videoyu duraklat';

  @override
  String get videoUnavailable => 'Video kullanılamıyor';

  @override
  String get videoPreview => 'Video önizlemesi';

  @override
  String get diagnosticWritersideVideoMissingSource =>
      'Videonun src özelliği eksik.';

  @override
  String diagnosticWritersideVideoUnsupportedSource(String source) {
    return 'Desteklenmeyen video kaynağı: $source';
  }

  @override
  String diagnosticWritersideVideoMissingFile(String source) {
    return 'Video dosyası mevcut değil: $source';
  }

  @override
  String diagnosticWritersideVideoMissingPreview(String preview) {
    return 'Video önizleme görüntüsü mevcut değil: $preview';
  }

  @override
  String get inlineImage => 'Satır içi resim';

  @override
  String get table => 'Tablo';

  @override
  String get htmlBlock => 'HTML bloğu';

  @override
  String get htmlContentDefault => 'HTML içeriği';

  @override
  String get shortcutHtmlBlockDescription => 'HTML bloğu ekleme veya düzenleme';

  @override
  String get renderedHtml => 'İşlenen HTML';

  @override
  String get editHtml => 'HTML\'yi düzenle';

  @override
  String get htmlSource => 'HTML kaynağı';

  @override
  String get thematicBreak => 'Yatay ayraç';

  @override
  String get bold => 'Kalın';

  @override
  String get italic => 'İtalik';

  @override
  String get underline => 'Altı çizili';

  @override
  String get strikethrough => 'Üstü çizili';

  @override
  String get inlineCode => 'Satır içi kod';

  @override
  String get link => 'Bağlantı';

  @override
  String get hardLineBreak => 'Zorunlu satır sonu';

  @override
  String get textStyle => 'Metin stili';

  @override
  String get paragraph => 'Paragraf';

  @override
  String get heading1 => 'Başlık 1';

  @override
  String get heading2 => 'Başlık 2';

  @override
  String get heading3 => 'Başlık 3';

  @override
  String get heading4 => 'Başlık 4';

  @override
  String get heading5 => 'Başlık 5';

  @override
  String get heading6 => 'Başlık 6';

  @override
  String headingLevelAbbreviation(int level) {
    return 'H$level';
  }

  @override
  String get deleteTable => 'Tabloyu sil';

  @override
  String tableColumnNumber(int columnNumber) {
    return 'Sütun $columnNumber';
  }

  @override
  String get insertColumnLeft => 'Sola sütun ekle';

  @override
  String get insertColumnRight => 'Sağa sütun ekle';

  @override
  String get deleteColumn => 'Sütunu sil';

  @override
  String get tableAlignmentUnspecified => 'Hizalama: belirtilmemiş';

  @override
  String get tableAlignmentLeft => 'Hizalama: sol';

  @override
  String get tableAlignmentCenter => 'Hizalama: orta';

  @override
  String get tableAlignmentRight => 'Hizalama: sağ';

  @override
  String tableRowNumber(int rowNumber) {
    return 'Satır $rowNumber';
  }

  @override
  String get insertRowAbove => 'Yukarıya satır ekle';

  @override
  String get insertRowBelow => 'Aşağıya satır ekle';

  @override
  String get deleteRow => 'Satırı sil';

  @override
  String get tableHeaderHint => 'Sütun başlığı';

  @override
  String get tableCellHint => 'Hücre';

  @override
  String get language => 'Dil';

  @override
  String get hideEditingButtons => 'Düzenleme düğmelerini gizle';

  @override
  String get showEditingButtons => 'Düzenleme düğmelerini göster';

  @override
  String get altText => 'Alternatif metin';

  @override
  String get editorPlaceholderText => 'metin';

  @override
  String get editorPlaceholderCode => 'kod';

  @override
  String get editorPlaceholderAltText => 'alternatif metin';

  @override
  String get describeTheImage => 'Resmi açıklayın';

  @override
  String get columns => 'Sütunlar';

  @override
  String get rows => 'Satırlar';

  @override
  String tableHeaderNumber(int columnNumber) {
    return 'Sütun başlığı $columnNumber';
  }

  @override
  String get tableCellDefault => 'Hücre';

  @override
  String get noImageSource => 'Resim kaynağı yok';

  @override
  String get remoteImageBlocked => 'Harici görsel engellendi';

  @override
  String get remoteImageBlockedTooltip =>
      'BusyMark\'ın harici görselleri yükleyip yükleyemeyeceğini seçin.';

  @override
  String get remoteImagesBlockedTitle => 'Harici görseller engellendi';

  @override
  String get remoteImagesBlockedMessage =>
      'Bu belge internetteki görsellere başvuruyor. Bunları yüklemek ağ bilgilerini görselin barındırıldığı sunucuya açığa çıkarabilir.';

  @override
  String get loadRemoteImagesForWorkspace => 'Bu çalışma alanı için yükleme';

  @override
  String get alwaysLoadRemoteImages => 'Harici görselleri her zaman yükle';

  @override
  String get hideSidebar => 'Kenar çubuğu panelini gizle';

  @override
  String get showSidebar => 'Kenar çubuğu panelini göster';

  @override
  String get showPreview => 'Önizlemeyi göster';

  @override
  String get hidePreview => 'Önizlemeyi gizle';

  @override
  String get workspaceKindUnsavedMarkdown => 'Kaydedilmemiş Markdown dosyası';

  @override
  String get workspaceKindSingleMarkdown => 'Tek Markdown dosyası';

  @override
  String get workspaceKindMarkdownFolder => 'Markdown klasörü';

  @override
  String get workspaceKindWritersideModule => 'Writerside modülü';

  @override
  String get problems => 'Sorunlar';

  @override
  String diagnosticCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tanılama',
      one: '1 tanılama',
      zero: 'Tanılama yok',
    );
    return '$_temp0';
  }

  @override
  String get files => 'Dosyalar';

  @override
  String get toc => 'İçindekiler';

  @override
  String get tocActions => 'İçindekiler eylemleri';

  @override
  String get markdownUnsaved => 'Kaydedilmemiş Markdown';

  @override
  String workspaceDetail(String kind, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya',
      one: '1 dosya',
    );
    return '$kind - $_temp0';
  }

  @override
  String get noFiles => 'Dosya yok';

  @override
  String get newFile => 'Yeni dosya';

  @override
  String get noWritersideToc => 'Writerside TOC\'si yok';

  @override
  String get tocSection => 'İçindekiler bölümü';

  @override
  String get newTopic => 'Yeni konu';

  @override
  String get newChildTopic => 'Yeni alt konu';

  @override
  String get newSiblingTopic => 'Yeni kardeş konu';

  @override
  String get renameTopicFile => 'Konu dosyasını yeniden adlandır';

  @override
  String get topicPlacement => 'İçindekiler yerleşimi';

  @override
  String get tocRoot => 'TOC kökünde';

  @override
  String get afterSelectedTopic => 'Seçili konunun ardından';

  @override
  String get insideSelectedTopic => 'Seçilen konunun içinde';

  @override
  String get pasteAfterTopic => 'Sonrasına yapıştır';

  @override
  String get pasteAsChildTopic => 'Alt konu olarak yapıştır';

  @override
  String get removeFromToc => 'TOC\'den kaldır';

  @override
  String get confirmRemoveFromTocTitle => 'TOC\'den kaldırılsın mı?';

  @override
  String confirmRemoveFromTocMessage(String name) {
    return '$name bu içindekiler tablosundan kaldırılsın mı? Konu dosyası saklanacaktır.';
  }

  @override
  String get confirmDeleteTopicTitle => 'Konu dosyası silinsin mi?';

  @override
  String confirmDeleteTopicMessage(String name) {
    return '$name silinip tüm içindekilerden kaldırılsın mı? Bu geri alınamaz.';
  }

  @override
  String get safeDeleteTopicFile => 'Konu dosyasını güvenle sil…';

  @override
  String get removeTocElement => 'TOC öğesini kaldır';

  @override
  String get reviewUsages => 'Kullanımları incele';

  @override
  String get deleteTopicFile => 'Konu dosyasını sil';

  @override
  String get removeAction => 'Kaldır';

  @override
  String topicRemovalSummary(String topic) {
    return 'Seçili örnekten “$topic” konusunu kaldır. Konu dosyası korunur.';
  }

  @override
  String safeDeleteTopicSummary(String topic) {
    return '“$topic” konusunu sil ve bu Writerside projesindeki referanslarını güvenle güncelle.';
  }

  @override
  String childTopicsPromoted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count alt konu bir seviye yukarı taşınacak.',
      one: '1 alt konu bir seviye yukarı taşınacak.',
    );
    return '$_temp0';
  }

  @override
  String get topicIsStartPageRemovalWarning =>
      'Bu konu bir Writerside örneğinin başlangıç sayfası olarak kullanılıyor. Devam etmeden önce kullanımlarını inceleyin ve başka bir başlangıç sayfası atayın.';

  @override
  String topicUsagesCount(int count) {
    return 'Kullanımlar ($count)';
  }

  @override
  String get noBreakingTopicUsages => 'Bozulacak referans bulunamadı.';

  @override
  String get topicUsagesFound =>
      'BusyMark bu konuya yönelik aşağıdaki referansları buldu.';

  @override
  String get topicUsageTocElements => 'İçindekiler öğeleri';

  @override
  String get topicUsageStartPages => 'Başlangıç sayfaları';

  @override
  String get topicUsageTopicLinks => 'Konu bağlantıları';

  @override
  String get topicUsageIncludes => 'Dahil etmeler';

  @override
  String usageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kullanım',
      one: '1 kullanım',
    );
    return '$_temp0';
  }

  @override
  String get refactoringOptions => 'Yeniden düzenleme seçenekleri';

  @override
  String get updateUsagesAutomatically => 'Kullanımları otomatik güncelle';

  @override
  String get updateUsagesAutomaticallyDescription =>
      'TOC başvurularını ve include öğelerini kaldırın, bağlantı metnini koruyun.';

  @override
  String get manualUsageUpdatesRequired =>
      'Bazı kullanımlar bu yeniden düzenleme işleminden önce el ile değişiklik yapılmasını gerektirir.';

  @override
  String get setRedirectTo => 'Yönlendirme hedefi:';

  @override
  String get noRedirectDescription => 'Eski yayımlanmış sayfayı yönlendirme.';

  @override
  String get redirectTarget => 'Yönlendirme hedefi';

  @override
  String get remainingUsagesBlockRemoval =>
      'Devam etmeden önce kalan kullanımları inceleyin ve güncelleyin veya mümkün olduğunda otomatik güncellemeleri etkinleştirin.';

  @override
  String usagesOfTopic(String topic) {
    return '$topic konusunun kullanımları';
  }

  @override
  String get noUsagesFound => 'Hiçbir kullanım bulunamadı';

  @override
  String get outsideSelectedInstance => 'seçilen örneğin dışında';

  @override
  String get doRefactor => 'Yeniden düzenle';

  @override
  String get orphanTopicTitle => 'Konu dosyası artık kullanılmıyor';

  @override
  String get keepTopicFile => 'Konu Dosyasını Sakla';

  @override
  String orphanTopicMessage(String topic) {
    return '“$topic” artık bu Writerside projesinin hiçbir yerinde kullanılmıyor. Dosyayı silin veya başka bir örnekte kullanmak üzere saklayın.';
  }

  @override
  String get defaultNewTopicTitle => 'Yeni konu';

  @override
  String get topicTitle => 'Konu başlığı';

  @override
  String get fileName => 'Dosya adı';

  @override
  String get topicTitleRequired => 'Konu başlığı zorunludur.';

  @override
  String get fileNameRequired => 'Dosya adı gerekli.';

  @override
  String get rename => 'Yeniden adlandır';

  @override
  String get confirmDeleteFileTitle => 'Dosya silinsin mi?';

  @override
  String get confirmDeleteFolderTitle => 'Klasör silinsin mi?';

  @override
  String confirmDeleteFileMessage(String name) {
    return '$name silinsin mi? Bu geri alınamaz.';
  }

  @override
  String confirmDeleteFolderMessage(String name) {
    return '$name ve içindeki tüm dosyalar silinsin mi? Bu geri alınamaz.';
  }

  @override
  String get useSingleSafeFileName => 'Tek bir güvenli dosya adı kullanın.';

  @override
  String useExpectedExtension(String extension) {
    return 'Seçilen format için $extension uzantısını kullanın.';
  }

  @override
  String get useIdentifierCharacters =>
      'Uzantının önünde harf, rakam, alt çizgi veya kısa çizgi kullanın.';

  @override
  String get topicIdAlreadyExists => 'Konu kimliği zaten mevcut.';

  @override
  String get createWritersideTopicFailed => 'Writerside konusu oluşturulamadı.';

  @override
  String get noOutline => 'Anahat yok';

  @override
  String expandKind(String kind) {
    return '$kind öğesini genişlet';
  }

  @override
  String collapseKind(String kind) {
    return '$kind öğesini daralt';
  }

  @override
  String get foldKindSection => 'bölüm';

  @override
  String get foldKindList => 'liste';

  @override
  String get foldKindQuote => 'alıntı';

  @override
  String get foldKindTag => 'etiket';

  @override
  String get sourceSearchPreviousMatch => 'Önceki eşleşme';

  @override
  String get sourceSearchNextMatch => 'Sonraki eşleşme';

  @override
  String get sourceSearchCaseSensitive => 'Büyük-küçük harf duyarlı';

  @override
  String get sourceSearchWholeWord => 'Tam sözcük';

  @override
  String get sourceSearchRegex => 'Düzenli ifade';

  @override
  String get sourceSearchReplacement => 'Şununla değiştir:';

  @override
  String get sourceSearchReplaceCurrent => 'Mevcut eşleşmeyi değiştir';

  @override
  String get sourceSearchReplaceAndFindNext => 'Değiştir ve sonrakini bul';

  @override
  String get sourceSearchReplaceAll => 'Tümünü değiştir';

  @override
  String get workspaceReplace => 'Çalışma alanında değiştir';

  @override
  String get reviewReplacements => 'Değiştirmeleri incele';

  @override
  String get applyReplacements => 'Değişiklikleri uygula';

  @override
  String get skippedFiles => 'Atlanan dosyalar';

  @override
  String get workspaceReplaceDirtyBuffer => 'Kaydedilmemiş düzenleyici içeriği';

  @override
  String get workspaceReplaceDiskContent => 'Kaydedilen disk içeriği';

  @override
  String selectFileMatches(int count) {
    return 'Tüm $count eşleşmeyi seç';
  }

  @override
  String workspaceReplaceApplied(int matches, int files, int skipped) {
    return '$files dosyada $matches eşleşme değiştirildi; $skipped dosya atlandı.';
  }

  @override
  String documentFormatWithFinalNewline(String encoding, String lineEnding) {
    return '$encoding · $lineEnding · Son satır sonu var';
  }

  @override
  String documentFormatWithoutFinalNewline(String encoding, String lineEnding) {
    return '$encoding · $lineEnding · Son satır sonu yok';
  }

  @override
  String get normalizeLineEndings => 'Satır sonlarını normalleştir';

  @override
  String get mixedLineEndingsSavePrompt =>
      'Bu belge karışık satır sonları içeriyor. Bir format seçin.';

  @override
  String workspaceReplaceMixedLineEndings(String fileName) {
    return '$fileName karışık satır sonları kullanır. Değiştirmeden önce kullanılacak formatı seçin.';
  }

  @override
  String get workspaceReplaceIssueOversized =>
      'Büyük boyutlu bir dosya atlandı.';

  @override
  String get workspaceReplaceIssueUnreadable => 'Okunamayan bir dosya atlandı.';

  @override
  String get workspaceReplaceIssueInvalidUtf8 =>
      'Geçerli UTF-8 olmayan bir dosya atlandı.';

  @override
  String get workspaceReplaceIssueTruncated => 'Değiştirme önizlemesi kesildi.';

  @override
  String get workspaceReplaceIssueFileChanged =>
      'Önizlemeden sonra değişen bir dosya atlandı.';

  @override
  String get workspaceReplaceIssueBufferChanged =>
      'Önizlemeden sonra değişen düzenleyici arabelleği atlandı.';

  @override
  String get workspaceReplaceIssueNormalizationRequired =>
      'Değiştirmeden önce LF veya CRLF normalizasyonunu seçin.';

  @override
  String get workspaceReplaceIssuePartialConflict =>
      'Dosya aynı anda değiştiği için geri alma durduruldu. Bazı değişiklikler kalabilir; yeri değiştirilen içerik aşağıdaki yolda korundu.';

  @override
  String get workspaceReplaceIssueApplyFailed =>
      'İncelenen değiştirme işlemi gerçekleştirilemedi; hiçbir dosya değiştirilmedi.';

  @override
  String externalChangesTitle(String fileName) {
    return 'Harici değişiklikler — $fileName';
  }

  @override
  String get externalFileDeleted => 'Bu dosya diskte silindi.';

  @override
  String get externalFileChanged =>
      'Kaydedilmemiş düzenlemeleriniz varken bu dosya diskte değişti.';

  @override
  String recoveredDocumentReview(String fileName) {
    return '$fileName için kurtarılan kaydedilmemiş içerik. İnceleyin, sonra kaydedin, farklı kaydedin veya vazgeçin.';
  }

  @override
  String get compare => 'Karşılaştır';

  @override
  String get reloadFromDisk => 'Diskten Yeniden Yükle';

  @override
  String get keepMine => 'Benimkini koru';

  @override
  String get saveAs => 'Farklı Kaydet';

  @override
  String get sourceSearchInvalidRegex => 'Geçersiz düzenli ifade';

  @override
  String get sourceLargeFileFeaturesPaused =>
      'Büyük dosya: vurgulama ve katlama duraklatıldı';

  @override
  String get nothingToRead => 'Okunacak bir şey yok';

  @override
  String get admonition => 'Bilgi kutusu';

  @override
  String get quote => 'Alıntı';

  @override
  String get note => 'Not';

  @override
  String get tip => 'İpucu';

  @override
  String get warning => 'Uyarı';

  @override
  String get tabs => 'Sekmeler';

  @override
  String get tab => 'Sekme';

  @override
  String get procedure => 'Prosedür';

  @override
  String get step => 'Adım';

  @override
  String get topic => 'Konu';

  @override
  String get chapter => 'Bölüm';

  @override
  String couldNotOpenTarget(String target) {
    return '$target açılamadı';
  }

  @override
  String linkTargetNotFound(String targetPath) {
    return 'Bağlantı hedefi bulunamadı: $targetPath';
  }

  @override
  String get cannotOpenFileTypeInEditor =>
      'Bu dosya türü düzenleyicide açılamıyor';

  @override
  String anchorNotFound(String anchor) {
    return 'Bağlantı noktası bulunamadı: $anchor';
  }

  @override
  String get noProblemsFound => 'Hiçbir sorun bulunamadı';

  @override
  String get noResults => 'Sonuç yok';

  @override
  String searchResultLine(String relativePath, int lineNumber) {
    return '$relativePath - Satır $lineNumber';
  }

  @override
  String get untitledResult => 'Başlıksız sonuç';

  @override
  String get documentKindMarkdownFile => 'Markdown dosyası';

  @override
  String get documentKindWritersideMarkdownTopic =>
      'Writerside Markdown konusu';

  @override
  String get documentKindWritersideXmlTopic => 'Writerside XML konusu';

  @override
  String get documentKindWritersideTree => 'Writerside ağacı';

  @override
  String get documentKindConfigurationFile => 'Yapılandırma dosyası';

  @override
  String get documentKindVariablesFile => 'Değişkenler dosyası';

  @override
  String get documentKindCategoriesFile => 'Kategoriler dosyası';

  @override
  String get documentKindResourceFile => 'Kaynak dosyası';

  @override
  String workspaceErrorOpenFailed(String error) {
    return 'Açma başarısız oldu: $error';
  }

  @override
  String workspaceErrorCreateWritersideProjectFailed(String error) {
    return 'Writerside projesi oluşturulamadı: $error';
  }

  @override
  String workspaceErrorCreateWritersideTopicFailed(String error) {
    return 'Writerside konusu oluşturulamadı: $error';
  }

  @override
  String workspaceErrorCouldNotOpenFile(String error) {
    return 'Dosya açılamadı: $error';
  }

  @override
  String get workspaceErrorChooseWhereToSaveMarkdown =>
      'Bu Markdown dosyasının nereye kaydedileceğini seçin.';

  @override
  String get workspaceErrorSaveBlockedFileChangedOnDisk =>
      'Kaydetme engellendi: diskteki dosya değiştirildi.';

  @override
  String workspaceErrorSaveFailed(String error) {
    return 'Kaydetme başarısız oldu: $error';
  }

  @override
  String workspaceErrorFileOperationFailed(String error) {
    return 'Dosya işlemi başarısız oldu: $error';
  }

  @override
  String workspaceErrorValidationFailed(String error) {
    return 'Doğrulama başarısız oldu: $error';
  }

  @override
  String workspaceRecoveryRestored(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count kaydedilmemiş belge kurtarıldı. Kaydetmeden veya silmeden önce her birini inceleyin.',
      one:
          '1 kaydedilmemiş belge kurtarıldı. Kaydetmeden veya silmeden önce inceleyin.',
    );
    return '$_temp0';
  }

  @override
  String workspaceRecoveryDamaged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count hasarlı kurtarma kaydı geri yüklenemedi. Geçerli kurtarma kayıtları kullanılabilir durumda.',
      one:
          'Hasarlı bir kurtarma kaydı geri yüklenemedi. Özgün kurtarma dosyası incelenmek üzere korundu.',
    );
    return '$_temp0';
  }

  @override
  String errorPathDoesNotExist(String path) {
    return 'Yol mevcut değil: $path';
  }

  @override
  String errorTargetDirectoryNotEmpty(String path) {
    return 'Hedef dizin zaten mevcut ve boş değil: $path';
  }

  @override
  String errorTargetPathNotDirectory(String path) {
    return 'Hedef yol zaten mevcut ve bir dizin değil: $path';
  }

  @override
  String errorGeneratedFileAlreadyExists(String path) {
    return 'Oluşturulan dosya zaten mevcut: $path';
  }

  @override
  String get errorParentDirectoryRequired => 'Ana dizin gerekli.';

  @override
  String errorParentDirectoryMissing(String path) {
    return 'Ana dizin mevcut değil: $path';
  }

  @override
  String errorDirectoryMissing(String path) {
    return 'Dizin mevcut değil: $path';
  }

  @override
  String errorPathAlreadyExists(String path) {
    return 'Yol zaten mevcut: $path';
  }

  @override
  String get errorFileNameRequired => 'Dosya adı gerekli.';

  @override
  String get errorFileNameUnsafe =>
      'Dosya adı tek bir güvenli yol bölümü olmalıdır.';

  @override
  String get errorFileOperationInvalidTarget =>
      'Bir klasör kendi içine taşınamaz.';

  @override
  String get errorFileOperationOutsideRoot =>
      'Dosya işlemi çalışma alanının içinde kalmalıdır.';

  @override
  String get errorFileOperationRoot =>
      'Çalışma alanı kökü dosya ağacından değiştirilemez.';

  @override
  String get errorProjectNameRequired => 'Proje adı gerekli.';

  @override
  String get errorDirectoryNameRequired => 'Klasör adı gerekli.';

  @override
  String get errorDirectoryNameUnsafe =>
      'Klasör adı tek bir güvenli yol bölümü olmalıdır.';

  @override
  String get errorInstanceIdInvalid =>
      'Örnek kimliği küçük harfle başlamalı ve yalnızca küçük harfler, sayılar, alt çizgiler ve kısa çizgiler içermelidir.';

  @override
  String get errorTopicFileInvalid =>
      'Konu dosyası adı, yol ayırıcıları olmayan bir Markdown dosya adı olmalıdır.';

  @override
  String get errorTopicTitleRequired => 'Konu başlığı zorunludur.';

  @override
  String errorWritersideModuleRootMissing(String path) {
    return 'Writerside modül kökü mevcut değil: $path';
  }

  @override
  String get errorWritersideModuleNotOpen =>
      'Konu oluşturmak için Writerside modülünün açık olması gerekir.';

  @override
  String get errorWritersideInstanceTreeMissing =>
      'Writerside modülünün örnek ağacı yoktur.';

  @override
  String errorWritersideTreeFileMissing(String path) {
    return 'Writerside ağaç dosyası mevcut değil: $path';
  }

  @override
  String errorTopicIdAlreadyExists(String topicId) {
    return 'Konu Kimliği \"$topicId\" bu yardım modülünde zaten mevcut.';
  }

  @override
  String errorTopicFileAlreadyExists(String path) {
    return 'Konu dosyası zaten mevcut: $path';
  }

  @override
  String errorReferenceTopicMissing(String topic) {
    return 'Referans konusu seçilen ağaçta mevcut değil: $topic';
  }

  @override
  String get errorWritersideTocNodeMissing =>
      'Seçilen TOC girişi artık mevcut değil.';

  @override
  String get errorWritersideTocInvalidMove =>
      'Bir TOC girişi kendisine veya alt öğelerinden birine taşınamaz.';

  @override
  String errorWritersideStartTopicDelete(String topic) {
    return '$topic başlangıç konusu silinemez. Önce başka bir başlangıç sayfası seçin.';
  }

  @override
  String get errorWritersideSafeDeleteRequired =>
      'Writerside konu dosyaları için Güvenli Silme\'yi kullanın.';

  @override
  String get errorWritersideTopicUsageScanFailed =>
      'Konu kullanımı taraması tamamlanamadı. Hiçbir dosya değiştirilmedi.';

  @override
  String get errorWritersideTopicUsagesRemain =>
      'Bazı konu kullanımları hâlâ dikkat gerektiriyor. Devam etmeden önce bunları inceleyin.';

  @override
  String get errorWritersideRedirectInvalid =>
      'Seçilen yönlendirme hedefi artık geçerli değil. Tekrar seçin.';

  @override
  String errorWritersideRollbackFailed(String paths) {
    return 'Konu kaldırma işlemi tamamen geri alınamadı. Devam etmeden önce şu yolları inceleyin: $paths';
  }

  @override
  String get errorTopicsRootUnsafe =>
      'Konu kökü güvenli bir göreli dizin olmalıdır.';

  @override
  String get errorTopicFileNameUnsafe =>
      'Konu dosyası adı tek bir güvenli yol bölümü olmalıdır.';

  @override
  String errorTopicFileExtensionMismatch(String extension) {
    return 'Konu dosyası uzantısı seçilen formatla ($extension) eşleşmelidir.';
  }

  @override
  String get errorTopicFileNameInvalid =>
      'Konu dosyası adı yalnızca harf, rakam, alt çizgi ve kısa çizgi içermelidir.';

  @override
  String errorUnknown(String code) {
    return 'Bilinmeyen hata: $code';
  }

  @override
  String diagnosticWorkspaceFileStatFailed(String error) {
    return 'Dosya meta verileri okunamadı: $error';
  }

  @override
  String get diagnosticWorkspaceScanSkipped =>
      'Büyük çalışma alanı algılandı. Uygulamanın duyarlı kalması için bazı dosyalar atlandı.';

  @override
  String diagnosticWorkspaceScanInspectFailed(String error) {
    return 'Çalışma alanı girişi incelenemedi: $error';
  }

  @override
  String get diagnosticWorkspaceFileTooLarge =>
      'Dosya beta otomatik ayrıştırma sınırından daha büyük.';

  @override
  String diagnosticWorkspaceFileReadFailed(String error) {
    return 'Markdown dosyası okunamadı: $error';
  }

  @override
  String get diagnosticMarkdownAttributeMalformed =>
      'Biçimi bozuk Writerside başlık öznitelik bloğu.';

  @override
  String diagnosticMarkdownHeadingDuplicateId(String id) {
    return 'Yinelenen başlık kimliği \"$id\".';
  }

  @override
  String get diagnosticWritersideTopicH1ConvertedToChapter =>
      'Ek üst düzey H1 başlıkları bölümler olarak ele alınır.';

  @override
  String get diagnosticWritersideMarkdownTopicMissingTitle =>
      'Writerside Markdown konusunun H1 veya frontmatter başlığı yok.';

  @override
  String get diagnosticWritersideXmlTopicMissingTitle =>
      'XML konusunun başlığı eksik.';

  @override
  String diagnosticWritersideTopicFileMissingTitle(String fileName) {
    return '\"$fileName\" konusunun başlığı eksik.';
  }

  @override
  String get diagnosticMarkdownFrontMatterMalformed =>
      'Frontmatter kapatılmamış.';

  @override
  String get diagnosticMarkdownRawHtmlUnsafe => 'Güvenli olmayan HTML öğesi.';

  @override
  String diagnosticMarkdownLinkUnresolvedTarget(String targetPath) {
    return 'Bağlantı hedefi mevcut değil: $targetPath';
  }

  @override
  String diagnosticMarkdownLinkUnresolvedAnchor(String anchor) {
    return '\"$anchor\" çapası mevcut değil.';
  }

  @override
  String diagnosticMarkdownImageMissingAlt(String destination) {
    return '\"$destination\" görselinde alternatif metin eksik.';
  }

  @override
  String diagnosticMarkdownImageMissingFile(String destination) {
    return 'Resim mevcut değil: $destination';
  }

  @override
  String diagnosticInvalidXml(String message) {
    return 'Geçersiz XML: $message';
  }

  @override
  String get diagnosticWritersideConfigInvalidRoot =>
      'writerside.cfg kökü <ihp> olmalıdır.';

  @override
  String get diagnosticWritersideConfigMissingSnippetsSrc =>
      'snippet bildiriminde src eksik.';

  @override
  String get diagnosticWritersideConfigMissingInstanceGroupsSrc =>
      'instance-groups bildiriminde src eksik.';

  @override
  String diagnosticWritersideConfigInvalidKeymapsMode(String mode) {
    return 'Desteklenmeyen tuş haritaları modu: $mode';
  }

  @override
  String get diagnosticWritersideConfigMissingInstanceSrc =>
      'Instance bildiriminde src eksik.';

  @override
  String get diagnosticWritersideConfigMissingInstance =>
      'writerside.cfg bir instance kaydetmiyor.';

  @override
  String get diagnosticWritersideTreeInvalidRoot =>
      '.tree kökü <instance-profile> olmalıdır.';

  @override
  String get diagnosticWritersideTreeMissingId =>
      'Instance profilinde kimlik eksik.';

  @override
  String diagnosticWritersideTreeIdMismatch(String id) {
    return 'Ağaç dosyası kökü \"$id\" instance kimliğiyle eşleşmiyor.';
  }

  @override
  String get diagnosticWritersideTreeMissingStartPage =>
      'Kütüphane olmayan örnek start-page içermiyor.';

  @override
  String diagnosticWritersideStartPageMissing(String startPage) {
    return '\"$startPage\" başlangıç sayfası mevcut değil.';
  }

  @override
  String diagnosticWritersideTreeDuplicateTopic(String topic) {
    return 'Bu instance\'ın TOC\'sinde \"$topic\" konusu birden fazla kez görünüyor.';
  }

  @override
  String get diagnosticWritersideVariableMalformedDeclaration =>
      'Değişken bildiriminin adı ve değeri olmalıdır.';

  @override
  String diagnosticWritersideVariableDuplicateName(String name) {
    return '\"$name\" değişkeni birden fazla kez bildirildi.';
  }

  @override
  String get diagnosticWritersideCategoryMissingId =>
      'Kategorinin kimliği eksik.';

  @override
  String diagnosticWritersideCategoryDuplicateId(String id) {
    return '\"$id\" kategorisi birden fazla kez bildirildi.';
  }

  @override
  String diagnosticWritersideCategoryDuplicateOrder(String order) {
    return 'Kategori sırası \"$order\" birden fazla kez bildirildi.';
  }

  @override
  String get diagnosticWritersideTopicInvalidRoot =>
      '.topic kökü <topic> olmalıdır.';

  @override
  String get diagnosticWritersideTopicMissingRootId =>
      'XML konusunun kök kimliği eksik.';

  @override
  String diagnosticWritersideTopicRootIdMismatch(String id, String expectedId) {
    return 'XML konu kök kimliği \"$id\", \"$expectedId\" dosya adıyla eşleşmelidir.';
  }

  @override
  String diagnosticWritersideTopicDuplicateElementId(String elementId) {
    return 'Öğe kimliği \"$elementId\" birden fazla görünüyor.';
  }

  @override
  String get diagnosticWritersideTopicAnchorMissingHref =>
      '<a>\'da href eksik.';

  @override
  String get diagnosticWritersideConfigMissing =>
      'Writerside modu için writerside.cfg gereklidir.';

  @override
  String diagnosticWritersideConfigMissingBuildConfigDirectory(
    String relativePath,
  ) {
    return 'Yapılandırılmış yapı yapılandırma dizini eksik: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingApiSpecificationsDirectory(
    String relativePath,
  ) {
    return 'Yapılandırılmış API spesifikasyonları dizini eksik: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingSnippetsDirectory(
    String relativePath,
  ) {
    return 'Yapılandırılmış snippet dizini eksik: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingVarsFile(String relativePath) {
    return 'Yapılandırılmış değişkenler dosyası eksik: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingCategoriesFile(String relativePath) {
    return 'Yapılandırılmış kategoriler dosyası eksik: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceGroupsFile(
    String relativePath,
  ) {
    return 'Yapılandırılmış instance grupları dosyası eksik: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceTree(String source) {
    return 'Kayıtlı instance ağacı \"$source\" mevcut değil.';
  }

  @override
  String diagnosticWritersideTopicReadFailed(String error) {
    return 'Konu dosyası okunamadı: $error';
  }

  @override
  String diagnosticWritersideDefaultTopicsDirectoryMissing(
    String relativePath,
  ) {
    return 'Varsayılan konu dizini eksik: $relativePath';
  }

  @override
  String diagnosticWritersideTopicsDirectoryMissing(String relativePath) {
    return 'Yapılandırılmış konular dizini eksik: $relativePath';
  }

  @override
  String diagnosticWritersideImagesDirectoryMissing(String relativePath) {
    return 'Yapılandırılmış görüntüler dizini eksik: $relativePath';
  }

  @override
  String diagnosticWritersideTopicDuplicateId(String id) {
    return 'Öğe kimliği \"$id\" birden fazla görünüyor.';
  }

  @override
  String diagnosticWritersideTreeMissingTopic(String topic) {
    return 'TOC, eksik \"$topic\" konusuna atıfta bulunuyor.';
  }

  @override
  String diagnosticWritersideTreeInvalidHref(String href) {
    return 'Harici href \"$href\" geçersiz.';
  }

  @override
  String diagnosticWritersideVariableUnresolved(String name) {
    return '\"%$name%\" değişkeni bildirilmedi.';
  }

  @override
  String diagnosticWritersideTopicLinkUnresolved(String destination) {
    return '\"$destination\" konu bağlantısı çözülmüyor.';
  }

  @override
  String diagnosticWritersideAnchorUnresolved(
    String anchor,
    String targetName,
  ) {
    return '\"$anchor\" çapası \"$targetName\"te mevcut değil.';
  }

  @override
  String get diagnosticWritersideIncludeMissingFrom =>
      '<include> öğesinde from niteliği eksik.';

  @override
  String diagnosticWritersideIncludeSourceMissing(String from) {
    return 'Include kaynağı \"$from\" mevcut değil.';
  }

  @override
  String diagnosticWritersideIncludeElementMissing(
    String elementId,
    String from,
  ) {
    return '\"$elementId\" dahil etme öğesi \"$from\"te mevcut değil.';
  }

  @override
  String diagnosticWritersideCategoryUnresolved(String ref) {
    return 'seealso kategorisi \"$ref\" bildirilmemiş.';
  }

  @override
  String diagnosticWritersideTopicAmbiguousReference(String reference) {
    return 'Konu referansı \"$reference\" belirsiz.';
  }

  @override
  String diagnosticUnknown(String code) {
    return 'Bilinmeyen teşhis: $code';
  }

  @override
  String get close => 'Kapat';

  @override
  String get git => 'Git';

  @override
  String get gitDiff => 'Git farkı';

  @override
  String get gitShowDiff => 'Farkı göster';

  @override
  String gitDiffHunkRange(String oldRange, String newRange) {
    return 'eski $oldRange → yeni $newRange';
  }

  @override
  String get gitDiffNoLines => 'satır yok';

  @override
  String get gitUnavailableTitle => 'Git kullanılamıyor';

  @override
  String gitUnavailableMessage(String reason) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'other':
          'Git\'i yükleyin veya BusyMark\'i kullanılabilir bir Git çalıştırılabilir dosyası kullanacak şekilde yapılandırın. $reason',
    });
    return '$_temp0';
  }

  @override
  String get gitTrustRequiredTitle =>
      'Git için bu çalışma alanına güveniyor musunuz?';

  @override
  String get gitTrustRequiredMessage =>
      'Git depoları programları kancalar, filtreler ve diğer yapılandırmalar aracılığıyla çalıştırabilir. BusyMark depo verilerini okumadan veya Git eylemlerini etkinleştirmeden önce bu çalışma alanına güvenin.';

  @override
  String get gitTrustWorkspace => 'Çalışma alanına güven';

  @override
  String get gitNotRepositoryTitle => 'Git deposu değil';

  @override
  String get gitNotRepositoryMessage =>
      'Bu çalışma alanı Git deposunun içinde değil.';

  @override
  String get gitInitializeRepository => 'Git deposunu başlat';

  @override
  String get gitDetachedHead => 'Ayrık HEAD';

  @override
  String gitDetachedHeadAt(String commit) {
    return '$commit\'te ayrılmış';
  }

  @override
  String get gitNoUpstream => 'Upstream yok';

  @override
  String gitAheadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gönderilmemiş commit',
      one: '1 gönderilmemiş commit',
    );
    return '$_temp0';
  }

  @override
  String gitBehindCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count çekilecek commit',
      one: '1 çekilecek commit',
    );
    return '$_temp0';
  }

  @override
  String get gitClean => 'Değişiklik yok';

  @override
  String get gitConflicts => 'Çatışmalar';

  @override
  String get gitChanges => 'Değişiklikler';

  @override
  String get gitStaged => 'Stage edilmiş';

  @override
  String get gitUnstaged => 'Stage edilmemiş';

  @override
  String get gitHistory => 'Geçmiş';

  @override
  String get gitBranches => 'Dallar';

  @override
  String get gitActions => 'Git işlemleri';

  @override
  String get gitPull => 'Pull';

  @override
  String get gitFetch => 'Getir';

  @override
  String get gitPush => 'Push';

  @override
  String get gitCommit => 'Commit et';

  @override
  String get gitSelectForCommit => 'Commit için seç';

  @override
  String get gitRemoveFromCommit => 'Commit\'ten çıkar';

  @override
  String get gitDiscard => 'Değişikliklerden vazgeç';

  @override
  String get gitOpenFile => 'Dosyayı aç';

  @override
  String get gitMarkResolved => 'Çözüldü olarak işaretle';

  @override
  String get gitUntracked => 'İzlenmiyor';

  @override
  String get gitCommitMessage => 'Commit mesajı';

  @override
  String get gitCommitSelectedFiles => 'Seçili dosyalar';

  @override
  String get gitCommitNoSelectedFiles =>
      'Commit etmeden önce en az bir dosyayı stage edin.';

  @override
  String gitStagedFileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stage edilmiş dosya',
      one: '1 stage edilmiş dosya',
    );
    return '$_temp0';
  }

  @override
  String get gitOutsideWorkspace => 'Çalışma alanı dışında';

  @override
  String get gitCommitMessageRequired => 'Bir commit mesajı girin.';

  @override
  String get gitCreateBranch => 'Dal oluştur';

  @override
  String get gitNewBranch => 'Yeni dal';

  @override
  String get gitBranchName => 'Dal adı';

  @override
  String get gitSwitchBranch => 'Dal değiştir';

  @override
  String get gitNoChanges => 'Değişiklik yok';

  @override
  String get gitNoHistory => 'Geçmiş yok';

  @override
  String get gitNoBranches => 'Dal yok';

  @override
  String get gitNoDiff => 'Gösterilecek fark yok';

  @override
  String get gitBinaryFile => 'İkili dosya. BusyMark ikili yamaları göstermez.';

  @override
  String gitBinaryFileInfo(int size) {
    return 'İkili dosya ($size bayt). BusyMark ikili yamaları göstermez.';
  }

  @override
  String get gitUnsavedChangesBanner =>
      'Kaydedilmemiş düzenleyici değişiklikleri kaydedilene kadar dahil edilmez.';

  @override
  String get gitConfirmDiscardTitle => 'Git değişikliklerinden vazgeçilsin mi?';

  @override
  String gitConfirmDiscardTracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Seçili izlenen dosyalardaki tüm stage edilmiş ve stage edilmemiş değişiklikler HEAD sürümüne geri yüklenecek.',
      one:
          'Seçili izlenen dosyadaki tüm stage edilmiş ve stage edilmemiş değişiklikler HEAD sürümüne geri yüklenecek.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardUntracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Seçili izlenmeyen dosyalar silinecek.',
      one: 'Seçili izlenmeyen dosya silinecek.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardMixed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Seçili dosyalar Git durumlarına göre geri yüklenecek veya silinecek.',
      one: 'Seçili dosya Git durumuna göre geri yüklenecek veya silinecek.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmSwitchBranchTitle(String branch) {
    return '$branch\'e geçilsin mi?';
  }

  @override
  String get gitConfirmSwitchBranchMessage =>
      'Git başka bir dala geçtikten sonra BusyMark çalışma alanını diskten yeniden yükleyecek.';

  @override
  String get gitConfirmPushSetUpstreamTitle => 'Upstream dalı ayarlansın mı?';

  @override
  String gitConfirmPushSetUpstreamMessage(String branch) {
    return 'Bu dalın upstream\'i yok. Tam olarak bir remote yapılandırılmışsa BusyMark $branch dalını push edip upstream\'i ayarlayabilir.';
  }

  @override
  String get gitProjectHistory => 'Proje Geçmişi';

  @override
  String get gitFileHistory => 'Dosya Geçmişi';

  @override
  String get gitFileHistoryRequiresOpenFile =>
      'Dosya Geçmişi açık bir Markdown dosyası gerektirir.';

  @override
  String get gitLoadMore => 'Daha Fazla Yükle';

  @override
  String get gitChangesInCommit => 'Bu commit\'teki değişiklikler';

  @override
  String get gitCompareWithCurrent => 'Mevcut sürümle karşılaştır';

  @override
  String get gitRestoreVersion => 'Bu sürümü geri yükle';

  @override
  String get gitConfirmRestoreTitle => 'Bu dosya sürümü geri yüklensin mi?';

  @override
  String get gitConfirmRestoreMessage =>
      'BusyMark mevcut çalışma ağacı dosyasını seçili commit sürümüyle değiştirir. Geri yüklenen dosya stage edilmemiş durumda kalır.';

  @override
  String get gitCommitActions => 'Commit işlemleri';

  @override
  String get gitResetCurrentBranchToHere => 'Mevcut dalı buraya sıfırla…';

  @override
  String gitResetCurrentBranchTitle(String branch, String commit) {
    return '$branch, $commit\'e sıfırlansın mı?';
  }

  @override
  String gitResetCurrentBranchMessage(String branch, String commit) {
    return 'Bu işlem $branch dalını $commit commit\'ine taşır. Git\'in dizini ve çalışma ağacını nasıl güncelleyeceğini seçin.';
  }

  @override
  String get gitReset => 'Sıfırla';

  @override
  String get gitResetModeSoft => 'Soft';

  @override
  String get gitResetModeSoftDescription =>
      'Yalnızca dalı taşıyın. Dizini ve çalışma ağacını değiştirmeyin; seçili commit ile arasındaki farklar stage edilmiş olarak kalır.';

  @override
  String get gitResetModeMixed => 'Mixed';

  @override
  String get gitResetModeMixedDescription =>
      'Dalı taşıyın ve dizini sıfırlayın. Çalışma ağacını değiştirmeyin; farkları stage edilmemiş durumda bırakın.';

  @override
  String get gitResetModeHard => 'Hard';

  @override
  String get gitResetModeHardDescription =>
      'Dalı taşıyın ve dizini ve çalışma ağacını sıfırlayın. İzlenen değişiklikler atılır; yolu engelleyen izlenmeyen dosyalar silinebilir.';

  @override
  String get gitResetModeKeep => 'Keep';

  @override
  String get gitResetModeKeepDescription =>
      'Yerel değişiklikleri koruyarak dalı taşıyın ve izlenen dosyaları sıfırlayın. Bu değişiklikler sıfırlamayla çakışırsa Git işlemi iptal eder.';

  @override
  String gitAdditionsDeletions(int additions, int deletions) {
    return '+$additions -$deletions';
  }

  @override
  String get fileActions => 'Dosya eylemleri';

  @override
  String get actions => 'Eylemler';

  @override
  String get gitStatusAdded => 'Eklendi';

  @override
  String get gitStatusDeleted => 'Silindi';

  @override
  String get gitStatusRenamed => 'Yeniden adlandırıldı';

  @override
  String get gitStatusCopied => 'Kopyalandı';

  @override
  String get gitStatusUntracked => 'İzlenmiyor';

  @override
  String get gitStatusConflicted => 'Çatışmalı';

  @override
  String get gitStatusIgnored => 'Yoksayıldı';

  @override
  String get gitStatusTypeChanged => 'Tür değiştirildi';

  @override
  String get gitStatusModified => 'Değiştirildi';

  @override
  String get gitStatusUnknown => 'Bilinmiyor';

  @override
  String get gitErrorUnavailable => 'Git kullanılamıyor.';

  @override
  String get gitErrorNotRepository => 'Bu çalışma alanı bir Git deposu değil.';

  @override
  String get gitErrorUnsafePath =>
      'BusyMark güvenli olmayan bir Git yolunu engelledi.';

  @override
  String get gitErrorInvalidBranchName => 'Geçerli bir dal adı girin.';

  @override
  String get gitErrorNoRemote => 'Git remote\'u yapılandırılmamış.';

  @override
  String get gitErrorNoUpstream => 'Upstream dalı yapılandırılmamış.';

  @override
  String get gitErrorMultipleRemotes =>
      'Birden fazla remote yapılandırılmış. Bu BusyMark sürümünün dışında bir upstream seçin.';

  @override
  String get gitErrorDirtyWorkspace =>
      'Dal değiştirmeden önce BusyMark düzenleyici değişikliklerini kaydedin veya göz ardı edin.';

  @override
  String get gitErrorResetDirtyWorkspace =>
      'Geçerli dalı sıfırlamadan önce BusyMark düzenleyici değişikliklerini kaydedin veya yok sayın.';

  @override
  String get gitErrorRestoreStagedFile =>
      'Geçmiş bir sürümü geri yüklemeden önce bu dosyayı staging\'den çıkarın.';

  @override
  String get gitErrorResetDetachedHead => 'Sıfırlamadan önce bir dala geçin.';

  @override
  String get gitErrorDiverged =>
      'Dallar birbirinden ayrılmış. Birleştirme veya yeniden temellendirme işlemini bu BusyMark sürümünün dışında çözün.';

  @override
  String get gitErrorAuthorIdentity =>
      'Git\'in commit atabilmesi için bir yazar adına ve e-posta adresine ihtiyacı var.';

  @override
  String get gitAuthorIdentityTitle => 'Git yazar kimliği';

  @override
  String get gitAuthorIdentityMessage =>
      'Git\'in commit\'lerde kullanacağı kimliği girin. BusyMark bu kimliği kaydedecek ve commit\'i yeniden deneyecek.';

  @override
  String get gitAuthorName => 'İsim';

  @override
  String get gitAuthorEmail => 'E-posta';

  @override
  String get gitAuthorIdentityGlobal => 'Tüm depolar için kullanın';

  @override
  String get gitAuthorIdentityGlobalDescription =>
      'BusyMark Snap olarak kurulduysa bu ayar BusyMark\'ta açılan tüm depolar için geçerlidir.';

  @override
  String get gitSaveIdentityAndCommit => 'Kimliği kaydet ve commit et';

  @override
  String get gitErrorAuthentication => 'Git kimlik doğrulaması başarısız oldu.';

  @override
  String get gitErrorNetwork => 'Git ağ işlemi başarısız oldu.';

  @override
  String get gitErrorConflict => 'Git çözülmemiş çakışmaları bildirdi.';

  @override
  String get gitErrorCommandFailed => 'Git komutu başarısız oldu.';

  @override
  String get markdownAndHtml => 'Markdown ve HTML';

  @override
  String get markdownHtmlMarkdownBlocks => 'Markdown blokları';

  @override
  String get markdownHtmlMarkdownBlocksDescription =>
      'Markdown kaynağında ve önizlemesinde desteklenen blok yapıları.';

  @override
  String get markdownHtmlInlineFormatting => 'Satır içi biçimlendirme';

  @override
  String get markdownHtmlInlineFormattingDescription =>
      'Paragrafların, liste öğelerinin ve tablo hücrelerinin içinde görünebilecek biçimlendirme.';

  @override
  String get markdownHtmlRawHtmlBlocks => 'Ham HTML Blokları';

  @override
  String get markdownHtmlRawHtmlBlocksDescription =>
      'BusyMark önizleme widget\'ları aracılığıyla oluşturulan güvenli blok düzeyinde HTML etiketleri.';

  @override
  String get markdownHtmlRawHtmlInline => 'Ham HTML Satır İçi Etiketleri';

  @override
  String get markdownHtmlRawHtmlInlineDescription =>
      'Gerçek etiketler gösterilmeden oluşturulan güvenli satır içi HTML etiketleri.';

  @override
  String get markdownHtmlSafety => 'Güvenlik Kuralları';

  @override
  String get markdownHtmlSafetyDescription =>
      'Ham HTML, önizleme oluşturmadan önce ayrıştırılır ve arındırılır.';

  @override
  String get markdownHtmlHeadings => 'Başlıklar';

  @override
  String get markdownHtmlParagraphs => 'Paragraflar';

  @override
  String get markdownHtmlLists => 'Listeler';

  @override
  String get markdownHtmlHtmlContainers => 'Konteynerler';

  @override
  String get markdownHtmlHtmlTextBlocks => 'Metin blokları';

  @override
  String get markdownHtmlHtmlFigures => 'Şekiller ve görseller';

  @override
  String get markdownHtmlHtmlPreformatted => 'Önceden biçimlendirilmiş kod';

  @override
  String get markdownHtmlHtmlDisclosure => 'Açıklama blokları';

  @override
  String get markdownHtmlHtmlDescriptionLists => 'Açıklama listeleri';

  @override
  String get markdownHtmlHtmlFormattingTags => 'Etiketleri biçimlendirme';

  @override
  String get markdownHtmlHtmlInlineCodeTags => 'Satır içi kod etiketleri';

  @override
  String get markdownHtmlHtmlNeutralInlineTags => 'Anlamsal metin etiketleri';

  @override
  String get markdownHtmlSanitizedPreview => 'Temizlenmiş önizleme';

  @override
  String get markdownHtmlSanitizedPreviewDescription =>
      'İzin verilen HTML, tarayıcıda oluşturulmaz, BusyMark önizleme bloklarına dönüştürülür.';

  @override
  String get markdownHtmlSourcePreserved => 'Kaynak korunur';

  @override
  String get markdownHtmlSourcePreservedDescription =>
      'Düzenlenmemiş ham HTML, tam olarak kaynak metin olarak kaydedilir.';

  @override
  String get markdownHtmlMarkdownInsideHtml => 'HTML içindeki Markdown';

  @override
  String get markdownHtmlMarkdownInsideHtmlDescription =>
      'Ham HTML içindeki Markdown işaretleri düz metin olarak görüntülenir.';

  @override
  String get markdownHtmlBlockedContent => 'Engellenen etkin içerik';

  @override
  String get markdownHtmlBlockedContentDescription =>
      'Komut dosyaları, stiller, çerçeveler, formlar, SVG, MathML, olaylar ve güvenli olmayan özellikler engellenir.';

  @override
  String get markdownHtmlSafeUrls => 'Yalnızca güvenli URL\'ler';

  @override
  String get markdownHtmlSafeUrlsDescription =>
      'Bağlantılar http, https, mailto, tel, göreli ve parça URL\'lerine izin verir; güvenli olmayan şemalar engellenir.';

  @override
  String get exportAsPdf => 'PDF olarak dışa aktar';

  @override
  String get pdfExportDescription =>
      'Kendi başına kullanılabilen, düzenli bir PDF için sayfa düzenini seçin.';

  @override
  String get pdfRemoteImagesNote =>
      'Dışa aktarma sırasında harici görseller indirilmez. Varsa yerel görseller eklenir.';

  @override
  String get pdfPageSize => 'Sayfa boyutu';

  @override
  String get pdfPageSizeA4 => 'A4';

  @override
  String get pdfPageSizeLetter => 'Letter boyutu';

  @override
  String get pdfOrientation => 'Yönlendirme';

  @override
  String get pdfPortrait => 'Portre';

  @override
  String get pdfLandscape => 'Manzara';

  @override
  String get pdfMargins => 'Kenar boşlukları';

  @override
  String get pdfMarginNarrow => 'Dar';

  @override
  String get pdfMarginNormal => 'Standart';

  @override
  String get pdfMarginWide => 'Geniş';

  @override
  String get pdfIncludePageNumbers => 'Sayfa numaralarını dahil et';

  @override
  String get export => 'Dışa aktar';

  @override
  String get exportingPdf => 'PDF dışa aktarılıyor…';

  @override
  String get fileTypePdf => 'PDF belgesi';

  @override
  String pdfExported(String fileName) {
    return '$fileName dışa aktarıldı.';
  }

  @override
  String pdfExportedWithWarnings(String fileName, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uyarıyla',
      one: '1 uyarıyla',
    );
    return '$fileName, $_temp0 birlikte dışa aktarıldı.';
  }

  @override
  String get pdfExportUnavailable =>
      'PDF dışa aktarma bileşeni eksik. BusyMark\'ı yeniden yükleyin ve tekrar deneyin.';

  @override
  String get pdfExportTimedOut =>
      'PDF dışa aktarımı çok uzun sürdü ve durduruldu.';

  @override
  String get pdfExportFailed =>
      'BusyMark bu belgeyi PDF olarak dışa aktaramadı.';

  @override
  String get visualizationRendering => 'Oluşturuluyor…';

  @override
  String get visualizationStale => 'Son geçerli görünüm gösteriliyor';

  @override
  String get visualizationShowSource => 'Kaynağı göster';

  @override
  String get visualizationShowRender => 'Görünümü göster';

  @override
  String get visualizationFitWidth => 'Genişliğe sığdır';

  @override
  String get visualizationSaveImage => 'Görseli kaydet';

  @override
  String get visualizationCopyImage => 'Görseli kopyala';

  @override
  String get visualizationImageCopied => 'Resim kopyalandı';

  @override
  String get visualizationOpenApiReference => 'API Referansını Aç';

  @override
  String get visualizationValid => 'Geçerli';

  @override
  String get visualizationInvalid => 'Geçersiz';

  @override
  String get visualizationServers => 'Sunucular';

  @override
  String get visualizationPaths => 'Yollar';

  @override
  String get visualizationOperations => 'Operasyonlar';

  @override
  String get visualizationTags => 'Etiketler';

  @override
  String get visualizationNoOperations => 'Eşleşen işlem bulunamadı';

  @override
  String get visualizationSearchOperations => 'İşlemleri ara';

  @override
  String get visualizationRenderFailed => 'Bu görselleştirme oluşturulamadı.';

  @override
  String get visualizationRetry => 'Yeniden dene';

  @override
  String visualizationSaved(String fileName) {
    return '$fileName kaydedildi';
  }

  @override
  String get shortcutExportPdfDescription =>
      'Etkin belgeyi veya Writerside modülünü PDF olarak dışa aktarın.';

  @override
  String get instances => 'Örnekler';

  @override
  String get newInstance => 'Yeni örnek';

  @override
  String get newTocLibrary => 'Yeni TOC kitaplığı';

  @override
  String get editInstance => 'Örneği düzenle';

  @override
  String get openTocFile => 'TOC dosyasını aç';

  @override
  String get createInstance => 'Örnek oluştur';

  @override
  String get createTocLibrary => 'İçindekiler kitaplığı oluştur';

  @override
  String get instanceContent => 'İçerik';

  @override
  String get instanceContentSource => 'İçerik kaynağı:';

  @override
  String get emptyInstance => 'Boş örnek';

  @override
  String get markdownFiles => 'Yerel Markdown dosyaları';

  @override
  String get chooseMarkdownFolder => 'Markdown klasörünü seçin';

  @override
  String get errorWritersideInstanceImportSourceRequired =>
      'Markdown dosyalarını içeren bir klasör seçin.';

  @override
  String get instanceAppearance => 'Görünüm';

  @override
  String get instanceColor => 'Simge rengi';

  @override
  String get instanceVersion => 'Sürüm';

  @override
  String instanceVersionInherited(String version) {
    return 'Bu alan boş olduğunda proje sürümü $version\'tir.';
  }

  @override
  String get instanceWebPath => 'Web yolu';

  @override
  String get instanceStatus => 'Durum';

  @override
  String get instanceStatusRelease => 'release';

  @override
  String get instanceStatusEap => 'EAP';

  @override
  String get instanceStatusDeprecated => 'Kullanımdan kaldırıldı';

  @override
  String get allowSearchEngineIndexing =>
      'Arama motoru dizine eklenmesine izin ver';

  @override
  String get allowSearchEngineIndexingDescription =>
      'Harici arama motorlarının bu çıktıyı dizine eklemesine izin verin.';

  @override
  String get offlineArtifact => 'Çevrimdışı artefakt';

  @override
  String get offlineArtifactDescription =>
      'Kaynakları, yerleşik belgelerin bağımsız olmasını sağlayacak şekilde paketleyin.';

  @override
  String get instanceOutputSettings => 'Çıktı ayarları';

  @override
  String get markdownImportSource => 'Markdown kaynağı';

  @override
  String get markdownImportFiles => 'Markdown dosyaları';

  @override
  String get selectNone => 'Hiçbirini seçme';

  @override
  String markdownFilesFound(int count) {
    return '$count Markdown dosyası/dosyaları bulundu';
  }

  @override
  String get noMarkdownFilesFound => 'Bu dizinde Markdown dosyası bulunamadı.';

  @override
  String get copyReferencedMedia => 'Başvurulan medyayı kopyala';

  @override
  String get copyReferencedMediaDescription =>
      'Göreli yolları koruyarak, seçilen dosyaların referans verdiği yerel görüntüleri ve videoları kopyalayın.';

  @override
  String get instanceIdRenameWarningTitle =>
      'Örnek kimliği yeniden adlandırılsın mı?';

  @override
  String instanceIdRenameWarning(String oldId, String newId) {
    return 'BusyMark, .tree dosyasını yeniden adlandıracak ve Writerside proje referanslarını \"$oldId\"ten \"$newId\"e güncelleyecektir. Yayın komut dosyaları değiştirilmez ve ayrı olarak güncellenmeleri gerekir.';
  }

  @override
  String get renameAndUpdateReferences =>
      'Referansları yeniden adlandırın ve güncelleyin';

  @override
  String get tocLibraryDescription =>
      'Bir TOC kütüphanesi yeniden kullanılabilir bölümleri saklar ve kendi çıktısını üretmez.';

  @override
  String get defaultTocLibraryName => 'Paylaşılan İçindekiler';

  @override
  String get instanceColorAutomatic => 'Otomatik';

  @override
  String get instanceColorBlue => 'Mavi';

  @override
  String get instanceColorGreen => 'Yeşil';

  @override
  String get instanceColorOrange => 'Turuncu';

  @override
  String get instanceColorPurple => 'Mor';

  @override
  String get instanceColorRed => 'Kırmızı';

  @override
  String get instanceColorTeal => 'turkuaz';

  @override
  String get instanceColorYellow => 'Sarı';

  @override
  String get errorWritersideInstanceNameRequired => 'Bir örnek adı girin.';

  @override
  String errorWritersideInstanceIdExists(String id) {
    return '\"$id\" kimliğine sahip bir örnek zaten mevcut.';
  }

  @override
  String errorWritersideInstanceTreeExists(String path) {
    return 'Örnek ağacı zaten mevcut: $path';
  }

  @override
  String errorWritersideInstanceImportSourceMissing(String path) {
    return 'Markdown kaynak dizini mevcut değil: $path';
  }

  @override
  String get errorWritersideInstanceImportSelectionRequired =>
      'İçe aktarılacak en az bir Markdown dosyası seçin.';

  @override
  String errorWritersideInstanceImportFileInvalid(String path) {
    return 'Bu, seçilen kaynağın içindeki okunabilir bir Markdown dosyası değil: $path';
  }

  @override
  String errorWritersideInstanceImportTargetExists(String path) {
    return 'İçe aktarma, mevcut bir proje dosyasının üzerine yazılmasına neden olur: $path';
  }

  @override
  String get errorWritersideInstanceFilesChanged =>
      'Örnek dosyalar diskte değiştirildi. Bunları inceleyin ve tekrar deneyin.';

  @override
  String errorWritersideInstanceRollbackFailed(String paths) {
    return 'BusyMark, örnek değişikliğini tamamen geri alamadı. Devam etmeden önce bu dosyaları inceleyin: $paths';
  }

  @override
  String get errorWritersideInstanceLibraryImport =>
      'İçindekiler kitaplığı Markdown konularını içe aktaramaz.';

  @override
  String get errorWritersideInstanceWebPathInvalid =>
      'Web yolu tek bir segmentten oluşmalıdır.';

  @override
  String get errorWritersideInstanceConfigurationInvalid =>
      'Writerside örnek yapılandırması geçersiz. Teşhislerini düzeltip tekrar deneyin.';

  @override
  String get errorWritersideInstanceTemporaryFile =>
      'BusyMark örnek değişikliklerini güvenli bir şekilde gerçekleştiremedi.';

  @override
  String diagnosticWritersideTreeInvalidStatus(String status) {
    return 'Bilinmeyen örnek durumu \"$status\". Release, eap veya deprecated kullanın.';
  }

  @override
  String diagnosticWritersideDuplicateInstanceId(String id) {
    return '“$id” örnek kimliği birden fazla ağaç dosyası tarafından kullanılıyor.';
  }

  @override
  String get diagnosticWritersideBuildProfilesInvalidRoot =>
      'buildprofiles.xml bir <buildprofiles> kök öğesine sahip olmalıdır.';

  @override
  String diagnosticWritersideBuildProfilesInvalidBoolean(
    String name,
    String value,
  ) {
    return '$name değeri “$value” true veya false olmalıdır.';
  }

  @override
  String get diagnosticWritersideBuildProfileMissingInstance =>
      'Bir <build-profile> öğesi bir örnek kimliği belirtmelidir.';

  @override
  String get diagnosticWritersideTreeInvalidInclude =>
      'Bir ağaç <include>, hem from hem de element-id belirtmelidir.';

  @override
  String get diagnosticWritersideTreeMissingSnippetId =>
      'Bir ağaç <snippet>\'i bir kimlik belirtmelidir.';

  @override
  String get diagnosticWritersideTreeInvalidCrossInstanceReference =>
      'Çapraz örnek TOC referansı hem ref hem de in\'i belirtmelidir.';

  @override
  String get diagnosticWritersideTreeConflictingTargets =>
      'Bir TOC öğesi birden fazla konuyu, referansı, bağlantıyı veya yönlendirmeyi hedefleyemez.';

  @override
  String diagnosticWritersideTreeDuplicateElementId(String id) {
    return 'Ağaç öğesi kimliği \"$id\" birden fazla kez bildirildi.';
  }

  @override
  String get diagnosticWritersideInstanceGroupsInvalidRoot =>
      'Örnek grupları dosyasında bir <instance-groups> kök öğesi bulunmalıdır.';

  @override
  String get diagnosticWritersideInstanceGroupInvalid =>
      'Bir örnek grubunun boş olmayan bir kimlik ve örnek listesi belirtmesi gerekir.';

  @override
  String diagnosticWritersideInstanceGroupDuplicateId(String id) {
    return 'Örnek grubu kimliği \"$id\" birden fazla kez bildirildi.';
  }

  @override
  String diagnosticWritersideExternalTreeInclude(
    String source,
    String id,
    String origin,
  ) {
    return 'TOC include “$source#$id”, harici “$origin” modülüne aittir ve bu çalışma alanında genişletilemez.';
  }

  @override
  String diagnosticWritersideTreeIncludeElementMissing(
    String source,
    String id,
  ) {
    return '\"$id\" ağaç öğesi kayıtlı \"$source\" ağacında mevcut değil.';
  }

  @override
  String diagnosticWritersideTreeCircularInclude(String source, String id) {
    return '“$source#$id” içeren ağaç bir döngü oluşturur.';
  }

  @override
  String diagnosticWritersideUnknownInstanceGroup(String group) {
    return 'Örnek koşulu, bilinmeyen \"@$group\" grubuna referans veriyor.';
  }

  @override
  String diagnosticWritersideReferenceInstanceMissing(String instance) {
    return 'Çapraz örnek referansı, bilinmeyen \"$instance\" örneğini hedefliyor.';
  }

  @override
  String diagnosticWritersideReferenceTopicMissing(
    String topic,
    String instance,
  ) {
    return '“$topic” konusu başvurulan “$instance” örneğinde değil.';
  }

  @override
  String get download => 'İndir';

  @override
  String get exportWritersideAsPdf => 'Writerside\'ı PDF olarak dışa aktar';

  @override
  String get writersidePdfContent => 'İçeriği dışa aktar';

  @override
  String get writersidePdfPage => 'Sayfa';

  @override
  String get exportingWritersidePdf => 'Writerside PDF\'si dışa aktarılıyor…';

  @override
  String get ai => 'AI';

  @override
  String get aiLocalOllama => 'Yerel Ollama';

  @override
  String get aiDisabled => 'Devre dışı';

  @override
  String get aiExplicitEditingDescription =>
      'AI düzenleme açıkça kullanıcının isteğiyle başlatılır. BusyMark yalnızca seçili sağlayıcı için gösterilen bağlamı gönderir ve bir öneriyi hiçbiri onaylama olmadan uygulamaz.';

  @override
  String get aiProvider => 'AI sağlayıcısı';

  @override
  String get aiDefaultProvider => 'Varsayılan sağlayıcı';

  @override
  String get aiConfigureProvider => 'Sağlayıcıyı yapılandır';

  @override
  String get aiChooseProvider => 'AI sağlayıcısını seç';

  @override
  String get aiOllamaEndpoint => 'Ollama uç noktası';

  @override
  String get aiOllamaModel => 'Ollama modeli';

  @override
  String get aiTestConnection => 'Bağlantıyı test edin';

  @override
  String get aiTestingConnection => 'Test ediliyor…';

  @override
  String aiConnectionReady(int count) {
    return 'Bağlandı. $count yüklü model bulundu.';
  }

  @override
  String get aiNoModels => 'Hiçbir model seçilmedi.';

  @override
  String get aiConnectionFailed =>
      'BusyMark, AI metin oluşturma işlemini doğrulayamadı.';

  @override
  String get aiConfigureFirst =>
      'Bir AI sağlayıcısını etkinleştirin ve Ayarlar → AI bölümünde bir modeli doğrulayın.';

  @override
  String get aiEditWithAi => 'AI ile düzenle';

  @override
  String get aiRefineWithAi => 'AI ile iyileştir';

  @override
  String get aiInstruction => 'Talimat';

  @override
  String get aiChangeTarget => 'Neler değişebilir?';

  @override
  String get aiSharedContext => 'AI ile paylaşılan bağlam';

  @override
  String get aiTargetSelection => 'Seçilen içerik';

  @override
  String get aiTargetInsertAfterBlock => 'Geçerli bloktan sonra ekle';

  @override
  String get aiTargetCurrentBlock => 'Geçerli blok';

  @override
  String get aiTargetCurrentSection => 'Mevcut bölüm';

  @override
  String get aiTargetCompleteDocument => 'Belgenin tamamı';

  @override
  String get aiContextNone => 'Belge bağlamı yok';

  @override
  String get aiContextSelection => 'Seçilen içerik';

  @override
  String get aiContextCurrentBlock => 'Geçerli blok';

  @override
  String get aiContextCurrentSection => 'Mevcut bölüm';

  @override
  String get aiContextCompleteDocument => 'Belgenin tamamı';

  @override
  String get aiGenerating => 'Teklif oluşturuluyor…';

  @override
  String get aiProposal => 'AI önerisi';

  @override
  String get aiGenerateProposal => 'Teklif oluştur';

  @override
  String aiContextDisclosure(int count) {
    return 'Seçilen sağlayıcı $count karakterlik gösterilen bağlam alacaktır.';
  }

  @override
  String get aiOriginal => 'Orijinal';

  @override
  String get aiSuggested => 'Önerilen';

  @override
  String get aiApplyProposal => 'Teklifi uygula';

  @override
  String aiTokenUsage(int input, int output) {
    return '$input girdi tokenı · $output çıktı tokenı';
  }

  @override
  String get aiStaleProposal =>
      'Bu teklif oluşturulurken belge değiştirildi. Eylemi yeniden çalıştırın.';

  @override
  String get gitAiStagedChangesChanged =>
      'Bu commit mesajı oluşturulurken stage edilmiş değişiklikler değişti. İşlemi yeniden çalıştırın.';

  @override
  String get aiViewContext => 'Gönderilen bağlamı görüntüle';

  @override
  String get aiReviewExactContent => 'Tam içeriği incele';

  @override
  String get aiContentToChange => 'Değiştirilecek içerik';

  @override
  String get aiContentSentToAi => 'AI\'ye gönderilen içerik';

  @override
  String get aiApiKey => 'API anahtarı';

  @override
  String get aiApiKeyStoredHint =>
      'Sistemin kimlik bilgileri deposunda bir anahtar saklanır';

  @override
  String get aiApiKeyEnterHint => 'Sağlayıcının API anahtarını girin';

  @override
  String get aiReplaceApiKey => 'API anahtarını değiştir';

  @override
  String get aiSaveApiKey => 'API anahtarını güvenle kaydet';

  @override
  String get aiRemoveApiKey => 'Kaydedilen API anahtarını kaldır';

  @override
  String get aiCredentialSaved =>
      'API anahtarı sistem kimlik bilgileri deposuna kaydedildi.';

  @override
  String get aiCredentialRemoved => 'Kaydedilen API anahtarı kaldırıldı.';

  @override
  String get aiModelRouting => 'Model yönlendirme';

  @override
  String get aiAutomaticRouting => 'Göreve göre otomatik';

  @override
  String get aiFixedModelRouting => 'Seçilen modeli kullan';

  @override
  String get aiPreferredModel => 'Tercih edilen model';

  @override
  String get aiModel => 'AI modeli';

  @override
  String aiUsageThisMonth(int requests, int input, int output) {
    return '$requests istek · $input girdi tokenı · $output çıktı tokenı';
  }

  @override
  String aiCloudConsentTitle(String provider) {
    return '$provider\'e içerik gönderilsin mi?';
  }

  @override
  String aiCloudConsentEnable(String provider) {
    return '$provider\'i etkinleştir';
  }

  @override
  String get aiCloudConsentMessage =>
      'Yalnızca her AI inceleme iletişim kutusunda gösterilen içerik gönderilir. İstekler durum bilgisine sahip değildir, tekliflerin incelenmesi gerekir ve API anahtarı Linux sisteminin kimlik bilgileri deposunda saklanır.';

  @override
  String aiCloudConsentRequired(String provider) {
    return 'Önce Ayarlar → AI bölümünden $provider ile veri paylaşımını onaylayın.';
  }

  @override
  String aiGenerationVerified(String model, int count) {
    return 'Oluşturma $model ile doğrulandı. $count uyumlu model kullanılabilir.';
  }

  @override
  String get aiColdStartObserved =>
      'Yerel model için soğuk başlangıç gözlemlendi.';

  @override
  String get aiNoCompatibleModels =>
      'Uyumlu bir metin oluşturma modeli mevcut değil.';

  @override
  String get aiEnableProvider => 'Önce bir AI sağlayıcısını etkinleştirin.';

  @override
  String get aiDraftCommitMessage => 'Taslak commit mesajı';

  @override
  String get aiDrafting => 'Taslak hazırlanıyor…';

  @override
  String get aiDraftWithAi => 'AI ile taslak oluştur';

  @override
  String get generateOrUpdateMarkdownToc =>
      'İçindekiler tablosu oluştur/güncelle';

  @override
  String get markdownTocTitle => 'İçindekiler';

  @override
  String markdownTocUpdated(int count) {
    return 'İçindekiler tablosu $count girişle güncellendi.';
  }

  @override
  String get markdownTocNoHeadings =>
      'İçindekiler tablosu oluşturmadan önce en az bir bölüm başlığı ekleyin.';

  @override
  String get markdownTocMalformedMarkers =>
      'BusyMark içindekiler tablosu işaretçileri eksik, yinelenmiş veya hatalı.';

  @override
  String diagnosticMarkdownHeadingSkippedLevel(int level, int previousLevel) {
    return '$level başlık seviyesi $previousLevel seviyesini takip eder; bölümün iç içe geçmesini inceleyin.';
  }

  @override
  String get diagnosticMarkdownLinkEmptyText =>
      'Bağlantı metni boş; amacını açıklayan erişilebilir bir ad sağlayın.';

  @override
  String diagnosticMarkdownLinkReviewText(String text) {
    return '“$text” bağlantı metninin bağlamda amacını açıklayıp açıklamadığını inceleyin.';
  }

  @override
  String get diagnosticMarkdownTableEmptyHeader =>
      'Tablo başlığı hücreleri sütunlarını tanımlamalıdır; her boş başlığı tamamlayın.';

  @override
  String get mathRenderFailed => 'Matematiksel ifade işlenemedi.';

  @override
  String get inlineMath => 'Satır içi matematik';

  @override
  String get displayMath => 'Blok matematik';
}
