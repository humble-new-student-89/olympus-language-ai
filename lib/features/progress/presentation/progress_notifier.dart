import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firebase/firestore_service.dart';
import '../domain/streak_service.dart';
import '../domain/fluency_service.dart';

class ProgressData {
  final int fluencyScore;
  final String fluencyLevel;
  final String fluencyTrend;
  final int currentStreak;
  final int totalMinutes;
  final int sessionCount;
  final int avgSessionMinutes;

  ProgressData({
    required this.fluencyScore,
    required this.fluencyLevel,
    required this.fluencyTrend,
    required this.currentStreak,
    required this.totalMinutes,
    required this.sessionCount,
    required this.avgSessionMinutes,
  });
}

class ProgressState {
  final bool isLoading;
  final ProgressData? data;
  final String? error;

  ProgressState({this.isLoading = true, this.data, this.error});

  ProgressState copyWith({
    bool? isLoading,
    ProgressData? data,
    String? error,
  }) =>
      ProgressState(
        isLoading: isLoading ?? this.isLoading,
        data: data ?? this.data,
        error: error,
      );
}

class ProgressNotifier extends StateNotifier<ProgressState> {
  final FirestoreService _firestore;
  final StreakService _streakService;
  final FluencyService _fluencyService;

  ProgressNotifier({
    required FirestoreService firestore,
    required StreakService streakService,
    required FluencyService fluencyService,
  })  : _firestore = firestore,
        _streakService = streakService,
        _fluencyService = fluencyService,
        super(ProgressState());

  Future<void> loadProgress(String uid) async {
    state = ProgressState(isLoading: true);

    try {
      final recentSessions = await _firestore.getRecentSessions(uid, days: 30);
      final userDoc = await _firestore.getUser(uid);
      final userData = userDoc.data() as Map<String, dynamic>?;

      final totalMinutes =
          (userData?['totalMinutesUsed'] as int?) ?? 0;
      final sessionCount = recentSessions
          .where((s) => s['endedAt'] != null)
          .length;
      final currentStreak = _streakService.calculateStreak(
        (userData?['lastActiveDate'] as Timestamp?)?.toDate(),
        (userData?['currentStreak'] as int?) ?? 0,
      );
      final fluencyScore =
          _fluencyService.calculateFluencyScore(recentSessions);
      final fluencyTrend =
          _fluencyService.fluencyTrend(recentSessions);
      final fluencyLevel =
          _fluencyService.levelFromScore(fluencyScore);

      final avgSessionMinutes = sessionCount > 0
          ? totalMinutes ~/ sessionCount
          : 0;

      state = ProgressState(
        isLoading: false,
        data: ProgressData(
          fluencyScore: fluencyScore,
          fluencyLevel: fluencyLevel,
          fluencyTrend: fluencyTrend,
          currentStreak: currentStreak,
          totalMinutes: totalMinutes,
          sessionCount: sessionCount,
          avgSessionMinutes: avgSessionMinutes,
        ),
      );
    } catch (e) {
      state = ProgressState(isLoading: false, error: e.toString());
    }
  }
}
