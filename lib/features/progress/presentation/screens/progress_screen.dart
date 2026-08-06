import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import '../../../auth/presentation/providers.dart';
import '../../../auth/domain/auth_state.dart';
import '../../../conversation/presentation/providers.dart';
import '../providers.dart';
import '../progress_notifier.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  List<FlSpot> _scoreHistory = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final user = ref.read(authStateProvider);
    if (user is AuthAuthenticated) {
      await ref.read(progressStateProvider.notifier).loadProgress(user.user.uid);

      final firestore = ref.read(firestoreServiceProvider);
      final sessions =
          await firestore.getRecentSessions(user.user.uid, days: 30);

      final fluencyService = ref.read(fluencyServiceProvider);
      final spots = <FlSpot>[];
      for (var i = 0; i < sessions.length; i++) {
        final window = sessions.sublist(0, i + 1);
        final score = fluencyService.calculateFluencyScore(window).toDouble();
        spots.add(FlSpot(i.toDouble(), score));
      }

      if (mounted) setState(() => _scoreHistory = spots);
    }
  }

  IconData _trendIcon(String trend) => switch (trend) {
        'improving' => Icons.trending_up,
        'declining' => Icons.trending_down,
        _ => Icons.trending_flat,
      };

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(progressStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Progress'),
        actions: [
          if (progress.data != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                final d = progress.data!;
                Share.share(
                  'I\'ve completed ${d.sessionCount} conversations on '
                  'Olympus Language AI! Fluency: ${d.fluencyScore}/100 '
                  '(${d.fluencyLevel}). ${d.currentStreak}-day streak! '
                  'Join me: olympuslanguage.ai',
                );
              },
            ),
        ],
      ),
      body: progress.isLoading
          ? const Center(child: CircularProgressIndicator())
          : progress.error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 8),
                      Text(progress.error!,
                          style: const TextStyle(color: Colors.red)),
                      TextButton(
                        onPressed: _load,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildContent(progress.data!),
    );
  }

  Widget _buildContent(ProgressData data) {
    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildScoreHeader(data),
            const SizedBox(height: 24),
            _buildChart(),
            const SizedBox(height: 24),
            _buildStreakCard(data),
            const SizedBox(height: 16),
            _buildStatsGrid(data),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreHeader(ProgressData data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            '${data.fluencyScore}',
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              data.fluencyLevel,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_trendIcon(data.fluencyTrend),
                  size: 20, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                data.fluencyTrend == 'improving'
                    ? 'Improving'
                    : data.fluencyTrend == 'declining'
                        ? 'Declining'
                        : 'Steady',
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    if (_scoreHistory.length < 2) {
      return Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'Complete more sessions\nto see your fluency trend',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fluency Trend',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 200,
          padding: const EdgeInsets.only(top: 16, right: 16, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (_scoreHistory.length - 1).toDouble(),
              minY: 0,
              maxY: 100,
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: _scoreHistory,
                  isCurved: true,
                  preventCurveOverShooting: true,
                  color: Theme.of(context).colorScheme.primary,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStreakCard(ProgressData data) {
    final atRisk = ref.read(streakServiceProvider).isStreakAtRisk(null);
    final milestone =
        ref.read(streakServiceProvider).streakMilestone(data.currentStreak);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: atRisk ? Colors.orange.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: atRisk
            ? Border.all(color: Colors.orange.shade200)
            : null,
      ),
      child: Row(
        children: [
          Text(
            milestone != null ? '🔥' : '🔥',
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${data.currentStreak} Day Streak',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  milestone ?? 'Keep the momentum going!',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                if (atRisk) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Practice today to keep your streak!',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(ProgressData data) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildStatTile(
            Icons.chat, '${data.sessionCount}', 'Sessions'),
        _buildStatTile(
            Icons.timer_outlined, '${data.totalMinutes}', 'Min Practiced'),
        _buildStatTile(Icons.speed, '${data.avgSessionMinutes}',
            'Avg Min/Session'),
        _buildStatTile(
            Icons.local_fire_department, '${data.currentStreak}', 'Day Streak'),
      ],
    );
  }

  Widget _buildStatTile(IconData icon, String value, String label) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 72) / 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(label,
                style:
                    TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}
