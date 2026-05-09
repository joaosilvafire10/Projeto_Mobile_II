import 'dart:math';
import '../models/message_model.dart';
import '../models/ticket_model.dart';
import 'package:uuid/uuid.dart';

/// Serviço de IA simulado que gerencia o fluxo inteligente de atendimento.
/// Em produção, isso se conectaria a uma API real de IA (GPT, Gemini, etc).
class AIService {
  static const _uuid = Uuid();

  // Base de conhecimento para resolução automática
  static final Map<String, Map<String, dynamic>> _knowledgeBase = {
    'senha': {
      'keywords': ['senha', 'password', 'login', 'acesso', 'entrar', 'esqueci', 'redefinir', 'resetar'],
      'category': 'Acesso e Autenticação',
      'department': 'TI - Suporte',
      'priority': TicketPriority.medium,
      'questions': [
        'Qual sistema você está tentando acessar?',
        'Há quanto tempo está com esse problema?',
        'Você já tentou usar a opção "Esqueci minha senha"?',
      ],
      'solutions': [
        '🔐 **Redefinição de Senha**\n\nPara redefinir sua senha, siga estes passos:\n\n1. Acesse a tela de login do sistema\n2. Clique em "Esqueci minha senha"\n3. Informe seu e-mail corporativo\n4. Verifique sua caixa de entrada (inclusive spam)\n5. Clique no link recebido e crie uma nova senha\n\n💡 **Dica:** A nova senha deve ter no mínimo 8 caracteres, incluindo letras maiúsculas, minúsculas e números.',
      ],
      'canResolve': true,
    },
    'internet': {
      'keywords': ['internet', 'wifi', 'rede', 'conexão', 'conectar', 'lento', 'desconectando', 'sem acesso'],
      'category': 'Infraestrutura de Rede',
      'department': 'TI - Infraestrutura',
      'priority': TicketPriority.high,
      'questions': [
        'O problema é com Wi-Fi ou rede cabeada?',
        'Outros colegas do mesmo setor estão com o mesmo problema?',
        'Você já tentou reiniciar o roteador/modem?',
      ],
      'solutions': [
        '🌐 **Problemas de Conexão**\n\nTente os seguintes passos:\n\n1. Desconecte e reconecte à rede Wi-Fi\n2. Esqueça a rede e conecte novamente\n3. Reinicie seu dispositivo\n4. Verifique se o modo avião está desativado\n5. Tente se conectar a outra rede para testar\n\n⚡ Se o problema persistir, pode ser uma questão de infraestrutura que precisa de análise da equipe técnica.',
      ],
      'canResolve': true,
    },
    'email': {
      'keywords': ['email', 'e-mail', 'outlook', 'gmail', 'enviar', 'receber', 'caixa', 'mensagem'],
      'category': 'Comunicação e E-mail',
      'department': 'TI - Suporte',
      'priority': TicketPriority.medium,
      'questions': [
        'Qual cliente de e-mail você está utilizando?',
        'Consegue acessar o e-mail pelo navegador (webmail)?',
        'A mensagem de erro aparece ao enviar ou receber?',
      ],
      'solutions': [
        '📧 **Problemas com E-mail**\n\n1. Verifique sua conexão com a internet\n2. Tente acessar via webmail (navegador)\n3. Limpe o cache do aplicativo de e-mail\n4. Verifique se o armazenamento não está cheio\n5. Reconfigure a conta removendo e adicionando novamente\n\n📌 Caso use Outlook, tente reparar o perfil em: Painel de Controle > Email > Mostrar Perfis > Reparar.',
      ],
      'canResolve': true,
    },
    'impressora': {
      'keywords': ['impressora', 'imprimir', 'printer', 'impressão', 'toner', 'papel', 'scanner'],
      'category': 'Periféricos e Impressão',
      'department': 'TI - Suporte',
      'priority': TicketPriority.low,
      'questions': [
        'Qual é o modelo e localização da impressora?',
        'A impressora aparece como disponível no seu computador?',
        'Aparece alguma mensagem de erro específica?',
      ],
      'solutions': [
        '🖨️ **Problemas com Impressora**\n\n1. Verifique se a impressora está ligada e conectada\n2. Reinicie a fila de impressão:\n   - Windows: Serviços > Spooler de Impressão > Reiniciar\n3. Remova trabalhos travados na fila\n4. Verifique níveis de toner e papel\n5. Tente imprimir uma página de teste\n\n🔧 Se o problema persistir, reinstale o driver da impressora.',
      ],
      'canResolve': true,
    },
    'software': {
      'keywords': ['instalar', 'programa', 'software', 'aplicativo', 'app', 'atualizar', 'erro', 'travando', 'crashando', 'bug'],
      'category': 'Software e Aplicações',
      'department': 'TI - Desenvolvimento',
      'priority': TicketPriority.medium,
      'questions': [
        'Qual software/aplicativo está apresentando o problema?',
        'Qual é a versão do software?',
        'O erro ocorre ao abrir o programa ou durante o uso?',
        'Aparece alguma mensagem de erro? Se sim, qual?',
      ],
      'solutions': [],
      'canResolve': false,
    },
    'hardware': {
      'keywords': ['computador', 'notebook', 'tela', 'monitor', 'teclado', 'mouse', 'lento', 'travando', 'reiniciando', 'desligando'],
      'category': 'Hardware e Equipamentos',
      'department': 'TI - Infraestrutura',
      'priority': TicketPriority.high,
      'questions': [
        'Qual equipamento está com problema?',
        'Desde quando o problema começou?',
        'O equipamento faz algum barulho incomum?',
        'Houve alguma queda ou impacto recente?',
      ],
      'solutions': [],
      'canResolve': false,
    },
    'acesso': {
      'keywords': ['permissão', 'acesso', 'autorização', 'bloqueado', 'restrito', 'liberar', 'pasta', 'compartilhamento'],
      'category': 'Gestão de Acessos',
      'department': 'TI - Segurança',
      'priority': TicketPriority.medium,
      'questions': [
        'Qual recurso/sistema você precisa acessar?',
        'Você já teve acesso anteriormente?',
        'Seu gestor já autorizou o acesso?',
      ],
      'solutions': [],
      'canResolve': false,
    },
  };

  // Estado do fluxo de conversa
  int _currentStep = 0;
  String? _identifiedCategory;
  Map<String, dynamic>? _matchedKnowledge;
  final List<String> _collectedInfo = [];
  int _questionIndex = 0;
  bool _problemDescribed = false;
  bool _resolved = false;

  void reset() {
    _currentStep = 0;
    _identifiedCategory = null;
    _matchedKnowledge = null;
    _collectedInfo.clear();
    _questionIndex = 0;
    _problemDescribed = false;
    _resolved = false;
  }

  bool get isResolved => _resolved;
  String? get identifiedDepartment => _matchedKnowledge?['department'];
  String? get identifiedCategory => _matchedKnowledge?['category'] ?? _identifiedCategory;
  TicketPriority get identifiedPriority =>
      _matchedKnowledge?['priority'] ?? TicketPriority.medium;

  /// Processa a mensagem do usuário e retorna a resposta da IA
  Future<MessageModel> processMessage(String userMessage) async {
    // Simula delay de processamento
    await Future.delayed(Duration(milliseconds: 800 + Random().nextInt(1200)));

    String response;

    if (!_problemDescribed) {
      // Primeira interação: analisar o problema descrito
      _problemDescribed = true;
      _analyzeMessage(userMessage);

      if (_matchedKnowledge != null) {
        response = _buildAnalysisResponse();
      } else {
        _identifiedCategory = 'Suporte Geral';
        response = '🔍 Entendi seu problema. Preciso de mais algumas informações para ajudá-lo melhor.\n\n'
            'Poderia me dizer:\n'
            '• Desde quando esse problema está acontecendo?\n'
            '• Com que frequência ele ocorre?\n'
            '• Já tentou alguma solução?';
        _currentStep = 2; // Pula para coleta de info
      }
    } else if (_matchedKnowledge != null && _canAutoResolve()) {
      // Tenta resolver automaticamente
      _resolved = true;
      response = _getAutoSolution();
    } else if (_hasMoreQuestions()) {
      // Coleta informações complementares
      _collectedInfo.add(userMessage);
      response = _getNextQuestion();
    } else {
      // Todas as informações coletadas - gerar resumo
      _collectedInfo.add(userMessage);
      response = _buildEscalationResponse();
    }

    _currentStep++;

    return MessageModel(
      id: _uuid.v4(),
      content: response,
      sender: MessageSender.ai,
    );
  }

  void _analyzeMessage(String message) {
    final lowerMessage = message.toLowerCase();

    for (final entry in _knowledgeBase.entries) {
      final keywords = entry.value['keywords'] as List<String>;
      for (final keyword in keywords) {
        if (lowerMessage.contains(keyword)) {
          _matchedKnowledge = entry.value;
          return;
        }
      }
    }
  }

  String _buildAnalysisResponse() {
    final category = _matchedKnowledge!['category'];
    final canResolve = _matchedKnowledge!['canResolve'] as bool;

    if (canResolve) {
      return '✅ **Problema identificado!**\n\n'
          '📂 **Categoria:** $category\n\n'
          'Encontrei uma possível solução para o seu problema. Gostaria de tentar?\n\n'
          'Responda **"sim"** para ver a solução ou descreva mais detalhes se o problema for diferente.';
    } else {
      return '🔍 **Problema identificado!**\n\n'
          '📂 **Categoria:** $category\n\n'
          'Para esse tipo de problema, preciso coletar algumas informações antes de encaminhar para a equipe técnica.\n\n'
          '${_getNextQuestionText()}';
    }
  }

  bool _canAutoResolve() {
    if (_matchedKnowledge == null) return false;
    final canResolve = _matchedKnowledge!['canResolve'] as bool;
    final solutions = _matchedKnowledge!['solutions'] as List<String>;
    return canResolve && solutions.isNotEmpty && _currentStep <= 2;
  }

  String _getAutoSolution() {
    final solutions = _matchedKnowledge!['solutions'] as List<String>;
    return '${solutions.first}\n\n'
        '---\n\n'
        '✅ **Problema resolvido?**\n\n'
        'Se essa solução resolveu seu problema, você pode encerrar o atendimento.\n'
        'Se o problema persistir, clique no botão **"Abrir Chamado"** para que nossa equipe técnica analise seu caso.';
  }

  bool _hasMoreQuestions() {
    if (_matchedKnowledge == null) return _currentStep < 4;
    final questions = _matchedKnowledge!['questions'] as List<String>;
    return _questionIndex < questions.length;
  }

  String _getNextQuestion() {
    _questionIndex++;
    return _getNextQuestionText();
  }

  String _getNextQuestionText() {
    if (_matchedKnowledge != null) {
      final questions = _matchedKnowledge!['questions'] as List<String>;
      if (_questionIndex < questions.length) {
        return '❓ ${questions[_questionIndex]}';
      }
    }
    // Perguntas genéricas
    final genericQuestions = [
      '❓ Poderia descrever com mais detalhes o que acontece?',
      '❓ Esse problema afeta outros colegas do seu setor?',
      '❓ Qual é a urgência desta solicitação para o seu trabalho?',
    ];
    final idx = _currentStep - 2;
    if (idx >= 0 && idx < genericQuestions.length) {
      return genericQuestions[idx];
    }
    return _buildEscalationResponse();
  }

  String _buildEscalationResponse() {
    final dept = _matchedKnowledge?['department'] ?? 'TI - Suporte Geral';
    final category = _matchedKnowledge?['category'] ?? 'Suporte Geral';

    return '📋 **Resumo do Atendimento**\n\n'
        'Coletei todas as informações necessárias.\n\n'
        '📂 **Categoria:** $category\n'
        '🏢 **Departamento:** $dept\n'
        '📊 **Informações coletadas:** ${_collectedInfo.length} respostas\n\n'
        '---\n\n'
        'Infelizmente não consegui resolver seu problema automaticamente. '
        'Recomendo a abertura de um chamado técnico para que a equipe especializada possa te ajudar.\n\n'
        'Clique no botão **"Abrir Chamado"** abaixo para criar automaticamente um chamado com todo o histórico desta conversa.';
  }

  /// Gera o resumo da conversa para anexar ao chamado
  String generateSummary(List<MessageModel> messages) {
    final dept = _matchedKnowledge?['department'] ?? 'TI - Suporte Geral';
    final category = _matchedKnowledge?['category'] ?? 'Suporte Geral';

    final buffer = StringBuffer();
    buffer.writeln('═══ RESUMO GERADO PELA IA ═══');
    buffer.writeln('');
    buffer.writeln('📂 Categoria: $category');
    buffer.writeln('🏢 Departamento Sugerido: $dept');
    buffer.writeln('📊 Prioridade: ${identifiedPriority.name.toUpperCase()}');
    buffer.writeln('💬 Total de mensagens: ${messages.length}');
    buffer.writeln('');
    buffer.writeln('─── Descrição do Problema ───');

    for (final msg in messages) {
      if (msg.sender == MessageSender.user) {
        buffer.writeln('• ${msg.content}');
      }
    }

    buffer.writeln('');
    buffer.writeln('─── Informações Coletadas ───');
    for (int i = 0; i < _collectedInfo.length; i++) {
      buffer.writeln('${i + 1}. ${_collectedInfo[i]}');
    }

    return buffer.toString();
  }

  /// Gera título automático para o chamado
  String generateTitle(String firstMessage) {
    final category = _matchedKnowledge?['category'] ?? 'Suporte';
    final truncated = firstMessage.length > 40
        ? '${firstMessage.substring(0, 40)}...'
        : firstMessage;
    return '[$category] $truncated';
  }

  /// Mensagem de boas-vindas da IA
  static MessageModel getWelcomeMessage() {
    return MessageModel(
      id: _uuid.v4(),
      content: '👋 Olá! Sou o **Assistente Virtual** do suporte técnico.\n\n'
          'Estou aqui para ajudar a resolver seu problema de forma rápida e eficiente.\n\n'
          '💬 **Descreva seu problema** com o máximo de detalhes possível e eu vou:\n\n'
          '• 🔍 Analisar e identificar a categoria\n'
          '• 💡 Tentar uma solução automática\n'
          '• 📋 Coletar informações técnicas\n'
          '• 🎯 Direcionar ao setor correto, se necessário\n\n'
          '_Como posso ajudá-lo hoje?_',
      sender: MessageSender.ai,
    );
  }
}
