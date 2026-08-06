class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final String? correction;

  ChatMessage({required this.role, required this.content, this.correction});

  Map<String, String> toMap() => {
        'role': role,
        'content': content,
        if (correction != null) 'correction': correction!,
      };

  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
        role: map['role'] as String,
        content: map['content'] as String,
        correction: map['correction'] as String?,
      );
}

class Session {
  final String id;
  final String userId;
  final String? scenarioId;
  final String? scenarioName;
  final DateTime startedAt;
  final List<ChatMessage> messages;

  Session({
    required this.id,
    required this.userId,
    this.scenarioId,
    this.scenarioName,
    required this.startedAt,
    List<ChatMessage>? messages,
  }) : messages = messages ?? [];

  void addMessage(ChatMessage message) => messages.add(message);
}

class SessionSummary {
  final String sessionId;
  final String? scenarioName;
  final DateTime startedAt;
  final int messageCount;
  final int durationSeconds;

  SessionSummary({
    required this.sessionId,
    this.scenarioName,
    required this.startedAt,
    required this.messageCount,
    required this.durationSeconds,
  });
}

class SessionRecap {
  final String sessionId;
  final String? scenarioName;
  final DateTime startedAt;
  final int durationSeconds;
  final int messageCount;
  final List<ChatMessage> messages;
  final List<String> topMistakes;
  final String strength;

  SessionRecap({
    required this.sessionId,
    this.scenarioName,
    required this.startedAt,
    required this.durationSeconds,
    required this.messageCount,
    required this.messages,
    required this.topMistakes,
    required this.strength,
  });
}
