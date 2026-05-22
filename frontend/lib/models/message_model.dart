enum MessageSender { user, ai, system }

class MessageModel {
  final String id;
  final String content;
  final MessageSender sender;
  final String? senderName;
  final DateTime timestamp;
  final bool isTyping;

  MessageModel({
    required this.id,
    required this.content,
    required this.sender,
    this.senderName,
    DateTime? timestamp,
    this.isTyping = false,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'sender': sender.name,
      'senderName': senderName,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] ?? '',
      content: map['content'] ?? '',
      sender: MessageSender.values.firstWhere(
        (e) => e.name == map['sender'],
        orElse: () => MessageSender.ai,
      ),
      senderName: map['senderName'],
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}
