import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/ticket_model.dart';
import '../models/message_model.dart';
import '../services/ai_service.dart';

class ChatProvider extends ChangeNotifier {
  final List<MessageModel> _messages = [];
  final AIService _aiService = AIService();
  bool _isAiTyping = false;
  bool _isResolved = false;
  bool _ticketCreated = false;
  static const _uuid = Uuid();

  List<MessageModel> get messages => List.unmodifiable(_messages);
  bool get isAiTyping => _isAiTyping;
  bool get isResolved => _isResolved;
  bool get ticketCreated => _ticketCreated;
  AIService get aiService => _aiService;

  String? _selectedCategoryName;
  String? _selectedActivityName;

  String? get selectedCategoryName => _selectedCategoryName;
  String? get selectedActivityName => _selectedActivityName;

  void startConversation({String? categoryName, String? activityName}) {
    _messages.clear();
    _aiService.reset();
    _isResolved = false;
    _ticketCreated = false;
    _selectedCategoryName = categoryName;
    _selectedActivityName = activityName;
    _aiService.setScope(categoryName, activityName);
    _messages.add(AIService.getWelcomeMessage(
      categoryName: categoryName,
      activityName: activityName,
    ));
    notifyListeners();
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    // Adiciona mensagem do usuário
    final userMessage = MessageModel(
      id: _uuid.v4(),
      content: content.trim(),
      sender: MessageSender.user,
    );
    _messages.add(userMessage);
    _isAiTyping = true;
    notifyListeners();

    // Processa com a IA
    final aiResponse = await _aiService.processMessage(content.trim());
    _isAiTyping = false;
    _messages.add(aiResponse);

    if (_aiService.isResolved) {
      _isResolved = true;
    }

    notifyListeners();
  }

  TicketModel createTicket(String userId, String userName) {
    final firstUserMessage = _messages.firstWhere(
      (m) => m.sender == MessageSender.user,
      orElse: () => MessageModel(
        id: '0',
        content: 'Sem descrição',
        sender: MessageSender.user,
      ),
    );

    String finalCategory = _selectedCategoryName ?? _aiService.identifiedCategory ?? 'Suporte Geral';
    String titlePrefix = _selectedActivityName != null ? '[$finalCategory - $_selectedActivityName]' : '[$finalCategory]';
    
    final ticket = TicketModel(
      id: _uuid.v4(),
      title: '$titlePrefix ${firstUserMessage.content.length > 30 ? firstUserMessage.content.substring(0, 30) + '...' : firstUserMessage.content}',
      description: firstUserMessage.content,
      userId: userId,
      userName: userName,
      department: _selectedCategoryName == 'Financeiro' 
          ? 'Financeiro' 
          : (_selectedCategoryName == 'Contabilidade' ? 'Contabilidade' : (_aiService.identifiedDepartment ?? 'TI - Suporte Geral')),
      priority: _aiService.identifiedPriority,
      category: finalCategory,
      chatHistory: List.from(_messages),
      aiSummary: _aiService.generateSummary(_messages),
    );

    _ticketCreated = true;

    // Adiciona mensagem do sistema confirmando
    _messages.add(MessageModel(
      id: _uuid.v4(),
      content: '🎫 **Chamado criado com sucesso!**\n\n'
          '📋 **Nº:** ${ticket.id.substring(0, 8).toUpperCase()}\n'
          '📂 **Categoria:** ${ticket.category}\n'
          '🏢 **Departamento:** ${ticket.department}\n'
          '📊 **Prioridade:** ${ticket.priority.name.toUpperCase()}\n\n'
          'Sua equipe técnica receberá o chamado com todo o contexto desta conversa. '
          'Você pode acompanhar o status na aba **"Meus Chamados"**.',
      sender: MessageSender.system,
    ));

    notifyListeners();
    return ticket;
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
