import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/conversation_state.dart';
import '../../domain/models.dart';
import '../../domain/scenarios.dart';
import '../../../milestones/domain/milestone_service.dart';
import '../../../milestones/presentation/milestone_card.dart';
import '../conversation_notifier.dart';
import '../providers.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  final String? scenarioId;

  const ConversationScreen({super.key, this.scenarioId});

  @override
  ConsumerState<ConversationScreen> createState() =>
      _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final scenario = widget.scenarioId != null
          ? predefinedScenarios.where((s) => s.id == widget.scenarioId).firstOrNull
          : null;

      ref.read(conversationStateProvider.notifier).setScenarioPrompt(
            scenario?.systemPrompt,
          );

      try {
        await ref.read(conversationStateProvider.notifier).startSession(
              scenarioId: scenario?.id,
              scenarioName: scenario?.name,
            );
      } on UsageExceededException {
        if (mounted) {
          context.push('/paywall');
        }
      }
    });
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) return;

    final tempDir = await getTemporaryDirectory();
    final path = '${tempDir.path}/recording.wav';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.wav),
      path: path,
    );
    setState(() => _isRecording = true);
    ref.read(conversationStateProvider.notifier).startRecording();
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    setState(() => _isRecording = false);

    if (path != null && mounted) {
      await ref.read(conversationStateProvider.notifier).processTurn(path);
    }
  }

  Future<void> _endSession() async {
    final recap =
        await ref.read(conversationStateProvider.notifier).endSession();
    if (!mounted) return;
    final milestones = ref.read(conversationStateProvider.notifier).newMilestones;
    if (milestones.isNotEmpty) {
      if (!mounted) return;
      _showMilestoneCelebration(context, milestones);
      await Future.delayed(const Duration(seconds: 2));
    }
    if (!mounted) return;
    Navigator.of(context).pop(recap);
  }

  void _showMilestoneCelebration(BuildContext context, List<Milestone> milestones) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            const Text(
              'Milestone Unlocked!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...milestones.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: MilestoneCard(milestone: m),
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Awesome!'),
          ),
        ],
      ),
    );
  }

  Widget _buildStateIndicator(ConversationState state) {
    String label = '';
    Widget icon = const SizedBox.shrink();

    switch (state) {
      case ConversationIdle():
        label = 'Hold to speak';
        icon = const Icon(Icons.mic, size: 48, color: Colors.white);
      case ConversationRecording():
        label = 'Listening...';
        icon = const Icon(Icons.mic, size: 48, color: Colors.red);
      case ConversationProcessing():
        label = 'Thinking...';
        icon = const SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(color: Colors.white),
        );
      case ConversationSpeaking():
        label = 'Speaking...';
        icon = const Icon(Icons.volume_up, size: 48, color: Colors.white);
      case ConversationError(message: final msg):
        label = msg;
        icon = const Icon(Icons.error_outline, size: 48, color: Colors.red);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: state is ConversationRecording
                ? Colors.red.shade700
                : Theme.of(context).colorScheme.primary,
          ),
          child: Center(child: icon),
        ),
        const SizedBox(height: 16),
        Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
      ],
    );
  }

  Widget _buildTranscript() {
    final state = ref.watch(conversationStateProvider);
    final messages = switch (state) {
      ConversationIdle(messages: final m) => m,
      ConversationRecording(messages: final m) => m,
      ConversationProcessing(messages: final m) => m,
      ConversationSpeaking(messages: final m) => m,
      ConversationError(messages: final m) => m,
    };

    if (messages.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'Press and hold the mic button\nto start speaking.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    final recent = messages.length > 4
        ? messages.sublist(messages.length - 4)
        : messages;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: recent.length,
        itemBuilder: (context, index) {
          final msg = recent[index] as ChatMessage;
          final isUser = msg.role == 'user';

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  isUser ? 'You' : 'Partner',
                  style: TextStyle(
                    fontSize: 11,
                    color: isUser ? Colors.blue : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  msg.content,
                  style: const TextStyle(fontSize: 14),
                ),
                if (!isUser && msg.correction != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lightbulb_outline,
                            size: 14, color: Colors.orange.shade700),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            msg.correction!,
                            style: TextStyle(
                              fontSize: 12,
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
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(conversationStateProvider);
    final scenarioName = switch (state) {
      ConversationIdle(scenarioName: final n) => n,
      ConversationRecording(scenarioName: final n) => n,
      ConversationProcessing(scenarioName: final n) => n,
      ConversationSpeaking(scenarioName: final n) => n,
      ConversationError(scenarioName: final n) => n,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(scenarioName ?? 'Conversation'),
        actions: [
          TextButton(
            onPressed:
                state is ConversationIdle || state is ConversationError
                    ? _endSession
                    : null,
            child: const Text('End', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(child: _buildTranscript()),
            ),
            const SizedBox(height: 24),
            _buildStateIndicator(state),
            const SizedBox(height: 16),
            if (state is ConversationError)
              TextButton(
                onPressed: () =>
                    ref.read(conversationStateProvider.notifier).clearError(),
                child: const Text('Try again'),
              ),
            const SizedBox(height: 48),
            GestureDetector(
              onTapDown: (_) {
                if (state is ConversationIdle) _startRecording();
              },
              onTapUp: (_) {
                if (_isRecording) _stopRecording();
              },
              onTapCancel: () {
                if (_isRecording) _stopRecording();
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isRecording
                        ? Colors.red
                        : Theme.of(context).colorScheme.primary,
                    boxShadow: [
                      BoxShadow(
                        color: (_isRecording ? Colors.red : Theme.of(context).colorScheme.primary)
                            .withValues(alpha: 0.4),
                        blurRadius: 16,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
