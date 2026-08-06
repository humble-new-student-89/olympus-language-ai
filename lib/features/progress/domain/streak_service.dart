class StreakService {
  static const int streakResetHours = 48;
  static const int streakAtRiskHours = 36;

  static const List<int> milestoneDays = [3, 7, 14, 30, 50, 100];

  int calculateStreak(DateTime? lastActiveDate, int currentStreak) {
    final now = DateTime.now();

    if (lastActiveDate == null) return 1;

    final hoursSinceLastActive =
        now.difference(lastActiveDate).inHours;

    if (hoursSinceLastActive >= streakResetHours) return 1;

    final lastActiveDay = DateTime(
        lastActiveDate.year, lastActiveDate.month, lastActiveDate.day);
    final today = DateTime(now.year, now.month, now.day);
    final daysDiff = today.difference(lastActiveDay).inDays;

    if (daysDiff == 0) return currentStreak < 1 ? 1 : currentStreak;

    if (daysDiff == 1) return currentStreak + 1;

    return 1;
  }

  bool isStreakAtRisk(DateTime? lastActiveDate) {
    if (lastActiveDate == null) return true;
    final hoursSinceLastActive =
        DateTime.now().difference(lastActiveDate).inHours;
    return hoursSinceLastActive >= streakAtRiskHours &&
        hoursSinceLastActive < streakResetHours;
  }

  String? streakMilestone(int streak) {
    if (milestoneDays.contains(streak)) return '$streak day streak!';
    return null;
  }
}
