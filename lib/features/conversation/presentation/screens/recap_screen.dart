import 'package:flutter/material.dart';
import '../../domain/models.dart';

class RecapScreen extends StatelessWidget {
  final SessionRecap recap;

  const RecapScreen({super.key, required this.recap});

  @override
  Widget build(BuildContext context) {
    final durationMin = recap.durationSeconds ~/ 60;
    final durationSec = recap.durationSeconds % 60;
    final durationStr =
        '${durationMin}m ${durationSec.toString().padLeft(2, '0')}s';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Recap'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              Container(
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
                    const Icon(Icons.emoji_events, size: 48, color: Colors.white),
                    const SizedBox(height: 12),
                    const Text(
                      'Great session!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      recap.scenarioName != null
                          ? 'Scenario: ${recap.scenarioName}'
                          : 'Free conversation',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Stats row
              Row(
                children: [
                  _StatCard(
                    icon: Icons.timer_outlined,
                    label: 'Duration',
                    value: durationStr,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    icon: Icons.chat_bubble_outline,
                    label: 'Messages',
                    value: '${recap.messageCount}',
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    icon: Icons.mic,
                    label: 'Turns',
                    value: '${recap.messageCount ~/ 2}',
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Strength
              if (recap.strength.isNotEmpty) ...[
                const Text(
                  'What you did well',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          recap.strength,
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Mistakes
              if (recap.topMistakes.isNotEmpty) ...[
                const Text(
                  'Things to improve',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...recap.topMistakes.map(
                  (mistake) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.lightbulb_outline,
                              color: Colors.orange.shade700, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              mistake,
                              style: TextStyle(
                                color: Colors.orange.shade900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              // Transcript preview
              if (recap.messages.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'Conversation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...recap.messages.map(
                  (msg) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: msg.role == 'user'
                              ? Colors.blue.shade100
                              : Colors.green.shade100,
                          child: Text(
                            msg.role == 'user' ? 'Y' : 'P',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: msg.role == 'user'
                                  ? Colors.blue.shade700
                                  : Colors.green.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg.role == 'user' ? 'You' : 'Partner',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: msg.role == 'user'
                                      ? Colors.blue.shade600
                                      : Colors.green.shade600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                msg.content,
                                style: const TextStyle(fontSize: 13),
                              ),
                              if (msg.role == 'assistant' &&
                                  msg.correction != null) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                        color: Colors.orange.shade200),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.lightbulb_outline,
                                          size: 12,
                                          color: Colors.orange.shade700),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          msg.correction!,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.orange.shade800,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: Colors.grey.shade600),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
