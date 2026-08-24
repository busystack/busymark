// ignore_for_file: text_direction_code_point_in_literal, text_direction_code_point_in_comment

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'BusyMark';

  @override
  String get appSubtitle =>
      'Editor de arquivos Markdown e projetos de documentação compatíveis com o Writerside.';

  @override
  String get aboutBusyMark => 'Sobre BusyMark';

  @override
  String get aboutTagline => 'Editor de Markdown e Writerside';

  @override
  String get aboutLicenseLabel => 'Licença';

  @override
  String get aboutLicenseName => 'Apache License 2.0';

  @override
  String get aboutWebsite => 'Site';

  @override
  String get aboutSourceCode => 'Código-fonte';

  @override
  String get reportIssue => 'Comunicar um problema';

  @override
  String get feedbackCategory => 'Categoria';

  @override
  String get feedbackChooseCategory => 'Escolha uma categoria';

  @override
  String get feedbackCategoryProblem => 'Problema ou erro';

  @override
  String get feedbackCategoryFeature => 'Pedido de funcionalidade';

  @override
  String get feedbackCategoryPrivacySecurity =>
      'Preocupação com privacidade ou segurança';

  @override
  String get feedbackCategoryUsability => 'Preocupação de usabilidade';

  @override
  String get feedbackCategoryOther => 'Outro';

  @override
  String get feedbackSubject => 'Assunto';

  @override
  String get feedbackMessage => 'Mensagem detalhada';

  @override
  String get feedbackReplyEmail => 'E-mail para resposta (opcional)';

  @override
  String get feedbackIncludeTechnicalDetails => 'Incluir detalhes técnicos';

  @override
  String get feedbackTechnicalDetailsDisclosure =>
      'Quando esta opção está ativada, são adicionados apenas a versão do sistema operativo Linux e as definições regionais da aplicação BusyMark. Não são anexados registos, ficheiros, dados de conta nem outros diagnósticos.';

  @override
  String get feedbackSubmit => 'Enviar';

  @override
  String get feedbackSubmitting => 'A enviar…';

  @override
  String get feedbackCategoryRequired => 'Escolha uma categoria.';

  @override
  String get feedbackSubjectLength =>
      'O assunto deve ter entre 3 e 120 carateres.';

  @override
  String get feedbackMessageLength =>
      'A mensagem deve ter entre 10 e 5000 carateres.';

  @override
  String get feedbackReplyEmailInvalid =>
      'Introduza um endereço de e-mail válido ou deixe este campo vazio.';

  @override
  String get feedbackConnectionFailure =>
      'O BusyMark não conseguiu estabelecer ligação. Verifique a ligação à Internet e tente novamente.';

  @override
  String get feedbackTimeoutFailure =>
      'O pedido excedeu o tempo limite. Tente novamente.';

  @override
  String get feedbackRateLimitedFailure =>
      'Foram enviados demasiados relatórios a partir desta ligação. Aguarde e tente novamente.';

  @override
  String get feedbackRejectedFailure =>
      'O servidor rejeitou o relatório. Verifique os campos do formulário e tente novamente.';

  @override
  String get feedbackServerFailure =>
      'O servidor não conseguiu aceitar o relatório. Tente novamente mais tarde.';

  @override
  String feedbackSuccess(String id) {
    return 'Comentários enviados. ID de referência: $id';
  }

  @override
  String get advanced => 'Avançado';

  @override
  String get addToGit => 'Adicionar ao Git';

  @override
  String get appearance => 'Aparência';

  @override
  String get apply => 'Aplicar';

  @override
  String get back => 'Voltar';

  @override
  String get bottomLeft => 'Canto inferior esquerdo';

  @override
  String get bottomRight => 'Canto inferior direito';

  @override
  String get cancel => 'Cancelar';

  @override
  String get choose => 'Escolher';

  @override
  String get chooseLocation => 'Escolher local';

  @override
  String get copy => 'Copiar';

  @override
  String get copyName => 'Copiar nome';

  @override
  String get copyFileName => 'Copiar nome do arquivo';

  @override
  String get copyPath => 'Copiar caminho';

  @override
  String get create => 'Criar';

  @override
  String get creating => 'Criando...';

  @override
  String get cut => 'Recortar';

  @override
  String get promoteSection => 'Promover seção';

  @override
  String get demoteSection => 'Rebaixar seção';

  @override
  String get moveSectionUp => 'Mover seção para cima';

  @override
  String get moveSectionDown => 'Mover seção para baixo';

  @override
  String get confirmDeleteSectionTitle => 'Excluir seção?';

  @override
  String confirmDeleteSectionMessage(String name) {
    return 'Excluir “$name” e todo o conteúdo da seção? Isso não pode ser desfeito.';
  }

  @override
  String get darkTheme => 'Escuro';

  @override
  String get delete => 'Excluir';

  @override
  String get discard => 'Descartar';

  @override
  String get editor => 'Editor';

  @override
  String get file => 'Arquivo';

  @override
  String get fileHistory => 'Histórico do arquivo';

  @override
  String get folder => 'Pasta';

  @override
  String get insert => 'Inserir';

  @override
  String get keyboardShortcuts => 'Atalhos de teclado';

  @override
  String get commandPalette => 'Paleta de comandos';

  @override
  String get commandPaletteHint => 'Digite um comando';

  @override
  String get commandPaletteEmpty => 'Nenhum comando correspondente';

  @override
  String get commandUnavailableInContext =>
      'Este comando não está disponível no contexto atual.';

  @override
  String get lightTheme => 'Claro';

  @override
  String get mainMenu => 'Menu principal';

  @override
  String get fullScreen => 'Tela cheia';

  @override
  String get markdown => 'Markdown';

  @override
  String get open => 'Abrir';

  @override
  String get openInFiles => 'Abrir em Arquivos';

  @override
  String get pathActions => 'Ações do caminho';

  @override
  String get outline => 'Estrutura';

  @override
  String get overwrite => 'Sobrescrever';

  @override
  String get paste => 'Colar';

  @override
  String get pasteWithoutFormatting => 'Colar sem formatar';

  @override
  String get reading => 'Leitura';

  @override
  String get recent => 'Recentes';

  @override
  String get redo => 'Refazer';

  @override
  String get save => 'Salvar';

  @override
  String get search => 'Pesquisar';

  @override
  String get selectAll => 'Selecionar tudo';

  @override
  String get settings => 'Configurações';

  @override
  String get source => 'Código-fonte';

  @override
  String get split => 'Dividido';

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
  String get toggleSidebar => 'Painel lateral';

  @override
  String get topLeft => 'Canto superior esquerdo';

  @override
  String get topRight => 'Canto superior direito';

  @override
  String get undo => 'Desfazer';

  @override
  String get validate => 'Validar';

  @override
  String get validation => 'Validação';

  @override
  String get viewMode => 'Modo de exibição';

  @override
  String get welcome => 'Bem-vindo';

  @override
  String get writerside => 'Writerside';

  @override
  String get xml => 'XML';

  @override
  String get fileTypeMarkdown => 'Markdown';

  @override
  String get fileTypeImages => 'Imagens';

  @override
  String get openMarkdownFile => 'Abrir arquivo Markdown';

  @override
  String get markdownFileExtensions => '.md ou .markdown';

  @override
  String get openFolderOrWritersideProject =>
      'Abrir pasta ou projeto Writerside';

  @override
  String get markdownFolderOrWritersideProject =>
      'Pasta Markdown ou projeto compatível com Writerside';

  @override
  String get noOpenFile => 'Nenhum arquivo aberto';

  @override
  String get shortcutDeleteTreeItemDescription =>
      'Excluir o item selecionado em Arquivos ou remover o tópico selecionado do sumário';

  @override
  String get shortcutGroupGeneral => 'Geral';

  @override
  String get shortcutNewDocument => 'Criar';

  @override
  String get shortcutNewDocumentDescription =>
      'Criar arquivo Markdown ou projeto Writerside';

  @override
  String get shortcutOpenDescription =>
      'Abrir um arquivo Markdown, uma pasta ou um projeto Writerside';

  @override
  String get shortcutSaveDescription => 'Salvar o documento atual';

  @override
  String get shortcutSearchDescription =>
      'Pesquisar no espaço de trabalho atual';

  @override
  String get shortcutKeyboardShortcutsDescription =>
      'Mostrar esta referência de atalhos de teclado';

  @override
  String get shortcutMarkdownAndHtmlDescription =>
      'Abrir a referência de Markdown e HTML';

  @override
  String get shortcutSettingsDescription =>
      'Abrir as configurações do BusyMark';

  @override
  String get shortcutNextTab => 'Próxima guia';

  @override
  String get shortcutNextTabDescription => 'Ir para a próxima guia aberta';

  @override
  String get shortcutPreviousTab => 'Guia anterior';

  @override
  String get shortcutPreviousTabDescription => 'Ir para a guia aberta anterior';

  @override
  String get shortcutCloseTab => 'Fechar guia';

  @override
  String get shortcutCloseTabDescription => 'Fechar a guia ativa';

  @override
  String get shortcutCloseAllTabs => 'Fechar todas as guias';

  @override
  String get shortcutCloseAllTabsDescription => 'Fechar todas as guias abertas';

  @override
  String get shortcutGroupTextEditing => 'Edição de texto';

  @override
  String get shortcutSelectAllDescription =>
      'No modo Código-fonte, selecionar todo o texto; no modo Editor, pressionar duas vezes para selecionar todos os blocos';

  @override
  String get shortcutCutDescription => 'Recortar o texto selecionado';

  @override
  String get shortcutCopyDescription => 'Copiar o texto selecionado';

  @override
  String get shortcutPasteDescription => 'Colar da área de transferência';

  @override
  String get shortcutPastePlainTextDescription =>
      'Colar o texto da área de transferência sem formatação';

  @override
  String get shortcutUndoDescription => 'Desfazer a última edição';

  @override
  String get shortcutRedoDescription => 'Refazer a última edição desfeita';

  @override
  String get shortcutInsertIndentation => 'Inserir recuo';

  @override
  String get shortcutInsertIndentationDescription =>
      'Inserir recuo na posição do cursor';

  @override
  String get shortcutOutdentSource => 'Diminuir recuo do código-fonte';

  @override
  String get shortcutOutdentSourceDescription =>
      'Remover um nível de recuo no modo Código-fonte';

  @override
  String get shortcutEscape =>
      'Fechar a pesquisa ou limpar a seleção de blocos';

  @override
  String get shortcutEscapeDescription =>
      'Fechar a pesquisa do espaço de trabalho ou limpar uma seleção de blocos no modo Editor';

  @override
  String get shortcutGroupFormatting => 'Formatação';

  @override
  String get shortcutBoldDescription => 'Alternar negrito no texto selecionado';

  @override
  String get shortcutItalicDescription =>
      'Alternar itálico no texto selecionado';

  @override
  String get shortcutUnderlineDescription =>
      'Alternar sublinhado no texto selecionado';

  @override
  String get shortcutLinkDescription => 'Inserir ou editar um link';

  @override
  String get shortcutInlineCodeDescription =>
      'Alternar código embutido no texto selecionado';

  @override
  String get shortcutStrikethroughDescription =>
      'Alternar tachado no texto selecionado';

  @override
  String get shortcutGroupBlocks => 'Blocos';

  @override
  String get shortcutParagraphDescription =>
      'Definir o bloco atual como parágrafo';

  @override
  String get shortcutHeading1Description =>
      'Definir o bloco atual como Título 1';

  @override
  String get shortcutHeading2Description =>
      'Definir o bloco atual como Título 2';

  @override
  String get shortcutHeading3Description =>
      'Definir o bloco atual como Título 3';

  @override
  String get shortcutHeading4Description =>
      'Definir o bloco atual como Título 4';

  @override
  String get shortcutHeading5Description =>
      'Definir o bloco atual como Título 5';

  @override
  String get shortcutHeading6Description =>
      'Definir o bloco atual como Título 6';

  @override
  String get shortcutGroupLists => 'Listas';

  @override
  String get numberedList => 'Lista numerada';

  @override
  String get shortcutNumberedListDescription =>
      'Alternar formatação de lista numerada';

  @override
  String get bulletedList => 'Lista com marcadores';

  @override
  String get shortcutBulletedListDescription =>
      'Alternar formatação de lista com marcadores';

  @override
  String get checklist => 'Lista de verificação';

  @override
  String get shortcutChecklistDescription =>
      'Alternar formatação de lista de verificação';

  @override
  String get shortcutGroupSidebar => 'Barra lateral';

  @override
  String get sidebarViewMenu => 'Visualização da barra lateral';

  @override
  String get createMarkdownFile => 'Criar arquivo Markdown';

  @override
  String get createMarkdownFileDescription =>
      'Iniciar um documento Markdown local não salvo';

  @override
  String get createWritersideProject => 'Criar projeto Writerside';

  @override
  String get createWritersideProjectDescription =>
      'Iniciar um projeto local compatível com Writerside';

  @override
  String get defaultProjectName => 'Documentação';

  @override
  String get defaultInstanceName => 'Guia do usuário';

  @override
  String get defaultStartTopicTitle => 'Primeiros passos';

  @override
  String get projectName => 'Nome do projeto';

  @override
  String get directoryName => 'Nome do diretório';

  @override
  String get instanceName => 'Nome da instância';

  @override
  String get instanceId => 'ID da instância';

  @override
  String get startTopicTitle => 'Título do tópico inicial';

  @override
  String get location => 'Local';

  @override
  String get projectNameRequired => 'O nome do projeto é obrigatório.';

  @override
  String get directoryNameRequired => 'O nome do diretório é obrigatório.';

  @override
  String get useSingleSafeDirectoryName =>
      'Use um único nome de diretório seguro.';

  @override
  String get useLowercaseIdentifier =>
      'Use um identificador em minúsculas com letras, números, sublinhados ou hifens.';

  @override
  String get startTopicTitleRequired =>
      'O título do tópico inicial é obrigatório.';

  @override
  String get createWritersideProjectFailed =>
      'Não foi possível criar o projeto Writerside.';

  @override
  String get settingsTitle => 'Configurações do BusyMark';

  @override
  String get autoSave => 'Salvamento automático';

  @override
  String get autoSaveDescription =>
      'Salva automaticamente as alterações do arquivo após um curto período de inatividade.';

  @override
  String get wordWrap => 'Quebra de linha';

  @override
  String get editorFontSize => 'Tamanho da fonte do editor';

  @override
  String get validateOnEdit => 'Validar ao editar';

  @override
  String get clearRecentWorkspaces => 'Limpar espaços de trabalho recentes';

  @override
  String get editingButtonsPosition => 'Posição dos botões de edição';

  @override
  String get editingButtonsPositionDescription =>
      'Escolha onde os botões flutuantes de edição WYSIWYG aparecem.';

  @override
  String get editingButtonsDirection => 'Orientação dos botões de edição';

  @override
  String get editingButtonsDirectionDescription =>
      'Escolha se os botões flutuantes de edição WYSIWYG ficam dispostos horizontalmente ou verticalmente.';

  @override
  String get horizontal => 'Horizontal';

  @override
  String get vertical => 'Vertical';

  @override
  String get privacy => 'Privacidade';

  @override
  String get allowRemoteImages => 'Carregar imagens remotas';

  @override
  String get allowRemoteImagesDescription =>
      'Permitir que a pré-visualização do Markdown e o editor carreguem imagens de URLs HTTP e HTTPS.';

  @override
  String get clearRemoteImagePermissions =>
      'Limpar permissões de imagens remotas';

  @override
  String get clearRemoteImagePermissionsDescription =>
      'Esquecer os espaços de trabalho autorizados a carregar imagens remotas.';

  @override
  String get clearGitWorkspaceTrust =>
      'Limpar espaços de trabalho confiáveis para o Git';

  @override
  String get clearGitWorkspaceTrustDescription =>
      'Perguntar antes de ativar recursos do Git em espaços de trabalho considerados confiáveis anteriormente.';

  @override
  String get settingsWindowSectionTitle => 'Janela';

  @override
  String get settingsConfirmCloseWithUnsavedChangesTitle =>
      'Confirmar antes de fechar com alterações não salvas';

  @override
  String get settingsConfirmCloseWithUnsavedChangesDescription =>
      'Perguntar antes de fechar o BusyMark quando documentos tiverem alterações não salvas.';

  @override
  String get closeUnsavedChangesTitle => 'Alterações não salvas';

  @override
  String get closeUnsavedChangesSingleMessage =>
      'Este documento tem alterações não salvas. Salvar as alterações antes de fechar o BusyMark?';

  @override
  String closeUnsavedChangesMultipleMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count documentos têm alterações não salvas. Salvar as alterações antes de fechar o BusyMark?',
      one:
          '1 documento tem alterações não salvas. Salvar as alterações antes de fechar o BusyMark?',
      zero: 'Salvar as alterações antes de fechar o BusyMark?',
    );
    return '$_temp0';
  }

  @override
  String get closeUnsavedChangesCancel => 'Cancelar';

  @override
  String get closeUnsavedChangesDiscard => 'Descartar';

  @override
  String get closeUnsavedChangesSave => 'Salvar';

  @override
  String get currentFile => 'arquivo atual';

  @override
  String get unsavedChanges => 'Alterações não salvas';

  @override
  String unsavedChangesMessage(String fileName) {
    return 'Você tem alterações não salvas em $fileName. Salvá-las antes de continuar?';
  }

  @override
  String unsavedChangesMultipleMessage(int count) {
    return 'Há $count documentos com alterações não salvas. Deseja salvá-los antes de continuar?';
  }

  @override
  String get fileChangedOnDisk => 'Arquivo alterado no disco';

  @override
  String get fileChangedOnDiskMessage =>
      'Este arquivo foi alterado no disco desde que foi aberto. Sobrescrever?';

  @override
  String get untitledMarkdownFileName => 'Sem título.md';

  @override
  String get unorderedList => 'Lista não ordenada';

  @override
  String get orderedList => 'Lista ordenada';

  @override
  String get taskList => 'Lista de tarefas';

  @override
  String get toggleTaskChecked => 'Marcar/desmarcar tarefa';

  @override
  String get indentListItem => 'Recuar item da lista';

  @override
  String get outdentListItem => 'Remover recuo do item da lista';

  @override
  String get blockquote => 'Citação em bloco';

  @override
  String get codeBlock => 'Bloco de código';

  @override
  String get codeBlockLanguage => 'Linguagem do bloco de código';

  @override
  String get image => 'Imagem';

  @override
  String get video => 'Vídeo';

  @override
  String get openVideo => 'Reproduzir vídeo';

  @override
  String get pauseVideo => 'Pausar vídeo';

  @override
  String get videoUnavailable => 'Vídeo indisponível';

  @override
  String get videoPreview => 'Pré-visualização do vídeo';

  @override
  String get diagnosticWritersideVideoMissingSource =>
      'O vídeo não tem o atributo src.';

  @override
  String diagnosticWritersideVideoUnsupportedSource(String source) {
    return 'Fonte de vídeo não suportada: $source';
  }

  @override
  String diagnosticWritersideVideoMissingFile(String source) {
    return 'O ficheiro de vídeo não existe: $source';
  }

  @override
  String diagnosticWritersideVideoMissingPreview(String preview) {
    return 'A imagem de pré-visualização do vídeo não existe: $preview';
  }

  @override
  String get inlineImage => 'Imagem embutida';

  @override
  String get table => 'Tabela';

  @override
  String get htmlBlock => 'Bloco HTML';

  @override
  String get htmlContentDefault => 'Conteúdo HTML';

  @override
  String get shortcutHtmlBlockDescription => 'Inserir ou editar um bloco HTML';

  @override
  String get renderedHtml => 'HTML renderizado';

  @override
  String get editHtml => 'Editar HTML';

  @override
  String get htmlSource => 'Código-fonte HTML';

  @override
  String get thematicBreak => 'Separador temático';

  @override
  String get bold => 'Negrito';

  @override
  String get italic => 'Itálico';

  @override
  String get underline => 'Sublinhado';

  @override
  String get strikethrough => 'Tachado';

  @override
  String get inlineCode => 'Código embutido';

  @override
  String get link => 'Link';

  @override
  String get hardLineBreak => 'Quebra de linha forçada';

  @override
  String get textStyle => 'Estilo de texto';

  @override
  String get paragraph => 'Parágrafo';

  @override
  String get heading1 => 'Título 1';

  @override
  String get heading2 => 'Título 2';

  @override
  String get heading3 => 'Título 3';

  @override
  String get heading4 => 'Título 4';

  @override
  String get heading5 => 'Título 5';

  @override
  String get heading6 => 'Título 6';

  @override
  String headingLevelAbbreviation(int level) {
    return 'H$level';
  }

  @override
  String get deleteTable => 'Excluir tabela';

  @override
  String tableColumnNumber(int columnNumber) {
    return 'Coluna $columnNumber';
  }

  @override
  String get insertColumnLeft => 'Inserir coluna à esquerda';

  @override
  String get insertColumnRight => 'Inserir coluna à direita';

  @override
  String get deleteColumn => 'Excluir coluna';

  @override
  String get tableAlignmentUnspecified => 'Alinhamento: não especificado';

  @override
  String get tableAlignmentLeft => 'Alinhamento: esquerda';

  @override
  String get tableAlignmentCenter => 'Alinhamento: centro';

  @override
  String get tableAlignmentRight => 'Alinhamento: direita';

  @override
  String tableRowNumber(int rowNumber) {
    return 'Linha $rowNumber';
  }

  @override
  String get insertRowAbove => 'Inserir linha acima';

  @override
  String get insertRowBelow => 'Inserir linha abaixo';

  @override
  String get deleteRow => 'Excluir linha';

  @override
  String get tableHeaderHint => 'Cabeçalho';

  @override
  String get tableCellHint => 'Célula';

  @override
  String get language => 'Linguagem';

  @override
  String get hideEditingButtons => 'Ocultar botões de edição';

  @override
  String get showEditingButtons => 'Mostrar botões de edição';

  @override
  String get altText => 'Texto alternativo';

  @override
  String get editorPlaceholderText => 'texto';

  @override
  String get editorPlaceholderCode => 'código';

  @override
  String get editorPlaceholderAltText => 'texto alternativo';

  @override
  String get describeTheImage => 'Descreva a imagem';

  @override
  String get columns => 'Colunas';

  @override
  String get rows => 'Linhas';

  @override
  String tableHeaderNumber(int columnNumber) {
    return 'Cabeçalho $columnNumber';
  }

  @override
  String get tableCellDefault => 'Célula';

  @override
  String get noImageSource => 'Nenhuma origem de imagem';

  @override
  String get remoteImageBlocked => 'Imagem remota bloqueada';

  @override
  String get remoteImageBlockedTooltip =>
      'Escolha se o BusyMark pode carregar imagens remotas.';

  @override
  String get remoteImagesBlockedTitle => 'As imagens remotas estão bloqueadas';

  @override
  String get remoteImagesBlockedMessage =>
      'Este documento faz referência a imagens da Internet. Carregá-las pode revelar informações de rede ao servidor que as hospeda.';

  @override
  String get loadRemoteImagesForWorkspace =>
      'Carregar neste espaço de trabalho';

  @override
  String get alwaysLoadRemoteImages => 'Sempre carregar imagens remotas';

  @override
  String get hideSidebar => 'Ocultar painel lateral';

  @override
  String get showSidebar => 'Mostrar painel lateral';

  @override
  String get showPreview => 'Mostrar pré-visualização';

  @override
  String get hidePreview => 'Ocultar pré-visualização';

  @override
  String get workspaceKindUnsavedMarkdown => 'Arquivo Markdown não salvo';

  @override
  String get workspaceKindSingleMarkdown => 'Arquivo Markdown único';

  @override
  String get workspaceKindMarkdownFolder => 'Pasta Markdown';

  @override
  String get workspaceKindWritersideModule => 'Módulo Writerside';

  @override
  String get problems => 'Problemas';

  @override
  String diagnosticCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count diagnósticos',
      one: '1 diagnóstico',
      zero: 'Nenhum diagnóstico',
    );
    return '$_temp0';
  }

  @override
  String get files => 'Arquivos';

  @override
  String get toc => 'TOC';

  @override
  String get tocActions => 'Ações do sumário';

  @override
  String get markdownUnsaved => 'Markdown - não salvo';

  @override
  String workspaceDetail(String kind, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arquivos',
      one: '1 arquivo',
    );
    return '$kind - $_temp0';
  }

  @override
  String get noFiles => 'Nenhum arquivo';

  @override
  String get newFile => 'Novo arquivo';

  @override
  String get noWritersideToc => 'Nenhum TOC do Writerside';

  @override
  String get tocSection => 'Seção do TOC';

  @override
  String get newTopic => 'Novo tópico';

  @override
  String get newChildTopic => 'Novo subtópico';

  @override
  String get newSiblingTopic => 'Novo tópico no mesmo nível';

  @override
  String get renameTopicFile => 'Renomear arquivo do tópico';

  @override
  String get topicPlacement => 'Posição no TOC';

  @override
  String get tocRoot => 'Na raiz do TOC';

  @override
  String get afterSelectedTopic => 'Após o tópico selecionado';

  @override
  String get insideSelectedTopic => 'Dentro do tópico selecionado';

  @override
  String get pasteAfterTopic => 'Colar depois';

  @override
  String get pasteAsChildTopic => 'Colar como subtópico';

  @override
  String get removeFromToc => 'Remover do TOC';

  @override
  String get confirmRemoveFromTocTitle => 'Remover do TOC?';

  @override
  String confirmRemoveFromTocMessage(String name) {
    return 'Remover $name deste TOC? O arquivo do tópico será mantido.';
  }

  @override
  String get confirmDeleteTopicTitle => 'Excluir o arquivo do tópico?';

  @override
  String confirmDeleteTopicMessage(String name) {
    return 'Excluir $name e removê-lo de todos os TOCs? Isso não pode ser desfeito.';
  }

  @override
  String get safeDeleteTopicFile =>
      'Excluir o arquivo do tópico com segurança…';

  @override
  String get removeTocElement => 'Remover elemento do TOC';

  @override
  String get reviewUsages => 'Revisar usos';

  @override
  String get deleteTopicFile => 'Excluir arquivo do tópico';

  @override
  String get removeAction => 'Remover';

  @override
  String topicRemovalSummary(String topic) {
    return 'Remova “$topic” da instância selecionada. O arquivo do tópico será mantido.';
  }

  @override
  String safeDeleteTopicSummary(String topic) {
    return 'Exclua “$topic” e atualize com segurança as referências a ele em todo este projeto Writerside.';
  }

  @override
  String childTopicsPromoted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Os $count tópicos filhos subirão um nível.',
      one: 'O tópico filho subirá um nível.',
    );
    return '$_temp0';
  }

  @override
  String get topicIsStartPageRemovalWarning =>
      'Este tópico é usado como página inicial de uma instância. Revise os usos dele e atribua outra página inicial antes de continuar.';

  @override
  String topicUsagesCount(int count) {
    return 'Usos ($count)';
  }

  @override
  String get noBreakingTopicUsages =>
      'Não foram encontradas referências que deixariam de funcionar.';

  @override
  String get topicUsagesFound =>
      'O BusyMark encontrou as seguintes referências a este tópico.';

  @override
  String get topicUsageTocElements => 'Elementos do TOC';

  @override
  String get topicUsageStartPages => 'Páginas iniciais';

  @override
  String get topicUsageTopicLinks => 'Links para tópicos';

  @override
  String get topicUsageIncludes => 'Inclusões';

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
  String get refactoringOptions => 'Opções de refatoração';

  @override
  String get updateUsagesAutomatically => 'Atualizar usos automaticamente';

  @override
  String get updateUsagesAutomaticallyDescription =>
      'Remova referências dos TOCs e inclusões e preserve o texto dos links.';

  @override
  String get manualUsageUpdatesRequired =>
      'Alguns usos exigem alterações manuais antes desta refatoração.';

  @override
  String get setRedirectTo => 'Redirecionar para';

  @override
  String get noRedirectDescription =>
      'Não redirecionar a página publicada antiga.';

  @override
  String get redirectTarget => 'Destino do redirecionamento';

  @override
  String get remainingUsagesBlockRemoval =>
      'Revise e atualize os usos restantes antes de continuar ou ative as atualizações automáticas quando estiverem disponíveis.';

  @override
  String usagesOfTopic(String topic) {
    return 'Usos de $topic';
  }

  @override
  String get noUsagesFound => 'Nenhum uso encontrado.';

  @override
  String get outsideSelectedInstance => 'Fora da instância selecionada';

  @override
  String get doRefactor => 'Refatorar';

  @override
  String get orphanTopicTitle => 'O arquivo do tópico não é mais usado';

  @override
  String get keepTopicFile => 'Manter o arquivo do tópico';

  @override
  String orphanTopicMessage(String topic) {
    return '“$topic” não é mais usado em nenhum lugar deste projeto Writerside. Exclua o arquivo ou mantenha-o para uso em outra instância.';
  }

  @override
  String get defaultNewTopicTitle => 'Novo tópico';

  @override
  String get topicTitle => 'Título do tópico';

  @override
  String get fileName => 'Nome do arquivo';

  @override
  String get topicTitleRequired => 'O título do tópico é obrigatório.';

  @override
  String get fileNameRequired => 'O nome do arquivo é obrigatório.';

  @override
  String get rename => 'Renomear';

  @override
  String get confirmDeleteFileTitle => 'Excluir arquivo?';

  @override
  String get confirmDeleteFolderTitle => 'Excluir pasta?';

  @override
  String confirmDeleteFileMessage(String name) {
    return 'Excluir $name? Isso não pode ser desfeito.';
  }

  @override
  String confirmDeleteFolderMessage(String name) {
    return 'Excluir $name e todos os arquivos dentro dela? Isso não pode ser desfeito.';
  }

  @override
  String get useSingleSafeFileName => 'Use um único nome de arquivo seguro.';

  @override
  String useExpectedExtension(String extension) {
    return 'Use a extensão $extension para o formato selecionado.';
  }

  @override
  String get useIdentifierCharacters =>
      'Use letras, números, sublinhados ou hifens antes da extensão.';

  @override
  String get topicIdAlreadyExists => 'O ID do tópico já existe.';

  @override
  String get createWritersideTopicFailed =>
      'Não foi possível criar o tópico do Writerside.';

  @override
  String get noOutline => 'Sem estrutura';

  @override
  String expandKind(String kind) {
    return 'Expandir $kind';
  }

  @override
  String collapseKind(String kind) {
    return 'Recolher $kind';
  }

  @override
  String get foldKindSection => 'seção';

  @override
  String get foldKindList => 'lista';

  @override
  String get foldKindQuote => 'citação';

  @override
  String get foldKindTag => 'tag';

  @override
  String get sourceSearchPreviousMatch => 'Correspondência anterior';

  @override
  String get sourceSearchNextMatch => 'Próxima correspondência';

  @override
  String get sourceSearchCaseSensitive =>
      'Diferenciar maiúsculas de minúsculas';

  @override
  String get sourceSearchWholeWord => 'Palavra inteira';

  @override
  String get sourceSearchRegex => 'Expressão regular';

  @override
  String get sourceSearchReplacement => 'Substituir por';

  @override
  String get sourceSearchReplaceCurrent => 'Substituir atual';

  @override
  String get sourceSearchReplaceAndFindNext => 'Substituir e localizar próximo';

  @override
  String get sourceSearchReplaceAll => 'Substituir tudo';

  @override
  String get workspaceReplace => 'Substituir no espaço de trabalho';

  @override
  String get reviewReplacements => 'Revisar substituições';

  @override
  String get applyReplacements => 'Aplicar substituições';

  @override
  String get skippedFiles => 'Arquivos ignorados';

  @override
  String get workspaceReplaceDirtyBuffer => 'Conteúdo não salvo do editor';

  @override
  String get workspaceReplaceDiskContent => 'Conteúdo salvo no disco';

  @override
  String selectFileMatches(int count) {
    return 'Selecionar todas as $count correspondências';
  }

  @override
  String workspaceReplaceApplied(int matches, int files, int skipped) {
    return 'Foram substituídas $matches correspondências em $files arquivos; $skipped ignoradas.';
  }

  @override
  String documentFormatWithFinalNewline(String encoding, String lineEnding) {
    return '$encoding · $lineEnding · Quebra de linha final';
  }

  @override
  String documentFormatWithoutFinalNewline(String encoding, String lineEnding) {
    return '$encoding · $lineEnding · Sem quebra de linha final';
  }

  @override
  String get normalizeLineEndings => 'Normalizar finais de linha';

  @override
  String get mixedLineEndingsSavePrompt =>
      'Este documento contém finais de linha mistos. Escolha um formato.';

  @override
  String workspaceReplaceMixedLineEndings(String fileName) {
    return '$fileName usa finais de linha mistos. Escolha o formato antes de substituir.';
  }

  @override
  String get workspaceReplaceIssueOversized =>
      'Um arquivo grande demais foi ignorado.';

  @override
  String get workspaceReplaceIssueUnreadable =>
      'Um arquivo que não pôde ser lido foi ignorado.';

  @override
  String get workspaceReplaceIssueInvalidUtf8 =>
      'Um arquivo que não é UTF-8 válido foi ignorado.';

  @override
  String get workspaceReplaceIssueTruncated =>
      'A prévia de substituições foi truncada.';

  @override
  String get workspaceReplaceIssueFileChanged =>
      'Um arquivo alterado após a prévia foi ignorado.';

  @override
  String get workspaceReplaceIssueBufferChanged =>
      'Um buffer do editor alterado após a prévia foi ignorado.';

  @override
  String get workspaceReplaceIssueNormalizationRequired =>
      'Escolha a normalização LF ou CRLF antes de substituir.';

  @override
  String get workspaceReplaceIssuePartialConflict =>
      'A reversão foi interrompida porque o ficheiro foi alterado em simultâneo. Algumas substituições podem permanecer; o conteúdo deslocado foi preservado no caminho abaixo.';

  @override
  String get workspaceReplaceIssueApplyFailed =>
      'Nenhuma substituição foi aplicada porque o conjunto revisado não pôde ser salvo com segurança.';

  @override
  String externalChangesTitle(String fileName) {
    return 'Alterações externas — $fileName';
  }

  @override
  String get externalFileDeleted => 'Este arquivo foi excluído do disco.';

  @override
  String get externalFileChanged =>
      'Este arquivo mudou no disco enquanto você tem alterações não salvas.';

  @override
  String recoveredDocumentReview(String fileName) {
    return 'O conteúdo não salvo de $fileName foi recuperado. Revise-o e depois salve, salve como ou descarte-o.';
  }

  @override
  String get compare => 'Comparar';

  @override
  String get reloadFromDisk => 'Recarregar do disco';

  @override
  String get keepMine => 'Manter minha versão';

  @override
  String get saveAs => 'Salvar como';

  @override
  String get sourceSearchInvalidRegex => 'Expressão regular inválida';

  @override
  String get sourceLargeFileFeaturesPaused =>
      'Arquivo grande: o realce e o recolhimento estão pausados';

  @override
  String get nothingToRead => 'Nenhum conteúdo para ler';

  @override
  String get admonition => 'Aviso';

  @override
  String get quote => 'Citação';

  @override
  String get note => 'Observação';

  @override
  String get tip => 'Dica';

  @override
  String get warning => 'Aviso';

  @override
  String get tabs => 'Guias';

  @override
  String get tab => 'Guia';

  @override
  String get procedure => 'Procedimento';

  @override
  String get step => 'Etapa';

  @override
  String get topic => 'Tópico';

  @override
  String get chapter => 'Capítulo';

  @override
  String couldNotOpenTarget(String target) {
    return 'Não foi possível abrir $target';
  }

  @override
  String linkTargetNotFound(String targetPath) {
    return 'Destino do link não encontrado: $targetPath';
  }

  @override
  String get cannotOpenFileTypeInEditor =>
      'Não é possível abrir este tipo de arquivo no editor';

  @override
  String anchorNotFound(String anchor) {
    return 'Âncora não encontrada: $anchor';
  }

  @override
  String get noProblemsFound => 'Nenhum problema encontrado';

  @override
  String get noResults => 'Nenhum resultado';

  @override
  String searchResultLine(String relativePath, int lineNumber) {
    return '$relativePath - linha $lineNumber';
  }

  @override
  String get untitledResult => 'Resultado sem título';

  @override
  String get documentKindMarkdownFile => 'Arquivo Markdown';

  @override
  String get documentKindWritersideMarkdownTopic =>
      'Tópico Markdown do Writerside';

  @override
  String get documentKindWritersideXmlTopic => 'Tópico XML do Writerside';

  @override
  String get documentKindWritersideTree => 'Árvore do Writerside';

  @override
  String get documentKindConfigurationFile => 'Arquivo de configuração';

  @override
  String get documentKindVariablesFile => 'Arquivo de variáveis';

  @override
  String get documentKindCategoriesFile => 'Arquivo de categorias';

  @override
  String get documentKindResourceFile => 'Arquivo de recursos';

  @override
  String workspaceErrorOpenFailed(String error) {
    return 'Falha ao abrir: $error';
  }

  @override
  String workspaceErrorCreateWritersideProjectFailed(String error) {
    return 'Não foi possível criar o projeto Writerside: $error';
  }

  @override
  String workspaceErrorCreateWritersideTopicFailed(String error) {
    return 'Não foi possível criar o tópico do Writerside: $error';
  }

  @override
  String workspaceErrorCouldNotOpenFile(String error) {
    return 'Não foi possível abrir o arquivo: $error';
  }

  @override
  String get workspaceErrorChooseWhereToSaveMarkdown =>
      'Escolha onde salvar este arquivo Markdown.';

  @override
  String get workspaceErrorSaveBlockedFileChangedOnDisk =>
      'Salvamento bloqueado: o arquivo foi alterado no disco.';

  @override
  String workspaceErrorSaveFailed(String error) {
    return 'Falha ao salvar: $error';
  }

  @override
  String workspaceErrorFileOperationFailed(String error) {
    return 'Falha na operação de arquivo: $error';
  }

  @override
  String workspaceErrorValidationFailed(String error) {
    return 'Falha na validação: $error';
  }

  @override
  String workspaceRecoveryRestored(int count) {
    return 'Foram recuperados $count documentos não salvos. Revise cada documento recuperado antes de continuar.';
  }

  @override
  String workspaceRecoveryDamaged(int count) {
    return 'Não foi possível restaurar $count registros de recuperação danificados. Os documentos recuperados válidos continuam disponíveis.';
  }

  @override
  String errorPathDoesNotExist(String path) {
    return 'O caminho não existe: $path';
  }

  @override
  String errorTargetDirectoryNotEmpty(String path) {
    return 'O diretório de destino já existe e não está vazio: $path';
  }

  @override
  String errorTargetPathNotDirectory(String path) {
    return 'O caminho de destino já existe e não é um diretório: $path';
  }

  @override
  String errorGeneratedFileAlreadyExists(String path) {
    return 'O arquivo gerado já existe: $path';
  }

  @override
  String get errorParentDirectoryRequired => 'O diretório pai é obrigatório.';

  @override
  String errorParentDirectoryMissing(String path) {
    return 'O diretório pai não existe: $path';
  }

  @override
  String errorDirectoryMissing(String path) {
    return 'O diretório não existe: $path';
  }

  @override
  String errorPathAlreadyExists(String path) {
    return 'O caminho já existe: $path';
  }

  @override
  String get errorFileNameRequired => 'O nome do arquivo é obrigatório.';

  @override
  String get errorFileNameUnsafe =>
      'O nome do arquivo deve ser um único segmento de caminho seguro.';

  @override
  String get errorFileOperationInvalidTarget =>
      'Não é possível mover uma pasta para dentro dela mesma.';

  @override
  String get errorFileOperationOutsideRoot =>
      'A operação de arquivo deve permanecer dentro do espaço de trabalho.';

  @override
  String get errorFileOperationRoot =>
      'A raiz do espaço de trabalho não pode ser alterada pela árvore de arquivos.';

  @override
  String get errorProjectNameRequired => 'O nome do projeto é obrigatório.';

  @override
  String get errorDirectoryNameRequired => 'O nome do diretório é obrigatório.';

  @override
  String get errorDirectoryNameUnsafe =>
      'O nome do diretório deve ser um único segmento de caminho seguro.';

  @override
  String get errorInstanceIdInvalid =>
      'O ID da instância deve começar com uma letra minúscula e conter apenas letras minúsculas, números, sublinhados e hifens.';

  @override
  String get errorTopicFileInvalid =>
      'O nome do arquivo do tópico deve ser um nome de arquivo Markdown sem separadores de caminho.';

  @override
  String get errorTopicTitleRequired => 'O título do tópico é obrigatório.';

  @override
  String errorWritersideModuleRootMissing(String path) {
    return 'A raiz do módulo Writerside não existe: $path';
  }

  @override
  String get errorWritersideModuleNotOpen =>
      'Um módulo Writerside deve estar aberto para criar um tópico.';

  @override
  String get errorWritersideInstanceTreeMissing =>
      'O módulo Writerside não tem uma árvore de instância.';

  @override
  String errorWritersideTreeFileMissing(String path) {
    return 'O arquivo de árvore do Writerside não existe: $path';
  }

  @override
  String errorTopicIdAlreadyExists(String topicId) {
    return 'O ID do tópico \"$topicId\" já existe neste módulo de ajuda.';
  }

  @override
  String errorTopicFileAlreadyExists(String path) {
    return 'O arquivo do tópico já existe: $path';
  }

  @override
  String errorReferenceTopicMissing(String topic) {
    return 'O tópico de referência não está presente na árvore selecionada: $topic';
  }

  @override
  String get errorWritersideTocNodeMissing =>
      'A entrada selecionada do TOC não existe mais.';

  @override
  String get errorWritersideTocInvalidMove =>
      'Uma entrada do TOC não pode ser movida para dentro de si mesma nem de um de seus descendentes.';

  @override
  String errorWritersideStartTopicDelete(String topic) {
    return 'O tópico inicial $topic não pode ser excluído. Escolha primeiro outra página inicial.';
  }

  @override
  String get errorWritersideSafeDeleteRequired =>
      'Use a exclusão segura para arquivos de tópicos do Writerside.';

  @override
  String get errorWritersideTopicUsageScanFailed =>
      'Não foi possível concluir a verificação dos usos do tópico. Nenhum arquivo foi alterado.';

  @override
  String get errorWritersideTopicUsagesRemain =>
      'Alguns usos do tópico ainda precisam de atenção. Revise-os antes de continuar.';

  @override
  String get errorWritersideRedirectInvalid =>
      'O destino de redirecionamento selecionado não é mais válido. Selecione-o novamente.';

  @override
  String errorWritersideRollbackFailed(String paths) {
    return 'Não foi possível reverter completamente a remoção do tópico. Revise estes caminhos antes de continuar: $paths';
  }

  @override
  String get errorTopicsRootUnsafe =>
      'A raiz dos tópicos deve ser um diretório relativo seguro.';

  @override
  String get errorTopicFileNameUnsafe =>
      'O nome do arquivo do tópico deve ser um único segmento de caminho seguro.';

  @override
  String errorTopicFileExtensionMismatch(String extension) {
    return 'A extensão do arquivo do tópico deve corresponder ao formato selecionado ($extension).';
  }

  @override
  String get errorTopicFileNameInvalid =>
      'O nome do arquivo do tópico deve conter apenas letras, números, sublinhados e hifens.';

  @override
  String errorUnknown(String code) {
    return 'Erro desconhecido: $code';
  }

  @override
  String diagnosticWorkspaceFileStatFailed(String error) {
    return 'Não foi possível ler os metadados do arquivo: $error';
  }

  @override
  String get diagnosticWorkspaceScanSkipped =>
      'Espaço de trabalho grande detectado. Alguns arquivos foram ignorados para manter o aplicativo responsivo.';

  @override
  String diagnosticWorkspaceScanInspectFailed(String error) {
    return 'Não foi possível inspecionar a entrada do espaço de trabalho: $error';
  }

  @override
  String get diagnosticWorkspaceFileTooLarge =>
      'O arquivo excede o limite beta de análise automática.';

  @override
  String diagnosticWorkspaceFileReadFailed(String error) {
    return 'Não foi possível ler o arquivo Markdown: $error';
  }

  @override
  String get diagnosticMarkdownAttributeMalformed =>
      'O bloco de atributos de título do Writerside está malformado.';

  @override
  String diagnosticMarkdownHeadingDuplicateId(String id) {
    return 'ID de título duplicado \"$id\".';
  }

  @override
  String get diagnosticWritersideTopicH1ConvertedToChapter =>
      'Títulos H1 adicionais no nível superior são tratados como capítulos.';

  @override
  String get diagnosticWritersideMarkdownTopicMissingTitle =>
      'O tópico Markdown do Writerside não tem H1 nem título no front matter.';

  @override
  String get diagnosticWritersideXmlTopicMissingTitle =>
      'O tópico XML não tem título.';

  @override
  String diagnosticWritersideTopicFileMissingTitle(String fileName) {
    return 'O tópico \"$fileName\" não tem título.';
  }

  @override
  String get diagnosticMarkdownFrontMatterMalformed =>
      'O front matter não foi fechado.';

  @override
  String get diagnosticMarkdownRawHtmlUnsafe => 'Elemento HTML inseguro.';

  @override
  String diagnosticMarkdownLinkUnresolvedTarget(String targetPath) {
    return 'O destino do link não existe: $targetPath';
  }

  @override
  String diagnosticMarkdownLinkUnresolvedAnchor(String anchor) {
    return 'A âncora \"$anchor\" não existe.';
  }

  @override
  String diagnosticMarkdownImageMissingAlt(String destination) {
    return 'A imagem \"$destination\" não tem texto alternativo.';
  }

  @override
  String diagnosticMarkdownImageMissingFile(String destination) {
    return 'A imagem não existe: $destination';
  }

  @override
  String diagnosticInvalidXml(String message) {
    return 'XML inválido: $message';
  }

  @override
  String get diagnosticWritersideConfigInvalidRoot =>
      'A raiz do arquivo writerside.cfg deve ser <ihp>.';

  @override
  String get diagnosticWritersideConfigMissingSnippetsSrc =>
      'A declaração de snippets está sem o atributo src.';

  @override
  String get diagnosticWritersideConfigMissingInstanceGroupsSrc =>
      'A declaração de instance-groups está sem o atributo src.';

  @override
  String diagnosticWritersideConfigInvalidKeymapsMode(String mode) {
    return 'Modo de keymaps não suportado: $mode';
  }

  @override
  String get diagnosticWritersideConfigMissingInstanceSrc =>
      'A declaração de instância está sem o atributo src.';

  @override
  String get diagnosticWritersideConfigMissingInstance =>
      'O arquivo writerside.cfg não registra uma instância.';

  @override
  String get diagnosticWritersideTreeInvalidRoot =>
      'A raiz do arquivo .tree deve ser <instance-profile>.';

  @override
  String get diagnosticWritersideTreeMissingId =>
      'O perfil da instância está sem o atributo id.';

  @override
  String diagnosticWritersideTreeIdMismatch(String id) {
    return 'O nome-base do arquivo .tree não corresponde ao ID da instância \"$id\".';
  }

  @override
  String get diagnosticWritersideTreeMissingStartPage =>
      'A instância que não é de biblioteca não tem start-page.';

  @override
  String diagnosticWritersideStartPageMissing(String startPage) {
    return 'A página inicial \"$startPage\" não existe.';
  }

  @override
  String diagnosticWritersideTreeDuplicateTopic(String topic) {
    return 'O tópico \"$topic\" aparece mais de uma vez no TOC desta instância.';
  }

  @override
  String get diagnosticWritersideVariableMalformedDeclaration =>
      'A declaração de variável deve ter nome e valor.';

  @override
  String diagnosticWritersideVariableDuplicateName(String name) {
    return 'A variável \"$name\" é declarada mais de uma vez.';
  }

  @override
  String get diagnosticWritersideCategoryMissingId =>
      'A categoria está sem o atributo id.';

  @override
  String diagnosticWritersideCategoryDuplicateId(String id) {
    return 'A categoria \"$id\" é declarada mais de uma vez.';
  }

  @override
  String diagnosticWritersideCategoryDuplicateOrder(String order) {
    return 'A ordem da categoria \"$order\" foi declarada mais de uma vez.';
  }

  @override
  String get diagnosticWritersideTopicInvalidRoot =>
      'A raiz do arquivo .topic deve ser <topic>.';

  @override
  String get diagnosticWritersideTopicMissingRootId =>
      'A raiz do tópico XML está sem o atributo id.';

  @override
  String diagnosticWritersideTopicRootIdMismatch(String id, String expectedId) {
    return 'O ID raiz do tópico XML \"$id\" deve corresponder ao nome do arquivo \"$expectedId\".';
  }

  @override
  String diagnosticWritersideTopicDuplicateElementId(String elementId) {
    return 'O ID do elemento \"$elementId\" aparece mais de uma vez.';
  }

  @override
  String get diagnosticWritersideTopicAnchorMissingHref =>
      '<a> está sem o atributo href.';

  @override
  String get diagnosticWritersideConfigMissing =>
      'O modo Writerside requer o arquivo writerside.cfg.';

  @override
  String diagnosticWritersideConfigMissingBuildConfigDirectory(
    String relativePath,
  ) {
    return 'O diretório configurado para a compilação está ausente: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingApiSpecificationsDirectory(
    String relativePath,
  ) {
    return 'O diretório de especificações de API configurado está ausente: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingSnippetsDirectory(
    String relativePath,
  ) {
    return 'O diretório de snippets configurado está ausente: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingVarsFile(String relativePath) {
    return 'O arquivo de variáveis configurado está ausente: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingCategoriesFile(String relativePath) {
    return 'O arquivo de categorias configurado está ausente: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceGroupsFile(
    String relativePath,
  ) {
    return 'O arquivo de grupos de instâncias configurado está ausente: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceTree(String source) {
    return 'A árvore de instância registrada \"$source\" não existe.';
  }

  @override
  String diagnosticWritersideTopicReadFailed(String error) {
    return 'Não foi possível ler o arquivo do tópico: $error';
  }

  @override
  String diagnosticWritersideDefaultTopicsDirectoryMissing(
    String relativePath,
  ) {
    return 'O diretório de tópicos padrão está ausente: $relativePath';
  }

  @override
  String diagnosticWritersideTopicsDirectoryMissing(String relativePath) {
    return 'O diretório de tópicos configurado está ausente: $relativePath';
  }

  @override
  String diagnosticWritersideImagesDirectoryMissing(String relativePath) {
    return 'O diretório de imagens configurado está ausente: $relativePath';
  }

  @override
  String diagnosticWritersideTopicDuplicateId(String id) {
    return 'O ID do elemento \"$id\" aparece mais de uma vez.';
  }

  @override
  String diagnosticWritersideTreeMissingTopic(String topic) {
    return 'O TOC faz referência ao tópico ausente \"$topic\".';
  }

  @override
  String diagnosticWritersideTreeInvalidHref(String href) {
    return 'O href externo \"$href\" é inválido.';
  }

  @override
  String diagnosticWritersideVariableUnresolved(String name) {
    return 'A variável \"%$name%\" não foi declarada.';
  }

  @override
  String diagnosticWritersideTopicLinkUnresolved(String destination) {
    return 'O link para o tópico \"$destination\" não pode ser resolvido.';
  }

  @override
  String diagnosticWritersideAnchorUnresolved(
    String anchor,
    String targetName,
  ) {
    return 'A âncora \"$anchor\" não existe em \"$targetName\".';
  }

  @override
  String get diagnosticWritersideIncludeMissingFrom =>
      '<include> está sem o atributo from.';

  @override
  String diagnosticWritersideIncludeSourceMissing(String from) {
    return 'A origem da inclusão \"$from\" não existe.';
  }

  @override
  String diagnosticWritersideIncludeElementMissing(
    String elementId,
    String from,
  ) {
    return 'O elemento incluído \"$elementId\" não existe em \"$from\".';
  }

  @override
  String diagnosticWritersideCategoryUnresolved(String ref) {
    return 'A categoria seealso \"$ref\" não foi declarada.';
  }

  @override
  String diagnosticWritersideTopicAmbiguousReference(String reference) {
    return 'A referência de tópico \"$reference\" é ambígua.';
  }

  @override
  String diagnosticUnknown(String code) {
    return 'Diagnóstico desconhecido: $code';
  }

  @override
  String get close => 'Fechar';

  @override
  String get git => 'Git';

  @override
  String get gitDiff => 'Diff do Git';

  @override
  String get gitShowDiff => 'Mostrar diff';

  @override
  String gitDiffHunkRange(String oldRange, String newRange) {
    return 'anterior $oldRange → novo $newRange';
  }

  @override
  String get gitDiffNoLines => 'sem linhas';

  @override
  String get gitUnavailableTitle => 'Git não está disponível';

  @override
  String gitUnavailableMessage(String reason) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'other':
          'Instale o Git ou configure o BusyMark para usar um executável do Git disponível. $reason',
    });
    return '$_temp0';
  }

  @override
  String get gitTrustRequiredTitle =>
      'Confiar neste espaço de trabalho para o Git?';

  @override
  String get gitTrustRequiredMessage =>
      'Os repositórios Git podem executar programas por meio de hooks, filtros e outras configurações. Confie neste espaço de trabalho antes que o BusyMark leia os dados do repositório ou ative ações do Git.';

  @override
  String get gitTrustWorkspace => 'Confiar no espaço de trabalho';

  @override
  String get gitNotRepositoryTitle => 'Não é um repositório Git';

  @override
  String get gitNotRepositoryMessage =>
      'Este espaço de trabalho não está em um repositório Git.';

  @override
  String get gitInitializeRepository => 'Inicializar repositório';

  @override
  String get gitDetachedHead => 'HEAD desanexado';

  @override
  String gitDetachedHeadAt(String commit) {
    return 'Desanexado em $commit';
  }

  @override
  String get gitNoUpstream => 'Sem upstream';

  @override
  String gitAheadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commits não enviados',
      one: '1 commit não enviado',
    );
    return '$_temp0';
  }

  @override
  String gitBehindCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commits para obter',
      one: '1 commit para obter',
    );
    return '$_temp0';
  }

  @override
  String get gitClean => 'Limpo';

  @override
  String get gitConflicts => 'Conflitos';

  @override
  String get gitChanges => 'Alterações';

  @override
  String get gitStaged => 'Preparados';

  @override
  String get gitUnstaged => 'Não preparados';

  @override
  String get gitHistory => 'Histórico';

  @override
  String get gitBranches => 'Branches';

  @override
  String get gitActions => 'Ações do Git';

  @override
  String get gitPull => 'Pull';

  @override
  String get gitFetch => 'Buscar';

  @override
  String get gitPush => 'Push';

  @override
  String get gitCommit => 'Commit';

  @override
  String get gitSelectForCommit => 'Adicionar arquivo ao índice';

  @override
  String get gitRemoveFromCommit => 'Remover arquivo do índice';

  @override
  String get gitDiscard => 'Descartar';

  @override
  String get gitOpenFile => 'Abrir arquivo';

  @override
  String get gitMarkResolved => 'Marcar como resolvido';

  @override
  String get gitUntracked => 'Arquivos não rastreados';

  @override
  String get gitCommitMessage => 'Mensagem de commit';

  @override
  String get gitCommitSelectedFiles => 'Arquivos selecionados';

  @override
  String get gitCommitNoSelectedFiles =>
      'Adicione pelo menos um arquivo ao índice antes de criar o commit.';

  @override
  String gitStagedFileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arquivos preparados',
      one: '1 arquivo preparado',
    );
    return '$_temp0';
  }

  @override
  String get gitOutsideWorkspace => 'Fora do espaço de trabalho';

  @override
  String get gitCommitMessageRequired => 'Digite uma mensagem de commit.';

  @override
  String get gitCreateBranch => 'Criar branch';

  @override
  String get gitNewBranch => 'Nova branch';

  @override
  String get gitBranchName => 'Nome da branch';

  @override
  String get gitSwitchBranch => 'Trocar';

  @override
  String get gitNoChanges => 'Nenhuma alteração';

  @override
  String get gitNoHistory => 'Nenhum histórico';

  @override
  String get gitNoBranches => 'Nenhuma branch';

  @override
  String get gitNoDiff => 'Nenhum diff para exibir';

  @override
  String get gitBinaryFile =>
      'Arquivo binário. O BusyMark não exibe patches binários.';

  @override
  String gitBinaryFileInfo(int size) {
    return 'Arquivo binário ($size bytes). O BusyMark não exibe patches binários.';
  }

  @override
  String get gitUnsavedChangesBanner =>
      'As alterações não salvas do editor não são incluídas até serem salvas.';

  @override
  String get gitConfirmDiscardTitle => 'Descartar alterações do Git?';

  @override
  String gitConfirmDiscardTracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Os arquivos rastreados selecionados serão restaurados pelo Git.',
      one: 'O arquivo rastreado selecionado será restaurado pelo Git.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardUntracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Os arquivos não rastreados selecionados serão excluídos.',
      one: 'O arquivo não rastreado selecionado será excluído.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardMixed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Os arquivos selecionados serão restaurados ou excluídos de acordo com o status do Git.',
      one:
          'O arquivo selecionado será restaurado ou excluído de acordo com o status do Git.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmSwitchBranchTitle(String branch) {
    return 'Trocar para $branch?';
  }

  @override
  String get gitConfirmSwitchBranchMessage =>
      'O BusyMark recarregará o espaço de trabalho do disco depois que o Git trocar de branch.';

  @override
  String get gitConfirmPushSetUpstreamTitle => 'Definir branch upstream?';

  @override
  String gitConfirmPushSetUpstreamMessage(String branch) {
    return 'Esta branch não tem upstream. O BusyMark pode enviar $branch e definir seu upstream quando houver exatamente um remoto configurado.';
  }

  @override
  String get gitProjectHistory => 'Projeto';

  @override
  String get gitFileHistory => 'Arquivo atual';

  @override
  String get gitFileHistoryRequiresOpenFile =>
      'O histórico do arquivo requer um arquivo Markdown aberto.';

  @override
  String get gitLoadMore => 'Carregar mais';

  @override
  String get gitChangesInCommit => 'Alterações neste commit';

  @override
  String get gitCompareWithCurrent => 'Comparar com a versão atual';

  @override
  String get gitRestoreVersion => 'Restaurar esta versão';

  @override
  String get gitConfirmRestoreTitle => 'Restaurar esta versão do arquivo?';

  @override
  String get gitConfirmRestoreMessage =>
      'O BusyMark substituirá o arquivo atual da árvore de trabalho pela versão selecionada do commit. O arquivo restaurado permanecerá não preparado.';

  @override
  String get gitCommitActions => 'Ações do commit';

  @override
  String get gitResetCurrentBranchToHere => 'Redefinir a branch atual aqui…';

  @override
  String gitResetCurrentBranchTitle(String branch, String commit) {
    return 'Redefinir $branch para $commit?';
  }

  @override
  String gitResetCurrentBranchMessage(String branch, String commit) {
    return 'Isto move a branch $branch para o commit $commit. Escolha como o Git deve atualizar o índice e a árvore de trabalho.';
  }

  @override
  String get gitReset => 'Redefinir';

  @override
  String get gitResetModeSoft => 'Soft';

  @override
  String get gitResetModeSoftDescription =>
      'Mover apenas a branch. Manter o índice e a árvore de trabalho inalterados; as diferenças em relação ao commit selecionado permanecem preparadas.';

  @override
  String get gitResetModeMixed => 'Mixed';

  @override
  String get gitResetModeMixedDescription =>
      'Mover a branch e redefinir o índice. Manter a árvore de trabalho inalterada, deixando as diferenças não preparadas.';

  @override
  String get gitResetModeHard => 'Hard';

  @override
  String get gitResetModeHardDescription =>
      'Mover a branch e redefinir o índice e a árvore de trabalho. As alterações monitorizadas são descartadas; os arquivos não monitorizados que bloqueiam a operação podem ser eliminados.';

  @override
  String get gitResetModeKeep => 'Keep';

  @override
  String get gitResetModeKeepDescription =>
      'Mover a branch e redefinir os arquivos monitorizados, preservando as alterações locais. O Git aborta se essas alterações entrarem em conflito com a redefinição.';

  @override
  String gitAdditionsDeletions(int additions, int deletions) {
    return '+$additions -$deletions';
  }

  @override
  String get fileActions => 'Ações do arquivo';

  @override
  String get actions => 'Ações';

  @override
  String get gitStatusAdded => 'Adicionado';

  @override
  String get gitStatusDeleted => 'Excluído';

  @override
  String get gitStatusRenamed => 'Renomeado';

  @override
  String get gitStatusCopied => 'Copiado';

  @override
  String get gitStatusUntracked => 'Não rastreado';

  @override
  String get gitStatusConflicted => 'Em conflito';

  @override
  String get gitStatusIgnored => 'Ignorado';

  @override
  String get gitStatusTypeChanged => 'Tipo alterado';

  @override
  String get gitStatusModified => 'Modificado';

  @override
  String get gitStatusUnknown => 'Desconhecido';

  @override
  String get gitErrorUnavailable => 'Git não está disponível.';

  @override
  String get gitErrorNotRepository =>
      'Este espaço de trabalho não é um repositório Git.';

  @override
  String get gitErrorUnsafePath =>
      'O BusyMark bloqueou um caminho Git inseguro.';

  @override
  String get gitErrorInvalidBranchName => 'Digite um nome de branch válido.';

  @override
  String get gitErrorNoRemote => 'Nenhum remoto Git está configurado.';

  @override
  String get gitErrorNoUpstream => 'Nenhuma branch upstream está configurada.';

  @override
  String get gitErrorMultipleRemotes =>
      'Há vários remotos configurados. Escolha um upstream fora desta versão do BusyMark.';

  @override
  String get gitErrorDirtyWorkspace =>
      'Salve ou descarte as alterações do editor do BusyMark antes de trocar de branch.';

  @override
  String get gitErrorResetDirtyWorkspace =>
      'Guarde ou descarte as alterações no editor do BusyMark antes de redefinir a branch atual.';

  @override
  String get gitErrorRestoreStagedFile =>
      'Remova o arquivo do índice antes de restaurar uma versão anterior.';

  @override
  String get gitErrorResetDetachedHead =>
      'Mude para uma branch antes de a redefinir.';

  @override
  String get gitErrorDiverged =>
      'A branch divergiu. Resolva o merge ou o rebase fora desta versão do BusyMark.';

  @override
  String get gitErrorAuthentication => 'A autenticação do Git falhou.';

  @override
  String get gitErrorNetwork => 'A operação de rede do Git falhou.';

  @override
  String get gitErrorConflict => 'O Git relatou conflitos não resolvidos.';

  @override
  String get gitErrorCommandFailed => 'O comando Git falhou.';

  @override
  String get markdownAndHtml => 'Markdown e HTML';

  @override
  String get markdownHtmlMarkdownBlocks => 'Blocos Markdown';

  @override
  String get markdownHtmlMarkdownBlocksDescription =>
      'Estruturas de bloco compatíveis no código Markdown e na pré-visualização.';

  @override
  String get markdownHtmlInlineFormatting => 'Markdown em linha';

  @override
  String get markdownHtmlInlineFormattingDescription =>
      'Formatação dentro de parágrafos, itens de lista e células de tabela.';

  @override
  String get markdownHtmlRawHtmlBlocks => 'Blocos de HTML bruto';

  @override
  String get markdownHtmlRawHtmlBlocksDescription =>
      'Tags HTML de bloco seguras renderizadas pelos widgets de pré-visualização do BusyMark.';

  @override
  String get markdownHtmlRawHtmlInline => 'Tags de HTML bruto em linha';

  @override
  String get markdownHtmlRawHtmlInlineDescription =>
      'Tags HTML em linha seguras renderizadas sem mostrar as tags literais.';

  @override
  String get markdownHtmlSafety => 'Regras de segurança';

  @override
  String get markdownHtmlSafetyDescription =>
      'O HTML bruto é analisado e higienizado antes da pré-visualização.';

  @override
  String get markdownHtmlHeadings => 'Títulos';

  @override
  String get markdownHtmlParagraphs => 'Parágrafos';

  @override
  String get markdownHtmlLists => 'Listas';

  @override
  String get markdownHtmlHtmlContainers => 'Contêineres';

  @override
  String get markdownHtmlHtmlTextBlocks => 'Blocos de texto';

  @override
  String get markdownHtmlHtmlFigures => 'Figuras e imagens';

  @override
  String get markdownHtmlHtmlPreformatted => 'Código pré-formatado';

  @override
  String get markdownHtmlHtmlDisclosure => 'Blocos expansíveis';

  @override
  String get markdownHtmlHtmlDescriptionLists => 'Listas de descrição';

  @override
  String get markdownHtmlHtmlFormattingTags => 'Tags de formatação';

  @override
  String get markdownHtmlHtmlInlineCodeTags => 'Tags de código em linha';

  @override
  String get markdownHtmlHtmlNeutralInlineTags => 'Tags de texto semântico';

  @override
  String get markdownHtmlSanitizedPreview => 'Pré-visualização higienizada';

  @override
  String get markdownHtmlSanitizedPreviewDescription =>
      'O HTML permitido é convertido em blocos de pré-visualização do BusyMark e não é renderizado em um navegador.';

  @override
  String get markdownHtmlSourcePreserved => 'Código-fonte preservado';

  @override
  String get markdownHtmlSourcePreservedDescription =>
      'HTML bruto não editado é salvo exatamente como texto fonte.';

  @override
  String get markdownHtmlMarkdownInsideHtml => 'Markdown dentro de HTML';

  @override
  String get markdownHtmlMarkdownInsideHtmlDescription =>
      'Marcadores Markdown dentro de HTML bruto são exibidos como texto literal.';

  @override
  String get markdownHtmlBlockedContent => 'Conteúdo ativo bloqueado';

  @override
  String get markdownHtmlBlockedContentDescription =>
      'Scripts, estilos, frames, formulários, SVG, MathML, eventos e atributos inseguros são bloqueados.';

  @override
  String get markdownHtmlSafeUrls => 'Somente URLs seguras';

  @override
  String get markdownHtmlSafeUrlsDescription =>
      'Links permitem http, https, mailto, tel, URLs relativas e fragmentos; esquemas inseguros são bloqueados.';

  @override
  String get exportAsPdf => 'Exportar como PDF';

  @override
  String get pdfExportDescription =>
      'Escolha o esquema da página para criar um PDF bem acabado e independente.';

  @override
  String get pdfRemoteImagesNote =>
      'As imagens remotas não são transferidas durante a exportação. As imagens locais são incluídas quando disponíveis.';

  @override
  String get pdfPageSize => 'Tamanho da página';

  @override
  String get pdfPageSizeA4 => 'A4';

  @override
  String get pdfPageSizeLetter => 'Carta';

  @override
  String get pdfOrientation => 'Orientação';

  @override
  String get pdfPortrait => 'Vertical';

  @override
  String get pdfLandscape => 'Horizontal';

  @override
  String get pdfMargins => 'Margens';

  @override
  String get pdfMarginNarrow => 'Estreitas';

  @override
  String get pdfMarginNormal => 'Normais';

  @override
  String get pdfMarginWide => 'Largas';

  @override
  String get pdfIncludePageNumbers => 'Incluir números de página';

  @override
  String get export => 'Exportar';

  @override
  String get exportingPdf => 'A exportar PDF…';

  @override
  String get fileTypePdf => 'Documento PDF';

  @override
  String pdfExported(String fileName) {
    return '$fileName foi exportado.';
  }

  @override
  String pdfExportedWithWarnings(String fileName, int count) {
    return '$fileName foi exportado. Imagens que não foi possível incluir: $count.';
  }

  @override
  String get pdfExportUnavailable =>
      'O componente de exportação para PDF está em falta. Reinstale o BusyMark e tente novamente.';

  @override
  String get pdfExportTimedOut =>
      'A exportação para PDF demorou demasiado e foi interrompida.';

  @override
  String get pdfExportFailed =>
      'O BusyMark não conseguiu exportar este documento como PDF.';

  @override
  String get visualizationRendering => 'A renderizar…';

  @override
  String get visualizationStale => 'A mostrar a última renderização válida';

  @override
  String get visualizationShowSource => 'Mostrar código-fonte';

  @override
  String get visualizationShowRender => 'Mostrar renderização';

  @override
  String get visualizationFitWidth => 'Ajustar à largura';

  @override
  String get visualizationSaveImage => 'Guardar imagem';

  @override
  String get visualizationCopyImage => 'Copiar imagem';

  @override
  String get visualizationImageCopied => 'Imagem copiada';

  @override
  String get visualizationOpenApiReference => 'Abrir referência da API';

  @override
  String get visualizationValid => 'Válido';

  @override
  String get visualizationInvalid => 'Inválido';

  @override
  String get visualizationServers => 'Servidores';

  @override
  String get visualizationPaths => 'Caminhos';

  @override
  String get visualizationOperations => 'Operações';

  @override
  String get visualizationTags => 'Etiquetas';

  @override
  String get visualizationNoOperations => 'Nenhuma operação correspondente';

  @override
  String get visualizationSearchOperations => 'Pesquisar operações';

  @override
  String get visualizationRenderFailed =>
      'Não foi possível renderizar esta visualização.';

  @override
  String get visualizationRetry => 'Tentar novamente';

  @override
  String visualizationSaved(String fileName) {
    return '$fileName guardado';
  }

  @override
  String get shortcutExportPdfDescription =>
      'Exportar o documento ativo ou o módulo do Writerside como PDF.';

  @override
  String get instances => 'Instâncias';

  @override
  String get newInstance => 'Nova instância';

  @override
  String get newTocLibrary => 'Nova biblioteca de sumário';

  @override
  String get editInstance => 'Editar instância';

  @override
  String get openTocFile => 'Abrir ficheiro de sumário';

  @override
  String get createInstance => 'Criar instância';

  @override
  String get createTocLibrary => 'Criar biblioteca de sumário';

  @override
  String get instanceContent => 'Conteúdo';

  @override
  String get instanceContentSource => 'Criar a partir de';

  @override
  String get emptyInstance => 'Instância vazia';

  @override
  String get markdownFiles => 'Ficheiros Markdown locais';

  @override
  String get chooseMarkdownFolder => 'Escolher pasta de Markdown';

  @override
  String get errorWritersideInstanceImportSourceRequired =>
      'Escolha uma pasta que contenha ficheiros Markdown.';

  @override
  String get instanceAppearance => 'Aspeto';

  @override
  String get instanceColor => 'Cor do ícone';

  @override
  String get instanceVersion => 'Versão';

  @override
  String instanceVersionInherited(String version) {
    return 'Quando este campo está vazio, é usada a versão do projeto $version.';
  }

  @override
  String get instanceWebPath => 'Caminho web';

  @override
  String get instanceStatus => 'Estado';

  @override
  String get instanceStatusRelease => 'Lançamento';

  @override
  String get instanceStatusEap => 'Acesso antecipado';

  @override
  String get instanceStatusDeprecated => 'Obsoleta';

  @override
  String get allowSearchEngineIndexing =>
      'Permitir indexação por motores de pesquisa';

  @override
  String get allowSearchEngineIndexingDescription =>
      'Permita que motores de pesquisa externos indexem esta saída.';

  @override
  String get offlineArtifact => 'Artefacto offline';

  @override
  String get offlineArtifactDescription =>
      'Inclua os recursos para que a documentação gerada seja autónoma.';

  @override
  String get instanceOutputSettings => 'Definições de saída';

  @override
  String get markdownImportSource => 'Origem Markdown';

  @override
  String get markdownImportFiles => 'Ficheiros Markdown';

  @override
  String get selectNone => 'Não selecionar nenhum';

  @override
  String markdownFilesFound(int count) {
    return 'Foram encontrados $count ficheiro(s) Markdown';
  }

  @override
  String get noMarkdownFilesFound =>
      'Não foram encontrados ficheiros Markdown neste diretório.';

  @override
  String get copyReferencedMedia => 'Copiar multimédia referenciada';

  @override
  String get copyReferencedMediaDescription =>
      'Copie imagens e vídeos locais referenciados pelos ficheiros selecionados, preservando os caminhos relativos.';

  @override
  String get instanceIdRenameWarningTitle => 'Mudar o nome do ID da instância?';

  @override
  String instanceIdRenameWarning(String oldId, String newId) {
    return 'O BusyMark mudará o nome do ficheiro .tree e atualizará as referências do projeto Writerside de “$oldId” para “$newId”. Os scripts de publicação não são alterados e devem ser atualizados separadamente.';
  }

  @override
  String get renameAndUpdateReferences =>
      'Mudar o nome e atualizar referências';

  @override
  String get tocLibraryDescription =>
      'Uma biblioteca de sumário armazena secções reutilizáveis e não produz uma saída própria.';

  @override
  String get defaultTocLibraryName => 'Sumário partilhado';

  @override
  String get instanceColorAutomatic => 'Automático';

  @override
  String get instanceColorBlue => 'Azul';

  @override
  String get instanceColorGreen => 'Verde';

  @override
  String get instanceColorOrange => 'Laranja';

  @override
  String get instanceColorPurple => 'Roxo';

  @override
  String get instanceColorRed => 'Vermelho';

  @override
  String get instanceColorTeal => 'Verde-azulado';

  @override
  String get instanceColorYellow => 'Amarelo';

  @override
  String get errorWritersideInstanceNameRequired =>
      'Introduza um nome para a instância.';

  @override
  String errorWritersideInstanceIdExists(String id) {
    return 'Já existe uma instância com o ID “$id”.';
  }

  @override
  String errorWritersideInstanceTreeExists(String path) {
    return 'A árvore da instância já existe: $path';
  }

  @override
  String errorWritersideInstanceImportSourceMissing(String path) {
    return 'O diretório de origem Markdown não existe: $path';
  }

  @override
  String get errorWritersideInstanceImportSelectionRequired =>
      'Selecione pelo menos um ficheiro Markdown para importar.';

  @override
  String errorWritersideInstanceImportFileInvalid(String path) {
    return 'Este não é um ficheiro Markdown legível dentro da origem selecionada: $path';
  }

  @override
  String errorWritersideInstanceImportTargetExists(String path) {
    return 'A importação substituiria um ficheiro existente do projeto: $path';
  }

  @override
  String get errorWritersideInstanceFilesChanged =>
      'Os ficheiros da instância foram alterados no disco. Reveja-os e tente novamente.';

  @override
  String errorWritersideInstanceRollbackFailed(String paths) {
    return 'O BusyMark não conseguiu reverter completamente a alteração da instância. Reveja estes ficheiros antes de continuar: $paths';
  }

  @override
  String get errorWritersideInstanceLibraryImport =>
      'Uma biblioteca de sumário não pode importar tópicos Markdown.';

  @override
  String get errorWritersideInstanceWebPathInvalid =>
      'O caminho web deve ter uma única linha.';

  @override
  String get errorWritersideInstanceConfigurationInvalid =>
      'A configuração da instância do Writerside é inválida. Corrija os diagnósticos e tente novamente.';

  @override
  String get errorWritersideInstanceTemporaryFile =>
      'O BusyMark não conseguiu preparar com segurança as alterações da instância.';

  @override
  String diagnosticWritersideTreeInvalidStatus(String status) {
    return 'Estado de instância desconhecido “$status”. Use release, eap ou deprecated.';
  }

  @override
  String diagnosticWritersideDuplicateInstanceId(String id) {
    return 'O ID de instância “$id” é usado por mais de um ficheiro de árvore.';
  }

  @override
  String get diagnosticWritersideBuildProfilesInvalidRoot =>
      'buildprofiles.xml deve ter um elemento raiz <buildprofiles>.';

  @override
  String diagnosticWritersideBuildProfilesInvalidBoolean(
    String name,
    String value,
  ) {
    return 'O valor $name “$value” deve ser true ou false.';
  }

  @override
  String get diagnosticWritersideBuildProfileMissingInstance =>
      'Um elemento <build-profile> deve especificar um ID de instância.';

  @override
  String get diagnosticWritersideTreeInvalidInclude =>
      'Um <include> da árvore deve especificar from e element-id.';

  @override
  String get diagnosticWritersideTreeMissingSnippetId =>
      'Um <snippet> da árvore deve especificar um id.';

  @override
  String get diagnosticWritersideTreeInvalidCrossInstanceReference =>
      'Uma referência de sumário entre instâncias deve especificar ref e in.';

  @override
  String get diagnosticWritersideTreeConflictingTargets =>
      'Um elemento do sumário não pode apontar para mais do que um tópico, referência, link ou redirecionamento.';

  @override
  String diagnosticWritersideTreeDuplicateElementId(String id) {
    return 'O ID de elemento da árvore “$id” foi declarado mais de uma vez.';
  }

  @override
  String get diagnosticWritersideInstanceGroupsInvalidRoot =>
      'O ficheiro de grupos de instâncias deve ter um elemento raiz <instance-groups>.';

  @override
  String get diagnosticWritersideInstanceGroupInvalid =>
      'Um grupo de instâncias deve especificar um id e uma lista de instâncias não vazios.';

  @override
  String diagnosticWritersideInstanceGroupDuplicateId(String id) {
    return 'O ID do grupo de instâncias “$id” foi declarado mais de uma vez.';
  }

  @override
  String diagnosticWritersideExternalTreeInclude(
    String source,
    String id,
    String origin,
  ) {
    return 'A inclusão de sumário “$source#$id” pertence ao módulo externo “$origin” e não pode ser expandida neste espaço de trabalho.';
  }

  @override
  String diagnosticWritersideTreeIncludeElementMissing(
    String source,
    String id,
  ) {
    return 'O elemento de árvore “$id” não existe na árvore registada “$source”.';
  }

  @override
  String diagnosticWritersideTreeCircularInclude(String source, String id) {
    return 'A inclusão de árvore “$source#$id” cria um ciclo.';
  }

  @override
  String diagnosticWritersideUnknownInstanceGroup(String group) {
    return 'A condição de instância referencia o grupo desconhecido “@$group”.';
  }

  @override
  String diagnosticWritersideReferenceInstanceMissing(String instance) {
    return 'A referência entre instâncias aponta para a instância desconhecida “$instance”.';
  }

  @override
  String diagnosticWritersideReferenceTopicMissing(
    String topic,
    String instance,
  ) {
    return 'O tópico “$topic” não está na instância referenciada “$instance”.';
  }

  @override
  String get download => 'Baixar';

  @override
  String get exportWritersideAsPdf => 'Exportar Writerside como PDF';

  @override
  String get writersidePdfContent => 'Conteúdo da exportação';

  @override
  String get writersidePdfPage => 'Página';

  @override
  String get exportingWritersidePdf => 'Exportando PDF do Writerside…';

  @override
  String get ai => 'IA';

  @override
  String get aiLocalOllama => 'Ollama local';

  @override
  String get aiDisabled => 'Desativado';

  @override
  String get aiLocalOnlyDescription =>
      'A edição com IA é iniciada apenas de forma explícita. O BusyMark envia somente o contexto exibido ao provedor selecionado e nunca aplica uma proposta sem revisão.';

  @override
  String get aiProvider => 'Provedor de IA';

  @override
  String get aiDefaultProvider => 'Provedor predefinido';

  @override
  String get aiConfigureProvider => 'Configurar provedor';

  @override
  String get aiChooseProvider => 'Escolher provedor de IA';

  @override
  String get aiOllamaEndpoint => 'Endpoint do Ollama';

  @override
  String get aiOllamaModel => 'Modelo do Ollama';

  @override
  String get aiTestConnection => 'Testar conexão';

  @override
  String get aiTestingConnection => 'Testando…';

  @override
  String aiConnectionReady(int count) {
    return 'Conectado. $count modelo(s) instalado(s) encontrado(s).';
  }

  @override
  String get aiNoModels => 'Nenhum modelo selecionado.';

  @override
  String get aiConnectionFailed =>
      'O BusyMark não conseguiu verificar a geração de texto por IA.';

  @override
  String get aiConfigureFirst =>
      'Ative um provedor de IA e verifique um modelo em Configurações → IA.';

  @override
  String get aiEditWithAi => 'Editar com IA';

  @override
  String get aiRefineWithAi => 'Melhorar com IA';

  @override
  String get aiInstruction => 'Instrução';

  @override
  String get aiChangeTarget => 'O que pode ser alterado';

  @override
  String get aiSharedContext => 'Contexto compartilhado com a IA';

  @override
  String get aiTargetSelection => 'Conteúdo selecionado';

  @override
  String get aiTargetInsertAfterBlock => 'Inserir após o bloco atual';

  @override
  String get aiTargetCurrentBlock => 'Bloco atual';

  @override
  String get aiTargetCurrentSection => 'Seção atual';

  @override
  String get aiTargetCompleteDocument => 'Documento completo';

  @override
  String get aiContextNone => 'Sem contexto do documento';

  @override
  String get aiContextSelection => 'Conteúdo selecionado';

  @override
  String get aiContextCurrentBlock => 'Bloco atual';

  @override
  String get aiContextCurrentSection => 'Seção atual';

  @override
  String get aiContextCompleteDocument => 'Documento completo';

  @override
  String get aiGenerating => 'Gerando proposta…';

  @override
  String get aiProposal => 'Proposta de IA';

  @override
  String get aiGenerateProposal => 'Gerar proposta';

  @override
  String aiContextDisclosure(int count) {
    return 'O provedor selecionado receberá $count caracteres do contexto exibido.';
  }

  @override
  String get aiOriginal => 'Texto original';

  @override
  String get aiSuggested => 'Sugestão';

  @override
  String get aiApplyProposal => 'Aplicar proposta';

  @override
  String aiTokenUsage(int input, int output) {
    return '$input tokens de entrada · $output tokens de saída';
  }

  @override
  String get aiStaleProposal =>
      'O documento foi alterado enquanto esta proposta era gerada. Execute a ação novamente.';

  @override
  String get gitAiStagedChangesChanged =>
      'As alterações preparadas mudaram enquanto esta mensagem de commit era gerada. Execute a ação novamente.';

  @override
  String get aiViewContext => 'Ver contexto enviado';

  @override
  String get aiReviewExactContent => 'Revisar conteúdo exato';

  @override
  String get aiContentToChange => 'Conteúdo a alterar';

  @override
  String get aiContentSentToAi => 'Conteúdo enviado à IA';

  @override
  String get aiApiKey => 'Chave de API';

  @override
  String get aiApiKeyStoredHint =>
      'Uma chave está armazenada no cofre de credenciais do sistema';

  @override
  String get aiApiKeyEnterHint => 'Insira uma chave de API do provedor';

  @override
  String get aiReplaceApiKey => 'Substituir chave de API';

  @override
  String get aiSaveApiKey => 'Salvar chave de API com segurança';

  @override
  String get aiRemoveApiKey => 'Remover chave de API salva';

  @override
  String get aiCredentialSaved =>
      'A chave de API foi salva no cofre de credenciais do sistema.';

  @override
  String get aiCredentialRemoved => 'A chave de API salva foi removida.';

  @override
  String get aiModelRouting => 'Seleção de modelo';

  @override
  String get aiAutomaticRouting => 'Automática conforme a tarefa';

  @override
  String get aiFixedModelRouting => 'Usar o modelo selecionado';

  @override
  String get aiPreferredModel => 'Modelo preferido';

  @override
  String get aiModel => 'Modelo';

  @override
  String aiUsageThisMonth(int requests, int input, int output) {
    return '$requests solicitações · $input tokens de entrada · $output tokens de saída';
  }

  @override
  String aiCloudConsentTitle(String provider) {
    return 'Enviar conteúdo para $provider?';
  }

  @override
  String aiCloudConsentEnable(String provider) {
    return 'Ativar $provider';
  }

  @override
  String get aiCloudConsentMessage =>
      'Somente o conteúdo exibido em cada caixa de diálogo de revisão de IA é enviado. As solicitações não mantêm estado, as propostas exigem revisão e a chave de API é armazenada no cofre de credenciais do sistema Linux.';

  @override
  String aiCloudConsentRequired(String provider) {
    return 'Primeiro, confirme o compartilhamento de dados com $provider em Configurações → IA.';
  }

  @override
  String aiGenerationVerified(String model, int count) {
    return 'Geração verificada com $model. Há $count modelos compatíveis disponíveis.';
  }

  @override
  String get aiColdStartObserved =>
      'Foi detetado um arranque a frio do modelo local.';

  @override
  String get aiNoCompatibleModels =>
      'Não há nenhum modelo compatível de geração de texto disponível.';

  @override
  String get aiEnableProvider => 'Primeiro, ative um provedor de IA.';

  @override
  String get aiDraftCommitMessage => 'Criar rascunho da mensagem de commit';

  @override
  String get aiDrafting => 'Criando rascunho…';

  @override
  String get aiDraftWithAi => 'Criar rascunho com IA';

  @override
  String get generateOrUpdateMarkdownToc => 'Gerar/atualizar sumário';

  @override
  String get markdownTocTitle => 'Sumário';

  @override
  String markdownTocUpdated(int count) {
    return 'Sumário atualizado com $count entradas.';
  }

  @override
  String get markdownTocNoHeadings =>
      'Adicione pelo menos um título de seção antes de gerar um sumário.';

  @override
  String get markdownTocMalformedMarkers =>
      'Os marcadores de sumário do BusyMark estão ausentes, duplicados ou fora de ordem.';

  @override
  String diagnosticMarkdownHeadingSkippedLevel(int level, int previousLevel) {
    return 'O título de nível $level vem após o nível $previousLevel; revise o aninhamento das seções.';
  }

  @override
  String get diagnosticMarkdownLinkEmptyText =>
      'O texto do link está vazio; forneça um nome acessível que descreva sua finalidade.';

  @override
  String diagnosticMarkdownLinkReviewText(String text) {
    return 'Verifique se o texto do link “$text” descreve sua finalidade no contexto.';
  }

  @override
  String get diagnosticMarkdownTableEmptyHeader =>
      'Os cabeçalhos da tabela devem identificar suas colunas; preencha cada cabeçalho vazio.';

  @override
  String get mathRenderFailed =>
      'Não foi possível renderizar a expressão matemática.';

  @override
  String get inlineMath => 'Matemática em linha';

  @override
  String get displayMath => 'Matemática em bloco';
}
