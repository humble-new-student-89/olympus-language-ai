import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers.dart';
import '../../../auth/domain/auth_state.dart';
import '../../../conversation/domain/scenarios.dart';
import '../../../conversation/domain/models.dart';
import '../../../conversation/presentation/conversation_notifier.dart';
import '../../../conversation/presentation/providers.dart';
import '../../../conversation/presentation/screens/recap_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _totalMinutes = 0;
  String _plan = 'free';
  int _streak = 0;
  bool _loaded = false;

  static const int trialMinutesLimit = 10;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = ref.read(authStateProvider);
    if (user is! AuthAuthenticated) return;

    final firestore = ref.read(firestoreServiceProvider);
    final doc = await firestore.getUser(user.user.uid);
    final data = doc.data() as Map<String, dynamic>?;
    if (data != null && mounted) {
      setState(() {
        _totalMinutes = (data['totalMinutesUsed'] as int?) ?? 0;
        _plan = (data['plan'] as String?) ?? 'free';
        _streak = (data['currentStreak'] as int?) ?? 0;
        _loaded = true;
      });
    }
  }

  Future<void> _startConversation({
    String? scenarioId,
    String? scenarioName,
  }) async {
    try {
      final recap = await context.push<SessionRecap>(
        scenarioId != null ? '/conversation/$scenarioId' : '/conversation',
      );
      if (recap != null && mounted) {
        final navigator = Navigator.of(context);
        _loadUserData();
        navigator.push(
          MaterialPageRoute(
            builder: (_) => RecapScreen(recap: recap),
          ),
        );
      }
      if (mounted) _loadUserData();
    } on UsageExceededException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Free trial exhausted: ${e.minutesUsed} / ${e.trialLimit} minutes',
            ),
            action: SnackBarAction(
              label: 'Upgrade',
              onPressed: () => context.push('/paywall'),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFree = _plan == 'free' || _plan == 'trial';
    final usagePercent = isFree
        ? (_totalMinutes / trialMinutesLimit).clamp(0.0, 1.0)
        : 1.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Olympus'),
        actions: [
          if (_loaded && _streak > 0)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Chip(
                avatar: const Text('🔥', style: TextStyle(fontSize: 14)),
                label: Text('$_streak'),
                backgroundColor: Colors.orange.shade50,
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.insights),
            onPressed: () => context.go('/progress'),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.go('/history'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authStateProvider.notifier).signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ready to practice?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose a scenario or start a free conversation.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              if (_loaded && isFree) ...[
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: usagePercent,
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation(
                            usagePercent > 0.8
                                ? Colors.orange
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$_totalMinutes / $trialMinutesLimit min',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (usagePercent >= 1.0)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/paywall'),
                      icon: const Icon(Icons.workspace_premium, size: 18),
                      label: const Text('Upgrade to Unlimited',
                          style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.deepPurple,
                        side: const BorderSide(color: Colors.deepPurple),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
              ],

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => _startConversation(),
                  icon: const Icon(Icons.mic, size: 28),
                  label: const Text(
                    'Free Conversation',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                'Scenarios',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Practice real-world situations',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              ...predefinedScenarios.map(
                (scenario) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _startConversation(
                        scenarioId: scenario.id,
                        scenarioName: scenario.name,
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Text(
                            scenario.icon,
                            style: const TextStyle(fontSize: 28),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  scenario.name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  scenario.description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.play_circle_outline,
                              color: Theme.of(context).colorScheme.primary),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
