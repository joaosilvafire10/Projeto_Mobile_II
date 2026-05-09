import 'package:flutter/material.dart';
import '../models/ticket_model.dart';

class TicketProvider extends ChangeNotifier {
  final List<TicketModel> _tickets = [];

  List<TicketModel> get tickets => List.unmodifiable(_tickets);

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
