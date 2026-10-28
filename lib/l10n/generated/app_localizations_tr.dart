// ignore_for_file: text_direction_code_point_in_literal, text_direction_code_point_in_comment

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get notesNewFromRetainedText => 'Saklanan metinden yeni not';

  @override
  String get notesAccountThrottled =>
      'Nextcloud beklemenizi istedi. Yeniden oturum açmadan önce bekleyin.';

  @override
  String get notesSettingsRefreshing =>
      'Onaylanan ayar güncellemesinden sonra Notes yenileniyor';

  @override
  String get notesExportOperationFailed =>
      'Dışa aktarma yayımlanmadan başarısız oldu. Kaynağı ve hedefi denetleyip yeniden deneyin.';

  @override
  String get notesRecoveryCreatedNotOpened =>
      'Kurtarılan not kaydedildi ancak açılamadı. Bekleyen düzenleyici veya özellik değişikliklerini çözün ve bu mevcut notu açın.';

  @override
  String get notesSettingsPendingNotes =>
      'Bekleyen notlar, çakışmalar veya belirsiz oluşturmalar bu değişikliği engelliyor. Notes içinde eşitleyin ya da inceleyin, ardından korunan ayar taslağını yeniden kaydedin.';

  @override
  String get notesSettingsPendingAttachments =>
      'Bekleyen ek işlemleri değişikliği engelliyor. Notes içinde ekleri inceleyip korunan ayar taslağını yeniden kaydedin.';

  @override
  String get notesAccountServerAddress =>
      'Nextcloud’un kurallı HTTPS adresini kullanıp yeniden oturum açın. Adres veya yönlendirme doğrulanamadı.';

  @override
  String get notesAccountUnsupported =>
      'Notes kullanılamıyor veya API desteklenmiyor. Ana API sürümü 1, alt sürümü en az 4 olan Nextcloud Notes’u etkinleştirin.';

  @override
  String get notesAccountAuthorizeAgain =>
      'Nextcloud kimlik bilgilerini reddetti. Hesabı yeniden yetkilendirin veya bağlayın.';

  @override
  String get notesAccountCheckForbidden =>
      'Nextcloud, Notes yetenek denetimini engelledi. Yöneticiden izin isteyip yeniden deneyin.';

  @override
  String get notesAccountMalformed =>
      'Nextcloud yanıtı doğrulanamadı. Sunucu kurulumunu denetleyip yeniden oturum açın.';

  @override
  String get notesAccountTimedOut =>
      'Oturum açma zaman aşımına uğradı. Yeniden başlatıp tarayıcıda yetkilendirmeyi tamamlayın.';

  @override
  String get notesAccountBrowserUnavailable =>
      'Sistem tarayıcısı açılamadı. Varsayılan tarayıcıyı denetleyip yeniden oturum açın.';

  @override
  String get notesAccountNetwork =>
      'Nextcloud’a ulaşılamadı. Bağlantıyı ve sunucuyu denetleyip yeniden oturum açın.';

  @override
  String get notesAccountRejected =>
      'Nextcloud yetenek isteğini reddetti. Erişimi yöneticiyle denetleyip yeniden deneyin.';

  @override
  String get notesAccountFailed =>
      'Hesap kurulumu tamamlanamadı. Yeniden oturum açmayı deneyin.';

  @override
  String get notesTransferSourceChanged =>
      'Kaynak incelemeden sonra değişti. Yeniden denemeden önce güncel dosyayı inceleyin veya yeni bir anlık görüntü alın.';

  @override
  String get notesTransferUnreadable =>
      'Kaynak okunamadı. Dosya veya klasör erişimini denetleyip yeniden inceleyin.';

  @override
  String get notesTransferInvalidSnapshot =>
      'Anlık görüntü geçersiz veya desteklenmiyor. Geçerli bir BusyMark Notes görüntüsü veya Markdown kaynağı seçin.';

  @override
  String get notesTransferMediaLimit =>
      'Medya içe aktarma boyut sınırını aşıyor. İlgili öğenin medyasını küçültüp yeniden inceleyin.';

  @override
  String get notesTransferUnsafeSource =>
      'Kaynak güvensiz bir yol içeriyor. Kaynak klasörü içindeki dosyaları seçip yeniden inceleyin.';

  @override
  String get notesTransferDestination =>
      'Dışa aktarma yazılamadı. Hedef erişimini ve boş alanı denetleyip yeniden deneyin.';

  @override
  String get notesTransferOperationFailed =>
      'Aktarım tamamlanamadı. İlgili öğeleri inceleyip yeniden deneyin. Önceden içe aktarılan öğeler kayıtlı kalır.';

  @override
  String get notesExportPublishedWithOmissions =>
      'Eksikleri olan dışa aktarma kullanılabilir';

  @override
  String get notesBatchUnchanged => 'İstenen değerler zaten ayarlanmıştı.';

  @override
  String get notesBatchReadOnly =>
      'Bu not salt okunurdur. Korunan özellikler değiştirilemez; Favori yine değiştirilebilir.';

  @override
  String get notesBatchReviewChanged =>
      'Bu not incelemeden sonra değişti. İşlemi yeniden uygulamadan önce güncel durumunu inceleyin.';

  @override
  String get notesBatchMissing =>
      'Bu not artık kullanılamıyor. Listeyi yenileyip hedefleri yeniden inceleyin.';

  @override
  String get notesBatchStorage =>
      'Yerel kayıt başarısız oldu. Depolamayı denetleyip bu öğeyi yeniden deneyin; başarılı öğeler kayıtlı kalır.';

  @override
  String get notesRemoteReviewChanged =>
      'Sunucu notu değişti. Birleştirme taslağınız korunuyor. Güncel karşılaştırmayı inceleyip çözümü yeniden seçin.';

  @override
  String get notesReviewRemote => 'Güncel sunucu sürümünü inceledim';

  @override
  String get wsModuleCapsNotPublished => 'Modülün harf biçimi yayımlanmaz.';

  @override
  String get wsTitleOverridesAction => 'Örnek ve içindekiler başlıkları…';

  @override
  String get wsHeadingNotPublished => 'Bu oluşturucu tarafından yayımlanmaz.';

  @override
  String get wsMarkdownInstanceTitleLimitation =>
      'Sabitlenmiş derleyici Markdown konularında örnek başlıklarını yayımlamaz. Mevcut işaretleme korunur; Kaynakta inceleyin.';

  @override
  String get wsTopicIdentity => 'Konu kimliği';

  @override
  String get wsElementAnchor => 'Öğe çapası';

  @override
  String get wsHeadingText => 'Başlık metni';

  @override
  String get wsDefaultTitle => 'Varsayılan başlık';

  @override
  String get wsTopicNavigation => 'Konu gezinmesi';

  @override
  String get wsHeadingOptions => 'Başlık öznitelikleri';

  @override
  String get wsDocumentOptions => 'Belge ayarları';

  @override
  String get wsSettingsPresent => 'Yazılmış ayarlar mevcut';

  @override
  String get wsTitleOverrideExplanation =>
      'Yayımlanan başlığı geçersiz kılar; başlık metni değişmez.';

  @override
  String get wsIgnoreVariables => 'Değişkenleri düz metin olarak işle';

  @override
  String get wsIgnoreVariablesExplanation =>
      'Etkinleştirildiğinde değişken benzeri metin değiştirilmez.';

  @override
  String get wsInstanceSelection => 'Yardım örnekleri';

  @override
  String get wsInstanceExplanation =>
      'Yardım çıktılarını adlar, gruplar, listeler, dışlamalar veya ifadelerle seçin.';

  @override
  String get wsFilterExplanation =>
      'Yeniden kullanılan içeriği ölçütlerle süzer; yardım örneği seçmez.';

  @override
  String get wsContextHelp => 'Bağlam yardımı kimliği';

  @override
  String get wsCapitalization => 'Büyük/küçük harf';

  @override
  String get wsLibraryTopic => 'Kitaplık konusu';

  @override
  String get wsLastModified => 'Son değiştirilme';

  @override
  String get wsMissingTopicHeading => 'Konu H1 başlığı yok. Kaynakta ekleyin.';

  @override
  String get wsMultipleTopicHeadings =>
      'İlk H1 konu başlığını belirler. Sonraki H1’ler ayrı başlıklardır.';

  @override
  String get wsTopicIdentityMismatch =>
      'Kök id, dosya adından türetilen konu kimliğinden farklı. Konu dosyasını yeniden adlandırın veya kaynağı inceleyin.';

  @override
  String get wsUnsupportedProperties =>
      'Desteklenmeyen öznitelikler korunur. Kaynakta inceleyin.';

  @override
  String get wsGeneratedAnchor =>
      'Oluşturulmuş çapa; bir değer geçersiz kılma oluşturur.';

  @override
  String get wsHeadingBuilderLimitation =>
      'Sabitlenmiş derleyici H1 özniteliklerini yayımlamaz. XML köküne değil başlığa aittirler.';

  @override
  String get closeOtherTabs => 'Diğer sekmeleri kapat';

  @override
  String get tocTopicFromTemplate => 'Şablondan Konu...';

  @override
  String get tocSaveAsTemplate => 'Şablon Olarak Kaydet';

  @override
  String get tocTemplateDialog => 'Şablondan Konu Oluştur';

  @override
  String get tocTemplatesEditor => 'Dosya ve Kod Şablonları';

  @override
  String get tocEditTemplates => 'Şablonları düzenle...';

  @override
  String get tocCreateCustomTemplate => 'Özel şablon oluştur...';

  @override
  String get tocTemplateCreated => 'Şablon oluşturuldu';

  @override
  String get tocTemplateDefault => 'Varsayılan';

  @override
  String get tocTemplateCustom => 'Özel';

  @override
  String get tocTemplateFilename => 'Dosya adı:';

  @override
  String get tocTemplateMarkdown => 'Markdown (.md)';

  @override
  String get tocTemplateXml => 'XML (.topic)';

  @override
  String get tocTemplatesInternal => 'Dahili';

  @override
  String get tocTemplateUnnamed => 'Adsız';

  @override
  String get tocTemplateNew => 'Yeni şablon...';

  @override
  String get tocTemplateName => 'Ad:';

  @override
  String get tocTemplateExtension => 'Uzantı:';

  @override
  String get tocTemplateLoadError =>
      'Şablonlar yüklenemedi. Mevcut şablonlar değiştirilmedi.';

  @override
  String get tocTemplateSaveError =>
      'Şablonlar kaydedilemedi. Düzenlemeleriniz burada duruyor.';

  @override
  String get tocTemplateConflict =>
      'Şablonlar başka bir pencerede değiştirildi. İptal edip düzenleyiciyi yeniden açın.';

  @override
  String get tocTemplateDuplicateName =>
      'Bu ada ve uzantıya sahip bir şablon zaten var.';

  @override
  String get tocTemplateFormat => 'Biçim:';

  @override
  String get tocTemplateReset => 'Sıfırla';

  @override
  String get tocTemplateRetry => 'Yeniden dene';

  @override
  String tocRemoveElementsDialog(int count) {
    return '$count İçindekiler Öğesini Kaldır';
  }

  @override
  String get tocRemoveElementsRetainFiles =>
      'Bu içindekiler öğeleriyle ilişkili kaynak dosyalar silinmeyecek.';

  @override
  String get tocOk => 'Tamam';

  @override
  String get tocSelectExistingTopic => 'Geçerli örneğe eklenecek konuyu seçin';

  @override
  String get tocGroupName => 'Grup adı';

  @override
  String get tocMoveLineUp => 'Satırı yukarı taşı';

  @override
  String get tocMoveLineDown => 'Satırı aşağı taşı';

  @override
  String get tocEmptyMdTopic => 'Boş MD konusu';

  @override
  String get tocEmptyXmlTopic => 'Boş XML konusu';

  @override
  String get tocCopySpecial => 'Özel kopyala';

  @override
  String tocCopyFileName(String name) {
    return 'Konu dosyası adı \'$name\'';
  }

  @override
  String get tocCopyFilePath => 'Konu dosyası yolu';

  @override
  String tocCopyTopicTitle(String title) {
    return 'Konu başlığı \'$title\'';
  }

  @override
  String tocCopyElementId(String id) {
    return 'İçindekiler öğesi kimliği \'$id\'';
  }

  @override
  String get tocCopyFileNameUnavailable => 'Konu dosyası adı';

  @override
  String get tocCopyTopicTitleUnavailable => 'Konu başlığı';

  @override
  String get tocCopyElementIdUnavailable => 'İçindekiler öğesi kimliği';

  @override
  String get tocEditTitleAction => 'Başlığı düzenle...';

  @override
  String get tocEditTitleDialog => 'Başlığı düzenle';

  @override
  String get tocRemoveElementAction => 'İçindekiler öğesini kaldır...';

  @override
  String get tocSetHomePage => 'Ana sayfa olarak ayarla';

  @override
  String tocGoToElement(String fileName) {
    return '\'$fileName\' içindeki içindekiler öğesine git';
  }

  @override
  String get tocSynchronize => 'İçindekiler ve düzenleyiciyi eşitle';

  @override
  String get tocEmptyGroupAction => 'Boş grup';

  @override
  String get tocNewEmptyGroup => 'Yeni boş grup';

  @override
  String get tocGroupAction => 'Grupla';

  @override
  String get tocNewGroup => 'Yeni grup';

  @override
  String get tocSortChildren => 'Alt konuları alfabetik sırala';

  @override
  String get tocLinkTopicFiles => 'Konu dosyalarını içindekilere bağla...';

  @override
  String get addLocalMarkdownFiles => 'Yerel Markdown Dosyaları Ekle';

  @override
  String get tocTitleField => 'İçindekiler başlığı:';

  @override
  String get tocTopicTitleField => 'Konu başlığı:';

  @override
  String get tocAdvancedSettings => 'Gelişmiş ayarlar';

  @override
  String tocInstanceTitleField(String instanceId) {
    return '\'$instanceId\' için başlık:';
  }

  @override
  String get tocOnlyTitleField => 'Yalnızca içindekiler başlığı:';

  @override
  String get tocInstanceTitleExplanation =>
      'Yalnızca geçerli örnek için kullanılır. Varsayılan olarak konu başlığından devralınır.';

  @override
  String get tocOnlyTitleExplanation =>
      'Yalnızca içindekilerde kullanılır. Varsayılan olarak konu başlığından veya ayarlanmışsa örneğe özgü başlıktan devralınır. Başlıklar hakkında açıklama:';

  @override
  String get tocTitleDocumentationLink => 'burada';

  @override
  String get tocFindUsages => 'Bul';

  @override
  String get tocRefactorMenu => 'Yeniden düzenle';

  @override
  String get tocSafeDelete => 'Güvenli sil';

  @override
  String get tocDuplicate => 'Çoğalt';

  @override
  String get tocDuplicateFilename => 'Konu dosyası adı:';

  @override
  String get tocDuplicateDialog => 'Konuyu çoğalt';

  @override
  String get pdfTitlePage => 'Başlık sayfası';

  @override
  String get pdfIncludeTitlePage => 'Başlık sayfası ekle';

  @override
  String get pdfTitlePageNote =>
      'Bu sayfada üstbilgi, altbilgi veya görünür sayfa numarası bulunmaz.';

  @override
  String get pdfTitlePageTitle => 'Başlık';

  @override
  String get pdfTitlePageSubtitle => 'Alt başlık';

  @override
  String get pdfTitlePageAuthor => 'Yazar';

  @override
  String get pdfTitlePageOrganization => 'Kuruluş';

  @override
  String get pdfTitlePageVersion => 'Sürüm';

  @override
  String get pdfTitlePageDate => 'Tarih';

  @override
  String get pdfTitlePageTitleRequired =>
      'Başlık sayfası için bir başlık girin.';

  @override
  String get pdfTocSectionNote =>
      'Ayrı bir sayfada başlar ve birden fazla sayfa sürebilir.';

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
  String get copyPlainText => 'Düz metin olarak kopyala';

  @override
  String get clipboardCopyFailed => 'Seçili içerik panoya kopyalanamadı.';

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
      'Uygulama klavye kısayollarını özelleştir';

  @override
  String get shortcutSyntaxReferenceDescription => 'Sözdizimi başvurusunu aç';

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
  String get wordWrapDescription =>
      'Uzun satırları yatay kaydırmak yerine düzenleyici genişliğine sığacak şekilde kaydırın.';

  @override
  String get editorFontSize => 'Düzenleyici yazı tipi boyutu';

  @override
  String get validateOnEdit => 'Düzenlemede doğrula';

  @override
  String get clearRecentWorkspaces => 'Son geçmişi temizle';

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
  String get settingsEditingButtonsSectionTitle => 'Düzenleme düğmeleri';

  @override
  String get spellingDictionaries => 'Yazım sözlükleri';

  @override
  String get spellingDictionariesDescription =>
      'Yazım sözlüklerini kurun ve yönetin';

  @override
  String get settingsDictionariesSectionTitle => 'Sözlükler';

  @override
  String get availableSpellingDictionaries => 'Kullanılabilir sözlükler';

  @override
  String get customSpellingDictionaries => 'Özel sözlükler';

  @override
  String get spellingDictionaryProblems => 'Sözlük sorunları';

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
  String get insertBlankLine => 'Boş satır ekle';

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
  String get newSiblingTopic => 'Yeni konu';

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
  String get removeTocElements => 'TOC öğelerini kaldır';

  @override
  String get reviewUsages => 'Kullanımları incele';

  @override
  String get deleteTopicFile => 'Konu dosyasını sil';

  @override
  String get removeAction => 'Kaldır';

  @override
  String topicRemovalSummary(String topic) {
    return '“$topic” içindekiler öğesi kaldırılsın mı? İçindekiler ile ilişkili kaynak dosya silinmeyecek.';
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
  String get topicIsHomePageRemovalWarning =>
      'Bu konu bu örneğin ana sayfasıdır. İçindekilerden kaldırmadan önce başka bir ana sayfa seçin.';

  @override
  String get newHomePage => 'Yeni ana sayfa';

  @override
  String get chooseHomePage => 'Ana sayfa seçin';

  @override
  String get noHomePageReplacement =>
      'Ana sayfasını kaldırmadan önce bu örneğe başka bir uygun konu ekleyin veya bağlayın.';

  @override
  String get topicIsStartPageRemovalWarning =>
      'Bu konu bir örneğin ana sayfasıdır. Kaynak dosyasını silmeden önce başka bir ana sayfa atayın.';

  @override
  String topicUsagesCount(int count) {
    return '$count kullanım bulundu.';
  }

  @override
  String get noBreakingTopicUsages => 'Bozulacak referans bulunamadı.';

  @override
  String get topicUsagesFound =>
      'BusyMark bu konuya yönelik aşağıdaki referansları buldu.';

  @override
  String get topicUsageTocElements => 'İçindekiler öğeleri';

  @override
  String get topicUsageStartPages => 'Ana sayfalar';

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
  String get preview => 'Önizleme';

  @override
  String get topicRenamePreviewTitle => 'Yeniden adlandırma önizlemesi';

  @override
  String topicRenamePathChange(String oldPath, String newPath) {
    return 'Yol: $oldPath → $newPath';
  }

  @override
  String topicRenameIdChange(String oldId, String newId) {
    return 'Konu kimliği: $oldId → $newId';
  }

  @override
  String topicRenameUrlChange(String instance, String oldName, String newName) {
    return 'Örnek $instance: $oldName → $newName';
  }

  @override
  String get topicRenameAffectedFiles => 'Etkilenen dosyalar';

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
  String get workspaceSearchIncomplete =>
      'Sonuçların yalnızca bir kısmı gösteriliyor. Daha fazlasını gösterin veya aramayı daraltın.';

  @override
  String get workspaceSearchShowMore => 'Daha fazla sonuç göster';

  @override
  String get workspaceSearchSkippedFiles =>
      'Arama eksik. Bu dosyalar 1 MiB boyutunu aşıyor veya okunamadı:';

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
  String workspaceErrorRecentWorkspaceUpdateFailed(String error) {
    return 'Son öğeler güncellenemedi: $error.';
  }

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
    return 'Ana sayfa $topic silinemez. Önce başka bir ana sayfa seçin.';
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
  String errorWritersideTopicRenameIncompleteProjectIndex(
    String module,
    String count,
    String paths,
  ) {
    return 'Yeniden adlandırma, $module modülündeki $count konu dosyası ayrıştırılmadığından tüm proje başvurularını güvenle güncelleyemiyor: $paths';
  }

  @override
  String get errorWritersideTopicRenameProjectBuffersDirty =>
      'Writerside proje dosyalarında kaydedilmemiş değişiklikler var. Bunları çözün ve yeni bir yeniden adlandırma önizlemesi hazırlayın.';

  @override
  String get errorWritersideTopicRenameProjectInventoryChanged =>
      'Writerside projesinin modül kümesi değişti. Yeniden düzenlemeden önce yeni bir yeniden adlandırma önizlemesi hazırlayın.';

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
  String diagnosticWritersideWebFileNameInvalid(
    String instanceId,
    String webFileName,
    String topic,
  ) {
    return '\"$instanceId\" örneği, \"$topic\" konusu için geçersiz \"$webFileName\" web dosyası adını yayımlıyor.';
  }

  @override
  String diagnosticWritersideWebFileNameCollision(
    String instanceId,
    String webFileName,
    String firstTopic,
    String secondTopic,
  ) {
    return '\"$instanceId\" örneği hem \"$firstTopic\" hem de \"$secondTopic\" konusunu \"$webFileName\" olarak yayımlıyor.';
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
  String get syntaxReference => 'Sözdizimi Başvurusu';

  @override
  String get syntaxReferenceMarkdownBlocks => 'Markdown blokları';

  @override
  String get syntaxReferenceMarkdownBlocksDescription =>
      'Markdown kaynağında ve önizlemesinde desteklenen blok yapıları.';

  @override
  String get syntaxReferenceInlineFormatting => 'Satır içi biçimlendirme';

  @override
  String get syntaxReferenceInlineFormattingDescription =>
      'Paragrafların, liste öğelerinin ve tablo hücrelerinin içinde görünebilecek biçimlendirme.';

  @override
  String get syntaxReferenceRawHtmlBlocks => 'Ham HTML Blokları';

  @override
  String get syntaxReferenceRawHtmlBlocksDescription =>
      'BusyMark önizleme widget\'ları aracılığıyla oluşturulan güvenli blok düzeyinde HTML etiketleri.';

  @override
  String get syntaxReferenceRawHtmlInline => 'Ham HTML Satır İçi Etiketleri';

  @override
  String get syntaxReferenceRawHtmlInlineDescription =>
      'Gerçek etiketler gösterilmeden oluşturulan güvenli satır içi HTML etiketleri.';

  @override
  String get syntaxReferenceHeadings => 'Başlıklar';

  @override
  String get syntaxReferenceParagraphs => 'Paragraflar';

  @override
  String get syntaxReferenceLists => 'Listeler';

  @override
  String get syntaxReferenceHtmlContainers => 'Konteynerler';

  @override
  String get syntaxReferenceHtmlTextBlocks => 'Metin blokları';

  @override
  String get syntaxReferenceHtmlFigures => 'Şekiller ve görseller';

  @override
  String get syntaxReferenceHtmlPreformatted => 'Önceden biçimlendirilmiş kod';

  @override
  String get syntaxReferenceHtmlDisclosure => 'Açıklama blokları';

  @override
  String get syntaxReferenceHtmlDescriptionLists => 'Açıklama listeleri';

  @override
  String get syntaxReferenceHtmlFormattingTags => 'Etiketleri biçimlendirme';

  @override
  String get syntaxReferenceHtmlInlineCodeTags => 'Satır içi kod etiketleri';

  @override
  String get syntaxReferenceHtmlNeutralInlineTags =>
      'Anlamsal metin etiketleri';

  @override
  String get syntaxReferenceSanitizedPreviewDescription =>
      'İzin verilen HTML, tarayıcıda oluşturulmaz, BusyMark önizleme bloklarına dönüştürülür.';

  @override
  String get syntaxReferenceSourcePreservedDescription =>
      'Düzenlenmemiş ham HTML, tam olarak kaynak metin olarak kaydedilir.';

  @override
  String get syntaxReferenceMarkdownInsideHtmlDescription =>
      'Ham HTML içindeki Markdown işaretleri düz metin olarak görüntülenir.';

  @override
  String get syntaxReferenceBlockedContentDescription =>
      'Komut dosyaları, stiller, çerçeveler, formlar, SVG, MathML, olaylar ve güvenli olmayan özellikler engellenir.';

  @override
  String get syntaxReferenceSafeUrlsDescription =>
      'Bağlantılar http, https, mailto, tel, göreli ve parça URL\'lerine izin verir; güvenli olmayan şemalar engellenir.';

  @override
  String get syntaxReferenceCategory => 'Kategori';

  @override
  String get syntaxReferenceCategoryHtml => 'HTML';

  @override
  String get syntaxReferenceCategoryDiagramsAndApi => 'Diyagramlar ve API';

  @override
  String get syntaxReferenceCategoryMathematics => 'Matematik';

  @override
  String get syntaxReferenceExample => 'Örnek';

  @override
  String get syntaxReferenceIdentifiers => 'Tanımlayıcılar ve diğer adlar';

  @override
  String get syntaxReferenceScope => 'Kapsam';

  @override
  String get syntaxReferenceLimitation => 'BusyMark sınırlaması';

  @override
  String get syntaxReferenceOfficialDocumentation => 'Resmî belgeler';

  @override
  String get syntaxReferenceScopeWritersideMarkdown =>
      'Yalnızca Writerside Markdown';

  @override
  String get syntaxReferenceScopeWritersideMarkdownAndXml =>
      'Yalnızca Writerside Markdown ve Writerside XML';

  @override
  String get syntaxReferenceMarkdownDescription =>
      'BusyMark\'ın yazabildiği ve önizleyebildiği temel Markdown biçimleri.';

  @override
  String get syntaxReferenceParagraphExample => 'Bir metin paragrafı.';

  @override
  String get syntaxReferenceTableLimitation =>
      'Tablolar GitHub Flavored Markdown dikey çizgi sözdizimini kullanır.';

  @override
  String get syntaxReferenceHardBreakIdentifiers =>
      'satır sonunda iki boşluk, \\, <br>';

  @override
  String get syntaxReferenceHtmlDescription =>
      'BusyMark, Markdown kaynağında sınırlı ve güvenli bir ham HTML alt kümesini kabul eder.';

  @override
  String get syntaxReferenceDiagramsDescription =>
      'Çitle çevrili Mermaid, PlantUML, D2 ve OpenAPI blokları Markdown kaynağında çalışır. Çit tanımlayıcıları büyük/küçük harfe duyarlı değildir ve BusyMark özgün yazımı korur.';

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
      'Çitle çevrili YAML veya JSON içeriği kullanın. BusyMark rastgele bir tam YAML ya da JSON belgesini OpenAPI başvurusu olarak değerlendirmez.';

  @override
  String get syntaxReferenceSemanticDiagramBlocks =>
      'Anlamsal diyagram kod blokları';

  @override
  String get syntaxReferenceSemanticDiagramLimitation =>
      'Anlamsal code-block ve src biçimleri Mermaid, PlantUML ve D2\'yi destekler; OpenAPI\'yi desteklemez ve yalnızca Writerside projelerinde çalışır.';

  @override
  String get syntaxReferenceReferencedDiagramSource =>
      'Başvurulan diyagram kaynağı';

  @override
  String get syntaxReferenceReferencedDiagramLimitation =>
      'Yollar göreli olmalı ve açılan Writerside projesinin içinde kalmalıdır; çit ve src biçimi yalnızca Writerside Markdown içindir.';

  @override
  String get syntaxReferenceMathematicsDescription =>
      'BusyMark TeX ifadelerini destekler; tam TeX veya LaTeX belgelerini desteklemez.';

  @override
  String get syntaxReferenceInlineMath => 'Satır içi matematik';

  @override
  String get syntaxReferenceGithubMath =>
      'Dolar ve ters tırnaklı GitHub matematiği';

  @override
  String get syntaxReferenceDisplayMath => 'Blok matematiği';

  @override
  String get syntaxReferenceMathFence => 'math çiti';

  @override
  String get syntaxReferenceTexFence => 'tex çiti';

  @override
  String get syntaxReferenceMathDelimitersLimitation =>
      'BusyMark \\(...\\) veya \\[...\\] dizilerini Markdown matematik sınırlayıcıları olarak tanımaz.';

  @override
  String get syntaxReferenceTexFenceLimitation =>
      'Writerside modu dışında tex çiti normal bir kod bloğu olarak kalır.';

  @override
  String get syntaxReferenceWritersideMathElement => 'Writerside math öğesi';

  @override
  String get syntaxReferenceWritersideMathElementLimitation =>
      'math öğesi anlamsal Writerside sözdizimidir; izin verilen ham HTML MathML değildir.';

  @override
  String get syntaxReferenceSemanticTexBlock => 'Anlamsal TeX kod bloğu';

  @override
  String get syntaxReferenceWritersideDescription =>
      'Bu odaklı uzantılar yalnızca açılmış Writerside projelerinde yorumlanır.';

  @override
  String get syntaxReferenceAdmonitionBlockquote => 'Uyarı blok alıntısı';

  @override
  String get syntaxReferenceAdmonitionLimitation =>
      'Düz blok alıntısı Writerside Markdown\'da ipucudur; normal Markdown\'da sıradan alıntı olarak kalır.';

  @override
  String get syntaxReferenceSemanticAdmonitions => 'Anlamsal uyarılar';

  @override
  String get syntaxReferenceSemanticMarkupLimitation =>
      'Normal Markdown bu anlamsal Writerside öğelerini yorumlamaz.';

  @override
  String get syntaxReferenceCollapsibleHeading => 'Daraltılabilir başlık';

  @override
  String get syntaxReferenceCollapsibleCode => 'Daraltılabilir kod çiti';

  @override
  String get syntaxReferenceSemanticCollapsibles =>
      'Anlamsal daraltılabilir içerik';

  @override
  String get syntaxReferenceSemanticCollapsiblesLimitation =>
      'BusyMark daraltılabilir chapter, procedure, code-block ve tanım listesi biçimlerini destekler; Writerside kataloğunun tamamını desteklemez.';

  @override
  String get syntaxReferenceSemanticCodeBlocks =>
      'Matematik ve diyagramlar için anlamsal kod blokları';

  @override
  String get syntaxReferenceVideo => 'Writerside videosu';

  @override
  String get syntaxReferenceVideoLimitation =>
      'Yerel video yerel bir preview-src görseli kullanır; barındırılan kaynaklar desteklenen HTTPS YouTube veya Vimeo adresleri olmalıdır.';

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
  String get exportFormat => 'Çıktı biçimi';

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
  String get openTocFile => 'İçindekiler dosyasını aç';

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

  @override
  String get goToDeclaration => 'Bildirime git';

  @override
  String get findUsages => 'Kullanımları bul';

  @override
  String get cannotRenameSymbol =>
      'Simge güvenle yeniden adlandırılamıyor. Yeniden denemeden önce adı kontrol edin ve başvuruyu yenileyin.';

  @override
  String get renameTopicFileInstead =>
      'Konu kimlikleri dosya adlarından gelir. İçindekiler tablosunda veya Dosyalar kenar çubuğunda Konu Dosyasını Yeniden Adlandır\'ı kullanın.';

  @override
  String get keyboardLayout => 'Klavye düzeni';

  @override
  String get diagnosticWritersideUnsupported =>
      'Desteklenmeyen veya hatalı içerik kaynak olarak gösterilir.';

  @override
  String diagnosticWritersideSource(String reference, String reason) {
    return '“$reference” kaynağı çözümlenemiyor: $reason';
  }

  @override
  String diagnosticWritersideLink(String destination) {
    return 'Bağlantı hedefi bu örnekte kullanılamıyor: $destination';
  }

  @override
  String diagnosticWritersideSchema(
    String element,
    String attribute,
    String reason,
  ) {
    return 'Geçersiz Writerside işaretlemesi: $element, $attribute. $reason';
  }

  @override
  String get diagnosticWritersideLlmsTxt =>
      '<llms-txt>true</llms-txt> veya <llms-txt>false</llms-txt> kullanın; single-file artık desteklenmiyor.';

  @override
  String diagnosticWritersideReference(String kind, String reference) {
    return '$kind çözümlenemiyor: $reference';
  }

  @override
  String get exportAsHtml => 'HTML olarak dışa aktar…';

  @override
  String get fileTypeHtml => 'HTML belgesi';

  @override
  String get exportingHtml => 'HTML dışa aktarılıyor…';

  @override
  String get htmlExported => 'HTML dışa aktarımı tamamlandı';

  @override
  String get htmlExportFailed => 'HTML dışa aktarılamadı';

  @override
  String get htmlKeepAssetsTogether =>
      'Bu dışa aktarımı kopyalarken HTML dosyasını ve ilgili kaynak klasörünü bir arada tutun.';

  @override
  String get htmlInstanceDescription =>
      'Bir örneği bağlantılı çevrimdışı sayfalar olarak dışa aktarın. Ayrı bir çıktı klasörü için ad seçin.';

  @override
  String get htmlInstance => 'Örnek';

  @override
  String get htmlOwnedDirectoryOnly =>
      'Yalnızca BusyMark HTML dışa aktarımıyla oluşturulan bir klasör değiştirilebilir. Değiştirilmiş veya ilgisiz dosyalar korunur.';

  @override
  String get showInFolder => 'Klasörde Göster';

  @override
  String sortTableColumn(String column) {
    return '$column sırala';
  }

  @override
  String get exportReset => 'Varsayılanlara sıfırla';

  @override
  String get exportToc => 'İçindekiler tablosunu ekle';

  @override
  String get exportTocDepth => 'İçindekiler derinliği';

  @override
  String get exportNumberHeadings => 'Başlıkları numaralandır';

  @override
  String get exportLegal => 'US Legal';

  @override
  String get exportCustom => 'Özel';

  @override
  String get exportPageWidth => 'Sayfa genişliği (mm)';

  @override
  String get exportPageHeight => 'Sayfa yüksekliği (mm)';

  @override
  String get exportMarginTop => 'Üst kenar boşluğu (mm)';

  @override
  String get exportMarginRight => 'Sağ kenar boşluğu (mm)';

  @override
  String get exportMarginBottom => 'Alt kenar boşluğu (mm)';

  @override
  String get exportMarginLeft => 'Sol kenar boşluğu (mm)';

  @override
  String get exportTypography => 'Tipografi';

  @override
  String get exportSans => 'Serifsiz';

  @override
  String get exportSerif => 'Serifli';

  @override
  String get exportBodySize => 'Gövde yazı tipi boyutu';

  @override
  String get exportCodeSize => 'Kod yazı tipi boyutu';

  @override
  String get exportRunningText => 'Üst bilgi ve alt bilgi';

  @override
  String get exportHeader => 'Üst bilgi';

  @override
  String get exportFooter => 'Alt bilgi';

  @override
  String get exportNone => 'Yok';

  @override
  String get exportDocumentTitle => 'Belge başlığı';

  @override
  String get exportBottomLeft => 'Sol alt';

  @override
  String get exportBottomCenter => 'Alt orta';

  @override
  String get exportBottomRight => 'Sağ alt';

  @override
  String get exportFirstPage => 'İlk sayfada üst ve alt bilgiyi göster';

  @override
  String get exportAccent => 'Vurgu / bağlantı rengi';

  @override
  String get exportTheme => 'Tema';

  @override
  String get exportAutomatic => 'Otomatik';

  @override
  String get exportLayout => 'Düzen';

  @override
  String get exportContentWidth => 'En fazla içerik genişliği';

  @override
  String get exportOutput => 'Çıktı';

  @override
  String get exportPackaging => 'Paketleme';

  @override
  String get exportSingleFile => 'Tek HTML dosyası';

  @override
  String get exportAssetsDirectory => 'HTML + kaynak klasörü';

  @override
  String get exportCustomCss => 'Özel stil sayfası…';

  @override
  String get exportRemoveCss => 'Özel stil sayfasını kaldır';

  @override
  String get exportCssNote =>
      'İsteğe bağlı UTF-8 CSS dosyası seçin (en fazla 256 KiB). İçe aktarımlar, kaynak URL’leri ve çalıştırılabilir veya kaçışlı CSS reddedilir. Stiller BusyMark CSS’inden sonra uygulanır. Uzak kaynaklar indirilmez.';

  @override
  String get exportSitePackagingNote =>
      'Writerside ayrı bağlantılı konu sayfalarını korur. Tek dosya modu kaynakları her sayfaya gömer.';

  @override
  String get exportInvalidGeometry =>
      'Kenar boşluklarından sonra en az 20 mm içerik genişliği ve yüksekliği bırakın.';

  @override
  String get exportInvalidColor => '#RRGGBB biçiminde bir renk girin.';

  @override
  String get exportInvalidCss =>
      'İçe aktarım, kaynak URL’si, HTML, çalıştırılabilir veya kaçışlı CSS içermeyen, okunabilir UTF-8 .css dosyası seçin (en fazla 256 KiB).';

  @override
  String get clipboardHistory => 'Kopyalama Geçmişi';

  @override
  String get clipboardHistoryDescription =>
      'Oturuma özgü kopyalama geçmişini aç.';

  @override
  String get clipboardCurrent => 'Mevcut kopyalama';

  @override
  String get clipboardCurrentExternal =>
      'Başka bir uygulamadan mevcut kopyalama';

  @override
  String clipboardDestination(String name) {
    return '$name\'e yapıştır';
  }

  @override
  String get clipboardSessionOnly =>
      'Sadece bu BusyMark oturumu için saklanır.';

  @override
  String get clipboardNoItems => 'Kopyalama geçmişi boş.';

  @override
  String get clipboardDisabled =>
      'Kopyalama Geçmişi koleksiyonu Ayarlar\'da devre dışıdır.';

  @override
  String get clipboardUnavailable =>
      'Mevcut kopyalama içeriği mevcut değil veya desteklenmiyor.';

  @override
  String get clipboardTooLarge =>
      'Bu kopyalanmış öğe, saklamak için çok büyüktür.';

  @override
  String get clipboardPastePlainText => 'Temiz Metin Olarak Yapıştır';

  @override
  String get clipboardClearAll => 'Kopyalama Geçmişini Temizle';

  @override
  String get clipboardEntryText => 'Metin';

  @override
  String get clipboardEntryRichText => 'Zengin Metin';

  @override
  String get clipboardEntryImage => 'Resim';

  @override
  String clipboardOrigin(String name) {
    return '$name\'den Kopyalandı';
  }

  @override
  String get localHistory => 'Yerel Geçmiş';

  @override
  String get localHistoryEllipsis => 'Yerel Geçmiş…';

  @override
  String get localHistoryDescription =>
      'Mevcut belge için kaydedilmiş ve otomatik yerel sürümleri göster.';

  @override
  String get findLocalHistoryEllipsis => 'Yerel Geçmişte Bul...';

  @override
  String get findLocalHistoryDescription =>
      'Yerel Geçmişte belgeleri ve revizyon içeriğini arayın.';

  @override
  String get localHistoryNoDocuments =>
      'Henüz herhangi bir belge Yerel Geçmişe sahip değil.';

  @override
  String get localHistoryNoRevisions =>
      'Bu belge Yerel Geçmiş revizyonlarına sahip değil.';

  @override
  String get localHistorySelectedRevision => 'Seçilen revizyon';

  @override
  String get localHistoryCurrentEditor => 'Mevcut düzenleme içeriği';

  @override
  String get localHistoryCurrentDisk => 'Disk üzerinde mevcut içerik';

  @override
  String get localHistoryMissingFile => 'Orijinal dosya bulunmuyor.';

  @override
  String get localHistoryRestoreRevision => 'Versiyonu Geri Yükle';

  @override
  String get localHistoryRestoreOriginalLocation =>
      'Orijinal Konuma Geri Yükle';

  @override
  String get localHistoryRestoreNewLocation => 'Yeni Konuma Geri Yükle…';

  @override
  String get localHistoryRestoreChange => 'Değişikliği Geri Yükle';

  @override
  String get localHistoryRestoreUnavailable =>
      'Bu değişiklik geri alınamaz çünkü karşılaştırma artık geçerli değil.';

  @override
  String get localHistoryComparisonSimplified =>
      'Bu büyük karşılaştırma basitleştirildi. Tek tek değişiklikleri geri yüklemek mümkün değil.';

  @override
  String localHistoryOlderChange(String text) {
    return 'Eski versiyon değişikliği: $text';
  }

  @override
  String localHistoryCurrentChange(String text) {
    return 'Mevcut içerik değişikliği: $text';
  }

  @override
  String get localHistoryDeleted => 'Silindi';

  @override
  String get localHistoryUntitled => 'Başlımsız';

  @override
  String get localHistoryClearDocument => 'Bu Dokümanın Geçmişini Temizle';

  @override
  String get localHistoryClearAll => 'Tüm Yerel Geçmişi Temizle';

  @override
  String get localHistoryClearDocumentTitle =>
      'Doküman Geçmişini Temizlemek İstemiyor Musunuz?';

  @override
  String get localHistoryClearAllTitle =>
      'Tüm Yerel Geçmişi Temizlemek İstemiyor Musunuz?';

  @override
  String get localHistoryClearConfirmation =>
      'Bu, kaydedilen tüm sürümleri kalıcı olarak kaldırır. Bu işlem geri alınamaz.';

  @override
  String get localHistoryWarningIndexRebuilt =>
      'Yerel Geçmiş indeksi, sağlam sürümlerden yeniden oluşturuldu.';

  @override
  String localHistoryWarningUnsupportedFormat(String version) {
    return 'Bu Yerel Geçmiş depolama, desteklenmeyen format $version kullanır.';
  }

  @override
  String localHistoryWarningUnavailable(String detail) {
    return 'Yerel Geçmiş kullanılabilir değil: $detail';
  }

  @override
  String get localHistoryWarningRecordingDisabled =>
      'Kayıt devre dışı bırakılmış veya bu yol hariç tutulmuş. Geri yükleme yapmadan önce tekrar etkinleştirin.';

  @override
  String localHistoryWarningPathChange(String detail) {
    return 'Yerel Geçmiş, yol değişikliğini kaydetemedi: $detail';
  }

  @override
  String localHistoryWarningDeletedPath(String detail) {
    return 'Yerel Geçmiş, silinen yolu kaydetemedi: $detail';
  }

  @override
  String get localHistoryWarningRevisionMissing =>
      'Seçilen sürüm eksik veya bozulmuş.';

  @override
  String localHistoryWarningRevisionRead(String detail) {
    return 'Seçilen sürüm okunamaz: $detail';
  }

  @override
  String localHistoryWarningCapture(String detail) {
    return 'Yerel Geçmiş, bu sürümü yakalamadı: $detail';
  }

  @override
  String localHistoryRevisionAt(String reason, String timestamp) {
    return '$reason – $timestamp';
  }

  @override
  String get localHistoryReasonBaseline => 'Temel Sürüm';

  @override
  String get localHistoryReasonSaved => 'Kaydedildi';

  @override
  String get localHistoryReasonAutomaticCheckpoint =>
      'Otomatik kontrol noktası';

  @override
  String get localHistoryReasonBeforeReload => 'Yenilemeden önce';

  @override
  String get localHistoryReasonBeforeDiscard => 'Atılmadan önce';

  @override
  String get localHistoryReasonBeforeRestore => 'Restorasyon öncesi';

  @override
  String get localHistoryReasonBeforeDelete => 'Silme öncesi';

  @override
  String get localHistoryReasonExternalChange => 'Dış kaynak değişiklik';

  @override
  String get settingsHistory => 'Geçmiş';

  @override
  String get settingsClipboardHistoryTitle => 'Geçmişi Kopyala';

  @override
  String get settingsClipboardHistoryDescription =>
      'Bu BusyMark oturumu için kopyalanan ve başarıyla yapıştırılan içeriği sakla.';

  @override
  String get settingsLocalHistoryTitle => 'Yerel Geçmişi Kaydet';

  @override
  String get settingsLocalHistoryDescription =>
      'Belgeleri kurtarma ve karşılaştırma için bu cihazda değişiklikleri sakla.';

  @override
  String get settingsHistoryCheckpoint => 'Otomatik kontrol noktası aralığı';

  @override
  String get settingsHistoryRetention => 'Saklama süresi';

  @override
  String get settingsHistoryStorage => 'Maksimum depolama alanı';

  @override
  String get settingsHistoryExcludedPaths => 'Hariç tutulan yollar';

  @override
  String get settingsHistoryExcludedPathsHint => 'Bir mutlak yol her satırda';

  @override
  String settingsSecondsValue(int value) {
    return '$value saniye';
  }

  @override
  String settingsDaysValue(int value) {
    return '$value gün';
  }

  @override
  String settingsMebibytesValue(int value) {
    return '$value MiB';
  }

  @override
  String get spelling => 'Yazım';

  @override
  String get automaticSpelling => 'Otomatik yazım denetimi';

  @override
  String get defaultSpellingLanguage => 'Varsayılan yazım dili';

  @override
  String get projectSpellingLanguage => 'Proje yazım denetimi dili';

  @override
  String get chooseSpellingLanguage => 'Yazım dili seç';

  @override
  String get spellingLanguageUnsetStatus => 'Dil…';

  @override
  String get spellingOffStatus => 'Yazım denetimi kapalı';

  @override
  String get checkSpelling => 'Yazımı Denetle';

  @override
  String get ignoreSpellingOnce => 'Bir Kez Yoksay';

  @override
  String get ignoreSpellingDocument => 'Bu Belgede Tümünü Yoksay';

  @override
  String get addPersonalSpellingWord => 'Kişisel Sözlüğe Ekle';

  @override
  String get addProjectSpellingWord => 'Proje Sözlüğüne Ekle';

  @override
  String get inheritSpellingLanguage => 'Proje veya uygulama dilini kullan';

  @override
  String get disableDocumentSpelling => 'Yazımı denetleme';

  @override
  String get importSpellingDictionary => 'Sözlük İçe Aktar';

  @override
  String get personalSpellingDictionary => 'Kişisel Sözlük';

  @override
  String get projectSpellingDictionary => 'Proje Sözlüğü';

  @override
  String get noSpellingErrors => 'Yazım hatası yok';

  @override
  String get noSpellingSuggestions => 'Yazım önerisi yok';

  @override
  String get spellingWordCheckFailed => 'Bu sözcük denetlenemedi';

  @override
  String get spellingCheckFailed => 'Yazım denetimi başarısız oldu';

  @override
  String get spellingSettingsLoadFailed =>
      'Yazım denetimi ayarları yüklenemedi';

  @override
  String get retrySpellingSettings => 'Yazım denetimi ayarlarını yeniden yükle';

  @override
  String get spellingCheckIncomplete => 'Yazım denetimi tamamlanmadı';

  @override
  String get spellingDictionaryNotInstalled => 'Sözlük yüklü değil';

  @override
  String spellingDictionaryNotInstalledForLanguage(String dictionary) {
    return '$dictionary sözlüğü yüklü değil';
  }

  @override
  String spellingDictionaryNotInstalledWithSize(String size) {
    return 'Yüklü değil · $size';
  }

  @override
  String get spellingDictionaryInstalled => 'Yüklü';

  @override
  String get installSpellingDictionary => 'Sözlüğü yükle';

  @override
  String get removeSpellingDictionary => 'Sözlüğü kaldır';

  @override
  String get cancelSpellingDictionaryInstall => 'Sözlük indirmesini iptal et';

  @override
  String get retrySpellingDictionaryInstall =>
      'Sözlük yüklemesini yeniden dene';

  @override
  String spellingDictionaryDownloading(String size) {
    return '$size indiriliyor…';
  }

  @override
  String get spellingDictionaryValidating => 'Sözlük doğrulanıyor…';

  @override
  String get spellingDictionaryInstallFailed =>
      'Sözlük yüklenemedi — yeniden denemek için seçin';

  @override
  String spellingDictionaryInstallPrompt(String dictionary, String size) {
    return '$dictionary ($size) yüklensin mi? Yüklendikten sonra kaldırılana kadar çevrimdışı kullanılabilir.';
  }

  @override
  String get spellingDictionaryUnavailable => 'Sözlük kullanılamıyor';

  @override
  String get spellingChecking => 'Yazım denetleniyor…';

  @override
  String exportInvalidRange(String field, String minimum, String maximum) {
    return '$field: $minimum ile $maximum arasında bir sayı girin.';
  }

  @override
  String get spellingDictionaryRecoveryConflict =>
      'Yazım sözlüğü harici olarak değiştirildi. Bir kurtarma kopyası korundu.';

  @override
  String get windowMinimize => 'Simge durumuna küçült';

  @override
  String get windowMaximize => 'Ekranı kapla';

  @override
  String get windowRestore => 'Geri yükle';

  @override
  String get nextcloudNotes => 'Nextcloud Notes';

  @override
  String get nextcloudConnect => 'Bağlan';

  @override
  String get nextcloudReconnect => 'Yeniden bağlan';

  @override
  String get nextcloudDisconnect => 'Bağlantıyı kes';

  @override
  String get nextcloudServer => 'Sunucu adresi';

  @override
  String get nextcloudSignInBrowser =>
      'Tarayıcınızda oturum açmayı tamamlayın.';

  @override
  String get nextcloudFavorites => 'Sık kullanılanlar';

  @override
  String get nextcloudNewNote => 'Yeni not';

  @override
  String get nextcloudSavedLocally => 'Yerel kaydedildi · eşitleme bekliyor';

  @override
  String get nextcloudSyncing => 'Eşitleniyor';

  @override
  String get nextcloudSynced => 'Eşitlendi';

  @override
  String get nextcloudOffline => 'Çevrimdışı';

  @override
  String get nextcloudLocked => 'Sunucu tarafından kilitlendi';

  @override
  String get nextcloudReconnectRequired => 'Yeniden bağlantı gerekli';

  @override
  String get nextcloudCreationUncertain => 'Oluşturma sonucu belirsiz';

  @override
  String get nextcloudReadOnly => 'Salt okunur';

  @override
  String get nextcloudTakeRemote => 'Sunucu sürümünü kullan';

  @override
  String get nextcloudMerge => 'Birleştir';

  @override
  String get nextcloudDeleteNote => 'Not silinsin mi?';

  @override
  String get nextcloudWorkspaceReplaceUnavailable =>
      'Nextcloud Notes için çalışma alanında değiştirme kullanılamaz. Her not içinde değiştirin.';

  @override
  String get nextcloudSaveLocalCopy => 'Yerel kopyayı kaydet…';

  @override
  String get nextcloudDisconnectWarning =>
      'Bu hesabı kaldırmak önbellekteki notları ve bekleyen değişiklikleri bu cihazdan siler. Çalışmayı sunucuda tutmak için önce eşitleyin.';

  @override
  String get nextcloudAttachmentRetryWarning =>
      'Önceki yükleme başarılı olduysa yeniden denemek sunucuda kullanılmayan bir ek bırakabilir.';

  @override
  String get nextcloudAttachmentReference => 'Sunucudaki ek başvurusu';

  @override
  String get nextcloudAddAttachment => 'Ek ekle…';

  @override
  String get nextcloudDeleteAttachmentWarning =>
      'Bu eki silmek, nottaki bağlantılarını kullanılamaz hale getirir. Saklanan veriler yerel geçmişten kurtarılabilir.';

  @override
  String get nextcloudChooseConflictingAttributes =>
      'Çakışan her öznitelik için bir değer seçin.';

  @override
  String get nextcloudUseServerNote => 'Bu sunucu notunu kullan';

  @override
  String get nextcloudUseServerNoteExplanation =>
      'Bu taslağı seçilen sunucu notuna bağlar, ardından korunan yerel değişiklikleri eşitler. Eşleşen bir istek, notu kimin oluşturduğunu doğrulamaz.';

  @override
  String get nextcloudExactCandidate =>
      'İstekle tam eşleşme; kimlik doğrulanmadı.';

  @override
  String get nextcloudPossibleCandidate =>
      'Düzenlenmiş istekle olası eşleşme; kimlik doğrulanmadı.';

  @override
  String get nextcloudSelectCandidate => 'İncelemek için bir sunucu notu seçin';

  @override
  String get nextcloudCreateSeparate => 'Ayrı bir not oluştur';

  @override
  String get nextcloudCreateSeparateWarning =>
      'İlk istek sunucuda zaten bir not oluşturmuş olabilir. Bu işlem korunan yerel çalışmanızla ayrı bir not oluşturur. Olası kopyalar silinmez.';

  @override
  String get wsSemanticFormats => 'Anlamsal biçimlendirme';

  @override
  String get wsUiControl => 'Arayüz denetimi';

  @override
  String get wsFilePath => 'Dosya / Yol';

  @override
  String get wsUiPath => 'Arayüz yolu';

  @override
  String get wsDefinitionList => 'Tanım listesi';

  @override
  String get wsIncludeContent => 'Yeniden kullanılabilir içerik ekle';

  @override
  String get wsVariableReference => 'Değişken başvurusu';

  @override
  String get wsConvertList => 'Listeyi prosedüre dönüştür';

  @override
  String get wsElementProperties => 'Öğe özellikleri';

  @override
  String get wsTopicProperties => 'Konu özellikleri';

  @override
  String get wsCollapsible => 'Daraltılabilir';

  @override
  String get wsPublishedState => 'Yayımlanan başlangıç durumu';

  @override
  String get wsExpanded => 'Genişletilmiş';

  @override
  String get wsCollapsed => 'Daraltılmış';

  @override
  String get wsCollapsedTitle => 'Daraltılmış başlık';

  @override
  String get wsTerm => 'Terim';

  @override
  String get wsListLayout => 'Liste düzeni';

  @override
  String get wsSyncGroup => 'Eşitleme grubu';

  @override
  String get wsTabKey => 'Sekme anahtarı';

  @override
  String get wsSwitcherLabel => 'Değiştirici etiketi';

  @override
  String get wsNavigationElements => 'Gezinme öğeleri';

  @override
  String get wsNavigationDepth => 'Gezinme derinliği';

  @override
  String get wsAddItem => 'Öğe ekle';

  @override
  String get wsStep => 'Adım';

  @override
  String get wsPropertyInvalid => 'Geçersiz özellik değeri';

  @override
  String get wsFilter => 'Filtre';

  @override
  String get wsIdentifier => 'Öğe kimliği';

  @override
  String get wsTldr => 'Özet (TLDR)';

  @override
  String get wsFullLayout => 'Tam genişlik';

  @override
  String get wsMediumLayout => 'Orta (1:2)';

  @override
  String get wsNarrowLayout => 'Dar terim sütunu';

  @override
  String get wsTitle => 'Başlık';

  @override
  String get wsSwitcherKey => 'Değiştirici anahtarı';

  @override
  String get nextcloudServerSettings => 'Sunucu Notes ayarları';

  @override
  String get nextcloudNotesPath => 'Not klasörünün yolu';

  @override
  String get nextcloudFileSuffix => 'Yeni notların dosya uzantısı';

  @override
  String get nextcloudServerSettingsExplanation =>
      'Bu sunucu Notes ayarları diğer istemcileri de etkiler. Yolun değiştirilmesi dosyaları taşımaz; uzantının değiştirilmesi mevcut notları yeniden adlandırmaz.';

  @override
  String get nextcloudSettingsSaved => 'Sunucu ayarları kaydedildi';

  @override
  String get nextcloudSettingsNormalized =>
      'Sunucunun normalleştirdiği değerlerle kaydedildi';

  @override
  String get nextcloudPendingUpload => 'Ek yüklemesi bekliyor';

  @override
  String nextcloudServerCheck(String time) {
    return 'Son sunucu kontrolü: $time';
  }

  @override
  String get nextcloudSettingsLoading => 'Sunucu ayarları yükleniyor';

  @override
  String get nextcloudSettingsSaving => 'Sunucu ayarları kaydediliyor';

  @override
  String get nextcloudPreviousLocalEdit => 'Önceki yerel düzenleme';

  @override
  String get nextcloudUsePreviousEdit => 'Önceki düzenlemeyi kullan';

  @override
  String get quickOpen => 'Hızlı aç';

  @override
  String get notesAll => 'Tüm notlar';

  @override
  String get notesUncategorized => 'Kategorisiz';

  @override
  String get notesRecovery => 'Kurtarma';

  @override
  String get notesRecentlyEdited => 'Son düzenlenen';

  @override
  String get notesOldestEdited => 'En eski düzenleme';

  @override
  String get notesTitleAscending => 'Başlık A–Z';

  @override
  String get notesTitleDescending => 'Başlık Z–A';

  @override
  String get notesMove => 'Kategoriye taşı';

  @override
  String get notesRemoveFavorite => 'Favoriyi kaldır';

  @override
  String get notesOffline => 'Çevrimdışı kullanılabilir yap';

  @override
  String get notesOfflineRemove => 'Çevrimdışı saklamayı kaldır';

  @override
  String get notesIndexing => 'Notlar dizine ekleniyor…';

  @override
  String get notesSearchHelp =>
      'Terimler VE ile birleştirilir. \"Alıntı ifadeler\", title: ve category: kullanın.';

  @override
  String get notesSourceLocation => 'Kaynak konumu';

  @override
  String get notesRecoveryHelp =>
      'Yalnızca saklanan yerel notlar ve yerel geçmiş. Sunucu çöp kutusu ve geçmişi kullanılamaz.';

  @override
  String get notesImport => 'Notları içe aktar';

  @override
  String get notesExport => 'Notları dışa aktar';

  @override
  String get notesImportDistinct => 'Ayrı bir not olarak içe aktar';

  @override
  String get notesAvailableOffline => 'Çevrimdışı kullanılabilir';

  @override
  String get notesIncomplete => 'Eksik';

  @override
  String get notesSelected => 'Seçilen notlar';

  @override
  String get notesNoHistory =>
      'Saklanan sürüm yok. Geçmiş kapalı, süresi dolmuş veya temizlenmiş olabilir.';

  @override
  String get notesTextAvailable => 'Metin yerel olarak kullanılabilir';

  @override
  String get notesLocalVersion => 'Yerel çalışma sürümü';

  @override
  String get notesAttachments => 'Ekler';

  @override
  String get notesSkipped => 'Atlandı';

  @override
  String get notesFailed => 'Başarısız';

  @override
  String get notesCompleted => 'Tamamlandı';

  @override
  String get notesImportNew => 'Yeni içe aktarma başlat';

  @override
  String get notesImportResume => 'Kesilen içe aktarmayı sürdür';

  @override
  String get notesImportAlreadyImported => 'Bu işlemde zaten içe aktarıldı';

  @override
  String get references => 'Başvurular';

  @override
  String get referenceIncoming => 'Gelen';

  @override
  String get referenceOutgoing => 'Giden';

  @override
  String get referenceChooseTarget => 'Bağlantı hedefini seç';

  @override
  String get referenceWholeDocument => 'Tüm belge';

  @override
  String get referenceSourceLocation => 'Kaynak konumu';

  @override
  String get referenceTargetLocation => 'Hedef konumu';

  @override
  String get referenceResolved => 'Çözüldü';

  @override
  String get referenceMissing => 'Eksik';

  @override
  String get referenceAmbiguous => 'Belirsiz';

  @override
  String get referenceUnavailable => 'Bu bağlamda kullanılamıyor';

  @override
  String get referenceUnsupported => 'Desteklenmiyor';

  @override
  String get referenceNoPortableId =>
      'Bu hedefin doğrulanmış taşınabilir not URL’si yok.';

  @override
  String get wsIncludeLines => 'Satırları dahil et';

  @override
  String get wsIncludeSymbol => 'Sembolü dahil et';

  @override
  String get wsEmphasizeLines => 'Görüntülenen satırları vurgula';

  @override
  String get wsPropertiesReadOnly => 'Bu görünümde özellikler salt okunurdur.';

  @override
  String get wsPropertiesProtected => 'Bu öğe korunuyor. Kaynağını düzenleyin.';

  @override
  String get wsPropertiesConflict =>
      'Belge veya öğe değişti. Taslağı geri alın ve yeniden seçin.';

  @override
  String get wsPropertiesUnresolved => 'Başvuru şu anda çözümlenemiyor.';

  @override
  String get wsUseDefault => 'Varsayılanı kullan';

  @override
  String get wsPropertiesSelection => 'Tek bir öğe seçin.';

  @override
  String get wsImageDisplay => 'Görüntü görünümü';

  @override
  String get wsImageThumbnail => 'Tıklanabilir küçük resim';

  @override
  String get wsEnabled => 'Etkin';

  @override
  String get wsDisabled => 'Devre dışı';

  @override
  String get wsWidth => 'Genişlik';

  @override
  String get wsHeight => 'Yükseklik';

  @override
  String get wsPropertiesInactive =>
      'Bu özellik yalnızca yayımlanan daraltma etkinken geçerlidir.';

  @override
  String get wsNavigationAll => 'Başlıklı tüm öğeler';

  @override
  String get wsNavigationNone => 'Gezinme yok';

  @override
  String get wsNavigationCustom => 'Özel gezinme';

  @override
  String get wsTitleOverride => 'Başlığı geçersiz kıl';

  @override
  String get wsCompactLayout => 'Kompakt';

  @override
  String get wsWideLayout => 'Geniş';

  @override
  String get wsCodeSourceConflict =>
      'src ayarlamadan önce bu blokta yazılan kodu taşıyın veya kaldırın. Writerside, kaynak başvurusu olan boş olmayan kod bloğunu reddeder.';

  @override
  String get wsInherited => 'Listeden devral';

  @override
  String get wsExternalImageSize =>
      'Writerside dış görüntülerin boyutunu güvenilir biçimde ayarlamaz. Mevcut boyutlar incelenebilir ve kaldırılabilir.';

  @override
  String get wsPropertiesNotSerialized =>
      'Bu değişiklik kaynağa uygulanmadı. Taslak korundu.';

  @override
  String get wsListItem => 'Liste öğesi';

  @override
  String get wsSourceFile => 'Kaynak dosya';

  @override
  String get wsLinkTarget => 'Bağlantı hedefi';

  @override
  String get wsPreviewImage => 'Önizleme resmi';

  @override
  String get wsIncludedElement => 'Dahil edilen öğe';

  @override
  String get wsHelpModule => 'Yardım modülü';

  @override
  String get wsActionId => 'Eylem kimliği';

  @override
  String get wsKeymapHelpInstance => 'Tuş eşlemesi yardım örneği';

  @override
  String get wsShowInSource => 'Kaynakta göster';

  @override
  String get wsOriginElement => 'Öğe geçersiz kılması';

  @override
  String get wsOriginAncestor => 'Üst öğe';

  @override
  String get wsOriginModule => 'Modül varsayılanı';

  @override
  String get wsOriginBuiltIn => 'Yerleşik varsayılan';

  @override
  String get wsOriginUnresolved => 'Çözümlenemedi';

  @override
  String wsEffectiveProperty(String value, String origin) {
    return 'Etkin: $value — $origin';
  }

  @override
  String get wsElementSelector => 'Öğe';

  @override
  String wsGeneratedAnchorValue(String anchor) {
    return 'Oluşturulan: $anchor';
  }

  @override
  String wsDefaultProperty(String value) {
    return 'Varsayılan: $value';
  }

  @override
  String wsDefaultPropertyOrigin(String value, String origin) {
    return 'Varsayılan: $value · $origin';
  }

  @override
  String wsResolvedProperty(String value) {
    return 'Çözümlenen: $value';
  }

  @override
  String get wsPropertyUnresolved => 'Çözümlenmedi';

  @override
  String get wsModule => 'Modül';

  @override
  String get wsParent => 'Üst öğe';

  @override
  String get wsListType => 'Liste türü';

  @override
  String get wsStartingNumber => 'Başlangıç numarası';

  @override
  String get wsListSorting => 'Sıralama';

  @override
  String get wsLetteredList => 'Harfli liste';

  @override
  String get wsCheckboxList => 'Onay kutulu liste';

  @override
  String get wsMarkerlessList => 'İşaretsiz liste';

  @override
  String get wsAscending => 'Artan';

  @override
  String get wsDescending => 'Azalan';

  @override
  String get wsNoSorting => 'Sıralama yok';

  @override
  String get wsAsWritten => 'Yazıldığı gibi';

  @override
  String get wsSentenceCase => 'Cümle düzeni';

  @override
  String get wsTitleCase => 'Başlık düzeni';

  @override
  String get wsLowerCase => 'Küçük harf';

  @override
  String get wsUpperCase => 'Büyük harf';

  @override
  String get wsNativeMarkers => 'Markdown işaretleri';

  @override
  String wsListMarkerStart(String number) {
    return 'İlk işaret: $number';
  }

  @override
  String wsListLevel(String level) {
    return 'Düzey $level';
  }

  @override
  String get wsModuleCapsIgnored =>
      'Sabitlenmiş derleyici modülün <caps> kurallarını yok sayar. Yerel caps özniteliği veya default-property kullanın.';

  @override
  String get wsInsertElements => 'Öğe ekle';

  @override
  String get wsAdmonitionsAndQuotes => 'Uyarılar ve alıntılar';

  @override
  String get wsSemanticText => 'Anlamsal metin';

  @override
  String get wsPropertiesUnavailable =>
      'İncelenen öğe kullanılamıyor. Devam etmek için bir öğeyi inceleyin.';

  @override
  String get searchDocumentsCategory => 'Belgeler';

  @override
  String get searchTopicsCategory => 'Konular';

  @override
  String get searchCurrentDocument => 'Geçerli belge';

  @override
  String get searchCurrentWorkspace => 'Geçerli çalışma alanı';

  @override
  String get browseNotes => 'Notlara göz at';

  @override
  String get searchActionsCommand => 'Eylemleri ara';

  @override
  String get searchDocumentsCommand => 'Belgeleri ara';

  @override
  String get searchTopicsCommand => 'Konuları ara';

  @override
  String get searchRecentCommand => 'Son kullanılanları ara';

  @override
  String get searchResourceUnavailable => 'Bu kaynak kullanılamıyor.';

  @override
  String get notesSync => 'Notları eşitle';

  @override
  String get searchInWorkspace => 'Çalışma Alanında Ara';

  @override
  String get searchCategory => 'Arama kategorisi';

  @override
  String get clearHistorySearchScope => 'Belgelerin geçmişinde ara';

  @override
  String get searchInDocument => 'Belgede ara';

  @override
  String get searchDocumentHint => 'Bu belgede ara…';

  @override
  String get searchWorkspaceHint => 'Bu çalışma alanında ara…';

  @override
  String get searchOutlineHint => 'Başlıklarda ara…';

  @override
  String get searchHistoryHint => 'Yerel geçmişte ara…';

  @override
  String get searchEnterText => 'Aranacak metni girin';

  @override
  String get searchAccountUnavailable => 'Hesap kullanılamıyor';

  @override
  String get searchDocumentsHint => 'Belgeleri ara…';

  @override
  String get searchTopicsHint => 'Konuları ara…';

  @override
  String get searchRecentHint => 'Son kullanılanları ara…';

  @override
  String get searchActionsHint => 'Eylemleri ara…';

  @override
  String get searchRequiresNotesWorkspace => 'Notlar çalışma alanı gerektirir';

  @override
  String get searchSidebarLabel => 'Ara:';

  @override
  String get searchDocumentTextCategory => 'Belge metni';

  @override
  String get searchWorkspaceTextCategory => 'Çalışma alanı metni';

  @override
  String get searchHeadingsCategory => 'Başlıklar';

  @override
  String get shortcutUnassigned => 'Atanmamış';

  @override
  String get shortcutPressKeys => 'Bir tuş birleşimine basın…';

  @override
  String get shortcutRecord => 'Kısayol kaydet';

  @override
  String get shortcutRestoreAll => 'Tüm varsayılanları geri yükle';

  @override
  String get shortcutRestoreAllQuestion =>
      'Tüm eylemlerin varsayılan kısayolları geri yüklensin mi? Özel atamalar kaldırılacak.';

  @override
  String get shortcutSaveFailed =>
      'Kısayollar etkin ancak kaydedilemedi. Yeniden başlatmadan sonra korumak için tekrar kaydedin.';

  @override
  String get shortcutRetry => 'Kaydetmeyi yeniden dene';

  @override
  String get shortcutChanged =>
      'Atamalar değişti. Geçerli kısayolları gözden geçirip yeniden deneyin.';

  @override
  String get shortcutInvalid => 'Bu birleşim bu bağlamda atanamaz.';

  @override
  String get shortcutSystemWarning =>
      'Masaüstünüz bu birleşimi kullanıyor olabilir. BusyMark sistem kısayollarını geçersiz kılamaz.';

  @override
  String get shortcutConflicts => 'Bu kısayol şu eylemlerle çakışıyor:';

  @override
  String get shortcutRemove => 'Atamayı kaldır';

  @override
  String get shortcutRestoreDefault => 'Varsayılanı geri yükle';

  @override
  String get shortcutAssign => 'Ata';

  @override
  String get shortcutReassign => 'Yeniden ata';

  @override
  String get shortcutContextApplication => 'Uygulama';

  @override
  String get shortcutContextDocument => 'Belge görünümleri';

  @override
  String get shortcutContextEditor => 'Düzenleyici ve kaynak';

  @override
  String get shortcutContextWritersideSource => 'Writerside kaynağı';

  @override
  String get shortcutContextWorkspace => 'Çalışma alanı gezintisi';

  @override
  String get shortcutContextTree => 'Kenar çubuğu ağaçları';

  @override
  String get searchHeadingsCommand => 'Başlıklarda Ara';

  @override
  String get shortcutFixed =>
      'Düzenleyici tarafından yönetilir; yapılandırılamaz.';

  @override
  String get shortcutDefaultConflict =>
      'Varsayılan kısayol özel bir atamayla çakışıyor.';

  @override
  String get shortcutCurrentBinding => 'Geçerli kısayol';

  @override
  String get shortcutProposedBinding => 'Önerilen kısayol';

  @override
  String get notesActions => 'Not işlemleri';

  @override
  String get noteActions => 'Bu notun işlemleri';

  @override
  String get noteProperties => 'Not Özellikleri';

  @override
  String get notesExportAll => 'Notları dışa aktar · Tüm notlar…';

  @override
  String get notesExportCategory => 'Notları dışa aktar · Kategori…';

  @override
  String get notesOfflineAll => 'Çevrimdışı kullanılabilir yap · Tüm notlar';

  @override
  String get notesOfflineCategory => 'Çevrimdışı kullanılabilir yap · Kategori';

  @override
  String get notesOfflineRemoveAll =>
      'Çevrimdışı saklamayı kaldır · Tüm notlar';

  @override
  String get notesOfflineRemoveCategory =>
      'Çevrimdışı saklamayı kaldır · Kategori';

  @override
  String get notesOfflinePause => 'İndirmeleri Duraklat';

  @override
  String get notesOfflineResume => 'İndirmeleri Sürdür';

  @override
  String get notesOfflineKeep => 'Çevrimdışı kullanılabilir yap';

  @override
  String get notesOfflineRetentionHelp =>
      'Bu gereksinimin kaldırılması mevcut önbelleği silmez. Kategori veya hesap gereksinimi notu tutmaya devam edebilir.';

  @override
  String get notesOfflineBroader =>
      'Bu not bir kategori veya hesap gereksinimi nedeniyle de tutuluyor.';

  @override
  String get notesOfflineExternal =>
      'Harici medya bağlantı gerektirir. BusyMark yalnızca not metnini ve yönetilen ekleri tutar.';

  @override
  String get notesEmptyAll => 'Henüz not yok. Başlamak için bir not oluşturun.';

  @override
  String get notesEmptyFavorites => 'Favori not yok.';

  @override
  String get notesEmptyCategory => 'Bu kategoride not yok.';

  @override
  String get notesEmptyUncategorized => 'Kategorisiz not yok.';

  @override
  String get notesEmptyRecovery => 'Kurtarılacak saklanmış not yok.';

  @override
  String get notesLoadFailed => 'Nextcloud Notes · Başarısız. Yeniden dene';

  @override
  String get notesOperationFailed =>
      'İşlem tamamlanamadı. Taslağınız korunuyor. Kaydetmeyi ve çakışmaları inceleyip yeniden deneyin.';

  @override
  String get notesInspectionFailed => 'Ekler · Başarısız. Yeniden dene';

  @override
  String get notesStartingConnection => 'Nextcloud bağlantısı başlatılıyor…';

  @override
  String get notesVerifyingConnection => 'Notlar erişimi doğrulanıyor…';

  @override
  String get notesCancellingConnection =>
      'Oturum açma iptal ediliyor ve temizleniyor…';

  @override
  String get notesRemovingConnection => 'Yerel hesap kaldırılıyor…';

  @override
  String get notesRemovedWarning =>
      'Yerel Nextcloud hesabı kaldırıldı. Uygulama parolasının iptali doğrulanamadı. Nextcloud Güvenlik ayarlarından BusyMark uygulama parolasını kaldırın.';

  @override
  String get notesBuffersNotSaved =>
      'Tüm açık notlar yerel olarak kaydedilemedi. Çalışma alanında kaydetmeyi, çakışmaları veya normalleştirmeyi inceleyin. Yerel değişikliklerin hâlâ Nextcloud ile eşitlenmesi gerekebilir.';

  @override
  String get notesSettingsLeave =>
      'Ayrılmadan önce Nextcloud ayarlarındaki değişiklikler kaydedilsin mi?';

  @override
  String get notesSettingsLeaveHelp =>
      'Sunucu Notes ayarları · Kaydedilmemiş değişiklikler';

  @override
  String get notesSettingsReload => 'Sunucu Ayarlarını Yeniden Yükle…';

  @override
  String get notesSettingsReloadHelp =>
      'Yeniden yükleme, taslağınızı geçerli Nextcloud ayarlarıyla değiştirir. Taslak atılıp yeniden yüklensin mi?';

  @override
  String get notesSettingsRefreshFailed =>
      'Nextcloud ayarları kabul etti ancak notları yenileme başarısız oldu. Gösterilen değerler sunucunun onayladığı değerlerdir. Notlar üzerinden yenilemeyi yeniden deneyin.';

  @override
  String get notesUnavailable =>
      'Çevrimdışı · Metin yerel olarak kullanılabilir · Yerel kaydedildi · eşitleme bekliyor';

  @override
  String get notesStorageFull =>
      'Nextcloud depolaması dolu. Sunucuda yer açıp yeniden deneyin.';

  @override
  String get notesRejected =>
      'Nextcloud bu değişikliği reddetti. Yeniden denemeden önce notu inceleyin ve yerel bir kopya kaydedin.';

  @override
  String get notesThrottled =>
      'Nextcloud beklemenizi istedi. Eşitleme, yeniden deneme süresi dolunca devam eder.';

  @override
  String get notesRecoveryRequired => 'Çatışmalar · Karşılaştır';

  @override
  String get notesScanning => 'Dosyalar taranıyor…';

  @override
  String get notesCancelling =>
      'İptal ediliyor… Geçerli işlemin bitmesi bekleniyor.';

  @override
  String get notesCancelled => 'İptal edildi';

  @override
  String get notesPartial => 'Kısmen tamamlandı';

  @override
  String get notesTransferFailed => 'Başarısız. Yeniden dene';

  @override
  String get notesImportPartialHelp =>
      'Önceki öğeler zaten yerel olarak kaydedilmiş olabilir. Kopya oluşturmadan devam etmek için bu içe aktarmayı sürdürün.';

  @override
  String get notesNotStarted => 'Başlatılmadı';

  @override
  String get notesCreated => 'Oluşturuldu';

  @override
  String get notesRemoteDeleteUnavailable =>
      'Sunucu adresi · Desteklenmiyor · Sil · Ekler';

  @override
  String get notesCurrentText => 'Şu anda saklanan metin';

  @override
  String get notesRecovering => 'Yeni bir not olarak kurtarılıyor…';

  @override
  String get notesReadOnlyHelp =>
      'Salt okunur · Sık kullanılanlar · Yerel kopyayı kaydet…';

  @override
  String get notesSort => 'Notları sırala';

  @override
  String get notesPathRelative =>
      'Not klasörü yolu Nextcloud depolamanıza görelidir.';

  @override
  String get notesSettingsStale =>
      'Nextcloud ayarları değişti. Taslağı değiştirmeden önce sunucu değerlerini yeniden yükleyip inceleyin.';

  @override
  String get notesDownloadsPaused => 'İndirmeler duraklatıldı';

  @override
  String get notesExportNotPublished => 'Hiçbir dışa aktarım yayımlanmadı.';

  @override
  String get notesKeyringUnavailable =>
      'Masaüstü anahtarlığının kilidini açıp yeniden deneyin.';

  @override
  String get notesConnectFailed =>
      'Nextcloud Notes bağlantısı kurulamadı. Sunucu adresini denetleyip yeniden deneyin.';

  @override
  String get notesAccountMismatch =>
      'Aynı Nextcloud hesabında oturum açın. Başka bir hesap bağlamak için önce bunu kaldırın.';

  @override
  String get notesLocalRemovalFailed =>
      'Yerel hesap temizliği başarısız oldu. Kaldırmayı yeniden deneyebilmeniz için hesap korundu.';

  @override
  String get notesTransferring => 'Notlar aktarılıyor…';

  @override
  String get notesTechnicalDetails => 'Teknik ayrıntılar';

  @override
  String get notesPauseRequirement => 'Çevrimdışı Gereksinimini Duraklat';

  @override
  String get notesResumeRequirement => 'Çevrimdışı Gereksinimini Sürdür';

  @override
  String get gitReturnToDocument => 'Belgeye dön';

  @override
  String gitSnapshotLabel(String revision, String path) {
    return 'Salt okunur anlık görüntü · $revision · $path';
  }

  @override
  String get gitNonUtf8FilenameMessage =>
      'Bu dosya adı UTF-8 olmayan baytlar içeriyor. Git inceleme ve hazırlama kullanılabilir; belge düzenleyicisi UTF-8 dosya adı gerektirir.';

  @override
  String get gitUiMergeInProgress => 'ilerlemeye katılmak';

  @override
  String get gitUiRebaseInProgress => 'Gelişmekte geri dönmek';

  @override
  String get gitUiCherryPickInProgress => 'Cherry-pick ilerliyor';

  @override
  String get gitUiRevertInProgress => 'Gelişmek için dönüş';

  @override
  String get gitUiPatchApplicationInProgress => 'Patch uygulaması ilerliyor';

  @override
  String get gitUiSquashMergeResultAwaitingCommit =>
      'Squash Mide Sonuçları Komiteyi Bekliyor';

  @override
  String get gitUiUnresolvedIndexConflicts => 'Çözülmemiş Endeks Çatışmaları';

  @override
  String get gitUiUnresolvedConflicts => ' · • Çözülmemiş çatışmalar';

  @override
  String get gitUiReviewOperation => 'İnceleme Operasyonu';

  @override
  String get gitUiRefresh => 'Yenile';

  @override
  String get gitUiCreateNamedStash => 'Adı Soyadı Stash';

  @override
  String get gitUiCreateStash => 'Değişiklikleri sakla…';

  @override
  String get gitUiNoStashes => 'Stash yok';

  @override
  String get gitUiSelectAStashToInspectItsChanges =>
      'Değişiklikleri kontrol etmek için bir stash seçin';

  @override
  String get gitUiStashedUntrackedFiles => 'Çekilmemiş dosyalar';

  @override
  String get gitUiInspectStashedUntrackedFiles =>
      'Soruşturma dosyalarını incelemeye başladı...';

  @override
  String get gitUiReinstateTheStashSStagedIndexStateWhenApplying =>
      'Stash\'in staged/index durumunu yeniden ayarlayın';

  @override
  String get gitUiApplyAndRetain => 'Uygulama ve tutma';

  @override
  String get gitUiPop => 'Pop...';

  @override
  String get gitUiCreateBranch => 'Dal oluştur…';

  @override
  String get gitUiDropStash => 'Saklanan değişiklikleri sil…';

  @override
  String get gitUiBranchFromStash => 'Saklanan değişikliklerden dal oluştur';

  @override
  String get gitUiCreateSwitchToABranchAtTheStashSOriginal =>
      'Orijinal basın üzerinde bir dal oluşturun / anahtarlayın, sonra uygulayın. Orijinal basın daha sonra açık bir şekilde silinmesi için saklanır.';

  @override
  String gitUiArg0ThisStash(String arg0) {
    return '$arg0 bu çarpışma?';
  }

  @override
  String get gitUiTheOriginalStashIsRetainedIfApplyingConflicts =>
      'Orijinal çubuk, çatışmaların uygulanması durumunda saklanır.';

  @override
  String get gitUiDeletesThisStashEntryItsChangesAreNotApplied =>
      'Bu yazıyı kaldırın. değişiklikler uygulanmaz.';

  @override
  String get gitUiResolveTheUnmergedFilesGitHasNoStashContinueOr =>
      'Birleştirilmemiş dosyaları çözün. Git\'te stash için devam veya iptal komutu yoktur; özgün stash kaydı korunur.';

  @override
  String get gitUiStashNameMessage => 'İsim / Mesaj';

  @override
  String get gitUiStashContentAndResultingIndex =>
      'Stash İçeriği ve Sonuç Endeksi';

  @override
  String get gitUiStashTrackedWorkingAndStagedChanges =>
      'Stash çalışmayı izledi ve aşamalı değişiklikler';

  @override
  String get gitUiStashChangesLeaveStagedChangesInPlaceKeepIndex =>
      'Değişiklikleri sakla, indeksteki değişiklikleri yerinde bırak (--keep-index)';

  @override
  String get gitUiStashOnlyStagedChangesStaged =>
      'Yalnızca indeksteki değişiklikleri sakla (--staged)';

  @override
  String get gitUiIncludeUntrackedFiles => 'izinsiz dosyaları içerir';

  @override
  String get gitUiAllEligiblePathsInThisRepository =>
      'Bu depolama alanında tüm uygun yollar';

  @override
  String get gitUiNoEligibleChangesForTheseStashOptions =>
      'Bu stash seçenekleri için uygun değişiklikler yoktur.';

  @override
  String get gitUiSelectAtLeastOneEligiblePath => 'En az bir uygun yolu seçin.';

  @override
  String get gitUiCreateStash2 => 'Değişiklikleri sakla';

  @override
  String get gitUiCreateWorktree => 'Çalışma alanı oluşturmak...';

  @override
  String get gitUiCreateACommitBeforeCreatingAWorktreeAtHEAD =>
      'HEAD üzerinde çalışma ağacı oluşturmadan önce bir commit oluşturun.';

  @override
  String get gitUiDetachedHEAD => 'Ayrık HEAD';

  @override
  String get gitUiCurrent => 'Şimdiki ·';

  @override
  String get gitUiLocked => 'Kapalı ·';

  @override
  String get gitUiOpenInBusyStack => 'BusyStack\'te açılımı';

  @override
  String get gitUiStatusNotInspected => 'Kontrol Edilmemiş Durum';

  @override
  String get gitUiDirty => 'kirli';

  @override
  String get gitUiClean => 'Değişiklik yok';

  @override
  String get gitUiOpenWorkingFolder => 'Açık Çalışma Dosyası';

  @override
  String get gitUiMoveWorktree => 'Çalışma hareketleri...';

  @override
  String get gitUiUnlock => 'Unlock Çözümleri';

  @override
  String get gitUiLock => 'Lock için';

  @override
  String get gitUiRemoveCleanWorktree => 'Temiz çalışma alanını kaldırın...';

  @override
  String get gitUiReviewRemovalIncludingLocalChanges =>
      'Yerel değişiklikler de dahil olmak üzere inceleme kaldırma ...';

  @override
  String get gitUiNewWorktreeFolderName => 'Yeni çalışma dosyası adı';

  @override
  String get gitUiNewWorktreeBranch => 'Yeni Çalışma Şubesi';

  @override
  String gitUiCreateArg0Arg1WithANewLocalBranchAtArg2(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return '$arg2 ($arg3) yeni bir yerel şubesi ile $arg0/$arg1 oluşturun.';
  }

  @override
  String get gitUiDestinationFolderName => 'Destination Dosya Adı';

  @override
  String get gitUiRemoveWorktree => 'Çalışma ortadan kaldırılır mı?';

  @override
  String
  get gitUiExplicitlyDiscardAllLocalTrackedUntrackedChangesInThisWorktree =>
      'Bu çalışma alanında yerel olarak izlenmemiş / izlenmemiş tüm değişiklikleri açıkça ortadan kaldırın.';

  @override
  String get gitUiGitRefusesRemovalIfThereAreLocalChangesUntrackedFiles =>
      'Git, yerel değişiklikler, izlenmemiş dosyalar veya bir kilit varsa kaldırmayı reddeder.';

  @override
  String get gitUiDiscardLocalWorktreeContentsAndRemove =>
      'Yerel çalışma içeriğini ortadan kaldırın ve kaldırın';

  @override
  String get gitUiRemoveCleanWorktree2 => 'Temiz Çalışma Çerçevesi';

  @override
  String
  get gitUiExplicitlyRecurseIntoNestedSubmodulesForUpdatesSynchronization =>
      'Güncelleştirmeler / senkronizasyon için net alt modüllere açıkça geri dönün';

  @override
  String get gitUiNoRecordedSubmodules => 'kayıtlı alt modüller yok';

  @override
  String get gitUiNotInitialized => 'Başlatılmamış';

  @override
  String gitUiParentGitlinkArg0CheckedOutArg1(String arg0, String arg1) {
    return '$arg0 Çözüldü: $arg1\n';
  }

  @override
  String get gitUiDirtyNestedRepository => 'kirli depolama alanı';

  @override
  String get gitUiCleanNestedRepository => 'Temiz Koyu Depolama';

  @override
  String get gitUiNestedStatusUnavailable => 'İhracatın mevcut olmadığı';

  @override
  String get gitUiEnterNestedRepository => 'Giriş Rezervasyon';

  @override
  String get gitUiInitializeConfiguration => 'Konfigürasyon başlangıç';

  @override
  String get gitUiUpdateToParentSRecordedCommit =>
      'Anasayfa GÜNCELLEMELER İLGİLİ HABER Ebeveynlerin Kayıtlı...';

  @override
  String get gitUiFollowConfiguredRemoteBranch =>
      'Uzaktan yapılandırılmış şubeleri takip edin...';

  @override
  String get gitUiSynchronizeConfiguredURLs => 'Sinkronize edilmiş URL’ler...';

  @override
  String get gitUiStageCurrentSubmodulePointerInParent =>
      'Mevcut alt modül göstergesi anne içinde';

  @override
  String get gitUiParentAndSubmoduleCommitsPushesAndDirtyStateRemainSeparate =>
      'Ebeveyn ve alt modül eylemleri, baskıları ve kirli durum ayrı kalır. tarama onları başlatmaz veya güncelleştirmez.';

  @override
  String gitUiFetchAndCheckOutTheConfiguredRemoteBranchSCommit(String arg0) {
    return 'Fetch ve yapılandırılmış uzaktan şubenin komutunu kontrol edin. Bu, ebeveynin kaydedilen gitlink\'ten farklıdır. Recursive: $arg0.';
  }

  @override
  String gitUiInitializeAsNeededAndCheckOutExactlyArg0RecursiveArg1(
    String arg0,
    String arg1,
  ) {
    return 'İhtiyaç duyulduğunda başlatın ve tam olarak $arg0. Recursive: $arg1.';
  }

  @override
  String gitUiApplyTheReviewedSubmoduleConfigurationOperationRecursiveArg0(
    String arg0,
  ) {
    return 'Yorumlanan alt modül yapılandırma işlemi uygulayın. Recursive: $arg0.';
  }

  @override
  String get gitUiApplySubmoduleOperation => 'Submodüel İşlemleri';

  @override
  String get gitUiInspectARecordedRevisionOrCreateARecoveryBranchReflog =>
      'Kayıtlı bir incelemeyi kontrol edin veya bir kurtarma şubesi oluşturun. Reflog, özgürce kaybolmamış veya izlenmemiş içeriği geri getirmez.';

  @override
  String get gitUiSelectAReflogEntry => 'Reflog girişini seçin';

  @override
  String get gitUiPreviousPage => 'Önceki Sayfa';

  @override
  String get gitUiNextPage => 'Sonraki Sayfa';

  @override
  String get gitUiRecoveryBranchName => 'Rehabilitasyon Şubesi Adı';

  @override
  String gitUiCreatesABranchAtArg0WorkingFilesAndTheCurrent(String arg0) {
    return '$arg0\'te bir şubesi oluşturur; çalışma dosyaları ve mevcut şubesi değişmez.';
  }

  @override
  String get gitUiCreateRecoveryBranch => 'İyileşme şubesi oluşturmak...';

  @override
  String get gitUiReadOnlyRecoverySnapshot => 'Read-only kurtarma snapshot';

  @override
  String get gitUiInspectSnapshot => 'Snapshot kontrolü...';

  @override
  String get gitUiReviewReset => 'Sıfırlamayı incele…';

  @override
  String gitUiPageArg0(String arg0) {
    return 'Sayfa $arg0';
  }

  @override
  String get gitUiAGitTextHistoryMustOwnItsEditableField =>
      'Bir Git metin geçmişi kendi düzenlenebilir alanına sahip olmalıdır.';

  @override
  String get gitUiEditHEADIndexWorkingTree =>
      'Düzenle HEAD | İndeks | Çalışma ağacı…';

  @override
  String
  get gitUiTheReviewedIndexOrWorkingContentChangedRefreshThisComparison =>
      'Değerlendirilmiş endeks veya çalışma içeriği değiştirildi. bu karşılaştırmayı sıralamadan önce yenileme.';

  @override
  String get gitUiRefreshComparison => 'Soğutma Karşılaştırması';

  @override
  String get gitUiPreviousChangedFile => 'Önceki Değiştirilmiş Dosya';

  @override
  String get gitUiNextChangedFile => 'Sonraki Değiştirilmiş Dosya';

  @override
  String get gitUiPreviousDifference => 'Önceki Farklılıklar';

  @override
  String get gitUiNextDifference => 'Sonraki Farklılıklar';

  @override
  String get gitUiComparisonMode => 'Karşılaştırma Modu';

  @override
  String get gitUiSideBySide => 'Yan tarafta';

  @override
  String get gitUiUnified => 'Birleşik';

  @override
  String get gitUiDiffDisplayOptions => 'Diff Display Seçenekleri';

  @override
  String get gitUiWrap => 'Satır kaydırma';

  @override
  String get gitUiWords => 'sözcükler';

  @override
  String get gitUiCollapseContext => 'Bağlamı daralt';

  @override
  String get gitUiIgnoreWhitespace => 'Beyaz alanı görmezden';

  @override
  String get gitUiSearchComparison => 'arama karşılaştırması';

  @override
  String get gitUiSearch => 'Ara';

  @override
  String get gitUiCloseSearch => 'yakın arama';

  @override
  String get gitUiStagingActions => 'İndeks işlemleri';

  @override
  String get gitUiStagingActions2 => 'İndeks işlemleri…';

  @override
  String get gitUiUnstageSelectedChangedLines =>
      'Seçili değişen satırları indeksten çıkar';

  @override
  String get gitUiStageSelectedChangedLines =>
      'Seçili değişen satırları indekse ekle';

  @override
  String get gitUiUnstageWholeFile => 'Tüm dosyayı indeksten çıkar';

  @override
  String get gitUiStageWholeFile => 'Tüm dosyayı indekse ekle';

  @override
  String gitUiArg0WhitespaceOnlyChangedLinesHiddenShowExactChanges(
    String arg0,
  ) {
    return '$arg0 whitespace-only changed lines hidden · Tam değişiklikleri göster';
  }

  @override
  String gitUiArg0ChangedLinesSelectedDisplaySettingsNeverAlterTheStaged(
    String arg0,
  ) {
    return '$arg0 seçilmiş hatları değiştirdi · Ekran ayarları asla adım atılan byteyi değiştirmez.';
  }

  @override
  String get gitUiReadOnlyComparisonCopyTextOrAdjustDisplaySettings =>
      'Salt okunur karşılaştırma · Metni kopyalayın veya görünümü ayarlayın.';

  @override
  String get gitUiNoFinalNewline => ' · • Son haber yok';

  @override
  String gitUiArg0Arg1Arg2BytesArg3(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return '$arg0 · $arg1 · $arg2 bayt$arg3';
  }

  @override
  String get gitUiTextComparisonIsUnavailableForTheseContents =>
      'Bu içerikler için metin karşılaştırması mevcut değildir.';

  @override
  String get gitUiThisComparisonExceedsTheBoundedTextReviewLimitTheContents =>
      'Bu karşılaştırma, sınırlı metin inceleme sınırını aşmaktadır. içerikler aynı olarak ilan edilmemiştir.';

  @override
  String get gitUiTheComparedContentsAreIdentical =>
      'Karşılaştırılmış içerikler aynıdır.';

  @override
  String get gitUiUnstage => 'Sınavı';

  @override
  String get gitUiStage => 'aşaması';

  @override
  String gitUiArg0ChangedLine(String arg0) {
    return '$arg0 değiştirilmiş çizgi';
  }

  @override
  String get gitUiContext => 'Konteyner';

  @override
  String get gitUiExpandUnchangedContext =>
      'Değişmemiş bir bağlamı genişletmek';

  @override
  String get gitUiUnstageThisHunk => 'Bu parçayı indeksten çıkar';

  @override
  String get gitUiStageThisHunk => 'Bu parçayı indekse ekle';

  @override
  String gitUiEditStagedContentArg0(String arg0) {
    return 'Etiket Arşivi: $arg0';
  }

  @override
  String get gitUiWritingReviewedIndexResult =>
      'Değerlendirilmiş Endeks Sonuçları';

  @override
  String get gitUiHead => 'HEAD';

  @override
  String get gitUiIndex => 'İndeks';

  @override
  String get gitUiWorkingTree => 'Çalışma ağacı';

  @override
  String gitUiHeadArg0(String arg0) {
    return 'HEAD · $arg0';
  }

  @override
  String get gitUiIndexEditableUTF8Blob => 'Etiket Arşivi: UTF-8 Blob';

  @override
  String get gitUiUndo => 'Geri al';

  @override
  String get gitUiRedo => 'Yinele';

  @override
  String get gitUiReloadIndexReview => 'Reload Index İncelemesi?';

  @override
  String get gitUiReloadTheCurrentHEADIndexAndWorkingVersionsThisReplaces =>
      'Geçerli HEAD, indeks ve çalışma sürümlerini yeniden yükleyin. Bu, indeks düzenleyicisindeki kaydedilmemiş taslağı değiştirir.';

  @override
  String get gitUiReplaceDraftAndReload =>
      'Tasarım değiştirmek ve yeniden yüklemek';

  @override
  String get gitUiReloadVersions => 'Reload versiyonu...';

  @override
  String get gitUiWriteEditedResultToThisIndexEntry =>
      'Bu indekslere düzenlenmiş sonuçları yazın';

  @override
  String get gitUiWorkingFilesRemainOnDiskReviewTheEditedIndexBefore =>
      'Çalışma dosyaları diskte kalır. uygulama yapmadan önce düzenlenmiş endeksi inceleyin.';

  @override
  String get gitUiReviewIndexTextFormatChanges =>
      'Etiket Arşivi: index text format değişiklikleri';

  @override
  String gitUiUpdateOnlyTheReviewedIndexEntryForArg0Arg1(
    String arg0,
    String arg1,
  ) {
    return 'Sadece $arg0 için incelenen endeks girişini güncelleme. $arg1';
  }

  @override
  String get gitUiWriteReviewedIndexResult =>
      'Değerlendirilmiş Index Sonuçları';

  @override
  String get gitUiTheEditedResultChangedDuringFormatReviewReviewItAgain =>
      'Format incelemesi sırasında düzenlenmiş sonuç değişti. yeniden incelemek.';

  @override
  String get gitUiSynchronizeScrolling => 'Sinkronizasyon Scrolling';

  @override
  String get gitUiReadOnlyRevisionContent => 'Read-only revize içeriği';

  @override
  String get gitUiEditableIndexContent => 'Endeksi içeriği';

  @override
  String get gitUiTheRequestedRevisionIsOutsideTheCurrentFiltersResetFilters =>
      'Gerekli inceleme mevcut filtrelerin dışındadır. filtreyi yeniden ayarlayın.';

  @override
  String get gitUiFilterLog => 'Filtreler Log';

  @override
  String get gitUiFilters => 'Filtreler...';

  @override
  String gitUiFiltersCount(String count) {
    return 'Filtreler ($count)';
  }

  @override
  String get gitUiMessage => 'İleti…';

  @override
  String get gitUiAuthor => 'Yazar…';

  @override
  String get gitUiPath => 'Yol...';

  @override
  String get gitUiDate => 'Tarih...';

  @override
  String get gitUiMessageFilter => 'Mesaj Filtresi';

  @override
  String get gitUiAuthorFilter => 'Yazar Filtresi';

  @override
  String get gitUiPathFilter => 'Yol Filtresi';

  @override
  String get gitUiMessage2 => 'İleti';

  @override
  String get gitUiAuthor2 => 'Yazar';

  @override
  String get gitUiPath2 => 'Yolu';

  @override
  String get gitUiDateFilter => 'Tarih Filtresi...';

  @override
  String get gitUiResetFilters => 'Reset Filtreler';

  @override
  String get gitUiRefreshLog => 'Renkli Log';

  @override
  String get gitUiGoToCommitReference => 'Konuşma / referans için gidin...';

  @override
  String get gitUiBackToHEAD => 'HEAD\'e dön';

  @override
  String get gitUiOrderedCherryPick => 'Seçilen sırayla cherry-pick';

  @override
  String gitUiReviewCherryPickArg0(String arg0) {
    return 'Çerçeve Çerçeve ($arg0)';
  }

  @override
  String get gitUiCompareTwoSelectedRevisions =>
      'İki seçilmiş incelemeyi karşılaştırın...';

  @override
  String get gitUiToggleBranchesPane => 'Birlikte Şubeler Pan';

  @override
  String get gitUiFilterBranchesAndTags => 'Filtre Şubeleri ve Etiketleri';

  @override
  String gitUiCommitArg0(String arg0) {
    return '$arg0 Yorumları';
  }

  @override
  String get gitUiCommitDetails => 'Detaylı komite...';

  @override
  String gitUiReferenceArg0(String arg0) {
    return 'Etiket: $arg0';
  }

  @override
  String get gitUiSelectThisCommit => 'Bu commiti seç';

  @override
  String get gitUiBranchOrTag => 'Branch veya Tag';

  @override
  String get gitUiAllReferences => 'Tüm referanslar';

  @override
  String get gitUiLocal => 'Yerel';

  @override
  String get gitUiRemote => 'Uzak depo';

  @override
  String get gitUiTags => 'Etiketler';

  @override
  String get gitUiNoCommitsMatchTheCurrentFilters =>
      'Şimdiki filtre ile eşleşen hiçbir komite yoktur.';

  @override
  String get gitUiObjectID => 'Objektif ID';

  @override
  String get gitUiSubjectReferences => 'Konu / Referanslar';

  @override
  String get gitUiDate2 => 'Tarih';

  @override
  String get gitUiGitCommits => 'Git commit’leri';

  @override
  String get gitUiParents => 'Üst commitler';

  @override
  String gitUiArg0Parents(String arg0) {
    return '$arg0 ebeveynler';
  }

  @override
  String get gitUiLoadMoreCommits => 'Daha Fazla Yükümlülük';

  @override
  String get gitUiLoadingChangedFiles => 'değiştirilmiş dosyaları yükleme';

  @override
  String get gitUiNoChangedFiles => 'Değiştirilmemiş dosyalar';

  @override
  String get gitUiSelectACommit => 'Bir komplo seçin';

  @override
  String gitUiCompareParentArg0Arg1(String arg0, String arg1) {
    return 'Karşılaştırma ana $arg0: $arg1';
  }

  @override
  String get gitUiChangedFiles => 'Değişen dosyalar';

  @override
  String gitUiAuthorArg0Arg1Arg2(String arg0, String arg1, String arg2) {
    return 'Yazar: $arg0 <$arg1> $arg2';
  }

  @override
  String gitUiCommitterArg0Arg1Arg2(String arg0, String arg1, String arg2) {
    return 'Komutan: $arg0 <$arg1> $arg2';
  }

  @override
  String get gitUiShallowPartialBoundaryAParentObjectIsUnavailable =>
      'Shallow/partal limit: Bir ana nesne mevcut değildir.';

  @override
  String get gitUiParentIsOutsideThisPageOrAShallowBoundary =>
      'Bu sayfanın dışındadır ya da bir sınır sınırı.';

  @override
  String gitUiParentArg0(String arg0) {
    return 'Üst commit $arg0';
  }

  @override
  String get gitUiCommitActions => 'eylemler için...';

  @override
  String get gitUiEmptyTree => 'Boş ağaç';

  @override
  String get gitUiCreateBranch2 => 'Dal oluştur';

  @override
  String get gitUiCreateTag => 'Etiket oluştur';

  @override
  String get gitUiCompareRevisions => 'Değerlendirmeleri Karşılaştırın';

  @override
  String get gitUiOpenSnapshot => 'Açılış Snapshot';

  @override
  String get gitUiRevertCommit => 'Geri Dönüş';

  @override
  String get gitUiInteractiveRebaseAfterThisBoundary =>
      'Bu sınırdan sonra etkileşimli düşüş';

  @override
  String get gitUiResetCurrentBranch => 'Geçerli dalı sıfırla';

  @override
  String get gitUiCopyFullObjectID => 'Tam Object ID kopyası';

  @override
  String get gitUiGoToCommitReference2 => 'Konuşma / Referans';

  @override
  String get gitUiEnterACommitIDOrReferenceToRevealInLog =>
      'Log\'da ortaya çıkarmak için bir komite kimliği veya referans girin.';

  @override
  String get gitUiTheRequestedRevisionIsUnavailable =>
      'Talep edilen inceleme mevcut değildir.';

  @override
  String
  get gitUiRepositoryMetadataIsReadOnlyBranchInspectionAndComparisonRemain =>
      'Repository metadata sadece okunur. şubelerin incelenmesi ve karşılaştırması mevcuttur.';

  @override
  String get gitUiWorkingFilesAreUnavailableOrReadOnlyBranchSwitchingAnd =>
      'Çalışma dosyaları mevcut değildir veya sadece okunabilir. şubeleri değiştirmek ve birleştirmek mevcut değildir.';

  @override
  String get gitUiSearchBranchesAndTags => 'Dal ve etiket ara';

  @override
  String get gitUiNewBranch => 'Yeni dal…';

  @override
  String get gitUiLocalBranches => 'Yerel dallar';

  @override
  String get gitUiRemoteBranches => 'Uzak dallar';

  @override
  String gitUiTracksArg0(String arg0) {
    return 'Yorumlar $arg0';
  }

  @override
  String gitUiCheckedOutAtArg0(String arg0) {
    return '$arg0 ile ilgili detaylar';
  }

  @override
  String get gitUiRefreshingBranchMetadata => 'Temizleyici metadata';

  @override
  String gitUiSwitchToArg0(String arg0) {
    return '$arg0 için geçiş yapın';
  }

  @override
  String get gitUiOpenOccupiedWorktree => 'Açık işgalci';

  @override
  String get gitUiCreateLocalTrackingBranch =>
      'Yerel izleme şubesi oluşturmak...';

  @override
  String get gitUiCompareToCurrentHEAD => 'Geçerli HEAD ile karşılaştır';

  @override
  String get gitUiMergeIntoCurrentBranch => 'Şimdiki şubelere katılın...';

  @override
  String get gitUiRename => 'Rönesans...';

  @override
  String get gitUiChangeUpstream => 'Upstream değişimi...';

  @override
  String get gitUiDelete => 'Kaldır...';

  @override
  String get gitUiDeleteFromRemote => 'Uzaktan çıkarma...';

  @override
  String gitUiActionsForArg0(String arg0) {
    return '$arg0 için eylem';
  }

  @override
  String get gitUiLocalBranchName => 'Bölge Adı';

  @override
  String gitUiCreateAtArg0TheNewBranchWillBeCheckedOut(String arg0) {
    return '$arg0\'te oluşturun. yeni şubesi kontrol edilecektir.';
  }

  @override
  String gitUiTheLocalBranchWillTrackArg0AndBeCheckedOut(String arg0) {
    return 'Yerel şubesi $arg0\'i izleyecek ve kontrol edilecek.';
  }

  @override
  String get gitUiChooseRemoteForDeletion => 'Deletion için uzaktan seçin';

  @override
  String get gitUiDeleteRemoteReference => 'uzaktan referans kaldırma';

  @override
  String gitUiMergeArg0IntoArg1(String arg0, String arg1) {
    return '$arg0 ile $arg1 arasındaki ilişki';
  }

  @override
  String gitUiRenameArg0(String arg0) {
    return 'İsim: $arg0';
  }

  @override
  String gitUiUpstreamForArg0(String arg0) {
    return '$arg0 için yükseltme';
  }

  @override
  String get gitUiNoUpstream => 'Üst dal yok';

  @override
  String gitUiDeleteArg0(String arg0) {
    return '$arg0 Kaldır mı?';
  }

  @override
  String gitUiArg0TargetArg1LocalDeletionOnlyAnUnmergedBranchIs(
    String arg0,
    String arg1,
  ) {
    return '$arg0 Target $arg1 Yerel kaldırma sadece.';
  }

  @override
  String get gitUiDelete2 => 'Sil';

  @override
  String gitUiDeleteUnmergedBranchArg0(String arg0) {
    return '$arg0\'i silinmeyen şubesi silin mi?';
  }

  @override
  String gitUiArg0GitReportsThisBranchIsNotFullyMergedExplicitly(String arg0) {
    return '$arg0 Git raporları bu şubesi tam olarak birleştirilmemiştir. açıkça yerel referansı görevlerini inceledikten sonra silinir; uzaktan kopyalar değişmez.';
  }

  @override
  String get gitUiDeleteUnmergedLocalBranch =>
      'Kırılmamış yerel şubeleri silin';

  @override
  String gitUiDestinationArg0Arg1(String arg0, String arg1) {
    return 'Konu: $arg0 · $arg1';
  }

  @override
  String get gitUiSourceBranchOrTag => 'Kaynak Şubesi veya Tag';

  @override
  String get gitUiMergePolicy => 'Birleşme Politikası';

  @override
  String get gitUiFastForwardWhenPossible => 'Mümkün olduğunda hızlı ilerleme';

  @override
  String get gitUiAlwaysCreateAMergeCommit =>
      'Her zaman bir ortaklık oluşturun';

  @override
  String get gitUiFastForwardOnly => 'Sadece hızlı ilerleme';

  @override
  String get gitUiSquashIntoStagedChanges => 'Gelişmiş Değişimlere Çıkış';

  @override
  String get gitUiStopBeforeCreatingTheMergeCommit =>
      'Birleşme komitesi oluşturmadan önce durun';

  @override
  String get gitUiFastForwardIsDisabledSoHEADCannotMoveBeforeReview =>
      'İncelemeden önce HEAD\'in taşınmaması için hızlı ilerleme devre dışıdır.';

  @override
  String get gitUiLeavesStagedChangesForASeparateCommitThisIsNot =>
      'Ayrı bir taahhüt için aşamalı değişiklikler bırakın; bu sürekli bir birleşme değildir.';

  @override
  String get gitUiConflictsRemainAvailableInTheSharedResolutionWorkspace =>
      'Çatışmalar ortak çözüm çalışma alanında mevcut kalır.';

  @override
  String get gitUiAddRemote => 'Uzaktan...';

  @override
  String gitUiFetchArg0PushArg1(String arg0, String arg1) {
    return 'FETŞ: $arg0 PUSH: $arg1';
  }

  @override
  String get gitUiRemoveRemote => 'uzaktan kaldırma...';

  @override
  String get gitUiChangeFetchURL => 'URL’yi değiştirmek için...';

  @override
  String get gitUiAddPushDestination => 'Push Destiny’ye katılın...';

  @override
  String get gitUiRemovePushDestination => 'Push Destiny’yi kaldırın.';

  @override
  String gitUiManageArg0(String arg0) {
    return '$arg0 Yönetimi';
  }

  @override
  String get gitUiRemoteName => 'uzaktan isim';

  @override
  String get gitUiNewRemoteName => 'Yeni uzaktan isim';

  @override
  String get gitUiRepositoryURLOrLocalSource => 'URL veya yerel kaynağı';

  @override
  String get gitUiEnterTheExactReviewedDestinationToRemove =>
      'Tam olarak gözden geçirilen hedefe girin kaldırmak için.';

  @override
  String get gitUiCredentialsAreSuppliedByConfiguredHelpersOrAPrivatePrompt =>
      'Sertifikalar konfigürasyonlu yardımcılar veya özel bir prompt tarafından sağlanır.';

  @override
  String gitUiRemoveRemoteArg0(String arg0) {
    return '$arg0 uzaktan kaldırma?';
  }

  @override
  String
  get gitUiRemovesLocalRemoteConfigurationAndTrackingReferencesItDoesNot =>
      'Yerel uzaktan yapılandırma ve izleme referansları kaldırır. sunucu depolama alanını kaldırmaz.';

  @override
  String get gitUiRemoveRemote2 => 'uzaktan kaldırma';

  @override
  String get gitUiCommitScopeEntireRepository =>
      'Etiket Arşivi: tüm depolama alanı';

  @override
  String get gitUiCachedTracking => 'gizli izleme';

  @override
  String get gitUiAmendLastCommit => 'Son commiti değiştir';

  @override
  String get gitUiConfiguredHooksAndSigningAreRespected =>
      'Yapılandırılmış çubuklar ve imza saygılıdır.';

  @override
  String get gitUiRewritesTheSelectedHEADCommitRemoteTrackingCannotProveIt =>
      'Seçili HEAD commit\'ini yeniden yazar. Uzak izleme, yayımlanmamış olduğunu kanıtlayamaz.';

  @override
  String get gitUiRepository => 'Depo';

  @override
  String gitUiDetachedArg0(String arg0) {
    return '$arg0 Çözünürlük';
  }

  @override
  String get gitUiLog => 'Geçmiş';

  @override
  String get gitUiRepositoryActions => 'Depo işlemleri';

  @override
  String gitUiCachedTrackingUpstreamAheadAheadBehindBehind(
    String upstream,
    String ahead,
    String behind,
  ) {
    return 'Önbellekteki izleme · $upstream · $ahead ileride · $behind geride';
  }

  @override
  String get gitUiBareRepositoryNoWorkingTreeOpenLogToInspectIts =>
      'Sadece depolama alanı · iş ağaçları yok. tarihini kontrol etmek için Kayıt açın.';

  @override
  String get gitUiReadOnlyRepositoryStagingAndCommitsAreUnavailable =>
      'Sadece okuma depolama alanı · staging ve komitler mevcut değildir.';

  @override
  String get gitUiRepositoryStatusUnavailable =>
      'Depolama Durumu Kullanılamıyor';

  @override
  String gitUiAmendRevision(String revision) {
    return '$revision değiştirme';
  }

  @override
  String get gitUiAddSignOffTrailer => 'Onay satırı ekle';

  @override
  String get gitUiUseConfiguredSigningPolicy =>
      'Konfigüratlı imza politikası kullanın';

  @override
  String get gitUiCryptographicallySignThisCommit =>
      'Bu komiteyi kripto olarak imzalamak';

  @override
  String get gitUiDoNotSignThisCommit => 'Bu sözleşmeyi imzalamayın';

  @override
  String get gitUiRecentCommitMessages => 'Son mesajlar...';

  @override
  String get gitUiUseConfiguredCommitTemplate =>
      'Şablonu kullanarak yapılandırılmış komite...';

  @override
  String get gitUiAuthorIdentityAndConfiguredHooks =>
      'Yazarın kimliği ve konfigürat hooks...';

  @override
  String get gitUiDraftMessage => 'Mesaj Tasarımı...';

  @override
  String get gitUiCommitOptions => 'Commit seçenekleri';

  @override
  String gitUiDraftRetainedInMemorySavingItFailedArg0(String arg0) {
    return 'Tasarım hafızada tutuluyor; kurtarma başarısız oldu. $arg0';
  }

  @override
  String get gitUiCommitMessage => 'Commit iletisi';

  @override
  String get gitUiGitOperationInProgress => 'Git Operasyon Gelişiyor';

  @override
  String get gitUiCancel => 'İptal';

  @override
  String get gitUiAmendStaged => 'Değişiklik Yapıldı';

  @override
  String gitUiCommitStagedCount(String count) {
    return 'İndeksteki değişiklikleri commitle ($count)';
  }

  @override
  String get gitUiCommitAndPush => 'Commit oluştur ve gönder…';

  @override
  String get gitUiNoReadableCommitTemplateIsConfigured =>
      'Okunabilir komut şablonu ayarlanmamıştır.';

  @override
  String get gitUiCommitIdentityAndHooks => 'Komite kimliği ve hooks';

  @override
  String get gitUiRecentMessages => 'Son mesajlar';

  @override
  String get gitUiReplaceMessageDraft => 'Mesaj Tasarımı Değiştirmek?';

  @override
  String get gitUiReplaceTheExistingCommitMessageWithTheSelectedMessage =>
      'Mevcut komite mesajını seçilmiş mesajla değiştirmek mi?';

  @override
  String get gitUiReplaceDraft => 'Tasarım Değiştirme';

  @override
  String gitUiLocalCommitArg0Exists(String arg0) {
    return 'Yerel komut $arg0 mevcuttur.';
  }

  @override
  String gitUiLocalCommitArg0ExistsReviewLogBeforeAttemptingAnotherCommit(
    String arg0,
  ) {
    return 'Yerel komite $arg0 mevcuttur. başka bir komite denemeden önce kaydolun. mesaj taslağı korunmuştur.';
  }

  @override
  String get gitUiCommitAuthorName => 'Yazar Adı';

  @override
  String get gitUiCommitAuthorEmail => 'E-posta Yazarın Sözleri';

  @override
  String get gitUiConfiguredDefault => 'default yapılandırma';

  @override
  String get gitUiOpenpgp => 'OpenPGP';

  @override
  String gitUiSigningArg0Arg1(String arg0, String arg1) {
    return 'Kayıt: $arg0 · $arg1';
  }

  @override
  String gitUiConfiguredHooksArg0(String arg0) {
    return 'Şekil: $arg0';
  }

  @override
  String get gitUiASignOffTrailerIsAStatementInTheMessage =>
      'Onay satırı iletideki bir beyandır; kriptografik imzadan ayrıdır. Kimlik yalnızca bu deponun yerel yapılandırmasına kaydedilir; taslak korunur.';

  @override
  String get gitUiSaveRepositoryIdentity => 'Depolama kimliğini kaydetmek';

  @override
  String get gitUiStaged => 'İndekste';

  @override
  String get gitUiUntracked => 'İzlenmeyen';

  @override
  String get gitUiUnstaged => 'İndeks dışında';

  @override
  String get gitUiConflicts => 'Çakışmalar';

  @override
  String get gitUiNoChanges => 'Değişiklik yok';

  @override
  String get gitUiRepositoryChangeTree => 'Ağaç Değişimi';

  @override
  String get gitUiChanges => 'Değişiklikler';

  @override
  String gitUiGroupCount(String group, String count) {
    return '$group ($count)';
  }

  @override
  String get gitUiExpand => 'Genişletme';

  @override
  String get gitUiCollapse => 'çöküş';

  @override
  String get gitUiUnstageFile => 'Dosyayı indeksten çıkar';

  @override
  String get gitUiStageFile => 'Dosyayı indekse ekle';

  @override
  String get gitUiExpandGroup => 'Genişletme grubu';

  @override
  String get gitUiCollapseGroup => 'çöküş grubu';

  @override
  String get gitUiReviewDifference => 'Farklılıklar incelemesi';

  @override
  String get gitUiUnstageSelectedFiles => 'Seçili dosyaları indeksten çıkar';

  @override
  String get gitUiStageSelectedFiles => 'Seçili dosyaları indekse ekle';

  @override
  String get gitUiFileHistoryAndBlame => 'Dosya Tarihi ve Suç...';

  @override
  String get gitUiDeleteUntrackedFile => 'Untracked dosyaları silin...';

  @override
  String get gitUiDiscardUnstagedChange => 'Sıkıntılı bir değişim...';

  @override
  String get gitUiFileHistory => 'Dosya geçmişi';

  @override
  String gitUiDiscardUnstagedArg0(String arg0) {
    return '$arg0\'i kaybeder mi?';
  }

  @override
  String gitUiArg0BytesArg1ReplacesWorkingContentWithTheIndexOr(
    String arg0,
    String arg1,
  ) {
    return '$arg0 bytes · $arg1 iş içeriğini endeksle değiştirir veya bu izinsiz dosyayı silir.';
  }

  @override
  String get gitUiDeleteUntrackedFile2 => 'Untracked dosyaları silin';

  @override
  String get gitUiDiscardWorkingChange => 'Çalışma Değişikliği';

  @override
  String gitUiDeleteREMOTEReferenceArg0(String arg0) {
    return '$arg0 referansını kaldırın';
  }

  @override
  String get gitUiThisRemovesTheReferenceOnEveryActualPushDestinationListed =>
      'Bu, aşağıda listelenen her gerçek push destinasyonu için referans kaldırır. yerel şubeler / etiketler korunur. beklenen ipuçları bu inceleme ile belirlenir.';

  @override
  String get gitUiReferenceDoesNotExist => 'Referans yok';

  @override
  String gitUiArg0ExpectedTipArg1(String arg0, String arg1) {
    return '$arg0 beklenen ipucu: $arg1';
  }

  @override
  String get gitUiRemoteDeletionCompleted => 'Uzaktan kaldırma tamamlandı.';

  @override
  String gitUiDeleteArg0FromTheRemote(String arg0) {
    return '$arg0 uzaktan silinir mi?';
  }

  @override
  String get gitUiTheExactDestinationTipsShownAboveWillBeRemovedAny =>
      'Yukarıda belirtilen doğru hedef ipuçları kaldırılacaktır. herhangi bir değiştirilmiş uzaktan ipuçları başka bir inceleme için işlemi durdurur.';

  @override
  String get gitUiReviewAndDeleteFromRemote => 'Yorum ve uzaktan silin...';

  @override
  String get gitUiDestinationReference => 'Destinasyon Referansları';

  @override
  String get gitUiReviewDestinations => 'Değerlendirme Hedefleri';

  @override
  String get gitUiNewRemoteBranch => 'Yeni uzaktan şubeler';

  @override
  String gitUiArg0Arg1ExpectedArg2(String arg0, String arg1, String arg2) {
    return '$arg0\n$arg1 · beklenen: $arg2';
  }

  @override
  String get gitUiADestinationHasCommitsThatAreUnavailableLocallyFetchThat =>
      'Bir varış noktası yerel olarak mevcut olmayan eylemler vardır. Fetch varış tarihi incelemeden önce varış noktası inceledi.';

  @override
  String get gitUiFetchReviewedDestination => 'FETCH YÖNETİM YÖNETİMİ';

  @override
  String get gitUiChooseADestinationAndReviewTheOutgoingCommits =>
      'Bir hedef seçin ve çıkış görevlerini inceleyin.';

  @override
  String get gitUiNoOutgoingCommits => 'Hiçbir çıkış sözleri';

  @override
  String get gitUiSelectAnOutgoingCommit => 'Bir çıkış komitesi seçin';

  @override
  String get gitUiLoadMoreOutgoingCommits => 'Daha Fazla Yükümlülükler';

  @override
  String get gitUiSetThisDestinationAsUpstream =>
      'Bu hedefi upstream olarak ayarlayın';

  @override
  String get gitUiChooseExactTagsToPublish =>
      'Yayınlamak için doğru etiketleri seçin';

  @override
  String get gitUiTagsNone => 'Etiket: hiç';

  @override
  String gitUiTagsArg0Selected(String arg0) {
    return 'Etiketler: $arg0 seçilmiş';
  }

  @override
  String gitUiPublishExactlyArg0(String arg0) {
    return 'Etiket Arşivi: $arg0';
  }

  @override
  String get gitUiPushCompletedTheLocalCommitRemainsAvailableInLog =>
      'Push tamamlandı. yerel komutlar Log\'da mevcut kalır.';

  @override
  String get gitUiForceRequiresTheExactDestinationTipsShownInThisReview =>
      'Zorlamalı gönderim için hedef referans uçları bu incelemede gösterilenlerle tam eşleşmelidir.';

  @override
  String get gitUiForceWithReviewedLease => 'Değerlendirilmiş kiralık...';

  @override
  String get gitUiPush => 'Gönder';

  @override
  String get gitUiForcePushWithReviewedLeases =>
      'Geri dönüştürülmüş kiralama ile güç basıncı?';

  @override
  String gitUiRewriteArg0OnlyIfEveryRemoteDestinationStillHasThe(String arg0) {
    return '$arg0\'i yalnızca her uzaktan varış noktası yukarıda gösterilen doğru noktaya sahipse yeniden yazın.\n';
  }

  @override
  String get gitUiOtherPeopleMayAlreadyUseThisHistoryABackgroundFetch =>
      'Başkaları bu geçmişi kullanıyor olabilir. Arka planda veri getirmek bu güvenlik koşulunu yenilemez.';

  @override
  String get gitUiForceWithLease => 'Kiralık Güç';

  @override
  String
  get gitUiTheRemoteOutcomeIsUncertainReviewDestinationsAgainBeforeAnother =>
      'Uzaktan sonuç belirsizdir. başka bir baskı öncesinde tekrar hedefleri inceleyin.';

  @override
  String gitUiParentArg0Arg1(String arg0, String arg1) {
    return '$arg0 · $arg1';
  }

  @override
  String get gitUiRemoteToFetch => 'FETCH için uzaktan';

  @override
  String get gitUiPruneDeletedRemoteTrackingBranches =>
      'Remote Tracking Şubeleri Kaldırıldı';

  @override
  String
  get gitUiFetchUpdatesRemoteTrackingInformationWithoutReplacingWorkingFiles =>
      'Fetch, çalışma dosyalarını değiştirmeden uzaktan izleme bilgileri güncelleştirir.';

  @override
  String get gitUiFetch => 'Getir';

  @override
  String get gitUiSourceRemote => 'Uzaktan Kaynak';

  @override
  String get gitUiSourceBranch => 'Kaynak Şubesi';

  @override
  String get gitUiReviewedStrategy => 'Strateji Değiştirme';

  @override
  String get gitUiMerge => 'Birleştir';

  @override
  String get gitUiRebase => 'Yeniden temellendir';

  @override
  String get gitUiStopIfTheDestinationCannotFastForwardNeverMergeOr =>
      'Hedef hızla ilerleyemezse durdurun; asla birleşme veya düşme.';

  @override
  String get gitUiMergeWithAMergeCommitIncludingWhenFastForwardIs =>
      'Birleşme komplo ile birleşin, hatta hızlı ilerleme mümkün olduğunda.';

  @override
  String get gitUiMergeAllowFastForwardWhenPossible =>
      'Mümkün olduğunda hızlı ilerlemeye izin verin.';

  @override
  String get gitUiRebaseLocalHistoryWhilePreservingLocalMergeCommits =>
      'Yerel birleşme eylemlerini korurken yerel tarihini yeniden canlandırın.';

  @override
  String get gitUiRebaseLocalCommitsAsALinearHistory =>
      'Yerel eylemleri lineer bir tarih olarak ele alalım.';

  @override
  String get gitUiGitIsConfiguredForInteractiveRebaseSelectAPullStrategy =>
      'Burada açıkça bir çekme stratejisi seçin veya bir planı incelemek için bir çekme stratejisi açın.';

  @override
  String get gitUiUseReviewedOrdinaryRebaseForThisPull =>
      'Bu çekim için incelenen sıradan basın kullanın';

  @override
  String get gitUiOptions => 'Seçenekler';

  @override
  String get gitUiAlwaysCreateAMergeCommitNoFastForward =>
      'Her zaman bir kombinasyon komitesi oluşturun (hızlı ilerleme yok)';

  @override
  String get gitUiPreserveLocalMergeCommits => 'Yerel Birleşme Sözleşmeleri';

  @override
  String get gitUiLocalChangesMayPreventPullReviewCommitThemOrExplicitly =>
      'Yerel değişiklikler çekmeyi engelleyebilir. inceleme / sipariş verin veya açıkça bir çubuk oluşturun.';

  @override
  String get gitUiStashes => 'Saklanan değişiklikler';

  @override
  String get gitUiCreateOrReviewStash => 'Stash oluşturmak veya incelemek...';

  @override
  String get gitUiPullWithSelectedStrategy =>
      'Seçilmiş strateji ile karıştırın';

  @override
  String get gitUiRepositoryURLOrLocalGitSource => 'URL veya yerel Git kaynağı';

  @override
  String get gitUiHttpsSSHOrLocalPath => 'HTTPS, SSH veya yerel yol';

  @override
  String get gitUiFolderToInitialize => 'Başlangıç için Folder';

  @override
  String get gitUiFinalCloneDestination => 'Son Klon Yeri';

  @override
  String get gitUiChoose => 'Seçin...';

  @override
  String get gitUiCreatesGitMetadataOnlyExistingFilesAreNotStagedOr =>
      'Yalnızca metadata oluşturur. mevcut dosyaları çizilmez veya yapıştırılmaz.';

  @override
  String get gitUiTheFinalDestinationMustBeAbsentOrEmptyExistingUser =>
      'Son hedef mevcut olmamalı veya boş olmalıdır. Kullanıcının mevcut verilerinin üzerine asla yazılmaz.';

  @override
  String get gitUiInitialBranchBlankUsesEffectiveGitPolicy =>
      'Başlangıç şubesi · beyaz etkili Git politikası kullanır';

  @override
  String get gitUiSelectedBranchOptional => 'Seçilmiş Şubeler · Seçmeli';

  @override
  String get gitUiExplicitlyInitializeUpdateSubmodulesRecursively =>
      'Açıklama / güncelleştirme submodüllerini tekrar tekrar';

  @override
  String get gitUiPreparingGitOperation => 'Git operasyonu için hazırlık...';

  @override
  String get gitUiThisAttemptCreated => 'Bu girişim yaratılmış';

  @override
  String get gitUiTheDestinationExistedBeforeThisAttempt =>
      'Bu denemeden önce var olan hedef:';

  @override
  String get gitUiTheDirectoryRemainsForInspectionReviewItBeforeAnotherClone =>
      'Klavye muayene için kalır. başka bir klon denemesi öncesinde inceleme.';

  @override
  String get gitUiNoDestinationDirectoryRemains => 'Amaç adresi kalmadı.';

  @override
  String get gitUiCancelProcess => 'İptal Süreci';

  @override
  String get gitUiInitialize => 'Başlat';

  @override
  String get gitUiClone => 'Klonla';

  @override
  String get gitUiChooseNewBase => 'Yeni tabanı seç';

  @override
  String get gitUiChooseUpstreamBoundary => 'Üst sınırı seç';

  @override
  String get gitUiNewBase => 'Yeni taban';

  @override
  String get gitUiUpstreamBoundaryExcluded => 'Üst sınır · hariç';

  @override
  String get gitUiSameAsUpstreamBoundary => 'Üst sınırla aynı';

  @override
  String get gitUiChooseBranchTagOrCommit => 'Dal, etiket veya commit seç…';

  @override
  String get gitUiUseUpstreamAsNewBase =>
      'Upstream\'i yeni bir temel olarak kullanın';

  @override
  String get gitUiChooseAValidBranchTagOrCommitFromLog =>
      'Geçerli bir şubesi seçin, etiketle veya Log\'dan bağlayın.';

  @override
  String get gitUiTheFirstRetainedCommitInABranchBlockCannotSquash =>
      'Dal bloğunda tutulan ilk commit squash veya fixup olamaz; öncesinde hedef commit yoktur.';

  @override
  String gitUiBranchBlockArg0(String arg0) {
    return 'Çiftlik Bloku $arg0\n';
  }

  @override
  String get gitUiRewordWillRequestANewMessage =>
      '[Reword yeni bir mesaj isteyecektir]\n';

  @override
  String get gitUiPlannedCommitMessages => 'Planlanan Mesajlar';

  @override
  String
  get gitUiOriginalCombinedMessagePreviewGitRequestsTheFinalRewordSquash =>
      'Orijinal/kombin mesaj önizlemesi · Git son reword/squash mesajları isteyin';

  @override
  String gitUiResultArg0Arg1(String arg0, String arg1) {
    return 'Sonuçlar $arg0 $arg1';
  }

  @override
  String gitUiCurrentBranchBranch(String branch) {
    return 'Geçerli dal: $branch';
  }

  @override
  String get gitUiDetachedHEAD2 => 'Ayrık HEAD';

  @override
  String
  get gitUiRebaseRewritesCommitIdentitiesRemoteTrackingInformationCannotProveHistory =>
      'Yeniden temellendirme commit kimliklerini değiştirir. Uzak dal izleme bilgileri, geçmişin hiç yayımlanmadığını kanıtlamaz.';

  @override
  String get gitUiIncludeRootCommits => 'Kök commitleri dahil et';

  @override
  String get gitUiMergeCommits => 'Birleşme Sözleşmeleri';

  @override
  String get gitUiFlattenHistory => 'Geçmişi düzleştir';

  @override
  String get gitUiPreserveBranchStructure => 'Dal yapısını koru';

  @override
  String get gitUiAutosquash => 'Otomatik birleştirme';

  @override
  String get gitUiPrepareGitPlan => 'Git planını hazırla';

  @override
  String gitUiCommitsToReplayCount(String count) {
    return 'Yeniden uygulanacak commit’ler: $count';
  }

  @override
  String get gitUiIncludesAllRootCommitsReachableFromThisBranch =>
      'Bu şubeden elde edilebilecek tüm kök komiteleri içerir.';

  @override
  String gitUiCommitsAfterBoundaryWillBeReplayedOntoBaseTheBoundary(
    String boundary,
    String base,
  ) {
    return '$boundary sonrasındaki commitler $base üzerine yeniden uygulanır; sınır commiti dahil edilmez.';
  }

  @override
  String get gitUiRoot => 'kökü';

  @override
  String get gitUiGitBranchLabelResetMergeStructure =>
      'Git şubesi / etiket / yeniden ayar / karıştırma yapısı';

  @override
  String get gitUiChooseAnExplicitOldBoundaryOrRootModeThenPrepare =>
      'Açıkça eski sınır veya kök modunu seçin, sonra planı hazırlayın.';

  @override
  String get gitUiMoveUp => 'Yukarı taşı';

  @override
  String get gitUiMoveDown => 'Aşağı taşı';

  @override
  String get gitUiResetPlan => 'Planı sıfırla';

  @override
  String gitUiBranchBlockArg02(String arg0) {
    return ' · Şubesi blok $arg0';
  }

  @override
  String get gitUiSelectACommitForDetailsAndChangedFiles =>
      'Detaylar için bir komite seçin ve dosyaları değiştirin';

  @override
  String get gitUiPreviewCombinedCommitMessages =>
      'Önceki Önceki yazı: Combined Commit Messages...';

  @override
  String get gitUiAltMovesTheSelectedCommitUnrelatedBranchReferencesWillNot =>
      'Alt+ ↑/↓ seçilen komutu hareket eder. Bağlantısız şubelerin referansları otomatik olarak güncellenmez.';

  @override
  String get gitUiCancelPlan => 'Planı iptal';

  @override
  String get gitUiStartReviewedRebase => 'İncelenen rebase başlatılsın mı?';

  @override
  String gitUiRewriteArg0PlannedCommitsOnArg1DroppedCommitsRemainVisibly(
    String arg0,
    String arg1,
  ) {
    return '$arg0 üzerinde planlanan komutları yeniden yazın $arg1. Dökülen komutlar, başlangıç yapana kadar bu planta görünür bir şekilde işaretlenir.';
  }

  @override
  String get gitUiStartRebase => 'Yeniden temellendirmeyi başlat';

  @override
  String get gitUiNoContinuingGitOperation => 'Git operasyonu devam etmiyor';

  @override
  String get gitUiStoppedForEditingAmend =>
      ' · düzenleme / değişiklik için durduruldu';

  @override
  String get gitUiTheseAreUnmergedIndexEntriesPossiblyFromAStashApplication =>
      'Bunlar bir stash uygulamasından, muhtemelen bir indeksleme girişidir. Git\'in hiçbir stash devamı veya kürtaj komutu yoktur.';

  @override
  String get gitUiEditTheWorkingFilesStageAndAmendTheCurrentCommit =>
      'Çalışma dosyalarını düzenleyin, aşamayı ve mevcut yükümlülüğünü değiştirin, sonra bu yükümlülüğü devam edin.';

  @override
  String gitUiArg0Arg1UnmergedStagesArg2(
    String arg0,
    String arg1,
    String arg2,
  ) {
    return '$arg0$arg1 · birleştirilmemiş indeks aşamaları $arg2';
  }

  @override
  String get gitUiTheIndexHasNoUnresolvedEntries =>
      'Endeksi çözülmemiş girişlere sahip değildir.';

  @override
  String get gitUiKeepTheCurrentCommitAsAnEmptyCommit =>
      'Mevcut taahhütü boş bir taahhüt olarak tutun';

  @override
  String get gitUiTheRealIndexHasNoStagedChangesCreateAnExplicit =>
      'Gerçek endeksin aşamalı değişiklikleri yoktur. açık bir boş komplo oluşturun, eğer aktif kalırsa sekencer\'ı devam edin.';

  @override
  String get gitUiKeepEmptyCommit => 'Boş tutun...';

  @override
  String get gitUiGitWillTryToReturnToTheOperationSStarting =>
      'Git işlemin başlangıcına dönmeyi dener. Önceden var olan indeks dışı değişikliklerin, izlenmeyen ve kaydedilmemiş içeriğin kurtarılması garanti edilmez.';

  @override
  String get gitUiSkipTheCurrentCommitAndContinueWithTheNextPlanned =>
      'Mevcut komployu atlayın ve bir sonraki planlanan komplo ile devam edin.';

  @override
  String
  get gitUiForgetThisOperationSBookkeepingWhileRetainingTheCurrentFiles =>
      'Mevcut dosyaları ve indeksleri korurken bu operasyonun kitap tutmayı unutun.';

  @override
  String gitUiContinueArg0(String arg0) {
    return '$arg0 İndir';
  }

  @override
  String get gitUiReloadConflictVersions => 'Çatışma versiyonları?';

  @override
  String get gitUiReplaceTheUnsavedResultDraftWithTheCurrentWorkingFile =>
      'Kurtarılmamış Sonuç taslağını mevcut çalışma dosyası ile değiştirin.';

  @override
  String get gitUiLoadingConflictVersions => 'Çatışma versiyonları...';

  @override
  String get gitUiLoadingConflict => 'Kargo çatışması';

  @override
  String get gitUiBaseLeft => 'bazı sol';

  @override
  String get gitUiBaseRight => 'Temel haklı';

  @override
  String get gitUiNoBaseEntryForThisConflict => 'Bu çatışmanın temeli yok';

  @override
  String get gitUiAcceptEntireLeftFile => 'Tüm sol dosyayı kabul edin...';

  @override
  String get gitUiAcceptEntireRightFile =>
      'Sağdaki dosyanın tamamını kabul et…';

  @override
  String get gitUiPreviousConflictRegion => 'Önceki İçerikSaldırı Bölgesi';

  @override
  String get gitUiNextConflictRegion => 'Sonraki çatışma bölgesi';

  @override
  String get gitUiManualResolution => 'Manual Çözüm';

  @override
  String gitUiRegionArg0Arg1Arg2Reviewed(
    String arg0,
    String arg1,
    String arg2,
  ) {
    return 'Bölge $arg0/$arg1 · $arg2 incelenmiş';
  }

  @override
  String
  get gitUiSourceAlignmentExceededTheTextComparisonLimitSourcePanesRemain =>
      'Kaynak uyumluluğu metin karşılaştırma sınırını aştı; kaynak panoları manuel inceleme için kullanılabilir kalır.';

  @override
  String get gitUiAcceptLeftRegion => 'Sol bölgeyi kabul et';

  @override
  String get gitUiAcceptRightRegion => 'Doğru bölgeyi kabul edin';

  @override
  String get gitUiKeepManualResultForRegion => 'Bölge için manuel sonuç tutun';

  @override
  String get gitUiApplyGitSNonConflictingChanges =>
      'Git’in çatışmaz değişikliklerini uygulayacak mı?';

  @override
  String get gitUiReplaceTheCurrentResultDraftWithGitSMergePreview =>
      'Geçerli sonuç taslağını Git\'in birleşme önizlemesi ile değiştirin. bu kaydedilmemiş manuel sonuç düzenlemelerini ortadan kaldırır; çalışma dosyası kaydedene kadar değişmez.';

  @override
  String get gitUiUseMergePreview => 'Birleşme Önizlemesi';

  @override
  String get gitUiApplyNonConflictingChanges =>
      'Karşıt olmayan değişiklikler...';

  @override
  String get gitUiLeftSource => 'sol kaynağı';

  @override
  String get gitUiResult => 'Sonuç';

  @override
  String get gitUiRightSource => 'Doğru kaynak';

  @override
  String get gitUiStage2 => 'Sezon 2';

  @override
  String get gitUiStage3 => '3 aşaması';

  @override
  String
  get gitUiConflictVersionsAreUnavailableRefreshToReviewTheirCurrentState =>
      'Çatışma versiyonları mevcut değildir. mevcut durumunu gözden geçirmek için yenileme.';

  @override
  String get gitUiResultSavedToDiskTheIndexStillDeterminesWhetherThis =>
      'Sonuç diske kaydedildi. endeks hala bu dosyanın çözüldüğünü belirler.';

  @override
  String get gitUiSaveResultDraft => 'Sonuç taslağını kaydet';

  @override
  String get gitUiApplyResultAndStageResolution =>
      'Sonucu uygula ve çözümü indekse ekle';

  @override
  String get gitUiResultEditableUTF8WorkingContent =>
      'Sonuç · düzenlenebilir UTF-8 çalışma içeriği';

  @override
  String get gitUiEditableConflictResult => 'Saldırı sonuçları';

  @override
  String gitUiLeftArg0Arg1RightArg2Arg3(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return 'Sol: $arg0 · $arg1\nSağ: $arg2 · $arg3';
  }

  @override
  String get gitUiChooseContentDeletionOrASubmoduleCommitExplicitlyNoBinary =>
      'İçeriği seçin, silin, ya da bir alt modül açıkça taahhüt. hiçbir ikili veri düzenlenebilir metin olarak dekore edilmez.';

  @override
  String get gitUiUseEntireLeftContent => 'Tüm sol içeriği kullanın...';

  @override
  String get gitUiUseEntireRightContent => 'Sağdaki içeriğin tamamını kullan…';

  @override
  String get gitUiDeleteThisPath => 'Bu yolun ortadan kaldırılması...';

  @override
  String get gitUiResolvedSubmoduleCommit => 'Çözülen alt modül';

  @override
  String get gitUiStageThisExactGitlinkInTheParentThisDoesNot =>
      'Bu doğru gitlink\'i ebeveynin içine koyun. bu, alt modülü kontrol etmez veya taahhüt etmez.';

  @override
  String get gitUiSetResolvedGitlink => 'Çözülen gitlink...';

  @override
  String gitUiBaseStageArg0(String arg0) {
    return 'Temel → aşama $arg0';
  }

  @override
  String get gitUiTheResultWasEditedKeepTheManualResultOrSelect =>
      'Sonuç düzenlenmiştir. manuel sonucu tutun veya değişmemiş bir bölge seçin.';

  @override
  String gitUiApplyArg0Resolution(String arg0) {
    return '“$arg0” çözümü uygulansın mı?';
  }

  @override
  String get gitUiStageTheChosenGitlinkCommitInTheParentTheSubmodule =>
      'Seçilen gitlink\'i ana bölümde yerleştirin. alt modül kontrolü ve dosyaları değiştirilmez.';

  @override
  String gitUiReplacesTheEntireWorkingPathArg0AndStagesTheDecision(
    String arg0,
  ) {
    return '$arg0 tüm çalışma yolu değiştirir ve kararın aşamasıdır. mevcut çalışma içeriği ve kayıp sonuç taslağı kaldırılacaktır.';
  }

  @override
  String get gitUiApplyEntireFileDecision => 'Tüm dosya kararını uygulayın';

  @override
  String get gitUiStageThisConflictResolution =>
      'Bu anlaşmazlık çözümü için mi?';

  @override
  String gitUiUseTheEntireEditedResultAsArg0GitRecordsThe(
    String arg0,
    String arg1,
  ) {
    return 'Tüm düzenlenmiş Sonuçları $arg0 olarak kullanın. $arg1 ilk olarak tüm amaçlı içeriği inceleyin.';
  }

  @override
  String get gitUiApplyAndStage => 'Uygula ve indekse ekle';

  @override
  String get gitUiReviewResultTextFormatChanges =>
      'Sonuçları incelemek metin biçimi değişiklikleri';

  @override
  String get gitUiSaveReviewedResult => 'Değerlendirilmiş sonuçları kaydedin';

  @override
  String
  get gitUiNativeGitTableAccessibilityIsUnavailableRetryAfterReconnectingThe =>
      'Native Git tablosu erişilebilirliği mevcut değildir. uygulama yeniden bağlandıktan sonra geri çekilme.';

  @override
  String get gitUiSans => 'olmadan';

  @override
  String get gitUiSelect => 'Seçim';

  @override
  String get gitUiContextMenu => 'Konteyner Menüsü';

  @override
  String get gitUiCopyText => 'kopyalanmış metin';

  @override
  String get gitUiLoadingRow => 'Yükleme Sırası';

  @override
  String get gitUiRetry => 'Yeniden dene';

  @override
  String get gitUiGitMessage => 'Git Mesajı';

  @override
  String get gitUiCancelPrompt => 'Hızlı İptal';

  @override
  String get gitUiUseMessageAndContinue => 'Mesajı kullanın ve devam edin';

  @override
  String get gitUiRespondPrivately => 'Özel cevaplar';

  @override
  String gitUiViewPreferencesCouldNotBeSavedArg0(String arg0) {
    return 'Görüntüleme tercihleri kaydedilemez: $arg0';
  }

  @override
  String gitUiCommitDraftStorageArg0(String arg0) {
    return 'Etiket Arşivi: $arg0';
  }

  @override
  String gitUiViewPreferencesCouldNotBeReadArg0(String arg0) {
    return 'Görüntüleme tercihleri okunamazdı: $arg0';
  }

  @override
  String gitUiCommitDraftWasRetainedInMemoryButCouldNotBe(String arg0) {
    return 'Komite taslağı hafızada tutuluyordu ama kurtarılamıyordu: $arg0';
  }

  @override
  String get gitUiTheReviewedRepositoryIsReadOnlyForThisOperationHistory =>
      'Değerlendirilmiş depolama alanı sadece bu işlem için okunabilir. tarih ve içerik denetimi mevcuttur.';

  @override
  String gitUiGitReturnedArg0TheApplicationCouldNotRefreshItsDocuments(
    String arg0,
    String arg1,
  ) {
    return 'Git $arg0\'i iade etti. uygulama belgelerini yenilemezdi: $arg1';
  }

  @override
  String get gitUiSelectCommitInLog => 'Geçmişten commit seç…';

  @override
  String get gitUiCurrentBranch => 'Geçerli dal';

  @override
  String get gitUiNoMatchingBranchesOrTagsSelectACommitInLog =>
      'Hiçbir şubesi veya etiket eşleşmiyor.Log\'da bir komite seçin.';

  @override
  String get gitUiBranches => 'Dallar';

  @override
  String get gitUiPushCommits => 'Commitleri gönder';

  @override
  String gitUiPullIntoArg0(String arg0) {
    return '$arg0 içine girin';
  }

  @override
  String gitUiResolveArg0(String arg0) {
    return 'Çözünür $arg0';
  }

  @override
  String get gitUiCurrentOperation => 'Şimdiki operasyon';

  @override
  String get gitUiRebaseCommits => 'Commitleri yeniden temellendir';

  @override
  String get gitUiFetch2 => 'Getir…';

  @override
  String get gitUiPull => 'Çek…';

  @override
  String get gitUiPush2 => 'Gönder…';

  @override
  String get gitUiBranches2 => 'Dallar…';

  @override
  String get gitUiManageRemotes => 'Uzak depoları yönet…';

  @override
  String gitUiMergeIntoArg0(String arg0) {
    return '$arg0’e katılın';
  }

  @override
  String get gitUiRebase2 => 'Yeniden temellendir…';

  @override
  String get gitUiConflictsAndCurrentOperation =>
      'Çatışmalar ve mevcut operasyonlar...';

  @override
  String get gitUiStashes2 => 'Saklanan değişiklikler…';

  @override
  String get gitUiWorktrees => 'Çalışma ağaçları…';

  @override
  String get gitUiSubmodules => 'Alt modüller…';

  @override
  String get gitUiReflogAndRecovery => 'Reflog ve kurtarma…';

  @override
  String get gitUiCloneRepository => 'Depoyu klonla…';

  @override
  String get gitUiRevokeRepositoryTrust => 'Depoya duyulan güveni geri al';

  @override
  String get gitUiWaitingForRepositoryStatus => 'Depozito Durumu için bekleyin';

  @override
  String get gitUiRepositoryStatusUnavailableRefresh =>
      'Depolama durumu mevcut değildir; yenileme';

  @override
  String get gitUiManageRemotes2 => 'Uzak depoları yönet';

  @override
  String gitUiMergeIntoArg02(String arg0) {
    return '$arg0 ile bağlantı kurun';
  }

  @override
  String get gitUiWorktrees2 => 'Çalışma ağaçları';

  @override
  String get gitUiSubmodules2 => 'Alt modüller';

  @override
  String get gitUiReflogAndRecovery2 => 'Reflog ve kurtarma';

  @override
  String gitUiCloneRepositoryArg0(String arg0) {
    return 'Klon depolama alanı · $arg0';
  }

  @override
  String get gitUiApply => 'Uygula';

  @override
  String get gitUiResizeGitPanes => 'Git paneler';

  @override
  String gitUiArg0Percent(String arg0) {
    return '$arg0 Yüzde';
  }

  @override
  String gitUiExitStatusStatus(String status) {
    return 'çıkış durumu: $status';
  }

  @override
  String get gitUiRepositoryChangedRefreshAndReviewBeforeTryingAgain =>
      'Repository değiştirildi. yeniden denemeden önce yenileme ve inceleme.';

  @override
  String get gitUiAnotherOperationHoldsTheRepositoryOrIndexLockWaitThen =>
      'Bir başka işlem depolama alanı veya indeksleme kilidi tutar. bekle, sonra yenileme.';

  @override
  String get gitUiRepositoryTrustIsRequiredForThisOperation =>
      'Bu operasyon için depolama güveni gereklidir.';

  @override
  String get gitUiTheGitServiceDisconnectedReconnectAndReconcileTheRepository =>
      'Git hizmetinin bağlantısı kesildi. depolama alanını yeniden bağlayın ve uyandırın.';

  @override
  String
  get gitUiTheInstalledGitExecutableCannotSupportThisOperationReviewIts =>
      'Yüklü Git executable bu işlemi desteklemez. çalışma süresi gereksinimlerini aşağıda inceleyin.';

  @override
  String get gitUiThisRepositoryIsReadOnlyForTheRequestedOperationReview =>
      'Bu depolama alanı yalnızca istediğiniz işlem için okunur. inceleme ve geçmişi mevcuttur.';

  @override
  String
  get gitUiTheOperationNeedsReconciliationReviewTheResultingRepositoryOrRemote =>
      'Operasyonun uzlaşmaya ihtiyacı vardır. sonuçlanan depolama alanını veya uzaktan durumunu tekrarlamadan önce inceleyin.';

  @override
  String get gitUiGitAuthenticationFailedReviewTheCredentialHelperOrUnlockThe =>
      'Git kimlik doğrulama başarısız oldu. kimlik doğrulama yardımcısını inceleyin veya yapılandırılmış keyring\'i açın.';

  @override
  String get gitUiSshHostVerificationFailedReviewTheHostIdentityThroughYour =>
      'SSH ev sahibi doğrulama başarısız oldu. yapılandırılmış SSH araçları aracılığıyla ev sahibi kimliğini inceleyin.';

  @override
  String get gitUiCommitSigningFailedOrWasCancelledReviewTheSigningKey =>
      'Kayıt anahtarı, aracı ve yapılandırılmış imza aracını inceleyin.';

  @override
  String get gitUiSetARepositoryAuthorNameAndEmailThenReturnTo =>
      'Bir depolama alanı yazar adı ve e-posta ayarlayın, sonra kaydedilen mesaj taslağına geri dönün.';

  @override
  String get gitUiGitRejectedTheReviewedUpdateRefreshAndReviewTheActual =>
      'Git, incelenen güncelleştirmeyi reddetti. yeniden denemeden önce gerçek hedefi yenileme ve inceleme.';

  @override
  String get gitUiWorkingOrStagedChangesPreventThisOperationReviewCommitOr =>
      'Bu işleyişi engelleyen çalışma veya aşamalı değişiklikler. inceleme, taahhüt veya açıkça bunları durdur.';

  @override
  String get gitUiARequiredGitObjectIsUnavailableReviewShallowOrPartial =>
      'Gerekli bir Git nesne mevcut değildir. derin veya kısmi depolama sınırlarını inceleyin ve gerekirse açıkça yapıştırın.';

  @override
  String gitUiGitOperationFailedArg0(String arg0) {
    return 'Git operasyonu başarısız oldu: $arg0';
  }

  @override
  String get gitUiDiagnostics => 'Diagnostik';

  @override
  String get gitUiAuthorizeGitInspection => 'Yetkilendirilmiş denetim...';

  @override
  String get gitUiCopyDiagnostics => 'Diagnostik kopyaları';

  @override
  String get gitUiActions => 'Eylemler';

  @override
  String gitUiBranchAtArg0(String arg0) {
    return '$arg0 ile ilgili';
  }

  @override
  String get gitUiCreatesALocalBranchWithoutCheckingItOut =>
      'Yerel bir şubesi oluşturur, onu kontrol etmeden.';

  @override
  String gitUiTagArg0(String arg0) {
    return '$arg0 İndir';
  }

  @override
  String gitUiReadOnlySnapshotArg0(String arg0) {
    return 'Sadece Okunma · $arg0';
  }

  @override
  String get gitUiCherryPickCommits => 'Commit’leri cherry-pick ile uygula';

  @override
  String get gitUiRevertCommits => 'Yükümlülükler';

  @override
  String get gitUiCompareToFullRevisionID =>
      'Tam Değerlendirme ID ile karşılaştırın';

  @override
  String gitUiTreeComparisonDirectionArg0TheRevisionEnteredHere(String arg0) {
    return 'Ağaç karşılaştırma yönü: $arg0 → inceleme burada girdi.';
  }

  @override
  String get gitUiEnterAFullValidObjectID =>
      'Tam bir geçerli nesne kimliği girin.';

  @override
  String gitUiArg0Arg1TreeComparison(String arg0, String arg1) {
    return '$arg0 → $arg1 · ağaç karşılaştırması';
  }

  @override
  String gitUiResetArg0ToArg1(String arg0, String arg1) {
    return '$arg0\'i $arg1\'e dönüştürün';
  }

  @override
  String
  get gitUiMovesHEADCurrentBranchReflogDoesNotRecoverArbitraryUntracked =>
      'HEAD\'i/geçerli dalı taşır. Reflog, rastgele izlenmeyen veya kaydedilmemiş içeriği kurtarmaz.';

  @override
  String get gitUiMoveHEADKeepIndexAndWorkingFiles =>
      'HEAD\'i taşı; indeksi ve çalışma dosyalarını koru.';

  @override
  String get gitUiMoveHEADAndReplaceIndexKeepWorkingFiles =>
      'HEAD\'i taşı ve indeksi değiştir; çalışma dosyalarını koru.';

  @override
  String
  get gitUiReplaceHEADIndexAndTrackedWorkingFilesMayOverwriteObstructing =>
      'HEAD\'i, indeksi ve izlenen çalışma dosyalarını değiştir; engel olan izlenmeyen dosyaların üzerine yazılabilir.';

  @override
  String get gitUiReplaceHEADIndexAndEligibleFilesRefuseIfLocalChanges =>
      'HEAD\'i, indeksi ve uygun dosyaları değiştir; yerel değişiklikler kaybolacaksa reddet.';

  @override
  String gitUiResetWithArg0(String arg0) {
    return '$arg0 ile yeniden yükleme?';
  }

  @override
  String gitUiArg0Arg1ReviewTheSelectedModeSEffectsBeforeApplying(
    String arg0,
    String arg1,
  ) {
    return '$arg0 → $arg1 Uygulamadan önce seçilen modun etkilerini inceleyin.';
  }

  @override
  String gitUiResetArg0(String arg0) {
    return '$arg0 Yükleme';
  }

  @override
  String gitUiTargetArg0(String arg0) {
    return 'Hedef $arg0';
  }

  @override
  String get gitUiTagName => 'Etiket adı';

  @override
  String get gitUiAnnotatedTag => 'Açıklamalı etiket';

  @override
  String get gitUiCryptographicSigning => 'Kriptografik imza';

  @override
  String get gitUiConfiguredPolicy => 'Konfigürasyon Politikası';

  @override
  String get gitUiSignThisTag => 'Bu etiketle kaydolun';

  @override
  String get gitUiDoNotSign => 'imzalamayın';

  @override
  String get gitUiTagMessage => 'Tag Mesajı';

  @override
  String get gitUiCreatesTheTagLocallyPublishSelectedTagsExplicitlyInPush =>
      'Etiketi yerel olarak oluşturun. seçilmiş etiketleri açıkça Push incelemesinde yayınlayın.';

  @override
  String gitUiCompleteTreesArg0Arg1(String arg0, String arg1) {
    return 'Tam ağaçlar: $arg0 → $arg1';
  }

  @override
  String get gitUiNextChangedFilePage => 'Sonraki Değiştirilmiş Dosya Sayfası';

  @override
  String get gitUiReadOnlyRepositorySnapshotOpeningAFileNeverChecksOut =>
      'Bir dosyayı açmak bu revizyonu asla kontrol etmez.';

  @override
  String get gitUiOpenReadOnlyVersion => 'Açık sadece okuma versiyonu';

  @override
  String get gitUiRestoreThisPathWaitingForRepositoryStatus =>
      'Bu yolu geri getirin... · Depolama durumu için bekleyin';

  @override
  String get gitUiRestoreThisPath => 'Bu yolun geri dönüşü...';

  @override
  String gitUiHistoryArg0(String arg0) {
    return 'Tarih · $arg0';
  }

  @override
  String gitUiRestoreArg0(String arg0) {
    return '$arg0\'i yeniden başlatır mısınız?';
  }

  @override
  String gitUiReplaceThisWorkingPathWithRevisionArg0ExistingStagedContent(
    String arg0,
  ) {
    return 'Bu çalışma yolu $arg0 ile değiştirin. mevcut aşamalı içerik korunur.';
  }

  @override
  String get gitUiRestoreWorkingFile => 'Çalışma dosyası kurtarma';

  @override
  String gitUiFileHistoryFollowsRenamesArg0(String arg0) {
    return 'Dosya geçmişi yeniden adlandırılır · $arg0';
  }

  @override
  String get gitUiBlameCommittedContent => 'Satır geçmişi · commit içeriği';

  @override
  String get gitUiBlame => 'Satır geçmişi…';

  @override
  String gitUiArg0WorkingTree(String arg0) {
    return '$arg0 → Çalışma Ağaçları';
  }

  @override
  String get gitUiOpenReadOnlyHistoricalFile => 'Sadece tarihi dosyayı okuyun';

  @override
  String get gitUiCompareToCurrentFile => 'Mevcut dosyaya kıyasla';

  @override
  String get gitUiCompareToParent => 'Bir ebeveynle karşılaştırma...';

  @override
  String gitUiCommittedArg0UnsavedEditorContentIsNotPartOfThese(String arg0) {
    return '$arg0 · kaydedilmemiş editör içeriği bu notların bir parçası değildir';
  }

  @override
  String gitUiHistoryFromArg0(String arg0) {
    return '$arg0 ile ilgili';
  }

  @override
  String get gitUiBoundary => ' · Sınır';

  @override
  String gitUiArg0Arg1OriginalLineArg2Arg3(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return '$arg0  $arg1\nÖzgün satır $arg2$arg3';
  }

  @override
  String get gitUiPreviousLines => 'Önceki Hatalar';

  @override
  String get gitUiNextLines => 'Sonraki çizgiler';

  @override
  String gitUiExplicitApplicationOrderDestinationArg0(String arg0) {
    return 'Açıklama Başvuru Siparişi · Hedef $arg0';
  }

  @override
  String get gitUiAddFullCommitObjectID => 'Tam Commit Object ID ekleme';

  @override
  String get gitUiAddReviewedCommit => 'Değerlendirilmiş komite...';

  @override
  String get gitUiMoveEarlier => 'Daha önce hareket';

  @override
  String get gitUiMoveLater => 'Daha sonra hareket';

  @override
  String get gitUiRemoveFromReviewedSequence =>
      'Değerlendirilmiş Sürümden Kaldır';

  @override
  String get gitUiApplyChangesWithoutCreatingCommits =>
      'Değişiklikler yapmadan uygulayın';

  @override
  String get gitUiUseThisExplicitMainlineParentForMergeCommits =>
      'Bu açık ana sözcük ebeveynleri birleştirme sözleşmeleri için kullanın';

  @override
  String get gitUiEmptyOrAlreadyAppliedCommitsMayStopGitForAn =>
      'Boş veya zaten uygulanmış emirler açık bir geçiş veya devam karar için Git\'i durdurabilir.';

  @override
  String get gitUiRevertInReviewedOrder => 'Değerlendirilmiş sırada dönüş';

  @override
  String get gitUiCherryPickInReviewedOrder => 'Cherry-pick incelenmiş sırada';

  @override
  String get gitUiReturnToFiles => 'Dosyaya Dönüş';

  @override
  String get gitUiGit => 'Git';

  @override
  String get gitUiCommit => 'Commit oluştur';

  @override
  String get gitUiBackToCommit => 'Komiteye Geri Dönüş';

  @override
  String get gitUiSelectAChangeToReview => 'Değişimi incelemek için seçin';

  @override
  String get gitUiLoadingBranch => 'Yükleme şubesi...';

  @override
  String get gitUiBranchUnavailable => 'Branch kullanılamıyor';

  @override
  String get gitUiUnbornHEAD => 'Commit içermeyen HEAD';

  @override
  String gitUiDetachedHEADRevision(String revision) {
    return 'Ayrık HEAD · $revision';
  }

  @override
  String get gitUiContinueAction => 'Devam';

  @override
  String get gitUiPick => 'Al';

  @override
  String get gitUiReword => 'İletiyi değiştir';

  @override
  String get gitUiEdit => 'Düzenle';

  @override
  String get gitUiSquash => 'Birleştir ve iletileri koru';

  @override
  String get gitUiFixup => 'İleti olmadan birleştir';

  @override
  String get gitUiDrop => 'Atla';

  @override
  String get gitUiAbort => 'İşlemi iptal et';

  @override
  String get gitUiSkip => 'Atla';

  @override
  String get gitUiQuit => 'Operasyon Çıktı';

  @override
  String get gitUiSoft => 'Yumuşak';

  @override
  String get gitUiMixed => 'Karma';

  @override
  String get gitUiHard => 'Sert';

  @override
  String get gitUiKeep => 'Koru';

  @override
  String get gitUiCreate => 'Oluştur';

  @override
  String get gitUiApplyStash => 'Saklanan değişiklikleri uygula';

  @override
  String get gitUiPopStash => 'Uygula ve başarılıysa saklamayı kaldır';

  @override
  String get gitUiDropStashAction => 'Saklanan değişiklikleri sil';

  @override
  String get gitUiEditedResult => 'Edit Sonuçları';

  @override
  String get gitUiLeftContent => 'sol içeriği';

  @override
  String get gitUiRightContent => 'Doğru içerik';

  @override
  String get gitUiDeletePath => 'Yürüyüş Yolu';

  @override
  String get gitUiSubmoduleCommit => 'Submodüller';

  @override
  String get gitUiPresentContent => 'Mevcut içerik';

  @override
  String get gitUiAbsentContent => 'eksik';

  @override
  String get gitUiBinaryContent => 'İkili içerik';

  @override
  String get gitUiTooLargeContent => 'İçerik gösterim sınırını aştı';

  @override
  String get gitUiUnavailableContent => 'Mevcut olmayan içerik';

  @override
  String get gitUiGitlinkContent => 'Submodüel göstergesi';

  @override
  String get gitUiSymlinkContent => 'sembolik bağlantı';

  @override
  String get gitUiNoOperation => 'Hiçbir operasyon';

  @override
  String get gitUiCherryPickOperation => 'Commit seçerek uygula';

  @override
  String get gitUiRevertOperation => 'Geri alan commit';

  @override
  String get gitUiApplyMailboxOperation => 'Patch uygulama';

  @override
  String get gitUiSquashOperation => 'Squash Birleşme';

  @override
  String get gitUiUnmergedOperation => 'indeksleri yok';

  @override
  String get gitUiWaitingForPromptPhase => 'Cevabını bekliyorum';

  @override
  String get gitUiStoppedPhase => 'İnceleme için durduruldu';

  @override
  String get gitUiCompletedPhase => 'Tamamlandı';

  @override
  String get gitUiFailedPhase => 'Başarısız';

  @override
  String get gitUiCancelledPhase => 'İptal edildi';

  @override
  String get gitUiUncertainPhase => 'Sonuçlar bir uzlaşma gerektirir';

  @override
  String gitUiStageVersion(String stage) {
    return 'Çatışma aşaması $stage';
  }

  @override
  String get gitUiGitMergePreview => 'Git merge önizleme';

  @override
  String get gitUiNormalizedWorking => 'Çalışma Ağaçları · Normalleşme';

  @override
  String gitUiPercentValue(String value) {
    return '$value Yüzde';
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
  String get gitUiUtf8Bom => 'UTF-8 byte sipariş işareti (BOM)';

  @override
  String get gitUiUtf8NoBom => 'UTF-8 byte sipariş işareti olmadan (BOM)';

  @override
  String get gitUiAddsBom =>
      'Bu düzen dosyanın başlangıcında bir UTF-8 byte sipariş işareti (BOM) eklenir.';

  @override
  String get gitUiRemovesBom =>
      'Bu düzenleme, dosyanın başlangıcından UTF-8 byte sipariş işareti (BOM) kaldırır.';

  @override
  String get gitUiNoLineTerminators => 'Terminatörler yok';

  @override
  String gitUiLineEndings(String format) {
    return '$format satır sonları';
  }

  @override
  String gitUiMixedLineEndings(String formats) {
    return 'Karışık çizgi sonları ($formats)';
  }

  @override
  String gitUiNoFinalLf(String format) {
    return '$format · hiçbir final LF';
  }

  @override
  String gitUiLineEndingChange(String before, String after) {
    return '$before\'den $after\'e çevrimiçi format değişiklikleri.';
  }

  @override
  String get gitUiGitFailure =>
      'Git ameliyatı başarısız oldu. aşağıdaki teşhisleri inceleyin.';

  @override
  String get gitUiAbortInline => 'İşlemi iptal et';

  @override
  String get gitUiSkipInline => 'Atla';

  @override
  String get gitUiQuitInline => 'Bırak';

  @override
  String get gitUiMergeInline => 'Birleştir';

  @override
  String get gitUiRebaseInline => 'Yeniden temellendir';

  @override
  String get gitUiCherryPickInline => 'Commit seçerek uygula';

  @override
  String get gitUiRevertInline => 'Geri alan commit';

  @override
  String get gitUiApplyMailboxInline => 'Uygulamalı';

  @override
  String get gitUiSquashInline => 'Birleştir ve iletileri koru';

  @override
  String get gitUiUnmergedInline => 'Sıkıntısız';

  @override
  String get gitHostFetch => 'Getir';

  @override
  String get gitHostRefreshGitStatus => 'Git statüsünü yenilemek';

  @override
  String get gitHostCommitStaged => 'Komite Sınavı';

  @override
  String get gitHostGitBranches => 'Git Şubeleri';

  @override
  String get gitHostReviewPush => 'Push İnceleme';

  @override
  String get gitHostGit => 'Git';

  @override
  String get gitHostGitOperationsApplyToThisEntireRepositoryAndMay =>
      'Git işlemleri tüm bu depolama alanı için geçerlidir ve yapılandırılmış çubukları, filtreleri, kimlik doğrulama ve imza araçlarını çalıştırabilir.';

  @override
  String get gitHostContentUnavailable => 'Kullanılamayan içerik';

  @override
  String get gitHostInitializeRepository => 'Git deposunu başlat';

  @override
  String get gitHostCloneRepository => 'Depoyu klonla';

  @override
  String get gitHostInitializeHere => 'Başlangıç burada...';

  @override
  String get gitHostCloneRepository2 => 'Depoyu klonla…';

  @override
  String get gitHostGitLog => 'Git geçmişi';

  @override
  String get gitUiAbsentPlaceholder => 'eksikliği )';

  @override
  String get gitUiUnborn => 'Doğmamış';

  @override
  String gitUiRebasedHistoryRevision(String revision) {
    return 'Yeniden temellendirilmiş geçmiş · $revision';
  }

  @override
  String gitUiCurrentHistoryRevision(String revision) {
    return 'Geçerli geçmiş · $revision';
  }

  @override
  String gitUiReplayedCommitRevision(String revision) {
    return 'Yeniden uygulanan commit · $revision';
  }

  @override
  String gitUiIncomingContentRevision(String revision) {
    return 'Gelen içerik · $revision';
  }

  @override
  String get gitUiContentConflict => 'içerik çatışması';

  @override
  String get gitUiSubmoduleConflict => 'Submodüel çatışma';

  @override
  String get gitUiSymlinkConflict => 'Simbolik bağlantı çatışması';

  @override
  String get gitUiAddAddConflict => 'Her iki tarafta da eklendi';

  @override
  String get gitUiModifyDeleteConflict =>
      'Değiştirilmiş / Kaldırılmış veya Değiştirilmiş / Kaldırılmış';

  @override
  String gitUiConflictIdentity(String path, String kind) {
    return '$path · $kind';
  }

  @override
  String get gitUiDiscardUnsavedIndexDraft =>
      'Kaydedilmemiş dizin taslağı atılsın mı?';

  @override
  String get gitUiClosingTheIndexEditorDiscardsOnlyItsDraft =>
      'Dizin düzenleyicisini kapatmak yalnızca taslağı atar. Dizin ve çalışma dosyası değişmez.';

  @override
  String get gitUiDiscardIndexDraft => 'Dizin taslağını at';

  @override
  String get gitUiDiscardUnsavedConflictDraft =>
      'Kaydedilmemiş çakışma sonucu atılsın mı?';

  @override
  String get gitUiClosingTheConflictEditorDiscardsOnlyItsDraft =>
      'Çakışma düzenleyicisini kapatmak yalnızca kaydedilmemiş sonuç taslağını atar. Kaydedilmiş çalışma içeriği ve indeks değişmez.';

  @override
  String get gitUiDiscardConflictDraft => 'Çakışma taslağını at';

  @override
  String get gitUiOpenCurrentFile => 'Geçerli dosyayı aç';

  @override
  String get gitUiPreviousSearchMatch => 'Önceki arama sonucu';

  @override
  String get gitUiNextSearchMatch => 'Sonraki arama sonucu';

  @override
  String gitUiSearchMatchPosition(String current, String count) {
    return '$count sonuçtan $current. sonuç';
  }

  @override
  String gitUiSearchResultsLimited(String count) {
    return 'İlk $count sonuç gösteriliyor. Daha fazlasını incelemek için aramayı daraltın.';
  }

  @override
  String get gitUiRevealRevisionWithoutFilters => 'Revizyonu filtresiz göster';

  @override
  String get gitUiRestoreHistoryFilters => 'Geçmiş filtrelerini geri yükle';

  @override
  String get gitUiShowAllAffectedFiles => 'Etkilenen tüm dosyaları göster';

  @override
  String get gitUiGraphLanes => 'Grafik şeritleri';

  @override
  String gitUiRebaseArg0OntoArg1(String arg0, String arg1) {
    return '$arg0 dalını $arg1 üzerine yeniden temellendir';
  }

  @override
  String get gitUiChangedLine => 'Değişen satır';

  @override
  String get gitUiCopyHeadRegionIntoIndexDraft =>
      'HEAD bölgesini indeks taslağına kopyala';

  @override
  String get gitUiCopyWorkingRegionIntoIndexDraft =>
      'Çalışma bölgesini indeks taslağına kopyala';

  @override
  String get gitUiUpdatingConflictRegions => 'Çakışma bölgeleri güncelleniyor';

  @override
  String gitUiRemainingConflictMarkers(String count) {
    return 'Çakışma işaretçileri içeren sonuç bölgeleri: $count';
  }

  @override
  String get gitUiIgnoreLeftRegion => 'Soldaki öneriyi yok say';

  @override
  String get gitUiIgnoreRightRegion => 'Sağdaki öneriyi yok say';

  @override
  String get gitUiIndexAppliedNewerDraftPreserved =>
      'Gönderilen taslak indekse yazıldı. Daha yeni metin hâlâ bu düzenleyicide. Uygulamadan önce geçerli sürümleri yeniden yükleyip inceleyin.';

  @override
  String get gitUiNewerConflictDraftRetained =>
      'Gönderilen sonuç kaydedildi. Daha yeni sonuç taslağınız hâlâ kaydedilmedi.';

  @override
  String get gitUiNoFileHistoryForThisPathAndRevision =>
      'Bu yol ve revizyon için dosya geçmişi bulunmuyor.';

  @override
  String get gitUiReviewSavedIndexAndKeepDraft =>
      'Kaydedilen indeksi incele ve taslağı koru';

  @override
  String get gitUiIndexSourcesChangedSinceApply =>
      'Kaydedilen indeks veya kaynakları değişti. Daha yeni taslak korunuyor; uygulamadan önce bu değişiklikleri ayrı olarak inceleyin.';

  @override
  String get gitUiReviewSavedMessage => 'Kaydedilmiş iletiyi incele';

  @override
  String get gitUiSavedMessage => 'Kaydedilmiş ileti';

  @override
  String get gitUiKeepThisMessage => 'Bu iletiyi koru';

  @override
  String get gitUiUseSavedMessage => 'Kaydedilmiş iletiyi kullan';

  @override
  String get gitUiCommitDraftChangedInAnotherWindow =>
      'Bu ileti başka bir pencerede değiştirildi. Değiştirmeden önce kaydedilmiş iletiyi inceleyin.';

  @override
  String get gitUiDiscardUnsavedCommitMessages =>
      'Kaydedilmemiş commit iletileri atılsın mı?';

  @override
  String get gitUiMessagesCouldNotBeSavedStayInThisWindow =>
      'Kaydedilemeyen iletiler hâlâ bu pencerede. Bunları atmak kaydedilmiş sürümleri değiştirmez.';

  @override
  String get gitUiDiscardCommitMessages => 'İletileri at';
}
