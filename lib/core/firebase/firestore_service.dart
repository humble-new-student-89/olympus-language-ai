import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_config.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseConfig.firestore;

  // ── Users ──

  Future<DocumentReference> createUser({
    required String uid,
    required String email,
    required String displayName,
  }) async {
    return _db.collection('users').doc(uid).set({
      'email': email,
      'displayName': displayName,
      'createdAt': FieldValue.serverTimestamp(),
      'plan': 'free',
      'totalMinutesUsed': 0,
      'currentStreak': 0,
      'lastActiveDate': null,
    }).then((_) => _db.collection('users').doc(uid));
  }

  Future<DocumentSnapshot> getUser(String uid) =>
      _db.collection('users').doc(uid).get();

  Future<void> updateUser(String uid, Map<String, dynamic> data) =>
      _db.collection('users').doc(uid).update(data);

  // ── Sessions ──

  Future<String> createSession({
    required String userId,
    String? scenarioId,
  }) async {
    final ref = _db.collection('sessions').doc();
    await ref.set({
      'userId': userId,
      'startedAt': FieldValue.serverTimestamp(),
      'endedAt': null,
      'durationSeconds': 0,
      'transcriptCount': 0,
      'scenarioId': scenarioId,
    });
    return ref.id;
  }

  Future<void> endSession(String sessionId, int durationSeconds) =>
      _db.collection('sessions').doc(sessionId).update({
        'endedAt': FieldValue.serverTimestamp(),
        'durationSeconds': durationSeconds,
      });

  // ── Transcripts ──

  Future<void> addTranscript({
    required String sessionId,
    required String userId,
    required String speaker,
    required String text,
    Map<String, dynamic>? correction,
  }) async {
    final ref = _db.collection('transcripts').doc();
    await ref.set({
      'sessionId': sessionId,
      'userId': userId,
      'speaker': speaker,
      'text': text,
      'audioUrl': null,
      'timestamp': FieldValue.serverTimestamp(),
      'correction': correction,
    });
    await _db.collection('sessions').doc(sessionId).update({
      'transcriptCount': FieldValue.increment(1),
    });
  }
}
