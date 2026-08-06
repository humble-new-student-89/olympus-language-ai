import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/conversation_state.dart';
import '../../domain/models.dart';
import '../providers.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({super.key});

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(conversationStateProvider.notifier).startSession();
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

  void _endSession() {
    ref.read(conversationStateProvider.notifier).endSession();
    if (mounted) Navigator.of(context).pop();
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

    // Show last 4 messages
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversation'),
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
