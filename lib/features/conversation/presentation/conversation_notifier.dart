import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../../../core/voice/voice_pipeline.dart';
import '../../../core/firebase/firebase_config.dart';
import '../domain/conversation_state.dart';
import '../domain/models.dart';
import '../data/conversation_repository.dart';

class ConversationNotifier extends StateNotifier<ConversationState> {
  final VoicePipeline _pipeline;
  final ConversationRepository _repository;
  final AudioPlayer _player = AudioPlayer();
  DateTime? _sessionStartTime;
  String? _scenarioSystemPrompt;

  ConversationNotifier({
    required VoicePipeline pipeline,
    required ConversationRepository repository,
  })  : _pipeline = pipeline,
        _repository = repository,
        super(ConversationIdle());

  String? get currentSessionId {
    return switch (state) {
      ConversationIdle(sessionId: final id) => id,
      ConversationRecording(sessionId: final id) => id,
      ConversationProcessing(sessionId: final id) => id,
      ConversationSpeaking(sessionId: final id) => id,
      ConversationError(sessionId: final id) => id,
    };
  }

  void setScenarioPrompt(String? prompt) {
    _scenarioSystemPrompt = prompt;
  }

  Future<void> startSession({String? scenarioId}) async {
    final user = FirebaseConfig.auth.currentUser;
    if (user == null) return;

    final sessionId = await _repository.startSession(
      userId: user.uid,
      scenarioId: scenarioId,
    );
    _sessionStartTime = DateTime.now();
    state = ConversationIdle(sessionId: sessionId);
  }

  void startRecording() {
    final sessionId = currentSessionId;
    if (sessionId == null) return;

    state = ConversationRecording(
      messages: _currentMessages,
      sessionId: sessionId,
    );
  }

  Future<void> processTurn(String audioFilePath) async {
    final sessionId = currentSessionId;
    if (sessionId == null) return;

    state = ConversationProcessing(
      messages: _currentMessages,
      sessionId: sessionId,
    );

    try {
      final history = _currentMessages
          .whereType<ChatMessage>()
          .toList();

      final turn = await _pipeline.processTurn(
        audioFilePath: audioFilePath,
        history: history,
        systemPrompt: _scenarioSystemPrompt,
      );

      // Save transcripts
      final user = FirebaseConfig.auth.currentUser;
      if (user != null) {
        await _repository.saveTranscript(
          sessionId: sessionId,
          userId: user.uid,
          text: turn.userTranscript,
        );
        await _repository.saveTranscript(
          sessionId: sessionId,
          userId: user.uid,
          text: turn.aiResponse,
          isUser: false,
        );
      }

      // Add to history
      final updatedMessages = [
        ..._currentMessages.whereType<ChatMessage>(),
        ChatMessage(role: 'user', content: turn.userTranscript),
        ChatMessage(role: 'assistant', content: turn.aiResponse),
      ];

      // Play audio
      state = ConversationSpeaking(
        messages: updatedMessages,
        sessionId: sessionId,
      );

      final tempDir = await getTemporaryDirectory();
      final audioFile = File('${tempDir.path}/response.mp3');
      await audioFile.writeAsBytes(turn.audio);

      _player.onPlayerComplete.listen((_) {
        if (state is ConversationSpeaking) {
          state = ConversationIdle(
            messages: updatedMessages,
            sessionId: sessionId,
          );
        }
      });

      await _player.play(DeviceFileSource(audioFile.path));
    } catch (e) {
      state = ConversationError(
        message: e.toString(),
        messages: _currentMessages,
        sessionId: sessionId,
      );
    }
  }

  Future<void> endSession() async {
    final sessionId = currentSessionId;
    if (sessionId != null && _sessionStartTime != null) {
      final duration = DateTime.now().difference(_sessionStartTime!).inSeconds;
      await _repository.endSession(sessionId, duration);
    }
    await _player.dispose();
    state = ConversationIdle();
  }

  void clearError() {
    final sessionId = currentSessionId;
    state = ConversationIdle(
      messages: _currentMessages,
      sessionId: sessionId,
    );
  }

  List<dynamic> get _currentMessages {
    return switch (state) {
      ConversationIdle(messages: final m) => m,
      ConversationRecording(messages: final m) => m,
      ConversationProcessing(messages: final m) => m,
      ConversationSpeaking(messages: final m) => m,
      ConversationError(messages: final m) => m,
    };
  }
}
