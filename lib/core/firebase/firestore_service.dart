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
    String? scenarioName,
  }) async {
    final ref = _db.collection('sessions').doc();
    await ref.set({
      'userId': userId,
      'startedAt': FieldValue.serverTimestamp(),
      'endedAt': null,
      'durationSeconds': 0,
      'transcriptCount': 0,
      'scenarioId': scenarioId,
      'scenarioName': scenarioName,
    });
    return ref.id;
  }

  Future<void> endSession(String sessionId, int durationSeconds) =>
      _db.collection('sessions').doc(sessionId).update({
        'endedAt': FieldValue.serverTimestamp(),
        'durationSeconds': durationSeconds,
      });

  Future<void> updateSessionRecap(
    String sessionId, {
    required List<String> topMistakes,
    required String strength,
  }) =>
      _db.collection('sessions').doc(sessionId).update({
        'topMistakes': topMistakes,
        'strength': strength,
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

  // ── Session History ──

  Future<List<Map<String, dynamic>>> getUserSessions(String userId) async {
    final snapshot = await _db
        .collection('sessions')
        .where('userId', isEqualTo: userId)
        .orderBy('startedAt', descending: true)
        .limit(50)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        ...data,
        'startedAt': (data['startedAt'] as Timestamp?)?.toDate(),
        'endedAt': (data['endedAt'] as Timestamp?)?.toDate(),
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getSessionTranscripts(
      String sessionId) async {
    final snapshot = await _db
        .collection('transcripts')
        .where('sessionId', isEqualTo: sessionId)
        .orderBy('timestamp', descending: false)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        ...data,
        'timestamp': (data['timestamp'] as Timestamp?)?.toDate(),
      };
    }).toList();
  }

  Future<Map<String, dynamic>?> getSession(String sessionId) async {
    final doc = await _db.collection('sessions').doc(sessionId).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    return {
      'id': doc.id,
      ...data,
      'startedAt': (data['startedAt'] as Timestamp?)?.toDate(),
      'endedAt': (data['endedAt'] as Timestamp?)?.toDate(),
    };
  }
}
