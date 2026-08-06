import 'package:flutter_test/flutter_test.dart';
import 'package:olympus_language_ai/features/progress/domain/streak_service.dart';

void main() {
  late StreakService service;
  final now = DateTime(2026, 8, 6, 14, 0);
  final today = DateTime(2026, 8, 6, 9, 0);
  final yesterday = DateTime(2026, 8, 5, 14, 0);
  final twoDaysAgo = DateTime(2026, 8, 4, 10, 0);
  final threeDaysAgo = DateTime(2026, 8, 3, 14, 0);

  setUp(() {
    service = StreakService();
  });

  group('calculateStreak', () {
    test('null lastActiveDate returns 1', () {
      expect(service.calculateStreak(null, 0), 1);
    });

    test('same day returns current streak unchanged', () {
      expect(service.calculateStreak(today, 5), 5);
    });

    test('same day with 0 streak returns 1', () {
      expect(service.calculateStreak(today, 0), 1);
    });

    test('yesterday increments streak', () {
      expect(service.calculateStreak(yesterday, 5), 6);
    });

    test('yesterday from 0 returns 1', () {
      expect(service.calculateStreak(yesterday, 0), 1);
    });

    test('36 hours ago still counts as consecutive', () {
      // Use yesterday + 12 hours = 36 hours, still consecutive
      final yesterdayEvening = DateTime(2026, 8, 5, 23, 0);
      expect(service.calculateStreak(yesterdayEvening, 5), 6);
    });

    test('2 days ago resets streak', () {
      expect(service.calculateStreak(twoDaysAgo, 5), 1);
    });

    test('3 days ago resets streak', () {
      expect(service.calculateStreak(threeDaysAgo, 10), 1);
    });
  });

  group('isStreakAtRisk', () {
    test('null lastActiveDate is at risk', () {
      expect(service.isStreakAtRisk(null), true);
    });

    test('1 hour ago is not at risk', () {
      final oneHourAgo = now.subtract(const Duration(hours: 1));
      expect(service.isStreakAtRisk(oneHourAgo), false);
    });

    test('36 hours ago is at risk', () {
      final thirtySixHoursAgo = DateTime.now().subtract(const Duration(hours: 36));
      expect(service.isStreakAtRisk(thirtySixHoursAgo), true);
    });

    test('40 hours ago is at risk', () {
      final fortyHoursAgo = DateTime.now().subtract(const Duration(hours: 40));
      expect(service.isStreakAtRisk(fortyHoursAgo), true);
    });

    test('48 hours ago is NOT at risk (streak is broken)', () {
      final fortyEightHoursAgo = DateTime.now().subtract(const Duration(hours: 48));
      expect(service.isStreakAtRisk(fortyEightHoursAgo), false);
    });
  });

  group('streakMilestone', () {
    test('returns milestone text for milestone days', () {
      expect(service.streakMilestone(3), '3 day streak!');
      expect(service.streakMilestone(7), '7 day streak!');
      expect(service.streakMilestone(14), '14 day streak!');
      expect(service.streakMilestone(30), '30 day streak!');
      expect(service.streakMilestone(50), '50 day streak!');
      expect(service.streakMilestone(100), '100 day streak!');
    });

    test('returns null for non-milestone days', () {
      expect(service.streakMilestone(1), null);
      expect(service.streakMilestone(2), null);
      expect(service.streakMilestone(5), null);
      expect(service.streakMilestone(15), null);
    });
  });
}
