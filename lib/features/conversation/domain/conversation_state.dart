sealed class ConversationState {}

class ConversationIdle extends ConversationState {
  final List<dynamic> messages;
  final String? sessionId;

  ConversationIdle({this.messages = const [], this.sessionId});
}

class ConversationRecording extends ConversationState {
  final List<dynamic> messages;
  final String sessionId;

  ConversationRecording({this.messages = const [], required this.sessionId});
}

class ConversationProcessing extends ConversationState {
  final List<dynamic> messages;
  final String sessionId;

  ConversationProcessing({this.messages = const [], required this.sessionId});
}

class ConversationSpeaking extends ConversationState {
  final List<dynamic> messages;
  final String sessionId;

  ConversationSpeaking({this.messages = const [], required this.sessionId});
}

class ConversationError extends ConversationState {
  final String message;
  final List<dynamic> messages;
  final String? sessionId;

  ConversationError({
    required this.message,
    this.messages = const [],
    this.sessionId,
  });
}
