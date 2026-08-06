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

  // ── Usage & Streaks ──

  Future<int> getTotalMinutesUsed(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return (doc.data()?['totalMinutesUsed'] as int?) ?? 0;
  }

  Future<void> incrementUsageMinutes(String uid, int minutes) =>
      _db.collection('users').doc(uid).update({
        'totalMinutesUsed': FieldValue.increment(minutes),
        'lastActiveDate': FieldValue.serverTimestamp(),
      });

  Future<void> updateStreak(String uid, int newStreak) async {
    final isNewStreak = newStreak == 1;
    _db.collection('users').doc(uid).update({
      'currentStreak': newStreak,
      'lastActiveDate': FieldValue.serverTimestamp(),
      if (isNewStreak) 'streakStartDate': FieldValue.serverTimestamp(),
    });
  }

  // ── Billing ──

  Future<void> updatePlan(String uid, String plan, {DateTime? expiry}) =>
      _db.collection('users').doc(uid).update({
        'plan': plan,
        'subscriptionExpiry': expiry != null
            ? Timestamp.fromDate(expiry)
            : FieldValue.delete(),
      });

  Future<void> startTrial(String uid) =>
      _db.collection('users').doc(uid).update({
        'trialStartedAt': FieldValue.serverTimestamp(),
        'plan': 'trial',
      });

  Future<Map<String, dynamic>?> getSubscriptionStatus(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data();
    if (data == null) return null;
    return {
      'plan': data['plan'] as String? ?? 'free',
      'trialStartedAt': (data['trialStartedAt'] as Timestamp?)?.toDate(),
      'subscriptionExpiry':
          (data['subscriptionExpiry'] as Timestamp?)?.toDate(),
      'totalMinutesUsed': data['totalMinutesUsed'] as int? ?? 0,
    };
  }

  // ── Progress ──

  Future<int> getTotalSessionCount(String uid) async {
    final snapshot = await _db
        .collection('sessions')
        .where('userId', isEqualTo: uid)
        .where('endedAt', isNotEqualTo: null)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<void> updateFluency(String uid, int score, String level) =>
      _db.collection('users').doc(uid).update({
        'fluencyScore': score,
        'fluencyLevel': level,
        'sessionCount': FieldValue.increment(1),
      });

  Future<List<Map<String, dynamic>>> getRecentSessions(
    String uid, {
    int days = 30,
  }) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final snapshot = await _db
        .collection('sessions')
        .where('userId', isEqualTo: uid)
        .where('endedAt', isNotEqualTo: null)
        .where('startedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
        .orderBy('startedAt', descending: false)
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

  // ── Milestones ──

  Future<List<Map<String, dynamic>>> getMilestones(String uid) async {
    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('milestones')
        .orderBy('achievedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        ...data,
        'achievedAt': (data['achievedAt'] as Timestamp?)?.toDate(),
      };
    }).toList();
  }

  Future<void> saveMilestone(
    String uid,
    String milestoneId,
    String title,
    String description,
    String icon,
  ) =>
      _db
          .collection('users')
          .doc(uid)
          .collection('milestones')
          .doc(milestoneId)
          .set({
            'title': title,
            'description': description,
            'icon': icon,
            'achievedAt': FieldValue.serverTimestamp(),
            'shared': false,
          });

  // ── FCM Tokens ──

  Future<void> saveFcmToken(String uid, String token) =>
      _db.collection('fcmTokens').doc(uid).set({
        'token': token,
        'platform': 'android',
        'updatedAt': FieldValue.serverTimestamp(),
      });

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
