import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/ticket_model.dart';
import '../models/message_model.dart';
import '../services/ticket_service.dart';
import '../services/api_service.dart';

/// Provider de tickets — todas as operações passam pela API REST.
class TicketProvider extends ChangeNotifier {
  final TicketService _service = TicketService();
  final ApiService _api = ApiService();

  List<TicketModel> _tickets = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<TicketModel> get tickets => List.unmodifiable(_tickets);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ── Leitura ────────────────────────────────────────────────────────────────

  Future<void> fetchTickets() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _tickets = await _service.fetchAll();
    } on DioException catch (e) {
      _errorMessage = _dioError(e);
    } catch (e) {
      _errorMessage = 'Erro inesperado ao carregar chamados.';
    }

    _isLoading = false;
    notifyListeners();
  }

  TicketModel? getTicketById(String ticketId) {
    final index = _tickets.indexWhere((t) => t.id == ticketId);
    return index != -1 ? _tickets[index] : null;
  }

  List<TicketModel> getTicketsByUser(String userId) {
    return _tickets.where((t) => t.userId == userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<TicketModel> getTicketsByStatus(TicketStatus status) {
    return _tickets.where((t) => t.status == status).toList();
  }

  // ── Criação (Create) ───────────────────────────────────────────────────────

  /// Cria um ticket via POST e atualiza a lista local.
  Future<TicketModel?> addTicket({
    required String title,
    required String description,
    required String priority,   // formato API: BAIXA | MEDIA | ALTA | CRITICA
    String? categoryId,
    String? activityId,
    String? department,
    String? aiSummary,
  }) async {
    try {
      final ticket = await _service.create(
        title: title,
        description: description,
        priority: priority,
        categoryId: categoryId,
        activityId: activityId,
        department: department,
        aiSummary: aiSummary,
      );
      _tickets.insert(0, ticket);
      notifyListeners();
      return ticket;
    } on DioException catch (e) {
      _errorMessage = _dioError(e);
      notifyListeners();
      return null;
    }
  }

  // ── Edição (Update) ────────────────────────────────────────────────────────

  /// Atualiza status e prioridade via PUT e reflete na lista local.
  Future<bool> editTicket(
    String ticketId, {
    TicketStatus? status,
    TicketPriority? priority,
    String? title,
    String? description,
  }) async {
    try {
      final local = getTicketById(ticketId);
      final updated = await _service.update(
        ticketId,
        status: status != null
            ? TicketModel(
                id: '', title: '', description: '', userId: '', userName: '',
                department: '', status: status,
              ).statusApi
            : null,
        priority: priority != null
            ? TicketModel(
                id: '', title: '', description: '', userId: '', userName: '',
                department: '', priority: priority,
              ).priorityApi
            : null,
        title: title,
        description: description,
      );
      final index = _tickets.indexWhere((t) => t.id == ticketId);
      if (index != -1) {
        // Mantém chatHistory e comments locais (não retornados no PUT)
        _tickets[index] = updated.copyWith(
          chatHistory: local?.chatHistory,
          comments: local?.comments,
        );
      }
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _errorMessage = _dioError(e);
      notifyListeners();
      return false;
    }
  }

  /// Atribui o ticket para o analista autenticado via PUT e reflete na lista local.
  Future<bool> assignTicketToMe(String ticketId) async {
    try {
      final updated = await _service.assignToMe(ticketId);
      final index = _tickets.indexWhere((t) => t.id == ticketId);
      if (index != -1) {
        final local = _tickets[index];
        _tickets[index] = updated.copyWith(
          chatHistory: local.chatHistory,
          comments: local.comments,
        );
      } else {
        _tickets.add(updated);
      }
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _errorMessage = _dioError(e);
      notifyListeners();
      return false;
    }
  }

  // ── Exclusão (Delete) ─────────────────────────────────────────────────────

  /// Remove ticket via DELETE e o retira da lista local.
  Future<bool> deleteTicket(String ticketId) async {
    try {
      await _service.delete(ticketId);
      _tickets.removeWhere((t) => t.id == ticketId);
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _errorMessage = _dioError(e);
      notifyListeners();
      return false;
    }
  }

  // ── Comentários locais (messages vêm do detalhe) ──────────────────────────

  void addComment(String ticketId, MessageModel comment) {
    final index = _tickets.indexWhere((t) => t.id == ticketId);
    if (index != -1) {
      final updatedComments = List<MessageModel>.from(_tickets[index].comments)
        ..add(comment);
      _tickets[index] = _tickets[index].copyWith(comments: updatedComments);
      notifyListeners();
    }
  }

  /// Envia uma mensagem para o ticket via API e atualiza localmente
  Future<void> sendMessage(String ticketId, String content) async {
    try {
      await _api.dio.post('/messages', data: {
        'ticketId': ticketId,
        'content': content,
        'sender': 'user',
      });
    } catch (_) {
      // Falha silenciosa — mensagem já adicionada localmente
    }
  }

  // ── Estatísticas (calculadas localmente) ──────────────────────────────────

  int get totalTickets => _tickets.length;
  int get openTickets => _tickets.where((t) => t.status == TicketStatus.open).length;
  int get inProgressTickets => _tickets.where((t) => t.status == TicketStatus.inProgress).length;
  int get resolvedTickets => _tickets.where((t) => t.status == TicketStatus.resolved).length;

  Map<String, int> get ticketsByCategory {
    final map = <String, int>{};
    for (final ticket in _tickets) {
      map[ticket.category] = (map[ticket.category] ?? 0) + 1;
    }
    return map;
  }

  Map<TicketPriority, int> get ticketsByPriority {
    final map = <TicketPriority, int>{};
    for (final ticket in _tickets) {
      map[ticket.priority] = (map[ticket.priority] ?? 0) + 1;
    }
    return map;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _dioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Timeout — verifique sua conexão.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Sem conexão — verifique sua internet.';
    }
    return e.response?.data?['message'] as String? ??
        'Erro ${e.response?.statusCode ?? "desconhecido"}.';
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
