import 'package:flutter_test/flutter_test.dart';
import 'package:olympus_language_ai/features/progress/domain/fluency_service.dart';

void main() {
  late FluencyService service;

  Map<String, dynamic> makeSession({
    int transcriptCount = 6,
    List<String>? topMistakes,
    bool ended = true,
  }) {
    return {
      'transcriptCount': transcriptCount,
      'topMistakes': topMistakes ?? [],
      'endedAt': ended ? DateTime.now() : null,
    };
  }

  setUp(() {
    service = FluencyService();
  });

  group('calculateFluencyScore', () {
    test('empty sessions returns 0', () {
      expect(service.calculateFluencyScore([]), 0);
    });

    test('sessions with no endedAt are excluded', () {
      final sessions = [
        makeSession(ended: false),
      ];
      expect(service.calculateFluencyScore(sessions), 0);
    });

    test('sessions with zero transcriptCount are excluded', () {
      final sessions = [
        makeSession(transcriptCount: 0),
      ];
      expect(service.calculateFluencyScore(sessions), 0);
    });

    test('single session with no mistakes returns a score above 0', () {
      final sessions = [
        makeSession(topMistakes: [], transcriptCount: 10),
      ];
      final score = service.calculateFluencyScore(sessions);
      expect(score, greaterThan(0));
      expect(score, lessThanOrEqualTo(100));
    });

    test('multiple sessions with no mistakes score higher than sessions with mistakes', () {
      final cleanSessions = List.generate(
          5, (_) => makeSession(topMistakes: [], transcriptCount: 10));
      final mistakeSessions = List.generate(
          5, (_) => makeSession(topMistakes: ['mistake1', 'mistake2'], transcriptCount: 10));

      final cleanScore = service.calculateFluencyScore(cleanSessions);
      final mistakeScore = service.calculateFluencyScore(mistakeSessions);

      expect(cleanScore, greaterThan(mistakeScore));
    });

    test('score is always between 0 and 100', () {
      final sessions = List.generate(
          10, (_) => makeSession(topMistakes: [], transcriptCount: 100));
      final score = service.calculateFluencyScore(sessions);
      expect(score, greaterThanOrEqualTo(0));
      expect(score, lessThanOrEqualTo(100));
    });
  });

  group('levelFromScore', () {
    test('returns Beginner for low scores', () {
      expect(service.levelFromScore(0), 'Beginner');
      expect(service.levelFromScore(10), 'Beginner');
      expect(service.levelFromScore(29), 'Beginner');
    });

    test('returns Elementary for scores 30-49', () {
      expect(service.levelFromScore(30), 'Elementary');
      expect(service.levelFromScore(45), 'Elementary');
    });

    test('returns Intermediate for scores 50-69', () {
      expect(service.levelFromScore(50), 'Intermediate');
      expect(service.levelFromScore(65), 'Intermediate');
    });

    test('returns Advanced for scores 70-84', () {
      expect(service.levelFromScore(70), 'Advanced');
      expect(service.levelFromScore(80), 'Advanced');
    });

    test('returns Fluent for scores 85+', () {
      expect(service.levelFromScore(85), 'Fluent');
      expect(service.levelFromScore(95), 'Fluent');
      expect(service.levelFromScore(100), 'Fluent');
    });
  });

  group('fluencyTrend', () {
    test('fewer than 3 sessions returns stable', () {
      final sessions = [makeSession(), makeSession()];
      expect(service.fluencyTrend(sessions), 'stable');
    });

    test('multiple good sessions returns stable', () {
      final sessions = List.generate(
          4, (_) => makeSession(topMistakes: [], transcriptCount: 10));
      expect(service.fluencyTrend(sessions), 'stable');
    });

    test('sessions without endedAt are excluded from trend', () {
      final sessions = [
        makeSession(ended: false),
        makeSession(ended: false),
      ];
      expect(service.fluencyTrend(sessions), 'stable');
    });
  });
}
