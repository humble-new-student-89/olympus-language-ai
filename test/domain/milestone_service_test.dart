import 'package:flutter_test/flutter_test.dart';
import 'package:olympus_language_ai/features/milestones/domain/milestone_service.dart';

void main() {
  late MilestoneService service;

  setUp(() {
    service = MilestoneService();
  });

  group('checkNewMilestones', () {
    test('returns session milestone for first session', () {
      final milestones = service.checkNewMilestones(
        sessionCount: 1,
        currentStreak: 1,
        totalMinutesUsed: 0,
        existingMilestoneIds: [],
      );

      expect(milestones.any((m) => m.id == 'sessions_1'), true);
      expect(milestones.firstWhere((m) => m.id == 'sessions_1').title,
          'First Steps');
      expect(
          milestones.firstWhere((m) => m.id == 'sessions_1').isShareable, false);
    });

    test('does not return already-achieved milestones', () {
      final milestones = service.checkNewMilestones(
        sessionCount: 10,
        currentStreak: 3,
        totalMinutesUsed: 0,
        existingMilestoneIds: ['sessions_1', 'sessions_5', 'sessions_10'],
      );

      expect(milestones.any((m) => m.id == 'sessions_10'), false);
    });

    test('returns streak milestone for streak of 7', () {
      final milestones = service.checkNewMilestones(
        sessionCount: 10,
        currentStreak: 7,
        totalMinutesUsed: 0,
        existingMilestoneIds: ['sessions_1', 'sessions_5', 'sessions_10'],
      );

      expect(milestones.any((m) => m.id == 'streak_7'), true);
      expect(
          milestones.firstWhere((m) => m.id == 'streak_7').title, 'Week Warrior');
    });

    test('returns minute milestone for 60 minutes', () {
      final milestones = service.checkNewMilestones(
        sessionCount: 5,
        currentStreak: 1,
        totalMinutesUsed: 60,
        existingMilestoneIds: [],
      );

      expect(milestones.any((m) => m.id == 'minutes_60'), true);
      expect(
          milestones.firstWhere((m) => m.id == 'minutes_60').title,
          'Hour of Practice');
    });

    test('returns multiple minute milestones when eligible', () {
      final milestones = service.checkNewMilestones(
        sessionCount: 50,
        currentStreak: 1,
        totalMinutesUsed: 600,
        existingMilestoneIds: ['sessions_1', 'sessions_5', 'sessions_10',
            'sessions_25', 'sessions_50', 'minutes_60', 'minutes_300'],
      );

      expect(milestones.any((m) => m.id == 'minutes_600'), true);
    });

    test('session milestone 50 is shareable', () {
      final milestones = service.checkNewMilestones(
        sessionCount: 50,
        currentStreak: 1,
        totalMinutesUsed: 0,
        existingMilestoneIds: [],
      );

      final m = milestones.firstWhere((m) => m.id == 'sessions_50');
      expect(m.isShareable, true);
    });

    test('empty milestones for no progress', () {
      final milestones = service.checkNewMilestones(
        sessionCount: 2,
        currentStreak: 1,
        totalMinutesUsed: 5,
        existingMilestoneIds: ['sessions_1'],
      );

      expect(milestones, isEmpty);
    });
  });
}
