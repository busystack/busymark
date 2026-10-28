// ignore_for_file: text_direction_code_point_in_literal, text_direction_code_point_in_comment

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get notesNewFromRetainedText => 'Nueva nota del texto conservado';

  @override
  String get notesAccountThrottled =>
      'Nextcloud solicitó una pausa. Espere antes de iniciar sesión de nuevo.';

  @override
  String get notesSettingsRefreshing =>
      'Actualizando Notes tras confirmar los ajustes';

  @override
  String get notesExportOperationFailed =>
      'La exportación falló antes de publicarse. Compruebe el origen y el destino y vuelva a exportar.';

  @override
  String get notesRecoveryCreatedNotOpened =>
      'La nota recuperada se guardó, pero no pudo abrirse. Resuelva los cambios pendientes del editor o de propiedades y abra esta nota existente.';

  @override
  String get notesSettingsPendingNotes =>
      'Hay notas pendientes, conflictos o creaciones inciertas que bloquean este cambio. Sincronícelos o revíselos en Notes y vuelva a guardar este borrador conservado.';

  @override
  String get notesSettingsPendingAttachments =>
      'Hay operaciones de adjuntos que bloquean este cambio. Revise los adjuntos en Notes y vuelva a guardar este borrador conservado.';

  @override
  String get notesAccountServerAddress =>
      'Use la dirección HTTPS canónica de Nextcloud y vuelva a iniciar sesión. No se pudo verificar la dirección o la redirección.';

  @override
  String get notesAccountUnsupported =>
      'Notes no está disponible o su API no es compatible. Active Nextcloud Notes con la API de versión principal 1 y secundaria 4 o posterior.';

  @override
  String get notesAccountAuthorizeAgain =>
      'Nextcloud rechazó las credenciales. Vuelva a autorizar la cuenta o a conectarla.';

  @override
  String get notesAccountCheckForbidden =>
      'Nextcloud denegó la comprobación de funciones de Notes. Solicite permiso al administrador y reinténtelo.';

  @override
  String get notesAccountMalformed =>
      'No se pudo verificar la respuesta de Nextcloud. Compruebe la instalación del servidor y vuelva a iniciar sesión.';

  @override
  String get notesAccountTimedOut =>
      'El inicio de sesión caducó. Reinícielo y complete la autorización en el navegador.';

  @override
  String get notesAccountBrowserUnavailable =>
      'No se pudo abrir el navegador del sistema. Compruebe el navegador predeterminado y vuelva a iniciar sesión.';

  @override
  String get notesAccountNetwork =>
      'No se pudo contactar con Nextcloud. Compruebe la conexión y el servidor y vuelva a iniciar sesión.';

  @override
  String get notesAccountRejected =>
      'Nextcloud rechazó la solicitud de funciones. Revise el acceso con el administrador y reinténtelo.';

  @override
  String get notesAccountFailed =>
      'No se pudo configurar la cuenta. Vuelva a iniciar sesión.';

  @override
  String get notesTransferSourceChanged =>
      'El origen cambió desde la revisión. Revise el archivo actual o capture otra instantánea antes de reintentar.';

  @override
  String get notesTransferUnreadable =>
      'No se pudo leer el origen. Compruebe el acceso al archivo o carpeta y vuelva a revisarlo.';

  @override
  String get notesTransferInvalidSnapshot =>
      'La instantánea no es válida o compatible. Elija una instantánea válida de BusyMark Notes o un origen Markdown.';

  @override
  String get notesTransferMediaLimit =>
      'Los medios superan el límite de importación. Reduzca los del elemento afectado y vuelva a revisarlo.';

  @override
  String get notesTransferUnsafeSource =>
      'El origen contiene una ruta insegura. Elija archivos dentro de la carpeta de origen y revíselos.';

  @override
  String get notesTransferDestination =>
      'No se pudo escribir la exportación. Compruebe el acceso y el espacio libre en el destino y reinténtelo.';

  @override
  String get notesTransferOperationFailed =>
      'La transferencia falló. Revise los elementos afectados y reinténtelo. Los ya importados siguen guardados.';

  @override
  String get notesExportPublishedWithOmissions =>
      'Exportación disponible con omisiones';

  @override
  String get notesBatchUnchanged =>
      'Los valores solicitados ya estaban establecidos.';

  @override
  String get notesBatchReadOnly =>
      'Esta nota es de solo lectura. Las propiedades protegidas no pueden cambiar; Favorito sigue permitido.';

  @override
  String get notesBatchReviewChanged =>
      'Esta nota cambió desde la revisión. Revise su estado actual antes de repetir la acción.';

  @override
  String get notesBatchMissing =>
      'Esta nota ya no está disponible. Actualice la lista y revise los destinos.';

  @override
  String get notesBatchStorage =>
      'Falló el guardado local. Compruebe el almacenamiento y reintente este elemento; los correctos siguen guardados.';

  @override
  String get notesRemoteReviewChanged =>
      'La nota del servidor cambió. Se conserva su borrador de combinación. Revise la nueva comparación y decida de nuevo cómo resolverla.';

  @override
  String get notesReviewRemote => 'He revisado la versión actual del servidor';

  @override
  String get wsModuleCapsNotPublished =>
      'No se publica la capitalización del módulo.';

  @override
  String get wsTitleOverridesAction => 'Títulos de instancia e índice…';

  @override
  String get wsHeadingNotPublished => 'Este generador no lo publica.';

  @override
  String get wsMarkdownInstanceTitleLimitation =>
      'El constructor fijado no publica títulos por instancia en temas Markdown. Se conserva el marcado existente; examínelo en el código fuente.';

  @override
  String get wsTopicIdentity => 'ID del tema';

  @override
  String get wsElementAnchor => 'Ancla del elemento';

  @override
  String get wsHeadingText => 'Texto del encabezado';

  @override
  String get wsDefaultTitle => 'Título predeterminado';

  @override
  String get wsTopicNavigation => 'Navegación del tema';

  @override
  String get wsHeadingOptions => 'Atributos del encabezado';

  @override
  String get wsDocumentOptions => 'Ajustes del documento';

  @override
  String get wsSettingsPresent => 'Hay ajustes explícitos';

  @override
  String get wsTitleOverrideExplanation =>
      'Reemplaza el título publicado; el texto del encabezado no cambia.';

  @override
  String get wsIgnoreVariables => 'Tratar las variables como texto literal';

  @override
  String get wsIgnoreVariablesExplanation =>
      'Al activarlo, el texto con aspecto de variable no se sustituye.';

  @override
  String get wsInstanceSelection => 'Instancias de ayuda';

  @override
  String get wsInstanceExplanation =>
      'Seleccione salidas de ayuda mediante nombres, grupos, listas, exclusiones o expresiones.';

  @override
  String get wsFilterExplanation =>
      'Filtra contenido reutilizable por criterios; no selecciona una instancia de ayuda.';

  @override
  String get wsContextHelp => 'ID de ayuda contextual';

  @override
  String get wsCapitalization => 'Mayúsculas y minúsculas';

  @override
  String get wsLibraryTopic => 'Tema de biblioteca';

  @override
  String get wsLastModified => 'Última modificación';

  @override
  String get wsMissingTopicHeading =>
      'No hay un H1 de tema. Añádalo en el código fuente.';

  @override
  String get wsMultipleTopicHeadings =>
      'El primer H1 define el título del tema. Los demás H1 son encabezados independientes.';

  @override
  String get wsTopicIdentityMismatch =>
      'El id raíz difiere del ID derivado del archivo. Use Renombrar archivo de tema o examine el código fuente.';

  @override
  String get wsUnsupportedProperties =>
      'Se conservan los atributos no compatibles. Examínelos en el código fuente.';

  @override
  String get wsGeneratedAnchor =>
      'Ancla generada; introducir un valor crea una anulación.';

  @override
  String get wsHeadingBuilderLimitation =>
      'El constructor fijado no publica los atributos del H1. Pertenecen al encabezado, no a la raíz XML.';

  @override
  String get closeOtherTabs => 'Cerrar las otras pestañas';

  @override
  String get tocTopicFromTemplate => 'Tema desde plantilla...';

  @override
  String get tocSaveAsTemplate => 'Guardar como plantilla';

  @override
  String get tocTemplateDialog => 'Crear tema desde plantilla';

  @override
  String get tocTemplatesEditor => 'Plantillas de archivo y código';

  @override
  String get tocEditTemplates => 'Editar plantillas...';

  @override
  String get tocCreateCustomTemplate => 'Crear plantilla personalizada...';

  @override
  String get tocTemplateCreated => 'Plantilla creada';

  @override
  String get tocTemplateDefault => 'Predeterminadas';

  @override
  String get tocTemplateCustom => 'Personalizadas';

  @override
  String get tocTemplateFilename => 'Nombre de archivo:';

  @override
  String get tocTemplateMarkdown => 'Markdown (.md)';

  @override
  String get tocTemplateXml => 'XML (.topic)';

  @override
  String get tocTemplatesInternal => 'Internas';

  @override
  String get tocTemplateUnnamed => 'Sin nombre';

  @override
  String get tocTemplateNew => 'Nueva plantilla...';

  @override
  String get tocTemplateName => 'Nombre:';

  @override
  String get tocTemplateExtension => 'Extensión:';

  @override
  String get tocTemplateLoadError =>
      'No se pudieron cargar las plantillas. No se han cambiado las existentes.';

  @override
  String get tocTemplateSaveError =>
      'No se pudieron guardar las plantillas. Los cambios siguen disponibles aquí.';

  @override
  String get tocTemplateConflict =>
      'Las plantillas cambiaron en otra ventana. Cancela y vuelve a abrir el editor.';

  @override
  String get tocTemplateDuplicateName =>
      'Ya existe una plantilla con este nombre y extensión.';

  @override
  String get tocTemplateFormat => 'Formato:';

  @override
  String get tocTemplateReset => 'Restablecer';

  @override
  String get tocTemplateRetry => 'Reintentar';

  @override
  String tocRemoveElementsDialog(int count) {
    return 'Eliminar $count elementos del índice';
  }

  @override
  String get tocRemoveElementsRetainFiles =>
      'No se eliminarán los archivos fuente asociados a estos elementos del índice.';

  @override
  String get tocOk => 'Aceptar';

  @override
  String get tocSelectExistingTopic =>
      'Seleccionar un tema para añadir a la instancia actual';

  @override
  String get tocGroupName => 'Nombre del grupo';

  @override
  String get tocMoveLineUp => 'Mover línea hacia arriba';

  @override
  String get tocMoveLineDown => 'Mover línea hacia abajo';

  @override
  String get tocEmptyMdTopic => 'Tema MD vacío';

  @override
  String get tocEmptyXmlTopic => 'Tema XML vacío';

  @override
  String get tocCopySpecial => 'Copia especial';

  @override
  String tocCopyFileName(String name) {
    return 'Nombre del archivo del tema \'$name\'';
  }

  @override
  String get tocCopyFilePath => 'Ruta del archivo del tema';

  @override
  String tocCopyTopicTitle(String title) {
    return 'Título del tema \'$title\'';
  }

  @override
  String tocCopyElementId(String id) {
    return 'ID del elemento del índice \'$id\'';
  }

  @override
  String get tocCopyFileNameUnavailable => 'Nombre del archivo del tema';

  @override
  String get tocCopyTopicTitleUnavailable => 'Título del tema';

  @override
  String get tocCopyElementIdUnavailable => 'ID del elemento del índice';

  @override
  String get tocEditTitleAction => 'Editar título...';

  @override
  String get tocEditTitleDialog => 'Editar título';

  @override
  String get tocRemoveElementAction => 'Quitar elemento del índice...';

  @override
  String get tocSetHomePage => 'Establecer como página de inicio';

  @override
  String tocGoToElement(String fileName) {
    return 'Ir al elemento del índice en \'$fileName\'';
  }

  @override
  String get tocSynchronize => 'Sincronizar índice y editor';

  @override
  String get tocEmptyGroupAction => 'Grupo vacío';

  @override
  String get tocNewEmptyGroup => 'Nuevo grupo vacío';

  @override
  String get tocGroupAction => 'Agrupar';

  @override
  String get tocNewGroup => 'Nuevo grupo';

  @override
  String get tocSortChildren => 'Ordenar temas secundarios alfabéticamente';

  @override
  String get tocLinkTopicFiles => 'Vincular archivos de temas al índice...';

  @override
  String get addLocalMarkdownFiles => 'Añadir archivos Markdown locales';

  @override
  String get tocTitleField => 'Título del índice:';

  @override
  String get tocTopicTitleField => 'Título del tema:';

  @override
  String get tocAdvancedSettings => 'Configuración avanzada';

  @override
  String tocInstanceTitleField(String instanceId) {
    return 'Título para \'$instanceId\':';
  }

  @override
  String get tocOnlyTitleField => 'Título exclusivo del índice:';

  @override
  String get tocInstanceTitleExplanation =>
      'Se usa solo para la instancia actual. De forma predeterminada, se hereda del título del tema.';

  @override
  String get tocOnlyTitleExplanation =>
      'Se usa solo en el índice. De forma predeterminada, se hereda del título del tema o del título específico de la instancia, si se ha definido. Los títulos se explican';

  @override
  String get tocTitleDocumentationLink => 'aquí';

  @override
  String get tocFindUsages => 'Buscar';

  @override
  String get tocRefactorMenu => 'Refactorizar';

  @override
  String get tocSafeDelete => 'Eliminación segura';

  @override
  String get tocDuplicate => 'Duplicar';

  @override
  String get tocDuplicateFilename => 'Nombre del archivo del tema:';

  @override
  String get tocDuplicateDialog => 'Duplicar tema';

  @override
  String get pdfTitlePage => 'Portada';

  @override
  String get pdfIncludeTitlePage => 'Incluir portada';

  @override
  String get pdfTitlePageNote =>
      'Esta página no tiene encabezado, pie de página ni número de página visible.';

  @override
  String get pdfTitlePageTitle => 'Título';

  @override
  String get pdfTitlePageSubtitle => 'Subtítulo';

  @override
  String get pdfTitlePageAuthor => 'Autor';

  @override
  String get pdfTitlePageOrganization => 'Organización';

  @override
  String get pdfTitlePageVersion => 'Versión';

  @override
  String get pdfTitlePageDate => 'Fecha';

  @override
  String get pdfTitlePageTitleRequired =>
      'Introduzca un título para la portada.';

  @override
  String get pdfTocSectionNote =>
      'Comienza en una página independiente y puede ocupar varias páginas.';

  @override
  String get appTitle => 'BusyMark';

  @override
  String get appSubtitle =>
      'Editor de archivos Markdown y proyectos de documentación compatibles con Writerside.';

  @override
  String get aboutBusyMark => 'Acerca de BusyMark';

  @override
  String get aboutTagline => 'Editor de Markdown y Writerside';

  @override
  String get aboutLicenseLabel => 'Licencia';

  @override
  String get aboutLicenseName => 'Apache License 2.0';

  @override
  String get aboutWebsite => 'Sitio web';

  @override
  String get aboutSourceCode => 'Código fuente';

  @override
  String get reportIssue => 'Informar de un problema';

  @override
  String get feedbackCategory => 'Categoría';

  @override
  String get feedbackChooseCategory => 'Elige una categoría';

  @override
  String get feedbackCategoryProblem => 'Problema o error';

  @override
  String get feedbackCategoryFeature => 'Solicitud de función';

  @override
  String get feedbackCategoryPrivacySecurity =>
      'Problema de privacidad o seguridad';

  @override
  String get feedbackCategoryUsability => 'Problema de usabilidad';

  @override
  String get feedbackCategoryOther => 'Otro';

  @override
  String get feedbackSubject => 'Asunto';

  @override
  String get feedbackMessage => 'Mensaje detallado';

  @override
  String get feedbackReplyEmail => 'Correo electrónico de respuesta (opcional)';

  @override
  String get feedbackIncludeTechnicalDetails => 'Incluir detalles técnicos';

  @override
  String get feedbackTechnicalDetailsDisclosure =>
      'Al activarlo, solo se añaden la versión del sistema operativo Linux y la configuración regional de la aplicación BusyMark. No se adjuntan registros, archivos, datos de cuentas ni otros diagnósticos.';

  @override
  String get feedbackSubmit => 'Enviar';

  @override
  String get feedbackSubmitting => 'Enviando…';

  @override
  String get feedbackCategoryRequired => 'Elige una categoría.';

  @override
  String get feedbackSubjectLength =>
      'El asunto debe tener entre 3 y 120 caracteres.';

  @override
  String get feedbackMessageLength =>
      'El mensaje debe tener entre 10 y 5.000 caracteres.';

  @override
  String get feedbackReplyEmailInvalid =>
      'Introduce una dirección de correo válida o deja este campo vacío.';

  @override
  String get feedbackConnectionFailure =>
      'BusyMark no pudo conectarse. Comprueba tu conexión a Internet e inténtalo de nuevo.';

  @override
  String get feedbackTimeoutFailure =>
      'La solicitud agotó el tiempo de espera. Inténtalo de nuevo.';

  @override
  String get feedbackRateLimitedFailure =>
      'Se enviaron demasiados informes desde esta conexión. Espera e inténtalo de nuevo.';

  @override
  String get feedbackRejectedFailure =>
      'El servidor rechazó el informe. Revisa los campos del formulario e inténtalo de nuevo.';

  @override
  String get feedbackServerFailure =>
      'El servidor no pudo aceptar el informe. Inténtalo más tarde.';

  @override
  String feedbackSuccess(String id) {
    return 'Comentarios enviados. ID de referencia: $id';
  }

  @override
  String get advanced => 'Avanzado';

  @override
  String get addToGit => 'Agregar a Git';

  @override
  String get appearance => 'Apariencia';

  @override
  String get apply => 'Aplicar';

  @override
  String get back => 'Atrás';

  @override
  String get bottomLeft => 'Abajo a la izquierda';

  @override
  String get bottomRight => 'Abajo a la derecha';

  @override
  String get cancel => 'Cancelar';

  @override
  String get choose => 'Elegir';

  @override
  String get chooseLocation => 'Elegir ubicación';

  @override
  String get copy => 'Copiar';

  @override
  String get copyPlainText => 'Copiar como texto sin formato';

  @override
  String get clipboardCopyFailed =>
      'No se pudo copiar la selección al portapapeles.';

  @override
  String get copyName => 'Copiar nombre';

  @override
  String get copyFileName => 'Copiar nombre de archivo';

  @override
  String get copyPath => 'Copiar ruta';

  @override
  String get create => 'Crear';

  @override
  String get creating => 'Creando...';

  @override
  String get cut => 'Cortar';

  @override
  String get promoteSection => 'Promover sección';

  @override
  String get demoteSection => 'Degradar sección';

  @override
  String get moveSectionUp => 'Mover sección hacia arriba';

  @override
  String get moveSectionDown => 'Mover sección hacia abajo';

  @override
  String get confirmDeleteSectionTitle => '¿Eliminar sección?';

  @override
  String confirmDeleteSectionMessage(String name) {
    return '¿Eliminar «$name» y todo el contenido de su sección? Esto no se puede deshacer.';
  }

  @override
  String get darkTheme => 'Oscuro';

  @override
  String get delete => 'Eliminar';

  @override
  String get discard => 'Descartar';

  @override
  String get editor => 'Editor';

  @override
  String get file => 'Archivo';

  @override
  String get fileHistory => 'Historial del archivo';

  @override
  String get folder => 'Carpeta';

  @override
  String get insert => 'Insertar';

  @override
  String get keyboardShortcuts => 'Atajos de teclado';

  @override
  String get commandUnavailableInContext =>
      'Este comando no está disponible en el contexto actual.';

  @override
  String get lightTheme => 'Claro';

  @override
  String get mainMenu => 'Menú principal';

  @override
  String get fullScreen => 'Pantalla completa';

  @override
  String get markdown => 'Markdown';

  @override
  String get open => 'Abrir';

  @override
  String get openInFiles => 'Abrir en Archivos';

  @override
  String get pathActions => 'Acciones de la ruta';

  @override
  String get outline => 'Esquema';

  @override
  String get overwrite => 'Sobrescribir';

  @override
  String get paste => 'Pegar';

  @override
  String get reading => 'Lectura';

  @override
  String get removeFromRecent => 'Quitar de Recientes';

  @override
  String get recent => 'Recientes';

  @override
  String get redo => 'Rehacer';

  @override
  String get save => 'Guardar';

  @override
  String get search => 'Buscar';

  @override
  String get selectAll => 'Seleccionar todo';

  @override
  String get settings => 'Configuración';

  @override
  String get source => 'Código fuente';

  @override
  String get split => 'Vista dividida';

  @override
  String get systemTheme => 'Sistema';

  @override
  String get theme => 'Tema';

  @override
  String get appLanguage => 'Idioma';

  @override
  String get systemLanguage => 'Sistema';

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
  String get toggleSidebar => 'Panel lateral';

  @override
  String get topLeft => 'Arriba a la izquierda';

  @override
  String get topRight => 'Arriba a la derecha';

  @override
  String get undo => 'Deshacer';

  @override
  String get validate => 'Validar';

  @override
  String get validation => 'Validación';

  @override
  String get viewMode => 'Modo de visualización';

  @override
  String get welcome => 'Bienvenida';

  @override
  String get writerside => 'Writerside';

  @override
  String get xml => 'XML';

  @override
  String get fileTypeMarkdown => 'Markdown';

  @override
  String get fileTypeImages => 'Imágenes';

  @override
  String get openMarkdownFile => 'Abrir archivo Markdown';

  @override
  String get markdownFileExtensions => '.md o .markdown';

  @override
  String get openFolderOrWritersideProject =>
      'Abrir carpeta o proyecto de Writerside';

  @override
  String get markdownFolderOrWritersideProject =>
      'Carpeta Markdown o proyecto compatible con Writerside';

  @override
  String get noOpenFile => 'No hay ningún archivo abierto';

  @override
  String get shortcutDeleteTreeItemDescription =>
      'Eliminar el elemento seleccionado en Archivos o quitar el tema seleccionado del índice';

  @override
  String get shortcutGroupGeneral => 'General';

  @override
  String get shortcutNewDocument => 'Crear';

  @override
  String get shortcutNewDocumentDescription =>
      'Crear un archivo Markdown o un proyecto de Writerside';

  @override
  String get shortcutOpenDescription =>
      'Abrir un archivo Markdown, una carpeta o un proyecto de Writerside';

  @override
  String get shortcutSaveDescription => 'Guardar el documento actual';

  @override
  String get shortcutSearchDescription =>
      'Buscar en el espacio de trabajo actual';

  @override
  String get shortcutKeyboardShortcutsDescription =>
      'Personalizar los atajos de teclado de la aplicación';

  @override
  String get shortcutSyntaxReferenceDescription =>
      'Abrir la referencia de sintaxis';

  @override
  String get shortcutSettingsDescription =>
      'Abrir la configuración de BusyMark';

  @override
  String get shortcutNextTab => 'Siguiente pestaña';

  @override
  String get shortcutNextTabDescription => 'Ir a la siguiente pestaña abierta';

  @override
  String get shortcutPreviousTab => 'Pestaña anterior';

  @override
  String get shortcutPreviousTabDescription =>
      'Ir a la pestaña abierta anterior';

  @override
  String get shortcutCloseTab => 'Cerrar pestaña';

  @override
  String get shortcutCloseTabDescription => 'Cerrar la pestaña activa';

  @override
  String get shortcutCloseAllTabs => 'Cerrar todas las pestañas';

  @override
  String get shortcutCloseAllTabsDescription =>
      'Cerrar todas las pestañas abiertas';

  @override
  String get shortcutGroupTextEditing => 'Edición de texto';

  @override
  String get shortcutSelectAllDescription =>
      'En el modo Código fuente, seleccionar todo el texto; en el modo Editor, pulsar dos veces para seleccionar todos los bloques';

  @override
  String get shortcutCutDescription => 'Cortar el texto seleccionado';

  @override
  String get shortcutCopyDescription => 'Copiar el texto seleccionado';

  @override
  String get shortcutPasteDescription => 'Pegar desde el portapapeles';

  @override
  String get shortcutPastePlainTextDescription =>
      'Pegar texto del portapapeles sin formato';

  @override
  String get shortcutUndoDescription => 'Deshacer la última edición';

  @override
  String get shortcutRedoDescription => 'Rehacer la última edición deshecha';

  @override
  String get shortcutInsertIndentation => 'Insertar sangría';

  @override
  String get shortcutInsertIndentationDescription =>
      'Insertar sangría en el cursor';

  @override
  String get shortcutOutdentSource => 'Reducir sangría del código fuente';

  @override
  String get shortcutOutdentSourceDescription =>
      'Quitar un nivel de sangría en el modo Código fuente';

  @override
  String get shortcutEscape =>
      'Cerrar la búsqueda o quitar la selección de bloques';

  @override
  String get shortcutEscapeDescription =>
      'Cerrar la búsqueda del espacio de trabajo o quitar una selección de bloques en el modo Editor';

  @override
  String get shortcutGroupFormatting => 'Formato';

  @override
  String get shortcutBoldDescription =>
      'Activar o desactivar la negrita en el texto seleccionado';

  @override
  String get shortcutItalicDescription =>
      'Activar o desactivar la cursiva en el texto seleccionado';

  @override
  String get shortcutUnderlineDescription =>
      'Activar o desactivar el subrayado en el texto seleccionado';

  @override
  String get shortcutLinkDescription => 'Insertar o editar un enlace';

  @override
  String get shortcutInlineCodeDescription =>
      'Activar o desactivar el código en línea en el texto seleccionado';

  @override
  String get shortcutStrikethroughDescription =>
      'Activar o desactivar el tachado en el texto seleccionado';

  @override
  String get shortcutGroupBlocks => 'Bloques';

  @override
  String get shortcutParagraphDescription =>
      'Convertir el bloque actual en párrafo';

  @override
  String get shortcutHeading1Description =>
      'Convertir el bloque actual en encabezado 1';

  @override
  String get shortcutHeading2Description =>
      'Convertir el bloque actual en encabezado 2';

  @override
  String get shortcutHeading3Description =>
      'Convertir el bloque actual en encabezado 3';

  @override
  String get shortcutHeading4Description =>
      'Convertir el bloque actual en encabezado 4';

  @override
  String get shortcutHeading5Description =>
      'Convertir el bloque actual en encabezado 5';

  @override
  String get shortcutHeading6Description =>
      'Convertir el bloque actual en encabezado 6';

  @override
  String get shortcutGroupLists => 'Listas';

  @override
  String get numberedList => 'Lista numerada';

  @override
  String get shortcutNumberedListDescription =>
      'Activar o desactivar el formato de lista numerada';

  @override
  String get bulletedList => 'Lista con viñetas';

  @override
  String get shortcutBulletedListDescription =>
      'Activar o desactivar el formato de lista con viñetas';

  @override
  String get checklist => 'Lista de verificación';

  @override
  String get shortcutChecklistDescription =>
      'Activar o desactivar el formato de lista de verificación';

  @override
  String get shortcutGroupSidebar => 'Barra lateral';

  @override
  String get sidebarViewMenu => 'Vista de la barra lateral';

  @override
  String get createMarkdownFile => 'Crear archivo Markdown';

  @override
  String get createMarkdownFileDescription =>
      'Iniciar un documento Markdown local sin guardar';

  @override
  String get createWritersideProject => 'Crear proyecto de Writerside';

  @override
  String get createWritersideProjectDescription =>
      'Iniciar un proyecto local compatible con Writerside';

  @override
  String get defaultProjectName => 'Documentación';

  @override
  String get defaultInstanceName => 'Guía del usuario';

  @override
  String get defaultStartTopicTitle => 'Primeros pasos';

  @override
  String get projectName => 'Nombre del proyecto';

  @override
  String get directoryName => 'Nombre del directorio';

  @override
  String get instanceName => 'Nombre de la instancia';

  @override
  String get instanceId => 'ID de la instancia';

  @override
  String get startTopicTitle => 'Título del tema inicial';

  @override
  String get location => 'Ubicación';

  @override
  String get projectNameRequired => 'El nombre del proyecto es obligatorio.';

  @override
  String get directoryNameRequired =>
      'El nombre del directorio es obligatorio.';

  @override
  String get useSingleSafeDirectoryName =>
      'Utilice un único nombre de directorio seguro.';

  @override
  String get useLowercaseIdentifier =>
      'Utilice un identificador en minúsculas con letras, números, guiones bajos o guiones.';

  @override
  String get startTopicTitleRequired =>
      'El título del tema inicial es obligatorio.';

  @override
  String get createWritersideProjectFailed =>
      'No se pudo crear el proyecto de Writerside.';

  @override
  String get settingsTitle => 'Configuración de BusyMark';

  @override
  String get autoSave => 'Guardado automático';

  @override
  String get autoSaveDescription =>
      'Guarda automáticamente los cambios del archivo después de un breve periodo de inactividad.';

  @override
  String get wordWrap => 'Ajuste de línea';

  @override
  String get wordWrapDescription =>
      'Ajusta las líneas largas al ancho del editor en lugar de desplazarse horizontalmente.';

  @override
  String get editorFontSize => 'Tamaño de fuente del editor';

  @override
  String get validateOnEdit => 'Validar al editar';

  @override
  String get clearRecentWorkspaces => 'Borrar el historial reciente';

  @override
  String get editingButtonsPosition => 'Posición de los botones de edición';

  @override
  String get editingButtonsPositionDescription =>
      'Elija dónde aparecen los botones flotantes de edición WYSIWYG.';

  @override
  String get editingButtonsDirection => 'Orientación de los botones de edición';

  @override
  String get editingButtonsDirectionDescription =>
      'Elija si los botones flotantes de edición WYSIWYG se disponen horizontalmente o verticalmente.';

  @override
  String get horizontal => 'Horizontal';

  @override
  String get vertical => 'Vertical';

  @override
  String get privacy => 'Privacidad';

  @override
  String get allowRemoteImages => 'Cargar imágenes remotas';

  @override
  String get allowRemoteImagesDescription =>
      'Permite cargar imágenes desde URL HTTP y HTTPS en la vista previa de Markdown y el editor.';

  @override
  String get clearRemoteImagePermissions =>
      'Borrar permisos de imágenes remotas';

  @override
  String get clearRemoteImagePermissionsDescription =>
      'Olvida los espacios de trabajo autorizados a cargar imágenes remotas.';

  @override
  String get clearGitWorkspaceTrust =>
      'Borrar espacios de trabajo de Git de confianza';

  @override
  String get clearGitWorkspaceTrustDescription =>
      'Preguntar antes de activar funciones de Git para espacios de trabajo que ya eran de confianza.';

  @override
  String get settingsEditingButtonsSectionTitle => 'Botones de edición';

  @override
  String get spellingDictionaries => 'Diccionarios ortográficos';

  @override
  String get spellingDictionariesDescription =>
      'Instalar y gestionar diccionarios ortográficos';

  @override
  String get settingsDictionariesSectionTitle => 'Diccionarios';

  @override
  String get availableSpellingDictionaries => 'Diccionarios disponibles';

  @override
  String get customSpellingDictionaries => 'Diccionarios personalizados';

  @override
  String get spellingDictionaryProblems => 'Problemas de diccionarios';

  @override
  String get settingsWindowSectionTitle => 'Ventana';

  @override
  String get settingsReopenWorkspaceOnStartupTitle =>
      'Volver a abrir el espacio de trabajo anterior al iniciar';

  @override
  String get settingsReopenWorkspaceOnStartupDescription =>
      'Abre el espacio de trabajo y las pestañas de la sesión anterior cuando se inicia BusyMark.';

  @override
  String get settingsConfirmCloseWithUnsavedChangesTitle =>
      'Confirmar antes de cerrar con cambios sin guardar';

  @override
  String get settingsConfirmCloseWithUnsavedChangesDescription =>
      'Pregunta antes de cerrar BusyMark cuando haya documentos con cambios sin guardar.';

  @override
  String get closeUnsavedChangesTitle => 'Cambios sin guardar';

  @override
  String get closeUnsavedChangesSingleMessage =>
      'Este documento tiene cambios sin guardar. ¿Guardar los cambios antes de cerrar BusyMark?';

  @override
  String closeUnsavedChangesMultipleMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count documentos tienen cambios sin guardar. ¿Guardar los cambios antes de cerrar BusyMark?',
      one:
          '1 documento tiene cambios sin guardar. ¿Guardar los cambios antes de cerrar BusyMark?',
      zero: '¿Guardar los cambios antes de cerrar BusyMark?',
    );
    return '$_temp0';
  }

  @override
  String get closeUnsavedChangesCancel => 'Cancelar';

  @override
  String get closeUnsavedChangesDiscard => 'Descartar';

  @override
  String get closeUnsavedChangesSave => 'Guardar';

  @override
  String get currentFile => 'archivo actual';

  @override
  String get unsavedChanges => 'Cambios sin guardar';

  @override
  String unsavedChangesMessage(String fileName) {
    return 'Hay cambios sin guardar en $fileName. ¿Guardarlos antes de continuar?';
  }

  @override
  String unsavedChangesMultipleMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Hay $count documentos con cambios sin guardar. ¿Desea guardarlos antes de continuar?',
      one:
          'Hay 1 documento con cambios sin guardar. ¿Desea guardarlo antes de continuar?',
    );
    return '$_temp0';
  }

  @override
  String get fileChangedOnDisk => 'Archivo modificado en disco';

  @override
  String get fileChangedOnDiskMessage =>
      'Este archivo ha cambiado en disco desde que se abrió. ¿Sobrescribirlo?';

  @override
  String get untitledMarkdownFileName => 'Sin título.md';

  @override
  String get unorderedList => 'Lista no ordenada';

  @override
  String get orderedList => 'Lista ordenada';

  @override
  String get taskList => 'Lista de tareas';

  @override
  String get toggleTaskChecked => 'Marcar/desmarcar tarea';

  @override
  String get indentListItem => 'Aumentar sangría del elemento de lista';

  @override
  String get outdentListItem => 'Reducir sangría del elemento de lista';

  @override
  String get blockquote => 'Cita en bloque';

  @override
  String get codeBlock => 'Bloque de código';

  @override
  String get codeBlockLanguage => 'Lenguaje del bloque de código';

  @override
  String get image => 'Imagen';

  @override
  String get video => 'Vídeo';

  @override
  String get openVideo => 'Reproducir vídeo';

  @override
  String get pauseVideo => 'Pausar vídeo';

  @override
  String get videoUnavailable => 'Vídeo no disponible';

  @override
  String get videoPreview => 'Vista previa del vídeo';

  @override
  String get diagnosticWritersideVideoMissingSource =>
      'Al vídeo le falta el atributo src.';

  @override
  String diagnosticWritersideVideoUnsupportedSource(String source) {
    return 'Fuente de vídeo no compatible: $source';
  }

  @override
  String diagnosticWritersideVideoMissingFile(String source) {
    return 'El archivo de vídeo no existe: $source';
  }

  @override
  String diagnosticWritersideVideoMissingPreview(String preview) {
    return 'La imagen de vista previa del vídeo no existe: $preview';
  }

  @override
  String get inlineImage => 'Imagen en línea';

  @override
  String get table => 'Tabla';

  @override
  String get htmlBlock => 'Bloque HTML';

  @override
  String get htmlContentDefault => 'Contenido HTML';

  @override
  String get shortcutHtmlBlockDescription => 'Insertar o editar un bloque HTML';

  @override
  String get renderedHtml => 'HTML renderizado';

  @override
  String get editHtml => 'Editar HTML';

  @override
  String get htmlSource => 'Código HTML';

  @override
  String get thematicBreak => 'Separador temático';

  @override
  String get bold => 'Negrita';

  @override
  String get italic => 'Cursiva';

  @override
  String get underline => 'Subrayado';

  @override
  String get strikethrough => 'Tachado';

  @override
  String get inlineCode => 'Código en línea';

  @override
  String get link => 'Enlace';

  @override
  String get hardLineBreak => 'Salto de línea forzado';

  @override
  String get insertBlankLine => 'Insertar línea en blanco';

  @override
  String get textStyle => 'Estilo de texto';

  @override
  String get paragraph => 'Párrafo';

  @override
  String get heading1 => 'Encabezado 1';

  @override
  String get heading2 => 'Encabezado 2';

  @override
  String get heading3 => 'Encabezado 3';

  @override
  String get heading4 => 'Encabezado 4';

  @override
  String get heading5 => 'Encabezado 5';

  @override
  String get heading6 => 'Encabezado 6';

  @override
  String headingLevelAbbreviation(int level) {
    return 'H$level';
  }

  @override
  String get deleteTable => 'Eliminar tabla';

  @override
  String tableColumnNumber(int columnNumber) {
    return 'Columna $columnNumber';
  }

  @override
  String get insertColumnLeft => 'Insertar columna a la izquierda';

  @override
  String get insertColumnRight => 'Insertar columna a la derecha';

  @override
  String get deleteColumn => 'Eliminar columna';

  @override
  String get tableAlignmentUnspecified => 'Alineación: Sin especificar';

  @override
  String get tableAlignmentLeft => 'Alineación: Izquierda';

  @override
  String get tableAlignmentCenter => 'Alineación: Centro';

  @override
  String get tableAlignmentRight => 'Alineación: Derecha';

  @override
  String tableRowNumber(int rowNumber) {
    return 'Fila $rowNumber';
  }

  @override
  String get insertRowAbove => 'Insertar fila encima';

  @override
  String get insertRowBelow => 'Insertar fila debajo';

  @override
  String get deleteRow => 'Eliminar fila';

  @override
  String get tableHeaderHint => 'Encabezado';

  @override
  String get tableCellHint => 'Celda';

  @override
  String get language => 'Idioma';

  @override
  String get hideEditingButtons => 'Ocultar botones de edición';

  @override
  String get showEditingButtons => 'Mostrar botones de edición';

  @override
  String get altText => 'Texto alternativo';

  @override
  String get editorPlaceholderText => 'texto';

  @override
  String get editorPlaceholderCode => 'código';

  @override
  String get editorPlaceholderAltText => 'texto alternativo';

  @override
  String get describeTheImage => 'Describa la imagen';

  @override
  String get columns => 'Columnas';

  @override
  String get rows => 'Filas';

  @override
  String tableHeaderNumber(int columnNumber) {
    return 'Encabezado $columnNumber';
  }

  @override
  String get tableCellDefault => 'Celda';

  @override
  String get noImageSource => 'Sin origen de imagen';

  @override
  String get remoteImageBlocked => 'Imagen remota bloqueada';

  @override
  String get remoteImageBlockedTooltip =>
      'Elija si BusyMark puede cargar imágenes remotas.';

  @override
  String get remoteImagesBlockedTitle =>
      'Las imágenes remotas están bloqueadas';

  @override
  String get remoteImagesBlockedMessage =>
      'Este documento hace referencia a imágenes de Internet. Cargarlas puede revelar información de red al servidor que las aloja.';

  @override
  String get loadRemoteImagesForWorkspace =>
      'Cargar en este espacio de trabajo';

  @override
  String get alwaysLoadRemoteImages => 'Cargar siempre las imágenes remotas';

  @override
  String get hideSidebar => 'Ocultar panel lateral';

  @override
  String get showSidebar => 'Mostrar panel lateral';

  @override
  String get showPreview => 'Mostrar vista previa';

  @override
  String get hidePreview => 'Ocultar vista previa';

  @override
  String get workspaceKindUnsavedMarkdown => 'Archivo Markdown sin guardar';

  @override
  String get workspaceKindSingleMarkdown => 'Archivo Markdown individual';

  @override
  String get workspaceKindMarkdownFolder => 'Carpeta Markdown';

  @override
  String get workspaceKindWritersideModule => 'Módulo de Writerside';

  @override
  String get problems => 'Problemas';

  @override
  String diagnosticCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count diagnósticos',
      one: '1 diagnóstico',
      zero: 'Sin diagnósticos',
    );
    return '$_temp0';
  }

  @override
  String get files => 'Archivos';

  @override
  String get toc => 'Tabla de contenidos';

  @override
  String get tocActions => 'Acciones del índice';

  @override
  String get markdownUnsaved => 'Markdown — sin guardar';

  @override
  String workspaceDetail(String kind, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos',
      one: '1 archivo',
    );
    return '$kind — $_temp0';
  }

  @override
  String get noFiles => 'No hay archivos';

  @override
  String get newFile => 'Nuevo archivo';

  @override
  String get noWritersideToc => 'No hay índice de Writerside';

  @override
  String get tocSection => 'sección del índice';

  @override
  String get newTopic => 'Nuevo tema';

  @override
  String get newChildTopic => 'Nuevo subtema';

  @override
  String get newSiblingTopic => 'Nuevo tema';

  @override
  String get renameTopicFile => 'Renombrar archivo del tema';

  @override
  String get topicPlacement => 'Ubicación en el índice';

  @override
  String get tocRoot => 'En la raíz del índice';

  @override
  String get afterSelectedTopic => 'Después del tema seleccionado';

  @override
  String get insideSelectedTopic => 'Dentro del tema seleccionado';

  @override
  String get pasteAfterTopic => 'Pegar después';

  @override
  String get pasteAsChildTopic => 'Pegar como subtema';

  @override
  String get removeFromToc => 'Quitar del índice';

  @override
  String get confirmRemoveFromTocTitle => '¿Quitar del índice?';

  @override
  String confirmRemoveFromTocMessage(String name) {
    return '¿Quitar $name de este índice? El archivo del tema se conservará.';
  }

  @override
  String get confirmDeleteTopicTitle => '¿Eliminar el archivo del tema?';

  @override
  String confirmDeleteTopicMessage(String name) {
    return '¿Eliminar $name y quitarlo de todos los índices? Esta acción no se puede deshacer.';
  }

  @override
  String get safeDeleteTopicFile =>
      'Eliminar el archivo del tema de forma segura…';

  @override
  String get removeTocElement => 'Quitar elemento del índice';

  @override
  String get removeTocElements => 'Quitar elementos del índice';

  @override
  String get reviewUsages => 'Revisar usos';

  @override
  String get deleteTopicFile => 'Eliminar archivo del tema';

  @override
  String get removeAction => 'Quitar';

  @override
  String topicRemovalSummary(String topic) {
    return '¿Quitar el elemento «$topic» del índice? No se eliminará el archivo fuente asociado al índice.';
  }

  @override
  String safeDeleteTopicSummary(String topic) {
    return 'Elimina «$topic» y actualiza de forma segura sus referencias en todo este proyecto de Writerside.';
  }

  @override
  String childTopicsPromoted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count temas hijos subirán un nivel.',
      one: '1 tema hijo subirá un nivel.',
    );
    return '$_temp0';
  }

  @override
  String get topicIsHomePageRemovalWarning =>
      'Este tema es la página de inicio de esta instancia. Elige otra página de inicio antes de quitarlo de la tabla de contenido.';

  @override
  String get newHomePage => 'Nueva página de inicio';

  @override
  String get chooseHomePage => 'Elegir página de inicio';

  @override
  String get noHomePageReplacement =>
      'Añade o vincula otro tema válido a esta instancia antes de quitar su página de inicio.';

  @override
  String get topicIsStartPageRemovalWarning =>
      'Este tema es la página de inicio de una instancia. Asigna otra página de inicio antes de eliminar su archivo de origen.';

  @override
  String topicUsagesCount(int count) {
    return 'Se encontraron $count usos.';
  }

  @override
  String get noBreakingTopicUsages =>
      'No se han encontrado referencias que pudieran dejar de funcionar.';

  @override
  String get topicUsagesFound =>
      'BusyMark ha encontrado las siguientes referencias a este tema.';

  @override
  String get topicUsageTocElements => 'Elementos del índice';

  @override
  String get topicUsageStartPages => 'Páginas de inicio';

  @override
  String get topicUsageTopicLinks => 'Enlaces a temas';

  @override
  String get topicUsageIncludes => 'Inclusiones';

  @override
  String usageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count usos',
      one: '1 uso',
    );
    return '$_temp0';
  }

  @override
  String get refactoringOptions => 'Opciones de refactorización';

  @override
  String get updateUsagesAutomatically => 'Actualizar los usos automáticamente';

  @override
  String get updateUsagesAutomaticallyDescription =>
      'Quita las referencias de los índices y las inclusiones, y conserva el texto de los enlaces.';

  @override
  String get manualUsageUpdatesRequired =>
      'Algunos usos requieren cambios manuales antes de esta refactorización.';

  @override
  String get setRedirectTo => 'Redirigir a:';

  @override
  String get noRedirectDescription =>
      'No redirigir la página publicada anterior.';

  @override
  String get redirectTarget => 'Destino de la redirección';

  @override
  String get remainingUsagesBlockRemoval =>
      'Revisa y actualiza los usos restantes antes de continuar, o activa las actualizaciones automáticas cuando estén disponibles.';

  @override
  String usagesOfTopic(String topic) {
    return 'Usos de $topic';
  }

  @override
  String get noUsagesFound => 'No se han encontrado usos.';

  @override
  String get outsideSelectedInstance => 'Fuera de la instancia seleccionada';

  @override
  String get doRefactor => 'Refactorizar';

  @override
  String get preview => 'Vista previa';

  @override
  String get topicRenamePreviewTitle => 'Vista previa del cambio de nombre';

  @override
  String topicRenamePathChange(String oldPath, String newPath) {
    return 'Ruta: $oldPath → $newPath';
  }

  @override
  String topicRenameIdChange(String oldId, String newId) {
    return 'ID del tema: $oldId → $newId';
  }

  @override
  String topicRenameUrlChange(String instance, String oldName, String newName) {
    return 'Instancia $instance: $oldName → $newName';
  }

  @override
  String get topicRenameAffectedFiles => 'Archivos afectados';

  @override
  String get orphanTopicTitle => 'El archivo del tema ya no se usa';

  @override
  String get keepTopicFile => 'Conservar el archivo del tema';

  @override
  String orphanTopicMessage(String topic) {
    return '«$topic» ya no se usa en ninguna parte de este proyecto de Writerside. Elimina el archivo o consérvalo para usarlo en otra instancia.';
  }

  @override
  String get defaultNewTopicTitle => 'Nuevo tema';

  @override
  String get topicTitle => 'Título del tema';

  @override
  String get fileName => 'Nombre de archivo';

  @override
  String get topicTitleRequired => 'El título del tema es obligatorio.';

  @override
  String get fileNameRequired => 'El nombre de archivo es obligatorio.';

  @override
  String get rename => 'Renombrar';

  @override
  String get confirmDeleteFileTitle => '¿Eliminar archivo?';

  @override
  String get confirmDeleteFolderTitle => '¿Eliminar carpeta?';

  @override
  String confirmDeleteFileMessage(String name) {
    return '¿Eliminar $name? Esto no se puede deshacer.';
  }

  @override
  String confirmDeleteFolderMessage(String name) {
    return '¿Eliminar $name y todos los archivos que contiene? Esto no se puede deshacer.';
  }

  @override
  String get useSingleSafeFileName =>
      'Utilice un único nombre de archivo seguro.';

  @override
  String useExpectedExtension(String extension) {
    return 'Utilice la extensión $extension para el formato seleccionado.';
  }

  @override
  String get useIdentifierCharacters =>
      'Utilice letras, números, guiones bajos o guiones antes de la extensión.';

  @override
  String get topicIdAlreadyExists => 'El ID del tema ya existe.';

  @override
  String get createWritersideTopicFailed =>
      'No se pudo crear el tema de Writerside.';

  @override
  String get noOutline => 'Sin esquema';

  @override
  String expandKind(String kind) {
    return 'Expandir $kind';
  }

  @override
  String collapseKind(String kind) {
    return 'Contraer $kind';
  }

  @override
  String get foldKindSection => 'sección';

  @override
  String get foldKindList => 'lista';

  @override
  String get foldKindQuote => 'cita';

  @override
  String get foldKindTag => 'etiqueta';

  @override
  String get sourceSearchPreviousMatch => 'Coincidencia anterior';

  @override
  String get sourceSearchNextMatch => 'Coincidencia siguiente';

  @override
  String get sourceSearchReplacement => 'Reemplazar por';

  @override
  String get sourceSearchReplaceCurrent => 'Reemplazar la coincidencia actual';

  @override
  String get sourceSearchReplaceAndFindNext => 'Reemplazar y buscar siguiente';

  @override
  String get sourceSearchReplaceAll => 'Reemplazar todo';

  @override
  String get workspaceReplace => 'Reemplazar en el espacio de trabajo';

  @override
  String get reviewReplacements => 'Revisar reemplazos';

  @override
  String get applyReplacements => 'Aplicar reemplazos';

  @override
  String get skippedFiles => 'Archivos omitidos';

  @override
  String get workspaceReplaceDirtyBuffer => 'Contenido no guardado del editor';

  @override
  String get workspaceReplaceDiskContent => 'Contenido guardado en disco';

  @override
  String selectFileMatches(int count) {
    return 'Seleccionar las $count coincidencias';
  }

  @override
  String workspaceReplaceApplied(int matches, int files, int skipped) {
    return 'Se reemplazaron $matches coincidencias en $files archivos; se omitieron $skipped.';
  }

  @override
  String documentFormatWithFinalNewline(String encoding, String lineEnding) {
    return '$encoding · $lineEnding · Salto de línea final';
  }

  @override
  String documentFormatWithoutFinalNewline(String encoding, String lineEnding) {
    return '$encoding · $lineEnding · Sin salto de línea final';
  }

  @override
  String get normalizeLineEndings => 'Normalizar finales de línea';

  @override
  String get mixedLineEndingsSavePrompt =>
      'Este documento contiene finales de línea mezclados. Elige un formato.';

  @override
  String workspaceReplaceMixedLineEndings(String fileName) {
    return '$fileName usa finales de línea mezclados. Elige el formato antes de reemplazar.';
  }

  @override
  String get workspaceReplaceIssueOversized =>
      'Se omitió un archivo demasiado grande.';

  @override
  String get workspaceReplaceIssueUnreadable =>
      'Se omitió un archivo que no se pudo leer.';

  @override
  String get workspaceReplaceIssueInvalidUtf8 =>
      'Se omitió un archivo que no contiene UTF-8 válido.';

  @override
  String get workspaceReplaceIssueTruncated =>
      'La vista previa de reemplazos se truncó.';

  @override
  String get workspaceReplaceIssueFileChanged =>
      'Se omitió un archivo que cambió después de la vista previa.';

  @override
  String get workspaceReplaceIssueBufferChanged =>
      'Se omitió un búfer del editor que cambió después de la vista previa.';

  @override
  String get workspaceReplaceIssueNormalizationRequired =>
      'Elige la normalización LF o CRLF antes de reemplazar.';

  @override
  String get workspaceReplaceIssuePartialConflict =>
      'La reversión se detuvo porque el archivo cambió al mismo tiempo. Es posible que queden algunos reemplazos; el contenido desplazado se conservó en la ruta indicada abajo.';

  @override
  String get workspaceReplaceIssueApplyFailed =>
      'No se aplicó ningún reemplazo porque el conjunto revisado no pudo guardarse de forma segura.';

  @override
  String externalChangesTitle(String fileName) {
    return 'Cambios externos — $fileName';
  }

  @override
  String get externalFileDeleted => 'Este archivo se eliminó del disco.';

  @override
  String get externalFileChanged =>
      'Este archivo cambió en el disco mientras tienes cambios sin guardar.';

  @override
  String recoveredDocumentReview(String fileName) {
    return 'Se recuperó contenido sin guardar de $fileName. Revíselo y después guárdelo, use Guardar como o descártelo.';
  }

  @override
  String get compare => 'Comparar';

  @override
  String get reloadFromDisk => 'Recargar desde el disco';

  @override
  String get keepMine => 'Conservar mi versión';

  @override
  String get saveAs => 'Guardar como';

  @override
  String get workspaceSearchIncomplete =>
      'Solo se muestran algunos resultados. Muestre más o limite la búsqueda.';

  @override
  String get workspaceSearchShowMore => 'Mostrar más resultados';

  @override
  String get workspaceSearchSkippedFiles =>
      'La búsqueda está incompleta. Estos archivos superan 1 MiB o no se pudieron leer:';

  @override
  String get sourceLargeFileFeaturesPaused =>
      'Archivo grande: el resaltado y el plegado están en pausa';

  @override
  String get nothingToRead => 'No hay contenido para leer';

  @override
  String get admonition => 'Aviso';

  @override
  String get quote => 'Cita';

  @override
  String get note => 'Nota';

  @override
  String get tip => 'Consejo';

  @override
  String get warning => 'Advertencia';

  @override
  String get tabs => 'Pestañas';

  @override
  String get tab => 'Pestaña';

  @override
  String get procedure => 'Procedimiento';

  @override
  String get step => 'Paso';

  @override
  String get topic => 'Tema';

  @override
  String get chapter => 'Capítulo';

  @override
  String couldNotOpenTarget(String target) {
    return 'No se pudo abrir $target';
  }

  @override
  String linkTargetNotFound(String targetPath) {
    return 'No se encontró el destino del enlace: $targetPath';
  }

  @override
  String get cannotOpenFileTypeInEditor =>
      'No se puede abrir este tipo de archivo en el editor';

  @override
  String anchorNotFound(String anchor) {
    return 'No se encontró el ancla: $anchor';
  }

  @override
  String get noProblemsFound => 'No se encontraron problemas';

  @override
  String get noResults => 'No hay resultados';

  @override
  String searchResultLine(String relativePath, int lineNumber) {
    return '$relativePath — línea $lineNumber';
  }

  @override
  String get untitledResult => 'Resultado sin título';

  @override
  String get documentKindMarkdownFile => 'Archivo Markdown';

  @override
  String get documentKindWritersideMarkdownTopic =>
      'Tema Markdown de Writerside';

  @override
  String get documentKindWritersideXmlTopic => 'Tema XML de Writerside';

  @override
  String get documentKindWritersideTree => 'Árbol de Writerside';

  @override
  String get documentKindConfigurationFile => 'Archivo de configuración';

  @override
  String get documentKindVariablesFile => 'Archivo de variables';

  @override
  String get documentKindCategoriesFile => 'Archivo de categorías';

  @override
  String get documentKindResourceFile => 'Archivo de recursos';

  @override
  String workspaceErrorRecentWorkspaceUpdateFailed(String error) {
    return 'No se pudieron actualizar los elementos recientes: $error.';
  }

  @override
  String workspaceErrorOpenFailed(String error) {
    return 'Error al abrir: $error';
  }

  @override
  String workspaceErrorCreateWritersideProjectFailed(String error) {
    return 'No se pudo crear el proyecto de Writerside: $error';
  }

  @override
  String workspaceErrorCreateWritersideTopicFailed(String error) {
    return 'No se pudo crear el tema de Writerside: $error';
  }

  @override
  String workspaceErrorCouldNotOpenFile(String error) {
    return 'No se pudo abrir el archivo: $error';
  }

  @override
  String get workspaceErrorChooseWhereToSaveMarkdown =>
      'Elija dónde guardar este archivo Markdown.';

  @override
  String get workspaceErrorSaveBlockedFileChangedOnDisk =>
      'Guardado bloqueado: el archivo ha cambiado en disco.';

  @override
  String workspaceErrorSaveFailed(String error) {
    return 'Error al guardar: $error';
  }

  @override
  String workspaceErrorFileOperationFailed(String error) {
    return 'Error en la operación de archivo: $error';
  }

  @override
  String workspaceErrorValidationFailed(String error) {
    return 'Error de validación: $error';
  }

  @override
  String workspaceRecoveryRestored(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Se recuperaron $count documentos sin guardar. Revise cada uno antes de guardar o descartarlo.',
      one:
          'Se recuperó 1 documento sin guardar. Revísalo antes de guardarlo o descartarlo.',
    );
    return '$_temp0';
  }

  @override
  String workspaceRecoveryDamaged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'No se pudieron recuperar $count registros de recuperación dañados. Los registros de recuperación válidos siguen disponibles.',
      one:
          'No se pudo recuperar 1 registro de recuperación dañado. Se conservó el archivo de recuperación original para su revisión.',
    );
    return '$_temp0';
  }

  @override
  String errorPathDoesNotExist(String path) {
    return 'La ruta no existe: $path';
  }

  @override
  String errorTargetDirectoryNotEmpty(String path) {
    return 'El directorio de destino ya existe y no está vacío: $path';
  }

  @override
  String errorTargetPathNotDirectory(String path) {
    return 'La ruta de destino ya existe y no es un directorio: $path';
  }

  @override
  String errorGeneratedFileAlreadyExists(String path) {
    return 'El archivo generado ya existe: $path';
  }

  @override
  String get errorParentDirectoryRequired =>
      'El directorio padre es obligatorio.';

  @override
  String errorParentDirectoryMissing(String path) {
    return 'El directorio padre no existe: $path';
  }

  @override
  String errorDirectoryMissing(String path) {
    return 'El directorio no existe: $path';
  }

  @override
  String errorPathAlreadyExists(String path) {
    return 'La ruta ya existe: $path';
  }

  @override
  String get errorFileNameRequired => 'El nombre del archivo es obligatorio.';

  @override
  String get errorFileNameUnsafe =>
      'El nombre del archivo debe ser un único segmento de ruta seguro.';

  @override
  String get errorFileOperationInvalidTarget =>
      'No se puede mover una carpeta dentro de sí misma.';

  @override
  String get errorFileOperationOutsideRoot =>
      'La operación de archivo debe permanecer dentro del espacio de trabajo.';

  @override
  String get errorFileOperationRoot =>
      'La raíz del espacio de trabajo no se puede cambiar desde el árbol de archivos.';

  @override
  String get errorProjectNameRequired =>
      'El nombre del proyecto es obligatorio.';

  @override
  String get errorDirectoryNameRequired =>
      'El nombre del directorio es obligatorio.';

  @override
  String get errorDirectoryNameUnsafe =>
      'El nombre del directorio debe ser un único segmento de ruta seguro.';

  @override
  String get errorInstanceIdInvalid =>
      'El ID de instancia debe comenzar con una letra minúscula y contener solo letras minúsculas, números, guiones bajos y guiones.';

  @override
  String get errorTopicFileInvalid =>
      'El nombre del archivo del tema debe ser un nombre de archivo Markdown sin separadores de ruta.';

  @override
  String get errorTopicTitleRequired => 'El título del tema es obligatorio.';

  @override
  String errorWritersideModuleRootMissing(String path) {
    return 'La raíz del módulo de Writerside no existe: $path';
  }

  @override
  String get errorWritersideModuleNotOpen =>
      'Debe haber un módulo de Writerside abierto para crear un tema.';

  @override
  String get errorWritersideInstanceTreeMissing =>
      'El módulo de Writerside no tiene un árbol de instancia.';

  @override
  String errorWritersideTreeFileMissing(String path) {
    return 'El archivo de árbol de Writerside no existe: $path';
  }

  @override
  String errorTopicIdAlreadyExists(String topicId) {
    return 'El ID del tema \"$topicId\" ya existe en este módulo de ayuda.';
  }

  @override
  String errorTopicFileAlreadyExists(String path) {
    return 'El archivo de tema ya existe: $path';
  }

  @override
  String errorReferenceTopicMissing(String topic) {
    return 'El tema de referencia no está presente en el árbol seleccionado: $topic';
  }

  @override
  String get errorWritersideTocNodeMissing =>
      'La entrada seleccionada del índice ya no existe.';

  @override
  String get errorWritersideTocInvalidMove =>
      'Una entrada del índice no se puede mover dentro de sí misma ni de uno de sus elementos descendientes.';

  @override
  String errorWritersideStartTopicDelete(String topic) {
    return 'No se puede eliminar la página de inicio $topic. Elige otra página de inicio primero.';
  }

  @override
  String get errorWritersideSafeDeleteRequired =>
      'Usa la eliminación segura para los archivos de temas de Writerside.';

  @override
  String get errorWritersideTopicUsageScanFailed =>
      'No se pudo completar el análisis de usos del tema. No se modificó ningún archivo.';

  @override
  String get errorWritersideTopicUsagesRemain =>
      'Algunos usos del tema aún requieren atención. Revísalos antes de continuar.';

  @override
  String get errorWritersideRedirectInvalid =>
      'El destino de redirección seleccionado ya no es válido. Vuelve a seleccionarlo.';

  @override
  String errorWritersideRollbackFailed(String paths) {
    return 'No se pudo revertir por completo la eliminación del tema. Revisa estas rutas antes de continuar: $paths';
  }

  @override
  String errorWritersideTopicRenameIncompleteProjectIndex(
    String module,
    String count,
    String paths,
  ) {
    return 'No se pueden actualizar de forma segura todas las referencias del proyecto porque no se analizaron $count archivo(s) de tema del módulo $module: $paths';
  }

  @override
  String get errorWritersideTopicRenameProjectBuffersDirty =>
      'Los archivos del proyecto de Writerside tienen cambios sin guardar. Resuélvalos y prepare una nueva vista previa del cambio de nombre.';

  @override
  String get errorWritersideTopicRenameProjectInventoryChanged =>
      'El conjunto de módulos del proyecto de Writerside cambió. Prepare una nueva vista previa del cambio de nombre antes de refactorizar.';

  @override
  String get errorTopicsRootUnsafe =>
      'La raíz de temas debe ser un directorio relativo seguro.';

  @override
  String get errorTopicFileNameUnsafe =>
      'El nombre del archivo del tema debe ser un único segmento de ruta seguro.';

  @override
  String errorTopicFileExtensionMismatch(String extension) {
    return 'La extensión del archivo del tema debe coincidir con el formato seleccionado ($extension).';
  }

  @override
  String get errorTopicFileNameInvalid =>
      'El nombre del archivo del tema debe contener solo letras, números, guiones bajos y guiones.';

  @override
  String errorUnknown(String code) {
    return 'Error desconocido: $code';
  }

  @override
  String diagnosticWorkspaceFileStatFailed(String error) {
    return 'No se pudieron leer los metadatos del archivo: $error';
  }

  @override
  String get diagnosticWorkspaceScanSkipped =>
      'Se detectó un espacio de trabajo grande. Se omitieron algunos archivos para que la aplicación siguiera respondiendo.';

  @override
  String diagnosticWorkspaceScanInspectFailed(String error) {
    return 'No se pudo inspeccionar la entrada del espacio de trabajo: $error';
  }

  @override
  String get diagnosticWorkspaceFileTooLarge =>
      'El archivo supera el límite beta de análisis automático.';

  @override
  String diagnosticWorkspaceFileReadFailed(String error) {
    return 'No se pudo leer el archivo Markdown: $error';
  }

  @override
  String get diagnosticMarkdownAttributeMalformed =>
      'Bloque de atributos de encabezado de Writerside con formato incorrecto.';

  @override
  String diagnosticMarkdownHeadingDuplicateId(String id) {
    return 'ID de encabezado duplicado \"$id\".';
  }

  @override
  String get diagnosticWritersideTopicH1ConvertedToChapter =>
      'Los encabezados H1 de nivel superior adicionales se tratan como capítulos.';

  @override
  String get diagnosticWritersideMarkdownTopicMissingTitle =>
      'El tema Markdown de Writerside no tiene un encabezado H1 ni un título de front matter.';

  @override
  String get diagnosticWritersideXmlTopicMissingTitle =>
      'Al tema XML le falta el título.';

  @override
  String diagnosticWritersideTopicFileMissingTitle(String fileName) {
    return 'Al tema \"$fileName\" le falta un título.';
  }

  @override
  String get diagnosticMarkdownFrontMatterMalformed =>
      'El front matter no está cerrado.';

  @override
  String get diagnosticMarkdownRawHtmlUnsafe => 'Elemento HTML inseguro.';

  @override
  String diagnosticMarkdownLinkUnresolvedTarget(String targetPath) {
    return 'El destino del enlace no existe: $targetPath';
  }

  @override
  String diagnosticMarkdownLinkUnresolvedAnchor(String anchor) {
    return 'El ancla \"$anchor\" no existe.';
  }

  @override
  String diagnosticMarkdownImageMissingAlt(String destination) {
    return 'A la imagen \"$destination\" le falta texto alternativo.';
  }

  @override
  String diagnosticMarkdownImageMissingFile(String destination) {
    return 'La imagen no existe: $destination';
  }

  @override
  String diagnosticInvalidXml(String message) {
    return 'XML no válido: $message';
  }

  @override
  String get diagnosticWritersideConfigInvalidRoot =>
      'La raíz de writerside.cfg debe ser <ihp>.';

  @override
  String get diagnosticWritersideConfigMissingSnippetsSrc =>
      'A la declaración de snippets le falta el atributo src.';

  @override
  String get diagnosticWritersideConfigMissingInstanceGroupsSrc =>
      'A la declaración de instance-groups le falta el atributo src.';

  @override
  String diagnosticWritersideConfigInvalidKeymapsMode(String mode) {
    return 'Modo de keymaps no compatible: $mode';
  }

  @override
  String get diagnosticWritersideConfigMissingInstanceSrc =>
      'A la declaración de instancia le falta el atributo src.';

  @override
  String get diagnosticWritersideConfigMissingInstance =>
      'writerside.cfg no registra ninguna instancia.';

  @override
  String get diagnosticWritersideTreeInvalidRoot =>
      'La raíz de .tree debe ser <instance-profile>.';

  @override
  String get diagnosticWritersideTreeMissingId =>
      'Al perfil de instancia le falta el atributo id.';

  @override
  String diagnosticWritersideTreeIdMismatch(String id) {
    return 'El nombre base del archivo de árbol no coincide con el ID de instancia \"$id\".';
  }

  @override
  String get diagnosticWritersideTreeMissingStartPage =>
      'A la instancia que no es de biblioteca le falta start-page.';

  @override
  String diagnosticWritersideStartPageMissing(String startPage) {
    return 'La página de inicio \"$startPage\" no existe.';
  }

  @override
  String diagnosticWritersideTreeDuplicateTopic(String topic) {
    return 'El tema \"$topic\" aparece más de una vez en el índice de esta instancia.';
  }

  @override
  String get diagnosticWritersideVariableMalformedDeclaration =>
      'La declaración de variable debe tener nombre y valor.';

  @override
  String diagnosticWritersideVariableDuplicateName(String name) {
    return 'La variable \"$name\" está declarada más de una vez.';
  }

  @override
  String get diagnosticWritersideCategoryMissingId =>
      'A la categoría le falta el atributo id.';

  @override
  String diagnosticWritersideCategoryDuplicateId(String id) {
    return 'La categoría \"$id\" está declarada más de una vez.';
  }

  @override
  String diagnosticWritersideCategoryDuplicateOrder(String order) {
    return 'El orden de categoría \"$order\" está declarado más de una vez.';
  }

  @override
  String get diagnosticWritersideTopicInvalidRoot =>
      'La raíz de .topic debe ser <topic>.';

  @override
  String get diagnosticWritersideTopicMissingRootId =>
      'Al tema XML le falta el ID de raíz.';

  @override
  String diagnosticWritersideTopicRootIdMismatch(String id, String expectedId) {
    return 'El ID de raíz del tema XML \"$id\" debe coincidir con el nombre de archivo \"$expectedId\".';
  }

  @override
  String diagnosticWritersideTopicDuplicateElementId(String elementId) {
    return 'El ID del elemento \"$elementId\" aparece más de una vez.';
  }

  @override
  String get diagnosticWritersideTopicAnchorMissingHref =>
      'A <a> le falta el atributo href.';

  @override
  String get diagnosticWritersideConfigMissing =>
      'El modo Writerside requiere writerside.cfg.';

  @override
  String diagnosticWritersideConfigMissingBuildConfigDirectory(
    String relativePath,
  ) {
    return 'Falta el directorio configurado para la compilación: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingApiSpecificationsDirectory(
    String relativePath,
  ) {
    return 'Falta el directorio de especificaciones de API configurado: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingSnippetsDirectory(
    String relativePath,
  ) {
    return 'Falta el directorio de snippets configurado: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingVarsFile(String relativePath) {
    return 'Falta el archivo de variables configurado: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingCategoriesFile(String relativePath) {
    return 'Falta el archivo de categorías configurado: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceGroupsFile(
    String relativePath,
  ) {
    return 'Falta el archivo de grupos de instancias configurado: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceTree(String source) {
    return 'El árbol de instancia registrado \"$source\" no existe.';
  }

  @override
  String diagnosticWritersideTopicReadFailed(String error) {
    return 'No se pudo leer el archivo de tema: $error';
  }

  @override
  String diagnosticWritersideDefaultTopicsDirectoryMissing(
    String relativePath,
  ) {
    return 'Falta el directorio de temas predeterminado: $relativePath';
  }

  @override
  String diagnosticWritersideTopicsDirectoryMissing(String relativePath) {
    return 'Falta el directorio de temas configurado: $relativePath';
  }

  @override
  String diagnosticWritersideImagesDirectoryMissing(String relativePath) {
    return 'Falta el directorio de imágenes configurado: $relativePath';
  }

  @override
  String diagnosticWritersideTopicDuplicateId(String id) {
    return 'El ID del elemento \"$id\" aparece más de una vez.';
  }

  @override
  String diagnosticWritersideWebFileNameInvalid(
    String instanceId,
    String webFileName,
    String topic,
  ) {
    return 'La instancia \"$instanceId\" publica el nombre de archivo web no válido \"$webFileName\" para el tema \"$topic\".';
  }

  @override
  String diagnosticWritersideWebFileNameCollision(
    String instanceId,
    String webFileName,
    String firstTopic,
    String secondTopic,
  ) {
    return 'La instancia \"$instanceId\" publica \"$firstTopic\" y \"$secondTopic\" como \"$webFileName\".';
  }

  @override
  String diagnosticWritersideTreeMissingTopic(String topic) {
    return 'El índice hace referencia a un tema inexistente \"$topic\".';
  }

  @override
  String diagnosticWritersideTreeInvalidHref(String href) {
    return 'El href externo \"$href\" no es válido.';
  }

  @override
  String diagnosticWritersideVariableUnresolved(String name) {
    return 'La variable \"%$name%\" no está declarada.';
  }

  @override
  String diagnosticWritersideTopicLinkUnresolved(String destination) {
    return 'El enlace al tema \"$destination\" no se puede resolver.';
  }

  @override
  String diagnosticWritersideAnchorUnresolved(
    String anchor,
    String targetName,
  ) {
    return 'El ancla \"$anchor\" no existe en \"$targetName\".';
  }

  @override
  String get diagnosticWritersideIncludeMissingFrom =>
      'A <include> le falta el atributo from.';

  @override
  String diagnosticWritersideIncludeSourceMissing(String from) {
    return 'El origen de inclusión \"$from\" no existe.';
  }

  @override
  String diagnosticWritersideIncludeElementMissing(
    String elementId,
    String from,
  ) {
    return 'El elemento de inclusión \"$elementId\" no existe en \"$from\".';
  }

  @override
  String diagnosticWritersideCategoryUnresolved(String ref) {
    return 'La categoría seealso \"$ref\" no está declarada.';
  }

  @override
  String diagnosticWritersideTopicAmbiguousReference(String reference) {
    return 'La referencia al tema \"$reference\" es ambigua.';
  }

  @override
  String diagnosticUnknown(String code) {
    return 'Diagnóstico desconocido: $code';
  }

  @override
  String get close => 'Cerrar';

  @override
  String get git => 'Git';

  @override
  String get gitDiff => 'Diff de Git';

  @override
  String get gitShowDiff => 'Mostrar diff';

  @override
  String gitDiffHunkRange(String oldRange, String newRange) {
    return 'anterior $oldRange → nuevo $newRange';
  }

  @override
  String get gitDiffNoLines => 'sin líneas';

  @override
  String get gitUnavailableTitle => 'Git no está disponible';

  @override
  String gitUnavailableMessage(String reason) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'other':
          'Instale Git o configure BusyMark para usar un ejecutable de Git disponible. $reason',
    });
    return '$_temp0';
  }

  @override
  String get gitTrustRequiredTitle =>
      '¿Confiar en este espacio de trabajo para Git?';

  @override
  String get gitTrustRequiredMessage =>
      'Los repositorios Git pueden ejecutar programas mediante hooks, filtros y otras opciones de configuración. Confíe en este espacio de trabajo antes de que BusyMark lea datos del repositorio o active acciones de Git.';

  @override
  String get gitTrustWorkspace => 'Confiar en el espacio de trabajo';

  @override
  String get gitNotRepositoryTitle => 'No es un repositorio Git';

  @override
  String get gitNotRepositoryMessage =>
      'Este espacio de trabajo no está dentro de un repositorio Git.';

  @override
  String get gitInitializeRepository => 'Inicializar repositorio';

  @override
  String get gitDetachedHead => 'HEAD desacoplado';

  @override
  String gitDetachedHeadAt(String commit) {
    return 'Desacoplado en $commit';
  }

  @override
  String get gitNoUpstream => 'Sin upstream';

  @override
  String gitAheadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commits sin enviar',
      one: '1 commit sin enviar',
    );
    return '$_temp0';
  }

  @override
  String gitBehindCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commits para incorporar',
      one: '1 commit para incorporar',
    );
    return '$_temp0';
  }

  @override
  String get gitClean => 'Limpio';

  @override
  String get gitConflicts => 'Conflictos';

  @override
  String get gitChanges => 'Cambios';

  @override
  String get gitStaged => 'Preparados';

  @override
  String get gitUnstaged => 'Sin preparar';

  @override
  String get gitHistory => 'Historial';

  @override
  String get gitBranches => 'Ramas';

  @override
  String get gitActions => 'Acciones de Git';

  @override
  String get gitPull => 'Pull';

  @override
  String get gitFetch => 'Obtener';

  @override
  String get gitPush => 'Push';

  @override
  String get gitCommit => 'Commit';

  @override
  String get gitSelectForCommit => 'Preparar archivo';

  @override
  String get gitRemoveFromCommit => 'Quitar archivo del área de preparación';

  @override
  String get gitDiscard => 'Descartar';

  @override
  String get gitOpenFile => 'Abrir archivo';

  @override
  String get gitMarkResolved => 'Marcar como resuelto';

  @override
  String get gitUntracked => 'Archivos sin seguimiento';

  @override
  String get gitCommitMessage => 'Mensaje del commit';

  @override
  String get gitCommitSelectedFiles => 'Archivos seleccionados';

  @override
  String get gitCommitNoSelectedFiles =>
      'Prepare al menos un archivo antes de crear el commit.';

  @override
  String gitStagedFileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos preparados',
      one: '1 archivo preparado',
    );
    return '$_temp0';
  }

  @override
  String get gitOutsideWorkspace => 'Fuera del espacio de trabajo';

  @override
  String get gitCommitMessageRequired =>
      'Introduzca un mensaje para el commit.';

  @override
  String get gitCreateBranch => 'Crear rama';

  @override
  String get gitNewBranch => 'Nueva rama';

  @override
  String get gitBranchName => 'Nombre de la rama';

  @override
  String get gitSwitchBranch => 'Cambiar';

  @override
  String get gitNoChanges => 'No hay cambios';

  @override
  String get gitNoHistory => 'No hay historial';

  @override
  String get gitNoBranches => 'No hay ramas';

  @override
  String get gitNoDiff => 'No hay ningún diff que mostrar';

  @override
  String get gitBinaryFile =>
      'Archivo binario. BusyMark no muestra parches binarios.';

  @override
  String gitBinaryFileInfo(int size) {
    return 'Archivo binario ($size bytes). BusyMark no muestra parches binarios.';
  }

  @override
  String get gitUnsavedChangesBanner =>
      'Los cambios sin guardar del editor no se incluyen hasta que se guarden.';

  @override
  String get gitConfirmDiscardTitle => '¿Descartar los cambios de Git?';

  @override
  String gitConfirmDiscardTracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Se restaurarán en HEAD todos los cambios preparados y sin preparar de los archivos rastreados seleccionados.',
      one:
          'Se restaurarán en HEAD todos los cambios preparados y sin preparar del archivo rastreado seleccionado.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardUntracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Los archivos seleccionados sin seguimiento se eliminarán.',
      one: 'El archivo seleccionado sin seguimiento se eliminará.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardMixed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Los archivos seleccionados se restaurarán o eliminarán según su estado de Git.',
      one:
          'El archivo seleccionado se restaurará o eliminará según su estado de Git.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmSwitchBranchTitle(String branch) {
    return '¿Cambiar a $branch?';
  }

  @override
  String get gitConfirmSwitchBranchMessage =>
      'BusyMark volverá a cargar el espacio de trabajo desde el disco después de que Git cambie de rama.';

  @override
  String get gitConfirmPushSetUpstreamTitle => '¿Configurar la rama upstream?';

  @override
  String gitConfirmPushSetUpstreamMessage(String branch) {
    return 'Esta rama no tiene upstream. BusyMark puede enviar $branch y configurar su upstream cuando haya exactamente un remoto configurado.';
  }

  @override
  String get gitProjectHistory => 'Historial del proyecto';

  @override
  String get gitFileHistory => 'Historial del archivo';

  @override
  String get gitFileHistoryRequiresOpenFile =>
      'El historial de archivos requiere un archivo Markdown abierto.';

  @override
  String get gitLoadMore => 'Cargar más';

  @override
  String get gitChangesInCommit => 'Cambios en este commit';

  @override
  String get gitCompareWithCurrent => 'Comparar con la versión actual';

  @override
  String get gitRestoreVersion => 'Restaurar esta versión';

  @override
  String get gitConfirmRestoreTitle => '¿Restaurar esta versión del archivo?';

  @override
  String get gitConfirmRestoreMessage =>
      'BusyMark reemplazará el archivo actual del árbol de trabajo por la versión seleccionada del commit. El archivo restaurado permanecerá sin preparar.';

  @override
  String get gitCommitActions => 'Acciones del commit';

  @override
  String get gitResetCurrentBranchToHere => 'Restablecer aquí la rama actual…';

  @override
  String gitResetCurrentBranchTitle(String branch, String commit) {
    return '¿Restablecer $branch en $commit?';
  }

  @override
  String gitResetCurrentBranchMessage(String branch, String commit) {
    return 'Esto mueve la rama $branch al commit $commit. Elige cómo debe actualizar Git el índice y el árbol de trabajo.';
  }

  @override
  String get gitReset => 'Restablecer';

  @override
  String get gitResetModeSoft => 'Soft';

  @override
  String get gitResetModeSoftDescription =>
      'Mover solo la rama. Mantener sin cambios el índice y el árbol de trabajo; las diferencias respecto al commit seleccionado permanecen preparadas.';

  @override
  String get gitResetModeMixed => 'Mixed';

  @override
  String get gitResetModeMixedDescription =>
      'Mover la rama y restablecer el índice. Mantener sin cambios el árbol de trabajo, dejando las diferencias sin preparar.';

  @override
  String get gitResetModeHard => 'Hard';

  @override
  String get gitResetModeHardDescription =>
      'Mover la rama y restablecer el índice y el árbol de trabajo. Se descartan los cambios con seguimiento; pueden eliminarse archivos sin seguimiento que obstaculicen la operación.';

  @override
  String get gitResetModeKeep => 'Keep';

  @override
  String get gitResetModeKeepDescription =>
      'Mover la rama y restablecer los archivos con seguimiento conservando los cambios locales. Git aborta si esos cambios entran en conflicto con el restablecimiento.';

  @override
  String gitAdditionsDeletions(int additions, int deletions) {
    return '+$additions -$deletions';
  }

  @override
  String get fileActions => 'Acciones de archivo';

  @override
  String get actions => 'Acciones';

  @override
  String get gitStatusAdded => 'Añadido';

  @override
  String get gitStatusDeleted => 'Eliminado';

  @override
  String get gitStatusRenamed => 'Renombrado';

  @override
  String get gitStatusCopied => 'Copiado';

  @override
  String get gitStatusUntracked => 'Sin seguimiento';

  @override
  String get gitStatusConflicted => 'En conflicto';

  @override
  String get gitStatusIgnored => 'Ignorado';

  @override
  String get gitStatusTypeChanged => 'Tipo cambiado';

  @override
  String get gitStatusModified => 'Modificado';

  @override
  String get gitStatusUnknown => 'Desconocido';

  @override
  String get gitErrorUnavailable => 'Git no está disponible.';

  @override
  String get gitErrorNotRepository =>
      'Este espacio de trabajo no es un repositorio Git.';

  @override
  String get gitErrorUnsafePath =>
      'BusyMark ha bloqueado una ruta de Git insegura.';

  @override
  String get gitErrorInvalidBranchName =>
      'Introduzca un nombre de rama válido.';

  @override
  String get gitErrorNoRemote => 'No hay ningún remoto de Git configurado.';

  @override
  String get gitErrorNoUpstream => 'No hay ninguna rama upstream configurada.';

  @override
  String get gitErrorMultipleRemotes =>
      'Hay varios remotos configurados. Elija un upstream fuera de esta versión de BusyMark.';

  @override
  String get gitErrorDirtyWorkspace =>
      'Guarde o descarte los cambios del editor de BusyMark antes de cambiar de rama.';

  @override
  String get gitErrorResetDirtyWorkspace =>
      'Guarda o descarta los cambios del editor de BusyMark antes de restablecer la rama actual.';

  @override
  String get gitErrorRestoreStagedFile =>
      'Quite el archivo del área de preparación antes de restaurar una versión anterior.';

  @override
  String get gitErrorResetDetachedHead =>
      'Cambia a una rama antes de restablecerla.';

  @override
  String get gitErrorDiverged =>
      'La rama ha divergido. Resuelva el merge o el rebase fuera de esta versión de BusyMark.';

  @override
  String get gitErrorAuthorIdentity =>
      'Git necesita un nombre y un correo electrónico de autor antes de confirmar cambios.';

  @override
  String get gitAuthorIdentityTitle => 'Identidad del autor de Git';

  @override
  String get gitAuthorIdentityMessage =>
      'Introduce la identidad que Git debe registrar en las confirmaciones. BusyMark la guardará y volverá a intentar esta confirmación.';

  @override
  String get gitAuthorName => 'Nombre';

  @override
  String get gitAuthorEmail => 'Correo electrónico';

  @override
  String get gitAuthorIdentityGlobal => 'Usar en todos los repositorios';

  @override
  String get gitAuthorIdentityGlobalDescription =>
      'Cuando se instala como Snap, se aplica a los repositorios abiertos en BusyMark.';

  @override
  String get gitSaveIdentityAndCommit => 'Guardar y confirmar';

  @override
  String get gitErrorAuthentication => 'La autenticación de Git ha fallado.';

  @override
  String get gitErrorNetwork => 'La operación de red de Git ha fallado.';

  @override
  String get gitErrorConflict => 'Git ha informado de conflictos sin resolver.';

  @override
  String get gitErrorCommandFailed => 'El comando de Git ha fallado.';

  @override
  String get syntaxReference => 'Referencia de sintaxis';

  @override
  String get syntaxReferenceMarkdownBlocks => 'Bloques Markdown';

  @override
  String get syntaxReferenceMarkdownBlocksDescription =>
      'Estructuras de bloque admitidas en el código Markdown y la vista previa.';

  @override
  String get syntaxReferenceInlineFormatting => 'Markdown en línea';

  @override
  String get syntaxReferenceInlineFormattingDescription =>
      'Formato dentro de párrafos, elementos de lista y celdas de tabla.';

  @override
  String get syntaxReferenceRawHtmlBlocks => 'Bloques HTML sin procesar';

  @override
  String get syntaxReferenceRawHtmlBlocksDescription =>
      'Etiquetas HTML de bloque seguras renderizadas con widgets de vista previa de BusyMark.';

  @override
  String get syntaxReferenceRawHtmlInline =>
      'Etiquetas HTML sin procesar en línea';

  @override
  String get syntaxReferenceRawHtmlInlineDescription =>
      'Etiquetas HTML en línea seguras renderizadas sin mostrar las etiquetas literales.';

  @override
  String get syntaxReferenceHeadings => 'Encabezados';

  @override
  String get syntaxReferenceParagraphs => 'Párrafos';

  @override
  String get syntaxReferenceLists => 'Listas';

  @override
  String get syntaxReferenceHtmlContainers => 'Contenedores';

  @override
  String get syntaxReferenceHtmlTextBlocks => 'Bloques de texto';

  @override
  String get syntaxReferenceHtmlFigures => 'Figuras e imágenes';

  @override
  String get syntaxReferenceHtmlPreformatted => 'Código preformateado';

  @override
  String get syntaxReferenceHtmlDisclosure => 'Bloques desplegables';

  @override
  String get syntaxReferenceHtmlDescriptionLists => 'Listas de descripción';

  @override
  String get syntaxReferenceHtmlFormattingTags => 'Etiquetas de formato';

  @override
  String get syntaxReferenceHtmlInlineCodeTags =>
      'Etiquetas de código en línea';

  @override
  String get syntaxReferenceHtmlNeutralInlineTags =>
      'Etiquetas semánticas de texto';

  @override
  String get syntaxReferenceSanitizedPreviewDescription =>
      'El HTML permitido se convierte en bloques de vista previa de BusyMark, no se renderiza en un navegador.';

  @override
  String get syntaxReferenceSourcePreservedDescription =>
      'El HTML sin procesar no editado se guarda exactamente como texto fuente.';

  @override
  String get syntaxReferenceMarkdownInsideHtmlDescription =>
      'Los marcadores Markdown dentro de HTML sin procesar se muestran como texto literal.';

  @override
  String get syntaxReferenceBlockedContentDescription =>
      'Se bloquean scripts, estilos, marcos, formularios, SVG, MathML, eventos y atributos inseguros.';

  @override
  String get syntaxReferenceSafeUrlsDescription =>
      'Los enlaces permiten http, https, mailto, tel, URLs relativas y fragmentos; los esquemas inseguros se bloquean.';

  @override
  String get syntaxReferenceCategory => 'Categoría';

  @override
  String get syntaxReferenceCategoryHtml => 'HTML';

  @override
  String get syntaxReferenceCategoryDiagramsAndApi => 'Diagramas y API';

  @override
  String get syntaxReferenceCategoryMathematics => 'Matemáticas';

  @override
  String get syntaxReferenceExample => 'Ejemplo';

  @override
  String get syntaxReferenceIdentifiers => 'Identificadores y alias';

  @override
  String get syntaxReferenceScope => 'Ámbito';

  @override
  String get syntaxReferenceLimitation => 'Limitación de BusyMark';

  @override
  String get syntaxReferenceOfficialDocumentation => 'Documentación oficial';

  @override
  String get syntaxReferenceScopeWritersideMarkdown =>
      'Solo Markdown de Writerside';

  @override
  String get syntaxReferenceScopeWritersideMarkdownAndXml =>
      'Solo Markdown y XML de Writerside';

  @override
  String get syntaxReferenceMarkdownDescription =>
      'Las formas esenciales de Markdown que BusyMark puede crear y previsualizar.';

  @override
  String get syntaxReferenceParagraphExample => 'Un párrafo de texto.';

  @override
  String get syntaxReferenceTableLimitation =>
      'Las tablas usan la sintaxis con barras verticales de GitHub Flavored Markdown.';

  @override
  String get syntaxReferenceHardBreakIdentifiers =>
      'dos espacios al final de la línea, \\, <br>';

  @override
  String get syntaxReferenceHtmlDescription =>
      'BusyMark acepta un subconjunto seguro y específico de HTML sin procesar en el código Markdown.';

  @override
  String get syntaxReferenceDiagramsDescription =>
      'Los bloques delimitados Mermaid, PlantUML, D2 y OpenAPI funcionan en código Markdown. Los identificadores no distinguen mayúsculas de minúsculas y BusyMark conserva la grafía original.';

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
      'Use contenido YAML o JSON dentro de un bloque delimitado. BusyMark no trata cualquier documento YAML o JSON completo como referencia OpenAPI.';

  @override
  String get syntaxReferenceSemanticDiagramBlocks =>
      'Bloques de código semánticos para diagramas';

  @override
  String get syntaxReferenceSemanticDiagramLimitation =>
      'Las formas semánticas code-block y src admiten Mermaid, PlantUML y D2, no OpenAPI, y solo dentro de proyectos Writerside.';

  @override
  String get syntaxReferenceReferencedDiagramSource =>
      'Origen de diagrama referenciado';

  @override
  String get syntaxReferenceReferencedDiagramLimitation =>
      'Las rutas deben ser relativas y permanecer dentro del proyecto Writerside abierto; la forma de bloque delimitado con src solo funciona en Markdown de Writerside.';

  @override
  String get syntaxReferenceMathematicsDescription =>
      'BusyMark admite expresiones TeX, no documentos TeX o LaTeX completos.';

  @override
  String get syntaxReferenceInlineMath => 'Matemáticas en línea';

  @override
  String get syntaxReferenceGithubMath =>
      'Matemáticas de GitHub con dólar y acento grave';

  @override
  String get syntaxReferenceDisplayMath => 'Matemáticas en bloque';

  @override
  String get syntaxReferenceMathFence => 'Bloque delimitado math';

  @override
  String get syntaxReferenceTexFence => 'Bloque delimitado tex';

  @override
  String get syntaxReferenceMathDelimitersLimitation =>
      'BusyMark no reconoce \\(...\\) ni \\[...\\] como delimitadores matemáticos de Markdown.';

  @override
  String get syntaxReferenceTexFenceLimitation =>
      'Fuera del modo Writerside, un bloque tex sigue siendo un bloque de código común.';

  @override
  String get syntaxReferenceWritersideMathElement =>
      'Elemento math de Writerside';

  @override
  String get syntaxReferenceWritersideMathElementLimitation =>
      'El elemento math es sintaxis semántica de Writerside, no MathML HTML sin procesar permitido.';

  @override
  String get syntaxReferenceSemanticTexBlock =>
      'Bloque de código TeX semántico';

  @override
  String get syntaxReferenceWritersideDescription =>
      'Estas extensiones específicas solo se interpretan dentro de proyectos Writerside abiertos.';

  @override
  String get syntaxReferenceAdmonitionBlockquote => 'Cita de aviso';

  @override
  String get syntaxReferenceAdmonitionLimitation =>
      'Una cita simple es un consejo en Markdown de Writerside; en Markdown común sigue siendo una cita normal.';

  @override
  String get syntaxReferenceSemanticAdmonitions => 'Avisos semánticos';

  @override
  String get syntaxReferenceSemanticMarkupLimitation =>
      'Markdown común no interpreta estos elementos semánticos de Writerside.';

  @override
  String get syntaxReferenceCollapsibleHeading => 'Encabezado plegable';

  @override
  String get syntaxReferenceCollapsibleCode => 'Bloque de código plegable';

  @override
  String get syntaxReferenceSemanticCollapsibles =>
      'Contenido semántico plegable';

  @override
  String get syntaxReferenceSemanticCollapsiblesLimitation =>
      'BusyMark admite las formas plegables chapter, procedure, code-block y lista de definiciones, no todo el catálogo de Writerside.';

  @override
  String get syntaxReferenceSemanticCodeBlocks =>
      'Bloques de código semánticos para matemáticas y diagramas';

  @override
  String get syntaxReferenceVideo => 'Vídeo de Writerside';

  @override
  String get syntaxReferenceVideoLimitation =>
      'El vídeo local usa una imagen preview-src local; las fuentes alojadas deben ser URL HTTPS compatibles de YouTube o Vimeo.';

  @override
  String get exportAsPdf => 'Exportar como PDF';

  @override
  String get pdfExportDescription =>
      'Elige el diseño de página para crear un PDF pulido e independiente.';

  @override
  String get pdfRemoteImagesNote =>
      'Las imágenes remotas no se descargan durante la exportación. Las imágenes locales se incluyen cuando están disponibles.';

  @override
  String get pdfPageSize => 'Tamaño de página';

  @override
  String get pdfPageSizeA4 => 'A4';

  @override
  String get pdfPageSizeLetter => 'Carta';

  @override
  String get pdfOrientation => 'Orientación';

  @override
  String get pdfPortrait => 'Vertical';

  @override
  String get pdfLandscape => 'Horizontal';

  @override
  String get pdfMargins => 'Márgenes';

  @override
  String get pdfMarginNarrow => 'Estrechos';

  @override
  String get pdfMarginNormal => 'Normales';

  @override
  String get pdfMarginWide => 'Amplios';

  @override
  String get pdfIncludePageNumbers => 'Incluir números de página';

  @override
  String get export => 'Exportar';

  @override
  String get exportFormat => 'Formato de salida';

  @override
  String get exportingPdf => 'Exportando PDF…';

  @override
  String get fileTypePdf => 'Documento PDF';

  @override
  String pdfExported(String fileName) {
    return 'Se exportó $fileName.';
  }

  @override
  String pdfExportedWithWarnings(String fileName, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count advertencias',
      one: '1 advertencia',
    );
    return '$fileName se exportó con $_temp0.';
  }

  @override
  String get pdfExportUnavailable =>
      'Falta el componente de exportación a PDF. Reinstala BusyMark e inténtalo de nuevo.';

  @override
  String get pdfExportTimedOut =>
      'La exportación a PDF tardó demasiado y se detuvo.';

  @override
  String get pdfExportFailed =>
      'BusyMark no pudo exportar este documento como PDF.';

  @override
  String get visualizationRendering => 'Renderizando…';

  @override
  String get visualizationStale => 'Mostrando la última visualización válida';

  @override
  String get visualizationShowSource => 'Mostrar código fuente';

  @override
  String get visualizationShowRender => 'Mostrar visualización';

  @override
  String get visualizationFitWidth => 'Ajustar al ancho';

  @override
  String get visualizationSaveImage => 'Guardar imagen';

  @override
  String get visualizationCopyImage => 'Copiar imagen';

  @override
  String get visualizationImageCopied => 'Imagen copiada';

  @override
  String get visualizationOpenApiReference => 'Abrir referencia de la API';

  @override
  String get visualizationValid => 'Válido';

  @override
  String get visualizationInvalid => 'No válido';

  @override
  String get visualizationServers => 'Servidores';

  @override
  String get visualizationPaths => 'Rutas';

  @override
  String get visualizationOperations => 'Operaciones';

  @override
  String get visualizationTags => 'Etiquetas';

  @override
  String get visualizationNoOperations => 'No hay operaciones coincidentes';

  @override
  String get visualizationSearchOperations => 'Buscar operaciones';

  @override
  String get visualizationRenderFailed =>
      'No se pudo renderizar esta visualización.';

  @override
  String get visualizationRetry => 'Reintentar';

  @override
  String visualizationSaved(String fileName) {
    return 'Se guardó $fileName';
  }

  @override
  String get shortcutExportPdfDescription =>
      'Exportar el documento activo o el módulo de Writerside como PDF.';

  @override
  String get instances => 'Instancias';

  @override
  String get newInstance => 'Nueva instancia';

  @override
  String get newTocLibrary => 'Nueva biblioteca de TOC';

  @override
  String get editInstance => 'Editar instancia';

  @override
  String get openTocFile => 'Abrir archivo del índice';

  @override
  String get createInstance => 'Crear instancia';

  @override
  String get createTocLibrary => 'Crear biblioteca de TOC';

  @override
  String get instanceContent => 'Contenido';

  @override
  String get instanceContentSource => 'Crear desde';

  @override
  String get emptyInstance => 'Instancia vacía';

  @override
  String get markdownFiles => 'Archivos Markdown locales';

  @override
  String get chooseMarkdownFolder => 'Elegir carpeta de Markdown';

  @override
  String get errorWritersideInstanceImportSourceRequired =>
      'Elige una carpeta que contenga archivos Markdown.';

  @override
  String get instanceAppearance => 'Apariencia';

  @override
  String get instanceColor => 'Color del icono';

  @override
  String get instanceVersion => 'Versión';

  @override
  String instanceVersionInherited(String version) {
    return 'Si este campo está vacío, se usa la versión del proyecto $version.';
  }

  @override
  String get instanceWebPath => 'Ruta web';

  @override
  String get instanceStatus => 'Estado';

  @override
  String get instanceStatusRelease => 'Publicación';

  @override
  String get instanceStatusEap => 'Acceso anticipado';

  @override
  String get instanceStatusDeprecated => 'Obsoleta';

  @override
  String get allowSearchEngineIndexing =>
      'Permitir la indexación por motores de búsqueda';

  @override
  String get allowSearchEngineIndexingDescription =>
      'Permite que motores de búsqueda externos indexen esta salida.';

  @override
  String get offlineArtifact => 'Artefacto sin conexión';

  @override
  String get offlineArtifactDescription =>
      'Incluye los recursos para que la documentación generada sea autónoma.';

  @override
  String get instanceOutputSettings => 'Configuración de salida';

  @override
  String get markdownImportSource => 'Origen de Markdown';

  @override
  String get markdownImportFiles => 'Archivos Markdown';

  @override
  String get selectNone => 'No seleccionar ninguno';

  @override
  String markdownFilesFound(int count) {
    return 'Se encontraron $count archivo(s) Markdown';
  }

  @override
  String get noMarkdownFilesFound =>
      'No se encontraron archivos Markdown en este directorio.';

  @override
  String get copyReferencedMedia => 'Copiar medios referenciados';

  @override
  String get copyReferencedMediaDescription =>
      'Copia las imágenes y los vídeos locales de los archivos seleccionados conservando las rutas relativas.';

  @override
  String get instanceIdRenameWarningTitle => '¿Cambiar el ID de la instancia?';

  @override
  String instanceIdRenameWarning(String oldId, String newId) {
    return 'BusyMark cambiará el nombre del archivo .tree y actualizará las referencias del proyecto Writerside de «$oldId» a «$newId». Los scripts de publicación no se modifican y deben actualizarse por separado.';
  }

  @override
  String get renameAndUpdateReferences =>
      'Cambiar nombre y actualizar referencias';

  @override
  String get tocLibraryDescription =>
      'Una biblioteca de TOC almacena secciones reutilizables y no genera una salida propia.';

  @override
  String get defaultTocLibraryName => 'TOC compartido';

  @override
  String get instanceColorAutomatic => 'Automático';

  @override
  String get instanceColorBlue => 'Azul';

  @override
  String get instanceColorGreen => 'Verde';

  @override
  String get instanceColorOrange => 'Naranja';

  @override
  String get instanceColorPurple => 'Morado';

  @override
  String get instanceColorRed => 'Rojo';

  @override
  String get instanceColorTeal => 'Verde azulado';

  @override
  String get instanceColorYellow => 'Amarillo';

  @override
  String get errorWritersideInstanceNameRequired =>
      'Introduce un nombre para la instancia.';

  @override
  String errorWritersideInstanceIdExists(String id) {
    return 'Ya existe una instancia con el ID «$id».';
  }

  @override
  String errorWritersideInstanceTreeExists(String path) {
    return 'El árbol de la instancia ya existe: $path';
  }

  @override
  String errorWritersideInstanceImportSourceMissing(String path) {
    return 'El directorio de origen de Markdown no existe: $path';
  }

  @override
  String get errorWritersideInstanceImportSelectionRequired =>
      'Selecciona al menos un archivo Markdown para importar.';

  @override
  String errorWritersideInstanceImportFileInvalid(String path) {
    return 'No es un archivo Markdown legible dentro del origen seleccionado: $path';
  }

  @override
  String errorWritersideInstanceImportTargetExists(String path) {
    return 'La importación sobrescribiría un archivo existente del proyecto: $path';
  }

  @override
  String get errorWritersideInstanceFilesChanged =>
      'Los archivos de la instancia cambiaron en el disco. Revísalos e inténtalo de nuevo.';

  @override
  String errorWritersideInstanceRollbackFailed(String paths) {
    return 'BusyMark no pudo revertir por completo el cambio de la instancia. Revisa estos archivos antes de continuar: $paths';
  }

  @override
  String get errorWritersideInstanceLibraryImport =>
      'Una biblioteca de TOC no puede importar temas Markdown.';

  @override
  String get errorWritersideInstanceWebPathInvalid =>
      'La ruta web debe ocupar una sola línea.';

  @override
  String get errorWritersideInstanceConfigurationInvalid =>
      'La configuración de la instancia de Writerside no es válida. Corrige sus diagnósticos e inténtalo de nuevo.';

  @override
  String get errorWritersideInstanceTemporaryFile =>
      'BusyMark no pudo preparar de forma segura los cambios de la instancia.';

  @override
  String diagnosticWritersideTreeInvalidStatus(String status) {
    return 'Estado de instancia desconocido «$status». Usa release, eap o deprecated.';
  }

  @override
  String diagnosticWritersideDuplicateInstanceId(String id) {
    return 'El ID de instancia «$id» se usa en más de un archivo de árbol.';
  }

  @override
  String get diagnosticWritersideBuildProfilesInvalidRoot =>
      'buildprofiles.xml debe tener un elemento raíz <buildprofiles>.';

  @override
  String diagnosticWritersideBuildProfilesInvalidBoolean(
    String name,
    String value,
  ) {
    return 'El valor $name «$value» debe ser true o false.';
  }

  @override
  String get diagnosticWritersideBuildProfileMissingInstance =>
      'Un elemento <build-profile> debe indicar un ID de instancia.';

  @override
  String get diagnosticWritersideTreeInvalidInclude =>
      'Un <include> del árbol debe indicar tanto from como element-id.';

  @override
  String get diagnosticWritersideTreeMissingSnippetId =>
      'Un <snippet> del árbol debe indicar un id.';

  @override
  String get diagnosticWritersideTreeInvalidCrossInstanceReference =>
      'Una referencia de TOC entre instancias debe indicar tanto ref como in.';

  @override
  String get diagnosticWritersideTreeConflictingTargets =>
      'Un elemento de TOC no puede apuntar a más de un tema, referencia, enlace o redirección.';

  @override
  String diagnosticWritersideTreeDuplicateElementId(String id) {
    return 'El ID de elemento de árbol «$id» está declarado más de una vez.';
  }

  @override
  String get diagnosticWritersideInstanceGroupsInvalidRoot =>
      'El archivo de grupos de instancias debe tener un elemento raíz <instance-groups>.';

  @override
  String get diagnosticWritersideInstanceGroupInvalid =>
      'Un grupo de instancias debe indicar un id y una lista de instancias no vacíos.';

  @override
  String diagnosticWritersideInstanceGroupDuplicateId(String id) {
    return 'El ID de grupo de instancias «$id» está declarado más de una vez.';
  }

  @override
  String diagnosticWritersideExternalTreeInclude(
    String source,
    String id,
    String origin,
  ) {
    return 'La inclusión de TOC «$source#$id» pertenece al módulo externo «$origin» y no se puede expandir en este espacio de trabajo.';
  }

  @override
  String diagnosticWritersideTreeIncludeElementMissing(
    String source,
    String id,
  ) {
    return 'El elemento de árbol «$id» no existe en el árbol registrado «$source».';
  }

  @override
  String diagnosticWritersideTreeCircularInclude(String source, String id) {
    return 'La inclusión de árbol «$source#$id» crea un ciclo.';
  }

  @override
  String diagnosticWritersideUnknownInstanceGroup(String group) {
    return 'La condición de instancia hace referencia al grupo desconocido «@$group».';
  }

  @override
  String diagnosticWritersideReferenceInstanceMissing(String instance) {
    return 'La referencia entre instancias apunta a la instancia desconocida «$instance».';
  }

  @override
  String diagnosticWritersideReferenceTopicMissing(
    String topic,
    String instance,
  ) {
    return 'El tema «$topic» no está en la instancia referenciada «$instance».';
  }

  @override
  String get download => 'Descargar';

  @override
  String get exportWritersideAsPdf => 'Exportar Writerside como PDF';

  @override
  String get writersidePdfContent => 'Contenido de la exportación';

  @override
  String get writersidePdfPage => 'Página';

  @override
  String get exportingWritersidePdf => 'Exportando PDF de Writerside…';

  @override
  String get ai => 'IA';

  @override
  String get aiLocalOllama => 'Ollama local';

  @override
  String get aiDisabled => 'Desactivado';

  @override
  String get aiExplicitEditingDescription =>
      'La edición con IA solo se ejecuta de forma explícita. BusyMark envía únicamente el contexto mostrado al proveedor seleccionado y nunca aplica una propuesta sin revisarla.';

  @override
  String get aiProvider => 'Proveedor de IA';

  @override
  String get aiDefaultProvider => 'Proveedor predeterminado';

  @override
  String get aiConfigureProvider => 'Configurar proveedor';

  @override
  String get aiChooseProvider => 'Elegir proveedor de IA';

  @override
  String get aiOllamaEndpoint => 'Punto de conexión de Ollama';

  @override
  String get aiOllamaModel => 'Modelo de Ollama';

  @override
  String get aiTestConnection => 'Probar conexión';

  @override
  String get aiTestingConnection => 'Probando…';

  @override
  String aiConnectionReady(int count) {
    return 'Conectado. Se encontraron $count modelo(s) instalado(s).';
  }

  @override
  String get aiNoModels => 'Ningún modelo seleccionado.';

  @override
  String get aiConnectionFailed =>
      'BusyMark no pudo verificar la generación de texto con IA.';

  @override
  String get aiConfigureFirst =>
      'Active un proveedor de IA y verifique un modelo en Configuración → IA.';

  @override
  String get aiEditWithAi => 'Editar con IA';

  @override
  String get aiRefineWithAi => 'Mejorar con IA';

  @override
  String get aiInstruction => 'Instrucción';

  @override
  String get aiChangeTarget => 'Qué se puede cambiar';

  @override
  String get aiSharedContext => 'Contexto compartido con la IA';

  @override
  String get aiTargetSelection => 'Contenido seleccionado';

  @override
  String get aiTargetInsertAfterBlock => 'Insertar después del bloque actual';

  @override
  String get aiTargetCurrentBlock => 'Bloque actual';

  @override
  String get aiTargetCurrentSection => 'Sección actual';

  @override
  String get aiTargetCompleteDocument => 'Documento completo';

  @override
  String get aiContextNone => 'Sin contexto del documento';

  @override
  String get aiContextSelection => 'Contenido seleccionado';

  @override
  String get aiContextCurrentBlock => 'Bloque actual';

  @override
  String get aiContextCurrentSection => 'Sección actual';

  @override
  String get aiContextCompleteDocument => 'Documento completo';

  @override
  String get aiGenerating => 'Generando propuesta…';

  @override
  String get aiProposal => 'Propuesta de IA';

  @override
  String get aiGenerateProposal => 'Generar propuesta';

  @override
  String aiContextDisclosure(int count) {
    return 'El proveedor seleccionado recibirá $count caracteres del contexto mostrado.';
  }

  @override
  String get aiOriginal => 'Texto original';

  @override
  String get aiSuggested => 'Sugerencia';

  @override
  String get aiApplyProposal => 'Aplicar propuesta';

  @override
  String aiTokenUsage(int input, int output) {
    return '$input tokens de entrada · $output tokens de salida';
  }

  @override
  String get aiStaleProposal =>
      'El documento cambió mientras se generaba esta propuesta. Ejecute la acción de nuevo.';

  @override
  String get gitAiStagedChangesChanged =>
      'Los cambios preparados cambiaron mientras se generaba este mensaje de commit. Ejecute la acción de nuevo.';

  @override
  String get aiViewContext => 'Ver contexto enviado';

  @override
  String get aiReviewExactContent => 'Revisar contenido exacto';

  @override
  String get aiContentToChange => 'Contenido que se modificará';

  @override
  String get aiContentSentToAi => 'Contenido enviado a la IA';

  @override
  String get aiApiKey => 'Clave de API';

  @override
  String get aiApiKeyStoredHint =>
      'Hay una clave guardada en el almacén de credenciales del sistema';

  @override
  String get aiApiKeyEnterHint => 'Introduzca una clave de API del proveedor';

  @override
  String get aiReplaceApiKey => 'Sustituir clave de API';

  @override
  String get aiSaveApiKey => 'Guardar clave de API de forma segura';

  @override
  String get aiRemoveApiKey => 'Eliminar clave de API guardada';

  @override
  String get aiCredentialSaved =>
      'La clave de API se guardó en el almacén de credenciales del sistema.';

  @override
  String get aiCredentialRemoved => 'Se eliminó la clave de API guardada.';

  @override
  String get aiModelRouting => 'Selección de modelo';

  @override
  String get aiAutomaticRouting => 'Automática según la tarea';

  @override
  String get aiFixedModelRouting => 'Usar el modelo seleccionado';

  @override
  String get aiPreferredModel => 'Modelo preferido';

  @override
  String get aiModel => 'Modelo';

  @override
  String aiUsageThisMonth(int requests, int input, int output) {
    return '$requests solicitudes · $input tokens de entrada · $output tokens de salida';
  }

  @override
  String aiCloudConsentTitle(String provider) {
    return '¿Enviar contenido a $provider?';
  }

  @override
  String aiCloudConsentEnable(String provider) {
    return 'Activar $provider';
  }

  @override
  String get aiCloudConsentMessage =>
      'Solo se envía el contenido mostrado en cada diálogo de revisión de IA. Las solicitudes no conservan estado, las propuestas requieren revisión y la clave de API se guarda en el almacén de credenciales del sistema Linux.';

  @override
  String aiCloudConsentRequired(String provider) {
    return 'Confirme primero el envío de datos a $provider en Configuración → IA.';
  }

  @override
  String aiGenerationVerified(String model, int count) {
    return 'Generación verificada con $model. Hay $count modelos compatibles disponibles.';
  }

  @override
  String get aiColdStartObserved =>
      'Se detectó un arranque en frío del modelo local.';

  @override
  String get aiNoCompatibleModels =>
      'No hay ningún modelo compatible de generación de texto disponible.';

  @override
  String get aiEnableProvider => 'Active primero un proveedor de IA.';

  @override
  String get aiDraftCommitMessage => 'Redactar mensaje de commit';

  @override
  String get aiDrafting => 'Redactando…';

  @override
  String get aiDraftWithAi => 'Redactar con IA';

  @override
  String diagnosticMarkdownHeadingSkippedLevel(int level, int previousLevel) {
    return 'El encabezado de nivel $level sigue al nivel $previousLevel; revise la jerarquía de las secciones.';
  }

  @override
  String get diagnosticMarkdownLinkEmptyText =>
      'El texto del enlace está vacío; proporcione un nombre accesible que describa su propósito.';

  @override
  String diagnosticMarkdownLinkReviewText(String text) {
    return 'Revise si el texto del enlace «$text» describe su propósito en contexto.';
  }

  @override
  String get diagnosticMarkdownTableEmptyHeader =>
      'Los encabezados de tabla deben identificar sus columnas; complete cada encabezado vacío.';

  @override
  String get mathRenderFailed =>
      'No se pudo representar la expresión matemática.';

  @override
  String get inlineMath => 'Matemáticas en línea';

  @override
  String get displayMath => 'Matemáticas en bloque';

  @override
  String get goToDeclaration => 'Ir a la declaración';

  @override
  String get findUsages => 'Buscar usos';

  @override
  String get cannotRenameSymbol =>
      'No se puede cambiar el nombre del símbolo de forma segura. Compruebe el nombre y actualice la referencia antes de volver a intentarlo.';

  @override
  String get renameTopicFileInstead =>
      'Los ID de los temas proceden de sus nombres de archivo. Use «Cambiar nombre del archivo de tema» en la tabla de contenido o en la barra lateral Archivos.';

  @override
  String get keyboardLayout => 'Distribución del teclado';

  @override
  String get diagnosticWritersideUnsupported =>
      'El contenido no compatible o mal formado se muestra como código fuente.';

  @override
  String diagnosticWritersideSource(String reference, String reason) {
    return 'No se puede resolver el origen «$reference»: $reason';
  }

  @override
  String diagnosticWritersideLink(String destination) {
    return 'El destino del enlace no está disponible en esta instancia: $destination';
  }

  @override
  String diagnosticWritersideSchema(
    String element,
    String attribute,
    String reason,
  ) {
    return 'Marcado Writerside no válido: $element, $attribute. $reason';
  }

  @override
  String get diagnosticWritersideLlmsTxt =>
      'Use <llms-txt>true</llms-txt> o <llms-txt>false</llms-txt>; single-file ya no es compatible.';

  @override
  String diagnosticWritersideReference(String kind, String reference) {
    return 'No se puede resolver $kind: $reference';
  }

  @override
  String get exportAsHtml => 'Exportar como HTML…';

  @override
  String get fileTypeHtml => 'Documento HTML';

  @override
  String get exportingHtml => 'Exportando HTML…';

  @override
  String get htmlExported => 'Exportación HTML completada';

  @override
  String get htmlExportFailed => 'Error al exportar HTML';

  @override
  String get htmlKeepAssetsTogether =>
      'Al copiar esta exportación, mantenga juntos el archivo HTML y su carpeta de recursos.';

  @override
  String get htmlInstanceDescription =>
      'Exporte una instancia como páginas enlazadas sin conexión. Elija un nombre para una carpeta de salida exclusiva.';

  @override
  String get htmlInstance => 'Instancia';

  @override
  String get htmlOwnedDirectoryOnly =>
      'Solo se puede reemplazar una carpeta creada por la exportación HTML de BusyMark. Se conservarán los archivos modificados o ajenos.';

  @override
  String get showInFolder => 'Mostrar en carpeta';

  @override
  String sortTableColumn(String column) {
    return 'Ordenar $column';
  }

  @override
  String get exportReset => 'Restablecer valores predeterminados';

  @override
  String get exportToc => 'Incluir índice';

  @override
  String get exportTocDepth => 'Profundidad del índice';

  @override
  String get exportNumberHeadings => 'Numerar encabezados';

  @override
  String get exportLegal => 'US Legal';

  @override
  String get exportCustom => 'Personalizado';

  @override
  String get exportPageWidth => 'Ancho de página (mm)';

  @override
  String get exportPageHeight => 'Alto de página (mm)';

  @override
  String get exportMarginTop => 'Margen superior (mm)';

  @override
  String get exportMarginRight => 'Margen derecho (mm)';

  @override
  String get exportMarginBottom => 'Margen inferior (mm)';

  @override
  String get exportMarginLeft => 'Margen izquierdo (mm)';

  @override
  String get exportTypography => 'Tipografía';

  @override
  String get exportSans => 'Sin serifas';

  @override
  String get exportSerif => 'Con serifas';

  @override
  String get exportBodySize => 'Tamaño del texto';

  @override
  String get exportCodeSize => 'Tamaño del código';

  @override
  String get exportRunningText => 'Encabezado y pie de página';

  @override
  String get exportHeader => 'Encabezado';

  @override
  String get exportFooter => 'Pie de página';

  @override
  String get exportNone => 'Ninguno';

  @override
  String get exportDocumentTitle => 'Título del documento';

  @override
  String get exportBottomLeft => 'Abajo a la izquierda';

  @override
  String get exportBottomCenter => 'Abajo en el centro';

  @override
  String get exportBottomRight => 'Abajo a la derecha';

  @override
  String get exportFirstPage => 'Mostrar encabezado y pie en la primera página';

  @override
  String get exportAccent => 'Color de acento / enlaces';

  @override
  String get exportTheme => 'Tema';

  @override
  String get exportAutomatic => 'Automático';

  @override
  String get exportLayout => 'Diseño';

  @override
  String get exportContentWidth => 'Ancho máximo del contenido';

  @override
  String get exportOutput => 'Salida';

  @override
  String get exportPackaging => 'Empaquetado';

  @override
  String get exportSingleFile => 'Un solo archivo HTML';

  @override
  String get exportAssetsDirectory => 'HTML + carpeta de recursos';

  @override
  String get exportCustomCss => 'Hoja de estilo personalizada…';

  @override
  String get exportRemoveCss => 'Quitar hoja de estilo';

  @override
  String get exportCssNote =>
      'Seleccione un archivo CSS UTF-8 opcional (hasta 256 KiB). Se rechazan importaciones, URL de recursos y CSS ejecutable o escapado. Los estilos se aplican después de los de BusyMark. Nunca se descargan recursos remotos.';

  @override
  String get exportSitePackagingNote =>
      'Writerside conserva páginas de temas separadas y enlazadas. El modo de archivo único incorpora los recursos en cada página.';

  @override
  String get exportInvalidGeometry =>
      'Deje al menos 20 mm de ancho y alto de contenido después de los márgenes.';

  @override
  String get exportInvalidColor => 'Introduzca un color como #RRGGBB.';

  @override
  String get exportInvalidCss =>
      'Elija un archivo .css UTF-8 legible de hasta 256 KiB, sin importaciones, URL de recursos, HTML ni CSS ejecutable o escapado.';

  @override
  String get clipboardHistory => 'Historial de la Copia';

  @override
  String get clipboardHistoryDescription =>
      'Abrir el historial de la copia local de la sesión.';

  @override
  String get clipboardCurrent => 'Copia actual';

  @override
  String get clipboardCurrentExternal => 'Copia actual de otra aplicación';

  @override
  String clipboardDestination(String name) {
    return 'Pegar en $name';
  }

  @override
  String get clipboardSessionOnly =>
      'Almacenado solo para esta sesión de BusyMark.';

  @override
  String get clipboardNoItems => 'El historial de la copia está vacío.';

  @override
  String get clipboardDisabled =>
      'La colección de Historial de la Copia está deshabilitada en la configuración.';

  @override
  String get clipboardUnavailable =>
      'El contenido de la copia actual no está disponible o no es compatible.';

  @override
  String get clipboardTooLarge =>
      'Este elemento de la copia es demasiado grande para conservarlo.';

  @override
  String get clipboardPastePlainText => 'Pegar como Texto Plano';

  @override
  String get clipboardClearAll => 'Borrar el Historial de la Copia';

  @override
  String get clipboardEntryText => 'Texto';

  @override
  String get clipboardEntryRichText => 'Texto enriquecido';

  @override
  String get clipboardEntryImage => 'Imagen';

  @override
  String clipboardOrigin(String name) {
    return 'Copiado de $name';
  }

  @override
  String get localHistory => 'Historial Local';

  @override
  String get localHistoryEllipsis => 'Historial Local…';

  @override
  String get localHistoryDescription =>
      'Mostrar las revisiones locales guardadas y automáticas para el documento actual.';

  @override
  String get findLocalHistoryEllipsis => 'Buscar en el Historial Local…';

  @override
  String get findLocalHistoryDescription =>
      'Buscar documentos y contenido de revisiones en el Historial Local.';

  @override
  String get localHistoryNoDocuments =>
      'Ningún documento tiene Historial Local.';

  @override
  String get localHistoryNoRevisions =>
      'Este documento no tiene revisiones en el Historial Local.';

  @override
  String get localHistorySelectedRevision => 'Revisión seleccionada';

  @override
  String get localHistoryCurrentEditor => 'Contenido del editor actual';

  @override
  String get localHistoryCurrentDisk => 'Contenido actual en el disco';

  @override
  String get localHistoryMissingFile => 'El archivo original está ausente.';

  @override
  String get localHistoryRestoreRevision => 'Restaurar Revisión';

  @override
  String get localHistoryRestoreOriginalLocation =>
      'Restaurar a la Ubicación Original';

  @override
  String get localHistoryRestoreNewLocation =>
      'Restaurar a una Nueva Ubicación…';

  @override
  String get localHistoryRestoreChange => 'Restaurar Cambio';

  @override
  String get localHistoryRestoreUnavailable =>
      'Este cambio no puede ser restaurado porque la comparación ya no es válida.';

  @override
  String get localHistoryComparisonSimplified =>
      'Esta comparación grande se ha simplificado. Restaurar cambios individuales no está disponible.';

  @override
  String localHistoryOlderChange(String text) {
    return 'Cambio de revisión anterior: $text';
  }

  @override
  String localHistoryCurrentChange(String text) {
    return 'Cambio de contenido actual: $text';
  }

  @override
  String get localHistoryDeleted => 'Eliminado';

  @override
  String get localHistoryUntitled => 'Sin título';

  @override
  String get localHistoryClearDocument =>
      'Borrar el historial de este documento';

  @override
  String get localHistoryClearAll => 'Borrar todo el historial local';

  @override
  String get localHistoryClearDocumentTitle =>
      '¿Borrar el historial del documento?';

  @override
  String get localHistoryClearAllTitle => '¿Borrar todo el historial local?';

  @override
  String get localHistoryClearConfirmation =>
      'Esto elimina permanentemente las revisiones almacenadas. Esta acción no se puede deshacer.';

  @override
  String get localHistoryWarningIndexRebuilt =>
      'El índice de historial local se dañó y se reconstruyó a partir de revisiones intactas.';

  @override
  String localHistoryWarningUnsupportedFormat(String version) {
    return 'Esta tienda de historial local utiliza un formato no soportado $version.';
  }

  @override
  String localHistoryWarningUnavailable(String detail) {
    return 'El historial local no está disponible: $detail';
  }

  @override
  String get localHistoryWarningRecordingDisabled =>
      'La grabación está deshabilitada o esta ruta está excluida. Re-habilite la grabación antes de restaurar.';

  @override
  String localHistoryWarningPathChange(String detail) {
    return 'El historial local no pudo registrar el cambio de ruta: $detail';
  }

  @override
  String localHistoryWarningDeletedPath(String detail) {
    return 'El historial local no pudo conservar la ruta eliminada: $detail';
  }

  @override
  String get localHistoryWarningRevisionMissing =>
      'La revisión seleccionada está ausente o dañada.';

  @override
  String localHistoryWarningRevisionRead(String detail) {
    return 'La revisión seleccionada no se puede leer: $detail';
  }

  @override
  String localHistoryWarningCapture(String detail) {
    return 'El historial local no pudo capturar esta revisión: $detail';
  }

  @override
  String localHistoryRevisionAt(String reason, String timestamp) {
    return '$reason – $timestamp';
  }

  @override
  String get localHistoryReasonBaseline => 'Línea base';

  @override
  String get localHistoryReasonSaved => 'Guardado';

  @override
  String get localHistoryReasonAutomaticCheckpoint =>
      'Puntos de control automático';

  @override
  String get localHistoryReasonBeforeReload => 'Antes de recargar';

  @override
  String get localHistoryReasonBeforeDiscard => 'Antes de descartar';

  @override
  String get localHistoryReasonBeforeRestore => 'Antes de restaurar';

  @override
  String get localHistoryReasonBeforeDelete => 'Antes de eliminar';

  @override
  String get localHistoryReasonExternalChange => 'Cambio externo';

  @override
  String get settingsHistory => 'Historial';

  @override
  String get settingsClipboardHistoryTitle => 'Recolectar Historial de Copia';

  @override
  String get settingsClipboardHistoryDescription =>
      'Mantener el contenido copiado y pegado con éxito solo para esta sesión de BusyMark.';

  @override
  String get settingsLocalHistoryTitle => 'Registrar Historial Local';

  @override
  String get settingsLocalHistoryDescription =>
      'Almacenar revisiones del documento en este dispositivo para recuperación y comparación.';

  @override
  String get settingsHistoryCheckpoint =>
      'Intervalo de punto de control automático';

  @override
  String get settingsHistoryRetention => 'Edad de retención';

  @override
  String get settingsHistoryStorage => 'Almacenamiento máximo';

  @override
  String get settingsHistoryExcludedPaths => 'Rutas excluidas';

  @override
  String get settingsHistoryExcludedPathsHint => 'Una ruta absoluta por línea';

  @override
  String settingsSecondsValue(int value) {
    return '$value segundos';
  }

  @override
  String settingsDaysValue(int value) {
    return '$value días';
  }

  @override
  String settingsMebibytesValue(int value) {
    return '$value MiB';
  }

  @override
  String get spelling => 'Ortografía';

  @override
  String get automaticSpelling => 'Revisión ortográfica automática';

  @override
  String get defaultSpellingLanguage => 'Idioma ortográfico predeterminado';

  @override
  String get projectSpellingLanguage =>
      'Idioma de corrección ortográfica del proyecto';

  @override
  String get chooseSpellingLanguage => 'Elegir idioma ortográfico';

  @override
  String get spellingLanguageUnsetStatus => 'Idioma…';

  @override
  String get spellingOffStatus => 'Ortografía desactivada';

  @override
  String get checkSpelling => 'Revisar ortografía';

  @override
  String get ignoreSpellingOnce => 'Ignorar una vez';

  @override
  String get ignoreSpellingDocument => 'Ignorar todo en este documento';

  @override
  String get addPersonalSpellingWord => 'Añadir al diccionario personal';

  @override
  String get addProjectSpellingWord => 'Añadir al diccionario del proyecto';

  @override
  String get inheritSpellingLanguage =>
      'Usar el idioma del proyecto o la aplicación';

  @override
  String get disableDocumentSpelling => 'No revisar la ortografía';

  @override
  String get importSpellingDictionary => 'Importar diccionario';

  @override
  String get personalSpellingDictionary => 'Diccionario personal';

  @override
  String get projectSpellingDictionary => 'Diccionario del proyecto';

  @override
  String get noSpellingErrors => 'No hay errores ortográficos';

  @override
  String get noSpellingSuggestions => 'No hay sugerencias ortográficas';

  @override
  String get spellingWordCheckFailed => 'No se pudo comprobar esta palabra';

  @override
  String get spellingCheckFailed => 'La revisión ortográfica falló';

  @override
  String get spellingSettingsLoadFailed =>
      'No se pudo cargar la configuración ortográfica';

  @override
  String get retrySpellingSettings =>
      'Volver a cargar la configuración ortográfica';

  @override
  String get spellingCheckIncomplete =>
      'La revisión ortográfica está incompleta';

  @override
  String get spellingDictionaryNotInstalled => 'Diccionario no instalado';

  @override
  String spellingDictionaryNotInstalledForLanguage(String dictionary) {
    return 'El diccionario de $dictionary no está instalado';
  }

  @override
  String spellingDictionaryNotInstalledWithSize(String size) {
    return 'No instalado · $size';
  }

  @override
  String get spellingDictionaryInstalled => 'Instalado';

  @override
  String get installSpellingDictionary => 'Instalar diccionario';

  @override
  String get removeSpellingDictionary => 'Eliminar diccionario';

  @override
  String get cancelSpellingDictionaryInstall =>
      'Cancelar descarga del diccionario';

  @override
  String get retrySpellingDictionaryInstall =>
      'Reintentar instalación del diccionario';

  @override
  String spellingDictionaryDownloading(String size) {
    return 'Descargando $size…';
  }

  @override
  String get spellingDictionaryValidating => 'Validando diccionario…';

  @override
  String get spellingDictionaryInstallFailed =>
      'La instalación falló; selecciónelo para reintentar';

  @override
  String spellingDictionaryInstallPrompt(String dictionary, String size) {
    return '¿Instalar $dictionary ($size)? Tras instalarlo, estará disponible sin conexión hasta que lo elimine.';
  }

  @override
  String get spellingDictionaryUnavailable => 'Diccionario no disponible';

  @override
  String get spellingChecking => 'Comprobando la ortografía…';

  @override
  String exportInvalidRange(String field, String minimum, String maximum) {
    return '$field: introduzca un número entre $minimum y $maximum.';
  }

  @override
  String get spellingDictionaryRecoveryConflict =>
      'El diccionario ortográfico se modificó externamente. Se conservó una copia de recuperación.';

  @override
  String get windowMinimize => 'Minimizar';

  @override
  String get windowMaximize => 'Maximizar';

  @override
  String get windowRestore => 'Restaurar';

  @override
  String get nextcloudNotes => 'Nextcloud Notes';

  @override
  String get nextcloudConnect => 'Conectar';

  @override
  String get nextcloudReconnect => 'Volver a conectar';

  @override
  String get nextcloudDisconnect => 'Desconectar';

  @override
  String get nextcloudServer => 'URL del servidor';

  @override
  String get nextcloudSignInBrowser =>
      'Complete el inicio de sesión en el navegador.';

  @override
  String get nextcloudFavorites => 'Favoritos';

  @override
  String get nextcloudNewNote => 'Nueva nota';

  @override
  String get nextcloudSavedLocally =>
      'Guardado localmente · sincronización pendiente';

  @override
  String get nextcloudSyncing => 'Sincronizando';

  @override
  String get nextcloudSynced => 'Sincronizado';

  @override
  String get nextcloudOffline => 'Sin conexión';

  @override
  String get nextcloudLocked => 'Bloqueado por el servidor';

  @override
  String get nextcloudReconnectRequired => 'Es necesario volver a conectar';

  @override
  String get nextcloudCreationUncertain => 'Resultado de creación incierto';

  @override
  String get nextcloudReadOnly => 'Solo lectura';

  @override
  String get nextcloudTakeRemote => 'Usar versión remota';

  @override
  String get nextcloudMerge => 'Combinar';

  @override
  String get nextcloudDeleteNote => '¿Eliminar nota?';

  @override
  String get nextcloudWorkspaceReplaceUnavailable =>
      'El reemplazo del espacio de trabajo no está disponible para Nextcloud Notes. Reemplace dentro de cada nota.';

  @override
  String get nextcloudSaveLocalCopy => 'Guardar copia local…';

  @override
  String get nextcloudDisconnectWarning =>
      'Eliminar esta cuenta borra sus notas en caché y cambios pendientes de este dispositivo. Sincronice primero para conservar el trabajo pendiente en el servidor.';

  @override
  String get nextcloudAttachmentRetryWarning =>
      'Si la carga anterior se completó, reintentar puede dejar un archivo adjunto sin usar en el servidor.';

  @override
  String get nextcloudAttachmentReference =>
      'Referencia del archivo adjunto en el servidor';

  @override
  String get nextcloudAddAttachment => 'Añadir archivo adjunto…';

  @override
  String get nextcloudDeleteAttachmentWarning =>
      'Al eliminar este archivo adjunto, sus enlaces en la nota dejarán de estar disponibles. Los datos conservados se pueden recuperar mediante el historial local.';

  @override
  String get nextcloudChooseConflictingAttributes =>
      'Elige cada atributo en conflicto.';

  @override
  String get nextcloudUseServerNote => 'Usar esta nota del servidor';

  @override
  String get nextcloudUseServerNoteExplanation =>
      'Vincula este borrador con la nota seleccionada del servidor y luego sincroniza los cambios locales conservados. Una solicitud coincidente no confirma quién creó la nota.';

  @override
  String get nextcloudExactCandidate =>
      'Coincidencia exacta con la solicitud; identidad sin confirmar.';

  @override
  String get nextcloudPossibleCandidate =>
      'Posible coincidencia con la solicitud saneada; identidad sin confirmar.';

  @override
  String get nextcloudSelectCandidate =>
      'Seleccionar una nota del servidor para revisarla';

  @override
  String get nextcloudCreateSeparate => 'Crear una nota aparte';

  @override
  String get nextcloudCreateSeparateWarning =>
      'La primera solicitud puede haber creado ya una nota en el servidor. Esto crea una nota aparte con su trabajo local conservado. No se eliminará ningún posible duplicado.';

  @override
  String get wsSemanticFormats => 'Formato semántico';

  @override
  String get wsUiControl => 'Control de interfaz';

  @override
  String get wsFilePath => 'Archivo / Ruta';

  @override
  String get wsUiPath => 'Ruta de interfaz';

  @override
  String get wsDefinitionList => 'Lista de definiciones';

  @override
  String get wsIncludeContent => 'Incluir contenido reutilizable';

  @override
  String get wsVariableReference => 'Referencia de variable';

  @override
  String get wsConvertList => 'Convertir lista en procedimiento';

  @override
  String get wsElementProperties => 'Propiedades del elemento';

  @override
  String get wsTopicProperties => 'Propiedades del tema';

  @override
  String get wsCollapsible => 'Contraíble';

  @override
  String get wsPublishedState => 'Estado inicial publicado';

  @override
  String get wsExpanded => 'Expandido';

  @override
  String get wsCollapsed => 'Contraído';

  @override
  String get wsCollapsedTitle => 'Título contraído';

  @override
  String get wsTerm => 'Término';

  @override
  String get wsListLayout => 'Diseño de la lista';

  @override
  String get wsSyncGroup => 'Grupo de sincronización';

  @override
  String get wsTabKey => 'Clave de pestaña';

  @override
  String get wsSwitcherLabel => 'Etiqueta del selector';

  @override
  String get wsNavigationElements => 'Elementos de navegación';

  @override
  String get wsNavigationDepth => 'Profundidad de navegación';

  @override
  String get wsAddItem => 'Añadir elemento';

  @override
  String get wsStep => 'Paso';

  @override
  String get wsPropertyInvalid => 'Valor de propiedad no válido';

  @override
  String get wsFilter => 'Filtro';

  @override
  String get wsIdentifier => 'ID del elemento';

  @override
  String get wsTldr => 'Resumen (TLDR)';

  @override
  String get wsFullLayout => 'Ancho completo';

  @override
  String get wsMediumLayout => 'Medio (1:2)';

  @override
  String get wsNarrowLayout => 'Término estrecho';

  @override
  String get wsTitle => 'Título';

  @override
  String get wsSwitcherKey => 'Clave del selector';

  @override
  String get nextcloudServerSettings => 'Ajustes de Notes del servidor';

  @override
  String get nextcloudNotesPath => 'Ruta de la carpeta de notas';

  @override
  String get nextcloudFileSuffix => 'Extensión de las notas nuevas';

  @override
  String get nextcloudServerSettingsExplanation =>
      'Estos ajustes de Notes afectan a otros clientes. Cambiar la ruta no mueve archivos; cambiar la extensión no renombra las notas existentes.';

  @override
  String get nextcloudSettingsSaved => 'Ajustes del servidor guardados';

  @override
  String get nextcloudSettingsNormalized =>
      'Guardado con valores normalizados por el servidor';

  @override
  String get nextcloudPendingUpload => 'Carga de adjunto pendiente';

  @override
  String nextcloudServerCheck(String time) {
    return 'Última comprobación del servidor: $time';
  }

  @override
  String get nextcloudSettingsLoading => 'Cargando ajustes del servidor';

  @override
  String get nextcloudSettingsSaving => 'Guardando ajustes del servidor';

  @override
  String get nextcloudPreviousLocalEdit => 'Edición local anterior';

  @override
  String get nextcloudUsePreviousEdit => 'Usar edición anterior';

  @override
  String get quickOpen => 'Apertura rápida';

  @override
  String get notesAll => 'Todas las notas';

  @override
  String get notesUncategorized => 'Sin categoría';

  @override
  String get notesRecovery => 'Recuperación';

  @override
  String get notesRecentlyEdited => 'Editadas recientemente';

  @override
  String get notesOldestEdited => 'Ediciones más antiguas';

  @override
  String get notesTitleAscending => 'Título A–Z';

  @override
  String get notesTitleDescending => 'Título Z–A';

  @override
  String get notesMove => 'Mover a categoría';

  @override
  String get notesRemoveFavorite => 'Quitar favorito';

  @override
  String get notesOffline => 'Hacer disponible sin conexión';

  @override
  String get notesOfflineRemove => 'Quitar conservación sin conexión';

  @override
  String get notesIndexing => 'Indexando notas…';

  @override
  String get notesSearchHelp =>
      'Los términos usan Y. Use \"frases entre comillas\", title: y category:.';

  @override
  String get notesSourceLocation => 'Ubicación en el código fuente';

  @override
  String get notesRecoveryHelp =>
      'Solo notas locales conservadas e historial local. La papelera y el historial del servidor no están disponibles.';

  @override
  String get notesImport => 'Importar notas';

  @override
  String get notesExport => 'Exportar notas';

  @override
  String get notesImportDistinct => 'Importar como una nota distinta';

  @override
  String get notesAvailableOffline => 'Disponible sin conexión';

  @override
  String get notesIncomplete => 'Incompleto';

  @override
  String get notesSelected => 'Notas seleccionadas';

  @override
  String get notesNoHistory =>
      'No hay revisiones conservadas. El historial puede estar desactivado, caducado o borrado.';

  @override
  String get notesTextAvailable => 'Texto disponible localmente';

  @override
  String get notesLocalVersion => 'Versión de trabajo local';

  @override
  String get notesAttachments => 'Adjuntos';

  @override
  String get notesSkipped => 'Omitido';

  @override
  String get notesFailed => 'Fallido';

  @override
  String get notesCompleted => 'Completado';

  @override
  String get notesImportNew => 'Iniciar una nueva importación';

  @override
  String get notesImportResume => 'Reanudar importación interrumpida';

  @override
  String get notesImportAlreadyImported => 'Ya importado en esta operación';

  @override
  String get references => 'Referencias';

  @override
  String get referenceIncoming => 'Entrantes';

  @override
  String get referenceOutgoing => 'Salientes';

  @override
  String get referenceChooseTarget => 'Elegir destino del enlace';

  @override
  String get referenceWholeDocument => 'Documento completo';

  @override
  String get referenceSourceLocation => 'Ubicación de origen';

  @override
  String get referenceTargetLocation => 'Ubicación de destino';

  @override
  String get referenceResolved => 'Resuelta';

  @override
  String get referenceMissing => 'No encontrada';

  @override
  String get referenceAmbiguous => 'Ambigua';

  @override
  String get referenceUnavailable => 'No disponible en este contexto';

  @override
  String get referenceUnsupported => 'No compatible';

  @override
  String get referenceNoPortableId =>
      'Este destino no tiene una URL portátil de nota verificada.';

  @override
  String get wsIncludeLines => 'Incluir líneas';

  @override
  String get wsIncludeSymbol => 'Incluir símbolo';

  @override
  String get wsEmphasizeLines => 'Resaltar líneas mostradas';

  @override
  String get wsPropertiesReadOnly =>
      'Propiedades de solo lectura en esta vista.';

  @override
  String get wsPropertiesProtected =>
      'Este elemento está protegido. Edite su fuente.';

  @override
  String get wsPropertiesConflict =>
      'El documento o elemento cambió. Revierta el borrador y seleccione de nuevo.';

  @override
  String get wsPropertiesUnresolved =>
      'No se puede resolver la referencia actualmente.';

  @override
  String get wsUseDefault => 'Usar valor predeterminado';

  @override
  String get wsPropertiesSelection => 'Seleccione un solo elemento.';

  @override
  String get wsImageDisplay => 'Visualización de imagen';

  @override
  String get wsImageThumbnail => 'Miniatura pulsable';

  @override
  String get wsEnabled => 'Activado';

  @override
  String get wsDisabled => 'Desactivado';

  @override
  String get wsWidth => 'Ancho';

  @override
  String get wsHeight => 'Alto';

  @override
  String get wsPropertiesInactive =>
      'Esta propiedad no tiene efecto sin contraer en la publicación.';

  @override
  String get wsNavigationAll => 'Todos los elementos con título';

  @override
  String get wsNavigationNone => 'Sin navegación';

  @override
  String get wsNavigationCustom => 'Navegación personalizada';

  @override
  String get wsTitleOverride => 'Sustituir título';

  @override
  String get wsCompactLayout => 'Compacto';

  @override
  String get wsWideLayout => 'Ancho';

  @override
  String get wsCodeSourceConflict =>
      'Mueve o elimina el código escrito en este bloque antes de establecer src. Writerside rechaza bloques de código no vacíos con una referencia de origen.';

  @override
  String get wsInherited => 'Heredar de la lista';

  @override
  String get wsExternalImageSize =>
      'Writerside no dimensiona con fiabilidad las imágenes externas. Puede revisar y quitar dimensiones existentes.';

  @override
  String get wsPropertiesNotSerialized =>
      'Este cambio no se aplicó al código fuente. Se ha conservado el borrador.';

  @override
  String get wsListItem => 'Elemento de lista';

  @override
  String get wsSourceFile => 'Archivo de origen';

  @override
  String get wsLinkTarget => 'Destino del enlace';

  @override
  String get wsPreviewImage => 'Imagen de vista previa';

  @override
  String get wsIncludedElement => 'Elemento incluido';

  @override
  String get wsHelpModule => 'Módulo de ayuda';

  @override
  String get wsActionId => 'ID de acción';

  @override
  String get wsKeymapHelpInstance => 'Instancia de ayuda del mapa de teclas';

  @override
  String get wsShowInSource => 'Mostrar en Fuente';

  @override
  String get wsOriginElement => 'Valor del elemento';

  @override
  String get wsOriginAncestor => 'Elemento padre';

  @override
  String get wsOriginModule => 'Predeterminado del módulo';

  @override
  String get wsOriginBuiltIn => 'Predeterminado integrado';

  @override
  String get wsOriginUnresolved => 'Sin resolver';

  @override
  String wsEffectiveProperty(String value, String origin) {
    return 'Efectivo: $value — $origin';
  }

  @override
  String get wsElementSelector => 'Elemento';

  @override
  String wsGeneratedAnchorValue(String anchor) {
    return 'Generado: $anchor';
  }

  @override
  String wsDefaultProperty(String value) {
    return 'Predeterminado: $value';
  }

  @override
  String wsDefaultPropertyOrigin(String value, String origin) {
    return 'Predeterminado: $value · $origin';
  }

  @override
  String wsResolvedProperty(String value) {
    return 'Resuelto: $value';
  }

  @override
  String get wsPropertyUnresolved => 'Sin resolver';

  @override
  String get wsModule => 'Módulo';

  @override
  String get wsParent => 'Elemento padre';

  @override
  String get wsListType => 'Tipo de lista';

  @override
  String get wsStartingNumber => 'Número inicial';

  @override
  String get wsListSorting => 'Ordenación';

  @override
  String get wsLetteredList => 'Lista alfabética';

  @override
  String get wsCheckboxList => 'Lista de casillas';

  @override
  String get wsMarkerlessList => 'Lista sin marcadores';

  @override
  String get wsAscending => 'Ascendente';

  @override
  String get wsDescending => 'Descendente';

  @override
  String get wsNoSorting => 'Sin ordenar';

  @override
  String get wsAsWritten => 'Como está escrito';

  @override
  String get wsSentenceCase => 'Mayúscula inicial';

  @override
  String get wsTitleCase => 'Mayúsculas de título';

  @override
  String get wsLowerCase => 'Minúsculas';

  @override
  String get wsUpperCase => 'Mayúsculas';

  @override
  String get wsNativeMarkers => 'Marcadores Markdown';

  @override
  String wsListMarkerStart(String number) {
    return 'Inicio del marcador: $number';
  }

  @override
  String wsListLevel(String level) {
    return 'Nivel $level';
  }

  @override
  String get wsModuleCapsIgnored =>
      'El compilador fijado ignora las reglas <caps> del módulo. Use un atributo caps local o default-property.';

  @override
  String get wsInsertElements => 'Insertar elementos';

  @override
  String get wsAdmonitionsAndQuotes => 'Avisos y citas';

  @override
  String get wsSemanticText => 'Texto semántico';

  @override
  String get wsPropertiesUnavailable =>
      'El elemento inspeccionado no está disponible. Inspeccione otro elemento para continuar.';

  @override
  String get searchDocumentsCategory => 'Documentos';

  @override
  String get searchTopicsCategory => 'Temas';

  @override
  String get searchCurrentDocument => 'Documento actual';

  @override
  String get searchCurrentWorkspace => 'Espacio de trabajo actual';

  @override
  String get browseNotes => 'Explorar notas';

  @override
  String get searchActionsCommand => 'Buscar acciones';

  @override
  String get searchDocumentsCommand => 'Buscar documentos';

  @override
  String get searchTopicsCommand => 'Buscar temas';

  @override
  String get searchRecentCommand => 'Buscar recientes';

  @override
  String get searchResourceUnavailable => 'Este recurso no está disponible.';

  @override
  String get notesSync => 'Sincronizar notas';

  @override
  String get searchInWorkspace => 'Buscar en espacio de trabajo';

  @override
  String get searchCategory => 'Categoría de búsqueda';

  @override
  String get clearHistorySearchScope => 'Buscar en el historial de documentos';

  @override
  String get searchInDocument => 'Buscar en el documento';

  @override
  String get searchDocumentHint => 'Buscar en este documento…';

  @override
  String get searchWorkspaceHint => 'Buscar en este espacio de trabajo…';

  @override
  String get searchOutlineHint => 'Buscar encabezados…';

  @override
  String get searchHistoryHint => 'Buscar en el historial local…';

  @override
  String get searchEnterText => 'Introduce texto para buscar';

  @override
  String get searchAccountUnavailable => 'Cuenta no disponible';

  @override
  String get searchDocumentsHint => 'Buscar documentos…';

  @override
  String get searchTopicsHint => 'Buscar temas…';

  @override
  String get searchRecentHint => 'Buscar recientes…';

  @override
  String get searchActionsHint => 'Buscar acciones…';

  @override
  String get searchRequiresNotesWorkspace =>
      'Requiere un espacio de trabajo de Notas';

  @override
  String get searchSidebarLabel => 'Buscar:';

  @override
  String get searchDocumentTextCategory => 'Texto del documento';

  @override
  String get searchWorkspaceTextCategory => 'Texto del espacio de trabajo';

  @override
  String get searchHeadingsCategory => 'Encabezados';

  @override
  String get shortcutUnassigned => 'Sin asignar';

  @override
  String get shortcutPressKeys => 'Pulse una combinación de teclas…';

  @override
  String get shortcutRecord => 'Capturar atajo';

  @override
  String get shortcutRestoreAll =>
      'Restaurar todos los valores predeterminados';

  @override
  String get shortcutRestoreAllQuestion =>
      '¿Restaurar los atajos predeterminados de todas las acciones? Se eliminarán las asignaciones personalizadas.';

  @override
  String get shortcutSaveFailed =>
      'Los atajos están activos, pero no se pudieron guardar. Reintente para conservarlos tras reiniciar.';

  @override
  String get shortcutRetry => 'Reintentar guardado';

  @override
  String get shortcutChanged =>
      'Las asignaciones cambiaron. Revise los atajos actuales y reintente.';

  @override
  String get shortcutInvalid =>
      'Esta combinación no se puede asignar en este contexto.';

  @override
  String get shortcutSystemWarning =>
      'El escritorio puede usar esta combinación. BusyMark no puede sustituir atajos del sistema.';

  @override
  String get shortcutConflicts =>
      'Este atajo entra en conflicto con estas acciones:';

  @override
  String get shortcutRemove => 'Quitar asignación';

  @override
  String get shortcutRestoreDefault => 'Restaurar valor predeterminado';

  @override
  String get shortcutAssign => 'Asignar';

  @override
  String get shortcutReassign => 'Reasignar';

  @override
  String get shortcutContextApplication => 'Aplicación';

  @override
  String get shortcutContextDocument => 'Vistas del documento';

  @override
  String get shortcutContextEditor => 'Editor y código fuente';

  @override
  String get shortcutContextWritersideSource => 'Código fuente de Writerside';

  @override
  String get shortcutContextWorkspace => 'Navegación del espacio de trabajo';

  @override
  String get shortcutContextTree => 'Árboles laterales';

  @override
  String get searchHeadingsCommand => 'Buscar encabezados';

  @override
  String get shortcutFixed => 'Lo gestiona el editor; no se puede configurar.';

  @override
  String get shortcutDefaultConflict =>
      'El atajo predeterminado entra en conflicto con una asignación personalizada.';

  @override
  String get shortcutCurrentBinding => 'Atajo actual';

  @override
  String get shortcutProposedBinding => 'Atajo propuesto';

  @override
  String get notesActions => 'Acciones de notas';

  @override
  String get noteActions => 'Acciones de la nota';

  @override
  String get noteProperties => 'Propiedades de la nota';

  @override
  String get notesExportAll => 'Exportar notas · Todas las notas…';

  @override
  String get notesExportCategory => 'Exportar notas · Categoría…';

  @override
  String get notesOfflineAll =>
      'Hacer disponible sin conexión · Todas las notas';

  @override
  String get notesOfflineCategory =>
      'Hacer disponible sin conexión · Categoría';

  @override
  String get notesOfflineRemoveAll =>
      'Quitar conservación sin conexión · Todas las notas';

  @override
  String get notesOfflineRemoveCategory =>
      'Quitar conservación sin conexión · Categoría';

  @override
  String get notesOfflinePause => 'Pausar descargas';

  @override
  String get notesOfflineResume => 'Reanudar descargas';

  @override
  String get notesOfflineKeep => 'Hacer disponible sin conexión';

  @override
  String get notesOfflineRetentionHelp =>
      'Quitar este requisito conserva el contenido en caché. Un requisito de categoría o cuenta puede seguir reteniendo la nota.';

  @override
  String get notesOfflineBroader =>
      'Esta nota también se conserva por un requisito de categoría o cuenta.';

  @override
  String get notesOfflineExternal =>
      'El contenido multimedia externo necesita conexión. BusyMark solo conserva el texto y los adjuntos gestionados.';

  @override
  String get notesEmptyAll => 'Aún no hay notas. Cree una para empezar.';

  @override
  String get notesEmptyFavorites => 'No hay notas favoritas.';

  @override
  String get notesEmptyCategory => 'No hay notas en esta categoría.';

  @override
  String get notesEmptyUncategorized => 'No hay notas sin categoría.';

  @override
  String get notesEmptyRecovery => 'No hay notas conservadas para recuperar.';

  @override
  String get notesLoadFailed => 'Nextcloud Notes · Fallido. Reintentar';

  @override
  String get notesOperationFailed =>
      'La operación no pudo terminar. El borrador se conserva. Revise el guardado y los conflictos antes de reintentarlo.';

  @override
  String get notesInspectionFailed => 'Adjuntos · Fallido. Reintentar';

  @override
  String get notesStartingConnection => 'Iniciando la conexión con Nextcloud…';

  @override
  String get notesVerifyingConnection => 'Verificando el acceso a Notas…';

  @override
  String get notesCancellingConnection =>
      'Cancelando el inicio de sesión y limpiando…';

  @override
  String get notesRemovingConnection => 'Eliminando la cuenta local…';

  @override
  String get notesRemovedWarning =>
      'Se eliminó la cuenta local de Nextcloud. No se confirmó la revocación de la contraseña de aplicación. Elimine la contraseña de BusyMark en los ajustes de seguridad de Nextcloud.';

  @override
  String get notesBuffersNotSaved =>
      'No se pudieron guardar todas las notas abiertas localmente. Revise el guardado, los conflictos o la normalización en el espacio de trabajo. Los cambios pendientes aún pueden necesitar sincronización con Nextcloud.';

  @override
  String get notesSettingsLeave =>
      '¿Guardar los cambios de ajustes de Nextcloud antes de salir?';

  @override
  String get notesSettingsLeaveHelp =>
      'Ajustes de Notes del servidor · Cambios sin guardar';

  @override
  String get notesSettingsReload => 'Volver a cargar los ajustes del servidor…';

  @override
  String get notesSettingsReloadHelp =>
      'La recarga sustituye el borrador por los ajustes actuales de Nextcloud. ¿Descartar el borrador y recargar?';

  @override
  String get notesSettingsRefreshFailed =>
      'Nextcloud aceptó los ajustes, pero falló la actualización de las notas. Se muestran los valores confirmados por el servidor. Reintente actualizar desde Notas.';

  @override
  String get notesUnavailable =>
      'Sin conexión · Texto disponible localmente · Guardado localmente · sincronización pendiente';

  @override
  String get notesStorageFull =>
      'El almacenamiento de Nextcloud está lleno. Libere espacio en el servidor y reinténtelo.';

  @override
  String get notesRejected =>
      'Nextcloud rechazó este cambio. Revise la nota y guarde una copia local antes de reintentarlo.';

  @override
  String get notesThrottled =>
      'Nextcloud ha pedido esperar. La sincronización continuará al finalizar el plazo de espera.';

  @override
  String get notesRecoveryRequired => 'Conflictos · Comparar';

  @override
  String get notesScanning => 'Examinando archivos…';

  @override
  String get notesCancelling =>
      'Cancelando… Esperando a que termine la operación actual.';

  @override
  String get notesCancelled => 'Cancelado';

  @override
  String get notesPartial => 'Completado parcialmente';

  @override
  String get notesTransferFailed => 'Fallido. Reintentar';

  @override
  String get notesImportPartialHelp =>
      'Los elementos anteriores pueden estar guardados localmente. Reanude esta importación para continuar sin duplicarlos.';

  @override
  String get notesNotStarted => 'Sin iniciar';

  @override
  String get notesCreated => 'Creado';

  @override
  String get notesRemoteDeleteUnavailable =>
      'URL del servidor · No compatible · Eliminar · Adjuntos';

  @override
  String get notesCurrentText => 'Texto conservado actual';

  @override
  String get notesRecovering => 'Recuperando como nota nueva…';

  @override
  String get notesReadOnlyHelp =>
      'Solo lectura · Favoritos · Guardar copia local…';

  @override
  String get notesSort => 'Ordenar notas';

  @override
  String get notesPathRelative =>
      'La ruta de la carpeta de notas es relativa a su almacenamiento Nextcloud.';

  @override
  String get notesSettingsStale =>
      'Los ajustes cambiaron en Nextcloud. Recargue y revise los valores del servidor antes de sustituir el borrador.';

  @override
  String get notesDownloadsPaused => 'Descargas pausadas';

  @override
  String get notesExportNotPublished => 'No se publicó ninguna exportación.';

  @override
  String get notesKeyringUnavailable =>
      'Desbloquee el llavero del escritorio y reinténtelo.';

  @override
  String get notesConnectFailed =>
      'No se pudo conectar con Nextcloud Notes. Compruebe la dirección del servidor y reinténtelo.';

  @override
  String get notesAccountMismatch =>
      'Inicie sesión con la misma cuenta Nextcloud. Elimínela primero para conectar otra.';

  @override
  String get notesLocalRemovalFailed =>
      'Falló la limpieza local. La cuenta se conserva para poder reintentar su eliminación.';

  @override
  String get notesTransferring => 'Transfiriendo notas…';

  @override
  String get notesTechnicalDetails => 'Detalles técnicos';

  @override
  String get notesPauseRequirement => 'Pausar requisito sin conexión';

  @override
  String get notesResumeRequirement => 'Reanudar requisito sin conexión';

  @override
  String get gitReturnToDocument => 'Volver al documento';

  @override
  String gitSnapshotLabel(String revision, String path) {
    return 'Instantánea de solo lectura · $revision · $path';
  }

  @override
  String get gitNonUtf8FilenameMessage =>
      'El nombre del archivo contiene bytes que no son UTF-8. La revisión y la preparación de Git siguen disponibles; el editor requiere un nombre de archivo UTF-8.';

  @override
  String get gitUiMergeInProgress => 'Fusión en curso';

  @override
  String get gitUiRebaseInProgress => 'Reajustar la base en curso';

  @override
  String get gitUiCherryPickInProgress => 'Piquetes de cereza en curso';

  @override
  String get gitUiRevertInProgress => 'Revertir en curso';

  @override
  String get gitUiPatchApplicationInProgress =>
      'Aplicación de parches en curso';

  @override
  String get gitUiSquashMergeResultAwaitingCommit =>
      'Resultado de fusión Squash a la espera de confirmación';

  @override
  String get gitUiUnresolvedIndexConflicts =>
      'Conflictos de índices no resueltos';

  @override
  String get gitUiUnresolvedConflicts => ' · Conflictos no resueltos';

  @override
  String get gitUiReviewOperation => 'Operación de revisión';

  @override
  String get gitUiRefresh => 'Actualizar';

  @override
  String get gitUiCreateNamedStash => 'Crear un alijo con nombre';

  @override
  String get gitUiCreateStash => 'Crear reserva…';

  @override
  String get gitUiNoStashes => 'No hay escondites';

  @override
  String get gitUiSelectAStashToInspectItsChanges =>
      'Seleccione un alijo para inspeccionar sus cambios';

  @override
  String get gitUiStashedUntrackedFiles => 'Archivos sin rastrear';

  @override
  String get gitUiInspectStashedUntrackedFiles =>
      'Inspeccione archivos ocultos sin rastrear...';

  @override
  String get gitUiReinstateTheStashSStagedIndexStateWhenApplying =>
      'Reinserta el estado escenificado/indexado del alijo al aplicar';

  @override
  String get gitUiApplyAndRetain => 'Aplicar y retener';

  @override
  String get gitUiPop => 'Papá...';

  @override
  String get gitUiCreateBranch => 'Crear rama…';

  @override
  String get gitUiDropStash => 'Eliminar reserva…';

  @override
  String get gitUiBranchFromStash => 'Crear rama desde reserva';

  @override
  String get gitUiCreateSwitchToABranchAtTheStashSOriginal =>
      'Crear/cambiar a una rama en la base original del alijo, a continuación, aplicarlo. El alijo original se conserva para su eliminación posterior explícita.';

  @override
  String gitUiArg0ThisStash(String arg0) {
    return '¿$arg0 este alijo?';
  }

  @override
  String get gitUiTheOriginalStashIsRetainedIfApplyingConflicts =>
      'El alijo original se conserva si se aplican conflictos.';

  @override
  String get gitUiDeletesThisStashEntryItsChangesAreNotApplied =>
      'Elimina esta entrada de alijo. Sus cambios no se aplican.';

  @override
  String get gitUiResolveTheUnmergedFilesGitHasNoStashContinueOr =>
      'Resuelva los archivos sin fusionar. Git no tiene órdenes de continuar ni abortar una reserva; la reserva original se conserva.';

  @override
  String get gitUiStashNameMessage => 'Nombre/mensaje de reserva';

  @override
  String get gitUiStashContentAndResultingIndex =>
      'Stash contenido e índice resultante';

  @override
  String get gitUiStashTrackedWorkingAndStagedChanges =>
      'Stash tracked cambios de trabajo y escenificados';

  @override
  String get gitUiStashChangesLeaveStagedChangesInPlaceKeepIndex =>
      'Reservar cambios y mantener lo preparado en su sitio (--keep-index)';

  @override
  String get gitUiStashOnlyStagedChangesStaged =>
      'Reservar solo los cambios preparados (--staged)';

  @override
  String get gitUiIncludeUntrackedFiles => 'Incluir archivos no rastreados';

  @override
  String get gitUiAllEligiblePathsInThisRepository =>
      'Todas las rutas elegibles en este repositorio';

  @override
  String get gitUiNoEligibleChangesForTheseStashOptions =>
      'No hay cambios elegibles para estas opciones de alijo.';

  @override
  String get gitUiSelectAtLeastOneEligiblePath =>
      'Seleccione al menos una ruta elegible.';

  @override
  String get gitUiCreateStash2 => 'Crear reserva';

  @override
  String get gitUiCreateWorktree => 'Crear árbol de trabajo...';

  @override
  String get gitUiCreateACommitBeforeCreatingAWorktreeAtHEAD =>
      'Crea un commit antes de crear un árbol de trabajo en HEAD.';

  @override
  String get gitUiDetachedHEAD => 'HEAD separado';

  @override
  String get gitUiCurrent => 'Corriente ·';

  @override
  String get gitUiLocked => 'Bloqueado ·';

  @override
  String get gitUiOpenInBusyStack => 'Abierto en BussyStack ·';

  @override
  String get gitUiStatusNotInspected => 'Estado no inspeccionado';

  @override
  String get gitUiDirty => 'Sucio';

  @override
  String get gitUiClean => 'Limpio';

  @override
  String get gitUiOpenWorkingFolder => 'Abrir carpeta de trabajo';

  @override
  String get gitUiMoveWorktree => 'Mueve el árbol de trabajo...';

  @override
  String get gitUiUnlock => 'Desbloquear';

  @override
  String get gitUiLock => 'Bloquear';

  @override
  String get gitUiRemoveCleanWorktree => 'Quitar el árbol de trabajo limpio...';

  @override
  String get gitUiReviewRemovalIncludingLocalChanges =>
      'Revisar la eliminación incluyendo cambios locales...';

  @override
  String get gitUiNewWorktreeFolderName =>
      'Nuevo nombre de carpeta de worktree';

  @override
  String get gitUiNewWorktreeBranch => 'Nueva rama de árbol de trabajo';

  @override
  String gitUiCreateArg0Arg1WithANewLocalBranchAtArg2(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return 'Crear $arg0/$arg1 con una nueva sucursal local en $arg2 ($arg3).';
  }

  @override
  String get gitUiDestinationFolderName => 'Nombre de la carpeta de destino';

  @override
  String get gitUiRemoveWorktree => '¿Quitar árbol de trabajo?';

  @override
  String
  get gitUiExplicitlyDiscardAllLocalTrackedUntrackedChangesInThisWorktree =>
      'Descarte explícitamente todos los cambios locales de seguimiento/sin seguimiento en este árbol de trabajo. Los árboles de trabajo bloqueados/en uso permanecen protegidos.';

  @override
  String get gitUiGitRefusesRemovalIfThereAreLocalChangesUntrackedFiles =>
      'Git rechaza la eliminación si hay cambios locales, archivos no rastreados o un bloqueo.';

  @override
  String get gitUiDiscardLocalWorktreeContentsAndRemove =>
      'Desechar el contenido local de árbol de trabajo y eliminar';

  @override
  String get gitUiRemoveCleanWorktree2 => 'Eliminar árbol de trabajo limpio';

  @override
  String
  get gitUiExplicitlyRecurseIntoNestedSubmodulesForUpdatesSynchronization =>
      'Recurrir explícitamente a submódulos anidados para actualizaciones/sincronización';

  @override
  String get gitUiNoRecordedSubmodules => 'No hay submódulos registrados';

  @override
  String get gitUiNotInitialized => 'no inicializado';

  @override
  String gitUiParentGitlinkArg0CheckedOutArg1(String arg0, String arg1) {
    return 'gitlink padre: $arg0 Comprobado: $arg1\n';
  }

  @override
  String get gitUiDirtyNestedRepository => 'Repositorio sucio anidado';

  @override
  String get gitUiCleanNestedRepository => 'Repositorio anidado limpio';

  @override
  String get gitUiNestedStatusUnavailable =>
      'Estado de anidación no disponible';

  @override
  String get gitUiEnterNestedRepository => 'Introduzca el repositorio anidado';

  @override
  String get gitUiInitializeConfiguration => 'Inicializar configuración';

  @override
  String get gitUiUpdateToParentSRecordedCommit =>
      'Actualizar la confirmación registrada de los padres...';

  @override
  String get gitUiFollowConfiguredRemoteBranch =>
      'Siga la rama remota configurada...';

  @override
  String get gitUiSynchronizeConfiguredURLs =>
      'Sincronizar URLs configuradas...';

  @override
  String get gitUiStageCurrentSubmodulePointerInParent =>
      'Sugerencia de submódulo actual de etapa en el padre';

  @override
  String get gitUiParentAndSubmoduleCommitsPushesAndDirtyStateRemainSeparate =>
      'Padre y submódulo confirma, empuja, y el estado sucio permanecen separados. La navegación no inicializa o actualiza.';

  @override
  String gitUiFetchAndCheckOutTheConfiguredRemoteBranchSCommit(String arg0) {
    return 'Obtener y comprobar la confirmación de la rama remota configurada. Esto difiere del gitlink registrado por el padre. Recursivo: $arg0.';
  }

  @override
  String gitUiInitializeAsNeededAndCheckOutExactlyArg0RecursiveArg1(
    String arg0,
    String arg1,
  ) {
    return 'Inicializar según sea necesario y comprobar exactamente $arg0. Recursivo: $arg1.';
  }

  @override
  String gitUiApplyTheReviewedSubmoduleConfigurationOperationRecursiveArg0(
    String arg0,
  ) {
    return 'Aplicar la operación de configuración de submódulos revisada. Recursivo: $arg0.';
  }

  @override
  String get gitUiApplySubmoduleOperation => 'Aplicar operación de submódulos';

  @override
  String get gitUiInspectARecordedRevisionOrCreateARecoveryBranchReflog =>
      'Inspeccione una revisión registrada o cree una rama de recuperación. Reflog no recupera contenido arbitrario no guardado o no rastreado.';

  @override
  String get gitUiSelectAReflogEntry => 'Seleccione una entrada de reflog';

  @override
  String get gitUiPreviousPage => 'Página anterior';

  @override
  String get gitUiNextPage => 'Siguiente página';

  @override
  String get gitUiRecoveryBranchName => 'Nombre de la sucursal de recuperación';

  @override
  String gitUiCreatesABranchAtArg0WorkingFilesAndTheCurrent(String arg0) {
    return 'Crea una rama en $arg0; los archivos de trabajo y la rama actual no cambian.';
  }

  @override
  String get gitUiCreateRecoveryBranch => 'Crear rama de recuperación...';

  @override
  String get gitUiReadOnlyRecoverySnapshot =>
      'Instantánea de recuperación de solo lectura';

  @override
  String get gitUiInspectSnapshot => 'Inspeccione la instantánea...';

  @override
  String get gitUiReviewReset => 'Revisar el restablecimiento…';

  @override
  String gitUiPageArg0(String arg0) {
    return 'Página $arg0';
  }

  @override
  String get gitUiAGitTextHistoryMustOwnItsEditableField =>
      'Un historial de texto Git debe poseer su campo editable.';

  @override
  String get gitUiEditHEADIndexWorkingTree =>
      'Editar HEAD | Índice | Árbol de trabajo…';

  @override
  String
  get gitUiTheReviewedIndexOrWorkingContentChangedRefreshThisComparison =>
      'El índice revisado o el contenido de trabajo cambiado. Refrescar esta comparación antes de la puesta en escena.';

  @override
  String get gitUiRefreshComparison => 'Comparación de actualización';

  @override
  String get gitUiPreviousChangedFile => 'Archivo anterior cambiado';

  @override
  String get gitUiNextChangedFile => 'Siguiente archivo cambiado';

  @override
  String get gitUiPreviousDifference => 'Diferencia anterior';

  @override
  String get gitUiNextDifference => 'Siguiente diferencia';

  @override
  String get gitUiComparisonMode => 'Modo de comparación';

  @override
  String get gitUiSideBySide => 'Lado a lado';

  @override
  String get gitUiUnified => 'Unificado';

  @override
  String get gitUiDiffDisplayOptions => 'Opciones de visualización de diff';

  @override
  String get gitUiWrap => 'Ajuste';

  @override
  String get gitUiWords => 'Palabras';

  @override
  String get gitUiCollapseContext => 'Contraer contexto';

  @override
  String get gitUiIgnoreWhitespace => 'Ignorar el espacio en blanco';

  @override
  String get gitUiSearchComparison => 'Comparación de búsquedas';

  @override
  String get gitUiSearch => 'Buscar';

  @override
  String get gitUiCloseSearch => 'Cerrar búsqueda';

  @override
  String get gitUiStagingActions => 'Acciones de preparación';

  @override
  String get gitUiStagingActions2 => 'Acciones de preparación…';

  @override
  String get gitUiUnstageSelectedChangedLines =>
      'Quitar líneas modificadas seleccionadas de preparación';

  @override
  String get gitUiStageSelectedChangedLines =>
      'Preparar líneas modificadas seleccionadas';

  @override
  String get gitUiUnstageWholeFile => 'Quitar archivo completo de preparación';

  @override
  String get gitUiStageWholeFile => 'Preparar archivo completo';

  @override
  String gitUiArg0WhitespaceOnlyChangedLinesHiddenShowExactChanges(
    String arg0,
  ) {
    return '$arg0 líneas cambiadas sólo en espacio blanco ocultas · Mostrar cambios exactos';
  }

  @override
  String gitUiArg0ChangedLinesSelectedDisplaySettingsNeverAlterTheStaged(
    String arg0,
  ) {
    return '$arg0 cambió las líneas seleccionadas · La configuración de visualización nunca altera los bytes escenificados.';
  }

  @override
  String get gitUiReadOnlyComparisonCopyTextOrAdjustDisplaySettings =>
      'Comparación de solo lectura · Copie texto o ajuste la visualización.';

  @override
  String get gitUiNoFinalNewline => ' · no hay una nueva línea final';

  @override
  String gitUiArg0Arg1Arg2BytesArg3(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return '$arg0 · $arg1 · $arg2 bytes$arg3';
  }

  @override
  String get gitUiTextComparisonIsUnavailableForTheseContents =>
      'La comparación de texto no está disponible para estos contenidos.';

  @override
  String get gitUiThisComparisonExceedsTheBoundedTextReviewLimitTheContents =>
      'Esta comparación supera el límite de revisión de texto limitado. El contenido no ha sido declarado idéntico.';

  @override
  String get gitUiTheComparedContentsAreIdentical =>
      'Los contenidos comparados son idénticos.';

  @override
  String get gitUiUnstage => 'Desescalonamiento';

  @override
  String get gitUiStage => 'Etapa';

  @override
  String gitUiArg0ChangedLine(String arg0) {
    return '$arg0 cambió de línea';
  }

  @override
  String get gitUiContext => 'Contexto';

  @override
  String get gitUiExpandUnchangedContext => 'Expandir el contexto sin cambios';

  @override
  String get gitUiUnstageThisHunk => 'Quitar este bloque de preparación';

  @override
  String get gitUiStageThisHunk => 'Preparar este bloque';

  @override
  String gitUiEditStagedContentArg0(String arg0) {
    return 'Editar contenido escenificado · $arg0';
  }

  @override
  String get gitUiWritingReviewedIndexResult =>
      'Resultado del índice revisado de redacción';

  @override
  String get gitUiHead => 'HEAD';

  @override
  String get gitUiIndex => 'Índice';

  @override
  String get gitUiWorkingTree => 'Árbol de trabajo';

  @override
  String gitUiHeadArg0(String arg0) {
    return 'HEAD · $arg0';
  }

  @override
  String get gitUiIndexEditableUTF8Blob => 'Índice · blob UTF-8 editable';

  @override
  String get gitUiUndo => 'Deshacer';

  @override
  String get gitUiRedo => 'Rehacer';

  @override
  String get gitUiReloadIndexReview => '¿Recargar la revisión del índice?';

  @override
  String get gitUiReloadTheCurrentHEADIndexAndWorkingVersionsThisReplaces =>
      'Vuelve a cargar HEAD, el índice y las versiones de trabajo actuales. Se sustituirá el borrador sin guardar del editor del índice.';

  @override
  String get gitUiReplaceDraftAndReload => 'Reemplazar borrador y recargar';

  @override
  String get gitUiReloadVersions => 'Recargar versiones...';

  @override
  String get gitUiWriteEditedResultToThisIndexEntry =>
      'Escribir el resultado editado a esta entrada de índice';

  @override
  String get gitUiWorkingFilesRemainOnDiskReviewTheEditedIndexBefore =>
      'Los archivos de trabajo permanecen en el disco. Revise el índice editado antes de aplicar.';

  @override
  String get gitUiReviewIndexTextFormatChanges =>
      'Cambios en el formato del texto del índice de revisión';

  @override
  String gitUiUpdateOnlyTheReviewedIndexEntryForArg0Arg1(
    String arg0,
    String arg1,
  ) {
    return 'Actualizar sólo la entrada de índice revisada para $arg0. $arg1';
  }

  @override
  String get gitUiWriteReviewedIndexResult =>
      'Escribir el resultado del índice revisado';

  @override
  String get gitUiTheEditedResultChangedDuringFormatReviewReviewItAgain =>
      'El resultado editado cambió durante la revisión de formato. Revise de nuevo.';

  @override
  String get gitUiSynchronizeScrolling => 'Sincronizar desplazamiento';

  @override
  String get gitUiReadOnlyRevisionContent =>
      'Contenido de revisión de solo lectura';

  @override
  String get gitUiEditableIndexContent => 'Contenido del índice editable';

  @override
  String get gitUiTheRequestedRevisionIsOutsideTheCurrentFiltersResetFilters =>
      'La revisión solicitada está fuera de los filtros actuales. Reiniciar los filtros para revelarlo.';

  @override
  String get gitUiFilterLog => 'Registro de filtros';

  @override
  String get gitUiFilters => 'Filtros...';

  @override
  String gitUiFiltersCount(String count) {
    return 'Filtros ($count)...';
  }

  @override
  String get gitUiMessage => 'Mensaje…';

  @override
  String get gitUiAuthor => 'Autor…';

  @override
  String get gitUiPath => 'Camino...';

  @override
  String get gitUiDate => 'Fecha...';

  @override
  String get gitUiMessageFilter => 'Filtro de mensajes';

  @override
  String get gitUiAuthorFilter => 'Filtro de autor';

  @override
  String get gitUiPathFilter => 'Filtro de ruta';

  @override
  String get gitUiMessage2 => 'Mensaje';

  @override
  String get gitUiAuthor2 => 'Autor';

  @override
  String get gitUiPath2 => 'Ruta';

  @override
  String get gitUiDateFilter => 'Filtro de fecha...';

  @override
  String get gitUiResetFilters => 'Reiniciar filtros';

  @override
  String get gitUiRefreshLog => 'Actualizar registro';

  @override
  String get gitUiGoToCommitReference => 'Ir a commit/reference...';

  @override
  String get gitUiBackToHEAD => 'Volver a HEAD';

  @override
  String get gitUiOrderedCherryPick => 'Cherry-pick en el orden indicado';

  @override
  String gitUiReviewCherryPickArg0(String arg0) {
    return 'Revisar cherry-pick ($arg0)...';
  }

  @override
  String get gitUiCompareTwoSelectedRevisions =>
      'Comparar dos revisiones seleccionadas...';

  @override
  String get gitUiToggleBranchesPane => 'Conmutar el panel de ramas';

  @override
  String get gitUiFilterBranchesAndTags => 'Filtrar ramas y etiquetas';

  @override
  String gitUiCommitArg0(String arg0) {
    return 'Comprometer $arg0';
  }

  @override
  String get gitUiCommitDetails => 'Entregar detalles...';

  @override
  String gitUiReferenceArg0(String arg0) {
    return 'Referencia: $arg0';
  }

  @override
  String get gitUiSelectThisCommit => 'Seleccionar este commit';

  @override
  String get gitUiBranchOrTag => 'Rama o etiqueta';

  @override
  String get gitUiAllReferences => 'Todas las referencias';

  @override
  String get gitUiLocal => 'Locales';

  @override
  String get gitUiRemote => 'Remoto';

  @override
  String get gitUiTags => 'Etiquetas';

  @override
  String get gitUiNoCommitsMatchTheCurrentFilters =>
      'No hay confirmaciones que coincidan con los filtros actuales.';

  @override
  String get gitUiObjectID => 'ID del objeto';

  @override
  String get gitUiSubjectReferences => 'Asunto/referencias';

  @override
  String get gitUiDate2 => 'Fecha';

  @override
  String get gitUiGitCommits => 'Commits de Git';

  @override
  String get gitUiParents => 'Commits padre';

  @override
  String gitUiArg0Parents(String arg0) {
    return 'Padres $arg0';
  }

  @override
  String get gitUiLoadMoreCommits => 'Cargar más commits';

  @override
  String get gitUiLoadingChangedFiles => 'Cargando archivos cambiados';

  @override
  String get gitUiNoChangedFiles => 'No se han cambiado los archivos';

  @override
  String get gitUiSelectACommit => 'Seleccione una confirmación';

  @override
  String gitUiCompareParentArg0Arg1(String arg0, String arg1) {
    return 'Comparar $arg0 padre: $arg1';
  }

  @override
  String get gitUiChangedFiles => 'Archivos modificados';

  @override
  String gitUiAuthorArg0Arg1Arg2(String arg0, String arg1, String arg2) {
    return 'Autor: $arg0 <$arg1> $arg2';
  }

  @override
  String gitUiCommitterArg0Arg1Arg2(String arg0, String arg1, String arg2) {
    return 'Committer: $arg0 <$arg1> $arg2';
  }

  @override
  String get gitUiShallowPartialBoundaryAParentObjectIsUnavailable =>
      'Límites muy gruesos/parciales: un objeto padre no está disponible.';

  @override
  String get gitUiParentIsOutsideThisPageOrAShallowBoundary =>
      'Padre está fuera de esta página o un límite superficial.';

  @override
  String gitUiParentArg0(String arg0) {
    return 'Commit padre $arg0';
  }

  @override
  String get gitUiCommitActions => 'Comete acciones...';

  @override
  String get gitUiEmptyTree => 'árbol vacío';

  @override
  String get gitUiCreateBranch2 => 'Crear rama';

  @override
  String get gitUiCreateTag => 'Crear etiqueta';

  @override
  String get gitUiCompareRevisions => 'Comparar revisiones';

  @override
  String get gitUiOpenSnapshot => 'Abrir instantánea';

  @override
  String get gitUiRevertCommit => 'Revertir la confirmación';

  @override
  String get gitUiInteractiveRebaseAfterThisBoundary =>
      'Rebase interactiva después de este límite';

  @override
  String get gitUiResetCurrentBranch => 'Restablecer rama actual';

  @override
  String get gitUiCopyFullObjectID => 'Copiar el ID completo del objeto';

  @override
  String get gitUiGoToCommitReference2 => 'Ir a commit/reference';

  @override
  String get gitUiEnterACommitIDOrReferenceToRevealInLog =>
      'Introduzca un ID de confirmación o referencia para revelar en Registro.';

  @override
  String get gitUiTheRequestedRevisionIsUnavailable =>
      'La revisión solicitada no está disponible.';

  @override
  String
  get gitUiRepositoryMetadataIsReadOnlyBranchInspectionAndComparisonRemain =>
      'Los metadatos del repositorio son de sólo lectura. La inspección de la rama y la comparación siguen disponibles.';

  @override
  String get gitUiWorkingFilesAreUnavailableOrReadOnlyBranchSwitchingAnd =>
      'Los archivos de trabajo no están disponibles o sólo de lectura. No se puede cambiar de rama ni fusionar.';

  @override
  String get gitUiSearchBranchesAndTags => 'Buscar ramas y etiquetas';

  @override
  String get gitUiNewBranch => 'Nueva rama…';

  @override
  String get gitUiLocalBranches => 'Ramas locales';

  @override
  String get gitUiRemoteBranches => 'Ramas remotas';

  @override
  String gitUiTracksArg0(String arg0) {
    return 'Pistas $arg0';
  }

  @override
  String gitUiCheckedOutAtArg0(String arg0) {
    return 'Comprobado en $arg0';
  }

  @override
  String get gitUiRefreshingBranchMetadata => 'Actualizar metadatos de la rama';

  @override
  String gitUiSwitchToArg0(String arg0) {
    return 'Cambiar a $arg0';
  }

  @override
  String get gitUiOpenOccupiedWorktree => 'Árbol de trabajo abierto ocupado';

  @override
  String get gitUiCreateLocalTrackingBranch =>
      'Crear sucursal local de seguimiento...';

  @override
  String get gitUiCompareToCurrentHEAD => 'Comparar con HEAD actual';

  @override
  String get gitUiMergeIntoCurrentBranch => 'Fusionar en la rama actual...';

  @override
  String get gitUiRename => 'Renombrar...';

  @override
  String get gitUiChangeUpstream => 'Cambiar aguas arriba...';

  @override
  String get gitUiDelete => 'Borrar...';

  @override
  String get gitUiDeleteFromRemote => 'Eliminar del control remoto...';

  @override
  String gitUiActionsForArg0(String arg0) {
    return 'Acciones para $arg0';
  }

  @override
  String get gitUiLocalBranchName => 'Nombre de la sucursal local';

  @override
  String gitUiCreateAtArg0TheNewBranchWillBeCheckedOut(String arg0) {
    return 'Crear en $arg0. La nueva rama se comprobará.';
  }

  @override
  String gitUiTheLocalBranchWillTrackArg0AndBeCheckedOut(String arg0) {
    return 'La sucursal local rastreará $arg0 y será revisada.';
  }

  @override
  String get gitUiChooseRemoteForDeletion =>
      'Elija el control remoto para eliminar';

  @override
  String get gitUiDeleteRemoteReference => 'Eliminar la referencia remota';

  @override
  String gitUiMergeArg0IntoArg1(String arg0, String arg1) {
    return 'Fusionar $arg0 en $arg1';
  }

  @override
  String gitUiRenameArg0(String arg0) {
    return 'Renombrar $arg0';
  }

  @override
  String gitUiUpstreamForArg0(String arg0) {
    return 'Corriente hacia arriba para $arg0';
  }

  @override
  String get gitUiNoUpstream => 'Sin upstream';

  @override
  String gitUiDeleteArg0(String arg0) {
    return '¿Borrar $arg0?';
  }

  @override
  String gitUiArg0TargetArg1LocalDeletionOnlyAnUnmergedBranchIs(
    String arg0,
    String arg1,
  ) {
    return '$arg0 Target $arg1 Eliminación local solamente. Se rechaza una rama no fusionada.';
  }

  @override
  String get gitUiDelete2 => 'Eliminar';

  @override
  String gitUiDeleteUnmergedBranchArg0(String arg0) {
    return '¿Borrar la rama $arg0 sin fusionar?';
  }

  @override
  String gitUiArg0GitReportsThisBranchIsNotFullyMergedExplicitly(String arg0) {
    return '$arg0 Git informa que esta rama no está completamente fusionada. Borre explícitamente la referencia local después de revisar sus commits; las copias remotas no cambian.';
  }

  @override
  String get gitUiDeleteUnmergedLocalBranch =>
      'Eliminar sucursal local sin fusionar';

  @override
  String gitUiDestinationArg0Arg1(String arg0, String arg1) {
    return 'Destino: $arg0 · $arg1';
  }

  @override
  String get gitUiSourceBranchOrTag => 'Filial o etiqueta de origen';

  @override
  String get gitUiMergePolicy => 'Política de fusión';

  @override
  String get gitUiFastForwardWhenPossible => 'Avance rápido cuando sea posible';

  @override
  String get gitUiAlwaysCreateAMergeCommit =>
      'Crear siempre un commit de fusión';

  @override
  String get gitUiFastForwardOnly => 'Sólo hacia adelante';

  @override
  String get gitUiSquashIntoStagedChanges =>
      'Recorte en los cambios escalonados';

  @override
  String get gitUiStopBeforeCreatingTheMergeCommit =>
      'Detener antes de crear la confirmación de fusión';

  @override
  String get gitUiFastForwardIsDisabledSoHEADCannotMoveBeforeReview =>
      'El avance rápido está desactivado para que HEAD no se mueva antes de la revisión.';

  @override
  String get gitUiLeavesStagedChangesForASeparateCommitThisIsNot =>
      'Deja cambios escalonados para una confirmación separada; esta no es una fusión continua.';

  @override
  String get gitUiConflictsRemainAvailableInTheSharedResolutionWorkspace =>
      'Los conflictos siguen estando disponibles en el espacio de trabajo de resolución compartida.';

  @override
  String get gitUiAddRemote => 'Añadir control remoto...';

  @override
  String gitUiFetchArg0PushArg1(String arg0, String arg1) {
    return 'Obtener: $arg0 Push: $arg1';
  }

  @override
  String get gitUiRemoveRemote => 'Eliminar el control remoto...';

  @override
  String get gitUiChangeFetchURL => 'Cambiar URL de búsqueda...';

  @override
  String get gitUiAddPushDestination => 'Añadir destino push...';

  @override
  String get gitUiRemovePushDestination => 'Quitar destino push...';

  @override
  String gitUiManageArg0(String arg0) {
    return 'Administrar $arg0';
  }

  @override
  String get gitUiRemoteName => 'Nombre remoto';

  @override
  String get gitUiNewRemoteName => 'Nuevo nombre remoto';

  @override
  String get gitUiRepositoryURLOrLocalSource =>
      'URL del repositorio o fuente local';

  @override
  String get gitUiEnterTheExactReviewedDestinationToRemove =>
      'Introduzca el destino exacto revisado para eliminar.';

  @override
  String get gitUiCredentialsAreSuppliedByConfiguredHelpersOrAPrivatePrompt =>
      'Las credenciales son suministradas por ayudantes configurados o por un aviso privado.';

  @override
  String gitUiRemoveRemoteArg0(String arg0) {
    return '¿Quitar $arg0 remoto?';
  }

  @override
  String
  get gitUiRemovesLocalRemoteConfigurationAndTrackingReferencesItDoesNot =>
      'Elimina la configuración remota local y las referencias de seguimiento. No elimina el repositorio del servidor.';

  @override
  String get gitUiRemoveRemote2 => 'Eliminar el control remoto';

  @override
  String get gitUiCommitScopeEntireRepository =>
      'Alcance de la comisión: repositorio completo';

  @override
  String get gitUiCachedTracking => 'Rastreo en cacheado';

  @override
  String get gitUiAmendLastCommit => 'Modificar último commit';

  @override
  String get gitUiConfiguredHooksAndSigningAreRespected =>
      'Se respetan los ganchos y la firma configurados.';

  @override
  String get gitUiRewritesTheSelectedHEADCommitRemoteTrackingCannotProveIt =>
      'Reescribe el commit HEAD seleccionado. El seguimiento remoto no demuestra que no esté publicado.';

  @override
  String get gitUiRepository => 'Repositorio';

  @override
  String gitUiDetachedArg0(String arg0) {
    return '$arg0 separado';
  }

  @override
  String get gitUiLog => 'Historial';

  @override
  String get gitUiRepositoryActions => 'Acciones del repositorio';

  @override
  String gitUiCachedTrackingUpstreamAheadAheadBehindBehind(
    String upstream,
    String ahead,
    String behind,
  ) {
    return 'Seguimiento en caché · $upstream · $ahead por delante · $behind por detrás';
  }

  @override
  String get gitUiBareRepositoryNoWorkingTreeOpenLogToInspectIts =>
      'Depósito vacío · sin árbol de trabajo. Abra el registro para inspeccionar su historial.';

  @override
  String get gitUiReadOnlyRepositoryStagingAndCommitsAreUnavailable =>
      'Repositorio de sólo lectura · preparación y confirmaciones no están disponibles.';

  @override
  String get gitUiRepositoryStatusUnavailable =>
      'Estado del repositorio no disponible';

  @override
  String gitUiAmendRevision(String revision) {
    return 'Modifíquese $revision';
  }

  @override
  String get gitUiAddSignOffTrailer => 'Añadir línea de conformidad';

  @override
  String get gitUiUseConfiguredSigningPolicy =>
      'Usar la política de firma configurada';

  @override
  String get gitUiCryptographicallySignThisCommit =>
      'Firma criptográficamente este commit';

  @override
  String get gitUiDoNotSignThisCommit => 'No firme esta confirmación';

  @override
  String get gitUiRecentCommitMessages =>
      'Mensajes de confirmación recientes...';

  @override
  String get gitUiUseConfiguredCommitTemplate =>
      'Usar la plantilla de confirmación configurada...';

  @override
  String get gitUiAuthorIdentityAndConfiguredHooks =>
      'Autor de identidad y ganchos configurados...';

  @override
  String get gitUiDraftMessage => 'Mensaje de borrador...';

  @override
  String get gitUiCommitOptions => 'Opciones del commit';

  @override
  String gitUiDraftRetainedInMemorySavingItFailedArg0(String arg0) {
    return 'Borrador conservado en memoria; guardarlo falló. $arg0';
  }

  @override
  String get gitUiCommitMessage => 'Mensaje del commit';

  @override
  String get gitUiGitOperationInProgress => 'Operación Git en curso';

  @override
  String get gitUiCancel => 'Cancelar';

  @override
  String get gitUiAmendStaged => 'Modifíquese por etapas';

  @override
  String gitUiCommitStagedCount(String count) {
    return 'Confirmar lo preparado ($count)';
  }

  @override
  String get gitUiCommitAndPush => 'Confirmar y enviar…';

  @override
  String get gitUiNoReadableCommitTemplateIsConfigured =>
      'No se configura ninguna plantilla de confirmación legible.';

  @override
  String get gitUiCommitIdentityAndHooks => 'Cometer identidad y ganchos';

  @override
  String get gitUiRecentMessages => 'Mensajes recientes';

  @override
  String get gitUiReplaceMessageDraft => '¿Reemplazar el borrador del mensaje?';

  @override
  String get gitUiReplaceTheExistingCommitMessageWithTheSelectedMessage =>
      '¿Reemplazar el mensaje de confirmación existente con el mensaje seleccionado?';

  @override
  String get gitUiReplaceDraft =>
      'Sustitúyase el proyecto por el texto siguiente:';

  @override
  String gitUiLocalCommitArg0Exists(String arg0) {
    return 'local commit $arg0 existe.';
  }

  @override
  String gitUiLocalCommitArg0ExistsReviewLogBeforeAttemptingAnotherCommit(
    String arg0,
  ) {
    return 'Local commit $arg0 existe. Revise el registro antes de intentar otro commit. Se ha conservado el borrador del mensaje.';
  }

  @override
  String get gitUiCommitAuthorName => 'Nombre del autor de la comisión';

  @override
  String get gitUiCommitAuthorEmail => 'Enviar correo electrónico del autor';

  @override
  String get gitUiConfiguredDefault => 'predeterminado configurado';

  @override
  String get gitUiOpenpgp => 'OpenPGP';

  @override
  String gitUiSigningArg0Arg1(String arg0, String arg1) {
    return 'Firma: $arg0 · $arg1';
  }

  @override
  String gitUiConfiguredHooksArg0(String arg0) {
    return 'Ganchos configurados: $arg0';
  }

  @override
  String get gitUiASignOffTrailerIsAStatementInTheMessage =>
      'La línea de conformidad es una declaración en el mensaje, distinta de una firma criptográfica. La identidad se guarda solo en la configuración de este repositorio; el borrador se conserva.';

  @override
  String get gitUiSaveRepositoryIdentity =>
      'Guardar la identidad del repositorio';

  @override
  String get gitUiStaged => 'Preparados';

  @override
  String get gitUiUntracked => 'Sin seguimiento';

  @override
  String get gitUiUnstaged => 'Sin preparar';

  @override
  String get gitUiConflicts => 'Conflictos';

  @override
  String get gitUiNoChanges => 'No hay cambios';

  @override
  String get gitUiRepositoryChangeTree => 'Árbol de cambio del repositorio';

  @override
  String get gitUiChanges => 'Cambios';

  @override
  String gitUiGroupCount(String group, String count) {
    return '$group ($count)';
  }

  @override
  String get gitUiExpand => 'Expandir';

  @override
  String get gitUiCollapse => 'Colapso';

  @override
  String get gitUiUnstageFile => 'Quitar archivo de preparación';

  @override
  String get gitUiStageFile => 'Preparar archivo';

  @override
  String get gitUiExpandGroup => 'Expandir grupo';

  @override
  String get gitUiCollapseGroup => 'Grupo de colapso';

  @override
  String get gitUiReviewDifference => 'Diferencia de revisión';

  @override
  String get gitUiUnstageSelectedFiles =>
      'Quitar archivos seleccionados de preparación';

  @override
  String get gitUiStageSelectedFiles => 'Preparar archivos seleccionados';

  @override
  String get gitUiFileHistoryAndBlame => 'Historial de archivos y culpa...';

  @override
  String get gitUiDeleteUntrackedFile => 'Eliminar archivo no rastreado...';

  @override
  String get gitUiDiscardUnstagedChange => 'Desechar el cambio sin etapas...';

  @override
  String get gitUiFileHistory => 'Historial del archivo';

  @override
  String gitUiDiscardUnstagedArg0(String arg0) {
    return '¿Desechar $arg0 sin etapas?';
  }

  @override
  String gitUiArg0BytesArg1ReplacesWorkingContentWithTheIndexOr(
    String arg0,
    String arg1,
  ) {
    return '$arg0 bytes · $arg1 Reemplaza el contenido de trabajo con el índice, o elimina este archivo no rastreado. Se conserva el contenido escalonado. Los documentos de host no guardados deben revisarse primero.';
  }

  @override
  String get gitUiDeleteUntrackedFile2 => 'Eliminar archivo no rastreado';

  @override
  String get gitUiDiscardWorkingChange => 'Desechar el cambio de trabajo';

  @override
  String gitUiDeleteREMOTEReferenceArg0(String arg0) {
    return 'Borrar la referencia $arg0';
  }

  @override
  String get gitUiThisRemovesTheReferenceOnEveryActualPushDestinationListed =>
      'Esto elimina la referencia en cada destino de empuje real que se enumeran a continuación. Ramas/etiquetas locales se conservan. Los consejos esperados se fijan por esta revisión.';

  @override
  String get gitUiReferenceDoesNotExist => 'no existe referencia';

  @override
  String gitUiArg0ExpectedTipArg1(String arg0, String arg1) {
    return '$arg0 Punta esperada: $arg1';
  }

  @override
  String get gitUiRemoteDeletionCompleted => 'Eliminación remota completada.';

  @override
  String gitUiDeleteArg0FromTheRemote(String arg0) {
    return '¿Borrar $arg0 del control remoto?';
  }

  @override
  String get gitUiTheExactDestinationTipsShownAboveWillBeRemovedAny =>
      'Los consejos de destino exactos mostrados anteriormente serán eliminados. Cualquier punta remota cambiada detiene la operación para otra revisión.';

  @override
  String get gitUiReviewAndDeleteFromRemote =>
      'Revisar y eliminar desde el control remoto...';

  @override
  String get gitUiDestinationReference => 'Referencia de destino';

  @override
  String get gitUiReviewDestinations => 'Destinos de revisión';

  @override
  String get gitUiNewRemoteBranch => 'nueva rama remota';

  @override
  String gitUiArg0Arg1ExpectedArg2(String arg0, String arg1, String arg2) {
    return '$arg0\n$arg1 · esperado: $arg2';
  }

  @override
  String get gitUiADestinationHasCommitsThatAreUnavailableLocallyFetchThat =>
      'Un destino tiene compromisos que no están disponibles localmente. Obtener ese destino revisado antes de revisar el historial saliente.';

  @override
  String get gitUiFetchReviewedDestination => 'Obtener destino revisado';

  @override
  String get gitUiChooseADestinationAndReviewTheOutgoingCommits =>
      'Elija un destino y revise los compromisos salientes.';

  @override
  String get gitUiNoOutgoingCommits => 'Sin compromisos salientes';

  @override
  String get gitUiSelectAnOutgoingCommit =>
      'Seleccione una confirmación saliente';

  @override
  String get gitUiLoadMoreOutgoingCommits => 'Cargar más commits salientes';

  @override
  String get gitUiSetThisDestinationAsUpstream =>
      'Establecer este destino como aguas arriba';

  @override
  String get gitUiChooseExactTagsToPublish =>
      'Elija etiquetas exactas para publicar';

  @override
  String get gitUiTagsNone => 'Etiquetas: ninguna';

  @override
  String gitUiTagsArg0Selected(String arg0) {
    return 'Etiquetas: $arg0 seleccionado';
  }

  @override
  String gitUiPublishExactlyArg0(String arg0) {
    return 'Publique exactamente: $arg0';
  }

  @override
  String get gitUiPushCompletedTheLocalCommitRemainsAvailableInLog =>
      'Empujar completado. El compromiso local permanece disponible en Registro.';

  @override
  String get gitUiForceRequiresTheExactDestinationTipsShownInThisReview =>
      'El envío forzado exige exactamente las revisiones de destino mostradas en esta revisión.';

  @override
  String get gitUiForceWithReviewedLease => 'Fuerza con alquiler revisado...';

  @override
  String get gitUiPush => 'Enviar';

  @override
  String get gitUiForcePushWithReviewedLeases =>
      '¿Empujo la fuerza con contratos revisados?';

  @override
  String gitUiRewriteArg0OnlyIfEveryRemoteDestinationStillHasThe(String arg0) {
    return 'Reescribir $arg0 sólo si cada destino remoto todavía tiene la punta exacta mostrada arriba.\n';
  }

  @override
  String get gitUiOtherPeopleMayAlreadyUseThisHistoryABackgroundFetch =>
      'Otras personas podrían estar usando este historial. Una obtención en segundo plano no renueva esta condición de seguridad.';

  @override
  String get gitUiForceWithLease => 'Fuerza con contrato de arrendamiento';

  @override
  String
  get gitUiTheRemoteOutcomeIsUncertainReviewDestinationsAgainBeforeAnother =>
      'El resultado remoto es incierto. Revise los destinos de nuevo antes de otro empujón.';

  @override
  String gitUiParentArg0Arg1(String arg0, String arg1) {
    return 'Padre $arg0 · $arg1';
  }

  @override
  String get gitUiRemoteToFetch => 'Remoto a buscar';

  @override
  String get gitUiPruneDeletedRemoteTrackingBranches =>
      'Pune eliminado ramas de seguimiento remoto';

  @override
  String
  get gitUiFetchUpdatesRemoteTrackingInformationWithoutReplacingWorkingFiles =>
      'Obtener actualizaciones de información de seguimiento remoto sin reemplazar los archivos de trabajo.';

  @override
  String get gitUiFetch => 'Obtener';

  @override
  String get gitUiSourceRemote => 'Fuente remota';

  @override
  String get gitUiSourceBranch => 'Sucursal de origen';

  @override
  String get gitUiReviewedStrategy => 'Estrategia revisada';

  @override
  String get gitUiMerge => 'Fusionar';

  @override
  String get gitUiRebase => 'Reorganizar';

  @override
  String get gitUiStopIfTheDestinationCannotFastForwardNeverMergeOr =>
      'Parar si el destino no puede avanzar rápidamente; nunca fusionar o rebase.';

  @override
  String get gitUiMergeWithAMergeCommitIncludingWhenFastForwardIs =>
      'Fusionar con un commit de fusión, incluso cuando sea posible avanzar rápidamente.';

  @override
  String get gitUiMergeAllowFastForwardWhenPossible =>
      'Fusionar; permitir el avance rápido cuando sea posible.';

  @override
  String get gitUiRebaseLocalHistoryWhilePreservingLocalMergeCommits =>
      'Rebase la historia local mientras se preserva la fusión local commits.';

  @override
  String get gitUiRebaseLocalCommitsAsALinearHistory =>
      'Rebase local commits como una historia lineal.';

  @override
  String get gitUiGitIsConfiguredForInteractiveRebaseSelectAPullStrategy =>
      'Git está configurado para rebase interactivo. Seleccione una estrategia de tracción explícitamente aquí, o busque y abra Rebase... para revisar un plan.';

  @override
  String get gitUiUseReviewedOrdinaryRebaseForThisPull =>
      'Usar rebase ordinario revisado para este tirón';

  @override
  String get gitUiOptions => 'Opciones';

  @override
  String get gitUiAlwaysCreateAMergeCommitNoFastForward =>
      'Crear siempre un commit de fusión (sin avance rápido)';

  @override
  String get gitUiPreserveLocalMergeCommits =>
      'Preservar confirmaciones locales de la fusión';

  @override
  String get gitUiLocalChangesMayPreventPullReviewCommitThemOrExplicitly =>
      'Los cambios locales pueden impedir que se retiren. Revise/compromete o cree explícitamente un alijo.';

  @override
  String get gitUiStashes => 'Reservas';

  @override
  String get gitUiCreateOrReviewStash => 'Crear o revisar el escondite...';

  @override
  String get gitUiPullWithSelectedStrategy =>
      'Tira con la estrategia seleccionada';

  @override
  String get gitUiRepositoryURLOrLocalGitSource =>
      'URL del repositorio o fuente local de Git';

  @override
  String get gitUiHttpsSSHOrLocalPath => 'HTTPS, SSH o ruta local';

  @override
  String get gitUiFolderToInitialize => 'Carpeta a inicializar';

  @override
  String get gitUiFinalCloneDestination => 'Destino final del clon';

  @override
  String get gitUiChoose => 'Elija...';

  @override
  String get gitUiCreatesGitMetadataOnlyExistingFilesAreNotStagedOr =>
      'Crea solo metadatos Git. Los archivos existentes no están escenificados ni comprometidos.';

  @override
  String get gitUiTheFinalDestinationMustBeAbsentOrEmptyExistingUser =>
      'El destino final debe estar ausente o vacío. Nunca se sobrescriben los datos existentes del usuario.';

  @override
  String get gitUiInitialBranchBlankUsesEffectiveGitPolicy =>
      'Sucursal inicial · blank usa la política Git efectiva';

  @override
  String get gitUiSelectedBranchOptional => 'Rama seleccionada · opcional';

  @override
  String get gitUiExplicitlyInitializeUpdateSubmodulesRecursively =>
      'Inicializar/actualizar explícitamente los submódulos recursivamente';

  @override
  String get gitUiPreparingGitOperation => 'Preparando la operación Git...';

  @override
  String get gitUiThisAttemptCreated => 'Este intento creado';

  @override
  String get gitUiTheDestinationExistedBeforeThisAttempt =>
      'El destino existía antes de este intento:';

  @override
  String get gitUiTheDirectoryRemainsForInspectionReviewItBeforeAnotherClone =>
      'El directorio permanece para inspección. Revise antes de otro intento de clon.';

  @override
  String get gitUiNoDestinationDirectoryRemains =>
      'No queda ningún directorio de destino.';

  @override
  String get gitUiCancelProcess => 'Cancelar el proceso';

  @override
  String get gitUiInitialize => 'Inicializar';

  @override
  String get gitUiClone => 'Clonar';

  @override
  String get gitUiChooseNewBase => 'Elegir nueva base';

  @override
  String get gitUiChooseUpstreamBoundary => 'Elegir límite anterior';

  @override
  String get gitUiNewBase => 'Nueva base';

  @override
  String get gitUiUpstreamBoundaryExcluded => 'Límite anterior · excluido';

  @override
  String get gitUiSameAsUpstreamBoundary => 'Igual al límite anterior';

  @override
  String get gitUiChooseBranchTagOrCommit => 'Elegir rama, etiqueta o commit…';

  @override
  String get gitUiUseUpstreamAsNewBase =>
      'Utilizar aguas arriba como nueva base';

  @override
  String get gitUiChooseAValidBranchTagOrCommitFromLog =>
      'Elija una rama, etiqueta o confirmación válida de Registro.';

  @override
  String get gitUiTheFirstRetainedCommitInABranchBlockCannotSquash =>
      'El primer commit conservado de un bloque de rama no puede usar squash ni fixup: no tiene un commit anterior de destino.';

  @override
  String gitUiBranchBlockArg0(String arg0) {
    return 'Bloque de rama $arg0\n';
  }

  @override
  String get gitUiRewordWillRequestANewMessage =>
      '[Reformular solicitará un nuevo mensaje]\n';

  @override
  String get gitUiPlannedCommitMessages => 'Mensajes de confirmación previstos';

  @override
  String
  get gitUiOriginalCombinedMessagePreviewGitRequestsTheFinalRewordSquash =>
      'Previsualización de mensaje original/combinado · Git solicita los mensajes finales de repalabra/squash';

  @override
  String gitUiResultArg0Arg1(String arg0, String arg1) {
    return 'Resultado $arg0 $arg1';
  }

  @override
  String gitUiCurrentBranchBranch(String branch) {
    return 'Rama actual: $branch';
  }

  @override
  String get gitUiDetachedHEAD2 => 'HEAD separado';

  @override
  String
  get gitUiRebaseRewritesCommitIdentitiesRemoteTrackingInformationCannotProveHistory =>
      'La reorganización reescribe las identidades de los commits. El seguimiento remoto no demuestra que el historial nunca se haya publicado.';

  @override
  String get gitUiIncludeRootCommits => 'Incluir commits raíz';

  @override
  String get gitUiMergeCommits => 'Fusionar los compromisos';

  @override
  String get gitUiFlattenHistory => 'Aplanar historial';

  @override
  String get gitUiPreserveBranchStructure => 'Conservar estructura de ramas';

  @override
  String get gitUiAutosquash => 'Combinar automáticamente';

  @override
  String get gitUiPrepareGitPlan => 'Preparar plan de Git';

  @override
  String gitUiCommitsToReplayCount(String count) {
    return 'Commits que se volverán a aplicar: $count';
  }

  @override
  String get gitUiIncludesAllRootCommitsReachableFromThisBranch =>
      'Incluye todos los commits root alcanzables desde esta rama.';

  @override
  String gitUiCommitsAfterBoundaryWillBeReplayedOntoBaseTheBoundary(
    String boundary,
    String base,
  ) {
    return 'Los commits posteriores a $boundary se reaplicarán sobre $base; el commit límite queda excluido.';
  }

  @override
  String get gitUiRoot => 'Raíz';

  @override
  String get gitUiGitBranchLabelResetMergeStructure =>
      'Rama de Git/etiqueta/restablecimiento/estructura de fusión';

  @override
  String get gitUiChooseAnExplicitOldBoundaryOrRootModeThenPrepare =>
      'Elija un antiguo límite explícito o modo raíz, a continuación, prepare el plan.';

  @override
  String get gitUiMoveUp => 'Subir';

  @override
  String get gitUiMoveDown => 'Bajar';

  @override
  String get gitUiResetPlan => 'Restablecer plan';

  @override
  String gitUiBranchBlockArg02(String arg0) {
    return ' · Bloque de rama $arg0';
  }

  @override
  String get gitUiSelectACommitForDetailsAndChangedFiles =>
      'Seleccione una confirmación para obtener detalles y los archivos cambiados';

  @override
  String get gitUiPreviewCombinedCommitMessages =>
      'Previsualizar los mensajes de confirmación combinados...';

  @override
  String get gitUiAltMovesTheSelectedCommitUnrelatedBranchReferencesWillNot =>
      'Alt/↓ mueve la confirmación seleccionada. Las referencias de ramas no relacionadas no se actualizarán automáticamente.';

  @override
  String get gitUiCancelPlan => 'Cancelar el plan';

  @override
  String get gitUiStartReviewedRebase => '¿Iniciar el rebase revisado?';

  @override
  String gitUiRewriteArg0PlannedCommitsOnArg1DroppedCommitsRemainVisibly(
    String arg0,
    String arg1,
  ) {
    return 'Reescribir $arg0 commits planeados en $arg1. Los commits caídos permanecerán marcados visiblemente en este plan hasta que comience.';
  }

  @override
  String get gitUiStartRebase => 'Iniciar reorganización';

  @override
  String get gitUiNoContinuingGitOperation => 'No continuar la operación Git';

  @override
  String get gitUiStoppedForEditingAmend => ' · Detenido para editar/enmendar';

  @override
  String get gitUiTheseAreUnmergedIndexEntriesPossiblyFromAStashApplication =>
      'Estas son entradas de índice sin fusionar, posiblemente de una aplicación de almacenamiento. Git no tiene ninguna orden de continuar o abortar.';

  @override
  String get gitUiEditTheWorkingFilesStageAndAmendTheCurrentCommit =>
      'Edite los archivos de trabajo, escenifique y modifique la confirmación actual, y luego continúe esta rebase.';

  @override
  String gitUiArg0Arg1UnmergedStagesArg2(
    String arg0,
    String arg1,
    String arg2,
  ) {
    return '$arg0$arg1 · etapas del índice sin fusionar $arg2';
  }

  @override
  String get gitUiTheIndexHasNoUnresolvedEntries =>
      'El índice no tiene entradas sin resolver.';

  @override
  String get gitUiKeepTheCurrentCommitAsAnEmptyCommit =>
      'Mantener la confirmación actual como una confirmación vacía';

  @override
  String get gitUiTheRealIndexHasNoStagedChangesCreateAnExplicit =>
      'El índice real no tiene cambios escalonados. Cree una confirmación vacía explícita, luego continúe con el secuenciador si permanece activo.';

  @override
  String get gitUiKeepEmptyCommit => 'Mantenga la confirmación vacía...';

  @override
  String get gitUiGitWillTryToReturnToTheOperationSStarting =>
      'Git intentará volver al inicio de la operación. No se garantiza recuperar contenido previo sin preparar, sin seguimiento o sin guardar.';

  @override
  String get gitUiSkipTheCurrentCommitAndContinueWithTheNextPlanned =>
      'Omitir el compromiso actual y continuar con el siguiente compromiso planeado.';

  @override
  String
  get gitUiForgetThisOperationSBookkeepingWhileRetainingTheCurrentFiles =>
      'Olvídese de la contabilidad de esta operación mientras conserva los archivos e índices actuales.';

  @override
  String gitUiContinueArg0(String arg0) {
    return 'Continuar $arg0';
  }

  @override
  String get gitUiReloadConflictVersions => '¿Recargar versiones de conflicto?';

  @override
  String get gitUiReplaceTheUnsavedResultDraftWithTheCurrentWorkingFile =>
      'Reemplace el borrador de Resultado no guardado con el archivo de trabajo actual. Se conserva el contenido de trabajo guardado.';

  @override
  String get gitUiLoadingConflictVersions =>
      'Cargando versiones de conflicto...';

  @override
  String get gitUiLoadingConflict => 'Cargando conflicto';

  @override
  String get gitUiBaseLeft => 'Base → izquierda';

  @override
  String get gitUiBaseRight => 'Base → derecha';

  @override
  String get gitUiNoBaseEntryForThisConflict =>
      'No hay entrada de base para este conflicto';

  @override
  String get gitUiAcceptEntireLeftFile =>
      'Aceptar todo el archivo izquierdo...';

  @override
  String get gitUiAcceptEntireRightFile =>
      'Aceptar todo el archivo de la derecha…';

  @override
  String get gitUiPreviousConflictRegion => 'Región de conflicto anterior';

  @override
  String get gitUiNextConflictRegion => 'Próxima región de conflicto';

  @override
  String get gitUiManualResolution => 'Resolución manual';

  @override
  String gitUiRegionArg0Arg1Arg2Reviewed(
    String arg0,
    String arg1,
    String arg2,
  ) {
    return 'Región $arg0/$arg1 · $arg2 revisado';
  }

  @override
  String
  get gitUiSourceAlignmentExceededTheTextComparisonLimitSourcePanesRemain =>
      'La alineación de fuentes superó el límite de comparación de textos; los paneles fuente siguen disponibles para revisión manual.';

  @override
  String get gitUiAcceptLeftRegion => 'Aceptar región izquierda';

  @override
  String get gitUiAcceptRightRegion => 'Aceptar la región correcta';

  @override
  String get gitUiKeepManualResultForRegion =>
      'Mantener el resultado manual para la región';

  @override
  String get gitUiApplyGitSNonConflictingChanges =>
      '¿Aplicar los cambios no conflictivos de Git?';

  @override
  String get gitUiReplaceTheCurrentResultDraftWithGitSMergePreview =>
      'Reemplace el borrador de resultados actual con la vista previa de fusión de Git. Esto descarta las ediciones de resultados manuales no guardadas; el archivo de trabajo no cambia hasta Guardar.';

  @override
  String get gitUiUseMergePreview => 'Usar la vista previa de fusión';

  @override
  String get gitUiApplyNonConflictingChanges =>
      'Aplicar cambios no conflictivos...';

  @override
  String get gitUiLeftSource => 'Fuente izquierda';

  @override
  String get gitUiResult => 'Resultado';

  @override
  String get gitUiRightSource => 'Fuente derecha';

  @override
  String get gitUiStage2 => 'Etapa 2';

  @override
  String get gitUiStage3 => 'Etapa 3';

  @override
  String
  get gitUiConflictVersionsAreUnavailableRefreshToReviewTheirCurrentState =>
      'Las versiones de conflicto no están disponibles. Refresque para revisar su estado actual.';

  @override
  String get gitUiResultSavedToDiskTheIndexStillDeterminesWhetherThis =>
      'Resultado guardado en disco. El índice todavía determina si este archivo está resuelto.';

  @override
  String get gitUiSaveResultDraft => 'Guardar borrador del resultado';

  @override
  String get gitUiApplyResultAndStageResolution =>
      'Aplicar resultado y preparar resolución';

  @override
  String get gitUiResultEditableUTF8WorkingContent =>
      'Resultado · Contenido de trabajo editable UTF-8';

  @override
  String get gitUiEditableConflictResult => 'Resultado de conflicto editable';

  @override
  String gitUiLeftArg0Arg1RightArg2Arg3(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return 'Izquierda: $arg0 · $arg1\nDerecha: $arg2 · $arg3';
  }

  @override
  String get gitUiChooseContentDeletionOrASubmoduleCommitExplicitlyNoBinary =>
      'Elija contenido, eliminación o una confirmación de submódulo explícitamente. Ningún dato binario se decodifica como texto editable.';

  @override
  String get gitUiUseEntireLeftContent => 'Usar todo el contenido izquierdo...';

  @override
  String get gitUiUseEntireRightContent =>
      'Usar todo el contenido de la derecha…';

  @override
  String get gitUiDeleteThisPath => 'Borrar esta ruta...';

  @override
  String get gitUiResolvedSubmoduleCommit => 'Enviar submódulo resuelto';

  @override
  String get gitUiStageThisExactGitlinkInTheParentThisDoesNot =>
      'Establezca este gitlink exacto en el padre. Esto no comprueba o compromete el submódulo.';

  @override
  String get gitUiSetResolvedGitlink => 'Establecer gitlink resuelto...';

  @override
  String gitUiBaseStageArg0(String arg0) {
    return 'Base → etapa $arg0';
  }

  @override
  String get gitUiTheResultWasEditedKeepTheManualResultOrSelect =>
      'El resultado fue editado. Mantenga el resultado manual o seleccione otra región sin cambios.';

  @override
  String gitUiApplyArg0Resolution(String arg0) {
    return '¿Aplicar la resolución «$arg0»?';
  }

  @override
  String get gitUiStageTheChosenGitlinkCommitInTheParentTheSubmodule =>
      'Establezca la confirmación gitlink elegida en el padre. La caja del submódulo y sus archivos no se reemplazan.';

  @override
  String gitUiReplacesTheEntireWorkingPathArg0AndStagesTheDecision(
    String arg0,
  ) {
    return 'Reemplaza toda la ruta de trabajo $arg0 y escalona la decisión. El contenido de trabajo actual y cualquier borrador de resultado no guardado será descartado.';
  }

  @override
  String get gitUiApplyEntireFileDecision =>
      'Aplicar la decisión de archivo completo';

  @override
  String get gitUiStageThisConflictResolution =>
      '¿Escenificar esta resolución de conflictos?';

  @override
  String gitUiUseTheEntireEditedResultAsArg0GitRecordsThe(
    String arg0,
    String arg1,
  ) {
    return 'Utilice todo el resultado editado como $arg0. Git registra la ruta resuelta cuando se escenifica. Revise primero todo el contenido previsto.$arg1';
  }

  @override
  String get gitUiApplyAndStage => 'Aplicar y preparar';

  @override
  String get gitUiReviewResultTextFormatChanges =>
      'Revisión de los cambios en el formato de texto de los resultados';

  @override
  String get gitUiSaveReviewedResult => 'Guardar el resultado revisado';

  @override
  String
  get gitUiNativeGitTableAccessibilityIsUnavailableRetryAfterReconnectingThe =>
      'La accesibilidad de la tabla Native Git no está disponible. Inténtalo de nuevo después de reconectar la aplicación.';

  @override
  String get gitUiSans => 'Sans';

  @override
  String get gitUiSelect => 'Seleccionar';

  @override
  String get gitUiContextMenu => 'Menú contextual';

  @override
  String get gitUiCopyText => 'Copiar texto';

  @override
  String get gitUiLoadingRow => 'Cargar fila';

  @override
  String get gitUiRetry => 'Reintentar';

  @override
  String get gitUiGitMessage => 'Mensaje de Git';

  @override
  String get gitUiCancelPrompt => 'Cancelar el mensaje';

  @override
  String get gitUiUseMessageAndContinue => 'Usar mensaje y continuar';

  @override
  String get gitUiRespondPrivately => 'Responder en privado';

  @override
  String gitUiViewPreferencesCouldNotBeSavedArg0(String arg0) {
    return 'No se pudieron guardar las preferencias de Ver: $arg0';
  }

  @override
  String gitUiCommitDraftStorageArg0(String arg0) {
    return 'Enviar borrador de almacenamiento: $arg0';
  }

  @override
  String gitUiViewPreferencesCouldNotBeReadArg0(String arg0) {
    return 'Las preferencias de la vista no se pudieron leer: $arg0';
  }

  @override
  String gitUiCommitDraftWasRetainedInMemoryButCouldNotBe(String arg0) {
    return 'El borrador de la comisión se mantuvo en memoria pero no se pudo guardar: $arg0';
  }

  @override
  String get gitUiTheReviewedRepositoryIsReadOnlyForThisOperationHistory =>
      'El repositorio revisado es de sólo lectura para esta operación. Historial y contenido de inspección permanecen disponibles.';

  @override
  String gitUiGitReturnedArg0TheApplicationCouldNotRefreshItsDocuments(
    String arg0,
    String arg1,
  ) {
    return 'Git devolvió $arg0. La aplicación no pudo actualizar sus documentos: $arg1';
  }

  @override
  String get gitUiSelectCommitInLog => 'Elegir commit en el historial…';

  @override
  String get gitUiCurrentBranch => 'Rama actual';

  @override
  String get gitUiNoMatchingBranchesOrTagsSelectACommitInLog =>
      'No hay ramas o etiquetas coincidentes. Seleccione una confirmación en Registro.';

  @override
  String get gitUiBranches => 'Ramas';

  @override
  String get gitUiPushCommits => 'Enviar commits';

  @override
  String gitUiPullIntoArg0(String arg0) {
    return 'Tire hacia $arg0';
  }

  @override
  String gitUiResolveArg0(String arg0) {
    return 'Resolver $arg0';
  }

  @override
  String get gitUiCurrentOperation => 'Funcionamiento actual';

  @override
  String get gitUiRebaseCommits => 'Reorganizar commits';

  @override
  String get gitUiFetch2 => 'Obtener…';

  @override
  String get gitUiPull => 'Extraer…';

  @override
  String get gitUiPush2 => 'Enviar…';

  @override
  String get gitUiBranches2 => 'Ramas…';

  @override
  String get gitUiManageRemotes => 'Gestionar remotos…';

  @override
  String gitUiMergeIntoArg0(String arg0) {
    return 'Fusionar en $arg0...';
  }

  @override
  String get gitUiRebase2 => 'Reorganizar…';

  @override
  String get gitUiConflictsAndCurrentOperation =>
      'Conflictos y operación actual...';

  @override
  String get gitUiStashes2 => 'Reservas…';

  @override
  String get gitUiWorktrees => 'Árboles de trabajo…';

  @override
  String get gitUiSubmodules => 'Submódulos…';

  @override
  String get gitUiReflogAndRecovery => 'Reflog y recuperación…';

  @override
  String get gitUiCloneRepository => 'Clonar repositorio…';

  @override
  String get gitUiRevokeRepositoryTrust =>
      'Revocar la confianza en el repositorio';

  @override
  String get gitUiWaitingForRepositoryStatus =>
      'Esperando el estado del repositorio';

  @override
  String get gitUiRepositoryStatusUnavailableRefresh =>
      'Estado del repositorio no disponible; actualizar';

  @override
  String get gitUiManageRemotes2 => 'Gestionar remotos';

  @override
  String gitUiMergeIntoArg02(String arg0) {
    return 'Fusionar en $arg0';
  }

  @override
  String get gitUiWorktrees2 => 'Árboles de trabajo';

  @override
  String get gitUiSubmodules2 => 'Submódulos';

  @override
  String get gitUiReflogAndRecovery2 => 'Reflog y recuperación';

  @override
  String gitUiCloneRepositoryArg0(String arg0) {
    return 'Depósito de clones · $arg0';
  }

  @override
  String get gitUiApply => 'Aplicar';

  @override
  String get gitUiResizeGitPanes => 'Redimensionar los paneles Git';

  @override
  String gitUiArg0Percent(String arg0) {
    return '$arg0 por ciento';
  }

  @override
  String gitUiExitStatusStatus(String status) {
    return 'Estado de salida: $status';
  }

  @override
  String get gitUiRepositoryChangedRefreshAndReviewBeforeTryingAgain =>
      'Repositorio cambiado. Refrescar y revisar antes de intentarlo de nuevo.';

  @override
  String get gitUiAnotherOperationHoldsTheRepositoryOrIndexLockWaitThen =>
      'Otra operación sostiene el repositorio o bloqueo de índice. Espere y luego refresque.';

  @override
  String get gitUiRepositoryTrustIsRequiredForThisOperation =>
      'Para esta operación se requiere la confianza del repositorio.';

  @override
  String get gitUiTheGitServiceDisconnectedReconnectAndReconcileTheRepository =>
      'El servicio Git está desconectado. Reconecte y concilie el repositorio.';

  @override
  String
  get gitUiTheInstalledGitExecutableCannotSupportThisOperationReviewIts =>
      'El ejecutable Git instalado no puede soportar esta operación. Revise sus requisitos de tiempo de ejecución a continuación.';

  @override
  String get gitUiThisRepositoryIsReadOnlyForTheRequestedOperationReview =>
      'Este repositorio es de sólo lectura para la operación solicitada. Revisión e historial permanecen disponibles.';

  @override
  String
  get gitUiTheOperationNeedsReconciliationReviewTheResultingRepositoryOrRemote =>
      'La operación necesita conciliación. Revise el repositorio o estado remoto resultante antes de repetirlo.';

  @override
  String get gitUiGitAuthenticationFailedReviewTheCredentialHelperOrUnlockThe =>
      'Falló la autenticación de Git. Revise el ayudante de credencial o desbloquee el llavero configurado.';

  @override
  String get gitUiSshHostVerificationFailedReviewTheHostIdentityThroughYour =>
      'Falló la verificación del host SSH. Revise la identidad del host a través de sus herramientas SSH configuradas.';

  @override
  String get gitUiCommitSigningFailedOrWasCancelledReviewTheSigningKey =>
      'Falló la firma de comisión o fue cancelada. Revise la clave de firma, agente y herramienta de firma configurada.';

  @override
  String get gitUiSetARepositoryAuthorNameAndEmailThenReturnTo =>
      'Establezca un nombre de autor del repositorio y un correo electrónico, y luego vuelva al borrador del mensaje preservado.';

  @override
  String get gitUiGitRejectedTheReviewedUpdateRefreshAndReviewTheActual =>
      'Git rechazó la actualización revisada. Refresque y revise el destino real antes de intentarlo de nuevo.';

  @override
  String get gitUiWorkingOrStagedChangesPreventThisOperationReviewCommitOr =>
      'Los cambios de trabajo o escenificados evitan esta operación. Revise, commit o escondite explícitamente.';

  @override
  String get gitUiARequiredGitObjectIsUnavailableReviewShallowOrPartial =>
      'Un objeto Git requerido no está disponible. Revise los límites de repositorios poco profundos o parciales y busque explícitamente si es necesario.';

  @override
  String gitUiGitOperationFailedArg0(String arg0) {
    return 'Falló la operación de Git: $arg0';
  }

  @override
  String get gitUiDiagnostics => 'Diagnóstico';

  @override
  String get gitUiAuthorizeGitInspection => 'Autorizar la inspección de Git...';

  @override
  String get gitUiCopyDiagnostics => 'Copiar diagnósticos';

  @override
  String get gitUiActions => 'Acciones';

  @override
  String gitUiBranchAtArg0(String arg0) {
    return 'Sucursal de $arg0';
  }

  @override
  String get gitUiCreatesALocalBranchWithoutCheckingItOut =>
      'Crea una sucursal local sin revisarla.';

  @override
  String gitUiTagArg0(String arg0) {
    return 'Etiqueta $arg0';
  }

  @override
  String gitUiReadOnlySnapshotArg0(String arg0) {
    return 'Instantánea de solo lectura · $arg0';
  }

  @override
  String get gitUiCherryPickCommits => 'Aplicar commits con cherry-pick';

  @override
  String get gitUiRevertCommits => 'Revertir confirmaciones';

  @override
  String get gitUiCompareToFullRevisionID =>
      'Comparar con el ID de revisión completa';

  @override
  String gitUiTreeComparisonDirectionArg0TheRevisionEnteredHere(String arg0) {
    return 'Dirección de comparación de árboles: $arg0 → la revisión introducida aquí.';
  }

  @override
  String get gitUiEnterAFullValidObjectID =>
      'Introduzca un ID de objeto válido completo.';

  @override
  String gitUiArg0Arg1TreeComparison(String arg0, String arg1) {
    return '$arg0 → $arg1 · comparación de árboles';
  }

  @override
  String gitUiResetArg0ToArg1(String arg0, String arg1) {
    return 'Reiniciar $arg0 a $arg1';
  }

  @override
  String
  get gitUiMovesHEADCurrentBranchReflogDoesNotRecoverArbitraryUntracked =>
      'Mueve HEAD/la rama actual. El reflog no recupera contenido arbitrario sin seguimiento o sin guardar.';

  @override
  String get gitUiMoveHEADKeepIndexAndWorkingFiles =>
      'Mover HEAD; conservar el índice y los archivos de trabajo.';

  @override
  String get gitUiMoveHEADAndReplaceIndexKeepWorkingFiles =>
      'Mover HEAD y sustituir el índice; conservar los archivos de trabajo.';

  @override
  String
  get gitUiReplaceHEADIndexAndTrackedWorkingFilesMayOverwriteObstructing =>
      'Sustituir HEAD, el índice y los archivos de trabajo seguidos; puede sobrescribir archivos sin seguimiento que obstaculicen.';

  @override
  String get gitUiReplaceHEADIndexAndEligibleFilesRefuseIfLocalChanges =>
      'Sustituir HEAD, índice y archivos aptos; rechazar si se perderían cambios locales.';

  @override
  String gitUiResetWithArg0(String arg0) {
    return 'Reiniciar con $arg0?';
  }

  @override
  String gitUiArg0Arg1ReviewTheSelectedModeSEffectsBeforeApplying(
    String arg0,
    String arg1,
  ) {
    return '$arg0 → $arg1 Revise los efectos del modo seleccionado antes de aplicar.';
  }

  @override
  String gitUiResetArg0(String arg0) {
    return 'Reiniciar $arg0';
  }

  @override
  String gitUiTargetArg0(String arg0) {
    return 'Objetivo $arg0';
  }

  @override
  String get gitUiTagName => 'Nombre de etiqueta';

  @override
  String get gitUiAnnotatedTag => 'Etiqueta anotada';

  @override
  String get gitUiCryptographicSigning => 'Firma criptográfica';

  @override
  String get gitUiConfiguredPolicy => 'Política configurada';

  @override
  String get gitUiSignThisTag => 'Firma esta etiqueta';

  @override
  String get gitUiDoNotSign => 'No firmar';

  @override
  String get gitUiTagMessage => 'Mensaje de etiqueta';

  @override
  String get gitUiCreatesTheTagLocallyPublishSelectedTagsExplicitlyInPush =>
      'Crea la etiqueta localmente. Publique las etiquetas seleccionadas explícitamente en Push review.';

  @override
  String gitUiCompleteTreesArg0Arg1(String arg0, String arg1) {
    return 'Árboles completos: $arg0 → $arg1';
  }

  @override
  String get gitUiNextChangedFilePage => 'Siguiente página de archivo cambiado';

  @override
  String get gitUiReadOnlyRepositorySnapshotOpeningAFileNeverChecksOut =>
      'Instantánea del repositorio de sólo lectura. Abrir un archivo nunca comprueba esta revisión.';

  @override
  String get gitUiOpenReadOnlyVersion => 'Abrir versión de sólo lectura';

  @override
  String get gitUiRestoreThisPathWaitingForRepositoryStatus =>
      'Restaurar esta ruta... · Esperando el estado del repositorio';

  @override
  String get gitUiRestoreThisPath => 'Restaurar este camino...';

  @override
  String gitUiHistoryArg0(String arg0) {
    return 'Historia · $arg0';
  }

  @override
  String gitUiRestoreArg0(String arg0) {
    return '¿Restaurar $arg0?';
  }

  @override
  String gitUiReplaceThisWorkingPathWithRevisionArg0ExistingStagedContent(
    String arg0,
  ) {
    return 'Reemplace esta ruta de trabajo con la revisión $arg0. Se conserva el contenido escalonado existente.';
  }

  @override
  String get gitUiRestoreWorkingFile => 'Restaurar el archivo de trabajo';

  @override
  String gitUiFileHistoryFollowsRenamesArg0(String arg0) {
    return 'El historial de archivos sigue renombrando · $arg0';
  }

  @override
  String get gitUiBlameCommittedContent => 'Anotaciones · contenido confirmado';

  @override
  String get gitUiBlame => 'Anotaciones…';

  @override
  String gitUiArg0WorkingTree(String arg0) {
    return '$arg0 → Árbol de trabajo';
  }

  @override
  String get gitUiOpenReadOnlyHistoricalFile =>
      'Abrir archivo histórico de sólo lectura';

  @override
  String get gitUiCompareToCurrentFile => 'Comparar con el archivo actual';

  @override
  String get gitUiCompareToParent => 'Compara con los padres...';

  @override
  String gitUiCommittedArg0UnsavedEditorContentIsNotPartOfThese(String arg0) {
    return 'El contenido del editor no guardado de $arg0 no forma parte de estas anotaciones';
  }

  @override
  String gitUiHistoryFromArg0(String arg0) {
    return 'Historial de $arg0';
  }

  @override
  String get gitUiBoundary => ' · límite';

  @override
  String gitUiArg0Arg1OriginalLineArg2Arg3(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return '$arg0  $arg1\nLínea original $arg2$arg3';
  }

  @override
  String get gitUiPreviousLines => 'Líneas anteriores';

  @override
  String get gitUiNextLines => 'Siguientes líneas';

  @override
  String gitUiExplicitApplicationOrderDestinationArg0(String arg0) {
    return 'Orden explícita de aplicación · destino $arg0';
  }

  @override
  String get gitUiAddFullCommitObjectID =>
      'Añadir ID completo del objeto de confirmación';

  @override
  String get gitUiAddReviewedCommit => 'Añadir la confirmación revisada...';

  @override
  String get gitUiMoveEarlier => 'Mover antes';

  @override
  String get gitUiMoveLater => 'Mover más tarde';

  @override
  String get gitUiRemoveFromReviewedSequence =>
      'Eliminar de la secuencia revisada';

  @override
  String get gitUiApplyChangesWithoutCreatingCommits =>
      'Aplicar cambios sin crear confirmaciones';

  @override
  String get gitUiUseThisExplicitMainlineParentForMergeCommits =>
      'Utilice este padre de línea principal explícito para commits de fusión';

  @override
  String get gitUiEmptyOrAlreadyAppliedCommitsMayStopGitForAn =>
      'Los commits vacíos o ya aplicados pueden detener a Git para una decisión explícita de saltar o continuar.';

  @override
  String get gitUiRevertInReviewedOrder => 'Revertir en orden revisado';

  @override
  String get gitUiCherryPickInReviewedOrder =>
      'Piquete de cereza en orden revisado';

  @override
  String get gitUiReturnToFiles => 'Volver a archivos';

  @override
  String get gitUiGit => 'Git';

  @override
  String get gitUiCommit => 'Confirmar';

  @override
  String get gitUiBackToCommit => 'Volver a comisión';

  @override
  String get gitUiSelectAChangeToReview => 'Seleccione un cambio para revisar';

  @override
  String get gitUiLoadingBranch => 'Cargando rama...';

  @override
  String get gitUiBranchUnavailable => 'Sucursal no disponible';

  @override
  String get gitUiUnbornHEAD => 'HEAD sin commits';

  @override
  String gitUiDetachedHEADRevision(String revision) {
    return 'HEAD separado · $revision';
  }

  @override
  String get gitUiContinueAction => 'Continuar';

  @override
  String get gitUiPick => 'Conservar';

  @override
  String get gitUiReword => 'Cambiar mensaje';

  @override
  String get gitUiEdit => 'Editar';

  @override
  String get gitUiSquash => 'Combinar';

  @override
  String get gitUiFixup => 'Combinar sin mensaje';

  @override
  String get gitUiDrop => 'Omitir';

  @override
  String get gitUiAbort => 'Abortar';

  @override
  String get gitUiSkip => 'Saltar';

  @override
  String get gitUiQuit => 'Salir de la operación';

  @override
  String get gitUiSoft => 'Suave';

  @override
  String get gitUiMixed => 'Mixto';

  @override
  String get gitUiHard => 'Duro';

  @override
  String get gitUiKeep => 'Conservar';

  @override
  String get gitUiCreate => 'Crear';

  @override
  String get gitUiApplyStash => 'Aplicar reserva';

  @override
  String get gitUiPopStash => 'Aplicar y quitar reserva si tiene éxito';

  @override
  String get gitUiDropStashAction => 'Eliminar reserva';

  @override
  String get gitUiEditedResult => 'Resultado editado';

  @override
  String get gitUiLeftContent => 'Contenido izquierdo';

  @override
  String get gitUiRightContent => 'Contenido correcto';

  @override
  String get gitUiDeletePath => 'Eliminar ruta';

  @override
  String get gitUiSubmoduleCommit => 'Submódulo commit';

  @override
  String get gitUiPresentContent => 'Contenido disponible';

  @override
  String get gitUiAbsentContent => 'Ausente';

  @override
  String get gitUiBinaryContent => 'Contenido binario';

  @override
  String get gitUiTooLargeContent =>
      'El contenido supera el límite de visualización';

  @override
  String get gitUiUnavailableContent => 'Contenido no disponible';

  @override
  String get gitUiGitlinkContent => 'Puntero de submódulo';

  @override
  String get gitUiSymlinkContent => 'Enlace simbólico';

  @override
  String get gitUiNoOperation => 'Sin operación';

  @override
  String get gitUiCherryPickOperation => 'Seleccionar commit';

  @override
  String get gitUiRevertOperation => 'Revertir';

  @override
  String get gitUiApplyMailboxOperation => 'Aplicar parches';

  @override
  String get gitUiSquashOperation => 'Fusión Squash';

  @override
  String get gitUiUnmergedOperation => 'Índice sin fusionar';

  @override
  String get gitUiWaitingForPromptPhase => 'Esperando tu respuesta';

  @override
  String get gitUiStoppedPhase => 'Detenido para revisión';

  @override
  String get gitUiCompletedPhase => 'Completado';

  @override
  String get gitUiFailedPhase => 'Fallido';

  @override
  String get gitUiCancelledPhase => 'Cancelado';

  @override
  String get gitUiUncertainPhase => 'El resultado requiere conciliación';

  @override
  String gitUiStageVersion(String stage) {
    return 'Etapa de conflicto $stage';
  }

  @override
  String get gitUiGitMergePreview => 'Previsualización de la fusión de Git';

  @override
  String get gitUiNormalizedWorking => 'Árbol de trabajo · Git normalizado';

  @override
  String gitUiPercentValue(String value) {
    return '$value por ciento';
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
  String get gitUiUtf8Bom => 'UTF-8 con marca de orden de bytes (BOM)';

  @override
  String get gitUiUtf8NoBom => 'UTF-8 sin marca de orden de byte (BOM)';

  @override
  String get gitUiAddsBom =>
      'Esta edición añade una marca de orden de bytes UTF-8 (BOM) al inicio del archivo.';

  @override
  String get gitUiRemovesBom =>
      'Esta edición elimina la marca de orden de bytes UTF-8 (BOM) desde el inicio del archivo.';

  @override
  String get gitUiNoLineTerminators => 'Sin terminales de línea';

  @override
  String gitUiLineEndings(String format) {
    return 'Finales de línea $format';
  }

  @override
  String gitUiMixedLineEndings(String formats) {
    return 'Finales de línea mixtas ($formats)';
  }

  @override
  String gitUiNoFinalLf(String format) {
    return '$format · sin LF final';
  }

  @override
  String gitUiLineEndingChange(String before, String after) {
    return 'Los cambios de formato de terminación de línea de $before a $after. El texto del portapapeles puede utilizar diferentes terminaciones de línea del archivo original.';
  }

  @override
  String get gitUiGitFailure =>
      'Falló la operación de Git. Revise los diagnósticos a continuación.';

  @override
  String get gitUiAbortInline => 'Abortar';

  @override
  String get gitUiSkipInline => 'Saltar';

  @override
  String get gitUiQuitInline => 'dejar de fumar';

  @override
  String get gitUiMergeInline => 'Fusionar';

  @override
  String get gitUiRebaseInline => 'Reorganizar';

  @override
  String get gitUiCherryPickInline => 'Seleccionar commit';

  @override
  String get gitUiRevertInline => 'Revertir';

  @override
  String get gitUiApplyMailboxInline => 'aplicar parches';

  @override
  String get gitUiSquashInline => 'Combinar';

  @override
  String get gitUiUnmergedInline => 'sin fusionar';

  @override
  String get gitHostFetch => 'Obtener';

  @override
  String get gitHostRefreshGitStatus => 'Actualizar el estado de Git';

  @override
  String get gitHostCommitStaged => 'Entrega escalonada';

  @override
  String get gitHostGitBranches => 'Ramas de Git';

  @override
  String get gitHostReviewPush => 'Revision push';

  @override
  String get gitHostGit => 'Git';

  @override
  String get gitHostGitOperationsApplyToThisEntireRepositoryAndMay =>
      'Las operaciones de Git se aplican a este repositorio entero y pueden ejecutar sus ganchos, filtros, credenciales y herramientas de firma configuradas.';

  @override
  String get gitHostContentUnavailable => 'Contenido no disponible';

  @override
  String get gitHostInitializeRepository => 'Inicializar repositorio';

  @override
  String get gitHostCloneRepository => 'Clonar repositorio';

  @override
  String get gitHostInitializeHere => 'Inicialice aquí...';

  @override
  String get gitHostCloneRepository2 => 'Clonar repositorio…';

  @override
  String get gitHostGitLog => 'Registro de Git';

  @override
  String get gitUiAbsentPlaceholder => '(ausente)';

  @override
  String get gitUiUnborn => 'nonatos';

  @override
  String gitUiRebasedHistoryRevision(String revision) {
    return 'Historial reorganizado · $revision';
  }

  @override
  String gitUiCurrentHistoryRevision(String revision) {
    return 'Historial actual · $revision';
  }

  @override
  String gitUiReplayedCommitRevision(String revision) {
    return 'Commit reaplicado · $revision';
  }

  @override
  String gitUiIncomingContentRevision(String revision) {
    return 'Contenido entrante · $revision';
  }

  @override
  String get gitUiContentConflict => 'Conflicto de contenido';

  @override
  String get gitUiSubmoduleConflict => 'Conflicto de submódulos';

  @override
  String get gitUiSymlinkConflict => 'Conflicto de vínculos simbólicos';

  @override
  String get gitUiAddAddConflict => 'Agregado en ambos lados';

  @override
  String get gitUiModifyDeleteConflict =>
      'Modificado/suprimido o renombrado/suprimido';

  @override
  String gitUiConflictIdentity(String path, String kind) {
    return '$path · $kind';
  }
}
