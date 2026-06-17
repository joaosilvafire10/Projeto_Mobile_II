import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/ticket_model.dart';
import '../models/message_model.dart';
import '../services/ai_service.dart';
import '../services/ticket_service.dart';

class ChatProvider extends ChangeNotifier {
  final List<MessageModel> _messages = [];
  final AIService _aiService = AIService();
  final TicketService _ticketService = TicketService();

  bool _isAiTyping = false;
  bool _isResolved = false;
  bool _ticketCreated = false;
  TicketModel? _lastCreatedTicket;
  static const _uuid = Uuid();

  List<MessageModel> get messages => List.unmodifiable(_messages);
  bool get isAiTyping => _isAiTyping;
  bool get isResolved => _isResolved;
  bool get ticketCreated => _ticketCreated;
  TicketModel? get lastCreatedTicket => _lastCreatedTicket;
  AIService get aiService => _aiService;

  String? _selectedCategoryName;
  String? _selectedActivityName;

  String? get selectedCategoryName => _selectedCategoryName;
  String? get selectedActivityName => _selectedActivityName;

  void startConversation({String? categoryName, String? activityName,
      String? categoryId, String? activityId}) {
    _messages.clear();
    _aiService.reset();
    _isResolved = false;
    _ticketCreated = false;
    _lastCreatedTicket = null;
    _selectedCategoryName = categoryName;
    _selectedActivityName = activityName;
    _aiService.setScope(categoryName, activityName,
        categoryId: categoryId, activityId: activityId);
    _messages.add(AIService.getWelcomeMessage(
      categoryName: categoryName,
      activityName: activityName,
    ));
    notifyListeners();
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    final userMessage = MessageModel(
      id: _uuid.v4(),
      content: content.trim(),
      sender: MessageSender.user,
    );
    _messages.add(userMessage);
    _isAiTyping = true;
    notifyListeners();

    // Chama o backend (Gemini via /api/ai/triage)
    final aiResponse = await _aiService.processMessage(content.trim());
    _isAiTyping = false;
    _messages.add(aiResponse);

    if (_aiService.isResolved) {
      _isResolved = true;
    }
    // Se o backend criou o ticket automaticamente, marca como criado
    // para evitar exibir o botão "Abrir Chamado" que criaria um segundo
    if (_aiService.ticketAutoCreated) {
      _ticketCreated = true;
    }

    notifyListeners();
  }

  /// Cria o ticket via API REST (POST /api/tickets) e atualiza o estado local.
  Future<TicketModel?> createTicket(String userId, String userName) async {
    final firstUserMessage = _messages.firstWhere(
      (m) => m.sender == MessageSender.user,
      orElse: () => MessageModel(
        id: '0',
        content: 'Sem descrição',
        sender: MessageSender.user,
      ),
    );

    final String finalCategory = _selectedCategoryName ??
        _aiService.identifiedCategory ??
        'Suporte Geral';
    final String titlePrefix = _selectedActivityName != null
        ? '[$finalCategory - $_selectedActivityName]'
        : '[$finalCategory]';
    final String title =
        '$titlePrefix ${firstUserMessage.content.length > 30 ? '${firstUserMessage.content.substring(0, 30)}...' : firstUserMessage.content}';
    final String aiSummary = _aiService.generateSummary(_messages);
    final String priorityApi =
        _aiService.identifiedPriority == TicketPriority.high
            ? 'ALTA'
            : _aiService.identifiedPriority == TicketPriority.critical
                ? 'CRITICA'
                : _aiService.identifiedPriority == TicketPriority.low
                    ? 'BAIXA'
                    : 'MEDIA';

    try {
      // Garante que o departamento é um dos 3 valores válidos do banco
      const validDepartments = ['TI', 'FINANCEIRO', 'CONTABILIDADE'];
      final rawDept = _aiService.identifiedDepartment ?? 'TI';
      final department = validDepartments.contains(rawDept) ? rawDept : 'TI';

      // Usa os IDs reais de categoria e atividade selecionados pelo usuário
      final categoryId = _aiService.selectedCategoryId;
      final activityId = _aiService.selectedActivityId;

      // POST à API REST — cria o chamado no servidor
      final ticket = await _ticketService.create(
        title: title,
        description: firstUserMessage.content,
        priority: priorityApi,
        department: department,
        categoryId: categoryId,
        activityId: activityId,
        aiSummary: aiSummary,
      );

      _lastCreatedTicket = ticket;
      _ticketCreated = true;

      _messages.add(MessageModel(
        id: _uuid.v4(),
        content: '🎫 **Chamado criado com sucesso!**\n\n'
            '📋 **Nº:** ${ticket.id.substring(0, 8).toUpperCase()}\n'
            '📂 **Categoria:** ${ticket.category}\n'
            '📊 **Prioridade:** $priorityApi\n\n'
            'Sua equipe técnica receberá o chamado com todo o contexto desta conversa. '
            'Você pode acompanhar o status na aba **"Meus Chamados"**.',
        sender: MessageSender.system,
      ));

      notifyListeners();
      return ticket;
    } catch (e) {
      // Fallback: cria localmente caso a API falhe
      _messages.add(MessageModel(
        id: _uuid.v4(),
        content: '⚠️ Não foi possível criar o chamado no servidor. '
            'Verifique sua conexão e tente novamente.',
        sender: MessageSender.system,
      ));
      notifyListeners();
      return null;
    }
  }

  void markAsResolved() {
    _isResolved = true;
    _messages.add(MessageModel(
      id: _uuid.v4(),
      content: '✅ **Atendimento encerrado!**\n\n'
          'Que bom que consegui ajudar! A solução foi registrada em nosso sistema.\n\n'
          '⭐ Obrigado por utilizar o atendimento inteligente!',
      sender: MessageSender.system,
    ));
    notifyListeners();
  }
}
