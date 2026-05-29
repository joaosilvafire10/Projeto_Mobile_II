import 'message_model.dart';

enum TicketStatus { open, inProgress, resolved, closed }

enum TicketPriority { low, medium, high, critical }

class TicketModel {
  final String id;
  final String title;
  final String description;
  final String userId;
  final String userName;
  final String department;
  final TicketStatus status;
  final TicketPriority priority;
  final String category;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final List<MessageModel> chatHistory;
  final List<MessageModel> comments;
  final String aiSummary;
  final String? assignedTo;
  final String? solution;

  TicketModel({
    required this.id,
    required this.title,
    required this.description,
    required this.userId,
    required this.userName,
    required this.department,
    this.status = TicketStatus.open,
    this.priority = TicketPriority.medium,
    this.category = 'Geral',
    DateTime? createdAt,
    this.resolvedAt,
    this.chatHistory = const [],
    this.comments = const [],
    this.aiSummary = '',
    this.assignedTo,
    this.solution,
  }) : createdAt = createdAt ?? DateTime.now();

  // =============================================
  // Deserialização da resposta da API REST
  // =============================================
  factory TicketModel.fromMap(Map<String, dynamic> map) {
    return TicketModel(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      userId: map['userId'] as String? ?? map['user_id'] as String? ?? '',
      userName: map['user'] != null
          ? (map['user']['name'] as String? ?? '')
          : (map['userName'] as String? ?? ''),
      department: map['department'] as String? ?? 'GERAL',
      status: _parseStatus(map['status'] as String?),
      priority: _parsePriority(map['priority'] as String?),
      category: map['category'] != null
          ? (map['category']['name'] as String? ?? 'Geral')
          : (map['categoryName'] as String? ?? 'Geral'),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      resolvedAt: map['resolvedAt'] != null
          ? DateTime.tryParse(map['resolvedAt'] as String)
          : null,
      aiSummary: map['aiSummary'] as String? ?? map['ai_summary'] as String? ?? '',
      comments: map['messages'] != null
          ? (map['messages'] as List)
              .map((m) => MessageModel.fromMap(m as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }

  static TicketStatus _parseStatus(String? s) {
    switch ((s ?? '').toUpperCase()) {
      case 'ABERTO':
      case 'OPEN':
        return TicketStatus.open;
      case 'EM_ANDAMENTO':
      case 'IN_PROGRESS':
        return TicketStatus.inProgress;
      case 'RESOLVIDO':
      case 'RESOLVED':
        return TicketStatus.resolved;
      case 'FINALIZADO':
      case 'CLOSED':
        return TicketStatus.closed;
      default:
        return TicketStatus.open;
    }
  }

  static TicketPriority _parsePriority(String? p) {
    switch ((p ?? '').toUpperCase()) {
      case 'BAIXA':
      case 'LOW':
        return TicketPriority.low;
      case 'ALTA':
      case 'HIGH':
        return TicketPriority.high;
      case 'CRITICA':
      case 'CRITICAL':
        return TicketPriority.critical;
      default:
        return TicketPriority.medium;
    }
  }

  // Converte status do Flutter para formato da API
  String get statusApi {
    switch (status) {
      case TicketStatus.open:
        return 'ABERTO';
      case TicketStatus.inProgress:
        return 'EM_ANDAMENTO';
      case TicketStatus.resolved:
        return 'RESOLVIDO';
      case TicketStatus.closed:
        return 'FINALIZADO';
    }
  }

  // Converte prioridade do Flutter para formato da API
  String get priorityApi {
    switch (priority) {
      case TicketPriority.low:
        return 'BAIXA';
      case TicketPriority.medium:
        return 'MEDIA';
      case TicketPriority.high:
        return 'ALTA';
      case TicketPriority.critical:
        return 'CRITICA';
    }
  }

  TicketModel copyWith({
    String? id,
    String? title,
    String? description,
    String? userId,
    String? userName,
    String? department,
    TicketStatus? status,
    TicketPriority? priority,
    String? category,
    DateTime? createdAt,
    DateTime? resolvedAt,
    List<MessageModel>? chatHistory,
    List<MessageModel>? comments,
    String? aiSummary,
    String? assignedTo,
    String? solution,
  }) {
    return TicketModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      department: department ?? this.department,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      chatHistory: chatHistory ?? this.chatHistory,
      comments: comments ?? this.comments,
      aiSummary: aiSummary ?? this.aiSummary,
      assignedTo: assignedTo ?? this.assignedTo,
      solution: solution ?? this.solution,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'userId': userId,
      'userName': userName,
      'department': department,
      'status': status.name,
      'priority': priority.name,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'chatHistory': chatHistory.map((m) => m.toMap()).toList(),
      'comments': comments.map((m) => m.toMap()).toList(),
      'aiSummary': aiSummary,
      'assignedTo': assignedTo,
      'solution': solution,
    };
  }
}
