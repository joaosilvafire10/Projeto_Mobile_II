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
    this.aiSummary = '',
    this.assignedTo,
    this.solution,
  }) : createdAt = createdAt ?? DateTime.now();

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
      'aiSummary': aiSummary,
      'assignedTo': assignedTo,
      'solution': solution,
    };
  }
}
