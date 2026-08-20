// ignore_for_file: text_direction_code_point_in_literal, text_direction_code_point_in_comment

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

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
  String get pasteWithoutFormatting => 'Pegar sin formatear';

  @override
  String get preview => 'Vista previa';

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
      'Mostrar esta referencia de atajos de teclado';

  @override
  String get shortcutMarkdownAndHtmlDescription =>
      'Abrir la referencia de Markdown y HTML';

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
  String get editorFontSize => 'Tamaño de fuente del editor';

  @override
  String get validateOnEdit => 'Validar al editar';

  @override
  String get clearRecentWorkspaces => 'Borrar espacios de trabajo recientes';

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
  String get settingsWindowSectionTitle => 'Ventana';

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
  String get toc => 'Índice';

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
  String get newSiblingTopic => 'Nuevo tema del mismo nivel';

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
  String get reviewUsages => 'Revisar usos';

  @override
  String get deleteTopicFile => 'Eliminar archivo del tema';

  @override
  String get removeAction => 'Quitar';

  @override
  String topicRemovalSummary(String topic) {
    return 'Quita «$topic» de la instancia seleccionada. Se conservará el archivo del tema.';
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
  String get topicIsStartPageRemovalWarning =>
      'Este tema se usa como página de inicio de una instancia. Revisa sus usos y asigna otra página de inicio antes de continuar.';

  @override
  String topicUsagesCount(int count) {
    return 'Usos ($count)';
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
  String get setRedirectTo => 'Redirigir a';

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
  String get sourceSearchCaseSensitive => 'Distinguir mayúsculas y minúsculas';

  @override
  String get sourceSearchWholeWord => 'Palabra completa';

  @override
  String get sourceSearchRegex => 'Expresión regular';

  @override
  String get sourceSearchInvalidRegex => 'Expresión regular no válida';

  @override
  String get sourceLargeFileFeaturesPaused =>
      'Archivo grande: el resaltado y el plegado están en pausa';

  @override
  String get noPreview => 'Sin vista previa';

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
    return 'El tema de inicio $topic no se puede eliminar. Elija primero otra página de inicio.';
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
          'Los archivos seleccionados que están bajo seguimiento se restaurarán desde Git.',
      one:
          'El archivo seleccionado que está bajo seguimiento se restaurará desde Git.',
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
  String get gitProjectHistory => 'Proyecto';

  @override
  String get gitFileHistory => 'Archivo actual';

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
  String get gitErrorAuthentication =>
      'La autenticación de Git ha fallado. En el snap, los remotos SSH pueden requerir que se conecte la interfaz ssh-keys.';

  @override
  String get gitErrorNetwork => 'La operación de red de Git ha fallado.';

  @override
  String get gitErrorConflict => 'Git ha informado de conflictos sin resolver.';

  @override
  String get gitErrorCommandFailed => 'El comando de Git ha fallado.';

  @override
  String get markdownAndHtml => 'Markdown y HTML';

  @override
  String get markdownHtmlMarkdownBlocks => 'Bloques Markdown';

  @override
  String get markdownHtmlMarkdownBlocksDescription =>
      'Estructuras de bloque admitidas en el código Markdown y la vista previa.';

  @override
  String get markdownHtmlInlineFormatting => 'Markdown en línea';

  @override
  String get markdownHtmlInlineFormattingDescription =>
      'Formato dentro de párrafos, elementos de lista y celdas de tabla.';

  @override
  String get markdownHtmlRawHtmlBlocks => 'Bloques HTML sin procesar';

  @override
  String get markdownHtmlRawHtmlBlocksDescription =>
      'Etiquetas HTML de bloque seguras renderizadas con widgets de vista previa de BusyMark.';

  @override
  String get markdownHtmlRawHtmlInline =>
      'Etiquetas HTML sin procesar en línea';

  @override
  String get markdownHtmlRawHtmlInlineDescription =>
      'Etiquetas HTML en línea seguras renderizadas sin mostrar las etiquetas literales.';

  @override
  String get markdownHtmlSafety => 'Reglas de seguridad';

  @override
  String get markdownHtmlSafetyDescription =>
      'El HTML sin procesar se analiza y sanea antes de la vista previa.';

  @override
  String get markdownHtmlHeadings => 'Encabezados';

  @override
  String get markdownHtmlParagraphs => 'Párrafos';

  @override
  String get markdownHtmlLists => 'Listas';

  @override
  String get markdownHtmlHtmlContainers => 'Contenedores';

  @override
  String get markdownHtmlHtmlTextBlocks => 'Bloques de texto';

  @override
  String get markdownHtmlHtmlFigures => 'Figuras e imágenes';

  @override
  String get markdownHtmlHtmlPreformatted => 'Código preformateado';

  @override
  String get markdownHtmlHtmlDisclosure => 'Bloques desplegables';

  @override
  String get markdownHtmlHtmlDescriptionLists => 'Listas de descripción';

  @override
  String get markdownHtmlHtmlFormattingTags => 'Etiquetas de formato';

  @override
  String get markdownHtmlHtmlInlineCodeTags => 'Etiquetas de código en línea';

  @override
  String get markdownHtmlHtmlNeutralInlineTags =>
      'Etiquetas semánticas de texto';

  @override
  String get markdownHtmlSanitizedPreview => 'Vista previa saneada';

  @override
  String get markdownHtmlSanitizedPreviewDescription =>
      'El HTML permitido se convierte en bloques de vista previa de BusyMark, no se renderiza en un navegador.';

  @override
  String get markdownHtmlSourcePreserved => 'Se conserva el código fuente';

  @override
  String get markdownHtmlSourcePreservedDescription =>
      'El HTML sin procesar no editado se guarda exactamente como texto fuente.';

  @override
  String get markdownHtmlMarkdownInsideHtml => 'Markdown dentro de HTML';

  @override
  String get markdownHtmlMarkdownInsideHtmlDescription =>
      'Los marcadores Markdown dentro de HTML sin procesar se muestran como texto literal.';

  @override
  String get markdownHtmlBlockedContent => 'Contenido activo bloqueado';

  @override
  String get markdownHtmlBlockedContentDescription =>
      'Se bloquean scripts, estilos, marcos, formularios, SVG, MathML, eventos y atributos inseguros.';

  @override
  String get markdownHtmlSafeUrls => 'Solo URLs seguras';

  @override
  String get markdownHtmlSafeUrlsDescription =>
      'Los enlaces permiten http, https, mailto, tel, URLs relativas y fragmentos; los esquemas inseguros se bloquean.';

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
  String get exportingPdf => 'Exportando PDF…';

  @override
  String get fileTypePdf => 'Documento PDF';

  @override
  String pdfExported(String fileName) {
    return 'Se exportó $fileName.';
  }

  @override
  String pdfExportedWithWarnings(String fileName, int count) {
    return 'Se exportó $fileName. Imágenes que no se pudieron incluir: $count.';
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
  String get openTocFile => 'Abrir archivo de TOC';

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
  String get writersidePdfExportDescription =>
      'Elija una instancia y la configuración de PDF. BusyMark usa el compilador oficial de Writerside de JetBrains.';

  @override
  String get writersidePdfContent => 'Contenido de la exportación';

  @override
  String get writersidePdfSettings => 'Configuración de PDF';

  @override
  String get writersidePdfConfigureHere => 'Configurar para esta exportación';

  @override
  String get writersidePdfProjectConfiguration =>
      'Usar la configuración del proyecto';

  @override
  String get writersidePdfConfigurationFile =>
      'Archivo de configuración de PDF';

  @override
  String get writersidePdfPage => 'Página';

  @override
  String get writersidePdfKeymap => 'Mapa de teclas';

  @override
  String get writersidePdfNoKeymap => 'Sin mapa de teclas';

  @override
  String get writersidePdfTocTitle => 'Título de la tabla de contenido';

  @override
  String get writersidePdfCover => 'Portada';

  @override
  String get writersidePdfIncludeCover => 'Incluir portada';

  @override
  String get writersidePdfCoverTitle => 'Título de portada';

  @override
  String get writersidePdfCoverDescription => 'Descripción de portada';

  @override
  String get writersidePdfCopyright => 'Derechos de autor';

  @override
  String get writersidePdfCoverLogo => 'Logotipo de portada';

  @override
  String get writersidePdfChooseCoverLogo => 'Elegir logotipo de portada';

  @override
  String get writersidePdfHeaderAndFooter => 'Encabezado y pie de página';

  @override
  String get writersidePdfHeader => 'Encabezado';

  @override
  String get writersidePdfFooter => 'Pie de página';

  @override
  String get writersidePdfAdvancedDescription =>
      'Estos valores asignan el módulo abierto al diseño de fuentes del compilador.';

  @override
  String get writersidePdfModuleName => 'Nombre del módulo';

  @override
  String get writersidePdfSourceRoot => 'Raíz de fuentes';

  @override
  String get writersidePdfChooseSourceRoot => 'Elegir raíz de fuentes';

  @override
  String get writersidePdfBuilderVersion => 'Versión del compilador';

  @override
  String get writersidePdfAllowNetwork => 'Permitir red durante la compilación';

  @override
  String get writersidePdfAllowNetworkDescription =>
      'Desactivado de forma predeterminada. Actívelo solo si el proyecto necesita deliberadamente recursos de compilación remotos.';

  @override
  String get writersidePdfModuleNameRequired =>
      'Introduzca el nombre del módulo.';

  @override
  String get writersidePdfSourceRootRequired => 'Elija la raíz de fuentes.';

  @override
  String get writersidePdfBuilderVersionInvalid =>
      'Introduzca una versión válida del compilador.';

  @override
  String get writersidePdfBuilderRequired =>
      'Se requiere el compilador de Writerside';

  @override
  String writersidePdfBuilderDownloadDescription(String image) {
    return 'BusyMark usa la imagen de contenedor oficial $image. ¿Descargarla ahora? La imagen es grande y Docker la almacena.';
  }

  @override
  String get writersidePdfDownloadingBuilder =>
      'Descargando el compilador de Writerside…';

  @override
  String get exportingWritersidePdf => 'Exportando PDF de Writerside…';

  @override
  String get writersidePdfDockerUnavailable =>
      'Docker es necesario para exportar Writerside a PDF. Instale e inicie Docker y vuelva a intentarlo.';

  @override
  String get writersidePdfBuilderUnavailable =>
      'La imagen solicitada del compilador de Writerside no está disponible.';

  @override
  String get writersidePdfConfigurationInvalid =>
      'La configuración PDF de Writerside no es válida.';

  @override
  String get writersidePdfBuildFailed =>
      'El compilador de Writerside no pudo crear el PDF.';

  @override
  String get writersidePdfInvalidOutput =>
      'El compilador de Writerside no produjo un PDF válido.';

  @override
  String get ai => 'IA';

  @override
  String get aiLocalOllama => 'Ollama local';

  @override
  String get aiDisabled => 'Desactivado';

  @override
  String get aiLocalOnlyDescription =>
      'La edición con IA solo se ejecuta de forma explícita. BusyMark envía únicamente el contexto mostrado al proveedor seleccionado y nunca aplica una propuesta sin revisarla.';

  @override
  String get aiProvider => 'Proveedor de IA';

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
  String get aiNoModels =>
      'Ollama está en ejecución, pero no se encontraron modelos instalados.';

  @override
  String get aiConnectionFailed =>
      'BusyMark no pudo verificar la generación de texto con IA.';

  @override
  String get aiConfigureFirst =>
      'Active un proveedor de IA y verifique un modelo en Configuración → IA.';

  @override
  String get aiRewrite => 'Reescribir';

  @override
  String get aiShorten => 'Acortar';

  @override
  String get aiSummarize => 'Resumir';

  @override
  String get aiChangeTone => 'Cambiar tono…';

  @override
  String get aiTranslate => 'Traducir…';

  @override
  String get aiProofread => 'Corregir';

  @override
  String get aiDraft => 'Redactar…';

  @override
  String get aiSelectionRequired => 'Seleccione texto para esta acción de IA.';

  @override
  String get aiTonePrompt => 'Describa el tono deseado';

  @override
  String get aiLanguagePrompt => 'Idioma de destino';

  @override
  String get aiDraftPrompt => '¿Qué debe redactar BusyMark?';

  @override
  String get aiGenerating => 'Generando propuesta…';

  @override
  String get aiProposal => 'Propuesta de IA';

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
  String get aiPrivacyDisabled =>
      'La IA está desactivada. BusyMark nunca envía contenido del documento sin una acción de IA explícita.';

  @override
  String get aiPrivacyLocal =>
      'BusyMark solo envía el contexto mostrado en el diálogo de revisión al servicio Ollama local configurado. Las propuestas nunca se aplican sin revisión.';

  @override
  String aiPrivacyCloud(String provider) {
    return 'BusyMark solo envía el contexto mostrado en el diálogo de revisión a $provider. Las solicitudes no conservan estado y las propuestas nunca se aplican sin revisión.';
  }

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
  String get aiExplainCode => 'Explicar código';

  @override
  String get aiImproveCode => 'Mejorar código';

  @override
  String get aiDraftCommitMessage => 'Redactar mensaje de commit';

  @override
  String get aiCodeBlockRequired =>
      'Sitúe primero el cursor en un bloque de código delimitado.';

  @override
  String get aiDrafting => 'Redactando…';

  @override
  String get aiDraftWithAi => 'Redactar con IA';

  @override
  String get generateOrUpdateMarkdownToc =>
      'Generar/actualizar tabla de contenido';

  @override
  String get markdownTocTitle => 'Tabla de contenido';

  @override
  String markdownTocUpdated(int count) {
    return 'Tabla de contenido actualizada con $count entradas.';
  }

  @override
  String get markdownTocNoHeadings =>
      'Añada al menos un encabezado de sección antes de generar una tabla de contenido.';

  @override
  String get markdownTocMalformedMarkers =>
      'Los marcadores de la tabla de contenido de BusyMark faltan, están duplicados o no siguen el orden correcto.';

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
}
