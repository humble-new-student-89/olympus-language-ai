sealed class ConversationState {}

class ConversationIdle extends ConversationState {
  final List<dynamic> messages;
  final String? sessionId;
  final String? scenarioId;
  final String? scenarioName;

  ConversationIdle({
    this.messages = const [],
    this.sessionId,
    this.scenarioId,
    this.scenarioName,
  });
}

class ConversationRecording extends ConversationState {
  final List<dynamic> messages;
  final String sessionId;
  final String? scenarioId;
  final String? scenarioName;

  ConversationRecording({
    this.messages = const [],
    required this.sessionId,
    this.scenarioId,
    this.scenarioName,
  });
}

class ConversationProcessing extends ConversationState {
  final List<dynamic> messages;
  final String sessionId;
  final String? scenarioId;
  final String? scenarioName;

  ConversationProcessing({
    this.messages = const [],
    required this.sessionId,
    this.scenarioId,
    this.scenarioName,
  });
}

class ConversationSpeaking extends ConversationState {
  final List<dynamic> messages;
  final String sessionId;
  final String? scenarioId;
  final String? scenarioName;

  ConversationSpeaking({
    this.messages = const [],
    required this.sessionId,
    this.scenarioId,
    this.scenarioName,
  });
}

class ConversationError extends ConversationState {
  final String message;
  final List<dynamic> messages;
  final String? sessionId;
  final String? scenarioId;
  final String? scenarioName;

  ConversationError({
    required this.message,
    this.messages = const [],
    this.sessionId,
    this.scenarioId,
    this.scenarioName,
  });
}
