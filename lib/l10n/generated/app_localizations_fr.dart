// ignore_for_file: text_direction_code_point_in_literal, text_direction_code_point_in_comment

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'BusyMark';

  @override
  String get appSubtitle =>
      'Éditeur de fichiers Markdown et de projets de documentation compatibles avec Writerside.';

  @override
  String get aboutBusyMark => 'À propos de BusyMark';

  @override
  String get aboutTagline => 'Éditeur Markdown et Writerside';

  @override
  String get aboutLicenseLabel => 'Licence';

  @override
  String get aboutLicenseName => 'Apache License 2.0';

  @override
  String get aboutWebsite => 'Site web';

  @override
  String get aboutSourceCode => 'Code source';

  @override
  String get reportIssue => 'Signaler un problème';

  @override
  String get feedbackCategory => 'Catégorie';

  @override
  String get feedbackChooseCategory => 'Choisir une catégorie';

  @override
  String get feedbackCategoryProblem => 'Problème ou bogue';

  @override
  String get feedbackCategoryFeature => 'Demande de fonctionnalité';

  @override
  String get feedbackCategoryPrivacySecurity =>
      'Problème de confidentialité ou de sécurité';

  @override
  String get feedbackCategoryUsability => 'Problème d’utilisabilité';

  @override
  String get feedbackCategoryOther => 'Autre';

  @override
  String get feedbackSubject => 'Objet';

  @override
  String get feedbackMessage => 'Message détaillé';

  @override
  String get feedbackReplyEmail => 'Adresse e-mail de réponse (facultatif)';

  @override
  String get feedbackIncludeTechnicalDetails =>
      'Inclure les détails techniques';

  @override
  String get feedbackTechnicalDetailsDisclosure =>
      'Lorsque cette option est activée, seuls la version du système d’exploitation Linux et les paramètres régionaux de l’application BusyMark sont ajoutés. Aucun journal, fichier, donnée de compte ou autre diagnostic n’est joint.';

  @override
  String get feedbackSubmit => 'Envoyer';

  @override
  String get feedbackSubmitting => 'Envoi…';

  @override
  String get feedbackCategoryRequired => 'Choisissez une catégorie.';

  @override
  String get feedbackSubjectLength =>
      'L’objet doit comporter entre 3 et 120 caractères.';

  @override
  String get feedbackMessageLength =>
      'Le message doit comporter entre 10 et 5 000 caractères.';

  @override
  String get feedbackReplyEmailInvalid =>
      'Saisissez une adresse e-mail valide ou laissez ce champ vide.';

  @override
  String get feedbackConnectionFailure =>
      'BusyMark n’a pas pu se connecter. Vérifiez votre connexion Internet et réessayez.';

  @override
  String get feedbackTimeoutFailure => 'La requête a expiré. Réessayez.';

  @override
  String get feedbackRateLimitedFailure =>
      'Trop de rapports ont été envoyés depuis cette connexion. Attendez puis réessayez.';

  @override
  String get feedbackRejectedFailure =>
      'Le serveur a refusé le signalement. Vérifiez les champs du formulaire et réessayez.';

  @override
  String get feedbackServerFailure =>
      'Le serveur n’a pas pu accepter le rapport. Réessayez plus tard.';

  @override
  String feedbackSuccess(String id) {
    return 'Commentaires envoyés. Identifiant de référence : $id';
  }

  @override
  String get advanced => 'Avancé';

  @override
  String get addToGit => 'Ajouter à Git';

  @override
  String get appearance => 'Apparence';

  @override
  String get apply => 'Appliquer';

  @override
  String get back => 'Retour';

  @override
  String get bottomLeft => 'En bas à gauche';

  @override
  String get bottomRight => 'En bas à droite';

  @override
  String get cancel => 'Annuler';

  @override
  String get choose => 'Choisir';

  @override
  String get chooseLocation => 'Choisir un emplacement';

  @override
  String get copy => 'Copier';

  @override
  String get copyName => 'Copier le nom';

  @override
  String get copyFileName => 'Copier le nom du fichier';

  @override
  String get copyPath => 'Copier le chemin';

  @override
  String get create => 'Créer';

  @override
  String get creating => 'Création en cours…';

  @override
  String get cut => 'Couper';

  @override
  String get promoteSection => 'Promouvoir la section';

  @override
  String get demoteSection => 'Rétrograder la section';

  @override
  String get moveSectionUp => 'Déplacer la section vers le haut';

  @override
  String get moveSectionDown => 'Déplacer la section vers le bas';

  @override
  String get confirmDeleteSectionTitle => 'Supprimer la section ?';

  @override
  String confirmDeleteSectionMessage(String name) {
    return 'Supprimer « $name » et tout le contenu de sa section ? Cette action est irréversible.';
  }

  @override
  String get darkTheme => 'Sombre';

  @override
  String get delete => 'Supprimer';

  @override
  String get discard => 'Abandonner';

  @override
  String get editor => 'Éditeur';

  @override
  String get file => 'Fichier';

  @override
  String get fileHistory => 'Historique du fichier';

  @override
  String get folder => 'Dossier';

  @override
  String get insert => 'Insérer';

  @override
  String get keyboardShortcuts => 'Raccourcis clavier';

  @override
  String get lightTheme => 'Clair';

  @override
  String get mainMenu => 'Menu principal';

  @override
  String get fullScreen => 'Plein écran';

  @override
  String get markdown => 'Markdown';

  @override
  String get open => 'Ouvrir';

  @override
  String get openInFiles => 'Ouvrir dans Fichiers';

  @override
  String get pathActions => 'Actions sur le chemin';

  @override
  String get outline => 'Plan';

  @override
  String get overwrite => 'Écraser';

  @override
  String get paste => 'Coller';

  @override
  String get pasteWithoutFormatting => 'Coller sans mise en forme';

  @override
  String get preview => 'Aperçu';

  @override
  String get recent => 'Récents';

  @override
  String get redo => 'Refaire';

  @override
  String get save => 'Enregistrer';

  @override
  String get search => 'Rechercher';

  @override
  String get selectAll => 'Tout sélectionner';

  @override
  String get settings => 'Paramètres';

  @override
  String get source => 'Source';

  @override
  String get split => 'Fractionné';

  @override
  String get systemTheme => 'Système';

  @override
  String get theme => 'Thème';

  @override
  String get appLanguage => 'Langue';

  @override
  String get systemLanguage => 'Système';

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
  String get toggleSidebar => 'Panneau latéral';

  @override
  String get topLeft => 'En haut à gauche';

  @override
  String get topRight => 'En haut à droite';

  @override
  String get undo => 'Annuler';

  @override
  String get validate => 'Valider';

  @override
  String get validation => 'Validation';

  @override
  String get viewMode => 'Mode d’affichage';

  @override
  String get welcome => 'Bienvenue';

  @override
  String get writerside => 'Writerside';

  @override
  String get xml => 'XML';

  @override
  String get fileTypeMarkdown => 'Markdown';

  @override
  String get fileTypeImages => 'Images';

  @override
  String get openMarkdownFile => 'Ouvrir un fichier Markdown';

  @override
  String get markdownFileExtensions => '.md ou .markdown';

  @override
  String get openFolderOrWritersideProject =>
      'Ouvrir un dossier ou un projet Writerside';

  @override
  String get markdownFolderOrWritersideProject =>
      'Dossier Markdown ou projet compatible avec Writerside';

  @override
  String get noOpenFile => 'Aucun fichier ouvert';

  @override
  String get shortcutDeleteTreeItemDescription =>
      'Supprimer l’élément sélectionné dans « Fichiers » ou retirer la rubrique sélectionnée de la table des matières';

  @override
  String get shortcutGroupGeneral => 'Général';

  @override
  String get shortcutNewDocument => 'Créer';

  @override
  String get shortcutNewDocumentDescription =>
      'Créer un fichier Markdown ou un projet Writerside';

  @override
  String get shortcutOpenDescription =>
      'Ouvrir un fichier Markdown, un dossier ou un projet Writerside';

  @override
  String get shortcutSaveDescription => 'Enregistrer le document actuel';

  @override
  String get shortcutSearchDescription =>
      'Rechercher dans l’espace de travail actuel';

  @override
  String get shortcutKeyboardShortcutsDescription =>
      'Afficher cette liste de raccourcis clavier';

  @override
  String get shortcutMarkdownAndHtmlDescription =>
      'Ouvrir la référence Markdown et HTML';

  @override
  String get shortcutSettingsDescription => 'Ouvrir les paramètres de BusyMark';

  @override
  String get shortcutNextTab => 'Onglet suivant';

  @override
  String get shortcutNextTabDescription => 'Passer à l’onglet ouvert suivant';

  @override
  String get shortcutPreviousTab => 'Onglet précédent';

  @override
  String get shortcutPreviousTabDescription =>
      'Passer à l’onglet ouvert précédent';

  @override
  String get shortcutCloseTab => 'Fermer l’onglet';

  @override
  String get shortcutCloseTabDescription => 'Fermer l’onglet actif';

  @override
  String get shortcutCloseAllTabs => 'Fermer tous les onglets';

  @override
  String get shortcutCloseAllTabsDescription =>
      'Fermer tous les onglets ouverts';

  @override
  String get shortcutGroupTextEditing => 'Édition de texte';

  @override
  String get shortcutSelectAllDescription =>
      'En mode Source, sélectionner tout le texte ; en mode Éditeur, appuyer deux fois pour sélectionner tous les blocs';

  @override
  String get shortcutCutDescription => 'Couper le texte sélectionné';

  @override
  String get shortcutCopyDescription => 'Copier le texte sélectionné';

  @override
  String get shortcutPasteDescription => 'Coller depuis le presse-papiers';

  @override
  String get shortcutPastePlainTextDescription =>
      'Coller le texte du presse-papiers sans mise en forme';

  @override
  String get shortcutUndoDescription => 'Annuler la dernière modification';

  @override
  String get shortcutRedoDescription =>
      'Refaire la dernière modification annulée';

  @override
  String get shortcutInsertIndentation => 'Insérer un retrait';

  @override
  String get shortcutInsertIndentationDescription =>
      'Insérer un retrait à l’emplacement du curseur';

  @override
  String get shortcutOutdentSource => 'Diminuer le retrait du code source';

  @override
  String get shortcutOutdentSourceDescription =>
      'Supprimer un niveau de retrait en mode Source';

  @override
  String get shortcutEscape =>
      'Fermer la recherche ou désélectionner les blocs';

  @override
  String get shortcutEscapeDescription =>
      'Fermer la recherche dans l’espace de travail ou désélectionner des blocs en mode Éditeur';

  @override
  String get shortcutGroupFormatting => 'Mise en forme';

  @override
  String get shortcutBoldDescription =>
      'Activer ou désactiver le gras pour le texte sélectionné';

  @override
  String get shortcutItalicDescription =>
      'Activer ou désactiver l’italique pour le texte sélectionné';

  @override
  String get shortcutUnderlineDescription =>
      'Activer ou désactiver le soulignement pour le texte sélectionné';

  @override
  String get shortcutLinkDescription => 'Insérer ou modifier un lien';

  @override
  String get shortcutInlineCodeDescription =>
      'Activer ou désactiver le code en ligne pour le texte sélectionné';

  @override
  String get shortcutStrikethroughDescription =>
      'Activer ou désactiver le barré pour le texte sélectionné';

  @override
  String get shortcutGroupBlocks => 'Blocs';

  @override
  String get shortcutParagraphDescription =>
      'Définir le bloc actuel comme paragraphe';

  @override
  String get shortcutHeading1Description =>
      'Définir le bloc actuel comme titre 1';

  @override
  String get shortcutHeading2Description =>
      'Définir le bloc actuel comme titre 2';

  @override
  String get shortcutHeading3Description =>
      'Définir le bloc actuel comme titre 3';

  @override
  String get shortcutHeading4Description =>
      'Définir le bloc actuel comme titre 4';

  @override
  String get shortcutHeading5Description =>
      'Définir le bloc actuel comme titre 5';

  @override
  String get shortcutHeading6Description =>
      'Définir le bloc actuel comme titre 6';

  @override
  String get shortcutGroupLists => 'Listes';

  @override
  String get numberedList => 'Liste numérotée';

  @override
  String get shortcutNumberedListDescription =>
      'Activer ou désactiver la liste numérotée';

  @override
  String get bulletedList => 'Liste à puces';

  @override
  String get shortcutBulletedListDescription =>
      'Activer ou désactiver la liste à puces';

  @override
  String get checklist => 'Liste de tâches';

  @override
  String get shortcutChecklistDescription =>
      'Activer ou désactiver la liste de tâches';

  @override
  String get shortcutGroupSidebar => 'Barre latérale';

  @override
  String get sidebarViewMenu => 'Vue de la barre latérale';

  @override
  String get createMarkdownFile => 'Créer un fichier Markdown';

  @override
  String get createMarkdownFileDescription =>
      'Démarrer un document Markdown local non enregistré';

  @override
  String get createWritersideProject => 'Créer un projet Writerside';

  @override
  String get createWritersideProjectDescription =>
      'Démarrer un projet local compatible avec Writerside';

  @override
  String get defaultProjectName => 'Documentation';

  @override
  String get defaultInstanceName => 'Guide de l’utilisateur';

  @override
  String get defaultStartTopicTitle => 'Premiers pas';

  @override
  String get projectName => 'Nom du projet';

  @override
  String get directoryName => 'Nom du répertoire';

  @override
  String get instanceName => 'Nom de l’instance';

  @override
  String get instanceId => 'ID d’instance';

  @override
  String get startTopicTitle => 'Titre du sujet de départ';

  @override
  String get location => 'Emplacement';

  @override
  String get projectNameRequired => 'Le nom du projet est obligatoire.';

  @override
  String get directoryNameRequired => 'Le nom du répertoire est obligatoire.';

  @override
  String get useSingleSafeDirectoryName =>
      'Utilisez un seul nom de répertoire valide, sans séparateur de chemin.';

  @override
  String get useLowercaseIdentifier =>
      'Utilisez un identifiant en minuscules composé de lettres, de chiffres, de traits de soulignement ou de traits d’union.';

  @override
  String get startTopicTitleRequired =>
      'Le titre du sujet de départ est obligatoire.';

  @override
  String get createWritersideProjectFailed =>
      'Impossible de créer le projet Writerside.';

  @override
  String get settingsTitle => 'Paramètres de BusyMark';

  @override
  String get autoSave => 'Enregistrement automatique';

  @override
  String get autoSaveDescription =>
      'Enregistrer automatiquement les modifications après une courte période d’inactivité.';

  @override
  String get wordWrap => 'Retour à la ligne automatique';

  @override
  String get editorFontSize => 'Taille de la police de l’éditeur';

  @override
  String get validateOnEdit => 'Valider pendant la modification';

  @override
  String get clearRecentWorkspaces => 'Effacer les espaces de travail récents';

  @override
  String get editingButtonsPosition => 'Position des boutons d’édition';

  @override
  String get editingButtonsPositionDescription =>
      'Choisissez l’emplacement des boutons d’édition WYSIWYG flottants.';

  @override
  String get editingButtonsDirection => 'Orientation des boutons d’édition';

  @override
  String get editingButtonsDirectionDescription =>
      'Choisissez si les boutons d’édition WYSIWYG flottants sont disposés horizontalement ou verticalement.';

  @override
  String get horizontal => 'Horizontale';

  @override
  String get vertical => 'Verticale';

  @override
  String get privacy => 'Confidentialité';

  @override
  String get allowRemoteImages => 'Charger les images distantes';

  @override
  String get allowRemoteImagesDescription =>
      'Autoriser le chargement d’images depuis des URL HTTP et HTTPS dans l’aperçu Markdown et l’éditeur.';

  @override
  String get clearRemoteImagePermissions =>
      'Effacer les autorisations d’images distantes';

  @override
  String get clearRemoteImagePermissionsDescription =>
      'Oublier les espaces de travail autorisés à charger des images distantes.';

  @override
  String get clearGitWorkspaceTrust =>
      'Effacer les espaces de travail Git approuvés';

  @override
  String get clearGitWorkspaceTrustDescription =>
      'Demander confirmation avant d’activer les fonctions Git pour les espaces de travail précédemment approuvés.';

  @override
  String get settingsWindowSectionTitle => 'Fenêtre';

  @override
  String get settingsConfirmCloseWithUnsavedChangesTitle =>
      'Confirmer avant de fermer avec des modifications non enregistrées';

  @override
  String get settingsConfirmCloseWithUnsavedChangesDescription =>
      'Demander confirmation avant de fermer BusyMark lorsque des documents comportent des modifications non enregistrées.';

  @override
  String get closeUnsavedChangesTitle => 'Modifications non enregistrées';

  @override
  String get closeUnsavedChangesSingleMessage =>
      'Ce document contient des modifications non enregistrées. Enregistrer les modifications avant de fermer BusyMark ?';

  @override
  String closeUnsavedChangesMultipleMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count documents contiennent des modifications non enregistrées. Enregistrer les modifications avant de fermer BusyMark ?',
      one:
          '1 document contient des modifications non enregistrées. Enregistrer les modifications avant de fermer BusyMark ?',
      zero: 'Enregistrer les modifications avant de fermer BusyMark ?',
    );
    return '$_temp0';
  }

  @override
  String get closeUnsavedChangesCancel => 'Annuler';

  @override
  String get closeUnsavedChangesDiscard => 'Ne pas enregistrer';

  @override
  String get closeUnsavedChangesSave => 'Enregistrer';

  @override
  String get currentFile => 'fichier actuel';

  @override
  String get unsavedChanges => 'Modifications non enregistrées';

  @override
  String unsavedChangesMessage(String fileName) {
    return 'Des modifications non enregistrées sont présentes dans $fileName. Les enregistrer avant de continuer ?';
  }

  @override
  String get fileChangedOnDisk => 'Fichier modifié sur le disque';

  @override
  String get fileChangedOnDiskMessage =>
      'Ce fichier a été modifié sur le disque depuis son ouverture. L’écraser ?';

  @override
  String get untitledMarkdownFileName => 'Sans titre.md';

  @override
  String get unorderedList => 'Liste non ordonnée';

  @override
  String get orderedList => 'Liste ordonnée';

  @override
  String get taskList => 'Liste de tâches';

  @override
  String get toggleTaskChecked => 'Cocher/décocher la tâche';

  @override
  String get indentListItem => 'Augmenter le retrait de l’élément de liste';

  @override
  String get outdentListItem => 'Réduire le retrait de l’élément de liste';

  @override
  String get blockquote => 'Bloc de citation';

  @override
  String get codeBlock => 'Bloc de code';

  @override
  String get codeBlockLanguage => 'Langage du bloc de code';

  @override
  String get image => 'Image';

  @override
  String get inlineImage => 'Image en ligne';

  @override
  String get table => 'Tableau';

  @override
  String get htmlBlock => 'Bloc HTML';

  @override
  String get htmlContentDefault => 'Contenu HTML';

  @override
  String get shortcutHtmlBlockDescription => 'Insérer ou modifier un bloc HTML';

  @override
  String get renderedHtml => 'HTML rendu';

  @override
  String get editHtml => 'Modifier le HTML';

  @override
  String get htmlSource => 'Source HTML';

  @override
  String get thematicBreak => 'Séparateur horizontal';

  @override
  String get bold => 'Gras';

  @override
  String get italic => 'Italique';

  @override
  String get underline => 'Souligné';

  @override
  String get strikethrough => 'Barré';

  @override
  String get inlineCode => 'Code en ligne';

  @override
  String get link => 'Lien';

  @override
  String get hardLineBreak => 'Saut de ligne forcé';

  @override
  String get textStyle => 'Style de texte';

  @override
  String get paragraph => 'Paragraphe';

  @override
  String get heading1 => 'Titre 1';

  @override
  String get heading2 => 'Titre 2';

  @override
  String get heading3 => 'Titre 3';

  @override
  String get heading4 => 'Titre 4';

  @override
  String get heading5 => 'Titre 5';

  @override
  String get heading6 => 'Titre 6';

  @override
  String headingLevelAbbreviation(int level) {
    return 'H$level';
  }

  @override
  String get deleteTable => 'Supprimer le tableau';

  @override
  String tableColumnNumber(int columnNumber) {
    return 'Colonne $columnNumber';
  }

  @override
  String get insertColumnLeft => 'Insérer une colonne à gauche';

  @override
  String get insertColumnRight => 'Insérer une colonne à droite';

  @override
  String get deleteColumn => 'Supprimer la colonne';

  @override
  String tableRowNumber(int rowNumber) {
    return 'Ligne $rowNumber';
  }

  @override
  String get insertRowAbove => 'Insérer une ligne au-dessus';

  @override
  String get insertRowBelow => 'Insérer une ligne en dessous';

  @override
  String get deleteRow => 'Supprimer la ligne';

  @override
  String get tableHeaderHint => 'En-tête';

  @override
  String get tableCellHint => 'Cellule';

  @override
  String get language => 'Langue';

  @override
  String get hideEditingButtons => 'Masquer les boutons d’édition';

  @override
  String get showEditingButtons => 'Afficher les boutons d’édition';

  @override
  String get altText => 'Texte alternatif';

  @override
  String get editorPlaceholderText => 'texte';

  @override
  String get editorPlaceholderCode => 'code';

  @override
  String get editorPlaceholderAltText => 'texte alternatif';

  @override
  String get describeTheImage => 'Décrire l’image';

  @override
  String get columns => 'Colonnes';

  @override
  String get rows => 'Lignes';

  @override
  String tableHeaderNumber(int columnNumber) {
    return 'En-tête $columnNumber';
  }

  @override
  String get tableCellDefault => 'Cellule';

  @override
  String get noImageSource => 'Aucune source d’image';

  @override
  String get remoteImageBlocked => 'Image distante bloquée';

  @override
  String get remoteImageBlockedTooltip =>
      'Choisissez si BusyMark peut charger des images distantes.';

  @override
  String get remoteImagesBlockedTitle => 'Les images distantes sont bloquées';

  @override
  String get remoteImagesBlockedMessage =>
      'Ce document fait référence à des images sur Internet. Leur chargement peut révéler des informations réseau à l’hôte des images.';

  @override
  String get loadRemoteImagesForWorkspace =>
      'Charger pour cet espace de travail';

  @override
  String get alwaysLoadRemoteImages => 'Toujours charger les images distantes';

  @override
  String get hideSidebar => 'Masquer le panneau latéral';

  @override
  String get showSidebar => 'Afficher le panneau latéral';

  @override
  String get showPreview => 'Afficher l’aperçu';

  @override
  String get hidePreview => 'Masquer l’aperçu';

  @override
  String get workspaceKindUnsavedMarkdown => 'Fichier Markdown non enregistré';

  @override
  String get workspaceKindSingleMarkdown => 'Fichier Markdown unique';

  @override
  String get workspaceKindMarkdownFolder => 'Dossier Markdown';

  @override
  String get workspaceKindWritersideModule => 'Module Writerside';

  @override
  String get problems => 'Problèmes';

  @override
  String diagnosticCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count diagnostics',
      one: '1 diagnostic',
      zero: 'Aucun diagnostic',
    );
    return '$_temp0';
  }

  @override
  String get files => 'Fichiers';

  @override
  String get toc => 'Table des matières';

  @override
  String get tocActions => 'Actions sur la table des matières';

  @override
  String get markdownUnsaved => 'Markdown – non enregistré';

  @override
  String workspaceDetail(String kind, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers',
      one: '1 fichier',
    );
    return '$kind – $_temp0';
  }

  @override
  String get noFiles => 'Aucun fichier';

  @override
  String get newFile => 'Nouveau fichier';

  @override
  String get noWritersideToc => 'Aucune table des matières Writerside';

  @override
  String get tocSection => 'Section de la table des matières';

  @override
  String get newTopic => 'Nouveau sujet';

  @override
  String get newChildTopic => 'Nouveau sous-sujet';

  @override
  String get newSiblingTopic => 'Nouveau sujet de même niveau';

  @override
  String get renameTopicFile => 'Renommer le fichier du sujet';

  @override
  String get topicPlacement => 'Emplacement dans la table des matières';

  @override
  String get tocRoot => 'À la racine de la table des matières';

  @override
  String get afterSelectedTopic => 'Après le sujet sélectionné';

  @override
  String get insideSelectedTopic => 'Dans le sujet sélectionné';

  @override
  String get pasteAfterTopic => 'Coller après';

  @override
  String get pasteAsChildTopic => 'Coller comme sous-sujet';

  @override
  String get removeFromToc => 'Retirer de la table des matières';

  @override
  String get confirmRemoveFromTocTitle => 'Retirer de la table des matières ?';

  @override
  String confirmRemoveFromTocMessage(String name) {
    return 'Retirer $name de cette table des matières ? Le fichier du sujet sera conservé.';
  }

  @override
  String get confirmDeleteTopicTitle => 'Supprimer le fichier du sujet ?';

  @override
  String confirmDeleteTopicMessage(String name) {
    return 'Supprimer $name et le retirer de toutes les tables des matières ? Cette action est irréversible.';
  }

  @override
  String get safeDeleteTopicFile =>
      'Supprimer le fichier du sujet en toute sécurité…';

  @override
  String get removeTocElement => 'Retirer l’élément de la table des matières';

  @override
  String get reviewUsages => 'Examiner les utilisations';

  @override
  String get deleteTopicFile => 'Supprimer le fichier du sujet';

  @override
  String get removeAction => 'Retirer';

  @override
  String topicRemovalSummary(String topic) {
    return 'Retirez « $topic » de l’instance d’aide sélectionnée. Le fichier du sujet sera conservé.';
  }

  @override
  String safeDeleteTopicSummary(String topic) {
    return 'Supprimez « $topic » et mettez à jour ses références en toute sécurité dans l’ensemble de ce projet Writerside.';
  }

  @override
  String childTopicsPromoted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sujets enfants remonteront d’un niveau.',
      one: '1 sujet enfant remontera d’un niveau.',
    );
    return '$_temp0';
  }

  @override
  String get topicIsStartPageRemovalWarning =>
      'Ce sujet sert de page de démarrage à une instance. Examinez ses utilisations et attribuez une autre page de démarrage avant de continuer.';

  @override
  String topicUsagesCount(int count) {
    return 'Utilisations ($count)';
  }

  @override
  String get noBreakingTopicUsages =>
      'Aucune référence susceptible de ne plus fonctionner n’a été trouvée.';

  @override
  String get topicUsagesFound =>
      'BusyMark a trouvé les références suivantes à ce sujet.';

  @override
  String get topicUsageTocElements => 'Éléments de la table des matières';

  @override
  String get topicUsageStartPages => 'Pages de démarrage';

  @override
  String get topicUsageTopicLinks => 'Liens vers le sujet';

  @override
  String get topicUsageIncludes => 'Inclusions';

  @override
  String usageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count utilisations',
      one: '1 utilisation',
    );
    return '$_temp0';
  }

  @override
  String get refactoringOptions => 'Options de refactorisation';

  @override
  String get updateUsagesAutomatically =>
      'Mettre à jour les utilisations automatiquement';

  @override
  String get updateUsagesAutomaticallyDescription =>
      'Retirer les références des tables des matières et les inclusions, et conserver le texte des liens.';

  @override
  String get manualUsageUpdatesRequired =>
      'Certaines utilisations nécessitent des modifications manuelles avant cette refactorisation.';

  @override
  String get setRedirectTo => 'Rediriger vers';

  @override
  String get noRedirectDescription =>
      'Ne pas rediriger l’ancienne page publiée.';

  @override
  String get redirectTarget => 'Cible de la redirection';

  @override
  String get remainingUsagesBlockRemoval =>
      'Examinez et mettez à jour les utilisations restantes avant de continuer, ou activez les mises à jour automatiques lorsqu’elles sont disponibles.';

  @override
  String usagesOfTopic(String topic) {
    return 'Utilisations de $topic';
  }

  @override
  String get noUsagesFound => 'Aucune utilisation trouvée.';

  @override
  String get outsideSelectedInstance => 'En dehors de l’instance sélectionnée';

  @override
  String get doRefactor => 'Refactoriser';

  @override
  String get orphanTopicTitle => 'Le fichier du sujet n’est plus utilisé';

  @override
  String get keepTopicFile => 'Conserver le fichier du sujet';

  @override
  String orphanTopicMessage(String topic) {
    return '« $topic » n’est plus utilisé nulle part dans ce projet Writerside. Supprimez le fichier ou conservez-le pour l’utiliser dans une autre instance.';
  }

  @override
  String get defaultNewTopicTitle => 'Nouveau sujet';

  @override
  String get topicTitle => 'Titre du sujet';

  @override
  String get fileName => 'Nom de fichier';

  @override
  String get topicTitleRequired => 'Le titre du sujet est obligatoire.';

  @override
  String get fileNameRequired => 'Le nom de fichier est obligatoire.';

  @override
  String get rename => 'Renommer';

  @override
  String get confirmDeleteFileTitle => 'Supprimer le fichier ?';

  @override
  String get confirmDeleteFolderTitle => 'Supprimer le dossier ?';

  @override
  String confirmDeleteFileMessage(String name) {
    return 'Supprimer $name ? Cette action est irréversible.';
  }

  @override
  String confirmDeleteFolderMessage(String name) {
    return 'Supprimer $name et tous les fichiers qu’il contient ? Cette action est irréversible.';
  }

  @override
  String get useSingleSafeFileName =>
      'Utilisez un seul nom de fichier valide, sans séparateur de chemin.';

  @override
  String useExpectedExtension(String extension) {
    return 'Utilisez l’extension $extension pour le format sélectionné.';
  }

  @override
  String get useIdentifierCharacters =>
      'Utilisez des lettres, des chiffres, des traits de soulignement ou des traits d’union avant l’extension.';

  @override
  String get topicIdAlreadyExists => 'L’ID de sujet existe déjà.';

  @override
  String get createWritersideTopicFailed =>
      'Impossible de créer le sujet Writerside.';

  @override
  String get noOutline => 'Aucun plan';

  @override
  String expandKind(String kind) {
    return 'Développer la $kind';
  }

  @override
  String collapseKind(String kind) {
    return 'Réduire la $kind';
  }

  @override
  String get foldKindSection => 'section';

  @override
  String get foldKindList => 'liste';

  @override
  String get foldKindQuote => 'citation';

  @override
  String get foldKindTag => 'balise';

  @override
  String get sourceSearchPreviousMatch => 'Occurrence précédente';

  @override
  String get sourceSearchNextMatch => 'Occurrence suivante';

  @override
  String get sourceSearchCaseSensitive => 'Respecter la casse';

  @override
  String get sourceSearchWholeWord => 'Mot entier';

  @override
  String get sourceSearchRegex => 'Expression régulière';

  @override
  String get sourceSearchInvalidRegex => 'Expression régulière non valide';

  @override
  String get sourceLargeFileFeaturesPaused =>
      'Fichier volumineux : la coloration et le repliage sont suspendus';

  @override
  String get noPreview => 'Aucun aperçu';

  @override
  String get note => 'Note';

  @override
  String get tip => 'Astuce';

  @override
  String get warning => 'Avertissement';

  @override
  String get tabs => 'Onglets';

  @override
  String get tab => 'Onglet';

  @override
  String get procedure => 'Procédure';

  @override
  String get step => 'Étape';

  @override
  String get topic => 'Sujet';

  @override
  String get chapter => 'Chapitre';

  @override
  String couldNotOpenTarget(String target) {
    return 'Impossible d’ouvrir $target';
  }

  @override
  String linkTargetNotFound(String targetPath) {
    return 'Cible du lien introuvable : $targetPath';
  }

  @override
  String get cannotOpenFileTypeInEditor =>
      'Impossible d’ouvrir ce type de fichier dans l’éditeur';

  @override
  String anchorNotFound(String anchor) {
    return 'Ancre introuvable : $anchor';
  }

  @override
  String get noProblemsFound => 'Aucun problème trouvé';

  @override
  String get noResults => 'Aucun résultat';

  @override
  String searchResultLine(String relativePath, int lineNumber) {
    return '$relativePath – ligne $lineNumber';
  }

  @override
  String get untitledResult => 'Résultat sans titre';

  @override
  String get documentKindMarkdownFile => 'Fichier Markdown';

  @override
  String get documentKindWritersideMarkdownTopic => 'Sujet Writerside Markdown';

  @override
  String get documentKindWritersideXmlTopic => 'Sujet Writerside XML';

  @override
  String get documentKindWritersideTree => 'Arborescence Writerside';

  @override
  String get documentKindConfigurationFile => 'Fichier de configuration';

  @override
  String get documentKindVariablesFile => 'Fichier de variables';

  @override
  String get documentKindCategoriesFile => 'Fichier de catégories';

  @override
  String get documentKindResourceFile => 'Fichier de ressources';

  @override
  String workspaceErrorOpenFailed(String error) {
    return 'Échec de l’ouverture : $error';
  }

  @override
  String workspaceErrorCreateWritersideProjectFailed(String error) {
    return 'Impossible de créer le projet Writerside : $error';
  }

  @override
  String workspaceErrorCreateWritersideTopicFailed(String error) {
    return 'Impossible de créer le sujet Writerside : $error';
  }

  @override
  String workspaceErrorCouldNotOpenFile(String error) {
    return 'Impossible d’ouvrir le fichier : $error';
  }

  @override
  String get workspaceErrorChooseWhereToSaveMarkdown =>
      'Choisissez où enregistrer ce fichier Markdown.';

  @override
  String get workspaceErrorSaveBlockedFileChangedOnDisk =>
      'Enregistrement bloqué : le fichier a été modifié sur le disque.';

  @override
  String workspaceErrorSaveFailed(String error) {
    return 'Échec de l’enregistrement : $error';
  }

  @override
  String workspaceErrorFileOperationFailed(String error) {
    return 'Échec de l’opération sur le fichier : $error';
  }

  @override
  String workspaceErrorValidationFailed(String error) {
    return 'Échec de la validation : $error';
  }

  @override
  String errorPathDoesNotExist(String path) {
    return 'Le chemin n’existe pas : $path';
  }

  @override
  String errorTargetDirectoryNotEmpty(String path) {
    return 'Le répertoire cible existe déjà et n’est pas vide : $path';
  }

  @override
  String errorTargetPathNotDirectory(String path) {
    return 'Le chemin cible existe déjà et n’est pas un répertoire : $path';
  }

  @override
  String errorGeneratedFileAlreadyExists(String path) {
    return 'Le fichier généré existe déjà : $path';
  }

  @override
  String get errorParentDirectoryRequired =>
      'Le répertoire parent est obligatoire.';

  @override
  String errorParentDirectoryMissing(String path) {
    return 'Le répertoire parent n’existe pas : $path';
  }

  @override
  String errorDirectoryMissing(String path) {
    return 'Le répertoire n’existe pas : $path';
  }

  @override
  String errorPathAlreadyExists(String path) {
    return 'Le chemin existe déjà : $path';
  }

  @override
  String get errorFileNameRequired => 'Le nom de fichier est requis.';

  @override
  String get errorFileNameUnsafe =>
      'Le nom de fichier doit être un seul segment de chemin sûr.';

  @override
  String get errorFileOperationInvalidTarget =>
      'Impossible de déplacer un dossier dans lui-même.';

  @override
  String get errorFileOperationOutsideRoot =>
      'L’opération sur le fichier doit rester dans l’espace de travail.';

  @override
  String get errorFileOperationRoot =>
      'La racine de l’espace de travail ne peut pas être modifiée depuis l’arborescence.';

  @override
  String get errorProjectNameRequired => 'Le nom du projet est obligatoire.';

  @override
  String get errorDirectoryNameRequired =>
      'Le nom du répertoire est obligatoire.';

  @override
  String get errorDirectoryNameUnsafe =>
      'Le nom du répertoire doit être un seul segment de chemin valide.';

  @override
  String get errorInstanceIdInvalid =>
      'L’ID d’instance doit commencer par une lettre minuscule et contenir uniquement des lettres minuscules, des chiffres, des traits de soulignement et des traits d’union.';

  @override
  String get errorTopicFileInvalid =>
      'Le nom du fichier de sujet doit être un nom de fichier Markdown sans séparateurs de chemin.';

  @override
  String get errorTopicTitleRequired => 'Le titre du sujet est obligatoire.';

  @override
  String errorWritersideModuleRootMissing(String path) {
    return 'La racine du module Writerside n’existe pas : $path';
  }

  @override
  String get errorWritersideModuleNotOpen =>
      'Un module Writerside doit être ouvert pour créer un sujet.';

  @override
  String get errorWritersideInstanceTreeMissing =>
      'Le module Writerside n’a pas d’arborescence d’instance d’aide.';

  @override
  String errorWritersideTreeFileMissing(String path) {
    return 'Le fichier d’arborescence Writerside n’existe pas : $path';
  }

  @override
  String errorTopicIdAlreadyExists(String topicId) {
    return 'L’ID de sujet « $topicId » existe déjà dans ce module d’aide.';
  }

  @override
  String errorTopicFileAlreadyExists(String path) {
    return 'Le fichier de sujet existe déjà : $path';
  }

  @override
  String errorReferenceTopicMissing(String topic) {
    return 'Le sujet de référence n’est pas présent dans l’arborescence sélectionnée : $topic';
  }

  @override
  String get errorWritersideTocNodeMissing =>
      'L’entrée sélectionnée de la table des matières n’existe plus.';

  @override
  String get errorWritersideTocInvalidMove =>
      'Une entrée de la table des matières ne peut pas être déplacée dans elle-même ni dans l’un de ses descendants.';

  @override
  String errorWritersideStartTopicDelete(String topic) {
    return 'Le sujet de démarrage $topic ne peut pas être supprimé. Choisissez d’abord une autre page de démarrage.';
  }

  @override
  String get errorWritersideSafeDeleteRequired =>
      'Utilisez la suppression sécurisée pour les fichiers de sujet Writerside.';

  @override
  String get errorWritersideTopicUsageScanFailed =>
      'L’analyse des utilisations du sujet n’a pas pu aboutir. Aucun fichier n’a été modifié.';

  @override
  String get errorWritersideTopicUsagesRemain =>
      'Certaines utilisations du sujet nécessitent encore votre intervention. Examinez-les avant de continuer.';

  @override
  String get errorWritersideRedirectInvalid =>
      'La cible de redirection sélectionnée n’est plus valide. Sélectionnez-la de nouveau.';

  @override
  String errorWritersideRollbackFailed(String paths) {
    return 'La suppression du sujet n’a pas pu être entièrement annulée. Vérifiez ces chemins avant de continuer : $paths';
  }

  @override
  String get errorTopicsRootUnsafe =>
      'La racine des sujets doit être un répertoire relatif valide.';

  @override
  String get errorTopicFileNameUnsafe =>
      'Le nom du fichier de sujet doit être un seul segment de chemin valide.';

  @override
  String errorTopicFileExtensionMismatch(String extension) {
    return 'L’extension du fichier de sujet doit correspondre au format sélectionné ($extension).';
  }

  @override
  String get errorTopicFileNameInvalid =>
      'Le nom du fichier de sujet doit contenir uniquement des lettres, des chiffres, des traits de soulignement et des traits d’union.';

  @override
  String errorUnknown(String code) {
    return 'Erreur inconnue : $code';
  }

  @override
  String diagnosticWorkspaceFileStatFailed(String error) {
    return 'Impossible de lire les métadonnées du fichier : $error';
  }

  @override
  String get diagnosticWorkspaceScanSkipped =>
      'Espace de travail volumineux détecté. Certains fichiers ont été ignorés pour que l’application reste réactive.';

  @override
  String diagnosticWorkspaceScanInspectFailed(String error) {
    return 'Impossible d’inspecter l’entrée de l’espace de travail : $error';
  }

  @override
  String get diagnosticWorkspaceFileTooLarge =>
      'Le fichier dépasse la limite d’analyse automatique de la version bêta.';

  @override
  String diagnosticWorkspaceFileReadFailed(String error) {
    return 'Impossible de lire le fichier Markdown : $error';
  }

  @override
  String get diagnosticMarkdownAttributeMalformed =>
      'Bloc d’attributs de titre Writerside mal formé.';

  @override
  String diagnosticMarkdownHeadingDuplicateId(String id) {
    return 'ID de titre en double : « $id ».';
  }

  @override
  String get diagnosticWritersideTopicH1ConvertedToChapter =>
      'Les titres H1 de premier niveau supplémentaires sont traités comme des chapitres.';

  @override
  String get diagnosticWritersideMarkdownTopicMissingTitle =>
      'Le sujet Markdown Writerside n’a pas de titre H1 ni de titre dans le front matter.';

  @override
  String get diagnosticWritersideXmlTopicMissingTitle =>
      'Le sujet XML n’a pas de titre.';

  @override
  String diagnosticWritersideTopicFileMissingTitle(String fileName) {
    return 'Le sujet « $fileName » n’a pas de titre.';
  }

  @override
  String get diagnosticMarkdownFrontMatterMalformed =>
      'Le front matter n’est pas fermé.';

  @override
  String get diagnosticMarkdownRawHtmlUnsafe => 'Élément HTML non sûr.';

  @override
  String diagnosticMarkdownLinkUnresolvedTarget(String targetPath) {
    return 'La cible du lien n’existe pas : $targetPath';
  }

  @override
  String diagnosticMarkdownLinkUnresolvedAnchor(String anchor) {
    return 'L’ancre « $anchor » n’existe pas.';
  }

  @override
  String diagnosticMarkdownImageMissingAlt(String destination) {
    return 'L’image « $destination » ne contient pas de texte alternatif.';
  }

  @override
  String diagnosticMarkdownImageMissingFile(String destination) {
    return 'L’image n’existe pas : $destination';
  }

  @override
  String diagnosticInvalidXml(String message) {
    return 'XML non valide : $message';
  }

  @override
  String get diagnosticWritersideConfigInvalidRoot =>
      'La racine de writerside.cfg doit être <ihp>.';

  @override
  String get diagnosticWritersideConfigMissingSnippetsSrc =>
      'L’élément snippets n’a pas d’attribut src.';

  @override
  String get diagnosticWritersideConfigMissingInstanceGroupsSrc =>
      'L’élément instance-groups n’a pas d’attribut src.';

  @override
  String diagnosticWritersideConfigInvalidKeymapsMode(String mode) {
    return 'Mode de raccourcis clavier non pris en charge : $mode';
  }

  @override
  String get diagnosticWritersideConfigMissingInstanceSrc =>
      'La déclaration d’instance n’a pas d’attribut src.';

  @override
  String get diagnosticWritersideConfigMissingInstance =>
      'writerside.cfg ne déclare aucune instance.';

  @override
  String get diagnosticWritersideTreeInvalidRoot =>
      'La racine .tree doit être <instance-profile>.';

  @override
  String get diagnosticWritersideTreeMissingId =>
      'Le profil d’instance n’a pas d’attribut id.';

  @override
  String diagnosticWritersideTreeIdMismatch(String id) {
    return 'Le nom de base du fichier d’arborescence ne correspond pas à l’ID d’instance « $id ».';
  }

  @override
  String get diagnosticWritersideTreeMissingStartPage =>
      'Une instance qui n’est pas une bibliothèque n’a pas d’attribut start-page.';

  @override
  String diagnosticWritersideStartPageMissing(String startPage) {
    return 'La page de démarrage « $startPage » n’existe pas.';
  }

  @override
  String diagnosticWritersideTreeDuplicateTopic(String topic) {
    return 'Le sujet « $topic » apparaît plusieurs fois dans cette table des matières d’instance.';
  }

  @override
  String get diagnosticWritersideVariableMalformedDeclaration =>
      'La déclaration de variable doit avoir un nom et une valeur.';

  @override
  String diagnosticWritersideVariableDuplicateName(String name) {
    return 'La variable « $name » est déclarée plusieurs fois.';
  }

  @override
  String get diagnosticWritersideCategoryMissingId =>
      'La catégorie n’a pas d’ID.';

  @override
  String diagnosticWritersideCategoryDuplicateId(String id) {
    return 'La catégorie « $id » est déclarée plusieurs fois.';
  }

  @override
  String diagnosticWritersideCategoryDuplicateOrder(String order) {
    return 'L’ordre de catégorie « $order » est déclaré plusieurs fois.';
  }

  @override
  String get diagnosticWritersideTopicInvalidRoot =>
      'La racine .topic doit être <topic>.';

  @override
  String get diagnosticWritersideTopicMissingRootId =>
      'Le sujet XML n’a pas d’ID racine.';

  @override
  String diagnosticWritersideTopicRootIdMismatch(String id, String expectedId) {
    return 'L’ID racine du sujet XML « $id » doit correspondre au nom de fichier « $expectedId ».';
  }

  @override
  String diagnosticWritersideTopicDuplicateElementId(String elementId) {
    return 'L’ID d’élément « $elementId » apparaît plusieurs fois.';
  }

  @override
  String get diagnosticWritersideTopicAnchorMissingHref =>
      'L’élément <a> n’a pas d’attribut href.';

  @override
  String get diagnosticWritersideConfigMissing =>
      'Le mode Writerside nécessite writerside.cfg.';

  @override
  String diagnosticWritersideConfigMissingBuildConfigDirectory(
    String relativePath,
  ) {
    return 'Le répertoire configuré pour la compilation est introuvable : $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingApiSpecificationsDirectory(
    String relativePath,
  ) {
    return 'Le répertoire des spécifications d’API configuré est introuvable : $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingSnippetsDirectory(
    String relativePath,
  ) {
    return 'Le répertoire des extraits configuré est introuvable : $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingVarsFile(String relativePath) {
    return 'Le fichier de variables configuré est introuvable : $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingCategoriesFile(String relativePath) {
    return 'Le fichier de catégories configuré est introuvable : $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceGroupsFile(
    String relativePath,
  ) {
    return 'Le fichier de groupes d’instances configuré est introuvable : $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceTree(String source) {
    return 'L’arborescence d’instance enregistrée « $source » est introuvable.';
  }

  @override
  String diagnosticWritersideTopicReadFailed(String error) {
    return 'Impossible de lire le fichier de sujet : $error';
  }

  @override
  String diagnosticWritersideDefaultTopicsDirectoryMissing(
    String relativePath,
  ) {
    return 'Le répertoire des sujets par défaut est introuvable : $relativePath';
  }

  @override
  String diagnosticWritersideTopicsDirectoryMissing(String relativePath) {
    return 'Le répertoire des sujets configuré est introuvable : $relativePath';
  }

  @override
  String diagnosticWritersideImagesDirectoryMissing(String relativePath) {
    return 'Le répertoire des images configuré est introuvable : $relativePath';
  }

  @override
  String diagnosticWritersideTopicDuplicateId(String id) {
    return 'L’ID d’élément « $id » apparaît plusieurs fois.';
  }

  @override
  String diagnosticWritersideTreeMissingTopic(String topic) {
    return 'La table des matières fait référence à un sujet manquant : « $topic ».';
  }

  @override
  String diagnosticWritersideTreeInvalidHref(String href) {
    return 'L’attribut href externe « $href » n’est pas valide.';
  }

  @override
  String diagnosticWritersideVariableUnresolved(String name) {
    return 'La variable « %$name% » n’est pas déclarée.';
  }

  @override
  String diagnosticWritersideTopicLinkUnresolved(String destination) {
    return 'Le lien vers le sujet « $destination » ne peut pas être résolu.';
  }

  @override
  String diagnosticWritersideAnchorUnresolved(
    String anchor,
    String targetName,
  ) {
    return 'L’ancre « $anchor » n’existe pas dans « $targetName ».';
  }

  @override
  String get diagnosticWritersideIncludeMissingFrom =>
      'L’élément <include> n’a pas d’attribut from.';

  @override
  String diagnosticWritersideIncludeSourceMissing(String from) {
    return 'La source d’inclusion « $from » n’existe pas.';
  }

  @override
  String diagnosticWritersideIncludeElementMissing(
    String elementId,
    String from,
  ) {
    return 'L’élément d’inclusion « $elementId » n’existe pas dans « $from ».';
  }

  @override
  String diagnosticWritersideCategoryUnresolved(String ref) {
    return 'La catégorie seealso « $ref » n’est pas déclarée.';
  }

  @override
  String diagnosticWritersideTopicAmbiguousReference(String reference) {
    return 'La référence de sujet « $reference » est ambiguë.';
  }

  @override
  String diagnosticUnknown(String code) {
    return 'Diagnostic inconnu : $code';
  }

  @override
  String get close => 'Fermer';

  @override
  String get git => 'Git';

  @override
  String get gitDiff => 'Diff Git';

  @override
  String get gitShowDiff => 'Afficher le diff';

  @override
  String gitDiffHunkRange(String oldRange, String newRange) {
    return 'ancien $oldRange → nouveau $newRange';
  }

  @override
  String get gitDiffNoLines => 'aucune ligne';

  @override
  String get gitUnavailableTitle => 'Git est indisponible';

  @override
  String gitUnavailableMessage(String reason) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'other':
          'Installez Git ou configurez BusyMark pour utiliser un exécutable Git disponible. $reason',
    });
    return '$_temp0';
  }

  @override
  String get gitTrustRequiredTitle =>
      'Faire confiance à cet espace de travail pour Git ?';

  @override
  String get gitTrustRequiredMessage =>
      'Les dépôts Git peuvent exécuter des programmes au moyen de hooks, de filtres et d’autres options de configuration. Faites confiance à cet espace de travail avant que BusyMark lise les données du dépôt ou active les actions Git.';

  @override
  String get gitTrustWorkspace => 'Faire confiance à l’espace de travail';

  @override
  String get gitNotRepositoryTitle => 'Pas un dépôt Git';

  @override
  String get gitNotRepositoryMessage =>
      'Cet espace de travail ne se trouve pas dans un dépôt Git.';

  @override
  String get gitInitializeRepository => 'Initialiser le dépôt';

  @override
  String get gitDetachedHead => 'HEAD détachée';

  @override
  String gitDetachedHeadAt(String commit) {
    return 'Détachée sur $commit';
  }

  @override
  String get gitNoUpstream => 'Aucune branche en amont';

  @override
  String gitAheadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commits non poussés',
      one: '1 commit non poussé',
    );
    return '$_temp0';
  }

  @override
  String gitBehindCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commits à récupérer',
      one: '1 commit à récupérer',
    );
    return '$_temp0';
  }

  @override
  String get gitClean => 'Propre';

  @override
  String get gitConflicts => 'Conflits';

  @override
  String get gitChanges => 'Modifications';

  @override
  String get gitStaged => 'Indexés';

  @override
  String get gitUnstaged => 'Non indexés';

  @override
  String get gitHistory => 'Historique';

  @override
  String get gitBranches => 'Branches';

  @override
  String get gitActions => 'Actions Git';

  @override
  String get gitPull => 'Pull';

  @override
  String get gitFetch => 'Récupérer';

  @override
  String get gitPush => 'Push';

  @override
  String get gitCommit => 'Commit';

  @override
  String get gitSelectForCommit => 'Indexer le fichier';

  @override
  String get gitRemoveFromCommit => 'Désindexer le fichier';

  @override
  String get gitDiscard => 'Abandonner';

  @override
  String get gitOpenFile => 'Ouvrir le fichier';

  @override
  String get gitMarkResolved => 'Marquer comme résolu';

  @override
  String get gitUntracked => 'Fichiers non suivis';

  @override
  String get gitCommitMessage => 'Message de commit';

  @override
  String get gitCommitSelectedFiles => 'Fichiers sélectionnés';

  @override
  String get gitCommitNoSelectedFiles =>
      'Indexez au moins un fichier avant de créer le commit.';

  @override
  String gitStagedFileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers indexés',
      one: '1 fichier indexé',
    );
    return '$_temp0';
  }

  @override
  String get gitOutsideWorkspace => 'Hors de l’espace de travail';

  @override
  String get gitCommitMessageRequired => 'Saisissez un message de commit.';

  @override
  String get gitCreateBranch => 'Créer une branche';

  @override
  String get gitNewBranch => 'Nouvelle branche';

  @override
  String get gitBranchName => 'Nom de la branche';

  @override
  String get gitSwitchBranch => 'Changer';

  @override
  String get gitNoChanges => 'Aucune modification';

  @override
  String get gitNoHistory => 'Aucun historique';

  @override
  String get gitNoBranches => 'Aucune branche';

  @override
  String get gitNoDiff => 'Aucun diff à afficher';

  @override
  String get gitBinaryFile =>
      'Fichier binaire. BusyMark n’affiche pas les patchs binaires.';

  @override
  String gitBinaryFileInfo(int size) {
    return 'Fichier binaire ($size octets). BusyMark n’affiche pas les correctifs binaires.';
  }

  @override
  String get gitUnsavedChangesBanner =>
      'Les modifications non enregistrées de l’éditeur ne sont incluses qu’après leur enregistrement.';

  @override
  String get gitConfirmDiscardTitle => 'Abandonner les modifications Git ?';

  @override
  String gitConfirmDiscardTracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Les fichiers suivis sélectionnés seront restaurés depuis Git.',
      one: 'Le fichier suivi sélectionné sera restauré depuis Git.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardUntracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Les fichiers non suivis sélectionnés seront supprimés.',
      one: 'Le fichier non suivi sélectionné sera supprimé.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardMixed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Les fichiers sélectionnés seront restaurés ou supprimés selon leur état Git.',
      one:
          'Le fichier sélectionné sera restauré ou supprimé selon son état Git.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmSwitchBranchTitle(String branch) {
    return 'Passer à $branch ?';
  }

  @override
  String get gitConfirmSwitchBranchMessage =>
      'BusyMark rechargera l’espace de travail depuis le disque après le changement de branche par Git.';

  @override
  String get gitConfirmPushSetUpstreamTitle => 'Définir la branche en amont ?';

  @override
  String gitConfirmPushSetUpstreamMessage(String branch) {
    return 'Cette branche n’a pas de branche en amont. BusyMark peut pousser $branch et définir sa branche en amont lorsqu’un seul dépôt distant est configuré.';
  }

  @override
  String get gitProjectHistory => 'Projet';

  @override
  String get gitFileHistory => 'Fichier actuel';

  @override
  String get gitFileHistoryRequiresOpenFile =>
      'L’historique du fichier nécessite un fichier Markdown ouvert.';

  @override
  String get gitLoadMore => 'Charger plus';

  @override
  String get gitChangesInCommit => 'Modifications de ce commit';

  @override
  String get gitCompareWithCurrent => 'Comparer avec la version actuelle';

  @override
  String get gitRestoreVersion => 'Restaurer cette version';

  @override
  String get gitConfirmRestoreTitle => 'Restaurer cette version du fichier ?';

  @override
  String get gitConfirmRestoreMessage =>
      'BusyMark remplacera le fichier actuel de l’arbre de travail par la version sélectionnée du commit. Le fichier restauré restera non indexé.';

  @override
  String get gitCommitActions => 'Actions du commit';

  @override
  String get gitResetCurrentBranchToHere =>
      'Réinitialiser la branche actuelle ici…';

  @override
  String gitResetCurrentBranchTitle(String branch, String commit) {
    return 'Réinitialiser $branch sur $commit ?';
  }

  @override
  String gitResetCurrentBranchMessage(String branch, String commit) {
    return 'Cette action déplace la branche $branch sur le commit $commit. Choisissez comment Git met à jour l’index et l’arbre de travail.';
  }

  @override
  String get gitReset => 'Réinitialiser';

  @override
  String get gitResetModeSoft => 'Soft';

  @override
  String get gitResetModeSoftDescription =>
      'Déplacer uniquement la branche. Conserver l’index et l’arbre de travail ; les différences par rapport au commit sélectionné restent indexées.';

  @override
  String get gitResetModeMixed => 'Mixed';

  @override
  String get gitResetModeMixedDescription =>
      'Déplacer la branche et réinitialiser l’index. Conserver l’arbre de travail, en laissant les différences non indexées.';

  @override
  String get gitResetModeHard => 'Hard';

  @override
  String get gitResetModeHardDescription =>
      'Déplacer la branche et réinitialiser l’index et l’arbre de travail. Les modifications suivies sont abandonnées ; les fichiers non suivis qui bloquent l’opération peuvent être supprimés.';

  @override
  String get gitResetModeKeep => 'Keep';

  @override
  String get gitResetModeKeepDescription =>
      'Déplacer la branche et réinitialiser les fichiers suivis tout en conservant les modifications locales. Git abandonne si elles entrent en conflit avec la réinitialisation.';

  @override
  String gitAdditionsDeletions(int additions, int deletions) {
    return '+$additions -$deletions';
  }

  @override
  String get fileActions => 'Actions sur le fichier';

  @override
  String get gitStatusAdded => 'Ajouté';

  @override
  String get gitStatusDeleted => 'Supprimé';

  @override
  String get gitStatusRenamed => 'Renommé';

  @override
  String get gitStatusCopied => 'Copié';

  @override
  String get gitStatusUntracked => 'Non suivi';

  @override
  String get gitStatusConflicted => 'En conflit';

  @override
  String get gitStatusIgnored => 'Ignoré';

  @override
  String get gitStatusTypeChanged => 'Type modifié';

  @override
  String get gitStatusModified => 'Modifié';

  @override
  String get gitStatusUnknown => 'Inconnu';

  @override
  String get gitErrorUnavailable => 'Git est indisponible.';

  @override
  String get gitErrorNotRepository =>
      'Cet espace de travail n’est pas un dépôt Git.';

  @override
  String get gitErrorUnsafePath => 'BusyMark a bloqué un chemin Git non sûr.';

  @override
  String get gitErrorInvalidBranchName => 'Saisissez un nom de branche valide.';

  @override
  String get gitErrorNoRemote => 'Aucun dépôt Git distant n’est configuré.';

  @override
  String get gitErrorNoUpstream => 'Aucune branche en amont n’est configurée.';

  @override
  String get gitErrorMultipleRemotes =>
      'Plusieurs dépôts distants sont configurés. Choisissez une branche en amont en dehors de cette version de BusyMark.';

  @override
  String get gitErrorDirtyWorkspace =>
      'Enregistrez ou abandonnez les modifications de l’éditeur BusyMark avant de changer de branche.';

  @override
  String get gitErrorResetDirtyWorkspace =>
      'Enregistrez ou abandonnez les modifications de l’éditeur BusyMark avant de réinitialiser la branche actuelle.';

  @override
  String get gitErrorRestoreStagedFile =>
      'Retirez le fichier de l’index avant de restaurer une version antérieure.';

  @override
  String get gitErrorResetDetachedHead =>
      'Basculez sur une branche avant de la réinitialiser.';

  @override
  String get gitErrorDiverged =>
      'La branche a divergé. Résolvez la fusion ou le rebasage en dehors de cette version de BusyMark.';

  @override
  String get gitErrorAuthentication =>
      'L’authentification Git a échoué. Dans le snap, les dépôts SSH distants peuvent nécessiter la connexion de l’interface ssh-keys.';

  @override
  String get gitErrorNetwork => 'L’opération réseau Git a échoué.';

  @override
  String get gitErrorConflict => 'Git a signalé des conflits non résolus.';

  @override
  String get gitErrorCommandFailed => 'La commande Git a échoué.';

  @override
  String get markdownAndHtml => 'Markdown et HTML';

  @override
  String get markdownHtmlMarkdownBlocks => 'Blocs Markdown';

  @override
  String get markdownHtmlMarkdownBlocksDescription =>
      'Structures de blocs prises en charge dans la source Markdown et l’aperçu.';

  @override
  String get markdownHtmlInlineFormatting => 'Markdown en ligne';

  @override
  String get markdownHtmlInlineFormattingDescription =>
      'Mise en forme utilisable dans les paragraphes, listes et cellules de tableau.';

  @override
  String get markdownHtmlRawHtmlBlocks => 'Blocs HTML bruts';

  @override
  String get markdownHtmlRawHtmlBlocksDescription =>
      'Balises HTML de bloc sûres rendues par les widgets d’aperçu BusyMark.';

  @override
  String get markdownHtmlRawHtmlInline => 'Balises HTML brutes en ligne';

  @override
  String get markdownHtmlRawHtmlInlineDescription =>
      'Balises HTML en ligne sûres rendues sans afficher les balises littérales.';

  @override
  String get markdownHtmlSafety => 'Règles de sécurité';

  @override
  String get markdownHtmlSafetyDescription =>
      'Le HTML brut est analysé et assaini avant le rendu de l’aperçu.';

  @override
  String get markdownHtmlHeadings => 'Titres';

  @override
  String get markdownHtmlParagraphs => 'Paragraphes';

  @override
  String get markdownHtmlLists => 'Listes';

  @override
  String get markdownHtmlHtmlContainers => 'Conteneurs';

  @override
  String get markdownHtmlHtmlTextBlocks => 'Blocs de texte';

  @override
  String get markdownHtmlHtmlFigures => 'Figures et images';

  @override
  String get markdownHtmlHtmlPreformatted => 'Code préformaté';

  @override
  String get markdownHtmlHtmlDisclosure => 'Blocs dépliables';

  @override
  String get markdownHtmlHtmlDescriptionLists => 'Listes de description';

  @override
  String get markdownHtmlHtmlFormattingTags => 'Balises de mise en forme';

  @override
  String get markdownHtmlHtmlInlineCodeTags => 'Balises de code en ligne';

  @override
  String get markdownHtmlHtmlNeutralInlineTags => 'Balises de texte sémantique';

  @override
  String get markdownHtmlSanitizedPreview => 'Aperçu assaini';

  @override
  String get markdownHtmlSanitizedPreviewDescription =>
      'Le HTML autorisé est converti en blocs d’aperçu BusyMark et n’est pas rendu dans un navigateur.';

  @override
  String get markdownHtmlSourcePreserved => 'Source conservée';

  @override
  String get markdownHtmlSourcePreservedDescription =>
      'Le HTML brut non modifié est enregistré exactement comme texte source.';

  @override
  String get markdownHtmlMarkdownInsideHtml => 'Markdown dans HTML';

  @override
  String get markdownHtmlMarkdownInsideHtmlDescription =>
      'Les marqueurs Markdown dans le HTML brut sont affichés comme texte littéral.';

  @override
  String get markdownHtmlBlockedContent => 'Contenu actif bloqué';

  @override
  String get markdownHtmlBlockedContentDescription =>
      'Les scripts, styles, cadres, formulaires, SVG, MathML, événements et attributs dangereux sont bloqués.';

  @override
  String get markdownHtmlSafeUrls => 'URL sûres uniquement';

  @override
  String get markdownHtmlSafeUrlsDescription =>
      'Les liens acceptent http, https, mailto, tel, les URL relatives et les fragments ; les schémas dangereux sont bloqués.';

  @override
  String get exportAsPdf => 'Exporter en PDF';

  @override
  String get pdfExportDescription =>
      'Choisissez la mise en page pour obtenir un PDF soigné et autonome.';

  @override
  String get pdfRemoteImagesNote =>
      'Les images distantes ne sont pas téléchargées pendant l’exportation. Les images locales sont incluses lorsqu’elles sont disponibles.';

  @override
  String get pdfPageSize => 'Format de page';

  @override
  String get pdfPageSizeA4 => 'A4';

  @override
  String get pdfPageSizeLetter => 'Lettre';

  @override
  String get pdfOrientation => 'Orientation';

  @override
  String get pdfPortrait => 'Portrait';

  @override
  String get pdfLandscape => 'Paysage';

  @override
  String get pdfMargins => 'Marges';

  @override
  String get pdfMarginNarrow => 'Étroites';

  @override
  String get pdfMarginNormal => 'Normales';

  @override
  String get pdfMarginWide => 'Larges';

  @override
  String get pdfIncludePageNumbers => 'Inclure les numéros de page';

  @override
  String get export => 'Exporter';

  @override
  String get exportingPdf => 'Exportation du PDF…';

  @override
  String get fileTypePdf => 'Document PDF';

  @override
  String pdfExported(String fileName) {
    return '$fileName a été exporté.';
  }

  @override
  String pdfExportedWithWarnings(String fileName, int count) {
    return '$fileName a été exporté. Images non incluses : $count.';
  }

  @override
  String get pdfExportUnavailable =>
      'Le composant d’exportation PDF est manquant. Réinstallez BusyMark et réessayez.';

  @override
  String get pdfExportTimedOut =>
      'L’exportation PDF a pris trop de temps et a été arrêtée.';

  @override
  String get pdfExportFailed =>
      'BusyMark n’a pas pu exporter ce document en PDF.';

  @override
  String get visualizationRendering => 'Rendu en cours…';

  @override
  String get visualizationStale => 'Affichage du dernier rendu valide';

  @override
  String get visualizationShowSource => 'Afficher la source';

  @override
  String get visualizationShowRender => 'Afficher le rendu';

  @override
  String get visualizationFitWidth => 'Ajuster à la largeur';

  @override
  String get visualizationSaveImage => 'Enregistrer l’image';

  @override
  String get visualizationCopyImage => 'Copier l’image';

  @override
  String get visualizationImageCopied => 'Image copiée';

  @override
  String get visualizationOpenApiReference => 'Ouvrir la référence de l’API';

  @override
  String get visualizationValid => 'Valide';

  @override
  String get visualizationInvalid => 'Invalide';

  @override
  String get visualizationServers => 'Serveurs';

  @override
  String get visualizationPaths => 'Chemins';

  @override
  String get visualizationOperations => 'Opérations';

  @override
  String get visualizationTags => 'Étiquettes';

  @override
  String get visualizationNoOperations => 'Aucune opération correspondante';

  @override
  String get visualizationSearchOperations => 'Rechercher des opérations';

  @override
  String get visualizationRenderFailed =>
      'Impossible de générer cette visualisation.';

  @override
  String get visualizationRetry => 'Réessayer';

  @override
  String visualizationSaved(String fileName) {
    return 'Fichier enregistré : $fileName';
  }

  @override
  String get shortcutExportPdfDescription =>
      'Exporter le document Markdown actif en PDF.';
}
