class FluencyService {
  int calculateFluencyScore(List<Map<String, dynamic>> recentSessions) {
    if (recentSessions.isEmpty) return 0;

    final completedSessions = recentSessions.where((s) =>
        s['endedAt'] != null && (s['transcriptCount'] as int? ?? 0) > 0);

    if (completedSessions.isEmpty) return 0;

    var totalMistakes = 0;
    var totalMessages = 0;

    for (final session in completedSessions) {
      final mistakes =
          (session['topMistakes'] as List<dynamic>?)?.length ?? 0;
      final messages = session['transcriptCount'] as int? ?? 0;
      totalMistakes += mistakes;
      totalMessages += messages;
    }

    final count = completedSessions.length;

    final sessionCountScore =
        (count / 20).clamp(0.0, 1.0) * 0.3;

    final avgMistakesPerMessage = totalMessages > 0
        ? totalMistakes / totalMessages
        : 1.0;
    final mistakeScore =
        (1.0 - avgMistakesPerMessage.clamp(0.0, 0.5) * 2).clamp(0.0, 1.0) * 0.4;

    final avgMessagesPerSession =
        totalMessages / count;
    final messageScore =
        (avgMessagesPerSession / 20).clamp(0.0, 1.0) * 0.3;

    return ((sessionCountScore + mistakeScore + messageScore) * 100)
        .round()
        .clamp(0, 100);
  }

  String fluencyTrend(List<Map<String, dynamic>> recentSessions) {
    final completed = recentSessions
        .where((s) => s['endedAt'] != null)
        .toList();

    if (completed.length < 3) return 'stable';

    final midPoint = completed.length ~/ 2;
    final firstHalf = calculateFluencyScore(completed.sublist(0, midPoint));
    final secondHalf = calculateFluencyScore(completed.sublist(midPoint));

    final diff = secondHalf - firstHalf;
    if (diff >= 5) return 'improving';
    if (diff <= -5) return 'declining';
    return 'stable';
  }

  String levelFromScore(int score) {
    if (score >= 85) return 'Fluent';
    if (score >= 70) return 'Advanced';
    if (score >= 50) return 'Intermediate';
    if (score >= 30) return 'Elementary';
    return 'Beginner';
  }
}
