import '../../../core/firebase/firestore_service.dart';

class ConversationRepository {
  final FirestoreService _firestore;

  ConversationRepository({required FirestoreService firestore})
      : _firestore = firestore;

  Future<String> startSession({
    required String userId,
    String? scenarioId,
  }) async {
    return _firestore.createSession(
      userId: userId,
      scenarioId: scenarioId,
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
}
