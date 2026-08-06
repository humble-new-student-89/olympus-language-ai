import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers.dart';
import '../../../auth/domain/auth_state.dart';
import '../../../conversation/presentation/providers.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session History'),
      ),
      body: user is AuthAuthenticated
          ? _HistoryList(userId: user.user.uid)
          : const Center(child: Text('Please sign in to view history.')),
    );
  }
}

class _HistoryList extends ConsumerStatefulWidget {
  final String userId;

  const _HistoryList({required this.userId});

  @override
  ConsumerState<_HistoryList> createState() => _HistoryListState();
}

class _HistoryListState extends ConsumerState<_HistoryList> {
  late Future<List<Map<String, dynamic>>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  void _loadSessions() {
    final repo = ref.read(conversationRepositoryProvider);
    _sessionsFuture = repo.getSessions(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _sessionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 8),
                const Text('Failed to load sessions'),
                TextButton(
                  onPressed: () {
                    setState(() => _loadSessions());
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final sessions = snapshot.data ?? [];

        if (sessions.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No conversations yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 4),
                Text(
                  'Start speaking to build your history!',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() => _loadSessions());
            await _sessionsFuture;
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              final date = session['startedAt'] as DateTime?;
              final duration = session['durationSeconds'] as int? ?? 0;
              final transcriptCount = session['transcriptCount'] as int? ?? 0;
              final scenarioName = session['scenarioName'] as String?;
              final topMistakes =
                  (session['topMistakes'] as List<dynamic>?)?.cast<String>();
              final endedAt = session['endedAt'] as DateTime?;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    scenarioName ?? 'Free Conversation',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(_formatDate(date)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.timer_outlined,
                              size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            _formatDuration(duration),
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.chat_bubble_outline,
                              size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            '$transcriptCount messages',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      if (endedAt == null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'In progress',
                            style: TextStyle(
                                fontSize: 11, color: Colors.orange.shade800),
                          ),
                        ),
                      ],
                      if (topMistakes != null && topMistakes.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          '${topMistakes.length} mistake${topMistakes.length > 1 ? 's' : ''} identified',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                              fontStyle: FontStyle.italic),
                        ),
                      ],
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showSessionDetail(
                        context, session, ref);
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showSessionDetail(
      BuildContext context,
      Map<String, dynamic> session,
      WidgetRef ref) {
    final scenarioName = session['scenarioName'] as String?;
    final topMistakes =
        (session['topMistakes'] as List<dynamic>?)?.cast<String>() ?? [];
    final strength = session['strength'] as String? ?? '';
    final duration = session['durationSeconds'] as int? ?? 0;
    final date = session['startedAt'] as DateTime?;
    final sessionId = session['id'] as String;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _SessionDetailSheet(
        sessionId: sessionId,
        scenarioName: scenarioName,
        date: date,
        duration: duration,
        topMistakes: topMistakes,
        strength: strength,
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown date';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }
}

class _SessionDetailSheet extends ConsumerStatefulWidget {
  final String sessionId;
  final String? scenarioName;
  final DateTime? date;
  final int duration;
  final List<String> topMistakes;
  final String strength;

  const _SessionDetailSheet({
    required this.sessionId,
    this.scenarioName,
    this.date,
    required this.duration,
    required this.topMistakes,
    required this.strength,
  });

  @override
  ConsumerState<_SessionDetailSheet> createState() =>
      _SessionDetailSheetState();
}

class _SessionDetailSheetState extends ConsumerState<_SessionDetailSheet> {
  late Future<List<Map<String, dynamic>>> _transcriptsFuture;

  @override
  void initState() {
    super.initState();
    final repo = ref.read(conversationRepositoryProvider);
    _transcriptsFuture = repo.getTranscripts(widget.sessionId);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.scenarioName ?? 'Free Conversation',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(widget.date),
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              Text(
                'Duration: ${widget.duration ~/ 60}m ${widget.duration % 60}s',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              if (widget.strength.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle,
                          color: Colors.green.shade700, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.strength,
                          style: TextStyle(
                              color: Colors.green.shade800, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (widget.topMistakes.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...widget.topMistakes.map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lightbulb_outline,
                              color: Colors.orange.shade700, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(m,
                                style: TextStyle(
                                    color: Colors.orange.shade900,
                                    fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const Divider(),
              const Text(
                'Transcript',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _transcriptsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ));
                  }

                  final transcripts = snapshot.data ?? [];

                  if (transcripts.isEmpty) {
                    return const Text('No transcript data.');
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: transcripts.length,
                    itemBuilder: (context, index) {
                      final t = transcripts[index];
                      final isUser = t['speaker'] == 'user';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: isUser
                                  ? Colors.blue.shade100
                                  : Colors.green.shade100,
                              child: Text(
                                isUser ? 'Y' : 'P',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isUser
                                        ? Colors.blue.shade700
                                        : Colors.green.shade700),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                t['text'] ?? '',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
