import 'package:flutter/material.dart';
import '../models/ticket_model.dart';
import '../models/message_model.dart';

class TicketProvider extends ChangeNotifier {
  final List<TicketModel> _tickets = [];

  List<TicketModel> get tickets => List.unmodifiable(_tickets);

  /// Busca um chamado pelo ID
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

  List<TicketModel> getTicketsByDepartment(String department) {
    return _tickets.where((t) => t.department == department).toList();
  }

  void addTicket(TicketModel ticket) {
    _tickets.add(ticket);
    notifyListeners();
  }

  /// Adiciona um comentário/mensagem ao chamado
  void addComment(String ticketId, MessageModel comment) {
    final index = _tickets.indexWhere((t) => t.id == ticketId);
    if (index != -1) {
      final updatedComments = List<MessageModel>.from(_tickets[index].comments)
        ..add(comment);
      _tickets[index] = _tickets[index].copyWith(comments: updatedComments);
      notifyListeners();
    }
  }

  /// Edita os campos do chamado (título, descrição, prioridade, status)
  void editTicket(String ticketId, {
    String? title,
    String? description,
    TicketPriority? priority,
    TicketStatus? status,
  }) {
    final index = _tickets.indexWhere((t) => t.id == ticketId);
    if (index != -1) {
      _tickets[index] = _tickets[index].copyWith(
        title: title,
        description: description,
        priority: priority,
        status: status,
        resolvedAt: status == TicketStatus.resolved ? DateTime.now() : null,
      );
      notifyListeners();
    }
  }

  void updateTicketStatus(String ticketId, TicketStatus newStatus) {
    final index = _tickets.indexWhere((t) => t.id == ticketId);
    if (index != -1) {
      _tickets[index] = _tickets[index].copyWith(
        status: newStatus,
        resolvedAt: newStatus == TicketStatus.resolved ? DateTime.now() : null,
      );
      notifyListeners();
    }
  }

  void resolveTicket(String ticketId, String solution) {
    final index = _tickets.indexWhere((t) => t.id == ticketId);
    if (index != -1) {
      _tickets[index] = _tickets[index].copyWith(
        status: TicketStatus.resolved,
        resolvedAt: DateTime.now(),
        solution: solution,
      );
      notifyListeners();
    }
  }

  // Estatísticas
  int get totalTickets => _tickets.length;
  int get openTickets => _tickets.where((t) => t.status == TicketStatus.open).length;
  int get inProgressTickets =>
      _tickets.where((t) => t.status == TicketStatus.inProgress).length;
  int get resolvedTickets =>
      _tickets.where((t) => t.status == TicketStatus.resolved).length;

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
}
