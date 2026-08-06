class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;

  ChatMessage({required this.role, required this.content});

  Map<String, String> toMap() => {'role': role, 'content': content};

  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
        role: map['role'] as String,
        content: map['content'] as String,
      );
}

class Session {
  final String id;
  final String userId;
  final String? scenarioId;
  final DateTime startedAt;
  final List<ChatMessage> messages;

  Session({
    required this.id,
    required this.userId,
    this.scenarioId,
    required this.startedAt,
    List<ChatMessage>? messages,
  }) : messages = messages ?? [];

  void addMessage(ChatMessage message) => messages.add(message);
}
