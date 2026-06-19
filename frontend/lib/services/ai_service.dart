import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/message_model.dart';
import '../models/ticket_model.dart';
import '../services/api_service.dart';
import 'package:uuid/uuid.dart';

/// Serviço de IA — chama o endpoint real do backend (/api/ai/triage).
/// O backend usa o Google Gemini para processar as mensagens.
/// Possui fallback local caso o serviço esteja indisponível.
class AIService {
  static const _uuid = Uuid();
  final ApiService _api = ApiService();

  // Histórico de conversa para envio ao backend
  final List<Map<String, String>> _conversationHistory = [];

  // Estado da conversa
  bool _resolved = false;
  String? _identifiedCategory;
  String? _identifiedDepartment;
  TicketPriority _identifiedPriority = TicketPriority.medium;
  String? _aiSummary;

  // Escopo selecionado pelo usuário
  String? selectedCategoryName;
  String? selectedActivityName;
  String? selectedCategoryId;
  String? selectedActivityId;

  // Flag: o backend já criou o ticket automaticamente via IA
  bool _ticketAutoCreated = false;
  bool get ticketAutoCreated => _ticketAutoCreated;

  bool get isResolved => _resolved;
  String? get identifiedDepartment => _identifiedDepartment;
  String? get identifiedCategory => _identifiedCategory;
  TicketPriority get identifiedPriority => _identifiedPriority;
  String? get aiSummary => _aiSummary;

  void reset() {
    _conversationHistory.clear();
    _resolved = false;
    _identifiedCategory = null;
    _identifiedDepartment = null;
    _identifiedPriority = TicketPriority.medium;
    _aiSummary = null;
    selectedCategoryName = null;
    selectedActivityName = null;
    selectedCategoryId = null;
    selectedActivityId = null;
    _ticketAutoCreated = false;
  }

  void setScope(String? categoryName, String? activityName,
      {String? categoryId, String? activityId}) {
    selectedCategoryName = categoryName;
    selectedActivityName = activityName;
    selectedCategoryId = categoryId;
    selectedActivityId = activityId;
    _identifiedCategory = categoryName;
    
    if (categoryName != null) {
      final catLower = categoryName.toLowerCase();
      if (catLower.contains('financeiro')) {
        _identifiedDepartment = 'FINANCEIRO';
      } else if (catLower.contains('contabilidade')) {
        _identifiedDepartment = 'CONTABILIDADE';
      } else {
        _identifiedDepartment = 'TI';
      }
    }
  }

  /// Envia mensagem ao backend e retorna a resposta da IA.
  /// Em caso de falha, usa fallback local com mensagem amigável.
  Future<MessageModel> processMessage(String userMessage) async {
    // Adiciona mensagem ao histórico local
    _conversationHistory.add({'role': 'user', 'content': userMessage});

    try {
      final response = await _api.dio.post(
        '/ai/triage',
        data: {
          'message': userMessage,
          'conversationHistory': _conversationHistory,
          if (selectedCategoryName != null) 'categoryName': selectedCategoryName,
          if (selectedActivityName != null) 'activityName': selectedActivityName,
          if (selectedCategoryId != null) 'categoryId': selectedCategoryId,
          if (selectedActivityId != null) 'activityId': selectedActivityId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        final aiText = data['message'] as String? ?? '';
        final responseType = data['type'] as String? ?? 'response';

        // Registra metadados identificados pela IA
        if (data['category'] != null) _identifiedCategory = data['category'] as String;
        if (data['department'] != null) {
          final dept = (data['department'] as String).toUpperCase();
          const valid = ['TI', 'FINANCEIRO', 'CONTABILIDADE'];
          _identifiedDepartment = valid.contains(dept) ? dept : 'TI';
        }
        if (data['priority'] != null) {
          final p = (data['priority'] as String? ?? '').toUpperCase();
          _identifiedPriority = p == 'ALTA' || p == 'HIGH'
              ? TicketPriority.high
              : p == 'CRITICA' || p == 'CRITICAL'
                  ? TicketPriority.critical
                  : p == 'BAIXA' || p == 'LOW'
                      ? TicketPriority.low
                      : TicketPriority.medium;
        }

        // Adiciona resposta ao histórico
        _conversationHistory.add({'role': 'ai', 'content': aiText});

        // Se a IA criou um ticket automaticamente
        if (responseType == 'ticket_created') {
          _resolved = true;
          _ticketAutoCreated = true; // backend já criou — não criar de novo
          if (data['ticket'] != null) {
            _aiSummary = (data['ticket'] as Map<String, dynamic>)['aiSummary'] as String?;
          }
        }

        return MessageModel(
          id: _uuid.v4(),
          content: aiText,
          sender: MessageSender.ai,
        );
      }
    } on DioException catch (e) {
      debugPrint('AIService: Erro na chamada à API — ${e.message}');
      return _fallbackMessage(e);
    } catch (e) {
      debugPrint('AIService: Erro inesperado — $e');
    }

    return _fallbackMessage(null);
  }

  /// Gera um resumo da conversa para o chamado
  String generateSummary(List<MessageModel> messages) {
    if (_aiSummary != null) return _aiSummary!;

    final buffer = StringBuffer();
    buffer.writeln('═══ RESUMO GERADO PELA IA (Gemini) ═══');
    buffer.writeln('');
    buffer.writeln('📂 Categoria: ${_identifiedCategory ?? "Suporte Geral"}');
    buffer.writeln('🏢 Departamento: ${_identifiedDepartment ?? "TI - Suporte"}');
    buffer.writeln('📊 Prioridade: ${_identifiedPriority.name.toUpperCase()}');
    buffer.writeln('💬 Total de mensagens: ${messages.length}');
    buffer.writeln('');
    buffer.writeln('─── Descrição do Problema ───');
    for (final msg in messages) {
      if (msg.sender == MessageSender.user) {
        buffer.writeln('• ${msg.content}');
      }
    }
    return buffer.toString();
  }

  /// Gera título automático para o chamado
  String generateTitle(String firstMessage) {
    final category = _identifiedCategory ?? 'Suporte';
    final truncated = firstMessage.length > 40
        ? '${firstMessage.substring(0, 40)}...'
        : firstMessage;
    return '[$category] $truncated';
  }

  /// Mensagem de boas-vindas
  static MessageModel getWelcomeMessage({String? categoryName, String? activityName}) {
    String scopeText = '';
    if (categoryName != null && activityName != null) {
      scopeText = 'Você selecionou **$categoryName → $activityName**.\n\n';
    }

    return MessageModel(
      id: _uuid.v4(),
      content: '👋 Olá! Sou o **Assistente Gemini** do suporte técnico.\n\n'
          '$scopeText'
          'Estou aqui para ajudar a resolver seu problema de forma rápida.\n\n'
          '💬 **Descreva seu problema** com o máximo de detalhes e eu vou:\n\n'
          '• 🔍 Analisar e identificar a categoria\n'
          '• 💡 Tentar uma solução automática\n'
          '• 📋 Coletar informações técnicas\n'
          '• 🎯 Criar um chamado se necessário\n\n'
          '_Como posso ajudá-lo hoje?_',
      sender: MessageSender.ai,
    );
  }

  // ── Fallback quando a API de IA está indisponível ──────────────────────────

  MessageModel _fallbackMessage(DioException? e) {
    String msg;
    if (e?.type == DioExceptionType.connectionError ||
        e?.type == DioExceptionType.connectionTimeout) {
      msg = '⚠️ **Serviço de IA temporariamente indisponível.**\n\n'
          'Não foi possível conectar ao servidor. Verifique sua internet.\n\n'
          'Você ainda pode **abrir um chamado manual** clicando no botão abaixo.';
    } else {
      msg = '⚠️ **Assistente IA indisponível no momento.**\n\n'
          'Nosso serviço de inteligência artificial está temporariamente fora do ar.\n\n'
          '📋 Você pode abrir um chamado diretamente — clique em **"Abrir Chamado"** '
          'para que a equipe técnica receba sua solicitação.';
    }

    return MessageModel(
      id: _uuid.v4(),
      content: msg,
      sender: MessageSender.system,
    );
  }
}


