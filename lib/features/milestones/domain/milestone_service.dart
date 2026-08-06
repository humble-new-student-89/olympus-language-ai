class Milestone {
  final String id;
  final String title;
  final String description;
  final String icon;
  final DateTime achievedAt;
  final bool isShareable;
  bool shared;

  Milestone({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.achievedAt,
    this.isShareable = false,
    this.shared = false,
  });
}

class MilestoneService {
  static const sessionMilestones = {
    1: ('First Steps', 'Completed your first conversation', '🎤', false),
    5: ('Getting Started', 'Completed 5 conversations', '🌟', false),
    10: ('Conversationalist', 'Completed 10 conversations', '💬', true),
    25: ('Dedicated Learner', 'Completed 25 conversations', '🎯', true),
    50: ('Olympus Regular', 'Completed 50 conversations', '🏆', true),
    100: ('Olympus Master', 'Completed 100 conversations', '👑', true),
  };

  static const streakMilestones = {
    3: ('3-Day Streak', 'Practiced 3 days in a row', '🔥', false),
    7: ('Week Warrior', '7-day practice streak', '📅', true),
    14: ('Fortnight Focus', '14-day practice streak', '⚡', true),
    30: ('Monthly Mastery', '30-day practice streak', '💪', true),
    100: ('Centurion Streak', '100-day practice streak', '🏅', true),
  };

  static const minuteMilestones = {
    60: ('Hour of Practice', '60 minutes total practice', '⏱️', false),
    300: ('Dedicated Hours', '5 hours of conversation', '🎧', true),
    600: ('Olympus Pro', '10 hours of conversation', '⭐', true),
    3000: ('Living the Language', '50 hours of conversation', '🌍', true),
  };

  List<Milestone> checkNewMilestones({
    required int sessionCount,
    required int currentStreak,
    required int totalMinutesUsed,
    required List<String> existingMilestoneIds,
  }) {
    final newMilestones = <Milestone>[];

    if (sessionMilestones.containsKey(sessionCount)) {
      final id = 'sessions_$sessionCount';
      if (!existingMilestoneIds.contains(id)) {
        final info = sessionMilestones[sessionCount]!;
        newMilestones.add(Milestone(
          id: id,
          title: info.$1,
          description: info.$2,
          icon: info.$3,
          isShareable: info.$4,
          achievedAt: DateTime.now(),
        ));
      }
    }

    if (streakMilestones.containsKey(currentStreak)) {
      final id = 'streak_$currentStreak';
      if (!existingMilestoneIds.contains(id)) {
        final info = streakMilestones[currentStreak]!;
        newMilestones.add(Milestone(
          id: id,
          title: info.$1,
          description: info.$2,
          icon: info.$3,
          isShareable: info.$4,
          achievedAt: DateTime.now(),
        ));
      }
    }

    for (final entry in minuteMilestones.entries) {
      final id = 'minutes_${entry.key}';
      if (totalMinutesUsed >= entry.key &&
          !existingMilestoneIds.contains(id)) {
        final info = entry.value;
        newMilestones.add(Milestone(
          id: id,
          title: info.$1,
          description: info.$2,
          icon: info.$3,
          isShareable: info.$4,
          achievedAt: DateTime.now(),
        ));
      }
    }

    return newMilestones;
  }
}
