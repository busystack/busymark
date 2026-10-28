// ignore_for_file: text_direction_code_point_in_literal, text_direction_code_point_in_comment

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get notesNewFromRetainedText =>
      'Nova nota a partir do texto preservado';

  @override
  String get notesAccountThrottled =>
      'Nextcloud pediu uma pausa. Aguarde antes de voltar a autenticar-se.';

  @override
  String get notesSettingsRefreshing =>
      'A atualizar Notes após a confirmação das definições';

  @override
  String get notesExportOperationFailed =>
      'A exportação falhou antes da publicação. Verifique a origem e o destino e volte a exportar.';

  @override
  String get notesRecoveryCreatedNotOpened =>
      'A nota recuperada foi guardada, mas não abriu. Resolva as alterações pendentes no editor ou nas propriedades e abra esta nota existente.';

  @override
  String get notesSettingsPendingNotes =>
      'Notas pendentes, conflitos ou criações incertas impedem esta alteração. Sincronize ou reveja em Notes e volte a guardar este rascunho preservado.';

  @override
  String get notesSettingsPendingAttachments =>
      'Operações de anexos impedem esta alteração. Reveja os anexos em Notes e volte a guardar este rascunho preservado.';

  @override
  String get notesAccountServerAddress =>
      'Use o endereço HTTPS canónico do Nextcloud e reinicie a autenticação. Não foi possível verificar o endereço ou o redirecionamento.';

  @override
  String get notesAccountUnsupported =>
      'Notes está indisponível ou a API não é suportada. Ative Nextcloud Notes com API principal 1 e secundária 4 ou posterior.';

  @override
  String get notesAccountAuthorizeAgain =>
      'Nextcloud rejeitou as credenciais. Autorize novamente a conta ou volte a ligá-la.';

  @override
  String get notesAccountCheckForbidden =>
      'Nextcloud recusou a verificação de funcionalidades de Notes. Peça autorização ao administrador e tente novamente.';

  @override
  String get notesAccountMalformed =>
      'Não foi possível verificar a resposta do Nextcloud. Verifique a instalação do servidor e reinicie a autenticação.';

  @override
  String get notesAccountTimedOut =>
      'A autenticação expirou. Reinicie-a e conclua a autorização no navegador.';

  @override
  String get notesAccountBrowserUnavailable =>
      'Não foi possível abrir o navegador do sistema. Verifique o navegador predefinido e reinicie a autenticação.';

  @override
  String get notesAccountNetwork =>
      'Nextcloud está inacessível. Verifique a ligação e o servidor e tente autenticar-se novamente.';

  @override
  String get notesAccountRejected =>
      'Nextcloud rejeitou o pedido de funcionalidades. Verifique o acesso com o administrador e tente novamente.';

  @override
  String get notesAccountFailed =>
      'Não foi possível configurar a conta. Tente autenticar-se novamente.';

  @override
  String get notesTransferSourceChanged =>
      'A origem mudou desde a revisão. Reveja o ficheiro atual ou capture uma nova imagem antes de tentar novamente.';

  @override
  String get notesTransferUnreadable =>
      'Não foi possível ler a origem. Verifique o acesso ao ficheiro ou pasta e reveja.';

  @override
  String get notesTransferInvalidSnapshot =>
      'Imagem inválida ou não suportada. Escolha uma imagem BusyMark Notes válida ou uma origem Markdown.';

  @override
  String get notesTransferMediaLimit =>
      'Os conteúdos multimédia excedem o limite de importação. Reduza os do item afetado e reveja-o.';

  @override
  String get notesTransferUnsafeSource =>
      'A origem contém um caminho inseguro. Escolha ficheiros na pasta de origem e reveja.';

  @override
  String get notesTransferDestination =>
      'Não foi possível escrever a exportação. Verifique o acesso e espaço livre no destino e tente novamente.';

  @override
  String get notesTransferOperationFailed =>
      'A transferência falhou. Reveja os itens afetados e tente novamente. Os já importados continuam guardados.';

  @override
  String get notesExportPublishedWithOmissions =>
      'Exportação disponível com omissões';

  @override
  String get notesBatchUnchanged => 'Os valores pedidos já estavam definidos.';

  @override
  String get notesBatchReadOnly =>
      'Esta nota é só de leitura. As propriedades protegidas não podem mudar; Favorito continua permitido.';

  @override
  String get notesBatchReviewChanged =>
      'Esta nota mudou desde a revisão. Reveja o estado atual antes de repetir a ação.';

  @override
  String get notesBatchMissing =>
      'Esta nota já não está disponível. Atualize a lista e reveja os destinos.';

  @override
  String get notesBatchStorage =>
      'Falha ao guardar localmente. Verifique o armazenamento e repita este item; os bem-sucedidos continuam guardados.';

  @override
  String get notesRemoteReviewChanged =>
      'A nota no servidor mudou. O rascunho de união foi preservado. Reveja a comparação atualizada e escolha novamente a resolução.';

  @override
  String get notesReviewRemote => 'Revi a versão atual do servidor';

  @override
  String get wsModuleCapsNotPublished =>
      'A capitalização do módulo não é publicada.';

  @override
  String get wsTitleOverridesAction => 'Títulos da instância e do índice…';

  @override
  String get wsHeadingNotPublished => 'Não é publicado por este gerador.';

  @override
  String get wsMarkdownInstanceTitleLimitation =>
      'O builder fixado não publica títulos por instância em tópicos Markdown. A marcação existente é preservada; consulte o código-fonte.';

  @override
  String get wsTopicIdentity => 'ID do tópico';

  @override
  String get wsElementAnchor => 'Âncora do elemento';

  @override
  String get wsHeadingText => 'Texto do cabeçalho';

  @override
  String get wsDefaultTitle => 'Título predefinido';

  @override
  String get wsTopicNavigation => 'Navegação do tópico';

  @override
  String get wsHeadingOptions => 'Atributos do cabeçalho';

  @override
  String get wsDocumentOptions => 'Definições do documento';

  @override
  String get wsSettingsPresent => 'Existem definições explícitas';

  @override
  String get wsTitleOverrideExplanation =>
      'Substitui o título publicado; o texto do cabeçalho mantém-se.';

  @override
  String get wsIgnoreVariables => 'Tratar variáveis como texto literal';

  @override
  String get wsIgnoreVariablesExplanation =>
      'Quando ativo, o texto semelhante a variáveis não é substituído.';

  @override
  String get wsInstanceSelection => 'Instâncias de ajuda';

  @override
  String get wsInstanceExplanation =>
      'Selecione saídas por nomes, grupos, listas, exclusões ou expressões.';

  @override
  String get wsFilterExplanation =>
      'Filtra conteúdo reutilizável por critérios; não seleciona uma instância de ajuda.';

  @override
  String get wsContextHelp => 'ID de ajuda contextual';

  @override
  String get wsCapitalization => 'Capitalização';

  @override
  String get wsLibraryTopic => 'Tópico de biblioteca';

  @override
  String get wsLastModified => 'Última alteração';

  @override
  String get wsMissingTopicHeading =>
      'Não existe H1 do tópico. Adicione-o no código-fonte.';

  @override
  String get wsMultipleTopicHeadings =>
      'O primeiro H1 determina o título do tópico. Os restantes são cabeçalhos separados.';

  @override
  String get wsTopicIdentityMismatch =>
      'O id da raiz difere do ID baseado no ficheiro. Use Renomear ficheiro do tópico ou consulte o código-fonte.';

  @override
  String get wsUnsupportedProperties =>
      'Os atributos não suportados são preservados. Consulte-os no código-fonte.';

  @override
  String get wsGeneratedAnchor =>
      'Âncora gerada; introduzir um valor cria uma substituição.';

  @override
  String get wsHeadingBuilderLimitation =>
      'O builder fixado não publica atributos H1. Pertencem ao cabeçalho, não à raiz XML.';

  @override
  String get closeOtherTabs => 'Fechar os outros separadores';

  @override
  String get tocTopicFromTemplate => 'Tópico a partir de modelo...';

  @override
  String get tocSaveAsTemplate => 'Guardar como modelo';

  @override
  String get tocTemplateDialog => 'Criar tópico a partir de modelo';

  @override
  String get tocTemplatesEditor => 'Modelos de ficheiros e código';

  @override
  String get tocEditTemplates => 'Editar modelos...';

  @override
  String get tocCreateCustomTemplate => 'Criar modelo personalizado...';

  @override
  String get tocTemplateCreated => 'Modelo criado';

  @override
  String get tocTemplateDefault => 'Predefinidos';

  @override
  String get tocTemplateCustom => 'Personalizados';

  @override
  String get tocTemplateFilename => 'Nome do ficheiro:';

  @override
  String get tocTemplateMarkdown => 'Markdown (.md)';

  @override
  String get tocTemplateXml => 'XML (.topic)';

  @override
  String get tocTemplatesInternal => 'Internos';

  @override
  String get tocTemplateUnnamed => 'Sem nome';

  @override
  String get tocTemplateNew => 'Novo modelo...';

  @override
  String get tocTemplateName => 'Nome:';

  @override
  String get tocTemplateExtension => 'Extensão:';

  @override
  String get tocTemplateLoadError =>
      'Não foi possível carregar os modelos. Os modelos existentes não foram alterados.';

  @override
  String get tocTemplateSaveError =>
      'Não foi possível guardar os modelos. As alterações continuam disponíveis aqui.';

  @override
  String get tocTemplateConflict =>
      'Os modelos foram alterados noutra janela. Cancele e reabra o editor.';

  @override
  String get tocTemplateDuplicateName =>
      'Já existe um modelo com este nome e extensão.';

  @override
  String get tocTemplateFormat => 'Formato:';

  @override
  String get tocTemplateReset => 'Repor';

  @override
  String get tocTemplateRetry => 'Tentar novamente';

  @override
  String tocRemoveElementsDialog(int count) {
    return 'Remover $count elementos do índice';
  }

  @override
  String get tocRemoveElementsRetainFiles =>
      'Os ficheiros de origem associados a estes elementos do índice não serão eliminados.';

  @override
  String get tocOk => 'OK';

  @override
  String get tocSelectExistingTopic =>
      'Selecionar tópico para adicionar à instância atual';

  @override
  String get tocGroupName => 'Nome do grupo';

  @override
  String get tocMoveLineUp => 'Mover linha para cima';

  @override
  String get tocMoveLineDown => 'Mover linha para baixo';

  @override
  String get tocEmptyMdTopic => 'Tópico MD vazio';

  @override
  String get tocEmptyXmlTopic => 'Tópico XML vazio';

  @override
  String get tocCopySpecial => 'Cópia especial';

  @override
  String tocCopyFileName(String name) {
    return 'Nome do ficheiro do tópico \'$name\'';
  }

  @override
  String get tocCopyFilePath => 'Caminho do ficheiro do tópico';

  @override
  String tocCopyTopicTitle(String title) {
    return 'Título do tópico \'$title\'';
  }

  @override
  String tocCopyElementId(String id) {
    return 'ID do elemento do índice \'$id\'';
  }

  @override
  String get tocCopyFileNameUnavailable => 'Nome do ficheiro do tópico';

  @override
  String get tocCopyTopicTitleUnavailable => 'Título do tópico';

  @override
  String get tocCopyElementIdUnavailable => 'ID do elemento do índice';

  @override
  String get tocEditTitleAction => 'Editar título...';

  @override
  String get tocEditTitleDialog => 'Editar título';

  @override
  String get tocRemoveElementAction => 'Remover elemento do índice...';

  @override
  String get tocSetHomePage => 'Definir como página inicial';

  @override
  String tocGoToElement(String fileName) {
    return 'Ir para o elemento do índice em \'$fileName\'';
  }

  @override
  String get tocSynchronize => 'Sincronizar índice e editor';

  @override
  String get tocEmptyGroupAction => 'Grupo vazio';

  @override
  String get tocNewEmptyGroup => 'Novo grupo vazio';

  @override
  String get tocGroupAction => 'Agrupar';

  @override
  String get tocNewGroup => 'Novo grupo';

  @override
  String get tocSortChildren => 'Ordenar subtópicos alfabeticamente';

  @override
  String get tocLinkTopicFiles => 'Ligar ficheiros de tópicos ao índice...';

  @override
  String get addLocalMarkdownFiles => 'Adicionar ficheiros Markdown locais';

  @override
  String get tocTitleField => 'Título no índice:';

  @override
  String get tocTopicTitleField => 'Título do tópico:';

  @override
  String get tocAdvancedSettings => 'Definições avançadas';

  @override
  String tocInstanceTitleField(String instanceId) {
    return 'Título para \'$instanceId\':';
  }

  @override
  String get tocOnlyTitleField => 'Título exclusivo do índice:';

  @override
  String get tocInstanceTitleExplanation =>
      'Utilizado apenas na instância atual. Por predefinição, é herdado do título do tópico.';

  @override
  String get tocOnlyTitleExplanation =>
      'Utilizado apenas no índice. Por predefinição, é herdado do título do tópico ou do título específico da instância, se definido. Os títulos são explicados';

  @override
  String get tocTitleDocumentationLink => 'aqui';

  @override
  String get tocFindUsages => 'Localizar';

  @override
  String get tocRefactorMenu => 'Refatorizar';

  @override
  String get tocSafeDelete => 'Eliminação segura';

  @override
  String get tocDuplicate => 'Duplicar';

  @override
  String get tocDuplicateFilename => 'Nome do ficheiro do tópico:';

  @override
  String get tocDuplicateDialog => 'Duplicar tópico';

  @override
  String get pdfTitlePage => 'Página de título';

  @override
  String get pdfIncludeTitlePage => 'Incluir página de título';

  @override
  String get pdfTitlePageNote =>
      'Esta página não tem cabeçalho, rodapé nem número de página visível.';

  @override
  String get pdfTitlePageTitle => 'Título';

  @override
  String get pdfTitlePageSubtitle => 'Subtítulo';

  @override
  String get pdfTitlePageAuthor => 'Autor';

  @override
  String get pdfTitlePageOrganization => 'Organização';

  @override
  String get pdfTitlePageVersion => 'Versão';

  @override
  String get pdfTitlePageDate => 'Data';

  @override
  String get pdfTitlePageTitleRequired =>
      'Introduza um título para a página de título.';

  @override
  String get pdfTocSectionNote =>
      'Começa numa página separada e pode ocupar várias páginas.';

  @override
  String get appTitle => 'BusyMark';

  @override
  String get appSubtitle =>
      'Editor para ficheiros Markdown e projetos de documentação compatíveis com o Writerside.';

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
      'Quando esta opção está ativada, são adicionados apenas a versão do sistema operativo Linux e o idioma da aplicação BusyMark. Não são anexados registos, ficheiros, dados de conta nem outros diagnósticos.';

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
  String get copyPlainText => 'Copiar como texto simples';

  @override
  String get clipboardCopyFailed =>
      'Não foi possível copiar a seleção para a área de transferência.';

  @override
  String get copyName => 'Copiar nome';

  @override
  String get copyFileName => 'Copiar nome do ficheiro';

  @override
  String get copyPath => 'Copiar caminho';

  @override
  String get create => 'Criar';

  @override
  String get creating => 'A criar…';

  @override
  String get cut => 'Recortar';

  @override
  String get promoteSection => 'Promover secção';

  @override
  String get demoteSection => 'Rebaixar secção';

  @override
  String get moveSectionUp => 'Mover secção para cima';

  @override
  String get moveSectionDown => 'Mover secção para baixo';

  @override
  String get confirmDeleteSectionTitle => 'Eliminar secção?';

  @override
  String confirmDeleteSectionMessage(String name) {
    return 'Eliminar “$name” e todo o conteúdo da secção? Esta ação não pode ser anulada.';
  }

  @override
  String get darkTheme => 'Escuro';

  @override
  String get delete => 'Eliminar';

  @override
  String get discard => 'Descartar';

  @override
  String get editor => 'Editor';

  @override
  String get file => 'Ficheiro';

  @override
  String get fileHistory => 'Histórico do ficheiro';

  @override
  String get folder => 'Pasta';

  @override
  String get insert => 'Inserir';

  @override
  String get keyboardShortcuts => 'Atalhos de teclado';

  @override
  String get commandUnavailableInContext =>
      'Este comando não está disponível no contexto atual.';

  @override
  String get lightTheme => 'Claro';

  @override
  String get mainMenu => 'Menu principal';

  @override
  String get fullScreen => 'Ecrã inteiro';

  @override
  String get markdown => 'Markdown';

  @override
  String get open => 'Abrir';

  @override
  String get openInFiles => 'Abrir em Ficheiros';

  @override
  String get pathActions => 'Ações do caminho';

  @override
  String get outline => 'Estrutura';

  @override
  String get overwrite => 'Sobrescrever';

  @override
  String get paste => 'Colar';

  @override
  String get reading => 'Leitura';

  @override
  String get removeFromRecent => 'Remover dos recentes';

  @override
  String get recent => 'Recentes';

  @override
  String get redo => 'Refazer';

  @override
  String get save => 'Guardar';

  @override
  String get search => 'Pesquisar';

  @override
  String get selectAll => 'Selecionar tudo';

  @override
  String get settings => 'Definições';

  @override
  String get source => 'Código-fonte';

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
  String get viewMode => 'Modo de visualização';

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
  String get openMarkdownFile => 'Abrir ficheiro Markdown';

  @override
  String get markdownFileExtensions => '.md ou .markdown';

  @override
  String get openFolderOrWritersideProject =>
      'Abrir pasta ou projeto Writerside';

  @override
  String get markdownFolderOrWritersideProject =>
      'Pasta Markdown ou projeto compatível com Writerside';

  @override
  String get noOpenFile => 'Nenhum ficheiro aberto';

  @override
  String get shortcutDeleteTreeItemDescription =>
      'Eliminar o item selecionado em Ficheiros ou remover o tópico selecionado do sumário';

  @override
  String get shortcutGroupGeneral => 'Geral';

  @override
  String get shortcutNewDocument => 'Criar';

  @override
  String get shortcutNewDocumentDescription =>
      'Criar ficheiro Markdown ou projeto Writerside';

  @override
  String get shortcutOpenDescription =>
      'Abrir um ficheiro Markdown, uma pasta ou um projeto Writerside';

  @override
  String get shortcutSaveDescription => 'Guardar o documento atual';

  @override
  String get shortcutSearchDescription =>
      'Pesquisar no espaço de trabalho atual';

  @override
  String get shortcutKeyboardShortcutsDescription =>
      'Personalizar os atalhos de teclado da aplicação';

  @override
  String get shortcutSyntaxReferenceDescription =>
      'Abrir a referência de sintaxe';

  @override
  String get shortcutSettingsDescription => 'Abrir as definições do BusyMark';

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
  String get shortcutLinkDescription => 'Inserir ou editar uma ligação';

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
  String get createMarkdownFile => 'Criar ficheiro Markdown';

  @override
  String get createMarkdownFileDescription =>
      'Iniciar um documento Markdown local não guardado';

  @override
  String get createWritersideProject => 'Criar projeto Writerside';

  @override
  String get createWritersideProjectDescription =>
      'Iniciar um projeto local compatível com Writerside';

  @override
  String get defaultProjectName => 'Documentação';

  @override
  String get defaultInstanceName => 'Guia do utilizador';

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
  String get settingsTitle => 'Definições do BusyMark';

  @override
  String get autoSave => 'Gravação automática';

  @override
  String get autoSaveDescription =>
      'Guarda automaticamente as alterações do ficheiro após um curto período de inatividade.';

  @override
  String get wordWrap => 'Quebra de linha';

  @override
  String get wordWrapDescription =>
      'Ajustar linhas longas à largura do editor em vez de deslocar horizontalmente.';

  @override
  String get editorFontSize => 'Tamanho da fonte do editor';

  @override
  String get validateOnEdit => 'Validar ao editar';

  @override
  String get clearRecentWorkspaces => 'Limpar histórico recente';

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
  String get settingsEditingButtonsSectionTitle => 'Botões de edição';

  @override
  String get spellingDictionaries => 'Dicionários ortográficos';

  @override
  String get spellingDictionariesDescription =>
      'Instalar e gerir dicionários ortográficos';

  @override
  String get settingsDictionariesSectionTitle => 'Dicionários';

  @override
  String get availableSpellingDictionaries => 'Dicionários disponíveis';

  @override
  String get customSpellingDictionaries => 'Dicionários personalizados';

  @override
  String get spellingDictionaryProblems => 'Problemas de dicionários';

  @override
  String get settingsWindowSectionTitle => 'Janela';

  @override
  String get settingsReopenWorkspaceOnStartupTitle =>
      'Reabrir o espaço de trabalho anterior ao iniciar';

  @override
  String get settingsReopenWorkspaceOnStartupDescription =>
      'Abra o espaço de trabalho e as abas da sessão anterior quando o BusyMark iniciar.';

  @override
  String get settingsConfirmCloseWithUnsavedChangesTitle =>
      'Confirmar antes de fechar com alterações não guardadas';

  @override
  String get settingsConfirmCloseWithUnsavedChangesDescription =>
      'Perguntar antes de fechar o BusyMark quando documentos tiverem alterações não guardadas.';

  @override
  String get closeUnsavedChangesTitle => 'Alterações não guardadas';

  @override
  String get closeUnsavedChangesSingleMessage =>
      'Este documento tem alterações não guardadas. Guardar as alterações antes de fechar o BusyMark?';

  @override
  String closeUnsavedChangesMultipleMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count documentos têm alterações não guardadas. Guardar as alterações antes de fechar o BusyMark?',
      one:
          '1 documento tem alterações não guardadas. Guardar as alterações antes de fechar o BusyMark?',
      zero: 'Guardar as alterações antes de fechar o BusyMark?',
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
  String get currentFile => 'ficheiro atual';

  @override
  String get unsavedChanges => 'Alterações não guardadas';

  @override
  String unsavedChangesMessage(String fileName) {
    return 'Existem alterações não guardadas em $fileName. Pretende guardá-las antes de continuar?';
  }

  @override
  String unsavedChangesMultipleMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Existem $count documentos com alterações não guardadas. Pretende guardá-los antes de continuar?',
      one:
          'Existe 1 documento com alterações não guardadas. Pretende guardá-lo antes de continuar?',
    );
    return '$_temp0';
  }

  @override
  String get fileChangedOnDisk => 'Ficheiro alterado no disco';

  @override
  String get fileChangedOnDiskMessage =>
      'Este ficheiro foi alterado no disco desde que foi aberto. Sobrescrever?';

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
  String get link => 'Ligação';

  @override
  String get hardLineBreak => 'Quebra de linha forçada';

  @override
  String get insertBlankLine => 'Inserir linha em branco';

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
  String get deleteTable => 'Eliminar tabela';

  @override
  String tableColumnNumber(int columnNumber) {
    return 'Coluna $columnNumber';
  }

  @override
  String get insertColumnLeft => 'Inserir coluna à esquerda';

  @override
  String get insertColumnRight => 'Inserir coluna à direita';

  @override
  String get deleteColumn => 'Eliminar coluna';

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
  String get deleteRow => 'Eliminar linha';

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
  String get workspaceKindUnsavedMarkdown => 'Ficheiro Markdown não guardado';

  @override
  String get workspaceKindSingleMarkdown => 'Ficheiro Markdown único';

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
  String get files => 'Ficheiros';

  @override
  String get toc => 'Índice';

  @override
  String get tocActions => 'Ações do sumário';

  @override
  String get markdownUnsaved => 'Markdown - não guardado';

  @override
  String workspaceDetail(String kind, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ficheiros',
      one: '1 ficheiro',
    );
    return '$kind - $_temp0';
  }

  @override
  String get noFiles => 'Nenhum ficheiro';

  @override
  String get newFile => 'Novo ficheiro';

  @override
  String get noWritersideToc => 'Nenhum TOC do Writerside';

  @override
  String get tocSection => 'Secção do TOC';

  @override
  String get newTopic => 'Novo tópico';

  @override
  String get newChildTopic => 'Novo subtópico';

  @override
  String get newSiblingTopic => 'Novo tópico';

  @override
  String get renameTopicFile => 'Renomear ficheiro do tópico';

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
    return 'Remover $name deste TOC? O ficheiro do tópico será mantido.';
  }

  @override
  String get confirmDeleteTopicTitle => 'Eliminar o ficheiro do tópico?';

  @override
  String confirmDeleteTopicMessage(String name) {
    return 'Eliminar $name e removê-lo de todos os TOCs? Esta ação não pode ser anulada.';
  }

  @override
  String get safeDeleteTopicFile =>
      'Eliminar o ficheiro do tópico com segurança…';

  @override
  String get removeTocElement => 'Remover elemento do TOC';

  @override
  String get removeTocElements => 'Remover elementos do TOC';

  @override
  String get reviewUsages => 'Rever usos';

  @override
  String get deleteTopicFile => 'Eliminar ficheiro do tópico';

  @override
  String get removeAction => 'Remover';

  @override
  String topicRemovalSummary(String topic) {
    return 'Remover o elemento «$topic» do índice? O ficheiro de origem associado ao índice não será eliminado.';
  }

  @override
  String safeDeleteTopicSummary(String topic) {
    return 'Elimine “$topic” e atualize com segurança as referências a ele em todo este projeto Writerside.';
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
  String get topicIsHomePageRemovalWarning =>
      'Este tópico é a página inicial desta instância. Escolha outra página inicial antes de o remover do índice.';

  @override
  String get newHomePage => 'Nova página inicial';

  @override
  String get chooseHomePage => 'Escolher página inicial';

  @override
  String get noHomePageReplacement =>
      'Adicione ou associe outro tópico elegível a esta instância antes de remover a sua página inicial.';

  @override
  String get topicIsStartPageRemovalWarning =>
      'Este tópico é a página inicial de uma instância. Defina outra página inicial antes de eliminar o seu ficheiro de origem.';

  @override
  String topicUsagesCount(int count) {
    return '$count utilizações encontradas.';
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
  String get topicUsageTopicLinks => 'Ligações para tópicos';

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
      'Remova referências dos TOCs e inclusões e preserve o texto dos ligações.';

  @override
  String get manualUsageUpdatesRequired =>
      'Alguns usos exigem alterações manuais antes desta refatoração.';

  @override
  String get setRedirectTo => 'Redirecionar para:';

  @override
  String get noRedirectDescription =>
      'Não redirecionar a página publicada antiga.';

  @override
  String get redirectTarget => 'Destino do redirecionamento';

  @override
  String get remainingUsagesBlockRemoval =>
      'Reveja e atualize os usos restantes antes de continuar ou ative as atualizações automáticas quando estiverem disponíveis.';

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
  String get preview => 'Pré-visualizar';

  @override
  String get topicRenamePreviewTitle => 'Pré-visualização da mudança de nome';

  @override
  String topicRenamePathChange(String oldPath, String newPath) {
    return 'Caminho: $oldPath → $newPath';
  }

  @override
  String topicRenameIdChange(String oldId, String newId) {
    return 'ID do tópico: $oldId → $newId';
  }

  @override
  String topicRenameUrlChange(String instance, String oldName, String newName) {
    return 'Instância $instance: $oldName → $newName';
  }

  @override
  String get topicRenameAffectedFiles => 'Ficheiros afetados';

  @override
  String get orphanTopicTitle => 'O ficheiro do tópico não é mais usado';

  @override
  String get keepTopicFile => 'Manter o ficheiro do tópico';

  @override
  String orphanTopicMessage(String topic) {
    return '“$topic” não é mais usado em nenhum lugar deste projeto Writerside. Elimine o ficheiro ou mantenha-o para uso em outra instância.';
  }

  @override
  String get defaultNewTopicTitle => 'Novo tópico';

  @override
  String get topicTitle => 'Título do tópico';

  @override
  String get fileName => 'Nome do ficheiro';

  @override
  String get topicTitleRequired => 'O título do tópico é obrigatório.';

  @override
  String get fileNameRequired => 'O nome do ficheiro é obrigatório.';

  @override
  String get rename => 'Renomear';

  @override
  String get confirmDeleteFileTitle => 'Eliminar ficheiro?';

  @override
  String get confirmDeleteFolderTitle => 'Eliminar pasta?';

  @override
  String confirmDeleteFileMessage(String name) {
    return 'Eliminar $name? Esta ação não pode ser anulada.';
  }

  @override
  String confirmDeleteFolderMessage(String name) {
    return 'Eliminar $name e todos os ficheiros dentro dela? Esta ação não pode ser anulada.';
  }

  @override
  String get useSingleSafeFileName => 'Use um único nome de ficheiro seguro.';

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
  String get foldKindSection => 'secção';

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
  String get sourceSearchReplacement => 'Substituir por';

  @override
  String get sourceSearchReplaceCurrent => 'Substituir correspondência atual';

  @override
  String get sourceSearchReplaceAndFindNext => 'Substituir e localizar próximo';

  @override
  String get sourceSearchReplaceAll => 'Substituir tudo';

  @override
  String get workspaceReplace => 'Substituir no espaço de trabalho';

  @override
  String get reviewReplacements => 'Rever substituições';

  @override
  String get applyReplacements => 'Aplicar substituições';

  @override
  String get skippedFiles => 'Ficheiros ignorados';

  @override
  String get workspaceReplaceDirtyBuffer => 'Conteúdo não guardado do editor';

  @override
  String get workspaceReplaceDiskContent => 'Conteúdo guardado no disco';

  @override
  String selectFileMatches(int count) {
    return 'Selecionar todas as $count correspondências';
  }

  @override
  String workspaceReplaceApplied(int matches, int files, int skipped) {
    return 'Foram substituídas $matches correspondências em $files ficheiros; $skipped ignoradas.';
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
      'Foi ignorado um ficheiro demasiado grande.';

  @override
  String get workspaceReplaceIssueUnreadable =>
      'Um ficheiro que não pôde ser lido foi ignorado.';

  @override
  String get workspaceReplaceIssueInvalidUtf8 =>
      'Um ficheiro que não é UTF-8 válido foi ignorado.';

  @override
  String get workspaceReplaceIssueTruncated =>
      'A pré-visualização de substituições foi truncada.';

  @override
  String get workspaceReplaceIssueFileChanged =>
      'Um ficheiro alterado após a pré-visualização foi ignorado.';

  @override
  String get workspaceReplaceIssueBufferChanged =>
      'Um buffer do editor alterado após a pré-visualização foi ignorado.';

  @override
  String get workspaceReplaceIssueNormalizationRequired =>
      'Escolha a normalização LF ou CRLF antes de substituir.';

  @override
  String get workspaceReplaceIssuePartialConflict =>
      'A reversão foi interrompida porque o ficheiro foi alterado simultaneamente. Algumas substituições podem permanecer; o conteúdo deslocado foi preservado no caminho abaixo.';

  @override
  String get workspaceReplaceIssueApplyFailed =>
      'Nenhuma substituição foi aplicada porque o conjunto revisto não pôde ser guardado com segurança.';

  @override
  String externalChangesTitle(String fileName) {
    return 'Alterações externas — $fileName';
  }

  @override
  String get externalFileDeleted => 'Este ficheiro foi eliminado do disco.';

  @override
  String get externalFileChanged =>
      'Este ficheiro foi alterado no disco enquanto existem alterações não guardadas no editor.';

  @override
  String recoveredDocumentReview(String fileName) {
    return 'O conteúdo não guardado de $fileName foi recuperado. Reveja-o e, em seguida, guarde-o, guarde-o como ou descarte-o.';
  }

  @override
  String get compare => 'Comparar';

  @override
  String get reloadFromDisk => 'Recarregar do disco';

  @override
  String get keepMine => 'Manter minha versão';

  @override
  String get saveAs => 'Guardar como';

  @override
  String get workspaceSearchIncomplete =>
      'Só são apresentados alguns resultados. Mostre mais ou restrinja a pesquisa.';

  @override
  String get workspaceSearchShowMore => 'Mostrar mais resultados';

  @override
  String get workspaceSearchSkippedFiles =>
      'A pesquisa está incompleta. Estes ficheiros excedem 1 MiB ou não foi possível lê-los:';

  @override
  String get sourceLargeFileFeaturesPaused =>
      'Ficheiro grande: o realce e o recolhimento estão pausados';

  @override
  String get nothingToRead => 'Nenhum conteúdo para ler';

  @override
  String get admonition => 'Bloco de destaque';

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
    return 'Destino da ligação não encontrado: $targetPath';
  }

  @override
  String get cannotOpenFileTypeInEditor =>
      'Não é possível abrir este tipo de ficheiro no editor';

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
  String get documentKindMarkdownFile => 'Ficheiro Markdown';

  @override
  String get documentKindWritersideMarkdownTopic =>
      'Tópico Markdown do Writerside';

  @override
  String get documentKindWritersideXmlTopic => 'Tópico XML do Writerside';

  @override
  String get documentKindWritersideTree => 'Árvore do Writerside';

  @override
  String get documentKindConfigurationFile => 'Ficheiro de configuração';

  @override
  String get documentKindVariablesFile => 'Ficheiro de variáveis';

  @override
  String get documentKindCategoriesFile => 'Ficheiro de categorias';

  @override
  String get documentKindResourceFile => 'Ficheiro de recursos';

  @override
  String workspaceErrorRecentWorkspaceUpdateFailed(String error) {
    return 'Não foi possível atualizar os itens recentes: $error.';
  }

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
    return 'Não foi possível abrir o ficheiro: $error';
  }

  @override
  String get workspaceErrorChooseWhereToSaveMarkdown =>
      'Escolha onde guardar este ficheiro Markdown.';

  @override
  String get workspaceErrorSaveBlockedFileChangedOnDisk =>
      'Gravação bloqueada: o ficheiro foi alterado no disco.';

  @override
  String workspaceErrorSaveFailed(String error) {
    return 'Falha ao guardar: $error';
  }

  @override
  String workspaceErrorFileOperationFailed(String error) {
    return 'Falha na operação de ficheiro: $error';
  }

  @override
  String workspaceErrorValidationFailed(String error) {
    return 'Falha na validação: $error';
  }

  @override
  String workspaceRecoveryRestored(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Foram recuperados $count documentos não guardados. Reveja cada um antes de o guardar ou descartar.',
      one:
          'Foi recuperado 1 documento não guardado. Reveja-o antes de o guardar ou descartar.',
    );
    return '$_temp0';
  }

  @override
  String workspaceRecoveryDamaged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Não foi possível restaurar $count registos de recuperação danificados. Os registos de recuperação válidos continuam disponíveis.',
      one:
          'Não foi possível restaurar 1 registo de recuperação danificado. O ficheiro de recuperação original foi preservado para inspeção.',
    );
    return '$_temp0';
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
    return 'O ficheiro gerado já existe: $path';
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
  String get errorFileNameRequired => 'O nome do ficheiro é obrigatório.';

  @override
  String get errorFileNameUnsafe =>
      'O nome do ficheiro deve ser um único segmento de caminho seguro.';

  @override
  String get errorFileOperationInvalidTarget =>
      'Não é possível mover uma pasta para dentro dela mesma.';

  @override
  String get errorFileOperationOutsideRoot =>
      'A operação de ficheiro deve permanecer dentro do espaço de trabalho.';

  @override
  String get errorFileOperationRoot =>
      'A raiz do espaço de trabalho não pode ser alterada pela árvore de ficheiros.';

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
      'O nome do ficheiro do tópico deve ser um nome de ficheiro Markdown sem separadores de caminho.';

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
    return 'O ficheiro de árvore do Writerside não existe: $path';
  }

  @override
  String errorTopicIdAlreadyExists(String topicId) {
    return 'O ID do tópico \"$topicId\" já existe neste módulo de ajuda.';
  }

  @override
  String errorTopicFileAlreadyExists(String path) {
    return 'O ficheiro do tópico já existe: $path';
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
    return 'Não é possível eliminar a página inicial $topic. Escolha primeiro outra página inicial.';
  }

  @override
  String get errorWritersideSafeDeleteRequired =>
      'Use a eliminação segura para ficheiros de tópicos do Writerside.';

  @override
  String get errorWritersideTopicUsageScanFailed =>
      'Não foi possível concluir a verificação dos usos do tópico. Nenhum ficheiro foi alterado.';

  @override
  String get errorWritersideTopicUsagesRemain =>
      'Alguns usos do tópico ainda precisam de atenção. Reveja-os antes de continuar.';

  @override
  String get errorWritersideRedirectInvalid =>
      'O destino de redirecionamento selecionado não é mais válido. Selecione-o novamente.';

  @override
  String errorWritersideRollbackFailed(String paths) {
    return 'Não foi possível reverter completamente a remoção do tópico. Reveja estes caminhos antes de continuar: $paths';
  }

  @override
  String errorWritersideTopicRenameIncompleteProjectIndex(
    String module,
    String count,
    String paths,
  ) {
    return 'A mudança de nome não pode atualizar com segurança todas as referências do projeto porque $count ficheiro(s) de tópico no módulo $module não foram analisados: $paths';
  }

  @override
  String get errorWritersideTopicRenameProjectBuffersDirty =>
      'Os ficheiros do projeto Writerside têm alterações não guardadas. Resolva-as e prepare uma nova pré-visualização da mudança de nome.';

  @override
  String get errorWritersideTopicRenameProjectInventoryChanged =>
      'O conjunto de módulos do projeto Writerside foi alterado. Prepare uma nova pré-visualização da mudança de nome antes da refatoração.';

  @override
  String get errorTopicsRootUnsafe =>
      'A raiz dos tópicos deve ser um diretório relativo seguro.';

  @override
  String get errorTopicFileNameUnsafe =>
      'O nome do ficheiro do tópico deve ser um único segmento de caminho seguro.';

  @override
  String errorTopicFileExtensionMismatch(String extension) {
    return 'A extensão do ficheiro do tópico deve corresponder ao formato selecionado ($extension).';
  }

  @override
  String get errorTopicFileNameInvalid =>
      'O nome do ficheiro do tópico deve conter apenas letras, números, sublinhados e hifens.';

  @override
  String errorUnknown(String code) {
    return 'Erro desconhecido: $code';
  }

  @override
  String diagnosticWorkspaceFileStatFailed(String error) {
    return 'Não foi possível ler os metadados do ficheiro: $error';
  }

  @override
  String get diagnosticWorkspaceScanSkipped =>
      'Foi detetado um espaço de trabalho grande. Alguns ficheiros foram ignorados para manter a aplicação responsiva.';

  @override
  String diagnosticWorkspaceScanInspectFailed(String error) {
    return 'Não foi possível inspecionar a entrada do espaço de trabalho: $error';
  }

  @override
  String get diagnosticWorkspaceFileTooLarge =>
      'O ficheiro excede o limite beta de análise automática.';

  @override
  String diagnosticWorkspaceFileReadFailed(String error) {
    return 'Não foi possível ler o ficheiro Markdown: $error';
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
    return 'O destino da ligação não existe: $targetPath';
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
      'A raiz do ficheiro writerside.cfg deve ser <ihp>.';

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
      'O ficheiro writerside.cfg não regista uma instância.';

  @override
  String get diagnosticWritersideTreeInvalidRoot =>
      'A raiz do ficheiro .tree deve ser <instance-profile>.';

  @override
  String get diagnosticWritersideTreeMissingId =>
      'O perfil da instância está sem o atributo id.';

  @override
  String diagnosticWritersideTreeIdMismatch(String id) {
    return 'O nome-base do ficheiro .tree não corresponde ao ID da instância \"$id\".';
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
      'A raiz do ficheiro .topic deve ser <topic>.';

  @override
  String get diagnosticWritersideTopicMissingRootId =>
      'A raiz do tópico XML está sem o atributo id.';

  @override
  String diagnosticWritersideTopicRootIdMismatch(String id, String expectedId) {
    return 'O ID raiz do tópico XML \"$id\" deve corresponder ao nome do ficheiro \"$expectedId\".';
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
      'O modo Writerside requer o ficheiro writerside.cfg.';

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
    return 'O ficheiro de variáveis configurado está ausente: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingCategoriesFile(String relativePath) {
    return 'O ficheiro de categorias configurado está ausente: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceGroupsFile(
    String relativePath,
  ) {
    return 'O ficheiro de grupos de instâncias configurado está ausente: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceTree(String source) {
    return 'A árvore de instância registada \"$source\" não existe.';
  }

  @override
  String diagnosticWritersideTopicReadFailed(String error) {
    return 'Não foi possível ler o ficheiro do tópico: $error';
  }

  @override
  String diagnosticWritersideDefaultTopicsDirectoryMissing(
    String relativePath,
  ) {
    return 'O diretório de tópicos predefinido está ausente: $relativePath';
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
  String diagnosticWritersideWebFileNameInvalid(
    String instanceId,
    String webFileName,
    String topic,
  ) {
    return 'A instância \"$instanceId\" publica o nome de ficheiro Web inválido \"$webFileName\" para o tópico \"$topic\".';
  }

  @override
  String diagnosticWritersideWebFileNameCollision(
    String instanceId,
    String webFileName,
    String firstTopic,
    String secondTopic,
  ) {
    return 'A instância \"$instanceId\" publica \"$firstTopic\" e \"$secondTopic\" como \"$webFileName\".';
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
    return 'Não foi possível resolver a ligação para o tópico \"$destination\".';
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
      'Os repositórios Git podem executar programas por meio de hooks, filtros e outras definições. Confie neste espaço de trabalho antes que o BusyMark leia os dados do repositório ou ative ações do Git.';

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
  String get gitStaged => 'Indexadas';

  @override
  String get gitUnstaged => 'Não indexadas';

  @override
  String get gitHistory => 'Histórico';

  @override
  String get gitBranches => 'Ramificações';

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
  String get gitSelectForCommit => 'Adicionar ficheiro ao índice';

  @override
  String get gitRemoveFromCommit => 'Remover ficheiro do índice';

  @override
  String get gitDiscard => 'Descartar';

  @override
  String get gitOpenFile => 'Abrir ficheiro';

  @override
  String get gitMarkResolved => 'Marcar como resolvido';

  @override
  String get gitUntracked => 'Ficheiros não monitorizados';

  @override
  String get gitCommitMessage => 'Mensagem de commit';

  @override
  String get gitCommitSelectedFiles => 'Ficheiros selecionados';

  @override
  String get gitCommitNoSelectedFiles =>
      'Adicione pelo menos um ficheiro ao índice antes de criar o commit.';

  @override
  String gitStagedFileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ficheiros no índice',
      one: '1 ficheiro no índice',
    );
    return '$_temp0';
  }

  @override
  String get gitOutsideWorkspace => 'Fora do espaço de trabalho';

  @override
  String get gitCommitMessageRequired => 'Introduza uma mensagem de commit.';

  @override
  String get gitCreateBranch => 'Criar ramificação';

  @override
  String get gitNewBranch => 'Nova ramificação';

  @override
  String get gitBranchName => 'Nome da ramificação';

  @override
  String get gitSwitchBranch => 'Trocar';

  @override
  String get gitNoChanges => 'Nenhuma alteração';

  @override
  String get gitNoHistory => 'Nenhum histórico';

  @override
  String get gitNoBranches => 'Nenhuma ramificação';

  @override
  String get gitNoDiff => 'Nenhuma diferença para apresentar';

  @override
  String get gitBinaryFile =>
      'Ficheiro binário. O BusyMark não apresenta patches binários.';

  @override
  String gitBinaryFileInfo(int size) {
    return 'Ficheiro binário ($size bytes). O BusyMark não apresenta patches binários.';
  }

  @override
  String get gitUnsavedChangesBanner =>
      'As alterações não guardadas do editor não são incluídas até serem guardadas.';

  @override
  String get gitConfirmDiscardTitle => 'Descartar alterações do Git?';

  @override
  String gitConfirmDiscardTracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Todas as alterações indexadas e não indexadas nos ficheiros monitorizados selecionados serão repostas para HEAD.',
      one:
          'Todas as alterações indexadas e não indexadas no ficheiro monitorizado selecionado serão repostas para HEAD.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardUntracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Os ficheiros não monitorizados selecionados serão eliminados.',
      one: 'O ficheiro não monitorizado selecionado será eliminado.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardMixed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Os ficheiros selecionados serão repostos ou eliminados consoante o respetivo estado no Git.',
      one:
          'O ficheiro selecionado será reposto ou eliminado consoante o respetivo estado no Git.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmSwitchBranchTitle(String branch) {
    return 'Trocar para $branch?';
  }

  @override
  String get gitConfirmSwitchBranchMessage =>
      'O BusyMark voltará a carregar o espaço de trabalho a partir do disco depois de o Git mudar de ramificação.';

  @override
  String get gitConfirmPushSetUpstreamTitle => 'Definir ramificação upstream?';

  @override
  String gitConfirmPushSetUpstreamMessage(String branch) {
    return 'Esta ramificação não tem upstream. O BusyMark pode enviar $branch e definir o respetivo upstream quando existir exatamente um remoto configurado.';
  }

  @override
  String get gitProjectHistory => 'Histórico do projeto';

  @override
  String get gitFileHistory => 'Histórico do ficheiro';

  @override
  String get gitFileHistoryRequiresOpenFile =>
      'O histórico do ficheiro requer um ficheiro Markdown aberto.';

  @override
  String get gitLoadMore => 'Carregar mais';

  @override
  String get gitChangesInCommit => 'Alterações neste commit';

  @override
  String get gitCompareWithCurrent => 'Comparar com a versão atual';

  @override
  String get gitRestoreVersion => 'Restaurar esta versão';

  @override
  String get gitConfirmRestoreTitle => 'Restaurar esta versão do ficheiro?';

  @override
  String get gitConfirmRestoreMessage =>
      'O BusyMark substituirá o ficheiro atual da árvore de trabalho pela versão selecionada do commit. O ficheiro reposto permanecerá fora do índice.';

  @override
  String get gitCommitActions => 'Ações do commit';

  @override
  String get gitResetCurrentBranchToHere =>
      'Redefinir a ramificação atual aqui…';

  @override
  String gitResetCurrentBranchTitle(String branch, String commit) {
    return 'Redefinir $branch para $commit?';
  }

  @override
  String gitResetCurrentBranchMessage(String branch, String commit) {
    return 'Isto move a ramificação $branch para o commit $commit. Escolha como o Git deve atualizar o índice e a árvore de trabalho.';
  }

  @override
  String get gitReset => 'Redefinir';

  @override
  String get gitResetModeSoft => 'Soft';

  @override
  String get gitResetModeSoftDescription =>
      'Mover apenas a ramificação. Manter o índice e a árvore de trabalho inalterados; as diferenças em relação ao commit selecionado permanecem no índice.';

  @override
  String get gitResetModeMixed => 'Mixed';

  @override
  String get gitResetModeMixedDescription =>
      'Mover a ramificação e redefinir o índice. Manter a árvore de trabalho inalterada, deixando as diferenças fora do índice.';

  @override
  String get gitResetModeHard => 'Hard';

  @override
  String get gitResetModeHardDescription =>
      'Mover a ramificação e redefinir o índice e a árvore de trabalho. As alterações monitorizadas são descartadas; os ficheiros não monitorizados que bloqueiam a operação podem ser eliminados.';

  @override
  String get gitResetModeKeep => 'Keep';

  @override
  String get gitResetModeKeepDescription =>
      'Mover a ramificação e redefinir os ficheiros monitorizados, preservando as alterações locais. O Git aborta se essas alterações entrarem em conflito com a redefinição.';

  @override
  String gitAdditionsDeletions(int additions, int deletions) {
    return '+$additions -$deletions';
  }

  @override
  String get fileActions => 'Ações do ficheiro';

  @override
  String get actions => 'Ações';

  @override
  String get gitStatusAdded => 'Adicionado';

  @override
  String get gitStatusDeleted => 'Eliminado';

  @override
  String get gitStatusRenamed => 'Renomeado';

  @override
  String get gitStatusCopied => 'Copiado';

  @override
  String get gitStatusUntracked => 'Não monitorizado';

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
  String get gitErrorInvalidBranchName =>
      'Introduza um nome de ramificação válido.';

  @override
  String get gitErrorNoRemote => 'Nenhum remoto Git está configurado.';

  @override
  String get gitErrorNoUpstream =>
      'Nenhuma ramificação upstream está configurada.';

  @override
  String get gitErrorMultipleRemotes =>
      'Há vários remotos configurados. Escolha um upstream fora desta versão do BusyMark.';

  @override
  String get gitErrorDirtyWorkspace =>
      'Guarde ou descarte as alterações do editor do BusyMark antes de trocar de ramificação.';

  @override
  String get gitErrorResetDirtyWorkspace =>
      'Guarde ou descarte as alterações no editor do BusyMark antes de redefinir a ramificação atual.';

  @override
  String get gitErrorRestoreStagedFile =>
      'Retire o ficheiro do índice antes de repor uma versão anterior.';

  @override
  String get gitErrorResetDetachedHead =>
      'Alterne para uma ramificação antes de redefini-la.';

  @override
  String get gitErrorDiverged =>
      'A ramificação divergiu. Resolva o merge ou o rebase fora desta versão do BusyMark.';

  @override
  String get gitErrorAuthorIdentity =>
      'O Git precisa do nome e do e-mail do autor antes de criar um commit.';

  @override
  String get gitAuthorIdentityTitle => 'Identidade do autor do Git';

  @override
  String get gitAuthorIdentityMessage =>
      'Indique a identidade que o Git deve registar nos commits. O BusyMark irá guardá-la e tentar este commit novamente.';

  @override
  String get gitAuthorName => 'Nome';

  @override
  String get gitAuthorEmail => 'E-mail';

  @override
  String get gitAuthorIdentityGlobal => 'Usar em todos os repositórios';

  @override
  String get gitAuthorIdentityGlobalDescription =>
      'Quando instalado como Snap, isto se aplica aos repositórios abertos no BusyMark.';

  @override
  String get gitSaveIdentityAndCommit => 'Guardar e criar commit';

  @override
  String get gitErrorAuthentication => 'A autenticação do Git falhou.';

  @override
  String get gitErrorNetwork => 'A operação de rede do Git falhou.';

  @override
  String get gitErrorConflict => 'O Git relatou conflitos não resolvidos.';

  @override
  String get gitErrorCommandFailed => 'O comando Git falhou.';

  @override
  String get syntaxReference => 'Referência de sintaxe';

  @override
  String get syntaxReferenceMarkdownBlocks => 'Blocos Markdown';

  @override
  String get syntaxReferenceMarkdownBlocksDescription =>
      'Estruturas de bloco compatíveis no código Markdown e na pré-visualização.';

  @override
  String get syntaxReferenceInlineFormatting => 'Markdown em linha';

  @override
  String get syntaxReferenceInlineFormattingDescription =>
      'Formatação dentro de parágrafos, itens de lista e células de tabela.';

  @override
  String get syntaxReferenceRawHtmlBlocks => 'Blocos de HTML bruto';

  @override
  String get syntaxReferenceRawHtmlBlocksDescription =>
      'Tags HTML de bloco seguras renderizadas pelos widgets de pré-visualização do BusyMark.';

  @override
  String get syntaxReferenceRawHtmlInline => 'Tags de HTML bruto em linha';

  @override
  String get syntaxReferenceRawHtmlInlineDescription =>
      'Tags HTML em linha seguras renderizadas sem mostrar as tags literais.';

  @override
  String get syntaxReferenceHeadings => 'Títulos';

  @override
  String get syntaxReferenceParagraphs => 'Parágrafos';

  @override
  String get syntaxReferenceLists => 'Listas';

  @override
  String get syntaxReferenceHtmlContainers => 'Contêineres';

  @override
  String get syntaxReferenceHtmlTextBlocks => 'Blocos de texto';

  @override
  String get syntaxReferenceHtmlFigures => 'Figuras e imagens';

  @override
  String get syntaxReferenceHtmlPreformatted => 'Código pré-formatado';

  @override
  String get syntaxReferenceHtmlDisclosure => 'Blocos expansíveis';

  @override
  String get syntaxReferenceHtmlDescriptionLists => 'Listas de descrição';

  @override
  String get syntaxReferenceHtmlFormattingTags => 'Tags de formatação';

  @override
  String get syntaxReferenceHtmlInlineCodeTags => 'Tags de código em linha';

  @override
  String get syntaxReferenceHtmlNeutralInlineTags => 'Tags de texto semântico';

  @override
  String get syntaxReferenceSanitizedPreviewDescription =>
      'O HTML permitido é convertido em blocos de pré-visualização do BusyMark e não é renderizado em um navegador.';

  @override
  String get syntaxReferenceSourcePreservedDescription =>
      'HTML bruto não editado é guardado exatamente como texto fonte.';

  @override
  String get syntaxReferenceMarkdownInsideHtmlDescription =>
      'Marcadores Markdown dentro de HTML bruto são apresentados como texto literal.';

  @override
  String get syntaxReferenceBlockedContentDescription =>
      'Scripts, estilos, frames, formulários, SVG, MathML, eventos e atributos inseguros são bloqueados.';

  @override
  String get syntaxReferenceSafeUrlsDescription =>
      'Ligações permitem http, https, mailto, tel, URLs relativas e fragmentos; esquemas inseguros são bloqueados.';

  @override
  String get syntaxReferenceCategory => 'Categoria';

  @override
  String get syntaxReferenceCategoryHtml => 'HTML';

  @override
  String get syntaxReferenceCategoryDiagramsAndApi => 'Diagramas e API';

  @override
  String get syntaxReferenceCategoryMathematics => 'Matemática';

  @override
  String get syntaxReferenceExample => 'Exemplo';

  @override
  String get syntaxReferenceIdentifiers => 'Identificadores e aliases';

  @override
  String get syntaxReferenceScope => 'Escopo';

  @override
  String get syntaxReferenceLimitation => 'Limitação do BusyMark';

  @override
  String get syntaxReferenceOfficialDocumentation => 'Documentação oficial';

  @override
  String get syntaxReferenceScopeWritersideMarkdown =>
      'Apenas Markdown do Writerside';

  @override
  String get syntaxReferenceScopeWritersideMarkdownAndXml =>
      'Apenas Markdown e XML do Writerside';

  @override
  String get syntaxReferenceMarkdownDescription =>
      'As formas essenciais de Markdown que o BusyMark pode criar e visualizar.';

  @override
  String get syntaxReferenceParagraphExample => 'Um parágrafo de texto.';

  @override
  String get syntaxReferenceTableLimitation =>
      'As tabelas usam a sintaxe de barras verticais do GitHub Flavored Markdown.';

  @override
  String get syntaxReferenceHardBreakIdentifiers =>
      'dois espaços no fim da linha, \\, <br>';

  @override
  String get syntaxReferenceHtmlDescription =>
      'O BusyMark aceita um subconjunto seguro e específico de HTML bruto no código Markdown.';

  @override
  String get syntaxReferenceDiagramsDescription =>
      'Blocos cercados Mermaid, PlantUML, D2 e OpenAPI funcionam no código Markdown. Os identificadores não diferenciam maiúsculas de minúsculas, e o BusyMark preserva a grafia original.';

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
      'Use conteúdo YAML ou JSON em um bloco cercado. O BusyMark não trata um documento YAML ou JSON completo qualquer como referência OpenAPI.';

  @override
  String get syntaxReferenceSemanticDiagramBlocks =>
      'Blocos de código semânticos para diagramas';

  @override
  String get syntaxReferenceSemanticDiagramLimitation =>
      'As formas semânticas code-block e src aceitam Mermaid, PlantUML e D2, não OpenAPI, e apenas em projetos Writerside.';

  @override
  String get syntaxReferenceReferencedDiagramSource =>
      'Origem de diagrama referenciada';

  @override
  String get syntaxReferenceReferencedDiagramLimitation =>
      'Os caminhos devem ser relativos e permanecer dentro do projeto Writerside aberto; a forma de bloco cercado com src é exclusiva do Markdown do Writerside.';

  @override
  String get syntaxReferenceMathematicsDescription =>
      'O BusyMark aceita expressões TeX, não documentos TeX ou LaTeX completos.';

  @override
  String get syntaxReferenceInlineMath => 'Matemática em linha';

  @override
  String get syntaxReferenceGithubMath =>
      'Matemática do GitHub com cifrão e crase';

  @override
  String get syntaxReferenceDisplayMath => 'Matemática em bloco';

  @override
  String get syntaxReferenceMathFence => 'Bloco cercado math';

  @override
  String get syntaxReferenceTexFence => 'Bloco cercado tex';

  @override
  String get syntaxReferenceMathDelimitersLimitation =>
      'O BusyMark não reconhece \\(...\\) nem \\[...\\] como delimitadores matemáticos do Markdown.';

  @override
  String get syntaxReferenceTexFenceLimitation =>
      'Fora do modo Writerside, um bloco tex continua sendo um bloco de código comum.';

  @override
  String get syntaxReferenceWritersideMathElement =>
      'Elemento math do Writerside';

  @override
  String get syntaxReferenceWritersideMathElementLimitation =>
      'O elemento math é sintaxe semântica do Writerside, não MathML HTML bruto permitido.';

  @override
  String get syntaxReferenceSemanticTexBlock => 'Bloco de código TeX semântico';

  @override
  String get syntaxReferenceWritersideDescription =>
      'Estas extensões específicas são interpretadas apenas em projetos Writerside abertos.';

  @override
  String get syntaxReferenceAdmonitionBlockquote => 'Citação de aviso';

  @override
  String get syntaxReferenceAdmonitionLimitation =>
      'Uma citação simples é uma dica no Markdown do Writerside; no Markdown comum, continua sendo uma citação normal.';

  @override
  String get syntaxReferenceSemanticAdmonitions => 'Avisos semânticos';

  @override
  String get syntaxReferenceSemanticMarkupLimitation =>
      'O Markdown comum não interpreta estes elementos semânticos do Writerside.';

  @override
  String get syntaxReferenceCollapsibleHeading => 'Título recolhível';

  @override
  String get syntaxReferenceCollapsibleCode => 'Bloco de código recolhível';

  @override
  String get syntaxReferenceSemanticCollapsibles =>
      'Conteúdo semântico recolhível';

  @override
  String get syntaxReferenceSemanticCollapsiblesLimitation =>
      'O BusyMark aceita as formas recolhíveis chapter, procedure, code-block e lista de definições, não todo o catálogo do Writerside.';

  @override
  String get syntaxReferenceSemanticCodeBlocks =>
      'Blocos de código semânticos para matemática e diagramas';

  @override
  String get syntaxReferenceVideo => 'Vídeo do Writerside';

  @override
  String get syntaxReferenceVideoLimitation =>
      'Vídeo local usa uma imagem preview-src local; fontes hospedadas devem ser URLs HTTPS compatíveis do YouTube ou Vimeo.';

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
  String get exportFormat => 'Formato de saída';

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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count avisos',
      one: '1 aviso',
    );
    return '$fileName foi exportado com $_temp0.';
  }

  @override
  String get pdfExportUnavailable =>
      'O componente de exportação para PDF está ausente. Reinstale o BusyMark e tente novamente.';

  @override
  String get pdfExportTimedOut =>
      'A exportação para PDF demorou demasiado e foi interrompida.';

  @override
  String get pdfExportFailed =>
      'O BusyMark não conseguiu exportar este documento como PDF.';

  @override
  String get visualizationRendering => 'A renderizar…';

  @override
  String get visualizationStale => 'A apresentar a última renderização válida';

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
  String get openTocFile => 'Abrir ficheiro do índice';

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
  String get instanceAppearance => 'Aparência';

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
      'Permitir indexação por mecanismos de busca';

  @override
  String get allowSearchEngineIndexingDescription =>
      'Permita que mecanismos de busca externos indexem esta saída.';

  @override
  String get offlineArtifact => 'Artefato offline';

  @override
  String get offlineArtifactDescription =>
      'Inclua os recursos para que a documentação gerada funcione de forma autônoma.';

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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Foram encontrados $count ficheiros Markdown',
      one: 'Foi encontrado 1 ficheiro Markdown',
    );
    return '$_temp0';
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
      'Um elemento do sumário não pode apontar para mais do que um tópico, referência, ligação ou redirecionamento.';

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
  String get download => 'Transferir';

  @override
  String get exportWritersideAsPdf => 'Exportar Writerside como PDF';

  @override
  String get writersidePdfContent => 'Conteúdo da exportação';

  @override
  String get writersidePdfPage => 'Página';

  @override
  String get exportingWritersidePdf => 'A exportar PDF do Writerside…';

  @override
  String get ai => 'IA';

  @override
  String get aiLocalOllama => 'Ollama local';

  @override
  String get aiDisabled => 'Desativado';

  @override
  String get aiExplicitEditingDescription =>
      'A edição com IA é iniciada apenas de forma explícita. O BusyMark envia apenas o contexto apresentado ao fornecedor selecionado e nunca aplica uma proposta sem revisão.';

  @override
  String get aiProvider => 'Fornecedor de IA';

  @override
  String get aiDefaultProvider => 'Fornecedor predefinido';

  @override
  String get aiConfigureProvider => 'Configurar fornecedor';

  @override
  String get aiChooseProvider => 'Escolher fornecedor de IA';

  @override
  String get aiOllamaEndpoint => 'Endpoint do Ollama';

  @override
  String get aiOllamaModel => 'Modelo do Ollama';

  @override
  String get aiTestConnection => 'Testar ligação';

  @override
  String get aiTestingConnection => 'A testar…';

  @override
  String aiConnectionReady(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Foram encontrados $count modelos instalados',
      one: 'Foi encontrado 1 modelo instalado',
    );
    return 'Conectado. $_temp0.';
  }

  @override
  String get aiNoModels => 'Nenhum modelo selecionado.';

  @override
  String get aiConnectionFailed =>
      'O BusyMark não conseguiu verificar a geração de texto por IA.';

  @override
  String get aiConfigureFirst =>
      'Ative um fornecedor de IA e verifique um modelo em Definições → IA.';

  @override
  String get aiEditWithAi => 'Editar com IA';

  @override
  String get aiRefineWithAi => 'Melhorar com IA';

  @override
  String get aiInstruction => 'Instrução';

  @override
  String get aiChangeTarget => 'O que pode ser alterado';

  @override
  String get aiSharedContext => 'Contexto partilhado com a IA';

  @override
  String get aiTargetSelection => 'Conteúdo selecionado';

  @override
  String get aiTargetInsertAfterBlock => 'Inserir após o bloco atual';

  @override
  String get aiTargetCurrentBlock => 'Bloco atual';

  @override
  String get aiTargetCurrentSection => 'Secção atual';

  @override
  String get aiTargetCompleteDocument => 'Documento completo';

  @override
  String get aiContextNone => 'Sem contexto do documento';

  @override
  String get aiContextSelection => 'Conteúdo selecionado';

  @override
  String get aiContextCurrentBlock => 'Bloco atual';

  @override
  String get aiContextCurrentSection => 'Secção atual';

  @override
  String get aiContextCompleteDocument => 'Documento completo';

  @override
  String get aiGenerating => 'A gerar proposta…';

  @override
  String get aiProposal => 'Proposta de IA';

  @override
  String get aiGenerateProposal => 'Gerar proposta';

  @override
  String aiContextDisclosure(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count carateres',
      one: '1 caráter',
      zero: '0 carateres',
    );
    return 'O fornecedor selecionado receberá $_temp0 do contexto apresentado.';
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
      'As alterações no índice mudaram enquanto esta mensagem de commit era gerada. Execute a ação novamente.';

  @override
  String get aiViewContext => 'Ver contexto enviado';

  @override
  String get aiReviewExactContent => 'Rever conteúdo exato';

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
  String get aiApiKeyEnterHint => 'Introduza uma chave de API do fornecedor';

  @override
  String get aiReplaceApiKey => 'Substituir chave de API';

  @override
  String get aiSaveApiKey => 'Guardar chave de API com segurança';

  @override
  String get aiRemoveApiKey => 'Remover chave de API guardada';

  @override
  String get aiCredentialSaved =>
      'A chave de API foi guardada no cofre de credenciais do sistema.';

  @override
  String get aiCredentialRemoved => 'A chave de API guardada foi removida.';

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
    return '$requests pedidos · $input tokens de entrada · $output tokens de saída';
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
      'Apenas o conteúdo apresentado em cada caixa de diálogo de revisão de IA é enviado. Os pedidos não mantêm estado, as propostas exigem revisão e a chave de API é guardada no cofre de credenciais do sistema Linux.';

  @override
  String aiCloudConsentRequired(String provider) {
    return 'Primeiro, confirme a partilha de dados com $provider em Definições → IA.';
  }

  @override
  String aiGenerationVerified(String model, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Há $count modelos compatíveis disponíveis',
      one: 'Há 1 modelo compatível disponível',
      zero: 'Há 0 modelos compatíveis disponíveis',
    );
    return 'Geração verificada com $model. $_temp0.';
  }

  @override
  String get aiColdStartObserved =>
      'Foi detetado um arranque a frio do modelo local.';

  @override
  String get aiNoCompatibleModels =>
      'Não há nenhum modelo compatível de geração de texto disponível.';

  @override
  String get aiEnableProvider => 'Primeiro, ative um fornecedor de IA.';

  @override
  String get aiDraftCommitMessage => 'Criar rascunho da mensagem de commit';

  @override
  String get aiDrafting => 'A criar rascunho…';

  @override
  String get aiDraftWithAi => 'Criar rascunho com IA';

  @override
  String diagnosticMarkdownHeadingSkippedLevel(int level, int previousLevel) {
    return 'O título de nível $level vem após o nível $previousLevel; reveja o aninhamento das secções.';
  }

  @override
  String get diagnosticMarkdownLinkEmptyText =>
      'O texto da ligação está vazio; forneça um nome acessível que descreva a respetiva finalidade.';

  @override
  String diagnosticMarkdownLinkReviewText(String text) {
    return 'Verifique se o texto da ligação “$text” descreve a respetiva finalidade no contexto.';
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

  @override
  String get goToDeclaration => 'Ir para a declaração';

  @override
  String get findUsages => 'Encontrar utilizações';

  @override
  String get cannotRenameSymbol =>
      'Não é possível mudar o nome do símbolo com segurança. Verifique o nome e atualize a referência antes de tentar novamente.';

  @override
  String get renameTopicFileInstead =>
      'Os IDs dos tópicos provêm dos nomes dos ficheiros. Utilize Mudar o nome do ficheiro de tópico no índice ou na barra lateral Ficheiros.';

  @override
  String get keyboardLayout => 'Disposição do teclado';

  @override
  String get diagnosticWritersideUnsupported =>
      'O conteúdo não suportado ou malformado é apresentado como código-fonte.';

  @override
  String diagnosticWritersideSource(String reference, String reason) {
    return 'Não é possível resolver a origem «$reference»: $reason';
  }

  @override
  String diagnosticWritersideLink(String destination) {
    return 'O destino da ligação não está disponível nesta instância: $destination';
  }

  @override
  String diagnosticWritersideSchema(
    String element,
    String attribute,
    String reason,
  ) {
    return 'Marcação Writerside inválida: $element, $attribute. $reason';
  }

  @override
  String get diagnosticWritersideLlmsTxt =>
      'Use <llms-txt>true</llms-txt> ou <llms-txt>false</llms-txt>; single-file deixou de ser suportado.';

  @override
  String diagnosticWritersideReference(String kind, String reference) {
    return 'Não é possível resolver $kind: $reference';
  }

  @override
  String get exportAsHtml => 'Exportar como HTML…';

  @override
  String get fileTypeHtml => 'Documento HTML';

  @override
  String get exportingHtml => 'A exportar HTML…';

  @override
  String get htmlExported => 'Exportação HTML concluída';

  @override
  String get htmlExportFailed => 'Falha na exportação HTML';

  @override
  String get htmlKeepAssetsTogether =>
      'Ao copiar esta exportação, mantenha juntos o ficheiro HTML e a pasta de recursos associada.';

  @override
  String get htmlInstanceDescription =>
      'Exporte uma instância como páginas ligadas offline. Escolha um nome para uma pasta de destino dedicada.';

  @override
  String get htmlInstance => 'Instância';

  @override
  String get htmlOwnedDirectoryOnly =>
      'Só é possível substituir uma pasta criada pela exportação HTML do BusyMark. Os ficheiros modificados ou alheios serão preservados.';

  @override
  String get showInFolder => 'Mostrar na pasta';

  @override
  String sortTableColumn(String column) {
    return 'Ordenar $column';
  }

  @override
  String get exportReset => 'Restaurar predefinições';

  @override
  String get exportToc => 'Incluir índice';

  @override
  String get exportTocDepth => 'Profundidade do índice';

  @override
  String get exportNumberHeadings => 'Numerar títulos';

  @override
  String get exportLegal => 'US Legal';

  @override
  String get exportCustom => 'Personalizado';

  @override
  String get exportPageWidth => 'Largura da página (mm)';

  @override
  String get exportPageHeight => 'Altura da página (mm)';

  @override
  String get exportMarginTop => 'Margem superior (mm)';

  @override
  String get exportMarginRight => 'Margem direita (mm)';

  @override
  String get exportMarginBottom => 'Margem inferior (mm)';

  @override
  String get exportMarginLeft => 'Margem esquerda (mm)';

  @override
  String get exportTypography => 'Tipografia';

  @override
  String get exportSans => 'Sem serifas';

  @override
  String get exportSerif => 'Com serifas';

  @override
  String get exportBodySize => 'Tamanho do texto';

  @override
  String get exportCodeSize => 'Tamanho do código';

  @override
  String get exportRunningText => 'Cabeçalho e rodapé';

  @override
  String get exportHeader => 'Cabeçalho';

  @override
  String get exportFooter => 'Rodapé';

  @override
  String get exportNone => 'Nenhum';

  @override
  String get exportDocumentTitle => 'Título do documento';

  @override
  String get exportBottomLeft => 'Em baixo à esquerda';

  @override
  String get exportBottomCenter => 'Em baixo ao centro';

  @override
  String get exportBottomRight => 'Em baixo à direita';

  @override
  String get exportFirstPage => 'Mostrar cabeçalho e rodapé na primeira página';

  @override
  String get exportAccent => 'Cor de destaque / ligações';

  @override
  String get exportTheme => 'Tema';

  @override
  String get exportAutomatic => 'Automático';

  @override
  String get exportLayout => 'Disposição';

  @override
  String get exportContentWidth => 'Largura máxima do conteúdo';

  @override
  String get exportOutput => 'Saída';

  @override
  String get exportPackaging => 'Empacotamento';

  @override
  String get exportSingleFile => 'Um único ficheiro HTML';

  @override
  String get exportAssetsDirectory => 'HTML + pasta de recursos';

  @override
  String get exportCustomCss => 'Folha de estilo personalizada…';

  @override
  String get exportRemoveCss => 'Remover folha de estilo';

  @override
  String get exportCssNote =>
      'Escolha um ficheiro CSS UTF-8 opcional (até 256 KiB). Importações, URL de recursos e CSS executável ou com escapes são rejeitados. Os estilos seguem os do BusyMark. Nunca são transferidos recursos remotos.';

  @override
  String get exportSitePackagingNote =>
      'O Writerside mantém páginas de tópicos separadas e ligadas. O modo de ficheiro único incorpora os recursos em cada página.';

  @override
  String get exportInvalidGeometry =>
      'Deixe pelo menos 20 mm de largura e altura de conteúdo após as margens.';

  @override
  String get exportInvalidColor => 'Introduza uma cor como #RRGGBB.';

  @override
  String get exportInvalidCss =>
      'Escolha um ficheiro .css UTF-8 legível até 256 KiB, sem importações, URL de recursos, HTML ou CSS executável ou com escapes.';

  @override
  String get clipboardHistory => 'Histórico da Área de Transferência';

  @override
  String get clipboardHistoryDescription =>
      'Abrir o histórico da área de transferência local da sessão.';

  @override
  String get clipboardCurrent => 'Área de transferência atual';

  @override
  String get clipboardCurrentExternal =>
      'Área de transferência de outro aplicativo';

  @override
  String clipboardDestination(String name) {
    return 'Colar em $name';
  }

  @override
  String get clipboardSessionOnly =>
      'Armazenado apenas para esta sessão BusyMark.';

  @override
  String get clipboardNoItems =>
      'O histórico da área de transferência está vazio.';

  @override
  String get clipboardDisabled =>
      'A coleção de Histórico da Área de Transferência está desativada nas Configurações.';

  @override
  String get clipboardUnavailable =>
      'O conteúdo da área de transferência atual não está disponível ou não é suportado.';

  @override
  String get clipboardTooLarge =>
      'Este item na área de transferência é demasiado grande para manter.';

  @override
  String get clipboardPastePlainText => 'Colar como Texto Simples';

  @override
  String get clipboardClearAll => 'Limpar o Histórico da Área de Transferência';

  @override
  String get clipboardEntryText => 'Texto';

  @override
  String get clipboardEntryRichText => 'Texto formatado';

  @override
  String get clipboardEntryImage => 'Imagem';

  @override
  String clipboardOrigin(String name) {
    return 'Copiado de $name';
  }

  @override
  String get localHistory => 'Histórico Local';

  @override
  String get localHistoryEllipsis => 'Histórico Local…';

  @override
  String get localHistoryDescription =>
      'Mostrar as revisões locais salvas e automáticas para o documento atual.';

  @override
  String get findLocalHistoryEllipsis => 'Encontrar no Histórico Local…';

  @override
  String get findLocalHistoryDescription =>
      'Procurar documentos e conteúdos de revisão no Histórico Local.';

  @override
  String get localHistoryNoDocuments => 'Nenhum documento tem Histórico Local.';

  @override
  String get localHistoryNoRevisions =>
      'Este documento não tem revisões no Histórico Local.';

  @override
  String get localHistorySelectedRevision => 'Revisão selecionada';

  @override
  String get localHistoryCurrentEditor => 'Conteúdo atual do editor';

  @override
  String get localHistoryCurrentDisk => 'Conteúdo atual no disco';

  @override
  String get localHistoryMissingFile => 'O ficheiro original está ausente.';

  @override
  String get localHistoryRestoreRevision => 'Restaurar Versão';

  @override
  String get localHistoryRestoreOriginalLocation =>
      'Restaurar para Localização Original';

  @override
  String get localHistoryRestoreNewLocation =>
      'Restaurar para Nova Localização…';

  @override
  String get localHistoryRestoreChange => 'Restaurar Alteração';

  @override
  String get localHistoryRestoreUnavailable =>
      'Esta alteração não pode ser restaurada porque a comparação não está mais atualizada.';

  @override
  String get localHistoryComparisonSimplified =>
      'Esta alteração grande foi simplificada. Restaurar alterações individuais não está disponível.';

  @override
  String localHistoryOlderChange(String text) {
    return 'Alteração de versão anterior: $text';
  }

  @override
  String localHistoryCurrentChange(String text) {
    return 'Alteração de conteúdo atual: $text';
  }

  @override
  String get localHistoryDeleted => 'Excluído';

  @override
  String get localHistoryUntitled => 'Sem título';

  @override
  String get localHistoryClearDocument => 'Limpar o Histórico deste Documento';

  @override
  String get localHistoryClearAll => 'Limpar Todo o Histórico Local';

  @override
  String get localHistoryClearDocumentTitle =>
      'Limpar o Histórico do Documento?';

  @override
  String get localHistoryClearAllTitle => 'Limpar Todo o Histórico Local?';

  @override
  String get localHistoryClearConfirmation =>
      'Isto elimina permanentemente as versões armazenadas. Esta ação não pode ser desfeita.';

  @override
  String get localHistoryWarningIndexRebuilt =>
      'O índice do Histórico Local foi danificado e reconstruído a partir de versões intactas.';

  @override
  String localHistoryWarningUnsupportedFormat(String version) {
    return 'Esta loja de Histórico Local utiliza um formato não suportado $version.';
  }

  @override
  String localHistoryWarningUnavailable(String detail) {
    return 'O Histórico Local não está disponível: $detail';
  }

  @override
  String get localHistoryWarningRecordingDisabled =>
      'A gravação está desativada ou este caminho está excluído. Reative a gravação antes de restaurar.';

  @override
  String localHistoryWarningPathChange(String detail) {
    return 'O Histórico Local não conseguiu gravar a alteração do caminho: $detail';
  }

  @override
  String localHistoryWarningDeletedPath(String detail) {
    return 'O Histórico Local não conseguiu reter o caminho eliminado: $detail';
  }

  @override
  String get localHistoryWarningRevisionMissing =>
      'A revisão selecionada está ausente ou danificada.';

  @override
  String localHistoryWarningRevisionRead(String detail) {
    return 'A revisão selecionada não pode ser lida: $detail';
  }

  @override
  String localHistoryWarningCapture(String detail) {
    return 'O Histórico Local não conseguiu capturar esta revisão: $detail';
  }

  @override
  String localHistoryRevisionAt(String reason, String timestamp) {
    return '$reason – $timestamp';
  }

  @override
  String get localHistoryReasonBaseline => 'Linha Base';

  @override
  String get localHistoryReasonSaved => 'Guardado';

  @override
  String get localHistoryReasonAutomaticCheckpoint => 'Checkpoint automático';

  @override
  String get localHistoryReasonBeforeReload => 'Antes de recarregar';

  @override
  String get localHistoryReasonBeforeDiscard => 'Antes de descartar';

  @override
  String get localHistoryReasonBeforeRestore => 'Antes de restaurar';

  @override
  String get localHistoryReasonBeforeDelete => 'Antes de apagar';

  @override
  String get localHistoryReasonExternalChange => 'Alteração externa';

  @override
  String get settingsHistory => 'Histórico';

  @override
  String get settingsClipboardHistoryTitle =>
      'Recolher Histórico da Área de Transferência';

  @override
  String get settingsClipboardHistoryDescription =>
      'Manter o conteúdo copiado e colado com sucesso apenas para esta sessão BusyMark.';

  @override
  String get settingsLocalHistoryTitle => 'Gravar Histórico Local';

  @override
  String get settingsLocalHistoryDescription =>
      'Armazenar as versões do documento neste dispositivo para recuperação e comparação.';

  @override
  String get settingsHistoryCheckpoint =>
      'Intervalo de ponto de controlo automático';

  @override
  String get settingsHistoryRetention => 'Período de retenção';

  @override
  String get settingsHistoryStorage => 'Armazenamento máximo';

  @override
  String get settingsHistoryExcludedPaths => 'Caminhos excluídos';

  @override
  String get settingsHistoryExcludedPathsHint =>
      'Um caminho absoluto por linha';

  @override
  String settingsSecondsValue(int value) {
    return '$value segundos';
  }

  @override
  String settingsDaysValue(int value) {
    return '$value dias';
  }

  @override
  String settingsMebibytesValue(int value) {
    return '$value MiB';
  }

  @override
  String get spelling => 'Ortografia';

  @override
  String get automaticSpelling => 'Verificação ortográfica automática';

  @override
  String get defaultSpellingLanguage => 'Idioma ortográfico predefinido';

  @override
  String get projectSpellingLanguage =>
      'Idioma de verificação ortográfica do projeto';

  @override
  String get chooseSpellingLanguage => 'Escolher idioma ortográfico';

  @override
  String get spellingLanguageUnsetStatus => 'Idioma…';

  @override
  String get spellingOffStatus => 'Ortografia desativada';

  @override
  String get checkSpelling => 'Verificar ortografia';

  @override
  String get ignoreSpellingOnce => 'Ignorar uma vez';

  @override
  String get ignoreSpellingDocument => 'Ignorar tudo neste documento';

  @override
  String get addPersonalSpellingWord => 'Adicionar ao dicionário pessoal';

  @override
  String get addProjectSpellingWord => 'Adicionar ao dicionário do projeto';

  @override
  String get inheritSpellingLanguage =>
      'Usar o idioma do projeto ou da aplicação';

  @override
  String get disableDocumentSpelling => 'Não verificar a ortografia';

  @override
  String get importSpellingDictionary => 'Importar dicionário';

  @override
  String get personalSpellingDictionary => 'Dicionário pessoal';

  @override
  String get projectSpellingDictionary => 'Dicionário do projeto';

  @override
  String get noSpellingErrors => 'Sem erros ortográficos';

  @override
  String get noSpellingSuggestions => 'Sem sugestões ortográficas';

  @override
  String get spellingWordCheckFailed =>
      'Não foi possível verificar esta palavra';

  @override
  String get spellingCheckFailed => 'A verificação ortográfica falhou';

  @override
  String get spellingSettingsLoadFailed =>
      'Não foi possível carregar as definições de verificação ortográfica';

  @override
  String get retrySpellingSettings =>
      'Tentar carregar novamente as definições de verificação ortográfica';

  @override
  String get spellingCheckIncomplete =>
      'A verificação ortográfica está incompleta';

  @override
  String get spellingDictionaryNotInstalled => 'Dicionário não instalado';

  @override
  String spellingDictionaryNotInstalledForLanguage(String dictionary) {
    return 'O dicionário de $dictionary não está instalado';
  }

  @override
  String spellingDictionaryNotInstalledWithSize(String size) {
    return 'Não instalado · $size';
  }

  @override
  String get spellingDictionaryInstalled => 'Instalado';

  @override
  String get installSpellingDictionary => 'Instalar dicionário';

  @override
  String get removeSpellingDictionary => 'Remover dicionário';

  @override
  String get cancelSpellingDictionaryInstall =>
      'Cancelar transferência do dicionário';

  @override
  String get retrySpellingDictionaryInstall =>
      'Repetir instalação do dicionário';

  @override
  String spellingDictionaryDownloading(String size) {
    return 'A transferir $size…';
  }

  @override
  String get spellingDictionaryValidating => 'A validar o dicionário…';

  @override
  String get spellingDictionaryInstallFailed =>
      'A instalação falhou — selecione para repetir';

  @override
  String spellingDictionaryInstallPrompt(String dictionary, String size) {
    return 'Instalar $dictionary ($size)? Depois de instalado, ficará disponível offline até ser removido.';
  }

  @override
  String get spellingDictionaryUnavailable => 'Dicionário indisponível';

  @override
  String get spellingChecking => 'A verificar a ortografia…';

  @override
  String exportInvalidRange(String field, String minimum, String maximum) {
    return '$field: introduza um número entre $minimum e $maximum.';
  }

  @override
  String get spellingDictionaryRecoveryConflict =>
      'O dicionário ortográfico foi alterado externamente. Foi preservada uma cópia de recuperação.';

  @override
  String get windowMinimize => 'Minimizar';

  @override
  String get windowMaximize => 'Maximizar';

  @override
  String get windowRestore => 'Restaurar';

  @override
  String get nextcloudNotes => 'Nextcloud Notes';

  @override
  String get nextcloudConnect => 'Ligar';

  @override
  String get nextcloudReconnect => 'Voltar a ligar';

  @override
  String get nextcloudDisconnect => 'Desligar';

  @override
  String get nextcloudServer => 'URL do servidor';

  @override
  String get nextcloudSignInBrowser =>
      'Conclua o início de sessão no navegador.';

  @override
  String get nextcloudFavorites => 'Favoritos';

  @override
  String get nextcloudNewNote => 'Nova nota';

  @override
  String get nextcloudSavedLocally =>
      'Guardado localmente · sincronização pendente';

  @override
  String get nextcloudSyncing => 'A sincronizar';

  @override
  String get nextcloudSynced => 'Sincronizado';

  @override
  String get nextcloudOffline => 'Sem ligação';

  @override
  String get nextcloudLocked => 'Bloqueado pelo servidor';

  @override
  String get nextcloudReconnectRequired => 'É necessário voltar a ligar';

  @override
  String get nextcloudCreationUncertain => 'Resultado da criação incerto';

  @override
  String get nextcloudReadOnly => 'Só de leitura';

  @override
  String get nextcloudTakeRemote => 'Usar versão remota';

  @override
  String get nextcloudMerge => 'Unir';

  @override
  String get nextcloudDeleteNote => 'Eliminar nota?';

  @override
  String get nextcloudWorkspaceReplaceUnavailable =>
      'A substituição no espaço de trabalho não está disponível para Nextcloud Notes. Substitua em cada nota.';

  @override
  String get nextcloudSaveLocalCopy => 'Guardar cópia local…';

  @override
  String get nextcloudDisconnectWarning =>
      'Remover esta conta elimina as notas em cache e alterações pendentes deste dispositivo. Sincronize primeiro para guardar o trabalho no servidor.';

  @override
  String get nextcloudAttachmentRetryWarning =>
      'Se o envio anterior foi concluído, tentar novamente pode deixar um anexo não utilizado no servidor.';

  @override
  String get nextcloudAttachmentReference => 'Referência do anexo no servidor';

  @override
  String get nextcloudAddAttachment => 'Adicionar anexo…';

  @override
  String get nextcloudDeleteAttachmentWarning =>
      'Ao eliminar este anexo, as suas ligações na nota deixam de estar disponíveis. Os dados conservados podem ser recuperados através do histórico local.';

  @override
  String get nextcloudChooseConflictingAttributes =>
      'Escolha cada atributo em conflito.';

  @override
  String get nextcloudUseServerNote => 'Usar esta nota do servidor';

  @override
  String get nextcloudUseServerNoteExplanation =>
      'Associa este rascunho à nota selecionada no servidor e depois sincroniza as alterações locais preservadas. Um pedido correspondente não confirma quem criou a nota.';

  @override
  String get nextcloudExactCandidate =>
      'Correspondência exata com o pedido; identidade não confirmada.';

  @override
  String get nextcloudPossibleCandidate =>
      'Possível correspondência após normalização; identidade não confirmada.';

  @override
  String get nextcloudSelectCandidate =>
      'Selecionar uma nota do servidor para rever';

  @override
  String get nextcloudCreateSeparate => 'Criar uma nota separada';

  @override
  String get nextcloudCreateSeparateWarning =>
      'O primeiro pedido pode já ter criado uma nota no servidor. Isto cria uma nota separada com o trabalho local preservado. Nenhum possível duplicado será eliminado.';

  @override
  String get wsSemanticFormats => 'Formatação semântica';

  @override
  String get wsUiControl => 'Controlo da interface';

  @override
  String get wsFilePath => 'Ficheiro / Caminho';

  @override
  String get wsUiPath => 'Caminho da interface';

  @override
  String get wsDefinitionList => 'Lista de definições';

  @override
  String get wsIncludeContent => 'Incluir conteúdo reutilizável';

  @override
  String get wsVariableReference => 'Referência de variável';

  @override
  String get wsConvertList => 'Converter lista em procedimento';

  @override
  String get wsElementProperties => 'Propriedades do elemento';

  @override
  String get wsTopicProperties => 'Propriedades do tópico';

  @override
  String get wsCollapsible => 'Recolhível';

  @override
  String get wsPublishedState => 'Estado inicial publicado';

  @override
  String get wsExpanded => 'Expandido';

  @override
  String get wsCollapsed => 'Recolhido';

  @override
  String get wsCollapsedTitle => 'Título recolhido';

  @override
  String get wsTerm => 'Termo';

  @override
  String get wsListLayout => 'Disposição da lista';

  @override
  String get wsSyncGroup => 'Grupo de sincronização';

  @override
  String get wsTabKey => 'Chave do separador';

  @override
  String get wsSwitcherLabel => 'Etiqueta do seletor';

  @override
  String get wsNavigationElements => 'Elementos de navegação';

  @override
  String get wsNavigationDepth => 'Profundidade de navegação';

  @override
  String get wsAddItem => 'Adicionar item';

  @override
  String get wsStep => 'Passo';

  @override
  String get wsPropertyInvalid => 'Valor de propriedade inválido';

  @override
  String get wsFilter => 'Filtro';

  @override
  String get wsIdentifier => 'ID do elemento';

  @override
  String get wsTldr => 'Resumo (TLDR)';

  @override
  String get wsFullLayout => 'Largura total';

  @override
  String get wsMediumLayout => 'Médio (1:2)';

  @override
  String get wsNarrowLayout => 'Coluna de termo estreita';

  @override
  String get wsTitle => 'Título';

  @override
  String get wsSwitcherKey => 'Chave do seletor';

  @override
  String get nextcloudServerSettings => 'Definições de Notes do servidor';

  @override
  String get nextcloudNotesPath => 'Caminho da pasta de notas';

  @override
  String get nextcloudFileSuffix => 'Extensão de novas notas';

  @override
  String get nextcloudServerSettingsExplanation =>
      'Estas definições de Notes afetam outros clientes. Alterar o caminho não move ficheiros; alterar a extensão não renomeia notas existentes.';

  @override
  String get nextcloudSettingsSaved => 'Definições do servidor guardadas';

  @override
  String get nextcloudSettingsNormalized =>
      'Guardado com valores normalizados pelo servidor';

  @override
  String get nextcloudPendingUpload => 'Envio de anexo pendente';

  @override
  String nextcloudServerCheck(String time) {
    return 'Última verificação do servidor: $time';
  }

  @override
  String get nextcloudSettingsLoading => 'A carregar as definições do servidor';

  @override
  String get nextcloudSettingsSaving => 'A guardar as definições do servidor';

  @override
  String get nextcloudPreviousLocalEdit => 'Edição local anterior';

  @override
  String get nextcloudUsePreviousEdit => 'Usar edição anterior';

  @override
  String get quickOpen => 'Abertura rápida';

  @override
  String get notesAll => 'Todas as notas';

  @override
  String get notesUncategorized => 'Sem categoria';

  @override
  String get notesRecovery => 'Recuperação';

  @override
  String get notesRecentlyEdited => 'Editadas recentemente';

  @override
  String get notesOldestEdited => 'Edições mais antigas';

  @override
  String get notesTitleAscending => 'Título A–Z';

  @override
  String get notesTitleDescending => 'Título Z–A';

  @override
  String get notesMove => 'Mover para categoria';

  @override
  String get notesRemoveFavorite => 'Remover favorito';

  @override
  String get notesOffline => 'Disponibilizar offline';

  @override
  String get notesOfflineRemove => 'Remover retenção offline';

  @override
  String get notesIndexing => 'A indexar notas…';

  @override
  String get notesSearchHelp =>
      'Os termos usam E. Use \"frases entre aspas\", title: e category:.';

  @override
  String get notesSourceLocation => 'Localização no código fonte';

  @override
  String get notesRecoveryHelp =>
      'Apenas notas locais retidas e histórico local. O lixo e o histórico do servidor não estão disponíveis.';

  @override
  String get notesImport => 'Importar notas';

  @override
  String get notesExport => 'Exportar notas';

  @override
  String get notesImportDistinct => 'Importar como nota distinta';

  @override
  String get notesAvailableOffline => 'Disponível offline';

  @override
  String get notesIncomplete => 'Incompleto';

  @override
  String get notesSelected => 'Notas selecionadas';

  @override
  String get notesNoHistory =>
      'Não há revisões retidas. O histórico pode estar desativado, expirado ou apagado.';

  @override
  String get notesTextAvailable => 'Texto disponível localmente';

  @override
  String get notesLocalVersion => 'Versão de trabalho local';

  @override
  String get notesAttachments => 'Anexos';

  @override
  String get notesSkipped => 'Ignorado';

  @override
  String get notesFailed => 'Falhou';

  @override
  String get notesCompleted => 'Concluído';

  @override
  String get notesImportNew => 'Iniciar nova importação';

  @override
  String get notesImportResume => 'Retomar importação interrompida';

  @override
  String get notesImportAlreadyImported => 'Já importado nesta operação';

  @override
  String get references => 'Referências';

  @override
  String get referenceIncoming => 'Recebidas';

  @override
  String get referenceOutgoing => 'Enviadas';

  @override
  String get referenceChooseTarget => 'Escolher destino da ligação';

  @override
  String get referenceWholeDocument => 'Documento completo';

  @override
  String get referenceSourceLocation => 'Localização de origem';

  @override
  String get referenceTargetLocation => 'Localização de destino';

  @override
  String get referenceResolved => 'Resolvida';

  @override
  String get referenceMissing => 'Em falta';

  @override
  String get referenceAmbiguous => 'Ambígua';

  @override
  String get referenceUnavailable => 'Indisponível neste contexto';

  @override
  String get referenceUnsupported => 'Não suportada';

  @override
  String get referenceNoPortableId =>
      'Este destino não tem um URL portátil de nota verificado.';

  @override
  String get wsIncludeLines => 'Incluir linhas';

  @override
  String get wsIncludeSymbol => 'Incluir símbolo';

  @override
  String get wsEmphasizeLines => 'Realçar linhas exibidas';

  @override
  String get wsPropertiesReadOnly =>
      'Propriedades somente leitura nesta visualização.';

  @override
  String get wsPropertiesProtected => 'Elemento protegido. Edite sua fonte.';

  @override
  String get wsPropertiesConflict =>
      'Documento ou elemento alterado. Reverta o rascunho e selecione novamente.';

  @override
  String get wsPropertiesUnresolved =>
      'Não é possível resolver a referência no momento.';

  @override
  String get wsUseDefault => 'Usar padrão';

  @override
  String get wsPropertiesSelection => 'Selecione um único elemento.';

  @override
  String get wsImageDisplay => 'Exibição de imagem';

  @override
  String get wsImageThumbnail => 'Miniatura clicável';

  @override
  String get wsEnabled => 'Ativado';

  @override
  String get wsDisabled => 'Desativado';

  @override
  String get wsWidth => 'Largura';

  @override
  String get wsHeight => 'Altura';

  @override
  String get wsPropertiesInactive =>
      'Esta propriedade não tem efeito sem recolhimento publicado.';

  @override
  String get wsNavigationAll => 'Todos os elementos com título';

  @override
  String get wsNavigationNone => 'Sem navegação';

  @override
  String get wsNavigationCustom => 'Navegação personalizada';

  @override
  String get wsTitleOverride => 'Substituir título';

  @override
  String get wsCompactLayout => 'Compacto';

  @override
  String get wsWideLayout => 'Largo';

  @override
  String get wsCodeSourceConflict =>
      'Mova ou remova o código escrito neste bloco antes de definir src. O Writerside rejeita um bloco de código não vazio com uma referência de origem.';

  @override
  String get wsInherited => 'Herdar da lista';

  @override
  String get wsExternalImageSize =>
      'Writerside não dimensiona imagens externas de forma confiável. As dimensões existentes podem ser consultadas e removidas.';

  @override
  String get wsPropertiesNotSerialized =>
      'Esta alteração não foi aplicada ao código fonte. O rascunho foi mantido.';

  @override
  String get wsListItem => 'Item da lista';

  @override
  String get wsSourceFile => 'Arquivo de origem';

  @override
  String get wsLinkTarget => 'Destino do link';

  @override
  String get wsPreviewImage => 'Imagem de prévia';

  @override
  String get wsIncludedElement => 'Elemento incluído';

  @override
  String get wsHelpModule => 'Módulo de ajuda';

  @override
  String get wsActionId => 'ID da ação';

  @override
  String get wsKeymapHelpInstance => 'Instância de ajuda do mapa de teclas';

  @override
  String get wsShowInSource => 'Mostrar no Fonte';

  @override
  String get wsOriginElement => 'Valor do elemento';

  @override
  String get wsOriginAncestor => 'Elemento pai';

  @override
  String get wsOriginModule => 'Padrão do módulo';

  @override
  String get wsOriginBuiltIn => 'Padrão integrado';

  @override
  String get wsOriginUnresolved => 'Não resolvido';

  @override
  String wsEffectiveProperty(String value, String origin) {
    return 'Efetivo: $value — $origin';
  }

  @override
  String get wsElementSelector => 'Elemento';

  @override
  String wsGeneratedAnchorValue(String anchor) {
    return 'Gerado: $anchor';
  }

  @override
  String wsDefaultProperty(String value) {
    return 'Padrão: $value';
  }

  @override
  String wsDefaultPropertyOrigin(String value, String origin) {
    return 'Padrão: $value · $origin';
  }

  @override
  String wsResolvedProperty(String value) {
    return 'Resolvido: $value';
  }

  @override
  String get wsPropertyUnresolved => 'Não resolvido';

  @override
  String get wsModule => 'Módulo';

  @override
  String get wsParent => 'Elemento pai';

  @override
  String get wsListType => 'Tipo de lista';

  @override
  String get wsStartingNumber => 'Número inicial';

  @override
  String get wsListSorting => 'Ordenação';

  @override
  String get wsLetteredList => 'Lista alfabética';

  @override
  String get wsCheckboxList => 'Lista de caixas de seleção';

  @override
  String get wsMarkerlessList => 'Lista sem marcadores';

  @override
  String get wsAscending => 'Ascendente';

  @override
  String get wsDescending => 'Descendente';

  @override
  String get wsNoSorting => 'Sem ordenação';

  @override
  String get wsAsWritten => 'Como escrito';

  @override
  String get wsSentenceCase => 'Maiúscula inicial';

  @override
  String get wsTitleCase => 'Maiúsculas de título';

  @override
  String get wsLowerCase => 'Minúsculas';

  @override
  String get wsUpperCase => 'Maiúsculas';

  @override
  String get wsNativeMarkers => 'Marcadores Markdown';

  @override
  String wsListMarkerStart(String number) {
    return 'Marcador inicial: $number';
  }

  @override
  String wsListLevel(String level) {
    return 'Nível $level';
  }

  @override
  String get wsModuleCapsIgnored =>
      'O compilador fixado ignora as regras <caps> do módulo. Use um atributo caps local ou default-property.';

  @override
  String get wsInsertElements => 'Inserir elementos';

  @override
  String get wsAdmonitionsAndQuotes => 'Avisos e citações';

  @override
  String get wsSemanticText => 'Texto semântico';

  @override
  String get wsPropertiesUnavailable =>
      'O elemento inspecionado está indisponível. Inspecione um elemento para continuar.';

  @override
  String get searchDocumentsCategory => 'Documentos';

  @override
  String get searchTopicsCategory => 'Tópicos';

  @override
  String get searchCurrentDocument => 'Documento atual';

  @override
  String get searchCurrentWorkspace => 'Área de trabalho atual';

  @override
  String get browseNotes => 'Explorar notas';

  @override
  String get searchActionsCommand => 'Pesquisar ações';

  @override
  String get searchDocumentsCommand => 'Pesquisar documentos';

  @override
  String get searchTopicsCommand => 'Pesquisar tópicos';

  @override
  String get searchRecentCommand => 'Pesquisar recentes';

  @override
  String get searchResourceUnavailable => 'Este recurso não está disponível.';

  @override
  String get notesSync => 'Sincronizar notas';

  @override
  String get searchInWorkspace => 'Pesquisar no espaço de trabalho';

  @override
  String get searchCategory => 'Categoria de pesquisa';

  @override
  String get clearHistorySearchScope => 'Pesquisar no histórico de documentos';

  @override
  String get searchInDocument => 'Pesquisar no documento';

  @override
  String get searchDocumentHint => 'Pesquisar neste documento…';

  @override
  String get searchWorkspaceHint => 'Pesquisar neste espaço de trabalho…';

  @override
  String get searchOutlineHint => 'Pesquisar títulos…';

  @override
  String get searchHistoryHint => 'Pesquisar no histórico local…';

  @override
  String get searchEnterText => 'Introduza texto para pesquisar';

  @override
  String get searchAccountUnavailable => 'Conta indisponível';

  @override
  String get searchDocumentsHint => 'Pesquisar documentos…';

  @override
  String get searchTopicsHint => 'Pesquisar tópicos…';

  @override
  String get searchRecentHint => 'Pesquisar recentes…';

  @override
  String get searchActionsHint => 'Pesquisar ações…';

  @override
  String get searchRequiresNotesWorkspace =>
      'Requer um espaço de trabalho de Notas';

  @override
  String get searchSidebarLabel => 'Pesquisar:';

  @override
  String get searchDocumentTextCategory => 'Texto do documento';

  @override
  String get searchWorkspaceTextCategory => 'Texto do espaço de trabalho';

  @override
  String get searchHeadingsCategory => 'Cabeçalhos';

  @override
  String get shortcutUnassigned => 'Não atribuído';

  @override
  String get shortcutPressKeys => 'Prima uma combinação de teclas…';

  @override
  String get shortcutRecord => 'Capturar atalho';

  @override
  String get shortcutRestoreAll => 'Repor todas as predefinições';

  @override
  String get shortcutRestoreAllQuestion =>
      'Repor os atalhos predefinidos de todas as ações? As atribuições personalizadas serão removidas.';

  @override
  String get shortcutSaveFailed =>
      'Os atalhos estão ativos, mas não foram guardados. Tente novamente para os manter após reiniciar.';

  @override
  String get shortcutRetry => 'Tentar guardar novamente';

  @override
  String get shortcutChanged =>
      'As atribuições mudaram. Reveja os atalhos atuais e tente novamente.';

  @override
  String get shortcutInvalid =>
      'Esta combinação não pode ser atribuída neste contexto.';

  @override
  String get shortcutSystemWarning =>
      'O ambiente de trabalho pode usar esta combinação. O BusyMark não pode substituir atalhos do sistema.';

  @override
  String get shortcutConflicts =>
      'Este atalho entra em conflito com estas ações:';

  @override
  String get shortcutRemove => 'Remover atribuição';

  @override
  String get shortcutRestoreDefault => 'Repor predefinição';

  @override
  String get shortcutAssign => 'Atribuir';

  @override
  String get shortcutReassign => 'Reatribuir';

  @override
  String get shortcutContextApplication => 'Aplicação';

  @override
  String get shortcutContextDocument => 'Vistas do documento';

  @override
  String get shortcutContextEditor => 'Editor e código-fonte';

  @override
  String get shortcutContextWritersideSource => 'Código-fonte do Writerside';

  @override
  String get shortcutContextWorkspace => 'Navegação do espaço de trabalho';

  @override
  String get shortcutContextTree => 'Árvores laterais';

  @override
  String get searchHeadingsCommand => 'Pesquisar títulos';

  @override
  String get shortcutFixed => 'Gerido pelo editor; não é configurável.';

  @override
  String get shortcutDefaultConflict =>
      'O atalho predefinido está em conflito com uma atribuição personalizada.';

  @override
  String get shortcutCurrentBinding => 'Atalho atual';

  @override
  String get shortcutProposedBinding => 'Atalho proposto';

  @override
  String get notesActions => 'Ações das notas';

  @override
  String get noteActions => 'Ações da nota';

  @override
  String get noteProperties => 'Propriedades da nota';

  @override
  String get notesExportAll => 'Exportar notas · Todas as notas…';

  @override
  String get notesExportCategory => 'Exportar notas · Categoria…';

  @override
  String get notesOfflineAll => 'Disponibilizar offline · Todas as notas';

  @override
  String get notesOfflineCategory => 'Disponibilizar offline · Categoria';

  @override
  String get notesOfflineRemoveAll =>
      'Remover retenção offline · Todas as notas';

  @override
  String get notesOfflineRemoveCategory =>
      'Remover retenção offline · Categoria';

  @override
  String get notesOfflinePause => 'Pausar transferências';

  @override
  String get notesOfflineResume => 'Retomar transferências';

  @override
  String get notesOfflineKeep => 'Disponibilizar offline';

  @override
  String get notesOfflineRetentionHelp =>
      'Remover este requisito mantém o conteúdo em cache. Um requisito da categoria ou da conta pode continuar a manter a nota.';

  @override
  String get notesOfflineBroader =>
      'Esta nota também é mantida por um requisito da categoria ou da conta.';

  @override
  String get notesOfflineExternal =>
      'O conteúdo multimédia externo requer ligação. O BusyMark mantém apenas o texto e os anexos geridos.';

  @override
  String get notesEmptyAll => 'Ainda não há notas. Crie uma para começar.';

  @override
  String get notesEmptyFavorites => 'Não há notas favoritas.';

  @override
  String get notesEmptyCategory => 'Não há notas nesta categoria.';

  @override
  String get notesEmptyUncategorized => 'Não há notas sem categoria.';

  @override
  String get notesEmptyRecovery => 'Não há notas guardadas para recuperar.';

  @override
  String get notesLoadFailed => 'Nextcloud Notes · Falhou. Tentar novamente';

  @override
  String get notesOperationFailed =>
      'Não foi possível concluir a operação. O rascunho foi mantido. Reveja a gravação e os conflitos e tente novamente.';

  @override
  String get notesInspectionFailed => 'Anexos · Falhou. Tentar novamente';

  @override
  String get notesStartingConnection => 'A iniciar ligação ao Nextcloud…';

  @override
  String get notesVerifyingConnection => 'A verificar o acesso às notas…';

  @override
  String get notesCancellingConnection =>
      'A cancelar o início de sessão e a limpar…';

  @override
  String get notesRemovingConnection => 'A remover a conta local…';

  @override
  String get notesRemovedWarning =>
      'A conta local Nextcloud foi removida. Não foi confirmada a revogação da palavra-passe da aplicação. Remova a palavra-passe do BusyMark nas definições de segurança do Nextcloud.';

  @override
  String get notesBuffersNotSaved =>
      'Não foi possível guardar todas as notas abertas localmente. Reveja a gravação, os conflitos ou a normalização na área de trabalho. As alterações locais podem ainda precisar de sincronização com o Nextcloud.';

  @override
  String get notesSettingsLeave =>
      'Guardar as alterações às definições do Nextcloud antes de sair?';

  @override
  String get notesSettingsLeaveHelp =>
      'Definições de Notes do servidor · Alterações não guardadas';

  @override
  String get notesSettingsReload => 'Recarregar definições do servidor…';

  @override
  String get notesSettingsReloadHelp =>
      'Recarregar substitui o rascunho pelas definições atuais do Nextcloud. Descartar o rascunho e recarregar?';

  @override
  String get notesSettingsRefreshFailed =>
      'O Nextcloud aceitou as definições, mas a atualização das notas falhou. São apresentados os valores confirmados pelo servidor. Tente atualizar novamente a partir das Notas.';

  @override
  String get notesUnavailable =>
      'Sem ligação · Texto disponível localmente · Guardado localmente · sincronização pendente';

  @override
  String get notesStorageFull =>
      'O armazenamento Nextcloud está cheio. Liberte espaço no servidor e tente novamente.';

  @override
  String get notesRejected =>
      'O Nextcloud rejeitou esta alteração. Reveja a nota e guarde uma cópia local antes de tentar novamente.';

  @override
  String get notesThrottled =>
      'O Nextcloud pediu para aguardar. A sincronização será retomada após o prazo de espera.';

  @override
  String get notesRecoveryRequired => 'Conflitos · Comparar';

  @override
  String get notesScanning => 'A analisar ficheiros…';

  @override
  String get notesCancelling =>
      'A cancelar… A aguardar que a operação atual termine.';

  @override
  String get notesCancelled => 'Cancelado';

  @override
  String get notesPartial => 'Parcialmente concluído';

  @override
  String get notesTransferFailed => 'Falhou. Tentar novamente';

  @override
  String get notesImportPartialHelp =>
      'Os itens anteriores podem já estar guardados localmente. Retome esta importação para continuar sem os duplicar.';

  @override
  String get notesNotStarted => 'Não iniciado';

  @override
  String get notesCreated => 'Criado';

  @override
  String get notesRemoteDeleteUnavailable =>
      'URL do servidor · Não suportada · Eliminar · Anexos';

  @override
  String get notesCurrentText => 'Texto atualmente guardado';

  @override
  String get notesRecovering => 'A recuperar como nova nota…';

  @override
  String get notesReadOnlyHelp =>
      'Só de leitura · Favoritos · Guardar cópia local…';

  @override
  String get notesSort => 'Ordenar notas';

  @override
  String get notesPathRelative =>
      'O caminho da pasta de notas é relativo ao seu armazenamento Nextcloud.';

  @override
  String get notesSettingsStale =>
      'As definições mudaram no Nextcloud. Recarregue e reveja os valores do servidor antes de substituir o rascunho.';

  @override
  String get notesDownloadsPaused => 'Transferências pausadas';

  @override
  String get notesExportNotPublished => 'Não foi publicada nenhuma exportação.';

  @override
  String get notesKeyringUnavailable =>
      'Desbloqueie o porta-chaves do ambiente de trabalho e tente novamente.';

  @override
  String get notesConnectFailed =>
      'Não foi possível ligar ao Nextcloud Notes. Verifique o endereço do servidor e tente novamente.';

  @override
  String get notesAccountMismatch =>
      'Inicie sessão na mesma conta Nextcloud. Remova esta conta primeiro para ligar outra.';

  @override
  String get notesLocalRemovalFailed =>
      'A limpeza local da conta falhou. A conta é mantida para poder tentar removê-la novamente.';

  @override
  String get notesTransferring => 'A transferir notas…';

  @override
  String get notesTechnicalDetails => 'Detalhes técnicos';

  @override
  String get notesPauseRequirement => 'Pausar requisito offline';

  @override
  String get notesResumeRequirement => 'Retomar requisito offline';

  @override
  String get gitReturnToDocument => 'Voltar ao documento';

  @override
  String gitSnapshotLabel(String revision, String path) {
    return 'Instantâneo só de leitura · $revision · $path';
  }

  @override
  String get gitNonUtf8FilenameMessage =>
      'Este nome de ficheiro contém bytes não UTF-8. A revisão e a preparação Git continuam disponíveis; o editor requer um nome de ficheiro UTF-8.';

  @override
  String get gitUiMergeInProgress => 'A fusão está em curso';

  @override
  String get gitUiRebaseInProgress => 'Rebase em curso';

  @override
  String get gitUiCherryPickInProgress => 'Pilha de cereja em andamento';

  @override
  String get gitUiRevertInProgress => 'Reverter em curso';

  @override
  String get gitUiPatchApplicationInProgress =>
      'Aplicação de parâmetros em curso';

  @override
  String get gitUiSquashMergeResultAwaitingCommit =>
      'Resultado da fusão de Squash à espera de commit';

  @override
  String get gitUiUnresolvedIndexConflicts =>
      'Conflitos de índices não resolvidos';

  @override
  String get gitUiUnresolvedConflicts => ' · conflitos não resolvidos';

  @override
  String get gitUiReviewOperation => 'Operação de revisão';

  @override
  String get gitUiRefresh => 'Atualizar';

  @override
  String get gitUiCreateNamedStash => 'Criar um esconderijo nomeado';

  @override
  String get gitUiCreateStash => 'Criar stash…';

  @override
  String get gitUiNoStashes => 'Sem esconderijos';

  @override
  String get gitUiSelectAStashToInspectItsChanges =>
      'Selecione um estoque para inspecionar as suas alterações';

  @override
  String get gitUiStashedUntrackedFiles => 'Ficheiros não rastreados';

  @override
  String get gitUiInspectStashedUntrackedFiles =>
      'Inspeccione os ficheiros não localizados...';

  @override
  String get gitUiReinstateTheStashSStagedIndexStateWhenApplying =>
      'Reestabelecer o estado de estágio/índice do estoque ao aplicar';

  @override
  String get gitUiApplyAndRetain => 'Aplicar e manter';

  @override
  String get gitUiPop => 'Pai...';

  @override
  String get gitUiCreateBranch => 'Criar branch…';

  @override
  String get gitUiDropStash => 'Eliminar stash…';

  @override
  String get gitUiBranchFromStash => 'Criar branch a partir do stash';

  @override
  String get gitUiCreateSwitchToABranchAtTheStashSOriginal =>
      'Criar/conectar para um ramo na base original do estoque, depois aplicá-lo. O estoque original é retido para exclusão posterior explícita.';

  @override
  String gitUiArg0ThisStash(String arg0) {
    return '$arg0 este estoque?';
  }

  @override
  String get gitUiTheOriginalStashIsRetainedIfApplyingConflicts =>
      'O estoque original é mantido se aplicar conflitos.';

  @override
  String get gitUiDeletesThisStashEntryItsChangesAreNotApplied =>
      'Exclui esta entrada de reserva. As suas alterações não são aplicadas.';

  @override
  String get gitUiResolveTheUnmergedFilesGitHasNoStashContinueOr =>
      'Resolva os ficheiros não mesclados. O Git não tem comandos para continuar ou abortar um stash; o stash original é preservado.';

  @override
  String get gitUiStashNameMessage => 'Nome/mensagem da vara';

  @override
  String get gitUiStashContentAndResultingIndex =>
      'Conteúdo de estacas e índice resultante';

  @override
  String get gitUiStashTrackedWorkingAndStagedChanges =>
      'Stash rastreou o trabalho e as mudanças encenadas';

  @override
  String get gitUiStashChangesLeaveStagedChangesInPlaceKeepIndex =>
      'Guardar alterações em stash mantendo as preparadas no local (--keep-index)';

  @override
  String get gitUiStashOnlyStagedChangesStaged =>
      'Guardar em stash apenas as alterações preparadas (--staged)';

  @override
  String get gitUiIncludeUntrackedFiles => 'Incluir ficheiros não rastreados';

  @override
  String get gitUiAllEligiblePathsInThisRepository =>
      'Todos os caminhos elegíveis neste repositório';

  @override
  String get gitUiNoEligibleChangesForTheseStashOptions =>
      'Nenhuma alteração elegível para estas opções de estoque.';

  @override
  String get gitUiSelectAtLeastOneEligiblePath =>
      'Selecione pelo menos um caminho elegível.';

  @override
  String get gitUiCreateStash2 => 'Criar stash';

  @override
  String get gitUiCreateWorktree => 'Criar worktree...';

  @override
  String get gitUiCreateACommitBeforeCreatingAWorktreeAtHEAD =>
      'Crie um commit antes de criar uma árvore de trabalho em HEAD.';

  @override
  String get gitUiDetachedHEAD => 'HEAD destacado';

  @override
  String get gitUiCurrent => 'Corrente';

  @override
  String get gitUiLocked => 'Bloqueado';

  @override
  String get gitUiOpenInBusyStack => 'Abrir em Stack Ocupado ·';

  @override
  String get gitUiStatusNotInspected => 'Situação não inspeccionada';

  @override
  String get gitUiDirty => 'Sujo';

  @override
  String get gitUiClean => 'Limpo';

  @override
  String get gitUiOpenWorkingFolder => 'Abrir a pasta de trabalho';

  @override
  String get gitUiMoveWorktree => 'Mover o worktree...';

  @override
  String get gitUiUnlock => 'Desbloquear';

  @override
  String get gitUiLock => 'Fechar';

  @override
  String get gitUiRemoveCleanWorktree => 'Remover worktree limpo...';

  @override
  String get gitUiReviewRemovalIncludingLocalChanges =>
      'Revisar a remoção, incluindo alterações locais...';

  @override
  String get gitUiNewWorktreeFolderName => 'Nome da nova pasta Worktree';

  @override
  String get gitUiNewWorktreeBranch => 'Branco de árvore de trabalho nova';

  @override
  String gitUiCreateArg0Arg1WithANewLocalBranchAtArg2(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return 'Criar $arg0/$arg1 com uma nova filial local em $arg2 ($arg3).';
  }

  @override
  String get gitUiDestinationFolderName => 'Nome da pasta de destino';

  @override
  String get gitUiRemoveWorktree => 'Remover worktree?';

  @override
  String
  get gitUiExplicitlyDiscardAllLocalTrackedUntrackedChangesInThisWorktree =>
      'Descarte explicitamente todas as alterações localmente rastreadas/não rastreadas nesta árvore de trabalho. As árvores de trabalho bloqueadas/em uso permanecem protegidas.';

  @override
  String get gitUiGitRefusesRemovalIfThereAreLocalChangesUntrackedFiles =>
      'Git recusa remoção se houver alterações locais, arquivos não rastreados, ou um bloqueio.';

  @override
  String get gitUiDiscardLocalWorktreeContentsAndRemove =>
      'Descartar o conteúdo local da árvore de trabalho e remover';

  @override
  String get gitUiRemoveCleanWorktree2 => 'Remover a árvore de trabalho limpa';

  @override
  String
  get gitUiExplicitlyRecurseIntoNestedSubmodulesForUpdatesSynchronization =>
      'Recursar explicitamente em submódulos aninhados para atualizações/sincronização';

  @override
  String get gitUiNoRecordedSubmodules => 'Sem submódulos registados';

  @override
  String get gitUiNotInitialized => 'não inicializada';

  @override
  String gitUiParentGitlinkArg0CheckedOutArg1(String arg0, String arg1) {
    return 'Ligação de pais: $arg0 Data de saída: $arg1\n';
  }

  @override
  String get gitUiDirtyNestedRepository => 'Depósito aninhado sujo';

  @override
  String get gitUiCleanNestedRepository => 'Depósito ninhado limpo';

  @override
  String get gitUiNestedStatusUnavailable => 'Situação de nido indisponível';

  @override
  String get gitUiEnterNestedRepository => 'Digite o repositório aninhado';

  @override
  String get gitUiInitializeConfiguration => 'Iniciar a configuração';

  @override
  String get gitUiUpdateToParentSRecordedCommit =>
      'Atualização para o commit registado dos pais...';

  @override
  String get gitUiFollowConfiguredRemoteBranch =>
      'Siga o ramo remoto configurado...';

  @override
  String get gitUiSynchronizeConfiguredURLs =>
      'Sincronizar URLs configuradas...';

  @override
  String get gitUiStageCurrentSubmodulePointerInParent =>
      'Ponteiro do submódulo do estágio actual no pai';

  @override
  String get gitUiParentAndSubmoduleCommitsPushesAndDirtyStateRemainSeparate =>
      'O pai e o submódulo cometes, empurra e o estado sujo permanecem separados. A navegação não inicializa ou atualiza.';

  @override
  String gitUiFetchAndCheckOutTheConfiguredRemoteBranchSCommit(String arg0) {
    return 'Procurar e verificar o branch remoto configurado commit. Isto difere do gitlink registado do pai. Recursivo: $arg0.';
  }

  @override
  String gitUiInitializeAsNeededAndCheckOutExactlyArg0RecursiveArg1(
    String arg0,
    String arg1,
  ) {
    return 'Inicialize conforme necessário e confira exatamente $arg0. Recursiva: $arg1.';
  }

  @override
  String gitUiApplyTheReviewedSubmoduleConfigurationOperationRecursiveArg0(
    String arg0,
  ) {
    return 'Aplicar a operação de configuração do submódulo revisado. Recursivo: $arg0.';
  }

  @override
  String get gitUiApplySubmoduleOperation => 'Aplicar a operação do submódulo';

  @override
  String get gitUiInspectARecordedRevisionOrCreateARecoveryBranchReflog =>
      'Inspeccionar uma revisão gravada ou criar um ramo de recuperação. Reflog não recupera conteúdo arbitrário não salvo ou não rastreado.';

  @override
  String get gitUiSelectAReflogEntry => 'Selecione uma entrada de reflog';

  @override
  String get gitUiPreviousPage => 'Página anterior';

  @override
  String get gitUiNextPage => 'Próxima página';

  @override
  String get gitUiRecoveryBranchName => 'Nome do ramo de recuperação';

  @override
  String gitUiCreatesABranchAtArg0WorkingFilesAndTheCurrent(String arg0) {
    return 'Cria um branch em $arg0; os arquivos de trabalho e o branch atual estão inalterados.';
  }

  @override
  String get gitUiCreateRecoveryBranch => 'Criar ramo de recuperação...';

  @override
  String get gitUiReadOnlyRecoverySnapshot =>
      'instantâneo de recuperação de apenas leitura';

  @override
  String get gitUiInspectSnapshot => 'Inspeccionar instantâneo...';

  @override
  String get gitUiReviewReset => 'Rever reposição…';

  @override
  String gitUiPageArg0(String arg0) {
    return 'Página $arg0';
  }

  @override
  String get gitUiAGitTextHistoryMustOwnItsEditableField =>
      'Um histórico de texto Git deve possuir o seu campo editável.';

  @override
  String get gitUiEditHEADIndexWorkingTree =>
      'Editar HEAD | Índice | Árvore de trabalho…';

  @override
  String
  get gitUiTheReviewedIndexOrWorkingContentChangedRefreshThisComparison =>
      'O índice revisto ou o conteúdo de trabalho mudou. Actualize esta comparação antes do estadiamento.';

  @override
  String get gitUiRefreshComparison => 'Refrescar a comparação';

  @override
  String get gitUiPreviousChangedFile => 'Ficheiro alterado anterior';

  @override
  String get gitUiNextChangedFile => 'Próximo ficheiro alterado';

  @override
  String get gitUiPreviousDifference => 'Diferença anterior';

  @override
  String get gitUiNextDifference => 'Próxima diferença';

  @override
  String get gitUiComparisonMode => 'Modo de comparação';

  @override
  String get gitUiSideBySide => 'Lados a lado';

  @override
  String get gitUiUnified => 'Unificado';

  @override
  String get gitUiDiffDisplayOptions =>
      'Opções de exibição de diff@ info: whatsthis';

  @override
  String get gitUiWrap => 'Embrulho';

  @override
  String get gitUiWords => 'Palavras';

  @override
  String get gitUiCollapseContext => 'Recolher contexto';

  @override
  String get gitUiIgnoreWhitespace => 'Ignorar espaços brancos';

  @override
  String get gitUiSearchComparison => 'Comparação de pesquisas';

  @override
  String get gitUiSearch => 'Procurar';

  @override
  String get gitUiCloseSearch => 'Fechar pesquisa';

  @override
  String get gitUiStagingActions => 'Ações de preparação';

  @override
  String get gitUiStagingActions2 => 'Ações de preparação…';

  @override
  String get gitUiUnstageSelectedChangedLines =>
      'Retirar linhas alteradas selecionadas do índice';

  @override
  String get gitUiStageSelectedChangedLines =>
      'Preparar linhas alteradas selecionadas';

  @override
  String get gitUiUnstageWholeFile => 'Retirar ficheiro completo do índice';

  @override
  String get gitUiStageWholeFile => 'Preparar ficheiro completo';

  @override
  String gitUiArg0WhitespaceOnlyChangedLinesHiddenShowExactChanges(
    String arg0,
  ) {
    return '$arg0 apenas linhas mudadas de espaços brancos ocultas · Mostrar alterações exatas';
  }

  @override
  String gitUiArg0ChangedLinesSelectedDisplaySettingsNeverAlterTheStaged(
    String arg0,
  ) {
    return '$arg0 alteraram as linhas selecionadas · Configurações de exibição nunca alteram os bytes.';
  }

  @override
  String get gitUiReadOnlyComparisonCopyTextOrAdjustDisplaySettings =>
      'Comparação só de leitura · Copie texto ou ajuste a apresentação.';

  @override
  String get gitUiNoFinalNewline => ' · nenhuma nova linha final';

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
      'A comparação de texto não está disponível para estes conteúdos.';

  @override
  String get gitUiThisComparisonExceedsTheBoundedTextReviewLimitTheContents =>
      'Esta comparação excede o limite de revisão de texto limitado. O conteúdo não foi declarado idêntico.';

  @override
  String get gitUiTheComparedContentsAreIdentical =>
      'Os conteúdos comparados são idênticos.';

  @override
  String get gitUiUnstage => 'Não estágio';

  @override
  String get gitUiStage => 'Etapa';

  @override
  String gitUiArg0ChangedLine(String arg0) {
    return '$arg0 mudança de linha';
  }

  @override
  String get gitUiContext => 'Contexto';

  @override
  String get gitUiExpandUnchangedContext => 'Expandir o contexto inalterado';

  @override
  String get gitUiUnstageThisHunk => 'Retirar este bloco do índice';

  @override
  String get gitUiStageThisHunk => 'Preparar este bloco';

  @override
  String gitUiEditStagedContentArg0(String arg0) {
    return 'Editar conteúdo em fase · $arg0';
  }

  @override
  String get gitUiWritingReviewedIndexResult =>
      'Escrevendo o resultado do índice revisado';

  @override
  String get gitUiHead => 'HEAD';

  @override
  String get gitUiIndex => 'Índice';

  @override
  String get gitUiWorkingTree => 'Árvore de trabalho';

  @override
  String gitUiHeadArg0(String arg0) {
    return 'HEAD · $arg0';
  }

  @override
  String get gitUiIndexEditableUTF8Blob => 'Índice · blob UTF-8 editável';

  @override
  String get gitUiUndo => 'Desfazer';

  @override
  String get gitUiRedo => 'Refazer';

  @override
  String get gitUiReloadIndexReview => 'Revisão do índice de recarga?';

  @override
  String get gitUiReloadTheCurrentHEADIndexAndWorkingVersionsThisReplaces =>
      'Recarregue as versões atuais de HEAD, do índice e de trabalho. Isto substitui o rascunho não guardado no editor do índice.';

  @override
  String get gitUiReplaceDraftAndReload => 'Substituir o projecto e recarregar';

  @override
  String get gitUiReloadVersions => 'Recarregar as versões...';

  @override
  String get gitUiWriteEditedResultToThisIndexEntry =>
      'Escreva o resultado editado para esta entrada do índice';

  @override
  String get gitUiWorkingFilesRemainOnDiskReviewTheEditedIndexBefore =>
      'Os arquivos de trabalho permanecem no disco. Revise o índice editado antes de aplicar.';

  @override
  String get gitUiReviewIndexTextFormatChanges =>
      'Revisar as alterações no formato do texto do índice';

  @override
  String gitUiUpdateOnlyTheReviewedIndexEntryForArg0Arg1(
    String arg0,
    String arg1,
  ) {
    return 'Atualizar apenas a entrada do índice revisto para $arg0. $arg1';
  }

  @override
  String get gitUiWriteReviewedIndexResult =>
      'Escreva o resultado do índice revisado';

  @override
  String get gitUiTheEditedResultChangedDuringFormatReviewReviewItAgain =>
      'O resultado editado mudou durante a revisão de formato. Revise novamente.';

  @override
  String get gitUiSynchronizeScrolling => 'Sincronizar o desloque';

  @override
  String get gitUiReadOnlyRevisionContent =>
      'Conteúdo de revisão apenas para leitura';

  @override
  String get gitUiEditableIndexContent => 'Conteúdo do índice editável';

  @override
  String get gitUiTheRequestedRevisionIsOutsideTheCurrentFiltersResetFilters =>
      'A revisão solicitada está fora dos filtros atuais. Reinicie os filtros para revelá-los.';

  @override
  String get gitUiFilterLog => 'Registo de Filtros';

  @override
  String get gitUiFilters => 'Filtros...';

  @override
  String gitUiFiltersCount(String count) {
    return 'Filtros ($count)...';
  }

  @override
  String get gitUiMessage => 'Mensagem…';

  @override
  String get gitUiAuthor => 'Autor…';

  @override
  String get gitUiPath => 'Caminho...';

  @override
  String get gitUiDate => 'Data...';

  @override
  String get gitUiMessageFilter => 'Filtro de Mensagem';

  @override
  String get gitUiAuthorFilter => 'Filtro do autor';

  @override
  String get gitUiPathFilter => 'Filtro de localização';

  @override
  String get gitUiMessage2 => 'Mensagem';

  @override
  String get gitUiAuthor2 => 'Autor';

  @override
  String get gitUiPath2 => 'Caminho';

  @override
  String get gitUiDateFilter => 'Filtro de data...';

  @override
  String get gitUiResetFilters => 'Restaurar filtros';

  @override
  String get gitUiRefreshLog => 'Actualizar o Registo';

  @override
  String get gitUiGoToCommitReference => 'Ir para commit/reference...';

  @override
  String get gitUiBackToHEAD => 'Voltar a HEAD';

  @override
  String get gitUiOrderedCherryPick => 'Cherry-pick pela ordem escolhida';

  @override
  String gitUiReviewCherryPickArg0(String arg0) {
    return 'Comentário de cereja-pick ($arg0)...';
  }

  @override
  String get gitUiCompareTwoSelectedRevisions =>
      'Comparar duas revisões seleccionadas...';

  @override
  String get gitUiToggleBranchesPane => 'Painel de galhos de comutação';

  @override
  String get gitUiFilterBranchesAndTags => 'Filtrar ramos e etiquetas';

  @override
  String gitUiCommitArg0(String arg0) {
    return 'Comissário $arg0';
  }

  @override
  String get gitUiCommitDetails => 'Compromete os detalhes...';

  @override
  String gitUiReferenceArg0(String arg0) {
    return 'Referência: $arg0';
  }

  @override
  String get gitUiSelectThisCommit => 'Selecionar este commit';

  @override
  String get gitUiBranchOrTag => 'Branco ou etiqueta';

  @override
  String get gitUiAllReferences => 'Todas as referências';

  @override
  String get gitUiLocal => 'Local';

  @override
  String get gitUiRemote => 'Remoto';

  @override
  String get gitUiTags => 'Tags';

  @override
  String get gitUiNoCommitsMatchTheCurrentFilters =>
      'Nenhum commit corresponde aos filtros atuais.';

  @override
  String get gitUiObjectID => 'Identificação do objeto';

  @override
  String get gitUiSubjectReferences => 'Assunto / referências';

  @override
  String get gitUiDate2 => 'Data';

  @override
  String get gitUiGitCommits => 'Commits do Git';

  @override
  String get gitUiParents => 'Commits pai';

  @override
  String gitUiArg0Parents(String arg0) {
    return '$arg0 pais';
  }

  @override
  String get gitUiLoadMoreCommits => 'Carregar mais commits';

  @override
  String get gitUiLoadingChangedFiles => 'Carregando ficheiros alterados';

  @override
  String get gitUiNoChangedFiles => 'Nenhum ficheiro alterado';

  @override
  String get gitUiSelectACommit => 'Selecione um commit';

  @override
  String gitUiCompareParentArg0Arg1(String arg0, String arg1) {
    return 'Comparar os pais $arg0: $arg1';
  }

  @override
  String get gitUiChangedFiles => 'Ficheiros alterados';

  @override
  String gitUiAuthorArg0Arg1Arg2(String arg0, String arg1, String arg2) {
    return 'Autor: $arg0 <$arg1> $arg2';
  }

  @override
  String gitUiCommitterArg0Arg1Arg2(String arg0, String arg1, String arg2) {
    return 'Combustível: $arg0 <$arg1> $arg2';
  }

  @override
  String get gitUiShallowPartialBoundaryAParentObjectIsUnavailable =>
      'Limitação ligeira/partial: um objeto pai não está disponível.';

  @override
  String get gitUiParentIsOutsideThisPageOrAShallowBoundary =>
      'O pai está fora desta página ou um limite raso.';

  @override
  String gitUiParentArg0(String arg0) {
    return 'Commit pai $arg0';
  }

  @override
  String get gitUiCommitActions => 'Comete acções...';

  @override
  String get gitUiEmptyTree => 'árvore vazia';

  @override
  String get gitUiCreateBranch2 => 'Criar branch';

  @override
  String get gitUiCreateTag => 'Criar tag';

  @override
  String get gitUiCompareRevisions => 'Comparar as revisões';

  @override
  String get gitUiOpenSnapshot => 'Abrir a instantânea';

  @override
  String get gitUiRevertCommit => 'Reverter o commit';

  @override
  String get gitUiInteractiveRebaseAfterThisBoundary =>
      'Rebase interativo após este limite';

  @override
  String get gitUiResetCurrentBranch => 'Repor branch atual';

  @override
  String get gitUiCopyFullObjectID => 'Copie o ID completo do objeto';

  @override
  String get gitUiGoToCommitReference2 => 'Ir para commit/referência';

  @override
  String get gitUiEnterACommitIDOrReferenceToRevealInLog =>
      'Digite um ID de commit ou uma referência para revelar no Log.';

  @override
  String get gitUiTheRequestedRevisionIsUnavailable =>
      'A revisão solicitada não está disponível.';

  @override
  String
  get gitUiRepositoryMetadataIsReadOnlyBranchInspectionAndComparisonRemain =>
      'Os metadados do repositório são apenas de leitura. A inspeção e comparação da filial permanecem disponíveis.';

  @override
  String get gitUiWorkingFilesAreUnavailableOrReadOnlyBranchSwitchingAnd =>
      'Os ficheiros de trabalho não estão disponíveis ou só de leitura. A mudança e a fusão de ramos não estão disponíveis.';

  @override
  String get gitUiSearchBranchesAndTags => 'Pesquisar branches e tags';

  @override
  String get gitUiNewBranch => 'Nova branch…';

  @override
  String get gitUiLocalBranches => 'Branches locais';

  @override
  String get gitUiRemoteBranches => 'Branches remotas';

  @override
  String gitUiTracksArg0(String arg0) {
    return 'Pistas $arg0';
  }

  @override
  String gitUiCheckedOutAtArg0(String arg0) {
    return 'Checked out em $arg0';
  }

  @override
  String get gitUiRefreshingBranchMetadata =>
      'Actualização dos metadados da filial';

  @override
  String gitUiSwitchToArg0(String arg0) {
    return 'Mudar para $arg0';
  }

  @override
  String get gitUiOpenOccupiedWorktree => 'Árvore aberta ocupada';

  @override
  String get gitUiCreateLocalTrackingBranch =>
      'Criar ramo local de rastreamento...';

  @override
  String get gitUiCompareToCurrentHEAD => 'Comparar com HEAD atual';

  @override
  String get gitUiMergeIntoCurrentBranch => 'Junta-te ao ramo actual...';

  @override
  String get gitUiRename => 'Renomear...';

  @override
  String get gitUiChangeUpstream => 'Mudar para cima...';

  @override
  String get gitUiDelete => 'Excluir...';

  @override
  String get gitUiDeleteFromRemote => 'Excluir do remoto...';

  @override
  String gitUiActionsForArg0(String arg0) {
    return 'Acções para $arg0';
  }

  @override
  String get gitUiLocalBranchName => 'Nome da filial local';

  @override
  String gitUiCreateAtArg0TheNewBranchWillBeCheckedOut(String arg0) {
    return 'Crie em $arg0. O novo ramo será verificado.';
  }

  @override
  String gitUiTheLocalBranchWillTrackArg0AndBeCheckedOut(String arg0) {
    return 'O ramo local irá rastrear $arg0 e ser verificado.';
  }

  @override
  String get gitUiChooseRemoteForDeletion =>
      'Escolher o remoto para a exclusão';

  @override
  String get gitUiDeleteRemoteReference => 'Excluir a referência remota';

  @override
  String gitUiMergeArg0IntoArg1(String arg0, String arg1) {
    return 'Fusionar $arg0 em $arg1';
  }

  @override
  String gitUiRenameArg0(String arg0) {
    return 'Renomear-se-á $arg0';
  }

  @override
  String gitUiUpstreamForArg0(String arg0) {
    return 'Ascendente para $arg0';
  }

  @override
  String get gitUiNoUpstream => 'Sem upstream';

  @override
  String gitUiDeleteArg0(String arg0) {
    return 'Excluir $arg0?';
  }

  @override
  String gitUiArg0TargetArg1LocalDeletionOnlyAnUnmergedBranchIs(
    String arg0,
    String arg1,
  ) {
    return '$arg0 Alvo $arg1 Exclusão local apenas. Um ramo não fundido é recusado.';
  }

  @override
  String get gitUiDelete2 => 'Excluir';

  @override
  String gitUiDeleteUnmergedBranchArg0(String arg0) {
    return 'Excluir ramo não fundido $arg0?';
  }

  @override
  String gitUiArg0GitReportsThisBranchIsNotFullyMergedExplicitly(String arg0) {
    return '$arg0 Git relata que este ramo não está completamente fundido. Exclua explicitamente a referência local após rever os seus commits; cópias remotas não são modificadas.';
  }

  @override
  String get gitUiDeleteUnmergedLocalBranch =>
      'Excluir o ramo local não fundido';

  @override
  String gitUiDestinationArg0Arg1(String arg0, String arg1) {
    return 'Destino: $arg0 · $arg1';
  }

  @override
  String get gitUiSourceBranchOrTag => 'Ramo ou etiqueta de origem';

  @override
  String get gitUiMergePolicy => 'Política de fusão';

  @override
  String get gitUiFastForwardWhenPossible =>
      'Avançar rapidamente quando possível';

  @override
  String get gitUiAlwaysCreateAMergeCommit => 'Criar sempre um commit de fusão';

  @override
  String get gitUiFastForwardOnly => 'Apenas para avançar rápido';

  @override
  String get gitUiSquashIntoStagedChanges => 'Apanhar em mudanças encenadas';

  @override
  String get gitUiStopBeforeCreatingTheMergeCommit =>
      'Parar antes de criar o commit de fusão';

  @override
  String get gitUiFastForwardIsDisabledSoHEADCannotMoveBeforeReview =>
      'O avanço rápido está desativado para impedir que HEAD se mova antes da revisão.';

  @override
  String get gitUiLeavesStagedChangesForASeparateCommitThisIsNot =>
      'Deixa as mudanças encenadas para um commit separado; isto não é uma fusão contínua.';

  @override
  String get gitUiConflictsRemainAvailableInTheSharedResolutionWorkspace =>
      'Os conflitos permanecem disponíveis no espaço de trabalho de resolução compartilhada.';

  @override
  String get gitUiAddRemote => 'Adicionar remoto...';

  @override
  String gitUiFetchArg0PushArg1(String arg0, String arg1) {
    return 'Procure: $arg0 Empurre: $arg1';
  }

  @override
  String get gitUiRemoveRemote => 'Remover o remoto...';

  @override
  String get gitUiChangeFetchURL => 'Alterar a URL de captação...';

  @override
  String get gitUiAddPushDestination => 'Adicionar destino de empurrão...';

  @override
  String get gitUiRemovePushDestination => 'Remover o destino do empurrão...';

  @override
  String gitUiManageArg0(String arg0) {
    return 'Gerir $arg0';
  }

  @override
  String get gitUiRemoteName => 'Nome remoto';

  @override
  String get gitUiNewRemoteName => 'Novo nome remoto';

  @override
  String get gitUiRepositoryURLOrLocalSource =>
      'URL do repositório ou fonte local';

  @override
  String get gitUiEnterTheExactReviewedDestinationToRemove =>
      'Digite o destino exato revisto para remover.';

  @override
  String get gitUiCredentialsAreSuppliedByConfiguredHelpersOrAPrivatePrompt =>
      'As credenciais são fornecidas por ajudantes configurados ou por um prompt privado.';

  @override
  String gitUiRemoveRemoteArg0(String arg0) {
    return 'Remover remoto $arg0?';
  }

  @override
  String
  get gitUiRemovesLocalRemoteConfigurationAndTrackingReferencesItDoesNot =>
      'Remove a configuração remota local e as referências de rastreamento. Ele não exclui o repositório do servidor.';

  @override
  String get gitUiRemoveRemote2 => 'Remover o remoto';

  @override
  String get gitUiCommitScopeEntireRepository =>
      'Compromete o escopo: repositório inteiro';

  @override
  String get gitUiCachedTracking => 'Rastreamento em caches';

  @override
  String get gitUiAmendLastCommit => 'Alterar último commit';

  @override
  String get gitUiConfiguredHooksAndSigningAreRespected =>
      'Os ganchos configurados e a assinatura são respeitados.';

  @override
  String get gitUiRewritesTheSelectedHEADCommitRemoteTrackingCannotProveIt =>
      'Reescreve o commit HEAD selecionado. O rastreio remoto não prova que ainda não foi publicado.';

  @override
  String get gitUiRepository => 'Repositório';

  @override
  String gitUiDetachedArg0(String arg0) {
    return 'Detalhado $arg0';
  }

  @override
  String get gitUiLog => 'Histórico';

  @override
  String get gitUiRepositoryActions => 'Ações do repositório';

  @override
  String gitUiCachedTrackingUpstreamAheadAheadBehindBehind(
    String upstream,
    String ahead,
    String behind,
  ) {
    return 'Rastreio em cache · $upstream · $ahead à frente · $behind atrás';
  }

  @override
  String get gitUiBareRepositoryNoWorkingTreeOpenLogToInspectIts =>
      'Repository Bare · nenhuma árvore de trabalho. Abrir o log para inspecionar o seu histórico.';

  @override
  String get gitUiReadOnlyRepositoryStagingAndCommitsAreUnavailable =>
      'O repositório de apenas leitura · estadging e commits não estão disponíveis.';

  @override
  String get gitUiRepositoryStatusUnavailable =>
      'Situação do repositório indisponível';

  @override
  String gitUiAmendRevision(String revision) {
    return 'Alterar $revision';
  }

  @override
  String get gitUiAddSignOffTrailer => 'Adicionar linha de aprovação';

  @override
  String get gitUiUseConfiguredSigningPolicy =>
      'Usar a política de assinatura configurada';

  @override
  String get gitUiCryptographicallySignThisCommit =>
      'Criptograficamente assinar este commit';

  @override
  String get gitUiDoNotSignThisCommit => 'Não assine este commit';

  @override
  String get gitUiRecentCommitMessages => 'Mensagens de commit recentes...';

  @override
  String get gitUiUseConfiguredCommitTemplate =>
      'Usar o modelo de commit configurado...';

  @override
  String get gitUiAuthorIdentityAndConfiguredHooks =>
      'Identidade do autor e ganchos configurados...';

  @override
  String get gitUiDraftMessage => 'Projecto de mensagem...';

  @override
  String get gitUiCommitOptions => 'Opções do commit';

  @override
  String gitUiDraftRetainedInMemorySavingItFailedArg0(String arg0) {
    return 'Projeto conservado em memória; a salvação falhou. $arg0';
  }

  @override
  String get gitUiCommitMessage => 'Mensagem do commit';

  @override
  String get gitUiGitOperationInProgress => 'Operação Git em curso';

  @override
  String get gitUiCancel => 'Cancelar';

  @override
  String get gitUiAmendStaged => 'Modificar o estágio';

  @override
  String gitUiCommitStagedCount(String count) {
    return 'Commit das alterações preparadas ($count)';
  }

  @override
  String get gitUiCommitAndPush => 'Criar commit e enviar…';

  @override
  String get gitUiNoReadableCommitTemplateIsConfigured =>
      'Não está configurado nenhum modelo de commit legível.';

  @override
  String get gitUiCommitIdentityAndHooks =>
      'Identidade de compromisso e ganchos';

  @override
  String get gitUiRecentMessages => 'Mensagens recentes';

  @override
  String get gitUiReplaceMessageDraft => 'Substituir o rascunho da mensagem?';

  @override
  String get gitUiReplaceTheExistingCommitMessageWithTheSelectedMessage =>
      'Substituir a mensagem de commit existente pela mensagem selecionada?';

  @override
  String get gitUiReplaceDraft => 'Substituir o projecto';

  @override
  String gitUiLocalCommitArg0Exists(String arg0) {
    return 'A autorização local $arg0 existe.';
  }

  @override
  String gitUiLocalCommitArg0ExistsReviewLogBeforeAttemptingAnotherCommit(
    String arg0,
  ) {
    return 'O commit local $arg0 existe. Revisar o Registo antes de tentar outro commit. O esboço da mensagem foi mantido.';
  }

  @override
  String get gitUiCommitAuthorName => 'Commit nome do autor';

  @override
  String get gitUiCommitAuthorEmail => 'Commit email do autor';

  @override
  String get gitUiConfiguredDefault => 'configurado padrão';

  @override
  String get gitUiOpenpgp => 'OpenPGP';

  @override
  String gitUiSigningArg0Arg1(String arg0, String arg1) {
    return 'Assinatura: $arg0 · $arg1';
  }

  @override
  String gitUiConfiguredHooksArg0(String arg0) {
    return 'Ganchos configurados: $arg0';
  }

  @override
  String get gitUiASignOffTrailerIsAStatementInTheMessage =>
      'A linha de aprovação é uma declaração na mensagem, distinta de uma assinatura criptográfica. A identidade é guardada apenas na configuração local do repositório; o rascunho é preservado.';

  @override
  String get gitUiSaveRepositoryIdentity =>
      'Salvar a identidade do repositório';

  @override
  String get gitUiStaged => 'Preparadas';

  @override
  String get gitUiUntracked => 'Não rastreadas';

  @override
  String get gitUiUnstaged => 'Não preparadas';

  @override
  String get gitUiConflicts => 'Conflitos';

  @override
  String get gitUiNoChanges => 'Nenhuma alteração';

  @override
  String get gitUiRepositoryChangeTree => 'Árvore de mudança de repositório';

  @override
  String get gitUiChanges => 'Alterações';

  @override
  String gitUiGroupCount(String group, String count) {
    return '$group ($count)';
  }

  @override
  String get gitUiExpand => 'Expandir';

  @override
  String get gitUiCollapse => 'Colapso';

  @override
  String get gitUiUnstageFile => 'Retirar ficheiro do índice';

  @override
  String get gitUiStageFile => 'Preparar ficheiro';

  @override
  String get gitUiExpandGroup => 'Expandir o grupo';

  @override
  String get gitUiCollapseGroup => 'Grupo de colapso';

  @override
  String get gitUiReviewDifference => 'Diferença de revisão';

  @override
  String get gitUiUnstageSelectedFiles =>
      'Retirar ficheiros selecionados do índice';

  @override
  String get gitUiStageSelectedFiles => 'Preparar ficheiros selecionados';

  @override
  String get gitUiFileHistoryAndBlame => 'Histórico de ficheiros e culpa...';

  @override
  String get gitUiDeleteUntrackedFile => 'Excluir o ficheiro não rastreado...';

  @override
  String get gitUiDiscardUnstagedChange => 'Descartar a mudança sem cenas...';

  @override
  String get gitUiFileHistory => 'Histórico do ficheiro';

  @override
  String gitUiDiscardUnstagedArg0(String arg0) {
    return 'Descartar o $arg0 sem palco?';
  }

  @override
  String gitUiArg0BytesArg1ReplacesWorkingContentWithTheIndexOr(
    String arg0,
    String arg1,
  ) {
    return '$arg0 bytes · $arg1 Substitui o conteúdo de trabalho com o índice, ou exclui este arquivo não rastreado. O conteúdo em fase é mantido. Os documentos de hospedagem não guardados devem ser revistos primeiro.';
  }

  @override
  String get gitUiDeleteUntrackedFile2 => 'Excluir o ficheiro não rastreado';

  @override
  String get gitUiDiscardWorkingChange => 'Eliminar a alteração de trabalho';

  @override
  String gitUiDeleteREMOTEReferenceArg0(String arg0) {
    return 'Riscar a referência da REMOTE $arg0';
  }

  @override
  String get gitUiThisRemovesTheReferenceOnEveryActualPushDestinationListed =>
      'Isto remove a referência em todos os destinos de empurrão real listados abaixo. As ramificações/etiquetas locais são mantidas. As dicas esperadas são fixadas por esta revisão.';

  @override
  String get gitUiReferenceDoesNotExist => 'a referência não existe';

  @override
  String gitUiArg0ExpectedTipArg1(String arg0, String arg1) {
    return '$arg0 Dica prevista: $arg1';
  }

  @override
  String get gitUiRemoteDeletionCompleted => 'Apagamento remoto concluído.';

  @override
  String gitUiDeleteArg0FromTheRemote(String arg0) {
    return 'Excluir $arg0 do controle remoto?';
  }

  @override
  String get gitUiTheExactDestinationTipsShownAboveWillBeRemovedAny =>
      'As dicas de destino exatas mostradas acima serão removidas. Qualquer dica remota alterada para parar a operação para outra revisão.';

  @override
  String get gitUiReviewAndDeleteFromRemote =>
      'Revisar e apagar a partir do remoto...';

  @override
  String get gitUiDestinationReference => 'Referência do destino';

  @override
  String get gitUiReviewDestinations => 'Revisar os destinos';

  @override
  String get gitUiNewRemoteBranch => 'novo ramo remoto';

  @override
  String gitUiArg0Arg1ExpectedArg2(String arg0, String arg1, String arg2) {
    return '$arg0\n$arg1 · esperado: $arg2';
  }

  @override
  String get gitUiADestinationHasCommitsThatAreUnavailableLocallyFetchThat =>
      'Um destino tem commits que estão indisponíveis localmente. Obter o destino revisado antes de rever o histórico de saída.';

  @override
  String get gitUiFetchReviewedDestination => 'Procurar o destino revisto';

  @override
  String get gitUiChooseADestinationAndReviewTheOutgoingCommits =>
      'Escolha um destino e revise os commits de saída.';

  @override
  String get gitUiNoOutgoingCommits => 'Sem compromissos de saída';

  @override
  String get gitUiSelectAnOutgoingCommit => 'Selecione um commit de saída';

  @override
  String get gitUiLoadMoreOutgoingCommits => 'Carregar mais commits de saída';

  @override
  String get gitUiSetThisDestinationAsUpstream =>
      'Definir este destino como a montante';

  @override
  String get gitUiChooseExactTagsToPublish =>
      'Escolha etiquetas exatas para publicar';

  @override
  String get gitUiTagsNone => 'Etiquetas: nenhum';

  @override
  String gitUiTagsArg0Selected(String arg0) {
    return 'Etiquetas: $arg0 selecionado';
  }

  @override
  String gitUiPublishExactlyArg0(String arg0) {
    return 'Publique exatamente: $arg0';
  }

  @override
  String get gitUiPushCompletedTheLocalCommitRemainsAvailableInLog =>
      'Empurrar completado. O commit local permanece disponível no Log.';

  @override
  String get gitUiForceRequiresTheExactDestinationTipsShownInThisReview =>
      'O envio forçado exige exatamente as revisões de destino apresentadas nesta revisão.';

  @override
  String get gitUiForceWithReviewedLease => 'Força com aluguel revisado...';

  @override
  String get gitUiPush => 'Enviar';

  @override
  String get gitUiForcePushWithReviewedLeases => 'Forçar com aluguel revisado?';

  @override
  String gitUiRewriteArg0OnlyIfEveryRemoteDestinationStillHasThe(String arg0) {
    return 'Reescrever $arg0 apenas se cada destino remoto ainda tiver a ponta exata mostrada acima.\n';
  }

  @override
  String get gitUiOtherPeopleMayAlreadyUseThisHistoryABackgroundFetch =>
      'Outras pessoas podem já usar este histórico. Uma busca em segundo plano não renova esta condição de segurança.';

  @override
  String get gitUiForceWithLease => 'Força com contrato de arrendamento';

  @override
  String
  get gitUiTheRemoteOutcomeIsUncertainReviewDestinationsAgainBeforeAnother =>
      'O resultado remoto é incerto. Revise destinos novamente antes de outro empurrão.';

  @override
  String gitUiParentArg0Arg1(String arg0, String arg1) {
    return 'Pai e mãe $arg0 · $arg1';
  }

  @override
  String get gitUiRemoteToFetch => 'Remoto para obter';

  @override
  String get gitUiPruneDeletedRemoteTrackingBranches =>
      'Prune ramificações de rastreamento remoto excluídas';

  @override
  String
  get gitUiFetchUpdatesRemoteTrackingInformationWithoutReplacingWorkingFiles =>
      'Obtenha atualizações de informações de rastreamento remoto sem substituir arquivos de trabalho.';

  @override
  String get gitUiFetch => 'Buscar';

  @override
  String get gitUiSourceRemote => 'Remoto de fonte';

  @override
  String get gitUiSourceBranch => 'Filial fonte';

  @override
  String get gitUiReviewedStrategy => 'Estratégia revista';

  @override
  String get gitUiMerge => 'Mesclar';

  @override
  String get gitUiRebase => 'Rebase';

  @override
  String get gitUiStopIfTheDestinationCannotFastForwardNeverMergeOr =>
      'Parar se o destino não puder avançar rapidamente; nunca se fundir ou rebasar.';

  @override
  String get gitUiMergeWithAMergeCommitIncludingWhenFastForwardIs =>
      'Fuja com um commit de fusão, incluindo quando for possível fast-forward.';

  @override
  String get gitUiMergeAllowFastForwardWhenPossible =>
      'Fuja; permita que avance rápido quando possível.';

  @override
  String get gitUiRebaseLocalHistoryWhilePreservingLocalMergeCommits =>
      'Rebase a história local enquanto preserva a fusão local commits.';

  @override
  String get gitUiRebaseLocalCommitsAsALinearHistory =>
      'Rebase commits locais como um histórico linear.';

  @override
  String get gitUiGitIsConfiguredForInteractiveRebaseSelectAPullStrategy =>
      'O Git está configurado para rebase interativo. Selecione uma estratégia de puxação explicitamente aqui, ou procure e abra Rebase... para rever um plano.';

  @override
  String get gitUiUseReviewedOrdinaryRebaseForThisPull =>
      'Usar a rebase ordinária revisada para esta puxação';

  @override
  String get gitUiOptions => 'Opções';

  @override
  String get gitUiAlwaysCreateAMergeCommitNoFastForward =>
      'Criar sempre um commit de fusão (não fast-forward)';

  @override
  String get gitUiPreserveLocalMergeCommits =>
      'Preservar a fusão local commits';

  @override
  String get gitUiLocalChangesMayPreventPullReviewCommitThemOrExplicitly =>
      'Alterações locais podem impedir o puxamento. Revise/comprometa-as ou crie explicitamente um estoque.';

  @override
  String get gitUiStashes => 'Stashes';

  @override
  String get gitUiCreateOrReviewStash => 'Criar ou rever o estoque...';

  @override
  String get gitUiPullWithSelectedStrategy =>
      'Puxar com a estratégia selecionada';

  @override
  String get gitUiRepositoryURLOrLocalGitSource =>
      'URL do repositório ou fonte local do Git';

  @override
  String get gitUiHttpsSSHOrLocalPath => 'HTTPS, SSH ou caminho local';

  @override
  String get gitUiFolderToInitialize => 'Pasta para inicializar';

  @override
  String get gitUiFinalCloneDestination => 'Destino final do clone';

  @override
  String get gitUiChoose => 'Escolha...';

  @override
  String get gitUiCreatesGitMetadataOnlyExistingFilesAreNotStagedOr =>
      'Cria apenas metadados Git. Os ficheiros existentes não são encenados ou comprometidos.';

  @override
  String get gitUiTheFinalDestinationMustBeAbsentOrEmptyExistingUser =>
      'O destino final deve não existir ou estar vazio. Os dados existentes do utilizador nunca são substituídos.';

  @override
  String get gitUiInitialBranchBlankUsesEffectiveGitPolicy =>
      'Branco inicial · em branco utiliza a política eficaz de Git';

  @override
  String get gitUiSelectedBranchOptional => 'Branco selecionado · opcional';

  @override
  String get gitUiExplicitlyInitializeUpdateSubmodulesRecursively =>
      'Inicializar/actualizar explicitamente submódulos recursivamente';

  @override
  String get gitUiPreparingGitOperation => 'Preparar a operação Git...';

  @override
  String get gitUiThisAttemptCreated => 'Esta tentativa foi criada';

  @override
  String get gitUiTheDestinationExistedBeforeThisAttempt =>
      'O destino existia antes desta tentativa:';

  @override
  String get gitUiTheDirectoryRemainsForInspectionReviewItBeforeAnotherClone =>
      'O directorio permanece para inspeção. Revise-o antes de outra tentativa de clon.';

  @override
  String get gitUiNoDestinationDirectoryRemains =>
      'Não resta nenhum diretório de destino.';

  @override
  String get gitUiCancelProcess => 'Cancelar o processo';

  @override
  String get gitUiInitialize => 'Inicializar';

  @override
  String get gitUiClone => 'Clonar';

  @override
  String get gitUiChooseNewBase => 'Escolher nova base';

  @override
  String get gitUiChooseUpstreamBoundary => 'Escolher limite upstream';

  @override
  String get gitUiNewBase => 'Nova base';

  @override
  String get gitUiUpstreamBoundaryExcluded => 'Limite upstream · excluído';

  @override
  String get gitUiSameAsUpstreamBoundary => 'Igual ao limite upstream';

  @override
  String get gitUiChooseBranchTagOrCommit => 'Escolher branch, tag ou commit…';

  @override
  String get gitUiUseUpstreamAsNewBase => 'Usar a montante como nova base';

  @override
  String get gitUiChooseAValidBranchTagOrCommitFromLog =>
      'Escolha um ramo, tag ou commit válidos no Registro.';

  @override
  String get gitUiTheFirstRetainedCommitInABranchBlockCannotSquash =>
      'O primeiro commit mantido num bloco de branch não pode usar squash ou fixup: não existe um commit anterior de destino.';

  @override
  String gitUiBranchBlockArg0(String arg0) {
    return 'Bloqueio de ramos $arg0\n';
  }

  @override
  String get gitUiRewordWillRequestANewMessage =>
      '[Reformulação irá solicitar uma nova mensagem]\n';

  @override
  String get gitUiPlannedCommitMessages => 'Mensagens de autorização previstas';

  @override
  String
  get gitUiOriginalCombinedMessagePreviewGitRequestsTheFinalRewordSquash =>
      'Visualização da mensagem original/combinada · Git solicita a reformulação final/squash mensagens';

  @override
  String gitUiResultArg0Arg1(String arg0, String arg1) {
    return 'Resultado $arg0 $arg1';
  }

  @override
  String gitUiCurrentBranchBranch(String branch) {
    return 'Branch atual: $branch';
  }

  @override
  String get gitUiDetachedHEAD2 => 'HEAD destacado';

  @override
  String
  get gitUiRebaseRewritesCommitIdentitiesRemoteTrackingInformationCannotProveHistory =>
      'O rebase reescreve as identidades dos commits. Os dados de rastreio remoto não provam que o histórico nunca foi publicado.';

  @override
  String get gitUiIncludeRootCommits => 'Incluir commits raiz';

  @override
  String get gitUiMergeCommits => 'A fusão compromete-se';

  @override
  String get gitUiFlattenHistory => 'Linearizar histórico';

  @override
  String get gitUiPreserveBranchStructure => 'Preservar estrutura das branches';

  @override
  String get gitUiAutosquash => 'Combinação automática';

  @override
  String get gitUiPrepareGitPlan => 'Preparar plano Git';

  @override
  String gitUiCommitsToReplayCount(String count) {
    return 'Commits a reaplicar: $count';
  }

  @override
  String get gitUiIncludesAllRootCommitsReachableFromThisBranch =>
      'Inclui todos os commits root acessíveis a partir deste ramo.';

  @override
  String gitUiCommitsAfterBoundaryWillBeReplayedOntoBaseTheBoundary(
    String boundary,
    String base,
  ) {
    return 'Os commits após $boundary serão reaplicados sobre $base; o próprio commit limite é excluído.';
  }

  @override
  String get gitUiRoot => 'Raíz';

  @override
  String get gitUiGitBranchLabelResetMergeStructure =>
      'Estrutura de ramo/rótulo/reposição/fusão Git';

  @override
  String get gitUiChooseAnExplicitOldBoundaryOrRootModeThenPrepare =>
      'Escolha um modo explícito de contorno ou raiz, e prepare o plano.';

  @override
  String get gitUiMoveUp => 'Subir';

  @override
  String get gitUiMoveDown => 'Descer';

  @override
  String get gitUiResetPlan => 'Repor plano';

  @override
  String gitUiBranchBlockArg02(String arg0) {
    return ' · bloco de ramos $arg0';
  }

  @override
  String get gitUiSelectACommitForDetailsAndChangedFiles =>
      'Selecione um commit para obter detalhes e alterar arquivos';

  @override
  String get gitUiPreviewCombinedCommitMessages =>
      'Visualização das mensagens de commit combinadas...';

  @override
  String get gitUiAltMovesTheSelectedCommitUnrelatedBranchReferencesWillNot =>
      'Alt+↑/↓ move o commit seleccionado. As referências de ramo não relacionadas não serão atualizadas automaticamente.';

  @override
  String get gitUiCancelPlan => 'Cancelar o plano';

  @override
  String get gitUiStartReviewedRebase => 'Iniciar o rebase revisto?';

  @override
  String gitUiRewriteArg0PlannedCommitsOnArg1DroppedCommitsRemainVisibly(
    String arg0,
    String arg1,
  ) {
    return 'Reescrever $arg0 planejou commits em $arg1. Dropped commits permanece visivelmente marcado neste plano até que você comece.';
  }

  @override
  String get gitUiStartRebase => 'Iniciar rebase';

  @override
  String get gitUiNoContinuingGitOperation => 'Sem operação Git contínua';

  @override
  String get gitUiStoppedForEditingAmend => ' · parou para editar/alterar';

  @override
  String get gitUiTheseAreUnmergedIndexEntriesPossiblyFromAStashApplication =>
      'Estas são entradas de índice não fundidas, possivelmente de um aplicativo de estoque. O Git não tem nenhum estoque continuar ou abortar o comando.';

  @override
  String get gitUiEditTheWorkingFilesStageAndAmendTheCurrentCommit =>
      'Edite os arquivos de trabalho, estabeleça e modifique o commit atual, em seguida, continue esta rebase.';

  @override
  String gitUiArg0Arg1UnmergedStagesArg2(
    String arg0,
    String arg1,
    String arg2,
  ) {
    return '$arg0$arg1 · estágios do índice não mesclados $arg2';
  }

  @override
  String get gitUiTheIndexHasNoUnresolvedEntries =>
      'O índice não tem entradas não resolvidas.';

  @override
  String get gitUiKeepTheCurrentCommitAsAnEmptyCommit =>
      'Mantenha o commit atual como um commit vazio';

  @override
  String get gitUiTheRealIndexHasNoStagedChangesCreateAnExplicit =>
      'O índice real não tem alterações estaduais. Crie um commit vazio explícito, em seguida, continue o sequenciador se permanecer ativo.';

  @override
  String get gitUiKeepEmptyCommit => 'Mantenha o commit vazio...';

  @override
  String get gitUiGitWillTryToReturnToTheOperationSStarting =>
      'O Git tentará regressar ao início da operação. Não é garantida a recuperação de conteúdos anteriores fora do índice, não rastreados ou não guardados.';

  @override
  String get gitUiSkipTheCurrentCommitAndContinueWithTheNextPlanned =>
      'Saltar o commit atual e continuar com o commit próximo planejado.';

  @override
  String
  get gitUiForgetThisOperationSBookkeepingWhileRetainingTheCurrentFiles =>
      'Esqueça esta operação de contabilidade enquanto mantém os arquivos e índices atuais.';

  @override
  String gitUiContinueArg0(String arg0) {
    return 'Continuar $arg0';
  }

  @override
  String get gitUiReloadConflictVersions => 'Recarregar versões de conflito?';

  @override
  String get gitUiReplaceTheUnsavedResultDraftWithTheCurrentWorkingFile =>
      'Substituir o projecto de resultado não salvo pelo ficheiro de trabalho actual. O conteúdo de trabalho salvo é mantido.';

  @override
  String get gitUiLoadingConflictVersions =>
      'A carregar as versões de conflito...';

  @override
  String get gitUiLoadingConflict => 'Carregamento de conflitos';

  @override
  String get gitUiBaseLeft => 'Base → esquerda';

  @override
  String get gitUiBaseRight => 'Base → direita';

  @override
  String get gitUiNoBaseEntryForThisConflict =>
      'Nenhuma entrada de base para este conflito';

  @override
  String get gitUiAcceptEntireLeftFile => 'Aceitar todo o ficheiro esquerdo...';

  @override
  String get gitUiAcceptEntireRightFile =>
      'Aceitar todo o ficheiro da direita…';

  @override
  String get gitUiPreviousConflictRegion => 'Região de conflito anterior';

  @override
  String get gitUiNextConflictRegion => 'Próxima região de conflito';

  @override
  String get gitUiManualResolution => 'Resolução manual';

  @override
  String gitUiRegionArg0Arg1Arg2Reviewed(
    String arg0,
    String arg1,
    String arg2,
  ) {
    return 'Região $arg0/$arg1 · $arg2 reexaminado';
  }

  @override
  String
  get gitUiSourceAlignmentExceededTheTextComparisonLimitSourcePanesRemain =>
      'O alinhamento da fonte ultrapassou o limite de comparação de texto; os painéis fonte permanecem disponíveis para revisão manual.';

  @override
  String get gitUiAcceptLeftRegion => 'Aceitar região esquerda';

  @override
  String get gitUiAcceptRightRegion => 'Aceitar a região certa';

  @override
  String get gitUiKeepManualResultForRegion =>
      'Mantenha o resultado manual para a região';

  @override
  String get gitUiApplyGitSNonConflictingChanges =>
      'Aplicar as mudanças não conflitantes do Git?';

  @override
  String get gitUiReplaceTheCurrentResultDraftWithGitSMergePreview =>
      'Substituir o esboço de resultados atual com a pré-visualização da fusão do Git. Isto elimina as edições de resultados manuais não salvos; o ficheiro de trabalho não está alterado até Salvar.';

  @override
  String get gitUiUseMergePreview => 'Usar a pré-visualização da fusão';

  @override
  String get gitUiApplyNonConflictingChanges =>
      'Aplicar mudanças não conflitantes...';

  @override
  String get gitUiLeftSource => 'Fonte esquerda';

  @override
  String get gitUiResult => 'Resultado';

  @override
  String get gitUiRightSource => 'Fonte direita';

  @override
  String get gitUiStage2 => 'Fase 2';

  @override
  String get gitUiStage3 => 'Fase 3';

  @override
  String
  get gitUiConflictVersionsAreUnavailableRefreshToReviewTheirCurrentState =>
      'As versões de conflito não estão disponíveis. Actualize para rever o seu estado atual.';

  @override
  String get gitUiResultSavedToDiskTheIndexStillDeterminesWhetherThis =>
      'Resultado salvo no disco. O índice ainda determina se este ficheiro está resolvido.';

  @override
  String get gitUiSaveResultDraft => 'Guardar rascunho do resultado';

  @override
  String get gitUiApplyResultAndStageResolution =>
      'Aplicar resultado e preparar resolução';

  @override
  String get gitUiResultEditableUTF8WorkingContent =>
      'Resultado · conteúdo de trabalho editável UTF-8';

  @override
  String get gitUiEditableConflictResult => 'Resultado de conflito editável';

  @override
  String gitUiLeftArg0Arg1RightArg2Arg3(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return 'Esquerda: $arg0 · $arg1\nDireita: $arg2 · $arg3';
  }

  @override
  String get gitUiChooseContentDeletionOrASubmoduleCommitExplicitlyNoBinary =>
      'Escolha o conteúdo, a exclusão ou um submódulo de commit explicitamente. Nenhum dado binário é decodificado como texto editável.';

  @override
  String get gitUiUseEntireLeftContent => 'Usar todo o conteúdo esquerdo...';

  @override
  String get gitUiUseEntireRightContent => 'Usar todo o conteúdo da direita…';

  @override
  String get gitUiDeleteThisPath => 'Excluir este caminho...';

  @override
  String get gitUiResolvedSubmoduleCommit => 'Submódulo de commit resolvido';

  @override
  String get gitUiStageThisExactGitlinkInTheParentThisDoesNot =>
      'Estabelecer este gitlink exato no pai. Isto não verifica ou comete o submódulo.';

  @override
  String get gitUiSetResolvedGitlink => 'Definir o gitlink resolvido...';

  @override
  String gitUiBaseStageArg0(String arg0) {
    return 'Base → estágio $arg0';
  }

  @override
  String get gitUiTheResultWasEditedKeepTheManualResultOrSelect =>
      'O resultado foi editado. Mantenha o resultado manual ou selecione outra região inalterada.';

  @override
  String gitUiApplyArg0Resolution(String arg0) {
    return 'Aplicar a resolução «$arg0»?';
  }

  @override
  String get gitUiStageTheChosenGitlinkCommitInTheParentTheSubmodule =>
      'Estabelecer o gitlink escolhido commit no pai. O submódulo checkout e os seus ficheiros não são substituídos.';

  @override
  String gitUiReplacesTheEntireWorkingPathArg0AndStagesTheDecision(
    String arg0,
  ) {
    return 'Substitui toda a trajetória de trabalho $arg0 e encena a decisão. O conteúdo de trabalho atual e qualquer projeto de resultado não salvo serão descartados.';
  }

  @override
  String get gitUiApplyEntireFileDecision =>
      'Aplicar a decisão do ficheiro inteiro';

  @override
  String get gitUiStageThisConflictResolution =>
      'Encenar esta resolução de conflitos?';

  @override
  String gitUiUseTheEntireEditedResultAsArg0GitRecordsThe(
    String arg0,
    String arg1,
  ) {
    return 'Use todo o resultado editado como $arg0. Git registra o caminho resolvido quando é encenado. Revise todo o conteúdo pretendido primeiro.$arg1';
  }

  @override
  String get gitUiApplyAndStage => 'Aplicar e preparar';

  @override
  String get gitUiReviewResultTextFormatChanges =>
      'Revisar as alterações de formato de texto do resultado';

  @override
  String get gitUiSaveReviewedResult => 'Gravar o resultado revisto';

  @override
  String
  get gitUiNativeGitTableAccessibilityIsUnavailableRetryAfterReconnectingThe =>
      'A acessibilidade da tabela nativa Git não está disponível. Reexperimente após reconectar a aplicação.';

  @override
  String get gitUiSans => 'Sem';

  @override
  String get gitUiSelect => 'Selecionar';

  @override
  String get gitUiContextMenu => 'Menú de contexto';

  @override
  String get gitUiCopyText => 'Copie o texto';

  @override
  String get gitUiLoadingRow => 'A carregar a linha';

  @override
  String get gitUiRetry => 'Reexperimentar';

  @override
  String get gitUiGitMessage => 'Mensagem Git';

  @override
  String get gitUiCancelPrompt => 'Cancelar o prompt';

  @override
  String get gitUiUseMessageAndContinue => 'Usar mensagem e continuar';

  @override
  String get gitUiRespondPrivately => 'Resposta privada';

  @override
  String gitUiViewPreferencesCouldNotBeSavedArg0(String arg0) {
    return 'As preferências de visualização não puderam ser salvas: $arg0';
  }

  @override
  String gitUiCommitDraftStorageArg0(String arg0) {
    return 'Commit projeto de armazenamento: $arg0';
  }

  @override
  String gitUiViewPreferencesCouldNotBeReadArg0(String arg0) {
    return 'As preferências de visualização não puderam ser lidas: $arg0';
  }

  @override
  String gitUiCommitDraftWasRetainedInMemoryButCouldNotBe(String arg0) {
    return 'O rascunho de compromisso foi mantido em memória, mas não pôde ser salvo: $arg0';
  }

  @override
  String get gitUiTheReviewedRepositoryIsReadOnlyForThisOperationHistory =>
      'O repositório revisado é apenas de leitura para esta operação. O histórico e a inspeção de conteúdo permanecem disponíveis.';

  @override
  String gitUiGitReturnedArg0TheApplicationCouldNotRefreshItsDocuments(
    String arg0,
    String arg1,
  ) {
    return 'Git retornou $arg0. A aplicação não pôde atualizar seus documentos: $arg1';
  }

  @override
  String get gitUiSelectCommitInLog => 'Selecionar commit no histórico…';

  @override
  String get gitUiCurrentBranch => 'Branch atual';

  @override
  String get gitUiNoMatchingBranchesOrTagsSelectACommitInLog =>
      'Não há ramificações ou etiquetas correspondentes. Selecione um commit no Log.';

  @override
  String get gitUiBranches => 'Branches';

  @override
  String get gitUiPushCommits => 'Enviar commits';

  @override
  String gitUiPullIntoArg0(String arg0) {
    return 'Puxar para $arg0';
  }

  @override
  String gitUiResolveArg0(String arg0) {
    return 'Resolução $arg0';
  }

  @override
  String get gitUiCurrentOperation => 'Operação em curso';

  @override
  String get gitUiRebaseCommits => 'Rebase de commits';

  @override
  String get gitUiFetch2 => 'Buscar…';

  @override
  String get gitUiPull => 'Puxar…';

  @override
  String get gitUiPush2 => 'Enviar…';

  @override
  String get gitUiBranches2 => 'Branches…';

  @override
  String get gitUiManageRemotes => 'Gerir remotos…';

  @override
  String gitUiMergeIntoArg0(String arg0) {
    return 'Únete-te para $arg0...';
  }

  @override
  String get gitUiRebase2 => 'Rebase…';

  @override
  String get gitUiConflictsAndCurrentOperation =>
      'Conflitos e operações actuais...';

  @override
  String get gitUiStashes2 => 'Stashes…';

  @override
  String get gitUiWorktrees => 'Árvores de trabalho…';

  @override
  String get gitUiSubmodules => 'Submódulos…';

  @override
  String get gitUiReflogAndRecovery => 'Reflog e recuperação…';

  @override
  String get gitUiCloneRepository => 'Clonar repositório…';

  @override
  String get gitUiRevokeRepositoryTrust => 'Revogar a confiança no repositório';

  @override
  String get gitUiWaitingForRepositoryStatus =>
      'Aguardando o status do repositório';

  @override
  String get gitUiRepositoryStatusUnavailableRefresh =>
      'O estado do repositório não está disponível; atualizar';

  @override
  String get gitUiManageRemotes2 => 'Gerir remotos';

  @override
  String gitUiMergeIntoArg02(String arg0) {
    return 'Fusionar em $arg0';
  }

  @override
  String get gitUiWorktrees2 => 'Árvores de trabalho';

  @override
  String get gitUiSubmodules2 => 'Submódulos';

  @override
  String get gitUiReflogAndRecovery2 => 'Reflog e recuperação';

  @override
  String gitUiCloneRepositoryArg0(String arg0) {
    return 'Depósito de clones · $arg0';
  }

  @override
  String get gitUiApply => 'Aplicar';

  @override
  String get gitUiResizeGitPanes => 'Redimensionar os painéis Git';

  @override
  String gitUiArg0Percent(String arg0) {
    return '$arg0 por cento';
  }

  @override
  String gitUiExitStatusStatus(String status) {
    return 'Estado de saída: $status';
  }

  @override
  String get gitUiRepositoryChangedRefreshAndReviewBeforeTryingAgain =>
      'O repositório mudou. Actualize e revise antes de tentar novamente.';

  @override
  String get gitUiAnotherOperationHoldsTheRepositoryOrIndexLockWaitThen =>
      'Outra operação mantém o repositório ou o bloco do índice. Espere, em seguida, atualize.';

  @override
  String get gitUiRepositoryTrustIsRequiredForThisOperation =>
      'Para esta operação é necessária a confiança de repositório.';

  @override
  String get gitUiTheGitServiceDisconnectedReconnectAndReconcileTheRepository =>
      'O serviço Git desconectou. Reconecte e reconcilia o repositório.';

  @override
  String
  get gitUiTheInstalledGitExecutableCannotSupportThisOperationReviewIts =>
      'O executável Git instalado não pode suportar esta operação. Revise os requisitos de tempo de execução abaixo.';

  @override
  String get gitUiThisRepositoryIsReadOnlyForTheRequestedOperationReview =>
      'Este repositório é apenas de leitura para a operação solicitada. A revisão e o histórico permanecem disponíveis.';

  @override
  String
  get gitUiTheOperationNeedsReconciliationReviewTheResultingRepositoryOrRemote =>
      'A operação precisa de reconciliação. Revise o repositório resultante ou o estado remoto antes de o repetir.';

  @override
  String get gitUiGitAuthenticationFailedReviewTheCredentialHelperOrUnlockThe =>
      'A autenticação do Git falhou. Revise o ajudante credencial ou desbloqueie o chaveiro configurado.';

  @override
  String get gitUiSshHostVerificationFailedReviewTheHostIdentityThroughYour =>
      'A verificação do host SSH falhou. Revise a identidade do host através das ferramentas SSH configuradas.';

  @override
  String get gitUiCommitSigningFailedOrWasCancelledReviewTheSigningKey =>
      'Cometar a assinatura falhou ou foi cancelado. Revise a chave de assinatura, o agente e a ferramenta de assinatura configurada.';

  @override
  String get gitUiSetARepositoryAuthorNameAndEmailThenReturnTo =>
      'Defina um nome de autor do repositório e um e- mail, e retorne ao boceto de mensagem preservado.';

  @override
  String get gitUiGitRejectedTheReviewedUpdateRefreshAndReviewTheActual =>
      'Git rejeitou a atualização revista. Actualize e revise o destino real antes de tentar novamente.';

  @override
  String get gitUiWorkingOrStagedChangesPreventThisOperationReviewCommitOr =>
      'As alterações operacionais ou encenadas impedem esta operação. Revise, commit ou esconda- as explicitamente.';

  @override
  String get gitUiARequiredGitObjectIsUnavailableReviewShallowOrPartial =>
      'Um objeto Git obrigatório não está disponível. Reveja limites rasos ou parciais de repositório e busque explicitamente se necessário.';

  @override
  String gitUiGitOperationFailedArg0(String arg0) {
    return 'A operação Git falhou: $arg0';
  }

  @override
  String get gitUiDiagnostics => 'Diagnóstico';

  @override
  String get gitUiAuthorizeGitInspection => 'Autorizar a inspecção Git...';

  @override
  String get gitUiCopyDiagnostics => 'Copie o diagnóstico';

  @override
  String get gitUiActions => 'Acções';

  @override
  String gitUiBranchAtArg0(String arg0) {
    return 'Branch em $arg0';
  }

  @override
  String get gitUiCreatesALocalBranchWithoutCheckingItOut =>
      'Cria um ramo local sem verificar.';

  @override
  String gitUiTagArg0(String arg0) {
    return 'Tag $arg0';
  }

  @override
  String gitUiReadOnlySnapshotArg0(String arg0) {
    return 'instantâneo de apenas leitura · $arg0';
  }

  @override
  String get gitUiCherryPickCommits => 'Aplicar commits com cherry-pick';

  @override
  String get gitUiRevertCommits => 'Reverter os compromissos';

  @override
  String get gitUiCompareToFullRevisionID =>
      'Comparar com o ID de revisão completa';

  @override
  String gitUiTreeComparisonDirectionArg0TheRevisionEnteredHere(String arg0) {
    return 'Direção de comparação de árvores: $arg0 → a revisão introduzida aqui.';
  }

  @override
  String get gitUiEnterAFullValidObjectID =>
      'Digite um ID de objeto válido completo.';

  @override
  String gitUiArg0Arg1TreeComparison(String arg0, String arg1) {
    return '$arg0 → $arg1 · comparação de árvores';
  }

  @override
  String gitUiResetArg0ToArg1(String arg0, String arg1) {
    return 'Restaurar $arg0 para $arg1';
  }

  @override
  String
  get gitUiMovesHEADCurrentBranchReflogDoesNotRecoverArbitraryUntracked =>
      'Move HEAD/o branch atual. O reflog não recupera qualquer conteúdo não rastreado ou não guardado.';

  @override
  String get gitUiMoveHEADKeepIndexAndWorkingFiles =>
      'Mover HEAD; manter o índice e os ficheiros de trabalho.';

  @override
  String get gitUiMoveHEADAndReplaceIndexKeepWorkingFiles =>
      'Mover HEAD e substituir o índice; manter os ficheiros de trabalho.';

  @override
  String
  get gitUiReplaceHEADIndexAndTrackedWorkingFilesMayOverwriteObstructing =>
      'Substituir HEAD, índice e ficheiros rastreados; pode substituir ficheiros não rastreados que impeçam a operação.';

  @override
  String get gitUiReplaceHEADIndexAndEligibleFilesRefuseIfLocalChanges =>
      'Substituir HEAD, índice e ficheiros elegíveis; recusar se houver perda de alterações locais.';

  @override
  String gitUiResetWithArg0(String arg0) {
    return 'Restaurar com $arg0?';
  }

  @override
  String gitUiArg0Arg1ReviewTheSelectedModeSEffectsBeforeApplying(
    String arg0,
    String arg1,
  ) {
    return '$arg0 → $arg1 Revise os efeitos do modo selecionado antes de aplicar.';
  }

  @override
  String gitUiResetArg0(String arg0) {
    return 'Restaurar $arg0';
  }

  @override
  String gitUiTargetArg0(String arg0) {
    return 'Alvo $arg0';
  }

  @override
  String get gitUiTagName => 'Nome da tag';

  @override
  String get gitUiAnnotatedTag => 'Tag anotada';

  @override
  String get gitUiCryptographicSigning => 'Assinatura criptográfica';

  @override
  String get gitUiConfiguredPolicy => 'Política configurada';

  @override
  String get gitUiSignThisTag => 'Assinar esta etiqueta';

  @override
  String get gitUiDoNotSign => 'Não assinar';

  @override
  String get gitUiTagMessage => 'Mensagem de etiqueta';

  @override
  String get gitUiCreatesTheTagLocallyPublishSelectedTagsExplicitlyInPush =>
      'Cria a etiqueta localmente. Publique as etiquetas selecionadas explicitamente na revisão Push.';

  @override
  String gitUiCompleteTreesArg0Arg1(String arg0, String arg1) {
    return 'Árvores completas: $arg0 → $arg1';
  }

  @override
  String get gitUiNextChangedFilePage => 'Próxima página de arquivo alterado';

  @override
  String get gitUiReadOnlyRepositorySnapshotOpeningAFileNeverChecksOut =>
      'instantâneo do repositório apenas de leitura. Abrir um ficheiro nunca verifica esta revisão.';

  @override
  String get gitUiOpenReadOnlyVersion => 'Versão aberta de apenas leitura';

  @override
  String get gitUiRestoreThisPathWaitingForRepositoryStatus =>
      'Restaurar este caminho... · Aguardando o status do repositório';

  @override
  String get gitUiRestoreThisPath => 'Restaurar este caminho...';

  @override
  String gitUiHistoryArg0(String arg0) {
    return 'História · $arg0';
  }

  @override
  String gitUiRestoreArg0(String arg0) {
    return 'Restaurar $arg0?';
  }

  @override
  String gitUiReplaceThisWorkingPathWithRevisionArg0ExistingStagedContent(
    String arg0,
  ) {
    return 'Substitua este caminho de trabalho pela revisão $arg0. O conteúdo estágio existente é mantido.';
  }

  @override
  String get gitUiRestoreWorkingFile => 'Restaurar o ficheiro de trabalho';

  @override
  String gitUiFileHistoryFollowsRenamesArg0(String arg0) {
    return 'O histórico do arquivo segue os renomes · $arg0';
  }

  @override
  String get gitUiBlameCommittedContent => 'Anotações · conteúdo do commit';

  @override
  String get gitUiBlame => 'Anotações…';

  @override
  String gitUiArg0WorkingTree(String arg0) {
    return '$arg0 → Árvore de Trabalho';
  }

  @override
  String get gitUiOpenReadOnlyHistoricalFile =>
      'Abrir o ficheiro histórico de apenas leitura';

  @override
  String get gitUiCompareToCurrentFile => 'Comparar com o ficheiro actual';

  @override
  String get gitUiCompareToParent => 'Comparar com o pai...';

  @override
  String gitUiCommittedArg0UnsavedEditorContentIsNotPartOfThese(String arg0) {
    return 'Committed $arg0 · conteúdo de editor não salvo não faz parte dessas anotações';
  }

  @override
  String gitUiHistoryFromArg0(String arg0) {
    return 'História de $arg0';
  }

  @override
  String get gitUiBoundary => ' · limite';

  @override
  String gitUiArg0Arg1OriginalLineArg2Arg3(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return '$arg0  $arg1\nLinha original $arg2$arg3';
  }

  @override
  String get gitUiPreviousLines => 'Linhas anteriores';

  @override
  String get gitUiNextLines => 'Próximas linhas';

  @override
  String gitUiExplicitApplicationOrderDestinationArg0(String arg0) {
    return 'Pedido de pedido explícito · destino $arg0';
  }

  @override
  String get gitUiAddFullCommitObjectID =>
      'Adicionar o ID do objeto de commit completo';

  @override
  String get gitUiAddReviewedCommit => 'Adicionar uma revisão de commit...';

  @override
  String get gitUiMoveEarlier => 'Mover mais cedo';

  @override
  String get gitUiMoveLater => 'Mais tarde.';

  @override
  String get gitUiRemoveFromReviewedSequence =>
      'Remover da sequência de revisão';

  @override
  String get gitUiApplyChangesWithoutCreatingCommits =>
      'Aplicar alterações sem criar commits';

  @override
  String get gitUiUseThisExplicitMainlineParentForMergeCommits =>
      'Use este pai de linha principal explícito para fundir commits';

  @override
  String get gitUiEmptyOrAlreadyAppliedCommitsMayStopGitForAn =>
      'Compromissos vazios ou já aplicados podem parar o Git para uma decisão explícita de saut ou continuação.';

  @override
  String get gitUiRevertInReviewedOrder => 'Reverter em ordem de revisão';

  @override
  String get gitUiCherryPickInReviewedOrder =>
      'Pilha de cereja em ordem de revisão';

  @override
  String get gitUiReturnToFiles => 'Voltar para os Ficheiros';

  @override
  String get gitUiGit => 'Git';

  @override
  String get gitUiCommit => 'Criar commit';

  @override
  String get gitUiBackToCommit => 'Voltar ao Commit';

  @override
  String get gitUiSelectAChangeToReview => 'Selecione uma alteração para rever';

  @override
  String get gitUiLoadingBranch => 'A carregar o ramo...';

  @override
  String get gitUiBranchUnavailable => 'Sucursal indisponível';

  @override
  String get gitUiUnbornHEAD => 'HEAD sem commits';

  @override
  String gitUiDetachedHEADRevision(String revision) {
    return 'HEAD destacado · $revision';
  }

  @override
  String get gitUiContinueAction => 'Continuar';

  @override
  String get gitUiPick => 'Manter';

  @override
  String get gitUiReword => 'Reescrever mensagem';

  @override
  String get gitUiEdit => 'Editar';

  @override
  String get gitUiSquash => 'Combinar';

  @override
  String get gitUiFixup => 'Combinar sem mensagem';

  @override
  String get gitUiDrop => 'Omitir';

  @override
  String get gitUiAbort => 'Abortar';

  @override
  String get gitUiSkip => 'Ignorar';

  @override
  String get gitUiQuit => 'Sair da operação';

  @override
  String get gitUiSoft => 'Suave';

  @override
  String get gitUiMixed => 'Misto';

  @override
  String get gitUiHard => 'Rígido';

  @override
  String get gitUiKeep => 'Preservar';

  @override
  String get gitUiCreate => 'Criar';

  @override
  String get gitUiApplyStash => 'Aplicar stash';

  @override
  String get gitUiPopStash => 'Aplicar stash e remover se tiver êxito';

  @override
  String get gitUiDropStashAction => 'Eliminar stash';

  @override
  String get gitUiEditedResult => 'Resultado editado';

  @override
  String get gitUiLeftContent => 'Conteúdo esquerdo';

  @override
  String get gitUiRightContent => 'Conteúdo direito';

  @override
  String get gitUiDeletePath => 'Excluir o caminho';

  @override
  String get gitUiSubmoduleCommit => 'Submódulo de commit';

  @override
  String get gitUiPresentContent => 'Conteúdo disponível';

  @override
  String get gitUiAbsentContent => 'Ausência';

  @override
  String get gitUiBinaryContent => 'Conteúdo binário';

  @override
  String get gitUiTooLargeContent => 'O conteúdo excede o limite de exibição';

  @override
  String get gitUiUnavailableContent => 'Conteúdo não disponível';

  @override
  String get gitUiGitlinkContent => 'Ponto de submódulo';

  @override
  String get gitUiSymlinkContent => 'Ligação simbólica';

  @override
  String get gitUiNoOperation => 'Nenhuma operação';

  @override
  String get gitUiCherryPickOperation => 'Cherry-pick';

  @override
  String get gitUiRevertOperation => 'Reverter';

  @override
  String get gitUiApplyMailboxOperation => 'Aplicar os patches';

  @override
  String get gitUiSquashOperation => 'fusão de squash';

  @override
  String get gitUiUnmergedOperation => 'Índice não fundido';

  @override
  String get gitUiWaitingForPromptPhase => 'Aguardando a sua resposta';

  @override
  String get gitUiStoppedPhase => 'Pára para revisão';

  @override
  String get gitUiCompletedPhase => 'Concluído';

  @override
  String get gitUiFailedPhase => 'Falha';

  @override
  String get gitUiCancelledPhase => 'Cancelado';

  @override
  String get gitUiUncertainPhase => 'O resultado requer reconciliação';

  @override
  String gitUiStageVersion(String stage) {
    return 'Estágio de conflito $stage';
  }

  @override
  String get gitUiGitMergePreview => 'Git fusão pré-visualização';

  @override
  String get gitUiNormalizedWorking => 'Árvore de Trabalho · Git normalizado';

  @override
  String gitUiPercentValue(String value) {
    return '$value por cento';
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
  String get gitUiUtf8Bom => 'UTF-8 com marca de ordem de byte (BOM)';

  @override
  String get gitUiUtf8NoBom => 'UTF-8 sem marca de ordem de byte (BOM)';

  @override
  String get gitUiAddsBom =>
      'Esta edição adiciona uma marca UTF-8 byte-order (BOM) no início do arquivo.';

  @override
  String get gitUiRemovesBom =>
      'Esta edição remove a marca UTF-8 byte-order (BOM) do início do arquivo.';

  @override
  String get gitUiNoLineTerminators => 'Sem terminadores de linha';

  @override
  String gitUiLineEndings(String format) {
    return 'Finais de linha $format';
  }

  @override
  String gitUiMixedLineEndings(String formats) {
    return 'Finais de linhas mistas ($formats)';
  }

  @override
  String gitUiNoFinalLf(String format) {
    return '$format · sem LF final';
  }

  @override
  String gitUiLineEndingChange(String before, String after) {
    return 'O formato de terminação de linha muda de $before para $after. O texto da área de transferência pode usar terminações de linha diferentes do arquivo original.';
  }

  @override
  String get gitUiGitFailure =>
      'A operação do Git falhou, revise os diagnósticos abaixo.';

  @override
  String get gitUiAbortInline => 'Abortar';

  @override
  String get gitUiSkipInline => 'Ignorar';

  @override
  String get gitUiQuitInline => 'parar';

  @override
  String get gitUiMergeInline => 'Mesclar';

  @override
  String get gitUiRebaseInline => 'Rebase';

  @override
  String get gitUiCherryPickInline => 'Cherry-pick';

  @override
  String get gitUiRevertInline => 'Reverter';

  @override
  String get gitUiApplyMailboxInline => 'AplicarCaixa de Correio';

  @override
  String get gitUiSquashInline => 'Combinar';

  @override
  String get gitUiUnmergedInline => 'não fundidos';

  @override
  String get gitHostFetch => 'Buscar';

  @override
  String get gitHostRefreshGitStatus => 'Actualizar o estado do Git';

  @override
  String get gitHostCommitStaged => 'Compromisso encenado';

  @override
  String get gitHostGitBranches => 'Raízes de gítalo';

  @override
  String get gitHostReviewPush => 'Revisar o empurrão';

  @override
  String get gitHostGit => 'Git';

  @override
  String get gitHostGitOperationsApplyToThisEntireRepositoryAndMay =>
      'As operações Git aplicam-se a todo este repositório e podem executar seus ganchos configurados, filtros, credenciais e ferramentas de assinatura.';

  @override
  String get gitHostContentUnavailable => 'Conteúdo indisponível';

  @override
  String get gitHostInitializeRepository => 'Iniciar o repositório';

  @override
  String get gitHostCloneRepository => 'Clonar repositório';

  @override
  String get gitHostInitializeHere => 'Inicie aqui...';

  @override
  String get gitHostCloneRepository2 => 'Clonar repositório…';

  @override
  String get gitHostGitLog => 'Histórico do Git';

  @override
  String get gitUiAbsentPlaceholder => '(ausente)';

  @override
  String get gitUiUnborn => 'não-nascidos';

  @override
  String gitUiRebasedHistoryRevision(String revision) {
    return 'Histórico com nova base · $revision';
  }

  @override
  String gitUiCurrentHistoryRevision(String revision) {
    return 'Histórico atual · $revision';
  }

  @override
  String gitUiReplayedCommitRevision(String revision) {
    return 'Commit reaplicado · $revision';
  }

  @override
  String gitUiIncomingContentRevision(String revision) {
    return 'Conteúdo recebido · $revision';
  }

  @override
  String get gitUiContentConflict => 'Conflito de conteúdo';

  @override
  String get gitUiSubmoduleConflict => 'Conflito de submódulos';

  @override
  String get gitUiSymlinkConflict => 'Conflito de ligações simbólicas';

  @override
  String get gitUiAddAddConflict => 'Adicionado em ambos os lados';

  @override
  String get gitUiModifyDeleteConflict =>
      'Modificado/suprimido ou renomeado/suprimido';

  @override
  String gitUiConflictIdentity(String path, String kind) {
    return '$path · $kind';
  }

  @override
  String get gitUiDiscardUnsavedIndexDraft =>
      'Descartar o rascunho do índice não guardado?';

  @override
  String get gitUiClosingTheIndexEditorDiscardsOnlyItsDraft =>
      'Fechar o editor do índice descarta apenas o rascunho. O índice e o ficheiro de trabalho permanecem inalterados.';

  @override
  String get gitUiDiscardIndexDraft => 'Descartar rascunho do índice';

  @override
  String get gitUiDiscardUnsavedConflictDraft =>
      'Descartar o resultado do conflito não guardado?';

  @override
  String get gitUiClosingTheConflictEditorDiscardsOnlyItsDraft =>
      'Fechar o editor de conflitos descarta apenas o rascunho do resultado não guardado. O conteúdo de trabalho guardado e o índice permanecem inalterados.';

  @override
  String get gitUiDiscardConflictDraft => 'Descartar rascunho do conflito';

  @override
  String get gitUiOpenCurrentFile => 'Abrir ficheiro atual';

  @override
  String get gitUiPreviousSearchMatch => 'Resultado anterior';

  @override
  String get gitUiNextSearchMatch => 'Resultado seguinte';

  @override
  String gitUiSearchMatchPosition(String current, String count) {
    return 'Resultado $current de $count';
  }

  @override
  String gitUiSearchResultsLimited(String count) {
    return 'São apresentados os primeiros $count resultados. Refine a pesquisa para rever mais.';
  }

  @override
  String get gitUiRevealRevisionWithoutFilters => 'Mostrar revisão sem filtros';

  @override
  String get gitUiRestoreHistoryFilters => 'Restaurar filtros do histórico';

  @override
  String get gitUiShowAllAffectedFiles => 'Mostrar todos os ficheiros afetados';

  @override
  String get gitUiGraphLanes => 'Faixas do grafo';

  @override
  String gitUiRebaseArg0OntoArg1(String arg0, String arg1) {
    return 'Rebasear $arg0 sobre $arg1';
  }

  @override
  String get gitUiChangedLine => 'Linha alterada';

  @override
  String get gitUiCopyHeadRegionIntoIndexDraft =>
      'Copiar região de HEAD para o rascunho do índice';

  @override
  String get gitUiCopyWorkingRegionIntoIndexDraft =>
      'Copiar região de trabalho para o rascunho do índice';

  @override
  String get gitUiUpdatingConflictRegions => 'A atualizar regiões de conflito';

  @override
  String gitUiRemainingConflictMarkers(String count) {
    return 'Regiões do resultado com marcadores de conflito: $count';
  }

  @override
  String get gitUiIgnoreLeftRegion => 'Ignorar sugestão da esquerda';

  @override
  String get gitUiIgnoreRightRegion => 'Ignorar sugestão da direita';

  @override
  String get gitUiIndexAppliedNewerDraftPreserved =>
      'O rascunho submetido foi escrito no índice. O texto mais recente continua neste editor. Recarregue e reveja as versões atuais antes de o aplicar.';

  @override
  String get gitUiNewerConflictDraftRetained =>
      'O resultado submetido foi guardado. O seu rascunho de resultado mais recente continua por guardar.';

  @override
  String get gitUiNoFileHistoryForThisPathAndRevision =>
      'Não há histórico de ficheiros disponível para este caminho e revisão.';

  @override
  String get gitUiReviewSavedIndexAndKeepDraft =>
      'Rever o índice guardado e manter o rascunho';

  @override
  String get gitUiIndexSourcesChangedSinceApply =>
      'O índice guardado ou as suas origens foram alterados. O rascunho mais recente é mantido; reveja estas alterações separadamente antes de o aplicar.';
}

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class AppLocalizationsPtBr extends AppLocalizationsPt {
  AppLocalizationsPtBr() : super('pt_BR');

  @override
  String get notesNewFromRetainedText =>
      'Nova nota a partir do texto preservado';

  @override
  String get notesAccountThrottled =>
      'Nextcloud pediu uma pausa. Aguarde antes de entrar novamente.';

  @override
  String get notesSettingsRefreshing =>
      'A atualizar Notes após a confirmação das configurações';

  @override
  String get notesExportOperationFailed =>
      'A exportação falhou antes da publicação. Verifique a origem e o destino e volte a exportar.';

  @override
  String get notesRecoveryCreatedNotOpened =>
      'A nota recuperada foi salva, mas não abriu. Resolva as alterações pendentes no editor ou nas propriedades e abra esta nota existente.';

  @override
  String get notesSettingsPendingNotes =>
      'Notas pendentes, conflitos ou criações incertas impedem esta alteração. Sincronize ou reveja em Notes e volte a salvar este rascunho preservado.';

  @override
  String get notesSettingsPendingAttachments =>
      'Operações de anexos impedem esta alteração. Reveja os anexos em Notes e volte a salvar este rascunho preservado.';

  @override
  String get notesAccountServerAddress =>
      'Use o endereço HTTPS canônico do Nextcloud e reinicie a autenticação. Não foi possível verificar o endereço ou o redirecionamento.';

  @override
  String get notesAccountUnsupported =>
      'Notes está indisponível ou a API não é suportada. Ative Nextcloud Notes com API principal 1 e secundária 4 ou posterior.';

  @override
  String get notesAccountAuthorizeAgain =>
      'Nextcloud rejeitou as credenciais. Autorize novamente a conta ou volte a ligá-la.';

  @override
  String get notesAccountCheckForbidden =>
      'Nextcloud recusou a verificação de funcionalidades de Notes. Peça autorização ao administrador e tente novamente.';

  @override
  String get notesAccountMalformed =>
      'Não foi possível verificar a resposta do Nextcloud. Verifique a instalação do servidor e reinicie a autenticação.';

  @override
  String get notesAccountTimedOut =>
      'A autenticação expirou. Reinicie-a e conclua a autorização no navegador.';

  @override
  String get notesAccountBrowserUnavailable =>
      'Não foi possível abrir o navegador do sistema. Verifique o navegador padrão e reinicie a autenticação.';

  @override
  String get notesAccountNetwork =>
      'Nextcloud está inacessível. Verifique a conexão e o servidor e tente autenticar-se novamente.';

  @override
  String get notesAccountRejected =>
      'Nextcloud rejeitou o pedido de funcionalidades. Verifique o acesso com o administrador e tente novamente.';

  @override
  String get notesAccountFailed =>
      'Não foi possível configurar a conta. Tente autenticar-se novamente.';

  @override
  String get notesTransferSourceChanged =>
      'A origem mudou desde a revisão. Reveja o arquivo atual ou capture uma nova imagem antes de tentar novamente.';

  @override
  String get notesTransferUnreadable =>
      'Não foi possível ler a origem. Verifique o acesso ao arquivo ou pasta e reveja.';

  @override
  String get notesTransferInvalidSnapshot =>
      'Imagem inválida ou não suportada. Escolha uma imagem BusyMark Notes válida ou uma origem Markdown.';

  @override
  String get notesTransferMediaLimit =>
      'Os conteúdos multimédia excedem o limite de importação. Reduza os do item afetado e reveja-o.';

  @override
  String get notesTransferUnsafeSource =>
      'A origem contém um caminho inseguro. Escolha arquivos na pasta de origem e reveja.';

  @override
  String get notesTransferDestination =>
      'Não foi possível escrever a exportação. Verifique o acesso e espaço livre no destino e tente novamente.';

  @override
  String get notesTransferOperationFailed =>
      'A transferência falhou. Reveja os itens afetados e tente novamente. Os já importados continuam salvos.';

  @override
  String get notesExportPublishedWithOmissions =>
      'Exportação disponível com omissões';

  @override
  String get notesBatchUnchanged => 'Os valores pedidos já estavam definidos.';

  @override
  String get notesBatchReadOnly =>
      'Esta nota é só de leitura. As propriedades protegidas não podem mudar; Favorito continua permitido.';

  @override
  String get notesBatchReviewChanged =>
      'Esta nota mudou desde a revisão. Reveja o estado atual antes de repetir a ação.';

  @override
  String get notesBatchMissing =>
      'Esta nota já não está disponível. Atualize a lista e reveja os destinos.';

  @override
  String get notesBatchStorage =>
      'Falha ao salvar localmente. Verifique o armazenamento e repita este item; os bem-sucedidos continuam salvos.';

  @override
  String get notesRemoteReviewChanged =>
      'A nota no servidor mudou. O rascunho de união foi preservado. Reveja a comparação atualizada e escolha novamente a resolução.';

  @override
  String get notesReviewRemote => 'Revi a versão atual do servidor';

  @override
  String get wsModuleCapsNotPublished =>
      'A capitalização do módulo não é publicada.';

  @override
  String get wsTitleOverridesAction => 'Títulos da instância e do índice…';

  @override
  String get wsHeadingNotPublished => 'Não é publicado por este gerador.';

  @override
  String get wsMarkdownInstanceTitleLimitation =>
      'O builder fixado não publica títulos por instância em tópicos Markdown. A marcação existente é preservada; consulte o código-fonte.';

  @override
  String get wsTopicIdentity => 'ID do tópico';

  @override
  String get wsElementAnchor => 'Âncora do elemento';

  @override
  String get wsHeadingText => 'Texto do cabeçalho';

  @override
  String get wsDefaultTitle => 'Título padrão';

  @override
  String get wsTopicNavigation => 'Navegação do tópico';

  @override
  String get wsHeadingOptions => 'Atributos do cabeçalho';

  @override
  String get wsDocumentOptions => 'Configurações do documento';

  @override
  String get wsSettingsPresent => 'Existem configurações explícitas';

  @override
  String get wsTitleOverrideExplanation =>
      'Substitui o título publicado; o texto do cabeçalho permanece.';

  @override
  String get wsIgnoreVariables => 'Tratar variáveis como texto literal';

  @override
  String get wsIgnoreVariablesExplanation =>
      'Quando ativo, o texto semelhante a variáveis não é substituído.';

  @override
  String get wsInstanceSelection => 'Instâncias de ajuda';

  @override
  String get wsInstanceExplanation =>
      'Selecione saídas por nomes, grupos, listas, exclusões ou expressões.';

  @override
  String get wsFilterExplanation =>
      'Filtra conteúdo reutilizável por critérios; não seleciona uma instância de ajuda.';

  @override
  String get wsContextHelp => 'ID de ajuda contextual';

  @override
  String get wsCapitalization => 'Capitalização';

  @override
  String get wsLibraryTopic => 'Tópico de biblioteca';

  @override
  String get wsLastModified => 'Última alteração';

  @override
  String get wsMissingTopicHeading =>
      'Não existe H1 do tópico. Adicione-o no código-fonte.';

  @override
  String get wsMultipleTopicHeadings =>
      'O primeiro H1 determina o título do tópico. Os restantes são cabeçalhos separados.';

  @override
  String get wsTopicIdentityMismatch =>
      'O id da raiz difere do ID baseado no arquivo. Use Renomear arquivo do tópico ou consulte o código-fonte.';

  @override
  String get wsUnsupportedProperties =>
      'Os atributos não suportados são preservados. Consulte-os no código-fonte.';

  @override
  String get wsGeneratedAnchor =>
      'Âncora gerada; introduzir um valor cria uma substituição.';

  @override
  String get wsHeadingBuilderLimitation =>
      'O builder fixado não publica atributos H1. Pertencem ao cabeçalho, não à raiz XML.';

  @override
  String get closeOtherTabs => 'Fechar as outras abas';

  @override
  String get tocTopicFromTemplate => 'Tópico a partir de modelo...';

  @override
  String get tocSaveAsTemplate => 'Salvar como modelo';

  @override
  String get tocTemplateDialog => 'Criar tópico a partir de modelo';

  @override
  String get tocTemplatesEditor => 'Modelos de arquivos e código';

  @override
  String get tocEditTemplates => 'Editar modelos...';

  @override
  String get tocCreateCustomTemplate => 'Criar modelo personalizado...';

  @override
  String get tocTemplateCreated => 'Modelo criado';

  @override
  String get tocTemplateDefault => 'Padrão';

  @override
  String get tocTemplateCustom => 'Personalizados';

  @override
  String get tocTemplateFilename => 'Nome do arquivo:';

  @override
  String get tocTemplateMarkdown => 'Markdown (.md)';

  @override
  String get tocTemplateXml => 'XML (.topic)';

  @override
  String get tocTemplatesInternal => 'Internos';

  @override
  String get tocTemplateUnnamed => 'Sem nome';

  @override
  String get tocTemplateNew => 'Novo modelo...';

  @override
  String get tocTemplateName => 'Nome:';

  @override
  String get tocTemplateExtension => 'Extensão:';

  @override
  String get tocTemplateLoadError =>
      'Não foi possível carregar os modelos. Os modelos existentes não foram alterados.';

  @override
  String get tocTemplateSaveError =>
      'Não foi possível salvar os modelos. Suas alterações continuam disponíveis aqui.';

  @override
  String get tocTemplateConflict =>
      'Os modelos foram alterados em outra janela. Cancele e reabra o editor.';

  @override
  String get tocTemplateDuplicateName =>
      'Já existe um modelo com este nome e extensão.';

  @override
  String get tocTemplateFormat => 'Formato:';

  @override
  String get tocTemplateReset => 'Redefinir';

  @override
  String get tocTemplateRetry => 'Tentar novamente';

  @override
  String tocRemoveElementsDialog(int count) {
    return 'Remover $count elementos do sumário';
  }

  @override
  String get tocRemoveElementsRetainFiles =>
      'Os arquivos de origem associados a estes elementos do sumário não serão excluídos.';

  @override
  String get tocOk => 'OK';

  @override
  String get tocSelectExistingTopic =>
      'Selecionar tópico para adicionar à instância atual';

  @override
  String get tocGroupName => 'Nome do grupo';

  @override
  String get tocMoveLineUp => 'Mover linha para cima';

  @override
  String get tocMoveLineDown => 'Mover linha para baixo';

  @override
  String get tocEmptyMdTopic => 'Tópico MD vazio';

  @override
  String get tocEmptyXmlTopic => 'Tópico XML vazio';

  @override
  String get tocCopySpecial => 'Cópia especial';

  @override
  String tocCopyFileName(String name) {
    return 'Nome do arquivo do tópico \'$name\'';
  }

  @override
  String get tocCopyFilePath => 'Caminho do arquivo do tópico';

  @override
  String tocCopyTopicTitle(String title) {
    return 'Título do tópico \'$title\'';
  }

  @override
  String tocCopyElementId(String id) {
    return 'ID do elemento do índice \'$id\'';
  }

  @override
  String get tocCopyFileNameUnavailable => 'Nome do arquivo do tópico';

  @override
  String get tocCopyTopicTitleUnavailable => 'Título do tópico';

  @override
  String get tocCopyElementIdUnavailable => 'ID do elemento do índice';

  @override
  String get tocEditTitleAction => 'Editar título...';

  @override
  String get tocEditTitleDialog => 'Editar título';

  @override
  String get tocRemoveElementAction => 'Remover elemento do índice...';

  @override
  String get tocSetHomePage => 'Definir como página inicial';

  @override
  String tocGoToElement(String fileName) {
    return 'Ir para o elemento do índice em \'$fileName\'';
  }

  @override
  String get tocSynchronize => 'Sincronizar índice e editor';

  @override
  String get tocEmptyGroupAction => 'Grupo vazio';

  @override
  String get tocNewEmptyGroup => 'Novo grupo vazio';

  @override
  String get tocGroupAction => 'Agrupar';

  @override
  String get tocNewGroup => 'Novo grupo';

  @override
  String get tocSortChildren => 'Ordenar subtópicos alfabeticamente';

  @override
  String get tocLinkTopicFiles => 'Vincular arquivos de tópicos ao índice...';

  @override
  String get addLocalMarkdownFiles => 'Adicionar arquivos Markdown locais';

  @override
  String get tocTitleField => 'Título no índice:';

  @override
  String get tocTopicTitleField => 'Título do tópico:';

  @override
  String get tocAdvancedSettings => 'Configurações avançadas';

  @override
  String tocInstanceTitleField(String instanceId) {
    return 'Título para \'$instanceId\':';
  }

  @override
  String get tocOnlyTitleField => 'Título exclusivo do índice:';

  @override
  String get tocInstanceTitleExplanation =>
      'Usado apenas na instância atual. Por padrão, é herdado do título do tópico.';

  @override
  String get tocOnlyTitleExplanation =>
      'Usado apenas no índice. Por padrão, é herdado do título do tópico ou do título específico da instância, se definido. Os títulos são explicados';

  @override
  String get tocTitleDocumentationLink => 'aqui';

  @override
  String get tocFindUsages => 'Localizar';

  @override
  String get tocRefactorMenu => 'Refatorar';

  @override
  String get tocSafeDelete => 'Exclusão segura';

  @override
  String get tocDuplicate => 'Duplicar';

  @override
  String get tocDuplicateFilename => 'Nome do arquivo do tópico:';

  @override
  String get tocDuplicateDialog => 'Duplicar tópico';

  @override
  String get pdfTitlePage => 'Página de título';

  @override
  String get pdfIncludeTitlePage => 'Incluir página de título';

  @override
  String get pdfTitlePageNote =>
      'Esta página não tem cabeçalho, rodapé nem número de página visível.';

  @override
  String get pdfTitlePageTitle => 'Título';

  @override
  String get pdfTitlePageSubtitle => 'Subtítulo';

  @override
  String get pdfTitlePageAuthor => 'Autor';

  @override
  String get pdfTitlePageOrganization => 'Organização';

  @override
  String get pdfTitlePageVersion => 'Versão';

  @override
  String get pdfTitlePageDate => 'Data';

  @override
  String get pdfTitlePageTitleRequired =>
      'Insira um título para a página de título.';

  @override
  String get pdfTocSectionNote =>
      'Começa em uma página separada e pode ocupar várias páginas.';

  @override
  String get appTitle => 'BusyMark';

  @override
  String get appSubtitle =>
      'Editor para arquivos Markdown e projetos de documentação compatíveis com o Writerside.';

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
      'Quando esta opção está ativada, adiciona apenas a versão do sistema operacional Linux e o locale do BusyMark. Nenhum log, arquivo, dados de conta ou outro diagnóstico é anexado.';

  @override
  String get feedbackSubmit => 'Enviar';

  @override
  String get feedbackSubmitting => 'Enviando…';

  @override
  String get feedbackCategoryRequired => 'Escolha uma categoria.';

  @override
  String get feedbackSubjectLength =>
      'O assunto deve ter entre 3 e 120 caracteres.';

  @override
  String get feedbackMessageLength =>
      'A mensagem deve ter entre 10 e 5000 caracteres.';

  @override
  String get feedbackReplyEmailInvalid =>
      'Digite um endereço de e-mail válido ou deixe este campo vazio.';

  @override
  String get feedbackConnectionFailure =>
      'O BusyMark não conseguiu estabelecer conexão. Verifique a conexão com a Internet e tente novamente.';

  @override
  String get feedbackTimeoutFailure =>
      'O pedido excedeu o tempo limite. Tente novamente.';

  @override
  String get feedbackRateLimitedFailure =>
      'Foram enviados relatórios demais a partir desta conexão. Aguarde e tente novamente.';

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
  String get copyPlainText => 'Copiar como texto simples';

  @override
  String get clipboardCopyFailed =>
      'Não foi possível copiar a seleção para a área de transferência.';

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
  String get reading => 'Leitura';

  @override
  String get removeFromRecent => 'Remover dos recentes';

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
      'Personalizar os atalhos de teclado do aplicativo';

  @override
  String get shortcutSyntaxReferenceDescription =>
      'Abrir a referência de sintaxe';

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
  String get wordWrapDescription =>
      'Quebre linhas longas para ajustá-las à largura do editor em vez de rolar horizontalmente.';

  @override
  String get editorFontSize => 'Tamanho da fonte do editor';

  @override
  String get validateOnEdit => 'Validar ao editar';

  @override
  String get clearRecentWorkspaces => 'Limpar histórico recente';

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
  String get settingsEditingButtonsSectionTitle => 'Botões de edição';

  @override
  String get spellingDictionaries => 'Dicionários ortográficos';

  @override
  String get spellingDictionariesDescription =>
      'Instalar e gerenciar dicionários ortográficos';

  @override
  String get settingsDictionariesSectionTitle => 'Dicionários';

  @override
  String get availableSpellingDictionaries => 'Dicionários disponíveis';

  @override
  String get customSpellingDictionaries => 'Dicionários personalizados';

  @override
  String get spellingDictionaryProblems => 'Problemas de dicionários';

  @override
  String get settingsWindowSectionTitle => 'Janela';

  @override
  String get settingsReopenWorkspaceOnStartupTitle =>
      'Reabrir o espaço de trabalho anterior ao iniciar';

  @override
  String get settingsReopenWorkspaceOnStartupDescription =>
      'Abra o espaço de trabalho e as abas da sessão anterior quando o BusyMark iniciar.';

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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count documentos com alterações não salvas. Deseja salvá-los antes de continuar?',
      one:
          'Há 1 documento com alterações não salvas. Deseja salvá-lo antes de continuar?',
    );
    return '$_temp0';
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
    return 'O arquivo de vídeo não existe: $source';
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
  String get insertBlankLine => 'Inserir linha em branco';

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
  String get toc => 'Índice';

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
  String get newSiblingTopic => 'Novo tópico';

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
  String get removeTocElements => 'Remover elementos do TOC';

  @override
  String get reviewUsages => 'Revisar usos';

  @override
  String get deleteTopicFile => 'Excluir arquivo do tópico';

  @override
  String get removeAction => 'Remover';

  @override
  String topicRemovalSummary(String topic) {
    return 'Remover o elemento “$topic” do índice? O arquivo-fonte associado ao índice não será excluído.';
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
  String get topicIsHomePageRemovalWarning =>
      'Este tópico é a página inicial desta instância. Escolha outra página inicial antes de removê-lo do sumário.';

  @override
  String get newHomePage => 'Nova página inicial';

  @override
  String get chooseHomePage => 'Escolher página inicial';

  @override
  String get noHomePageReplacement =>
      'Adicione ou vincule outro tópico elegível a esta instância antes de remover sua página inicial.';

  @override
  String get topicIsStartPageRemovalWarning =>
      'Este tópico é a página inicial de uma instância. Defina outra página inicial antes de excluir seu arquivo de origem.';

  @override
  String topicUsagesCount(int count) {
    return '$count usos encontrados.';
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
  String get setRedirectTo => 'Redirecionar para:';

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
  String get preview => 'Prévia';

  @override
  String get topicRenamePreviewTitle => 'Prévia da renomeação';

  @override
  String topicRenamePathChange(String oldPath, String newPath) {
    return 'Caminho: $oldPath → $newPath';
  }

  @override
  String topicRenameIdChange(String oldId, String newId) {
    return 'ID do tópico: $oldId → $newId';
  }

  @override
  String topicRenameUrlChange(String instance, String oldName, String newName) {
    return 'Instância $instance: $oldName → $newName';
  }

  @override
  String get topicRenameAffectedFiles => 'Arquivos afetados';

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
  String get sourceSearchReplacement => 'Substituir por';

  @override
  String get sourceSearchReplaceCurrent => 'Substituir correspondência atual';

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
      'A reversão foi interrompida porque o arquivo foi alterado simultaneamente. Algumas substituições podem permanecer; o conteúdo deslocado foi preservado no caminho abaixo.';

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
  String get workspaceSearchIncomplete =>
      'Apenas alguns resultados são exibidos. Mostre mais ou restrinja a pesquisa.';

  @override
  String get workspaceSearchShowMore => 'Mostrar mais resultados';

  @override
  String get workspaceSearchSkippedFiles =>
      'A pesquisa está incompleta. Estes arquivos excedem 1 MiB ou não puderam ser lidos:';

  @override
  String get sourceLargeFileFeaturesPaused =>
      'Arquivo grande: o realce e o recolhimento estão pausados';

  @override
  String get nothingToRead => 'Nenhum conteúdo para ler';

  @override
  String get admonition => 'Bloco de destaque';

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
  String workspaceErrorRecentWorkspaceUpdateFailed(String error) {
    return 'Não foi possível atualizar os itens recentes: $error.';
  }

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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count documentos não salvos foram recuperados. Revise cada um antes de salvar ou descartar.',
      one:
          '1 documento não salvo foi recuperado. Revise-o antes de salvar ou descartar.',
    );
    return '$_temp0';
  }

  @override
  String workspaceRecoveryDamaged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count registros de recuperação danificados não puderam ser restaurados. Os registros de recuperação válidos permanecem disponíveis.',
      one:
          '1 registro de recuperação danificado não pôde ser restaurado. O arquivo de recuperação original foi preservado para inspeção.',
    );
    return '$_temp0';
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
    return 'Não é possível excluir a página inicial $topic. Escolha outra página inicial primeiro.';
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
  String errorWritersideTopicRenameIncompleteProjectIndex(
    String module,
    String count,
    String paths,
  ) {
    return 'A renomeação não pode atualizar com segurança todas as referências do projeto porque $count arquivo(s) de tópico no módulo $module não foram analisados: $paths';
  }

  @override
  String get errorWritersideTopicRenameProjectBuffersDirty =>
      'Os arquivos do projeto Writerside têm alterações não salvas. Resolva-as e prepare uma nova visualização da renomeação.';

  @override
  String get errorWritersideTopicRenameProjectInventoryChanged =>
      'O conjunto de módulos do projeto Writerside mudou. Prepare uma nova visualização da renomeação antes da refatoração.';

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
  String diagnosticWritersideWebFileNameInvalid(
    String instanceId,
    String webFileName,
    String topic,
  ) {
    return 'A instância \"$instanceId\" publica o nome de arquivo da Web inválido \"$webFileName\" para o tópico \"$topic\".';
  }

  @override
  String diagnosticWritersideWebFileNameCollision(
    String instanceId,
    String webFileName,
    String firstTopic,
    String secondTopic,
  ) {
    return 'A instância \"$instanceId\" publica \"$firstTopic\" e \"$secondTopic\" como \"$webFileName\".';
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
      other:
          'Todas as alterações preparadas e não preparadas nos arquivos rastreados selecionados serão restauradas para HEAD.',
      one:
          'Todas as alterações preparadas e não preparadas no arquivo rastreado selecionado serão restauradas para HEAD.',
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
  String get gitProjectHistory => 'Histórico do projeto';

  @override
  String get gitFileHistory => 'Histórico do arquivo';

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
      'Mover a branch e redefinir o índice e a árvore de trabalho. As alterações rastreadas são descartadas; os arquivos não rastreados que bloqueiam a operação podem ser excluídos.';

  @override
  String get gitResetModeKeep => 'Keep';

  @override
  String get gitResetModeKeepDescription =>
      'Mover a branch e redefinir os arquivos rastreados, preservando as alterações locais. O Git aborta se essas alterações entrarem em conflito com a redefinição.';

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
      'Salve ou descarte as alterações no editor do BusyMark antes de redefinir a branch atual.';

  @override
  String get gitErrorRestoreStagedFile =>
      'Remova o arquivo do índice antes de restaurar uma versão anterior.';

  @override
  String get gitErrorResetDetachedHead =>
      'Alterne para uma branch antes de redefini-la.';

  @override
  String get gitErrorDiverged =>
      'A branch divergiu. Resolva o merge ou o rebase fora desta versão do BusyMark.';

  @override
  String get gitErrorAuthorIdentity =>
      'O Git precisa do nome e do e-mail do autor antes de criar um commit.';

  @override
  String get gitAuthorIdentityTitle => 'Identidade do autor do Git';

  @override
  String get gitAuthorIdentityMessage =>
      'Informe a identidade que o Git deve registrar nos commits. O BusyMark irá salvá-la e tentar este commit novamente.';

  @override
  String get gitAuthorName => 'Nome';

  @override
  String get gitAuthorEmail => 'E-mail';

  @override
  String get gitAuthorIdentityGlobal => 'Usar em todos os repositórios';

  @override
  String get gitAuthorIdentityGlobalDescription =>
      'Quando instalado como Snap, isto se aplica aos repositórios abertos no BusyMark.';

  @override
  String get gitSaveIdentityAndCommit => 'Salvar e criar commit';

  @override
  String get gitErrorAuthentication => 'A autenticação do Git falhou.';

  @override
  String get gitErrorNetwork => 'A operação de rede do Git falhou.';

  @override
  String get gitErrorConflict => 'O Git relatou conflitos não resolvidos.';

  @override
  String get gitErrorCommandFailed => 'O comando Git falhou.';

  @override
  String get syntaxReference => 'Referência de sintaxe';

  @override
  String get syntaxReferenceMarkdownBlocks => 'Blocos Markdown';

  @override
  String get syntaxReferenceMarkdownBlocksDescription =>
      'Estruturas de bloco compatíveis no código Markdown e na pré-visualização.';

  @override
  String get syntaxReferenceInlineFormatting => 'Markdown em linha';

  @override
  String get syntaxReferenceInlineFormattingDescription =>
      'Formatação dentro de parágrafos, itens de lista e células de tabela.';

  @override
  String get syntaxReferenceRawHtmlBlocks => 'Blocos de HTML bruto';

  @override
  String get syntaxReferenceRawHtmlBlocksDescription =>
      'Tags HTML de bloco seguras renderizadas pelos widgets de pré-visualização do BusyMark.';

  @override
  String get syntaxReferenceRawHtmlInline => 'Tags de HTML bruto em linha';

  @override
  String get syntaxReferenceRawHtmlInlineDescription =>
      'Tags HTML em linha seguras renderizadas sem mostrar as tags literais.';

  @override
  String get syntaxReferenceHeadings => 'Títulos';

  @override
  String get syntaxReferenceParagraphs => 'Parágrafos';

  @override
  String get syntaxReferenceLists => 'Listas';

  @override
  String get syntaxReferenceHtmlContainers => 'Contêineres';

  @override
  String get syntaxReferenceHtmlTextBlocks => 'Blocos de texto';

  @override
  String get syntaxReferenceHtmlFigures => 'Figuras e imagens';

  @override
  String get syntaxReferenceHtmlPreformatted => 'Código pré-formatado';

  @override
  String get syntaxReferenceHtmlDisclosure => 'Blocos expansíveis';

  @override
  String get syntaxReferenceHtmlDescriptionLists => 'Listas de descrição';

  @override
  String get syntaxReferenceHtmlFormattingTags => 'Tags de formatação';

  @override
  String get syntaxReferenceHtmlInlineCodeTags => 'Tags de código em linha';

  @override
  String get syntaxReferenceHtmlNeutralInlineTags => 'Tags de texto semântico';

  @override
  String get syntaxReferenceSanitizedPreviewDescription =>
      'O HTML permitido é convertido em blocos de pré-visualização do BusyMark e não é renderizado em um navegador.';

  @override
  String get syntaxReferenceSourcePreservedDescription =>
      'HTML bruto não editado é salvo exatamente como texto fonte.';

  @override
  String get syntaxReferenceMarkdownInsideHtmlDescription =>
      'Marcadores Markdown dentro de HTML bruto são exibidos como texto literal.';

  @override
  String get syntaxReferenceBlockedContentDescription =>
      'Scripts, estilos, frames, formulários, SVG, MathML, eventos e atributos inseguros são bloqueados.';

  @override
  String get syntaxReferenceSafeUrlsDescription =>
      'Links permitem http, https, mailto, tel, URLs relativas e fragmentos; esquemas inseguros são bloqueados.';

  @override
  String get syntaxReferenceCategory => 'Categoria';

  @override
  String get syntaxReferenceCategoryHtml => 'HTML';

  @override
  String get syntaxReferenceCategoryDiagramsAndApi => 'Diagramas e API';

  @override
  String get syntaxReferenceCategoryMathematics => 'Matemática';

  @override
  String get syntaxReferenceExample => 'Exemplo';

  @override
  String get syntaxReferenceIdentifiers => 'Identificadores e aliases';

  @override
  String get syntaxReferenceScope => 'Escopo';

  @override
  String get syntaxReferenceLimitation => 'Limitação do BusyMark';

  @override
  String get syntaxReferenceOfficialDocumentation => 'Documentação oficial';

  @override
  String get syntaxReferenceScopeWritersideMarkdown =>
      'Somente Markdown do Writerside';

  @override
  String get syntaxReferenceScopeWritersideMarkdownAndXml =>
      'Somente Markdown e XML do Writerside';

  @override
  String get syntaxReferenceMarkdownDescription =>
      'As formas essenciais de Markdown que o BusyMark pode criar e visualizar.';

  @override
  String get syntaxReferenceParagraphExample => 'Um parágrafo de texto.';

  @override
  String get syntaxReferenceTableLimitation =>
      'As tabelas usam a sintaxe de barras verticais do GitHub Flavored Markdown.';

  @override
  String get syntaxReferenceHardBreakIdentifiers =>
      'dois espaços no fim da linha, \\, <br>';

  @override
  String get syntaxReferenceHtmlDescription =>
      'O BusyMark aceita um subconjunto seguro e específico de HTML bruto no código Markdown.';

  @override
  String get syntaxReferenceDiagramsDescription =>
      'Blocos cercados Mermaid, PlantUML, D2 e OpenAPI funcionam no código Markdown. Os identificadores não diferenciam maiúsculas de minúsculas, e o BusyMark preserva a grafia original.';

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
      'Use conteúdo YAML ou JSON em um bloco cercado. O BusyMark não trata um documento YAML ou JSON completo qualquer como referência OpenAPI.';

  @override
  String get syntaxReferenceSemanticDiagramBlocks =>
      'Blocos de código semânticos para diagramas';

  @override
  String get syntaxReferenceSemanticDiagramLimitation =>
      'As formas semânticas code-block e src aceitam Mermaid, PlantUML e D2, não OpenAPI, e somente em projetos Writerside.';

  @override
  String get syntaxReferenceReferencedDiagramSource =>
      'Origem de diagrama referenciada';

  @override
  String get syntaxReferenceReferencedDiagramLimitation =>
      'Os caminhos devem ser relativos e permanecer dentro do projeto Writerside aberto; a forma de bloco cercado com src é exclusiva do Markdown do Writerside.';

  @override
  String get syntaxReferenceMathematicsDescription =>
      'O BusyMark aceita expressões TeX, não documentos TeX ou LaTeX completos.';

  @override
  String get syntaxReferenceInlineMath => 'Matemática em linha';

  @override
  String get syntaxReferenceGithubMath =>
      'Matemática do GitHub com cifrão e crase';

  @override
  String get syntaxReferenceDisplayMath => 'Matemática em bloco';

  @override
  String get syntaxReferenceMathFence => 'Bloco cercado math';

  @override
  String get syntaxReferenceTexFence => 'Bloco cercado tex';

  @override
  String get syntaxReferenceMathDelimitersLimitation =>
      'O BusyMark não reconhece \\(...\\) nem \\[...\\] como delimitadores matemáticos do Markdown.';

  @override
  String get syntaxReferenceTexFenceLimitation =>
      'Fora do modo Writerside, um bloco tex continua sendo um bloco de código comum.';

  @override
  String get syntaxReferenceWritersideMathElement =>
      'Elemento math do Writerside';

  @override
  String get syntaxReferenceWritersideMathElementLimitation =>
      'O elemento math é sintaxe semântica do Writerside, não MathML HTML bruto permitido.';

  @override
  String get syntaxReferenceSemanticTexBlock => 'Bloco de código TeX semântico';

  @override
  String get syntaxReferenceWritersideDescription =>
      'Estas extensões específicas são interpretadas somente em projetos Writerside abertos.';

  @override
  String get syntaxReferenceAdmonitionBlockquote => 'Citação de aviso';

  @override
  String get syntaxReferenceAdmonitionLimitation =>
      'Uma citação simples é uma dica no Markdown do Writerside; no Markdown comum, continua sendo uma citação normal.';

  @override
  String get syntaxReferenceSemanticAdmonitions => 'Avisos semânticos';

  @override
  String get syntaxReferenceSemanticMarkupLimitation =>
      'O Markdown comum não interpreta estes elementos semânticos do Writerside.';

  @override
  String get syntaxReferenceCollapsibleHeading => 'Título recolhível';

  @override
  String get syntaxReferenceCollapsibleCode => 'Bloco de código recolhível';

  @override
  String get syntaxReferenceSemanticCollapsibles =>
      'Conteúdo semântico recolhível';

  @override
  String get syntaxReferenceSemanticCollapsiblesLimitation =>
      'O BusyMark aceita as formas recolhíveis chapter, procedure, code-block e lista de definições, não todo o catálogo do Writerside.';

  @override
  String get syntaxReferenceSemanticCodeBlocks =>
      'Blocos de código semânticos para matemática e diagramas';

  @override
  String get syntaxReferenceVideo => 'Vídeo do Writerside';

  @override
  String get syntaxReferenceVideoLimitation =>
      'Vídeo local usa uma imagem preview-src local; fontes hospedadas devem ser URLs HTTPS compatíveis do YouTube ou Vimeo.';

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
  String get exportFormat => 'Formato de saída';

  @override
  String get exportingPdf => 'Exportando PDF…';

  @override
  String get fileTypePdf => 'Documento PDF';

  @override
  String pdfExported(String fileName) {
    return '$fileName foi exportado.';
  }

  @override
  String pdfExportedWithWarnings(String fileName, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count avisos',
      one: '1 aviso',
    );
    return '$fileName foi exportado com $_temp0.';
  }

  @override
  String get pdfExportUnavailable =>
      'O componente de exportação para PDF está ausente. Reinstale o BusyMark e tente novamente.';

  @override
  String get pdfExportTimedOut =>
      'A exportação para PDF demorou demasiado e foi interrompida.';

  @override
  String get pdfExportFailed =>
      'O BusyMark não conseguiu exportar este documento como PDF.';

  @override
  String get visualizationRendering => 'Renderizando…';

  @override
  String get visualizationStale => 'Exibindo a última renderização válida';

  @override
  String get visualizationShowSource => 'Mostrar código-fonte';

  @override
  String get visualizationShowRender => 'Mostrar renderização';

  @override
  String get visualizationFitWidth => 'Ajustar à largura';

  @override
  String get visualizationSaveImage => 'Salvar imagem';

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
    return '$fileName salvo';
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
  String get openTocFile => 'Abrir arquivo do índice';

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
  String get markdownFiles => 'Arquivos Markdown locais';

  @override
  String get chooseMarkdownFolder => 'Escolher pasta de Markdown';

  @override
  String get errorWritersideInstanceImportSourceRequired =>
      'Escolha uma pasta que contenha arquivos Markdown.';

  @override
  String get instanceAppearance => 'Aparência';

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
      'Permitir indexação por mecanismos de busca';

  @override
  String get allowSearchEngineIndexingDescription =>
      'Permita que mecanismos de busca externos indexem esta saída.';

  @override
  String get offlineArtifact => 'Artefato offline';

  @override
  String get offlineArtifactDescription =>
      'Inclua os recursos para que a documentação gerada funcione de forma autônoma.';

  @override
  String get instanceOutputSettings => 'Configurações de saída';

  @override
  String get markdownImportSource => 'Origem Markdown';

  @override
  String get markdownImportFiles => 'Arquivos Markdown';

  @override
  String get selectNone => 'Não selecionar nenhum';

  @override
  String markdownFilesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Foram encontrados $count arquivos Markdown',
      one: 'Foi encontrado 1 arquivo Markdown',
    );
    return '$_temp0';
  }

  @override
  String get noMarkdownFilesFound =>
      'Não foram encontrados arquivos Markdown neste diretório.';

  @override
  String get copyReferencedMedia => 'Copiar mídia referenciada';

  @override
  String get copyReferencedMediaDescription =>
      'Copie imagens e vídeos locais referenciados pelos arquivos selecionados, preservando os caminhos relativos.';

  @override
  String get instanceIdRenameWarningTitle => 'Mudar o nome do ID da instância?';

  @override
  String instanceIdRenameWarning(String oldId, String newId) {
    return 'O BusyMark vai renomear o arquivo .tree e atualizar as referências do projeto Writerside de “$oldId” para “$newId”. Os scripts de publicação não são alterados e devem ser atualizados separadamente.';
  }

  @override
  String get renameAndUpdateReferences =>
      'Mudar o nome e atualizar referências';

  @override
  String get tocLibraryDescription =>
      'Uma biblioteca de sumário armazena seções reutilizáveis e não produz uma saída própria.';

  @override
  String get defaultTocLibraryName => 'Sumário compartilhado';

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
      'Digite um nome para a instância.';

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
      'Selecione pelo menos um arquivo Markdown para importar.';

  @override
  String errorWritersideInstanceImportFileInvalid(String path) {
    return 'Este não é um arquivo Markdown legível dentro da origem selecionada: $path';
  }

  @override
  String errorWritersideInstanceImportTargetExists(String path) {
    return 'A importação substituiria um arquivo existente do projeto: $path';
  }

  @override
  String get errorWritersideInstanceFilesChanged =>
      'Os arquivos da instância foram alterados no disco. Revise-os e tente novamente.';

  @override
  String errorWritersideInstanceRollbackFailed(String paths) {
    return 'O BusyMark não conseguiu reverter completamente a alteração da instância. Revise estes arquivos antes de continuar: $paths';
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
    return 'O ID de instância “$id” é usado por mais de um arquivo de árvore.';
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
      'O arquivo de grupos de instâncias deve ter um elemento raiz <instance-groups>.';

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
    return 'O elemento de árvore “$id” não existe na árvore registrada “$source”.';
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
  String get aiExplicitEditingDescription =>
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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Foram encontrados $count modelos instalados',
      one: 'Foi encontrado 1 modelo instalado',
    );
    return 'Conectado. $_temp0.';
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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count caracteres',
      one: '1 caractere',
      zero: '0 caracteres',
    );
    return 'O provedor selecionado receberá $_temp0 do contexto exibido.';
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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Há $count modelos compatíveis disponíveis',
      one: 'Há 1 modelo compatível disponível',
      zero: 'Há 0 modelos compatíveis disponíveis',
    );
    return 'Geração verificada com $model. $_temp0.';
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

  @override
  String get goToDeclaration => 'Ir para a declaração';

  @override
  String get findUsages => 'Encontrar usos';

  @override
  String get cannotRenameSymbol =>
      'Não é possível renomear o símbolo com segurança. Verifique o nome e atualize a referência antes de tentar novamente.';

  @override
  String get renameTopicFileInstead =>
      'Os IDs dos tópicos vêm dos nomes dos arquivos. Use Renomear arquivo do tópico no sumário ou na barra lateral Arquivos.';

  @override
  String get keyboardLayout => 'Layout do teclado';

  @override
  String get diagnosticWritersideUnsupported =>
      'O conteúdo não compatível ou malformado é exibido como código-fonte.';

  @override
  String diagnosticWritersideSource(String reference, String reason) {
    return 'Não é possível resolver a origem “$reference”: $reason';
  }

  @override
  String diagnosticWritersideLink(String destination) {
    return 'O destino do link não está disponível nesta instância: $destination';
  }

  @override
  String diagnosticWritersideSchema(
    String element,
    String attribute,
    String reason,
  ) {
    return 'Marcação Writerside inválida: $element, $attribute. $reason';
  }

  @override
  String get diagnosticWritersideLlmsTxt =>
      'Use <llms-txt>true</llms-txt> ou <llms-txt>false</llms-txt>; single-file não é mais compatível.';

  @override
  String diagnosticWritersideReference(String kind, String reference) {
    return 'Não é possível resolver $kind: $reference';
  }

  @override
  String get exportAsHtml => 'Exportar como HTML…';

  @override
  String get fileTypeHtml => 'Documento HTML';

  @override
  String get exportingHtml => 'Exportando HTML…';

  @override
  String get htmlExported => 'Exportação HTML concluída';

  @override
  String get htmlExportFailed => 'Falha na exportação HTML';

  @override
  String get htmlKeepAssetsTogether =>
      'Ao copiar esta exportação, mantenha juntos o arquivo HTML e a pasta de recursos associada.';

  @override
  String get htmlInstanceDescription =>
      'Exporte uma instância como páginas vinculadas offline. Escolha um nome para uma pasta de destino exclusiva.';

  @override
  String get htmlInstance => 'Instância';

  @override
  String get htmlOwnedDirectoryOnly =>
      'Só é possível substituir uma pasta criada pela exportação HTML do BusyMark. Os arquivos modificados ou alheios serão preservados.';

  @override
  String get showInFolder => 'Mostrar na pasta';

  @override
  String sortTableColumn(String column) {
    return 'Ordenar $column';
  }

  @override
  String get exportReset => 'Restaurar padrões';

  @override
  String get exportToc => 'Incluir índice';

  @override
  String get exportTocDepth => 'Profundidade do índice';

  @override
  String get exportNumberHeadings => 'Numerar títulos';

  @override
  String get exportLegal => 'US Legal';

  @override
  String get exportCustom => 'Personalizado';

  @override
  String get exportPageWidth => 'Largura da página (mm)';

  @override
  String get exportPageHeight => 'Altura da página (mm)';

  @override
  String get exportMarginTop => 'Margem superior (mm)';

  @override
  String get exportMarginRight => 'Margem direita (mm)';

  @override
  String get exportMarginBottom => 'Margem inferior (mm)';

  @override
  String get exportMarginLeft => 'Margem esquerda (mm)';

  @override
  String get exportTypography => 'Tipografia';

  @override
  String get exportSans => 'Sem serifas';

  @override
  String get exportSerif => 'Com serifas';

  @override
  String get exportBodySize => 'Tamanho do texto';

  @override
  String get exportCodeSize => 'Tamanho do código';

  @override
  String get exportRunningText => 'Cabeçalho e rodapé';

  @override
  String get exportHeader => 'Cabeçalho';

  @override
  String get exportFooter => 'Rodapé';

  @override
  String get exportNone => 'Nenhum';

  @override
  String get exportDocumentTitle => 'Título do documento';

  @override
  String get exportBottomLeft => 'Embaixo à esquerda';

  @override
  String get exportBottomCenter => 'Embaixo ao centro';

  @override
  String get exportBottomRight => 'Embaixo à direita';

  @override
  String get exportFirstPage => 'Mostrar cabeçalho e rodapé na primeira página';

  @override
  String get exportAccent => 'Cor de destaque / links';

  @override
  String get exportTheme => 'Tema';

  @override
  String get exportAutomatic => 'Automático';

  @override
  String get exportLayout => 'Layout';

  @override
  String get exportContentWidth => 'Largura máxima do conteúdo';

  @override
  String get exportOutput => 'Saída';

  @override
  String get exportPackaging => 'Empacotamento';

  @override
  String get exportSingleFile => 'Um único arquivo HTML';

  @override
  String get exportAssetsDirectory => 'HTML + pasta de recursos';

  @override
  String get exportCustomCss => 'Folha de estilo personalizada…';

  @override
  String get exportRemoveCss => 'Remover folha de estilo';

  @override
  String get exportCssNote =>
      'Escolha um arquivo CSS UTF-8 opcional (até 256 KiB). Importações, URL de recursos e CSS executável ou com escapes são rejeitados. Os estilos seguem os do BusyMark. Nunca são baixados recursos remotos.';

  @override
  String get exportSitePackagingNote =>
      'O Writerside mantém páginas de tópicos separadas e vinculadas. O modo de arquivo único incorpora os recursos em cada página.';

  @override
  String get exportInvalidGeometry =>
      'Deixe pelo menos 20 mm de largura e altura de conteúdo após as margens.';

  @override
  String get exportInvalidColor => 'Insira uma cor como #RRGGBB.';

  @override
  String get exportInvalidCss =>
      'Escolha um arquivo .css UTF-8 legível até 256 KiB, sem importações, URL de recursos, HTML ou CSS executável ou com escapes.';

  @override
  String get clipboardHistory => 'Histórico da Área de Transferência';

  @override
  String get clipboardHistoryDescription =>
      'Abrir o histórico da área de transferência local da sessão.';

  @override
  String get clipboardCurrent => 'Área de transferência atual';

  @override
  String get clipboardCurrentExternal =>
      'Área de transferência de outro aplicativo';

  @override
  String clipboardDestination(String name) {
    return 'Colar em $name';
  }

  @override
  String get clipboardSessionOnly =>
      'Armazenado apenas para esta sessão BusyMark.';

  @override
  String get clipboardNoItems =>
      'O histórico da área de transferência está vazio.';

  @override
  String get clipboardDisabled =>
      'A coleção de Histórico da Área de Transferência está desativada nas Configurações.';

  @override
  String get clipboardUnavailable =>
      'O conteúdo da área de transferência atual não está disponível ou não é suportado.';

  @override
  String get clipboardTooLarge =>
      'Este item da área de transferência é muito grande para ser armazenado.';

  @override
  String get clipboardPastePlainText => 'Colar como Texto Simples';

  @override
  String get clipboardClearAll => 'Limpar o Histórico da Área de Transferência';

  @override
  String get clipboardEntryText => 'Texto';

  @override
  String get clipboardEntryRichText => 'Texto formatado';

  @override
  String get clipboardEntryImage => 'Imagem';

  @override
  String clipboardOrigin(String name) {
    return 'Copiado de $name';
  }

  @override
  String get localHistory => 'Histórico Local';

  @override
  String get localHistoryEllipsis => 'Histórico Local…';

  @override
  String get localHistoryDescription =>
      'Mostrar revisões locais salvas e automáticas para o documento atual.';

  @override
  String get findLocalHistoryEllipsis => 'Encontrar no Histórico Local…';

  @override
  String get findLocalHistoryDescription =>
      'Pesquisar documentos e conteúdo de revisões no Histórico Local.';

  @override
  String get localHistoryNoDocuments =>
      'Nenhum documento possui Histórico Local.';

  @override
  String get localHistoryNoRevisions =>
      'Este documento não possui revisões no Histórico Local.';

  @override
  String get localHistorySelectedRevision => 'Revisão selecionada';

  @override
  String get localHistoryCurrentEditor => 'Conteúdo atual do editor';

  @override
  String get localHistoryCurrentDisk => 'Conteúdo atual no disco';

  @override
  String get localHistoryMissingFile => 'O arquivo original está faltando.';

  @override
  String get localHistoryRestoreRevision => 'Restaurar Versão';

  @override
  String get localHistoryRestoreOriginalLocation =>
      'Restaurar para a Localização Original';

  @override
  String get localHistoryRestoreNewLocation =>
      'Restaurar para a Nova Localização…';

  @override
  String get localHistoryRestoreChange => 'Restaurar Alteração';

  @override
  String get localHistoryRestoreUnavailable =>
      'Esta alteração não pode ser restaurada porque a comparação não está mais atualizada.';

  @override
  String get localHistoryComparisonSimplified =>
      'Esta comparação grande foi simplificada. Restaurar alterações individuais não está disponível.';

  @override
  String localHistoryOlderChange(String text) {
    return 'Alteração da versão anterior: $text';
  }

  @override
  String localHistoryCurrentChange(String text) {
    return 'Alteração do conteúdo atual: $text';
  }

  @override
  String get localHistoryDeleted => 'Excluído';

  @override
  String get localHistoryUntitled => 'Sem Título';

  @override
  String get localHistoryClearDocument => 'Limpar o Histórico deste Documento';

  @override
  String get localHistoryClearAll => 'Limpar todo o Histórico Local';

  @override
  String get localHistoryClearDocumentTitle =>
      'Limpar o histórico do documento?';

  @override
  String get localHistoryClearAllTitle => 'Limpar todo o Histórico Local?';

  @override
  String get localHistoryClearConfirmation =>
      'Isso remove permanentemente as revisões armazenadas. Esta ação não pode ser desfeita.';

  @override
  String get localHistoryWarningIndexRebuilt =>
      'O índice do Histórico Local foi danificado e reconstruído a partir de revisões íntegras.';

  @override
  String localHistoryWarningUnsupportedFormat(String version) {
    return 'Esta loja de Histórico Local usa o formato não suportado $version.';
  }

  @override
  String localHistoryWarningUnavailable(String detail) {
    return 'Histórico Local não está disponível: $detail';
  }

  @override
  String get localHistoryWarningRecordingDisabled =>
      'A gravação está desativada ou este caminho está excluído. Reative a gravação antes de restaurar.';

  @override
  String localHistoryWarningPathChange(String detail) {
    return 'O Histórico Local não conseguiu gravar a alteração do caminho: $detail';
  }

  @override
  String localHistoryWarningDeletedPath(String detail) {
    return 'O Histórico Local não conseguiu reter o caminho excluído: $detail';
  }

  @override
  String get localHistoryWarningRevisionMissing =>
      'A revisão selecionada está ausente ou corrompida.';

  @override
  String localHistoryWarningRevisionRead(String detail) {
    return 'A revisão selecionada não pode ser lida: $detail';
  }

  @override
  String localHistoryWarningCapture(String detail) {
    return 'O Histórico Local não conseguiu capturar esta revisão: $detail';
  }

  @override
  String localHistoryRevisionAt(String reason, String timestamp) {
    return '$reason – $timestamp';
  }

  @override
  String get localHistoryReasonBaseline => 'Linha de Base';

  @override
  String get localHistoryReasonSaved => 'Salvo';

  @override
  String get localHistoryReasonAutomaticCheckpoint => 'Checkpoint automático';

  @override
  String get localHistoryReasonBeforeReload => 'Antes de recarregar';

  @override
  String get localHistoryReasonBeforeDiscard => 'Antes de descartar';

  @override
  String get localHistoryReasonBeforeRestore => 'Antes da restauração';

  @override
  String get localHistoryReasonBeforeDelete => 'Antes da exclusão';

  @override
  String get localHistoryReasonExternalChange => 'Mudança externa';

  @override
  String get settingsHistory => 'Histórico';

  @override
  String get settingsClipboardHistoryTitle =>
      'Coletar Histórico da Área de Transferência';

  @override
  String get settingsClipboardHistoryDescription =>
      'Manter o conteúdo copiado e colado com sucesso apenas para esta sessão BusyMark.';

  @override
  String get settingsLocalHistoryTitle => 'Gravar Histórico Local';

  @override
  String get settingsLocalHistoryDescription =>
      'Armazenar revisões do documento neste dispositivo para recuperação e comparação.';

  @override
  String get settingsHistoryCheckpoint => 'Intervalo de checkpoint automático';

  @override
  String get settingsHistoryRetention => 'Tempo de retenção';

  @override
  String get settingsHistoryStorage => 'Armazenamento máximo';

  @override
  String get settingsHistoryExcludedPaths => 'Caminhos excluídos';

  @override
  String get settingsHistoryExcludedPathsHint =>
      'Um caminho absoluto por linha';

  @override
  String settingsSecondsValue(int value) {
    return '$value segundos';
  }

  @override
  String settingsDaysValue(int value) {
    return '$value dias';
  }

  @override
  String settingsMebibytesValue(int value) {
    return '$value MiB';
  }

  @override
  String get spelling => 'Ortografia';

  @override
  String get automaticSpelling => 'Verificação ortográfica automática';

  @override
  String get defaultSpellingLanguage => 'Idioma ortográfico padrão';

  @override
  String get projectSpellingLanguage =>
      'Idioma de verificação ortográfica do projeto';

  @override
  String get chooseSpellingLanguage => 'Escolher idioma ortográfico';

  @override
  String get spellingLanguageUnsetStatus => 'Idioma…';

  @override
  String get spellingOffStatus => 'Ortografia desativada';

  @override
  String get checkSpelling => 'Verificar ortografia';

  @override
  String get ignoreSpellingOnce => 'Ignorar uma vez';

  @override
  String get ignoreSpellingDocument => 'Ignorar tudo neste documento';

  @override
  String get addPersonalSpellingWord => 'Adicionar ao dicionário pessoal';

  @override
  String get addProjectSpellingWord => 'Adicionar ao dicionário do projeto';

  @override
  String get inheritSpellingLanguage =>
      'Usar o idioma do projeto ou do aplicativo';

  @override
  String get disableDocumentSpelling => 'Não verificar a ortografia';

  @override
  String get importSpellingDictionary => 'Importar dicionário';

  @override
  String get personalSpellingDictionary => 'Dicionário pessoal';

  @override
  String get projectSpellingDictionary => 'Dicionário do projeto';

  @override
  String get noSpellingErrors => 'Nenhum erro ortográfico';

  @override
  String get noSpellingSuggestions => 'Nenhuma sugestão ortográfica';

  @override
  String get spellingWordCheckFailed =>
      'Não foi possível verificar esta palavra';

  @override
  String get spellingCheckFailed => 'A verificação ortográfica falhou';

  @override
  String get spellingSettingsLoadFailed =>
      'Não foi possível carregar as configurações de verificação ortográfica';

  @override
  String get retrySpellingSettings =>
      'Tentar carregar novamente as configurações de verificação ortográfica';

  @override
  String get spellingCheckIncomplete =>
      'A verificação ortográfica está incompleta';

  @override
  String get spellingDictionaryNotInstalled => 'Dicionário não instalado';

  @override
  String spellingDictionaryNotInstalledForLanguage(String dictionary) {
    return 'O dicionário de $dictionary não está instalado';
  }

  @override
  String spellingDictionaryNotInstalledWithSize(String size) {
    return 'Não instalado · $size';
  }

  @override
  String get spellingDictionaryInstalled => 'Instalado';

  @override
  String get installSpellingDictionary => 'Instalar dicionário';

  @override
  String get removeSpellingDictionary => 'Remover dicionário';

  @override
  String get cancelSpellingDictionaryInstall =>
      'Cancelar download do dicionário';

  @override
  String get retrySpellingDictionaryInstall =>
      'Tentar instalar o dicionário novamente';

  @override
  String spellingDictionaryDownloading(String size) {
    return 'Baixando $size…';
  }

  @override
  String get spellingDictionaryValidating => 'Validando dicionário…';

  @override
  String get spellingDictionaryInstallFailed =>
      'Falha na instalação — selecione para tentar novamente';

  @override
  String spellingDictionaryInstallPrompt(String dictionary, String size) {
    return 'Instalar $dictionary ($size)? Depois de instalado, ficará disponível offline até ser removido.';
  }

  @override
  String get spellingDictionaryUnavailable => 'Dicionário indisponível';

  @override
  String get spellingChecking => 'Verificando a ortografia…';

  @override
  String exportInvalidRange(String field, String minimum, String maximum) {
    return '$field: insira um número entre $minimum e $maximum.';
  }

  @override
  String get spellingDictionaryRecoveryConflict =>
      'O dicionário ortográfico foi alterado externamente. Uma cópia de recuperação foi preservada.';

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
  String get nextcloudReconnect => 'Reconectar';

  @override
  String get nextcloudDisconnect => 'Desconectar';

  @override
  String get nextcloudServer => 'URL do servidor';

  @override
  String get nextcloudSignInBrowser => 'Conclua o login no navegador.';

  @override
  String get nextcloudFavorites => 'Favoritos';

  @override
  String get nextcloudNewNote => 'Nova nota';

  @override
  String get nextcloudSavedLocally =>
      'Salvo localmente · sincronização pendente';

  @override
  String get nextcloudSyncing => 'Sincronizando';

  @override
  String get nextcloudSynced => 'Sincronizado';

  @override
  String get nextcloudOffline => 'Sem conexão';

  @override
  String get nextcloudLocked => 'Bloqueado pelo servidor';

  @override
  String get nextcloudReconnectRequired => 'Reconexão necessária';

  @override
  String get nextcloudCreationUncertain => 'Resultado da criação incerto';

  @override
  String get nextcloudReadOnly => 'Somente leitura';

  @override
  String get nextcloudTakeRemote => 'Usar versão remota';

  @override
  String get nextcloudMerge => 'Mesclar';

  @override
  String get nextcloudDeleteNote => 'Excluir nota?';

  @override
  String get nextcloudWorkspaceReplaceUnavailable =>
      'A substituição no espaço de trabalho está indisponível para Nextcloud Notes. Substitua em cada nota.';

  @override
  String get nextcloudSaveLocalCopy => 'Salvar cópia local…';

  @override
  String get nextcloudDisconnectWarning =>
      'Remover esta conta exclui notas em cache e alterações pendentes deste dispositivo. Sincronize primeiro para conservar o trabalho no servidor.';

  @override
  String get nextcloudAttachmentRetryWarning =>
      'Se o envio anterior foi concluído, tentar novamente pode deixar um anexo não utilizado no servidor.';

  @override
  String get nextcloudAttachmentReference => 'Referência do anexo no servidor';

  @override
  String get nextcloudAddAttachment => 'Adicionar anexo…';

  @override
  String get nextcloudDeleteAttachmentWarning =>
      'Excluir este anexo torna seus links na nota indisponíveis. Os dados preservados podem ser recuperados pelo histórico local.';

  @override
  String get nextcloudChooseConflictingAttributes =>
      'Escolha cada atributo em conflito.';

  @override
  String get nextcloudUseServerNote => 'Usar esta nota do servidor';

  @override
  String get nextcloudUseServerNoteExplanation =>
      'Vincula este rascunho à nota selecionada no servidor e depois sincroniza as alterações locais preservadas. Uma solicitação correspondente não confirma quem criou a nota.';

  @override
  String get nextcloudExactCandidate =>
      'Correspondência exata com a solicitação; identidade não confirmada.';

  @override
  String get nextcloudPossibleCandidate =>
      'Possível correspondência após normalização; identidade não confirmada.';

  @override
  String get nextcloudSelectCandidate =>
      'Selecionar uma nota do servidor para revisar';

  @override
  String get nextcloudCreateSeparate => 'Criar uma nota separada';

  @override
  String get nextcloudCreateSeparateWarning =>
      'A primeira solicitação pode já ter criado uma nota no servidor. Isso cria uma nota separada com o trabalho local preservado. Nenhuma possível duplicata será excluída.';

  @override
  String get wsSemanticFormats => 'Formatação semântica';

  @override
  String get wsUiControl => 'Controle da interface';

  @override
  String get wsFilePath => 'Arquivo / Caminho';

  @override
  String get wsUiPath => 'Caminho da interface';

  @override
  String get wsDefinitionList => 'Lista de definições';

  @override
  String get wsIncludeContent => 'Incluir conteúdo reutilizável';

  @override
  String get wsVariableReference => 'Referência de variável';

  @override
  String get wsConvertList => 'Converter lista em procedimento';

  @override
  String get wsElementProperties => 'Propriedades do elemento';

  @override
  String get wsTopicProperties => 'Propriedades do tópico';

  @override
  String get wsCollapsible => 'Recolhível';

  @override
  String get wsPublishedState => 'Estado inicial publicado';

  @override
  String get wsExpanded => 'Expandido';

  @override
  String get wsCollapsed => 'Recolhido';

  @override
  String get wsCollapsedTitle => 'Título recolhido';

  @override
  String get wsTerm => 'Termo';

  @override
  String get wsListLayout => 'Disposição da lista';

  @override
  String get wsSyncGroup => 'Grupo de sincronização';

  @override
  String get wsTabKey => 'Chave do aba';

  @override
  String get wsSwitcherLabel => 'Etiqueta do seletor';

  @override
  String get wsNavigationElements => 'Elementos de navegação';

  @override
  String get wsNavigationDepth => 'Profundidade de navegação';

  @override
  String get wsAddItem => 'Adicionar item';

  @override
  String get wsStep => 'Passo';

  @override
  String get wsPropertyInvalid => 'Valor de propriedade inválido';

  @override
  String get wsFilter => 'Filtro';

  @override
  String get wsIdentifier => 'ID do elemento';

  @override
  String get wsTldr => 'Resumo (TLDR)';

  @override
  String get wsFullLayout => 'Largura total';

  @override
  String get wsMediumLayout => 'Médio (1:2)';

  @override
  String get wsNarrowLayout => 'Coluna de termo estreita';

  @override
  String get wsTitle => 'Título';

  @override
  String get wsSwitcherKey => 'Chave do seletor';

  @override
  String get nextcloudServerSettings => 'Configurações de Notes do servidor';

  @override
  String get nextcloudNotesPath => 'Caminho da pasta de notas';

  @override
  String get nextcloudFileSuffix => 'Extensão de novas notas';

  @override
  String get nextcloudServerSettingsExplanation =>
      'Estas configurações de Notes afetam outros clientes. Alterar o caminho não move arquivos; alterar a extensão não renomeia notas existentes.';

  @override
  String get nextcloudSettingsSaved => 'Configurações do servidor salvas';

  @override
  String get nextcloudSettingsNormalized =>
      'Salvo com valores normalizados pelo servidor';

  @override
  String get nextcloudPendingUpload => 'Envio de anexo pendente';

  @override
  String nextcloudServerCheck(String time) {
    return 'Última verificação do servidor: $time';
  }

  @override
  String get nextcloudSettingsLoading => 'Carregando configurações do servidor';

  @override
  String get nextcloudSettingsSaving => 'Salvando configurações do servidor';

  @override
  String get nextcloudPreviousLocalEdit => 'Edição local anterior';

  @override
  String get nextcloudUsePreviousEdit => 'Usar edição anterior';

  @override
  String get quickOpen => 'Abertura rápida';

  @override
  String get notesAll => 'Todas as notas';

  @override
  String get notesUncategorized => 'Sem categoria';

  @override
  String get notesRecovery => 'Recuperação';

  @override
  String get notesRecentlyEdited => 'Editadas recentemente';

  @override
  String get notesOldestEdited => 'Edições mais antigas';

  @override
  String get notesTitleAscending => 'Título A–Z';

  @override
  String get notesTitleDescending => 'Título Z–A';

  @override
  String get notesMove => 'Mover para categoria';

  @override
  String get notesRemoveFavorite => 'Remover favorito';

  @override
  String get notesOffline => 'Disponibilizar offline';

  @override
  String get notesOfflineRemove => 'Remover retenção offline';

  @override
  String get notesIndexing => 'Indexando notas…';

  @override
  String get notesSearchHelp =>
      'Os termos usam E. Use \"frases entre aspas\", title: e category:.';

  @override
  String get notesSourceLocation => 'Localização no código fonte';

  @override
  String get notesRecoveryHelp =>
      'Apenas notas locais retidas e histórico local. O lixo e o histórico do servidor não estão disponíveis.';

  @override
  String get notesImport => 'Importar notas';

  @override
  String get notesExport => 'Exportar notas';

  @override
  String get notesImportDistinct => 'Importar como nota distinta';

  @override
  String get notesAvailableOffline => 'Disponível offline';

  @override
  String get notesIncomplete => 'Incompleto';

  @override
  String get notesSelected => 'Notas selecionadas';

  @override
  String get notesNoHistory =>
      'Não há revisões retidas. O histórico pode estar desativado, expirado ou apagado.';

  @override
  String get notesTextAvailable => 'Texto disponível localmente';

  @override
  String get notesLocalVersion => 'Versão de trabalho local';

  @override
  String get notesAttachments => 'Anexos';

  @override
  String get notesSkipped => 'Ignorado';

  @override
  String get notesFailed => 'Falhou';

  @override
  String get notesCompleted => 'Concluído';

  @override
  String get notesImportNew => 'Iniciar nova importação';

  @override
  String get notesImportResume => 'Retomar importação interrompida';

  @override
  String get notesImportAlreadyImported => 'Já importado nesta operação';

  @override
  String get references => 'Referências';

  @override
  String get referenceIncoming => 'Recebidas';

  @override
  String get referenceOutgoing => 'Enviadas';

  @override
  String get referenceChooseTarget => 'Escolher destino do link';

  @override
  String get referenceWholeDocument => 'Documento completo';

  @override
  String get referenceSourceLocation => 'Local de origem';

  @override
  String get referenceTargetLocation => 'Local de destino';

  @override
  String get referenceResolved => 'Resolvida';

  @override
  String get referenceMissing => 'Ausente';

  @override
  String get referenceAmbiguous => 'Ambígua';

  @override
  String get referenceUnavailable => 'Indisponível neste contexto';

  @override
  String get referenceUnsupported => 'Não compatível';

  @override
  String get referenceNoPortableId =>
      'Este destino não tem uma URL portátil de nota verificada.';

  @override
  String get wsIncludeLines => 'Incluir linhas';

  @override
  String get wsIncludeSymbol => 'Incluir símbolo';

  @override
  String get wsEmphasizeLines => 'Realçar linhas exibidas';

  @override
  String get wsPropertiesReadOnly =>
      'Propriedades somente leitura nesta visualização.';

  @override
  String get wsPropertiesProtected => 'Elemento protegido. Edite sua fonte.';

  @override
  String get wsPropertiesConflict =>
      'Documento ou elemento alterado. Reverta o rascunho e selecione novamente.';

  @override
  String get wsPropertiesUnresolved =>
      'Não é possível resolver a referência no momento.';

  @override
  String get wsUseDefault => 'Usar padrão';

  @override
  String get wsPropertiesSelection => 'Selecione um único elemento.';

  @override
  String get wsImageDisplay => 'Exibição de imagem';

  @override
  String get wsImageThumbnail => 'Miniatura clicável';

  @override
  String get wsEnabled => 'Ativado';

  @override
  String get wsDisabled => 'Desativado';

  @override
  String get wsWidth => 'Largura';

  @override
  String get wsHeight => 'Altura';

  @override
  String get wsPropertiesInactive =>
      'Esta propriedade não tem efeito sem recolhimento publicado.';

  @override
  String get wsNavigationAll => 'Todos os elementos com título';

  @override
  String get wsNavigationNone => 'Sem navegação';

  @override
  String get wsNavigationCustom => 'Navegação personalizada';

  @override
  String get wsTitleOverride => 'Substituir título';

  @override
  String get wsCompactLayout => 'Compacto';

  @override
  String get wsWideLayout => 'Largo';

  @override
  String get wsCodeSourceConflict =>
      'Mova ou remova o código escrito neste bloco antes de definir src. O Writerside rejeita um bloco de código não vazio com uma referência de origem.';

  @override
  String get wsInherited => 'Herdar da lista';

  @override
  String get wsExternalImageSize =>
      'Writerside não dimensiona imagens externas de forma confiável. As dimensões existentes podem ser consultadas e removidas.';

  @override
  String get wsPropertiesNotSerialized =>
      'Esta alteração não foi aplicada ao código fonte. O rascunho foi mantido.';

  @override
  String get wsListItem => 'Item da lista';

  @override
  String get wsSourceFile => 'Arquivo de origem';

  @override
  String get wsLinkTarget => 'Destino do link';

  @override
  String get wsPreviewImage => 'Imagem de prévia';

  @override
  String get wsIncludedElement => 'Elemento incluído';

  @override
  String get wsHelpModule => 'Módulo de ajuda';

  @override
  String get wsActionId => 'ID da ação';

  @override
  String get wsKeymapHelpInstance => 'Instância de ajuda do mapa de teclas';

  @override
  String get wsShowInSource => 'Mostrar no Fonte';

  @override
  String get wsOriginElement => 'Valor do elemento';

  @override
  String get wsOriginAncestor => 'Elemento pai';

  @override
  String get wsOriginModule => 'Padrão do módulo';

  @override
  String get wsOriginBuiltIn => 'Padrão integrado';

  @override
  String get wsOriginUnresolved => 'Não resolvido';

  @override
  String wsEffectiveProperty(String value, String origin) {
    return 'Efetivo: $value — $origin';
  }

  @override
  String get wsElementSelector => 'Elemento';

  @override
  String wsGeneratedAnchorValue(String anchor) {
    return 'Gerado: $anchor';
  }

  @override
  String wsDefaultProperty(String value) {
    return 'Padrão: $value';
  }

  @override
  String wsDefaultPropertyOrigin(String value, String origin) {
    return 'Padrão: $value · $origin';
  }

  @override
  String wsResolvedProperty(String value) {
    return 'Resolvido: $value';
  }

  @override
  String get wsPropertyUnresolved => 'Não resolvido';

  @override
  String get wsModule => 'Módulo';

  @override
  String get wsParent => 'Elemento pai';

  @override
  String get wsListType => 'Tipo de lista';

  @override
  String get wsStartingNumber => 'Número inicial';

  @override
  String get wsListSorting => 'Ordenação';

  @override
  String get wsLetteredList => 'Lista alfabética';

  @override
  String get wsCheckboxList => 'Lista de caixas de seleção';

  @override
  String get wsMarkerlessList => 'Lista sem marcadores';

  @override
  String get wsAscending => 'Crescente';

  @override
  String get wsDescending => 'Decrescente';

  @override
  String get wsNoSorting => 'Sem ordenação';

  @override
  String get wsAsWritten => 'Como escrito';

  @override
  String get wsSentenceCase => 'Maiúscula inicial';

  @override
  String get wsTitleCase => 'Maiúsculas de título';

  @override
  String get wsLowerCase => 'Minúsculas';

  @override
  String get wsUpperCase => 'Maiúsculas';

  @override
  String get wsNativeMarkers => 'Marcadores Markdown';

  @override
  String wsListMarkerStart(String number) {
    return 'Marcador inicial: $number';
  }

  @override
  String wsListLevel(String level) {
    return 'Nível $level';
  }

  @override
  String get wsModuleCapsIgnored =>
      'O compilador fixado ignora as regras <caps> do módulo. Use um atributo caps local ou default-property.';

  @override
  String get wsInsertElements => 'Inserir elementos';

  @override
  String get wsAdmonitionsAndQuotes => 'Avisos e citações';

  @override
  String get wsSemanticText => 'Texto semântico';

  @override
  String get wsPropertiesUnavailable =>
      'O elemento inspecionado está indisponível. Inspecione um elemento para continuar.';

  @override
  String get searchDocumentsCategory => 'Documentos';

  @override
  String get searchTopicsCategory => 'Tópicos';

  @override
  String get searchCurrentDocument => 'Documento atual';

  @override
  String get searchCurrentWorkspace => 'Área de trabalho atual';

  @override
  String get browseNotes => 'Explorar notas';

  @override
  String get searchActionsCommand => 'Pesquisar ações';

  @override
  String get searchDocumentsCommand => 'Pesquisar documentos';

  @override
  String get searchTopicsCommand => 'Pesquisar tópicos';

  @override
  String get searchRecentCommand => 'Pesquisar recentes';

  @override
  String get searchResourceUnavailable => 'Este recurso não está disponível.';

  @override
  String get notesSync => 'Sincronizar notas';

  @override
  String get searchInWorkspace => 'Pesquisar no espaço de trabalho';

  @override
  String get searchCategory => 'Categoria de pesquisa';

  @override
  String get clearHistorySearchScope => 'Pesquisar no histórico de documentos';

  @override
  String get searchInDocument => 'Pesquisar no documento';

  @override
  String get searchDocumentHint => 'Pesquisar neste documento…';

  @override
  String get searchWorkspaceHint => 'Pesquisar neste espaço de trabalho…';

  @override
  String get searchOutlineHint => 'Pesquisar títulos…';

  @override
  String get searchHistoryHint => 'Pesquisar no histórico local…';

  @override
  String get searchEnterText => 'Digite texto para pesquisar';

  @override
  String get searchAccountUnavailable => 'Conta indisponível';

  @override
  String get searchDocumentsHint => 'Pesquisar documentos…';

  @override
  String get searchTopicsHint => 'Pesquisar tópicos…';

  @override
  String get searchRecentHint => 'Pesquisar recentes…';

  @override
  String get searchActionsHint => 'Pesquisar ações…';

  @override
  String get searchRequiresNotesWorkspace =>
      'Requer um espaço de trabalho de Notas';

  @override
  String get searchSidebarLabel => 'Pesquisar:';

  @override
  String get searchDocumentTextCategory => 'Texto do documento';

  @override
  String get searchWorkspaceTextCategory => 'Texto do espaço de trabalho';

  @override
  String get searchHeadingsCategory => 'Títulos';

  @override
  String get shortcutUnassigned => 'Não atribuído';

  @override
  String get shortcutPressKeys => 'Pressione uma combinação de teclas…';

  @override
  String get shortcutRecord => 'Capturar atalho';

  @override
  String get shortcutRestoreAll => 'Restaurar todos os padrões';

  @override
  String get shortcutRestoreAllQuestion =>
      'Restaurar os atalhos padrão de todas as ações? As atribuições personalizadas serão removidas.';

  @override
  String get shortcutSaveFailed =>
      'Os atalhos estão ativos, mas não foram salvos. Tente novamente para mantê-los após reiniciar.';

  @override
  String get shortcutRetry => 'Tentar salvar novamente';

  @override
  String get shortcutChanged =>
      'As atribuições mudaram. Confira os atalhos atuais e tente novamente.';

  @override
  String get shortcutInvalid =>
      'Esta combinação não pode ser atribuída neste contexto.';

  @override
  String get shortcutSystemWarning =>
      'O ambiente de trabalho pode usar esta combinação. O BusyMark não pode substituir atalhos do sistema.';

  @override
  String get shortcutConflicts =>
      'Este atalho entra em conflito com estas ações:';

  @override
  String get shortcutRemove => 'Remover atribuição';

  @override
  String get shortcutRestoreDefault => 'Restaurar padrão';

  @override
  String get shortcutAssign => 'Atribuir';

  @override
  String get shortcutReassign => 'Reatribuir';

  @override
  String get shortcutContextApplication => 'Aplicativo';

  @override
  String get shortcutContextDocument => 'Visualizações do documento';

  @override
  String get shortcutContextEditor => 'Editor e código-fonte';

  @override
  String get shortcutContextWritersideSource => 'Código-fonte do Writerside';

  @override
  String get shortcutContextWorkspace => 'Navegação do espaço de trabalho';

  @override
  String get shortcutContextTree => 'Árvores laterais';

  @override
  String get searchHeadingsCommand => 'Pesquisar títulos';

  @override
  String get shortcutFixed => 'Gerenciado pelo editor; não é configurável.';

  @override
  String get shortcutDefaultConflict =>
      'O atalho padrão está em conflito com uma atribuição personalizada.';

  @override
  String get shortcutCurrentBinding => 'Atalho atual';

  @override
  String get shortcutProposedBinding => 'Atalho proposto';

  @override
  String get notesActions => 'Ações das notas';

  @override
  String get noteActions => 'Ações da nota';

  @override
  String get noteProperties => 'Propriedades da nota';

  @override
  String get notesExportAll => 'Exportar notas · Todas as notas…';

  @override
  String get notesExportCategory => 'Exportar notas · Categoria…';

  @override
  String get notesOfflineAll => 'Disponibilizar offline · Todas as notas';

  @override
  String get notesOfflineCategory => 'Disponibilizar offline · Categoria';

  @override
  String get notesOfflineRemoveAll =>
      'Remover retenção offline · Todas as notas';

  @override
  String get notesOfflineRemoveCategory =>
      'Remover retenção offline · Categoria';

  @override
  String get notesOfflinePause => 'Pausar downloads';

  @override
  String get notesOfflineResume => 'Retomar downloads';

  @override
  String get notesOfflineKeep => 'Disponibilizar offline';

  @override
  String get notesOfflineRetentionHelp =>
      'Remover este requisito mantém o conteúdo em cache. Um requisito da categoria ou da conta pode continuar retendo a nota.';

  @override
  String get notesOfflineBroader =>
      'Esta nota também é retida por um requisito da categoria ou da conta.';

  @override
  String get notesOfflineExternal =>
      'Mídia externa exige conexão. O BusyMark mantém apenas texto e anexos gerenciados.';

  @override
  String get notesEmptyAll => 'Ainda não há notas. Crie uma para começar.';

  @override
  String get notesEmptyFavorites => 'Não há notas favoritas.';

  @override
  String get notesEmptyCategory => 'Não há notas nesta categoria.';

  @override
  String get notesEmptyUncategorized => 'Não há notas sem categoria.';

  @override
  String get notesEmptyRecovery => 'Não há notas retidas para recuperar.';

  @override
  String get notesLoadFailed => 'Nextcloud Notes · Falhou. Tentar novamente';

  @override
  String get notesOperationFailed =>
      'Não foi possível concluir a operação. Seu rascunho foi mantido. Revise o salvamento e os conflitos e tente novamente.';

  @override
  String get notesInspectionFailed => 'Anexos · Falhou. Tentar novamente';

  @override
  String get notesStartingConnection => 'Iniciando conexão com o Nextcloud…';

  @override
  String get notesVerifyingConnection => 'Verificando o acesso às notas…';

  @override
  String get notesCancellingConnection => 'Cancelando a entrada e limpando…';

  @override
  String get notesRemovingConnection => 'Removendo a conta local…';

  @override
  String get notesRemovedWarning =>
      'A conta local do Nextcloud foi removida. A revogação da senha de aplicativo não foi confirmada. Remova a senha do BusyMark nas configurações de segurança do Nextcloud.';

  @override
  String get notesBuffersNotSaved =>
      'Não foi possível salvar todas as notas abertas localmente. Revise o salvamento, os conflitos ou a normalização na área de trabalho. As alterações locais ainda podem precisar de sincronização com o Nextcloud.';

  @override
  String get notesSettingsLeave =>
      'Salvar alterações nas configurações do Nextcloud antes de sair?';

  @override
  String get notesSettingsLeaveHelp =>
      'Configurações de Notes do servidor · Alterações não salvas';

  @override
  String get notesSettingsReload => 'Recarregar configurações do servidor…';

  @override
  String get notesSettingsReloadHelp =>
      'Recarregar substitui o rascunho pelas configurações atuais do Nextcloud. Descartar o rascunho e recarregar?';

  @override
  String get notesSettingsRefreshFailed =>
      'O Nextcloud aceitou as configurações, mas a atualização das notas falhou. Os valores exibidos foram confirmados pelo servidor. Tente atualizar novamente pelas Notas.';

  @override
  String get notesUnavailable =>
      'Sem conexão · Texto disponível localmente · Salvo localmente · sincronização pendente';

  @override
  String get notesStorageFull =>
      'O armazenamento do Nextcloud está cheio. Libere espaço no servidor e tente novamente.';

  @override
  String get notesRejected =>
      'O Nextcloud rejeitou esta alteração. Revise a nota e salve uma cópia local antes de tentar novamente.';

  @override
  String get notesThrottled =>
      'O Nextcloud pediu para aguardar. A sincronização será retomada após o prazo de espera.';

  @override
  String get notesRecoveryRequired => 'Conflitos · Comparar';

  @override
  String get notesScanning => 'Verificando arquivos…';

  @override
  String get notesCancelling =>
      'Cancelando… Aguardando a conclusão da operação atual.';

  @override
  String get notesCancelled => 'Cancelado';

  @override
  String get notesPartial => 'Parcialmente concluído';

  @override
  String get notesTransferFailed => 'Falhou. Tentar novamente';

  @override
  String get notesImportPartialHelp =>
      'Itens anteriores podem já estar salvos localmente. Retome esta importação para continuar sem duplicá-los.';

  @override
  String get notesNotStarted => 'Não iniciado';

  @override
  String get notesCreated => 'Criado';

  @override
  String get notesRemoteDeleteUnavailable =>
      'URL do servidor · Não compatível · Excluir · Anexos';

  @override
  String get notesCurrentText => 'Texto retido atualmente';

  @override
  String get notesRecovering => 'Recuperando como nova nota…';

  @override
  String get notesReadOnlyHelp =>
      'Somente leitura · Favoritos · Salvar cópia local…';

  @override
  String get notesSort => 'Ordenar notas';

  @override
  String get notesPathRelative =>
      'O caminho da pasta de notas é relativo ao seu armazenamento Nextcloud.';

  @override
  String get notesSettingsStale =>
      'As configurações mudaram no Nextcloud. Recarregue e revise os valores do servidor antes de substituir o rascunho.';

  @override
  String get notesDownloadsPaused => 'Downloads pausados';

  @override
  String get notesExportNotPublished => 'Nenhuma exportação foi publicada.';

  @override
  String get notesKeyringUnavailable =>
      'Desbloqueie o chaveiro da área de trabalho e tente novamente.';

  @override
  String get notesConnectFailed =>
      'Não foi possível conectar ao Nextcloud Notes. Verifique o endereço do servidor e tente novamente.';

  @override
  String get notesAccountMismatch =>
      'Entre na mesma conta Nextcloud. Remova esta conta primeiro para conectar outra.';

  @override
  String get notesLocalRemovalFailed =>
      'A limpeza local da conta falhou. A conta foi mantida para que você possa tentar removê-la novamente.';

  @override
  String get notesTransferring => 'Transferindo notas…';

  @override
  String get notesTechnicalDetails => 'Detalhes técnicos';

  @override
  String get notesPauseRequirement => 'Pausar requisito offline';

  @override
  String get notesResumeRequirement => 'Retomar requisito offline';

  @override
  String get gitReturnToDocument => 'Voltar ao documento';

  @override
  String gitSnapshotLabel(String revision, String path) {
    return 'Instantâneo somente leitura · $revision · $path';
  }

  @override
  String get gitNonUtf8FilenameMessage =>
      'Este nome de arquivo contém bytes que não são UTF-8. A revisão e a preparação Git continuam disponíveis; o editor requer um nome de arquivo UTF-8.';

  @override
  String get gitUiMergeInProgress => 'A fusão está em curso';

  @override
  String get gitUiRebaseInProgress => 'Rebase em curso';

  @override
  String get gitUiCherryPickInProgress => 'Pilha de cereja em andamento';

  @override
  String get gitUiRevertInProgress => 'Reverter em curso';

  @override
  String get gitUiPatchApplicationInProgress =>
      'Aplicação de parâmetros em curso';

  @override
  String get gitUiSquashMergeResultAwaitingCommit =>
      'Resultado da fusão de Squash à espera de commit';

  @override
  String get gitUiUnresolvedIndexConflicts =>
      'Conflitos de índices não resolvidos';

  @override
  String get gitUiUnresolvedConflicts => ' · conflitos não resolvidos';

  @override
  String get gitUiReviewOperation => 'Operação de revisão';

  @override
  String get gitUiRefresh => 'Atualizar';

  @override
  String get gitUiCreateNamedStash => 'Criar um esconderijo nomeado';

  @override
  String get gitUiCreateStash => 'Criar stash…';

  @override
  String get gitUiNoStashes => 'Sem esconderijos';

  @override
  String get gitUiSelectAStashToInspectItsChanges =>
      'Selecione um estoque para inspecionar as suas alterações';

  @override
  String get gitUiStashedUntrackedFiles => 'Arquivos não rastreados';

  @override
  String get gitUiInspectStashedUntrackedFiles =>
      'Inspeccione os arquivos não localizados...';

  @override
  String get gitUiReinstateTheStashSStagedIndexStateWhenApplying =>
      'Reestabelecer o estado de estágio/índice do estoque ao aplicar';

  @override
  String get gitUiApplyAndRetain => 'Aplicar e manter';

  @override
  String get gitUiPop => 'Pai...';

  @override
  String get gitUiCreateBranch => 'Criar branch…';

  @override
  String get gitUiDropStash => 'Eliminar stash…';

  @override
  String get gitUiBranchFromStash => 'Criar branch a partir do stash';

  @override
  String get gitUiCreateSwitchToABranchAtTheStashSOriginal =>
      'Criar/conectar para um ramo na base original do estoque, depois aplicá-lo. O estoque original é retido para exclusão posterior explícita.';

  @override
  String gitUiArg0ThisStash(String arg0) {
    return '$arg0 este estoque?';
  }

  @override
  String get gitUiTheOriginalStashIsRetainedIfApplyingConflicts =>
      'O estoque original é mantido se aplicar conflitos.';

  @override
  String get gitUiDeletesThisStashEntryItsChangesAreNotApplied =>
      'Exclui esta entrada de reserva. As suas alterações não são aplicadas.';

  @override
  String get gitUiResolveTheUnmergedFilesGitHasNoStashContinueOr =>
      'Resolva os arquivos não mesclados. O Git não tem comandos para continuar ou abortar um stash; o stash original é preservado.';

  @override
  String get gitUiStashNameMessage => 'Nome/mensagem da vara';

  @override
  String get gitUiStashContentAndResultingIndex =>
      'Conteúdo de estacas e índice resultante';

  @override
  String get gitUiStashTrackedWorkingAndStagedChanges =>
      'Stash rastreou o trabalho e as mudanças encenadas';

  @override
  String get gitUiStashChangesLeaveStagedChangesInPlaceKeepIndex =>
      'Salvar alterações em stash mantendo as preparadas no local (--keep-index)';

  @override
  String get gitUiStashOnlyStagedChangesStaged =>
      'Salvar em stash apenas as alterações preparadas (--staged)';

  @override
  String get gitUiIncludeUntrackedFiles => 'Incluir arquivos não rastreados';

  @override
  String get gitUiAllEligiblePathsInThisRepository =>
      'Todos os caminhos elegíveis neste repositório';

  @override
  String get gitUiNoEligibleChangesForTheseStashOptions =>
      'Nenhuma alteração elegível para estas opções de estoque.';

  @override
  String get gitUiSelectAtLeastOneEligiblePath =>
      'Selecione pelo menos um caminho elegível.';

  @override
  String get gitUiCreateStash2 => 'Criar stash';

  @override
  String get gitUiCreateWorktree => 'Criar worktree...';

  @override
  String get gitUiCreateACommitBeforeCreatingAWorktreeAtHEAD =>
      'Crie um commit antes de criar uma árvore de trabalho em HEAD.';

  @override
  String get gitUiDetachedHEAD => 'HEAD destacado';

  @override
  String get gitUiCurrent => 'Corrente';

  @override
  String get gitUiLocked => 'Bloqueado';

  @override
  String get gitUiOpenInBusyStack => 'Abrir em Stack Ocupado ·';

  @override
  String get gitUiStatusNotInspected => 'Situação não inspeccionada';

  @override
  String get gitUiDirty => 'Sujo';

  @override
  String get gitUiClean => 'Limpo';

  @override
  String get gitUiOpenWorkingFolder => 'Abrir a pasta de trabalho';

  @override
  String get gitUiMoveWorktree => 'Mover o worktree...';

  @override
  String get gitUiUnlock => 'Desbloquear';

  @override
  String get gitUiLock => 'Fechar';

  @override
  String get gitUiRemoveCleanWorktree => 'Remover worktree limpo...';

  @override
  String get gitUiReviewRemovalIncludingLocalChanges =>
      'Revisar a remoção, incluindo alterações locais...';

  @override
  String get gitUiNewWorktreeFolderName => 'Nome da nova pasta Worktree';

  @override
  String get gitUiNewWorktreeBranch => 'Branco de árvore de trabalho nova';

  @override
  String gitUiCreateArg0Arg1WithANewLocalBranchAtArg2(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return 'Criar $arg0/$arg1 com uma nova filial local em $arg2 ($arg3).';
  }

  @override
  String get gitUiDestinationFolderName => 'Nome da pasta de destino';

  @override
  String get gitUiRemoveWorktree => 'Remover worktree?';

  @override
  String
  get gitUiExplicitlyDiscardAllLocalTrackedUntrackedChangesInThisWorktree =>
      'Descarte explicitamente todas as alterações localmente rastreadas/não rastreadas nesta árvore de trabalho. As árvores de trabalho bloqueadas/em uso permanecem protegidas.';

  @override
  String get gitUiGitRefusesRemovalIfThereAreLocalChangesUntrackedFiles =>
      'Git recusa remoção se houver alterações locais, arquivos não rastreados, ou um bloqueio.';

  @override
  String get gitUiDiscardLocalWorktreeContentsAndRemove =>
      'Descartar o conteúdo local da árvore de trabalho e remover';

  @override
  String get gitUiRemoveCleanWorktree2 => 'Remover a árvore de trabalho limpa';

  @override
  String
  get gitUiExplicitlyRecurseIntoNestedSubmodulesForUpdatesSynchronization =>
      'Recursar explicitamente em submódulos aninhados para atualizações/sincronização';

  @override
  String get gitUiNoRecordedSubmodules => 'Sem submódulos registados';

  @override
  String get gitUiNotInitialized => 'não inicializada';

  @override
  String gitUiParentGitlinkArg0CheckedOutArg1(String arg0, String arg1) {
    return 'Ligação de pais: $arg0 Data de saída: $arg1\n';
  }

  @override
  String get gitUiDirtyNestedRepository => 'Depósito aninhado sujo';

  @override
  String get gitUiCleanNestedRepository => 'Depósito ninhado limpo';

  @override
  String get gitUiNestedStatusUnavailable => 'Situação de nido indisponível';

  @override
  String get gitUiEnterNestedRepository => 'Digite o repositório aninhado';

  @override
  String get gitUiInitializeConfiguration => 'Iniciar a configuração';

  @override
  String get gitUiUpdateToParentSRecordedCommit =>
      'Atualização para o commit registado dos pais...';

  @override
  String get gitUiFollowConfiguredRemoteBranch =>
      'Siga o ramo remoto configurado...';

  @override
  String get gitUiSynchronizeConfiguredURLs =>
      'Sincronizar URLs configuradas...';

  @override
  String get gitUiStageCurrentSubmodulePointerInParent =>
      'Ponteiro do submódulo do estágio actual no pai';

  @override
  String get gitUiParentAndSubmoduleCommitsPushesAndDirtyStateRemainSeparate =>
      'O pai e o submódulo cometes, empurra e o estado sujo permanecem separados. A navegação não inicializa ou atualiza.';

  @override
  String gitUiFetchAndCheckOutTheConfiguredRemoteBranchSCommit(String arg0) {
    return 'Procurar e verificar o branch remoto configurado commit. Isto difere do gitlink registado do pai. Recursivo: $arg0.';
  }

  @override
  String gitUiInitializeAsNeededAndCheckOutExactlyArg0RecursiveArg1(
    String arg0,
    String arg1,
  ) {
    return 'Inicialize conforme necessário e confira exatamente $arg0. Recursiva: $arg1.';
  }

  @override
  String gitUiApplyTheReviewedSubmoduleConfigurationOperationRecursiveArg0(
    String arg0,
  ) {
    return 'Aplicar a operação de configuração do submódulo revisado. Recursivo: $arg0.';
  }

  @override
  String get gitUiApplySubmoduleOperation => 'Aplicar a operação do submódulo';

  @override
  String get gitUiInspectARecordedRevisionOrCreateARecoveryBranchReflog =>
      'Inspeccionar uma revisão gravada ou criar um ramo de recuperação. Reflog não recupera conteúdo arbitrário não salvo ou não rastreado.';

  @override
  String get gitUiSelectAReflogEntry => 'Selecione uma entrada de reflog';

  @override
  String get gitUiPreviousPage => 'Página anterior';

  @override
  String get gitUiNextPage => 'Próxima página';

  @override
  String get gitUiRecoveryBranchName => 'Nome do ramo de recuperação';

  @override
  String gitUiCreatesABranchAtArg0WorkingFilesAndTheCurrent(String arg0) {
    return 'Cria um branch em $arg0; os arquivos de trabalho e o branch atual estão inalterados.';
  }

  @override
  String get gitUiCreateRecoveryBranch => 'Criar ramo de recuperação...';

  @override
  String get gitUiReadOnlyRecoverySnapshot =>
      'instantâneo de recuperação de apenas leitura';

  @override
  String get gitUiInspectSnapshot => 'Inspeccionar instantâneo...';

  @override
  String get gitUiReviewReset => 'Revisar redefinição…';

  @override
  String gitUiPageArg0(String arg0) {
    return 'Página $arg0';
  }

  @override
  String get gitUiAGitTextHistoryMustOwnItsEditableField =>
      'Um histórico de texto Git deve possuir o seu campo editável.';

  @override
  String get gitUiEditHEADIndexWorkingTree =>
      'Editar HEAD | Índice | Árvore de trabalho…';

  @override
  String
  get gitUiTheReviewedIndexOrWorkingContentChangedRefreshThisComparison =>
      'O índice revisto ou o conteúdo de trabalho mudou. Actualize esta comparação antes do estadiamento.';

  @override
  String get gitUiRefreshComparison => 'Refrescar a comparação';

  @override
  String get gitUiPreviousChangedFile => 'Arquivo alterado anterior';

  @override
  String get gitUiNextChangedFile => 'Próximo arquivo alterado';

  @override
  String get gitUiPreviousDifference => 'Diferença anterior';

  @override
  String get gitUiNextDifference => 'Próxima diferença';

  @override
  String get gitUiComparisonMode => 'Modo de comparação';

  @override
  String get gitUiSideBySide => 'Lados a lado';

  @override
  String get gitUiUnified => 'Unificado';

  @override
  String get gitUiDiffDisplayOptions =>
      'Opções de exibição de diff@ info: whatsthis';

  @override
  String get gitUiWrap => 'Embrulho';

  @override
  String get gitUiWords => 'Palavras';

  @override
  String get gitUiCollapseContext => 'Recolher contexto';

  @override
  String get gitUiIgnoreWhitespace => 'Ignorar espaços brancos';

  @override
  String get gitUiSearchComparison => 'Comparação de pesquisas';

  @override
  String get gitUiSearch => 'Procurar';

  @override
  String get gitUiCloseSearch => 'Fechar pesquisa';

  @override
  String get gitUiStagingActions => 'Ações de preparação';

  @override
  String get gitUiStagingActions2 => 'Ações de preparação…';

  @override
  String get gitUiUnstageSelectedChangedLines =>
      'Retirar linhas alteradas selecionadas do índice';

  @override
  String get gitUiStageSelectedChangedLines =>
      'Preparar linhas alteradas selecionadas';

  @override
  String get gitUiUnstageWholeFile => 'Retirar arquivo completo do índice';

  @override
  String get gitUiStageWholeFile => 'Preparar arquivo completo';

  @override
  String gitUiArg0WhitespaceOnlyChangedLinesHiddenShowExactChanges(
    String arg0,
  ) {
    return '$arg0 apenas linhas mudadas de espaços brancos ocultas · Mostrar alterações exatas';
  }

  @override
  String gitUiArg0ChangedLinesSelectedDisplaySettingsNeverAlterTheStaged(
    String arg0,
  ) {
    return '$arg0 alteraram as linhas selecionadas · Configurações de exibição nunca alteram os bytes.';
  }

  @override
  String get gitUiReadOnlyComparisonCopyTextOrAdjustDisplaySettings =>
      'Comparação só de leitura · Copie texto ou ajuste a apresentação.';

  @override
  String get gitUiNoFinalNewline => ' · nenhuma nova linha final';

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
      'A comparação de texto não está disponível para estes conteúdos.';

  @override
  String get gitUiThisComparisonExceedsTheBoundedTextReviewLimitTheContents =>
      'Esta comparação excede o limite de revisão de texto limitado. O conteúdo não foi declarado idêntico.';

  @override
  String get gitUiTheComparedContentsAreIdentical =>
      'Os conteúdos comparados são idênticos.';

  @override
  String get gitUiUnstage => 'Não estágio';

  @override
  String get gitUiStage => 'Etapa';

  @override
  String gitUiArg0ChangedLine(String arg0) {
    return '$arg0 mudança de linha';
  }

  @override
  String get gitUiContext => 'Contexto';

  @override
  String get gitUiExpandUnchangedContext => 'Expandir o contexto inalterado';

  @override
  String get gitUiUnstageThisHunk => 'Retirar este bloco do índice';

  @override
  String get gitUiStageThisHunk => 'Preparar este bloco';

  @override
  String gitUiEditStagedContentArg0(String arg0) {
    return 'Editar conteúdo em fase · $arg0';
  }

  @override
  String get gitUiWritingReviewedIndexResult =>
      'Escrevendo o resultado do índice revisado';

  @override
  String get gitUiHead => 'HEAD';

  @override
  String get gitUiIndex => 'Índice';

  @override
  String get gitUiWorkingTree => 'Árvore de trabalho';

  @override
  String gitUiHeadArg0(String arg0) {
    return 'HEAD · $arg0';
  }

  @override
  String get gitUiIndexEditableUTF8Blob => 'Índice · blob UTF-8 editável';

  @override
  String get gitUiUndo => 'Desfazer';

  @override
  String get gitUiRedo => 'Refazer';

  @override
  String get gitUiReloadIndexReview => 'Revisão do índice de recarga?';

  @override
  String get gitUiReloadTheCurrentHEADIndexAndWorkingVersionsThisReplaces =>
      'Recarregue as versões atuais de HEAD, do índice e de trabalho. Isto substitui o rascunho não salvo no editor do índice.';

  @override
  String get gitUiReplaceDraftAndReload => 'Substituir o projecto e recarregar';

  @override
  String get gitUiReloadVersions => 'Recarregar as versões...';

  @override
  String get gitUiWriteEditedResultToThisIndexEntry =>
      'Escreva o resultado editado para esta entrada do índice';

  @override
  String get gitUiWorkingFilesRemainOnDiskReviewTheEditedIndexBefore =>
      'Os arquivos de trabalho permanecem no disco. Revise o índice editado antes de aplicar.';

  @override
  String get gitUiReviewIndexTextFormatChanges =>
      'Revisar as alterações no formato do texto do índice';

  @override
  String gitUiUpdateOnlyTheReviewedIndexEntryForArg0Arg1(
    String arg0,
    String arg1,
  ) {
    return 'Atualizar apenas a entrada do índice revisto para $arg0. $arg1';
  }

  @override
  String get gitUiWriteReviewedIndexResult =>
      'Escreva o resultado do índice revisado';

  @override
  String get gitUiTheEditedResultChangedDuringFormatReviewReviewItAgain =>
      'O resultado editado mudou durante a revisão de formato. Revise novamente.';

  @override
  String get gitUiSynchronizeScrolling => 'Sincronizar o desloque';

  @override
  String get gitUiReadOnlyRevisionContent =>
      'Conteúdo de revisão apenas para leitura';

  @override
  String get gitUiEditableIndexContent => 'Conteúdo do índice editável';

  @override
  String get gitUiTheRequestedRevisionIsOutsideTheCurrentFiltersResetFilters =>
      'A revisão solicitada está fora dos filtros atuais. Reinicie os filtros para revelá-los.';

  @override
  String get gitUiFilterLog => 'Registo de Filtros';

  @override
  String get gitUiFilters => 'Filtros...';

  @override
  String gitUiFiltersCount(String count) {
    return 'Filtros ($count)...';
  }

  @override
  String get gitUiMessage => 'Mensagem…';

  @override
  String get gitUiAuthor => 'Autor…';

  @override
  String get gitUiPath => 'Caminho...';

  @override
  String get gitUiDate => 'Data...';

  @override
  String get gitUiMessageFilter => 'Filtro de Mensagem';

  @override
  String get gitUiAuthorFilter => 'Filtro do autor';

  @override
  String get gitUiPathFilter => 'Filtro de localização';

  @override
  String get gitUiMessage2 => 'Mensagem';

  @override
  String get gitUiAuthor2 => 'Autor';

  @override
  String get gitUiPath2 => 'Caminho';

  @override
  String get gitUiDateFilter => 'Filtro de data...';

  @override
  String get gitUiResetFilters => 'Restaurar filtros';

  @override
  String get gitUiRefreshLog => 'Actualizar o Registo';

  @override
  String get gitUiGoToCommitReference => 'Ir para commit/reference...';

  @override
  String get gitUiBackToHEAD => 'Voltar a HEAD';

  @override
  String get gitUiOrderedCherryPick => 'Cherry-pick na ordem escolhida';

  @override
  String gitUiReviewCherryPickArg0(String arg0) {
    return 'Comentário de cereja-pick ($arg0)...';
  }

  @override
  String get gitUiCompareTwoSelectedRevisions =>
      'Comparar duas revisões seleccionadas...';

  @override
  String get gitUiToggleBranchesPane => 'Painel de galhos de comutação';

  @override
  String get gitUiFilterBranchesAndTags => 'Filtrar ramos e etiquetas';

  @override
  String gitUiCommitArg0(String arg0) {
    return 'Comissário $arg0';
  }

  @override
  String get gitUiCommitDetails => 'Compromete os detalhes...';

  @override
  String gitUiReferenceArg0(String arg0) {
    return 'Referência: $arg0';
  }

  @override
  String get gitUiSelectThisCommit => 'Selecionar este commit';

  @override
  String get gitUiBranchOrTag => 'Branco ou etiqueta';

  @override
  String get gitUiAllReferences => 'Todas as referências';

  @override
  String get gitUiLocal => 'Local';

  @override
  String get gitUiRemote => 'Remoto';

  @override
  String get gitUiTags => 'Tags';

  @override
  String get gitUiNoCommitsMatchTheCurrentFilters =>
      'Nenhum commit corresponde aos filtros atuais.';

  @override
  String get gitUiObjectID => 'Identificação do objeto';

  @override
  String get gitUiSubjectReferences => 'Assunto / referências';

  @override
  String get gitUiDate2 => 'Data';

  @override
  String get gitUiGitCommits => 'Commits do Git';

  @override
  String get gitUiParents => 'Commits pai';

  @override
  String gitUiArg0Parents(String arg0) {
    return '$arg0 pais';
  }

  @override
  String get gitUiLoadMoreCommits => 'Carregar mais commits';

  @override
  String get gitUiLoadingChangedFiles => 'Carregando arquivos alterados';

  @override
  String get gitUiNoChangedFiles => 'Nenhum arquivo alterado';

  @override
  String get gitUiSelectACommit => 'Selecione um commit';

  @override
  String gitUiCompareParentArg0Arg1(String arg0, String arg1) {
    return 'Comparar os pais $arg0: $arg1';
  }

  @override
  String get gitUiChangedFiles => 'Arquivos alterados';

  @override
  String gitUiAuthorArg0Arg1Arg2(String arg0, String arg1, String arg2) {
    return 'Autor: $arg0 <$arg1> $arg2';
  }

  @override
  String gitUiCommitterArg0Arg1Arg2(String arg0, String arg1, String arg2) {
    return 'Combustível: $arg0 <$arg1> $arg2';
  }

  @override
  String get gitUiShallowPartialBoundaryAParentObjectIsUnavailable =>
      'Limitação ligeira/partial: um objeto pai não está disponível.';

  @override
  String get gitUiParentIsOutsideThisPageOrAShallowBoundary =>
      'O pai está fora desta página ou um limite raso.';

  @override
  String gitUiParentArg0(String arg0) {
    return 'Commit pai $arg0';
  }

  @override
  String get gitUiCommitActions => 'Comete acções...';

  @override
  String get gitUiEmptyTree => 'árvore vazia';

  @override
  String get gitUiCreateBranch2 => 'Criar branch';

  @override
  String get gitUiCreateTag => 'Criar tag';

  @override
  String get gitUiCompareRevisions => 'Comparar as revisões';

  @override
  String get gitUiOpenSnapshot => 'Abrir a instantânea';

  @override
  String get gitUiRevertCommit => 'Reverter o commit';

  @override
  String get gitUiInteractiveRebaseAfterThisBoundary =>
      'Rebase interativo após este limite';

  @override
  String get gitUiResetCurrentBranch => 'Repor branch atual';

  @override
  String get gitUiCopyFullObjectID => 'Copie o ID completo do objeto';

  @override
  String get gitUiGoToCommitReference2 => 'Ir para commit/referência';

  @override
  String get gitUiEnterACommitIDOrReferenceToRevealInLog =>
      'Digite um ID de commit ou uma referência para revelar no Log.';

  @override
  String get gitUiTheRequestedRevisionIsUnavailable =>
      'A revisão solicitada não está disponível.';

  @override
  String
  get gitUiRepositoryMetadataIsReadOnlyBranchInspectionAndComparisonRemain =>
      'Os metadados do repositório são apenas de leitura. A inspeção e comparação da filial permanecem disponíveis.';

  @override
  String get gitUiWorkingFilesAreUnavailableOrReadOnlyBranchSwitchingAnd =>
      'Os arquivos de trabalho não estão disponíveis ou só de leitura. A mudança e a fusão de ramos não estão disponíveis.';

  @override
  String get gitUiSearchBranchesAndTags => 'Pesquisar branches e tags';

  @override
  String get gitUiNewBranch => 'Nova branch…';

  @override
  String get gitUiLocalBranches => 'Branches locais';

  @override
  String get gitUiRemoteBranches => 'Branches remotas';

  @override
  String gitUiTracksArg0(String arg0) {
    return 'Pistas $arg0';
  }

  @override
  String gitUiCheckedOutAtArg0(String arg0) {
    return 'Checked out em $arg0';
  }

  @override
  String get gitUiRefreshingBranchMetadata =>
      'Actualização dos metadados da filial';

  @override
  String gitUiSwitchToArg0(String arg0) {
    return 'Mudar para $arg0';
  }

  @override
  String get gitUiOpenOccupiedWorktree => 'Árvore aberta ocupada';

  @override
  String get gitUiCreateLocalTrackingBranch =>
      'Criar ramo local de rastreamento...';

  @override
  String get gitUiCompareToCurrentHEAD => 'Comparar com HEAD atual';

  @override
  String get gitUiMergeIntoCurrentBranch => 'Junta-te ao ramo actual...';

  @override
  String get gitUiRename => 'Renomear...';

  @override
  String get gitUiChangeUpstream => 'Mudar para cima...';

  @override
  String get gitUiDelete => 'Excluir...';

  @override
  String get gitUiDeleteFromRemote => 'Excluir do remoto...';

  @override
  String gitUiActionsForArg0(String arg0) {
    return 'Acções para $arg0';
  }

  @override
  String get gitUiLocalBranchName => 'Nome da filial local';

  @override
  String gitUiCreateAtArg0TheNewBranchWillBeCheckedOut(String arg0) {
    return 'Crie em $arg0. O novo ramo será verificado.';
  }

  @override
  String gitUiTheLocalBranchWillTrackArg0AndBeCheckedOut(String arg0) {
    return 'O ramo local irá rastrear $arg0 e ser verificado.';
  }

  @override
  String get gitUiChooseRemoteForDeletion =>
      'Escolher o remoto para a exclusão';

  @override
  String get gitUiDeleteRemoteReference => 'Excluir a referência remota';

  @override
  String gitUiMergeArg0IntoArg1(String arg0, String arg1) {
    return 'Fusionar $arg0 em $arg1';
  }

  @override
  String gitUiRenameArg0(String arg0) {
    return 'Renomear-se-á $arg0';
  }

  @override
  String gitUiUpstreamForArg0(String arg0) {
    return 'Ascendente para $arg0';
  }

  @override
  String get gitUiNoUpstream => 'Sem upstream';

  @override
  String gitUiDeleteArg0(String arg0) {
    return 'Excluir $arg0?';
  }

  @override
  String gitUiArg0TargetArg1LocalDeletionOnlyAnUnmergedBranchIs(
    String arg0,
    String arg1,
  ) {
    return '$arg0 Alvo $arg1 Exclusão local apenas. Um ramo não fundido é recusado.';
  }

  @override
  String get gitUiDelete2 => 'Excluir';

  @override
  String gitUiDeleteUnmergedBranchArg0(String arg0) {
    return 'Excluir ramo não fundido $arg0?';
  }

  @override
  String gitUiArg0GitReportsThisBranchIsNotFullyMergedExplicitly(String arg0) {
    return '$arg0 Git relata que este ramo não está completamente fundido. Exclua explicitamente a referência local após rever os seus commits; cópias remotas não são modificadas.';
  }

  @override
  String get gitUiDeleteUnmergedLocalBranch =>
      'Excluir o ramo local não fundido';

  @override
  String gitUiDestinationArg0Arg1(String arg0, String arg1) {
    return 'Destino: $arg0 · $arg1';
  }

  @override
  String get gitUiSourceBranchOrTag => 'Ramo ou etiqueta de origem';

  @override
  String get gitUiMergePolicy => 'Política de fusão';

  @override
  String get gitUiFastForwardWhenPossible =>
      'Avançar rapidamente quando possível';

  @override
  String get gitUiAlwaysCreateAMergeCommit => 'Criar sempre um commit de fusão';

  @override
  String get gitUiFastForwardOnly => 'Apenas para avançar rápido';

  @override
  String get gitUiSquashIntoStagedChanges => 'Apanhar em mudanças encenadas';

  @override
  String get gitUiStopBeforeCreatingTheMergeCommit =>
      'Parar antes de criar o commit de fusão';

  @override
  String get gitUiFastForwardIsDisabledSoHEADCannotMoveBeforeReview =>
      'O avanço rápido está desativado para impedir que HEAD se mova antes da revisão.';

  @override
  String get gitUiLeavesStagedChangesForASeparateCommitThisIsNot =>
      'Deixa as mudanças encenadas para um commit separado; isto não é uma fusão contínua.';

  @override
  String get gitUiConflictsRemainAvailableInTheSharedResolutionWorkspace =>
      'Os conflitos permanecem disponíveis no espaço de trabalho de resolução compartilhada.';

  @override
  String get gitUiAddRemote => 'Adicionar remoto...';

  @override
  String gitUiFetchArg0PushArg1(String arg0, String arg1) {
    return 'Procure: $arg0 Empurre: $arg1';
  }

  @override
  String get gitUiRemoveRemote => 'Remover o remoto...';

  @override
  String get gitUiChangeFetchURL => 'Alterar a URL de captação...';

  @override
  String get gitUiAddPushDestination => 'Adicionar destino de empurrão...';

  @override
  String get gitUiRemovePushDestination => 'Remover o destino do empurrão...';

  @override
  String gitUiManageArg0(String arg0) {
    return 'Gerir $arg0';
  }

  @override
  String get gitUiRemoteName => 'Nome remoto';

  @override
  String get gitUiNewRemoteName => 'Novo nome remoto';

  @override
  String get gitUiRepositoryURLOrLocalSource =>
      'URL do repositório ou fonte local';

  @override
  String get gitUiEnterTheExactReviewedDestinationToRemove =>
      'Digite o destino exato revisto para remover.';

  @override
  String get gitUiCredentialsAreSuppliedByConfiguredHelpersOrAPrivatePrompt =>
      'As credenciais são fornecidas por ajudantes configurados ou por um prompt privado.';

  @override
  String gitUiRemoveRemoteArg0(String arg0) {
    return 'Remover remoto $arg0?';
  }

  @override
  String
  get gitUiRemovesLocalRemoteConfigurationAndTrackingReferencesItDoesNot =>
      'Remove a configuração remota local e as referências de rastreamento. Ele não exclui o repositório do servidor.';

  @override
  String get gitUiRemoveRemote2 => 'Remover o remoto';

  @override
  String get gitUiCommitScopeEntireRepository =>
      'Compromete o escopo: repositório inteiro';

  @override
  String get gitUiCachedTracking => 'Rastreamento em caches';

  @override
  String get gitUiAmendLastCommit => 'Alterar último commit';

  @override
  String get gitUiConfiguredHooksAndSigningAreRespected =>
      'Os ganchos configurados e a assinatura são respeitados.';

  @override
  String get gitUiRewritesTheSelectedHEADCommitRemoteTrackingCannotProveIt =>
      'Reescreve o commit HEAD selecionado. O rastreio remoto não prova que ainda não foi publicado.';

  @override
  String get gitUiRepository => 'Repositório';

  @override
  String gitUiDetachedArg0(String arg0) {
    return 'Detalhado $arg0';
  }

  @override
  String get gitUiLog => 'Histórico';

  @override
  String get gitUiRepositoryActions => 'Ações do repositório';

  @override
  String gitUiCachedTrackingUpstreamAheadAheadBehindBehind(
    String upstream,
    String ahead,
    String behind,
  ) {
    return 'Rastreio em cache · $upstream · $ahead à frente · $behind atrás';
  }

  @override
  String get gitUiBareRepositoryNoWorkingTreeOpenLogToInspectIts =>
      'Repository Bare · nenhuma árvore de trabalho. Abrir o log para inspecionar o seu histórico.';

  @override
  String get gitUiReadOnlyRepositoryStagingAndCommitsAreUnavailable =>
      'O repositório de apenas leitura · estadging e commits não estão disponíveis.';

  @override
  String get gitUiRepositoryStatusUnavailable =>
      'Situação do repositório indisponível';

  @override
  String gitUiAmendRevision(String revision) {
    return 'Alterar $revision';
  }

  @override
  String get gitUiAddSignOffTrailer => 'Adicionar linha de aprovação';

  @override
  String get gitUiUseConfiguredSigningPolicy =>
      'Usar a política de assinatura configurada';

  @override
  String get gitUiCryptographicallySignThisCommit =>
      'Criptograficamente assinar este commit';

  @override
  String get gitUiDoNotSignThisCommit => 'Não assine este commit';

  @override
  String get gitUiRecentCommitMessages => 'Mensagens de commit recentes...';

  @override
  String get gitUiUseConfiguredCommitTemplate =>
      'Usar o modelo de commit configurado...';

  @override
  String get gitUiAuthorIdentityAndConfiguredHooks =>
      'Identidade do autor e ganchos configurados...';

  @override
  String get gitUiDraftMessage => 'Projecto de mensagem...';

  @override
  String get gitUiCommitOptions => 'Opções do commit';

  @override
  String gitUiDraftRetainedInMemorySavingItFailedArg0(String arg0) {
    return 'Projeto conservado em memória; a salvação falhou. $arg0';
  }

  @override
  String get gitUiCommitMessage => 'Mensagem do commit';

  @override
  String get gitUiGitOperationInProgress => 'Operação Git em curso';

  @override
  String get gitUiCancel => 'Cancelar';

  @override
  String get gitUiAmendStaged => 'Modificar o estágio';

  @override
  String gitUiCommitStagedCount(String count) {
    return 'Commit das alterações preparadas ($count)';
  }

  @override
  String get gitUiCommitAndPush => 'Criar commit e enviar…';

  @override
  String get gitUiNoReadableCommitTemplateIsConfigured =>
      'Não está configurado nenhum modelo de commit legível.';

  @override
  String get gitUiCommitIdentityAndHooks =>
      'Identidade de compromisso e ganchos';

  @override
  String get gitUiRecentMessages => 'Mensagens recentes';

  @override
  String get gitUiReplaceMessageDraft => 'Substituir o rascunho da mensagem?';

  @override
  String get gitUiReplaceTheExistingCommitMessageWithTheSelectedMessage =>
      'Substituir a mensagem de commit existente pela mensagem selecionada?';

  @override
  String get gitUiReplaceDraft => 'Substituir o projecto';

  @override
  String gitUiLocalCommitArg0Exists(String arg0) {
    return 'A autorização local $arg0 existe.';
  }

  @override
  String gitUiLocalCommitArg0ExistsReviewLogBeforeAttemptingAnotherCommit(
    String arg0,
  ) {
    return 'O commit local $arg0 existe. Revisar o Registo antes de tentar outro commit. O esboço da mensagem foi mantido.';
  }

  @override
  String get gitUiCommitAuthorName => 'Commit nome do autor';

  @override
  String get gitUiCommitAuthorEmail => 'Commit email do autor';

  @override
  String get gitUiConfiguredDefault => 'configurado padrão';

  @override
  String get gitUiOpenpgp => 'OpenPGP';

  @override
  String gitUiSigningArg0Arg1(String arg0, String arg1) {
    return 'Assinatura: $arg0 · $arg1';
  }

  @override
  String gitUiConfiguredHooksArg0(String arg0) {
    return 'Ganchos configurados: $arg0';
  }

  @override
  String get gitUiASignOffTrailerIsAStatementInTheMessage =>
      'A linha de aprovação é uma declaração na mensagem, distinta de uma assinatura criptográfica. A identidade é guardada apenas na configuração local do repositório; o rascunho é preservado.';

  @override
  String get gitUiSaveRepositoryIdentity =>
      'Salvar a identidade do repositório';

  @override
  String get gitUiStaged => 'Preparadas';

  @override
  String get gitUiUntracked => 'Não rastreadas';

  @override
  String get gitUiUnstaged => 'Não preparadas';

  @override
  String get gitUiConflicts => 'Conflitos';

  @override
  String get gitUiNoChanges => 'Nenhuma alteração';

  @override
  String get gitUiRepositoryChangeTree => 'Árvore de mudança de repositório';

  @override
  String get gitUiChanges => 'Alterações';

  @override
  String gitUiGroupCount(String group, String count) {
    return '$group ($count)';
  }

  @override
  String get gitUiExpand => 'Expandir';

  @override
  String get gitUiCollapse => 'Colapso';

  @override
  String get gitUiUnstageFile => 'Retirar arquivo do índice';

  @override
  String get gitUiStageFile => 'Preparar arquivo';

  @override
  String get gitUiExpandGroup => 'Expandir o grupo';

  @override
  String get gitUiCollapseGroup => 'Grupo de colapso';

  @override
  String get gitUiReviewDifference => 'Diferença de revisão';

  @override
  String get gitUiUnstageSelectedFiles =>
      'Retirar arquivos selecionados do índice';

  @override
  String get gitUiStageSelectedFiles => 'Preparar arquivos selecionados';

  @override
  String get gitUiFileHistoryAndBlame => 'Histórico de arquivos e culpa...';

  @override
  String get gitUiDeleteUntrackedFile => 'Excluir o arquivo não rastreado...';

  @override
  String get gitUiDiscardUnstagedChange => 'Descartar a mudança sem cenas...';

  @override
  String get gitUiFileHistory => 'Histórico do arquivo';

  @override
  String gitUiDiscardUnstagedArg0(String arg0) {
    return 'Descartar o $arg0 sem palco?';
  }

  @override
  String gitUiArg0BytesArg1ReplacesWorkingContentWithTheIndexOr(
    String arg0,
    String arg1,
  ) {
    return '$arg0 bytes · $arg1 Substitui o conteúdo de trabalho com o índice, ou exclui este arquivo não rastreado. O conteúdo em fase é mantido. Os documentos de hospedagem não salvos devem ser revistos primeiro.';
  }

  @override
  String get gitUiDeleteUntrackedFile2 => 'Excluir o arquivo não rastreado';

  @override
  String get gitUiDiscardWorkingChange => 'Eliminar a alteração de trabalho';

  @override
  String gitUiDeleteREMOTEReferenceArg0(String arg0) {
    return 'Riscar a referência da REMOTE $arg0';
  }

  @override
  String get gitUiThisRemovesTheReferenceOnEveryActualPushDestinationListed =>
      'Isto remove a referência em todos os destinos de empurrão real listados abaixo. As ramificações/etiquetas locais são mantidas. As dicas esperadas são fixadas por esta revisão.';

  @override
  String get gitUiReferenceDoesNotExist => 'a referência não existe';

  @override
  String gitUiArg0ExpectedTipArg1(String arg0, String arg1) {
    return '$arg0 Dica prevista: $arg1';
  }

  @override
  String get gitUiRemoteDeletionCompleted => 'Apagamento remoto concluído.';

  @override
  String gitUiDeleteArg0FromTheRemote(String arg0) {
    return 'Excluir $arg0 do controle remoto?';
  }

  @override
  String get gitUiTheExactDestinationTipsShownAboveWillBeRemovedAny =>
      'As dicas de destino exatas mostradas acima serão removidas. Qualquer dica remota alterada para parar a operação para outra revisão.';

  @override
  String get gitUiReviewAndDeleteFromRemote =>
      'Revisar e apagar a partir do remoto...';

  @override
  String get gitUiDestinationReference => 'Referência do destino';

  @override
  String get gitUiReviewDestinations => 'Revisar os destinos';

  @override
  String get gitUiNewRemoteBranch => 'novo ramo remoto';

  @override
  String gitUiArg0Arg1ExpectedArg2(String arg0, String arg1, String arg2) {
    return '$arg0\n$arg1 · esperado: $arg2';
  }

  @override
  String get gitUiADestinationHasCommitsThatAreUnavailableLocallyFetchThat =>
      'Um destino tem commits que estão indisponíveis localmente. Obter o destino revisado antes de rever o histórico de saída.';

  @override
  String get gitUiFetchReviewedDestination => 'Procurar o destino revisto';

  @override
  String get gitUiChooseADestinationAndReviewTheOutgoingCommits =>
      'Escolha um destino e revise os commits de saída.';

  @override
  String get gitUiNoOutgoingCommits => 'Sem compromissos de saída';

  @override
  String get gitUiSelectAnOutgoingCommit => 'Selecione um commit de saída';

  @override
  String get gitUiLoadMoreOutgoingCommits => 'Carregar mais commits de saída';

  @override
  String get gitUiSetThisDestinationAsUpstream =>
      'Definir este destino como a montante';

  @override
  String get gitUiChooseExactTagsToPublish =>
      'Escolha etiquetas exatas para publicar';

  @override
  String get gitUiTagsNone => 'Etiquetas: nenhum';

  @override
  String gitUiTagsArg0Selected(String arg0) {
    return 'Etiquetas: $arg0 selecionado';
  }

  @override
  String gitUiPublishExactlyArg0(String arg0) {
    return 'Publique exatamente: $arg0';
  }

  @override
  String get gitUiPushCompletedTheLocalCommitRemainsAvailableInLog =>
      'Empurrar completado. O commit local permanece disponível no Log.';

  @override
  String get gitUiForceRequiresTheExactDestinationTipsShownInThisReview =>
      'O envio forçado exige exatamente as revisões de destino apresentadas nesta revisão.';

  @override
  String get gitUiForceWithReviewedLease => 'Força com aluguel revisado...';

  @override
  String get gitUiPush => 'Enviar';

  @override
  String get gitUiForcePushWithReviewedLeases => 'Forçar com aluguel revisado?';

  @override
  String gitUiRewriteArg0OnlyIfEveryRemoteDestinationStillHasThe(String arg0) {
    return 'Reescrever $arg0 apenas se cada destino remoto ainda tiver a ponta exata mostrada acima.\n';
  }

  @override
  String get gitUiOtherPeopleMayAlreadyUseThisHistoryABackgroundFetch =>
      'Outras pessoas podem já usar este histórico. Uma busca em segundo plano não renova esta condição de segurança.';

  @override
  String get gitUiForceWithLease => 'Força com contrato de arrendamento';

  @override
  String
  get gitUiTheRemoteOutcomeIsUncertainReviewDestinationsAgainBeforeAnother =>
      'O resultado remoto é incerto. Revise destinos novamente antes de outro empurrão.';

  @override
  String gitUiParentArg0Arg1(String arg0, String arg1) {
    return 'Pai e mãe $arg0 · $arg1';
  }

  @override
  String get gitUiRemoteToFetch => 'Remoto para obter';

  @override
  String get gitUiPruneDeletedRemoteTrackingBranches =>
      'Prune ramificações de rastreamento remoto excluídas';

  @override
  String
  get gitUiFetchUpdatesRemoteTrackingInformationWithoutReplacingWorkingFiles =>
      'Obtenha atualizações de informações de rastreamento remoto sem substituir arquivos de trabalho.';

  @override
  String get gitUiFetch => 'Buscar';

  @override
  String get gitUiSourceRemote => 'Remoto de fonte';

  @override
  String get gitUiSourceBranch => 'Filial fonte';

  @override
  String get gitUiReviewedStrategy => 'Estratégia revista';

  @override
  String get gitUiMerge => 'Mesclar';

  @override
  String get gitUiRebase => 'Rebase';

  @override
  String get gitUiStopIfTheDestinationCannotFastForwardNeverMergeOr =>
      'Parar se o destino não puder avançar rapidamente; nunca se fundir ou rebasar.';

  @override
  String get gitUiMergeWithAMergeCommitIncludingWhenFastForwardIs =>
      'Fuja com um commit de fusão, incluindo quando for possível fast-forward.';

  @override
  String get gitUiMergeAllowFastForwardWhenPossible =>
      'Fuja; permita que avance rápido quando possível.';

  @override
  String get gitUiRebaseLocalHistoryWhilePreservingLocalMergeCommits =>
      'Rebase a história local enquanto preserva a fusão local commits.';

  @override
  String get gitUiRebaseLocalCommitsAsALinearHistory =>
      'Rebase commits locais como um histórico linear.';

  @override
  String get gitUiGitIsConfiguredForInteractiveRebaseSelectAPullStrategy =>
      'O Git está configurado para rebase interativo. Selecione uma estratégia de puxação explicitamente aqui, ou procure e abra Rebase... para rever um plano.';

  @override
  String get gitUiUseReviewedOrdinaryRebaseForThisPull =>
      'Usar a rebase ordinária revisada para esta puxação';

  @override
  String get gitUiOptions => 'Opções';

  @override
  String get gitUiAlwaysCreateAMergeCommitNoFastForward =>
      'Criar sempre um commit de fusão (não fast-forward)';

  @override
  String get gitUiPreserveLocalMergeCommits =>
      'Preservar a fusão local commits';

  @override
  String get gitUiLocalChangesMayPreventPullReviewCommitThemOrExplicitly =>
      'Alterações locais podem impedir o puxamento. Revise/comprometa-as ou crie explicitamente um estoque.';

  @override
  String get gitUiStashes => 'Stashes';

  @override
  String get gitUiCreateOrReviewStash => 'Criar ou rever o estoque...';

  @override
  String get gitUiPullWithSelectedStrategy =>
      'Puxar com a estratégia selecionada';

  @override
  String get gitUiRepositoryURLOrLocalGitSource =>
      'URL do repositório ou fonte local do Git';

  @override
  String get gitUiHttpsSSHOrLocalPath => 'HTTPS, SSH ou caminho local';

  @override
  String get gitUiFolderToInitialize => 'Pasta para inicializar';

  @override
  String get gitUiFinalCloneDestination => 'Destino final do clone';

  @override
  String get gitUiChoose => 'Escolha...';

  @override
  String get gitUiCreatesGitMetadataOnlyExistingFilesAreNotStagedOr =>
      'Cria apenas metadados Git. Os arquivos existentes não são encenados ou comprometidos.';

  @override
  String get gitUiTheFinalDestinationMustBeAbsentOrEmptyExistingUser =>
      'O destino final deve não existir ou estar vazio. Os dados existentes do usuário nunca são substituídos.';

  @override
  String get gitUiInitialBranchBlankUsesEffectiveGitPolicy =>
      'Branco inicial · em branco utiliza a política eficaz de Git';

  @override
  String get gitUiSelectedBranchOptional => 'Branco selecionado · opcional';

  @override
  String get gitUiExplicitlyInitializeUpdateSubmodulesRecursively =>
      'Inicializar/actualizar explicitamente submódulos recursivamente';

  @override
  String get gitUiPreparingGitOperation => 'Preparar a operação Git...';

  @override
  String get gitUiThisAttemptCreated => 'Esta tentativa foi criada';

  @override
  String get gitUiTheDestinationExistedBeforeThisAttempt =>
      'O destino existia antes desta tentativa:';

  @override
  String get gitUiTheDirectoryRemainsForInspectionReviewItBeforeAnotherClone =>
      'O directorio permanece para inspeção. Revise-o antes de outra tentativa de clon.';

  @override
  String get gitUiNoDestinationDirectoryRemains =>
      'Não resta nenhum diretório de destino.';

  @override
  String get gitUiCancelProcess => 'Cancelar o processo';

  @override
  String get gitUiInitialize => 'Inicializar';

  @override
  String get gitUiClone => 'Clonar';

  @override
  String get gitUiChooseNewBase => 'Escolher nova base';

  @override
  String get gitUiChooseUpstreamBoundary => 'Escolher limite upstream';

  @override
  String get gitUiNewBase => 'Nova base';

  @override
  String get gitUiUpstreamBoundaryExcluded => 'Limite upstream · excluído';

  @override
  String get gitUiSameAsUpstreamBoundary => 'Igual ao limite upstream';

  @override
  String get gitUiChooseBranchTagOrCommit => 'Escolher branch, tag ou commit…';

  @override
  String get gitUiUseUpstreamAsNewBase => 'Usar a montante como nova base';

  @override
  String get gitUiChooseAValidBranchTagOrCommitFromLog =>
      'Escolha um ramo, tag ou commit válidos no Registro.';

  @override
  String get gitUiTheFirstRetainedCommitInABranchBlockCannotSquash =>
      'O primeiro commit mantido num bloco de branch não pode usar squash ou fixup: não existe um commit anterior de destino.';

  @override
  String gitUiBranchBlockArg0(String arg0) {
    return 'Bloqueio de ramos $arg0\n';
  }

  @override
  String get gitUiRewordWillRequestANewMessage =>
      '[Reformulação irá solicitar uma nova mensagem]\n';

  @override
  String get gitUiPlannedCommitMessages => 'Mensagens de autorização previstas';

  @override
  String
  get gitUiOriginalCombinedMessagePreviewGitRequestsTheFinalRewordSquash =>
      'Visualização da mensagem original/combinada · Git solicita a reformulação final/squash mensagens';

  @override
  String gitUiResultArg0Arg1(String arg0, String arg1) {
    return 'Resultado $arg0 $arg1';
  }

  @override
  String gitUiCurrentBranchBranch(String branch) {
    return 'Branch atual: $branch';
  }

  @override
  String get gitUiDetachedHEAD2 => 'HEAD destacado';

  @override
  String
  get gitUiRebaseRewritesCommitIdentitiesRemoteTrackingInformationCannotProveHistory =>
      'O rebase reescreve as identidades dos commits. Os dados de rastreio remoto não provam que o histórico nunca foi publicado.';

  @override
  String get gitUiIncludeRootCommits => 'Incluir commits raiz';

  @override
  String get gitUiMergeCommits => 'A fusão compromete-se';

  @override
  String get gitUiFlattenHistory => 'Linearizar histórico';

  @override
  String get gitUiPreserveBranchStructure => 'Preservar estrutura das branches';

  @override
  String get gitUiAutosquash => 'Combinação automática';

  @override
  String get gitUiPrepareGitPlan => 'Preparar plano Git';

  @override
  String gitUiCommitsToReplayCount(String count) {
    return 'Commits a reaplicar: $count';
  }

  @override
  String get gitUiIncludesAllRootCommitsReachableFromThisBranch =>
      'Inclui todos os commits root acessíveis a partir deste ramo.';

  @override
  String gitUiCommitsAfterBoundaryWillBeReplayedOntoBaseTheBoundary(
    String boundary,
    String base,
  ) {
    return 'Os commits após $boundary serão reaplicados sobre $base; o próprio commit limite é excluído.';
  }

  @override
  String get gitUiRoot => 'Raíz';

  @override
  String get gitUiGitBranchLabelResetMergeStructure =>
      'Estrutura de ramo/rótulo/reposição/fusão Git';

  @override
  String get gitUiChooseAnExplicitOldBoundaryOrRootModeThenPrepare =>
      'Escolha um modo explícito de contorno ou raiz, e prepare o plano.';

  @override
  String get gitUiMoveUp => 'Subir';

  @override
  String get gitUiMoveDown => 'Descer';

  @override
  String get gitUiResetPlan => 'Repor plano';

  @override
  String gitUiBranchBlockArg02(String arg0) {
    return ' · bloco de ramos $arg0';
  }

  @override
  String get gitUiSelectACommitForDetailsAndChangedFiles =>
      'Selecione um commit para obter detalhes e alterar arquivos';

  @override
  String get gitUiPreviewCombinedCommitMessages =>
      'Visualização das mensagens de commit combinadas...';

  @override
  String get gitUiAltMovesTheSelectedCommitUnrelatedBranchReferencesWillNot =>
      'Alt+↑/↓ move o commit seleccionado. As referências de ramo não relacionadas não serão atualizadas automaticamente.';

  @override
  String get gitUiCancelPlan => 'Cancelar o plano';

  @override
  String get gitUiStartReviewedRebase => 'Iniciar o rebase revisado?';

  @override
  String gitUiRewriteArg0PlannedCommitsOnArg1DroppedCommitsRemainVisibly(
    String arg0,
    String arg1,
  ) {
    return 'Reescrever $arg0 planejou commits em $arg1. Dropped commits permanece visivelmente marcado neste plano até que você comece.';
  }

  @override
  String get gitUiStartRebase => 'Iniciar rebase';

  @override
  String get gitUiNoContinuingGitOperation => 'Sem operação Git contínua';

  @override
  String get gitUiStoppedForEditingAmend => ' · parou para editar/alterar';

  @override
  String get gitUiTheseAreUnmergedIndexEntriesPossiblyFromAStashApplication =>
      'Estas são entradas de índice não fundidas, possivelmente de um aplicativo de estoque. O Git não tem nenhum estoque continuar ou abortar o comando.';

  @override
  String get gitUiEditTheWorkingFilesStageAndAmendTheCurrentCommit =>
      'Edite os arquivos de trabalho, estabeleça e modifique o commit atual, em seguida, continue esta rebase.';

  @override
  String gitUiArg0Arg1UnmergedStagesArg2(
    String arg0,
    String arg1,
    String arg2,
  ) {
    return '$arg0$arg1 · estágios do índice não mesclados $arg2';
  }

  @override
  String get gitUiTheIndexHasNoUnresolvedEntries =>
      'O índice não tem entradas não resolvidas.';

  @override
  String get gitUiKeepTheCurrentCommitAsAnEmptyCommit =>
      'Mantenha o commit atual como um commit vazio';

  @override
  String get gitUiTheRealIndexHasNoStagedChangesCreateAnExplicit =>
      'O índice real não tem alterações estaduais. Crie um commit vazio explícito, em seguida, continue o sequenciador se permanecer ativo.';

  @override
  String get gitUiKeepEmptyCommit => 'Mantenha o commit vazio...';

  @override
  String get gitUiGitWillTryToReturnToTheOperationSStarting =>
      'O Git tentará regressar ao início da operação. Não é garantida a recuperação de conteúdos anteriores fora do índice, não rastreados ou não salvos.';

  @override
  String get gitUiSkipTheCurrentCommitAndContinueWithTheNextPlanned =>
      'Saltar o commit atual e continuar com o commit próximo planejado.';

  @override
  String
  get gitUiForgetThisOperationSBookkeepingWhileRetainingTheCurrentFiles =>
      'Esqueça esta operação de contabilidade enquanto mantém os arquivos e índices atuais.';

  @override
  String gitUiContinueArg0(String arg0) {
    return 'Continuar $arg0';
  }

  @override
  String get gitUiReloadConflictVersions => 'Recarregar versões de conflito?';

  @override
  String get gitUiReplaceTheUnsavedResultDraftWithTheCurrentWorkingFile =>
      'Substituir o projecto de resultado não salvo pelo arquivo de trabalho actual. O conteúdo de trabalho salvo é mantido.';

  @override
  String get gitUiLoadingConflictVersions =>
      'A carregar as versões de conflito...';

  @override
  String get gitUiLoadingConflict => 'Carregamento de conflitos';

  @override
  String get gitUiBaseLeft => 'Base → esquerda';

  @override
  String get gitUiBaseRight => 'Base → direita';

  @override
  String get gitUiNoBaseEntryForThisConflict =>
      'Nenhuma entrada de base para este conflito';

  @override
  String get gitUiAcceptEntireLeftFile => 'Aceitar todo o arquivo esquerdo...';

  @override
  String get gitUiAcceptEntireRightFile => 'Aceitar todo o arquivo da direita…';

  @override
  String get gitUiPreviousConflictRegion => 'Região de conflito anterior';

  @override
  String get gitUiNextConflictRegion => 'Próxima região de conflito';

  @override
  String get gitUiManualResolution => 'Resolução manual';

  @override
  String gitUiRegionArg0Arg1Arg2Reviewed(
    String arg0,
    String arg1,
    String arg2,
  ) {
    return 'Região $arg0/$arg1 · $arg2 reexaminado';
  }

  @override
  String
  get gitUiSourceAlignmentExceededTheTextComparisonLimitSourcePanesRemain =>
      'O alinhamento da fonte ultrapassou o limite de comparação de texto; os painéis fonte permanecem disponíveis para revisão manual.';

  @override
  String get gitUiAcceptLeftRegion => 'Aceitar região esquerda';

  @override
  String get gitUiAcceptRightRegion => 'Aceitar a região certa';

  @override
  String get gitUiKeepManualResultForRegion =>
      'Mantenha o resultado manual para a região';

  @override
  String get gitUiApplyGitSNonConflictingChanges =>
      'Aplicar as mudanças não conflitantes do Git?';

  @override
  String get gitUiReplaceTheCurrentResultDraftWithGitSMergePreview =>
      'Substituir o esboço de resultados atual com a pré-visualização da fusão do Git. Isto elimina as edições de resultados manuais não salvos; o arquivo de trabalho não está alterado até Salvar.';

  @override
  String get gitUiUseMergePreview => 'Usar a pré-visualização da fusão';

  @override
  String get gitUiApplyNonConflictingChanges =>
      'Aplicar mudanças não conflitantes...';

  @override
  String get gitUiLeftSource => 'Fonte esquerda';

  @override
  String get gitUiResult => 'Resultado';

  @override
  String get gitUiRightSource => 'Fonte direita';

  @override
  String get gitUiStage2 => 'Fase 2';

  @override
  String get gitUiStage3 => 'Fase 3';

  @override
  String
  get gitUiConflictVersionsAreUnavailableRefreshToReviewTheirCurrentState =>
      'As versões de conflito não estão disponíveis. Actualize para rever o seu estado atual.';

  @override
  String get gitUiResultSavedToDiskTheIndexStillDeterminesWhetherThis =>
      'Resultado salvo no disco. O índice ainda determina se este arquivo está resolvido.';

  @override
  String get gitUiSaveResultDraft => 'Salvar rascunho do resultado';

  @override
  String get gitUiApplyResultAndStageResolution =>
      'Aplicar resultado e preparar resolução';

  @override
  String get gitUiResultEditableUTF8WorkingContent =>
      'Resultado · conteúdo de trabalho editável UTF-8';

  @override
  String get gitUiEditableConflictResult => 'Resultado de conflito editável';

  @override
  String gitUiLeftArg0Arg1RightArg2Arg3(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return 'Esquerda: $arg0 · $arg1\nDireita: $arg2 · $arg3';
  }

  @override
  String get gitUiChooseContentDeletionOrASubmoduleCommitExplicitlyNoBinary =>
      'Escolha o conteúdo, a exclusão ou um submódulo de commit explicitamente. Nenhum dado binário é decodificado como texto editável.';

  @override
  String get gitUiUseEntireLeftContent => 'Usar todo o conteúdo esquerdo...';

  @override
  String get gitUiUseEntireRightContent => 'Usar todo o conteúdo da direita…';

  @override
  String get gitUiDeleteThisPath => 'Excluir este caminho...';

  @override
  String get gitUiResolvedSubmoduleCommit => 'Submódulo de commit resolvido';

  @override
  String get gitUiStageThisExactGitlinkInTheParentThisDoesNot =>
      'Estabelecer este gitlink exato no pai. Isto não verifica ou comete o submódulo.';

  @override
  String get gitUiSetResolvedGitlink => 'Definir o gitlink resolvido...';

  @override
  String gitUiBaseStageArg0(String arg0) {
    return 'Base → estágio $arg0';
  }

  @override
  String get gitUiTheResultWasEditedKeepTheManualResultOrSelect =>
      'O resultado foi editado. Mantenha o resultado manual ou selecione outra região inalterada.';

  @override
  String gitUiApplyArg0Resolution(String arg0) {
    return 'Aplicar a resolução «$arg0»?';
  }

  @override
  String get gitUiStageTheChosenGitlinkCommitInTheParentTheSubmodule =>
      'Estabelecer o gitlink escolhido commit no pai. O submódulo checkout e os seus arquivos não são substituídos.';

  @override
  String gitUiReplacesTheEntireWorkingPathArg0AndStagesTheDecision(
    String arg0,
  ) {
    return 'Substitui toda a trajetória de trabalho $arg0 e encena a decisão. O conteúdo de trabalho atual e qualquer projeto de resultado não salvo serão descartados.';
  }

  @override
  String get gitUiApplyEntireFileDecision =>
      'Aplicar a decisão do arquivo inteiro';

  @override
  String get gitUiStageThisConflictResolution =>
      'Encenar esta resolução de conflitos?';

  @override
  String gitUiUseTheEntireEditedResultAsArg0GitRecordsThe(
    String arg0,
    String arg1,
  ) {
    return 'Use todo o resultado editado como $arg0. Git registra o caminho resolvido quando é encenado. Revise todo o conteúdo pretendido primeiro.$arg1';
  }

  @override
  String get gitUiApplyAndStage => 'Aplicar e preparar';

  @override
  String get gitUiReviewResultTextFormatChanges =>
      'Revisar as alterações de formato de texto do resultado';

  @override
  String get gitUiSaveReviewedResult => 'Gravar o resultado revisto';

  @override
  String
  get gitUiNativeGitTableAccessibilityIsUnavailableRetryAfterReconnectingThe =>
      'A acessibilidade da tabela nativa Git não está disponível. Reexperimente após reconectar a aplicação.';

  @override
  String get gitUiSans => 'Sem';

  @override
  String get gitUiSelect => 'Selecionar';

  @override
  String get gitUiContextMenu => 'Menú de contexto';

  @override
  String get gitUiCopyText => 'Copie o texto';

  @override
  String get gitUiLoadingRow => 'A carregar a linha';

  @override
  String get gitUiRetry => 'Reexperimentar';

  @override
  String get gitUiGitMessage => 'Mensagem Git';

  @override
  String get gitUiCancelPrompt => 'Cancelar o prompt';

  @override
  String get gitUiUseMessageAndContinue => 'Usar mensagem e continuar';

  @override
  String get gitUiRespondPrivately => 'Resposta privada';

  @override
  String gitUiViewPreferencesCouldNotBeSavedArg0(String arg0) {
    return 'As preferências de visualização não puderam ser salvas: $arg0';
  }

  @override
  String gitUiCommitDraftStorageArg0(String arg0) {
    return 'Commit projeto de armazenamento: $arg0';
  }

  @override
  String gitUiViewPreferencesCouldNotBeReadArg0(String arg0) {
    return 'As preferências de visualização não puderam ser lidas: $arg0';
  }

  @override
  String gitUiCommitDraftWasRetainedInMemoryButCouldNotBe(String arg0) {
    return 'O rascunho de compromisso foi mantido em memória, mas não pôde ser salvo: $arg0';
  }

  @override
  String get gitUiTheReviewedRepositoryIsReadOnlyForThisOperationHistory =>
      'O repositório revisado é apenas de leitura para esta operação. O histórico e a inspeção de conteúdo permanecem disponíveis.';

  @override
  String gitUiGitReturnedArg0TheApplicationCouldNotRefreshItsDocuments(
    String arg0,
    String arg1,
  ) {
    return 'Git retornou $arg0. A aplicação não pôde atualizar seus documentos: $arg1';
  }

  @override
  String get gitUiSelectCommitInLog => 'Selecionar commit no histórico…';

  @override
  String get gitUiCurrentBranch => 'Branch atual';

  @override
  String get gitUiNoMatchingBranchesOrTagsSelectACommitInLog =>
      'Não há ramificações ou etiquetas correspondentes. Selecione um commit no Log.';

  @override
  String get gitUiBranches => 'Branches';

  @override
  String get gitUiPushCommits => 'Enviar commits';

  @override
  String gitUiPullIntoArg0(String arg0) {
    return 'Puxar para $arg0';
  }

  @override
  String gitUiResolveArg0(String arg0) {
    return 'Resolução $arg0';
  }

  @override
  String get gitUiCurrentOperation => 'Operação em curso';

  @override
  String get gitUiRebaseCommits => 'Rebase de commits';

  @override
  String get gitUiFetch2 => 'Buscar…';

  @override
  String get gitUiPull => 'Puxar…';

  @override
  String get gitUiPush2 => 'Enviar…';

  @override
  String get gitUiBranches2 => 'Branches…';

  @override
  String get gitUiManageRemotes => 'Gerir remotos…';

  @override
  String gitUiMergeIntoArg0(String arg0) {
    return 'Únete-te para $arg0...';
  }

  @override
  String get gitUiRebase2 => 'Rebase…';

  @override
  String get gitUiConflictsAndCurrentOperation =>
      'Conflitos e operações actuais...';

  @override
  String get gitUiStashes2 => 'Stashes…';

  @override
  String get gitUiWorktrees => 'Árvores de trabalho…';

  @override
  String get gitUiSubmodules => 'Submódulos…';

  @override
  String get gitUiReflogAndRecovery => 'Reflog e recuperação…';

  @override
  String get gitUiCloneRepository => 'Clonar repositório…';

  @override
  String get gitUiRevokeRepositoryTrust => 'Revogar a confiança no repositório';

  @override
  String get gitUiWaitingForRepositoryStatus =>
      'Aguardando o status do repositório';

  @override
  String get gitUiRepositoryStatusUnavailableRefresh =>
      'O estado do repositório não está disponível; atualizar';

  @override
  String get gitUiManageRemotes2 => 'Gerir remotos';

  @override
  String gitUiMergeIntoArg02(String arg0) {
    return 'Fusionar em $arg0';
  }

  @override
  String get gitUiWorktrees2 => 'Árvores de trabalho';

  @override
  String get gitUiSubmodules2 => 'Submódulos';

  @override
  String get gitUiReflogAndRecovery2 => 'Reflog e recuperação';

  @override
  String gitUiCloneRepositoryArg0(String arg0) {
    return 'Depósito de clones · $arg0';
  }

  @override
  String get gitUiApply => 'Aplicar';

  @override
  String get gitUiResizeGitPanes => 'Redimensionar os painéis Git';

  @override
  String gitUiArg0Percent(String arg0) {
    return '$arg0 por cento';
  }

  @override
  String gitUiExitStatusStatus(String status) {
    return 'Estado de saída: $status';
  }

  @override
  String get gitUiRepositoryChangedRefreshAndReviewBeforeTryingAgain =>
      'O repositório mudou. Actualize e revise antes de tentar novamente.';

  @override
  String get gitUiAnotherOperationHoldsTheRepositoryOrIndexLockWaitThen =>
      'Outra operação mantém o repositório ou o bloco do índice. Espere, em seguida, atualize.';

  @override
  String get gitUiRepositoryTrustIsRequiredForThisOperation =>
      'Para esta operação é necessária a confiança de repositório.';

  @override
  String get gitUiTheGitServiceDisconnectedReconnectAndReconcileTheRepository =>
      'O serviço Git desconectou. Reconecte e reconcilia o repositório.';

  @override
  String
  get gitUiTheInstalledGitExecutableCannotSupportThisOperationReviewIts =>
      'O executável Git instalado não pode suportar esta operação. Revise os requisitos de tempo de execução abaixo.';

  @override
  String get gitUiThisRepositoryIsReadOnlyForTheRequestedOperationReview =>
      'Este repositório é apenas de leitura para a operação solicitada. A revisão e o histórico permanecem disponíveis.';

  @override
  String
  get gitUiTheOperationNeedsReconciliationReviewTheResultingRepositoryOrRemote =>
      'A operação precisa de reconciliação. Revise o repositório resultante ou o estado remoto antes de o repetir.';

  @override
  String get gitUiGitAuthenticationFailedReviewTheCredentialHelperOrUnlockThe =>
      'A autenticação do Git falhou. Revise o ajudante credencial ou desbloqueie o chaveiro configurado.';

  @override
  String get gitUiSshHostVerificationFailedReviewTheHostIdentityThroughYour =>
      'A verificação do host SSH falhou. Revise a identidade do host através das ferramentas SSH configuradas.';

  @override
  String get gitUiCommitSigningFailedOrWasCancelledReviewTheSigningKey =>
      'Cometar a assinatura falhou ou foi cancelado. Revise a chave de assinatura, o agente e a ferramenta de assinatura configurada.';

  @override
  String get gitUiSetARepositoryAuthorNameAndEmailThenReturnTo =>
      'Defina um nome de autor do repositório e um e- mail, e retorne ao boceto de mensagem preservado.';

  @override
  String get gitUiGitRejectedTheReviewedUpdateRefreshAndReviewTheActual =>
      'Git rejeitou a atualização revista. Actualize e revise o destino real antes de tentar novamente.';

  @override
  String get gitUiWorkingOrStagedChangesPreventThisOperationReviewCommitOr =>
      'As alterações operacionais ou encenadas impedem esta operação. Revise, commit ou esconda- as explicitamente.';

  @override
  String get gitUiARequiredGitObjectIsUnavailableReviewShallowOrPartial =>
      'Um objeto Git obrigatório não está disponível. Reveja limites rasos ou parciais de repositório e busque explicitamente se necessário.';

  @override
  String gitUiGitOperationFailedArg0(String arg0) {
    return 'A operação Git falhou: $arg0';
  }

  @override
  String get gitUiDiagnostics => 'Diagnóstico';

  @override
  String get gitUiAuthorizeGitInspection => 'Autorizar a inspecção Git...';

  @override
  String get gitUiCopyDiagnostics => 'Copie o diagnóstico';

  @override
  String get gitUiActions => 'Acções';

  @override
  String gitUiBranchAtArg0(String arg0) {
    return 'Branch em $arg0';
  }

  @override
  String get gitUiCreatesALocalBranchWithoutCheckingItOut =>
      'Cria um ramo local sem verificar.';

  @override
  String gitUiTagArg0(String arg0) {
    return 'Tag $arg0';
  }

  @override
  String gitUiReadOnlySnapshotArg0(String arg0) {
    return 'instantâneo de apenas leitura · $arg0';
  }

  @override
  String get gitUiCherryPickCommits => 'Aplicar commits com cherry-pick';

  @override
  String get gitUiRevertCommits => 'Reverter os compromissos';

  @override
  String get gitUiCompareToFullRevisionID =>
      'Comparar com o ID de revisão completa';

  @override
  String gitUiTreeComparisonDirectionArg0TheRevisionEnteredHere(String arg0) {
    return 'Direção de comparação de árvores: $arg0 → a revisão introduzida aqui.';
  }

  @override
  String get gitUiEnterAFullValidObjectID =>
      'Digite um ID de objeto válido completo.';

  @override
  String gitUiArg0Arg1TreeComparison(String arg0, String arg1) {
    return '$arg0 → $arg1 · comparação de árvores';
  }

  @override
  String gitUiResetArg0ToArg1(String arg0, String arg1) {
    return 'Restaurar $arg0 para $arg1';
  }

  @override
  String
  get gitUiMovesHEADCurrentBranchReflogDoesNotRecoverArbitraryUntracked =>
      'Move HEAD/o branch atual. O reflog não recupera qualquer conteúdo não rastreado ou não salvo.';

  @override
  String get gitUiMoveHEADKeepIndexAndWorkingFiles =>
      'Mover HEAD; manter o índice e os arquivos de trabalho.';

  @override
  String get gitUiMoveHEADAndReplaceIndexKeepWorkingFiles =>
      'Mover HEAD e substituir o índice; manter os arquivos de trabalho.';

  @override
  String
  get gitUiReplaceHEADIndexAndTrackedWorkingFilesMayOverwriteObstructing =>
      'Substituir HEAD, índice e arquivos rastreados; pode substituir arquivos não rastreados que impeçam a operação.';

  @override
  String get gitUiReplaceHEADIndexAndEligibleFilesRefuseIfLocalChanges =>
      'Substituir HEAD, índice e arquivos elegíveis; recusar se houver perda de alterações locais.';

  @override
  String gitUiResetWithArg0(String arg0) {
    return 'Restaurar com $arg0?';
  }

  @override
  String gitUiArg0Arg1ReviewTheSelectedModeSEffectsBeforeApplying(
    String arg0,
    String arg1,
  ) {
    return '$arg0 → $arg1 Revise os efeitos do modo selecionado antes de aplicar.';
  }

  @override
  String gitUiResetArg0(String arg0) {
    return 'Restaurar $arg0';
  }

  @override
  String gitUiTargetArg0(String arg0) {
    return 'Alvo $arg0';
  }

  @override
  String get gitUiTagName => 'Nome da tag';

  @override
  String get gitUiAnnotatedTag => 'Tag anotada';

  @override
  String get gitUiCryptographicSigning => 'Assinatura criptográfica';

  @override
  String get gitUiConfiguredPolicy => 'Política configurada';

  @override
  String get gitUiSignThisTag => 'Assinar esta etiqueta';

  @override
  String get gitUiDoNotSign => 'Não assinar';

  @override
  String get gitUiTagMessage => 'Mensagem de etiqueta';

  @override
  String get gitUiCreatesTheTagLocallyPublishSelectedTagsExplicitlyInPush =>
      'Cria a etiqueta localmente. Publique as etiquetas selecionadas explicitamente na revisão Push.';

  @override
  String gitUiCompleteTreesArg0Arg1(String arg0, String arg1) {
    return 'Árvores completas: $arg0 → $arg1';
  }

  @override
  String get gitUiNextChangedFilePage => 'Próxima página de arquivo alterado';

  @override
  String get gitUiReadOnlyRepositorySnapshotOpeningAFileNeverChecksOut =>
      'instantâneo do repositório apenas de leitura. Abrir um arquivo nunca verifica esta revisão.';

  @override
  String get gitUiOpenReadOnlyVersion => 'Versão aberta de apenas leitura';

  @override
  String get gitUiRestoreThisPathWaitingForRepositoryStatus =>
      'Restaurar este caminho... · Aguardando o status do repositório';

  @override
  String get gitUiRestoreThisPath => 'Restaurar este caminho...';

  @override
  String gitUiHistoryArg0(String arg0) {
    return 'História · $arg0';
  }

  @override
  String gitUiRestoreArg0(String arg0) {
    return 'Restaurar $arg0?';
  }

  @override
  String gitUiReplaceThisWorkingPathWithRevisionArg0ExistingStagedContent(
    String arg0,
  ) {
    return 'Substitua este caminho de trabalho pela revisão $arg0. O conteúdo estágio existente é mantido.';
  }

  @override
  String get gitUiRestoreWorkingFile => 'Restaurar o arquivo de trabalho';

  @override
  String gitUiFileHistoryFollowsRenamesArg0(String arg0) {
    return 'O histórico do arquivo segue os renomes · $arg0';
  }

  @override
  String get gitUiBlameCommittedContent => 'Anotações · conteúdo do commit';

  @override
  String get gitUiBlame => 'Anotações…';

  @override
  String gitUiArg0WorkingTree(String arg0) {
    return '$arg0 → Árvore de Trabalho';
  }

  @override
  String get gitUiOpenReadOnlyHistoricalFile =>
      'Abrir o arquivo histórico de apenas leitura';

  @override
  String get gitUiCompareToCurrentFile => 'Comparar com o arquivo actual';

  @override
  String get gitUiCompareToParent => 'Comparar com o pai...';

  @override
  String gitUiCommittedArg0UnsavedEditorContentIsNotPartOfThese(String arg0) {
    return 'Committed $arg0 · conteúdo de editor não salvo não faz parte dessas anotações';
  }

  @override
  String gitUiHistoryFromArg0(String arg0) {
    return 'História de $arg0';
  }

  @override
  String get gitUiBoundary => ' · limite';

  @override
  String gitUiArg0Arg1OriginalLineArg2Arg3(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return '$arg0  $arg1\nLinha original $arg2$arg3';
  }

  @override
  String get gitUiPreviousLines => 'Linhas anteriores';

  @override
  String get gitUiNextLines => 'Próximas linhas';

  @override
  String gitUiExplicitApplicationOrderDestinationArg0(String arg0) {
    return 'Pedido de pedido explícito · destino $arg0';
  }

  @override
  String get gitUiAddFullCommitObjectID =>
      'Adicionar o ID do objeto de commit completo';

  @override
  String get gitUiAddReviewedCommit => 'Adicionar uma revisão de commit...';

  @override
  String get gitUiMoveEarlier => 'Mover mais cedo';

  @override
  String get gitUiMoveLater => 'Mais tarde.';

  @override
  String get gitUiRemoveFromReviewedSequence =>
      'Remover da sequência de revisão';

  @override
  String get gitUiApplyChangesWithoutCreatingCommits =>
      'Aplicar alterações sem criar commits';

  @override
  String get gitUiUseThisExplicitMainlineParentForMergeCommits =>
      'Use este pai de linha principal explícito para fundir commits';

  @override
  String get gitUiEmptyOrAlreadyAppliedCommitsMayStopGitForAn =>
      'Compromissos vazios ou já aplicados podem parar o Git para uma decisão explícita de saut ou continuação.';

  @override
  String get gitUiRevertInReviewedOrder => 'Reverter em ordem de revisão';

  @override
  String get gitUiCherryPickInReviewedOrder =>
      'Pilha de cereja em ordem de revisão';

  @override
  String get gitUiReturnToFiles => 'Voltar para os Arquivos';

  @override
  String get gitUiGit => 'Git';

  @override
  String get gitUiCommit => 'Criar commit';

  @override
  String get gitUiBackToCommit => 'Voltar ao Commit';

  @override
  String get gitUiSelectAChangeToReview => 'Selecione uma alteração para rever';

  @override
  String get gitUiLoadingBranch => 'A carregar o ramo...';

  @override
  String get gitUiBranchUnavailable => 'Sucursal indisponível';

  @override
  String get gitUiUnbornHEAD => 'HEAD sem commits';

  @override
  String gitUiDetachedHEADRevision(String revision) {
    return 'HEAD destacado · $revision';
  }

  @override
  String get gitUiContinueAction => 'Continuar';

  @override
  String get gitUiPick => 'Manter';

  @override
  String get gitUiReword => 'Reescrever mensagem';

  @override
  String get gitUiEdit => 'Editar';

  @override
  String get gitUiSquash => 'Combinar';

  @override
  String get gitUiFixup => 'Combinar sem mensagem';

  @override
  String get gitUiDrop => 'Omitir';

  @override
  String get gitUiAbort => 'Abortar';

  @override
  String get gitUiSkip => 'Ignorar';

  @override
  String get gitUiQuit => 'Sair da operação';

  @override
  String get gitUiSoft => 'Suave';

  @override
  String get gitUiMixed => 'Misto';

  @override
  String get gitUiHard => 'Rígido';

  @override
  String get gitUiKeep => 'Preservar';

  @override
  String get gitUiCreate => 'Criar';

  @override
  String get gitUiApplyStash => 'Aplicar stash';

  @override
  String get gitUiPopStash => 'Aplicar stash e remover se tiver êxito';

  @override
  String get gitUiDropStashAction => 'Eliminar stash';

  @override
  String get gitUiEditedResult => 'Resultado editado';

  @override
  String get gitUiLeftContent => 'Conteúdo esquerdo';

  @override
  String get gitUiRightContent => 'Conteúdo direito';

  @override
  String get gitUiDeletePath => 'Excluir o caminho';

  @override
  String get gitUiSubmoduleCommit => 'Submódulo de commit';

  @override
  String get gitUiPresentContent => 'Conteúdo disponível';

  @override
  String get gitUiAbsentContent => 'Ausência';

  @override
  String get gitUiBinaryContent => 'Conteúdo binário';

  @override
  String get gitUiTooLargeContent => 'O conteúdo excede o limite de exibição';

  @override
  String get gitUiUnavailableContent => 'Conteúdo não disponível';

  @override
  String get gitUiGitlinkContent => 'Ponto de submódulo';

  @override
  String get gitUiSymlinkContent => 'Ligação simbólica';

  @override
  String get gitUiNoOperation => 'Nenhuma operação';

  @override
  String get gitUiCherryPickOperation => 'Cherry-pick';

  @override
  String get gitUiRevertOperation => 'Reverter';

  @override
  String get gitUiApplyMailboxOperation => 'Aplicar os patches';

  @override
  String get gitUiSquashOperation => 'fusão de squash';

  @override
  String get gitUiUnmergedOperation => 'Índice não fundido';

  @override
  String get gitUiWaitingForPromptPhase => 'Aguardando a sua resposta';

  @override
  String get gitUiStoppedPhase => 'Pára para revisão';

  @override
  String get gitUiCompletedPhase => 'Concluído';

  @override
  String get gitUiFailedPhase => 'Falha';

  @override
  String get gitUiCancelledPhase => 'Cancelado';

  @override
  String get gitUiUncertainPhase => 'O resultado requer reconciliação';

  @override
  String gitUiStageVersion(String stage) {
    return 'Estágio de conflito $stage';
  }

  @override
  String get gitUiGitMergePreview => 'Git fusão pré-visualização';

  @override
  String get gitUiNormalizedWorking => 'Árvore de Trabalho · Git normalizado';

  @override
  String gitUiPercentValue(String value) {
    return '$value por cento';
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
  String get gitUiUtf8Bom => 'UTF-8 com marca de ordem de byte (BOM)';

  @override
  String get gitUiUtf8NoBom => 'UTF-8 sem marca de ordem de byte (BOM)';

  @override
  String get gitUiAddsBom =>
      'Esta edição adiciona uma marca UTF-8 byte-order (BOM) no início do arquivo.';

  @override
  String get gitUiRemovesBom =>
      'Esta edição remove a marca UTF-8 byte-order (BOM) do início do arquivo.';

  @override
  String get gitUiNoLineTerminators => 'Sem terminadores de linha';

  @override
  String gitUiLineEndings(String format) {
    return 'Finais de linha $format';
  }

  @override
  String gitUiMixedLineEndings(String formats) {
    return 'Finais de linhas mistas ($formats)';
  }

  @override
  String gitUiNoFinalLf(String format) {
    return '$format · sem LF final';
  }

  @override
  String gitUiLineEndingChange(String before, String after) {
    return 'O formato de terminação de linha muda de $before para $after. O texto da área de transferência pode usar terminações de linha diferentes do arquivo original.';
  }

  @override
  String get gitUiGitFailure =>
      'A operação do Git falhou, revise os diagnósticos abaixo.';

  @override
  String get gitUiAbortInline => 'Abortar';

  @override
  String get gitUiSkipInline => 'Ignorar';

  @override
  String get gitUiQuitInline => 'parar';

  @override
  String get gitUiMergeInline => 'Mesclar';

  @override
  String get gitUiRebaseInline => 'Rebase';

  @override
  String get gitUiCherryPickInline => 'Cherry-pick';

  @override
  String get gitUiRevertInline => 'Reverter';

  @override
  String get gitUiApplyMailboxInline => 'AplicarCaixa de Correio';

  @override
  String get gitUiSquashInline => 'Combinar';

  @override
  String get gitUiUnmergedInline => 'não fundidos';

  @override
  String get gitHostFetch => 'Buscar';

  @override
  String get gitHostRefreshGitStatus => 'Actualizar o estado do Git';

  @override
  String get gitHostCommitStaged => 'Compromisso encenado';

  @override
  String get gitHostGitBranches => 'Raízes de gítalo';

  @override
  String get gitHostReviewPush => 'Revisar o empurrão';

  @override
  String get gitHostGit => 'Git';

  @override
  String get gitHostGitOperationsApplyToThisEntireRepositoryAndMay =>
      'As operações Git aplicam-se a todo este repositório e podem executar seus ganchos configurados, filtros, credenciais e ferramentas de assinatura.';

  @override
  String get gitHostContentUnavailable => 'Conteúdo indisponível';

  @override
  String get gitHostInitializeRepository => 'Iniciar o repositório';

  @override
  String get gitHostCloneRepository => 'Clonar repositório';

  @override
  String get gitHostInitializeHere => 'Inicie aqui...';

  @override
  String get gitHostCloneRepository2 => 'Clonar repositório…';

  @override
  String get gitHostGitLog => 'Histórico do Git';

  @override
  String get gitUiAbsentPlaceholder => '(ausente)';

  @override
  String get gitUiUnborn => 'não-nascidos';

  @override
  String gitUiRebasedHistoryRevision(String revision) {
    return 'Histórico com nova base · $revision';
  }

  @override
  String gitUiCurrentHistoryRevision(String revision) {
    return 'Histórico atual · $revision';
  }

  @override
  String gitUiReplayedCommitRevision(String revision) {
    return 'Commit reaplicado · $revision';
  }

  @override
  String gitUiIncomingContentRevision(String revision) {
    return 'Conteúdo recebido · $revision';
  }

  @override
  String get gitUiContentConflict => 'Conflito de conteúdo';

  @override
  String get gitUiSubmoduleConflict => 'Conflito de submódulos';

  @override
  String get gitUiSymlinkConflict => 'Conflito de ligações simbólicas';

  @override
  String get gitUiAddAddConflict => 'Adicionado em ambos os lados';

  @override
  String get gitUiModifyDeleteConflict =>
      'Modificado/suprimido ou renomeado/suprimido';

  @override
  String gitUiConflictIdentity(String path, String kind) {
    return '$path · $kind';
  }

  @override
  String get gitUiDiscardUnsavedIndexDraft =>
      'Descartar o rascunho do índice não salvo?';

  @override
  String get gitUiClosingTheIndexEditorDiscardsOnlyItsDraft =>
      'Fechar o editor do índice descarta apenas o rascunho. O índice e o arquivo de trabalho permanecem inalterados.';

  @override
  String get gitUiDiscardIndexDraft => 'Descartar rascunho do índice';

  @override
  String get gitUiDiscardUnsavedConflictDraft =>
      'Descartar o resultado do conflito não salvo?';

  @override
  String get gitUiClosingTheConflictEditorDiscardsOnlyItsDraft =>
      'Fechar o editor de conflitos descarta apenas o rascunho do resultado não salvo. O conteúdo de trabalho salvo e o índice permanecem inalterados.';

  @override
  String get gitUiDiscardConflictDraft => 'Descartar rascunho do conflito';

  @override
  String get gitUiOpenCurrentFile => 'Abrir arquivo atual';

  @override
  String get gitUiPreviousSearchMatch => 'Resultado anterior';

  @override
  String get gitUiNextSearchMatch => 'Próximo resultado';

  @override
  String gitUiSearchMatchPosition(String current, String count) {
    return 'Resultado $current de $count';
  }

  @override
  String gitUiSearchResultsLimited(String count) {
    return 'São exibidos os primeiros $count resultados. Refine a pesquisa para revisar mais.';
  }

  @override
  String get gitUiRevealRevisionWithoutFilters => 'Mostrar revisão sem filtros';

  @override
  String get gitUiRestoreHistoryFilters => 'Restaurar filtros do histórico';

  @override
  String get gitUiShowAllAffectedFiles => 'Mostrar todos os arquivos afetados';

  @override
  String get gitUiGraphLanes => 'Faixas do grafo';

  @override
  String gitUiRebaseArg0OntoArg1(String arg0, String arg1) {
    return 'Rebasear $arg0 sobre $arg1';
  }

  @override
  String get gitUiChangedLine => 'Linha alterada';

  @override
  String get gitUiCopyHeadRegionIntoIndexDraft =>
      'Copiar região de HEAD para o rascunho do índice';

  @override
  String get gitUiCopyWorkingRegionIntoIndexDraft =>
      'Copiar região de trabalho para o rascunho do índice';

  @override
  String get gitUiUpdatingConflictRegions => 'Atualizando regiões de conflito';

  @override
  String gitUiRemainingConflictMarkers(String count) {
    return 'Regiões do resultado com marcadores de conflito: $count';
  }

  @override
  String get gitUiIgnoreLeftRegion => 'Ignorar sugestão da esquerda';

  @override
  String get gitUiIgnoreRightRegion => 'Ignorar sugestão da direita';

  @override
  String get gitUiIndexAppliedNewerDraftPreserved =>
      'O rascunho enviado foi gravado no índice. O texto mais recente continua neste editor. Recarregue e revise as versões atuais antes de aplicá-lo.';

  @override
  String get gitUiNewerConflictDraftRetained =>
      'O resultado enviado foi salvo. Seu rascunho de resultado mais recente ainda não foi salvo.';

  @override
  String get gitUiNoFileHistoryForThisPathAndRevision =>
      'Não há histórico de arquivos disponível para este caminho e revisão.';

  @override
  String get gitUiReviewSavedIndexAndKeepDraft =>
      'Revisar o índice salvo e manter o rascunho';

  @override
  String get gitUiIndexSourcesChangedSinceApply =>
      'O índice salvo ou suas origens foram alterados. O rascunho mais recente foi mantido; revise essas alterações separadamente antes de aplicá-lo.';
}
