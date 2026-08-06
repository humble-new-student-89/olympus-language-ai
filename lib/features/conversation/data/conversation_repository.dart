import '../../../core/firebase/firestore_service.dart';

class ConversationRepository {
  final FirestoreService _firestore;

  ConversationRepository({required FirestoreService firestore})
      : _firestore = firestore;

  Future<String> startSession({
    required String userId,
    String? scenarioId,
    String? scenarioName,
  }) async {
    return _firestore.createSession(
      userId: userId,
      scenarioId: scenarioId,
      scenarioName: scenarioName,
    );
  }

  Future<void> endSession(String sessionId, int durationSeconds) async {
    await _firestore.endSession(sessionId, durationSeconds);
  }

  Future<void> saveTranscript({
    required String sessionId,
    required String userId,
    required String text,
    bool isUser = true,
    Map<String, dynamic>? correction,
  }) async {
    await _firestore.addTranscript(
      sessionId: sessionId,
      userId: userId,
      speaker: isUser ? 'user' : 'ai',
      text: text,
      correction: correction,
    );
  }

  Future<void> saveRecap(
    String sessionId, {
    required List<String> topMistakes,
    required String strength,
  }) async {
    await _firestore.updateSessionRecap(
      sessionId,
      topMistakes: topMistakes,
      strength: strength,
    );
  }

  Future<List<Map<String, dynamic>>> getSessions(String userId) =>
      _firestore.getUserSessions(userId);

  Future<List<Map<String, dynamic>>> getTranscripts(String sessionId) =>
      _firestore.getSessionTranscripts(sessionId);

  Future<Map<String, dynamic>?> getSession(String sessionId) =>
      _firestore.getSession(sessionId);
}
