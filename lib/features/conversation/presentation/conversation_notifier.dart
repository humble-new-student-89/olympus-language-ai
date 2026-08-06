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

  String? get currentScenarioId {
    return switch (state) {
      ConversationIdle(scenarioId: final id) => id,
      ConversationRecording(scenarioId: final id) => id,
      ConversationProcessing(scenarioId: final id) => id,
      ConversationSpeaking(scenarioId: final id) => id,
      ConversationError(scenarioId: final id) => id,
    };
  }

  String? get currentScenarioName {
    return switch (state) {
      ConversationIdle(scenarioName: final n) => n,
      ConversationRecording(scenarioName: final n) => n,
      ConversationProcessing(scenarioName: final n) => n,
      ConversationSpeaking(scenarioName: final n) => n,
      ConversationError(scenarioName: final n) => n,
    };
  }

  void setScenarioPrompt(String? prompt) {
    _scenarioSystemPrompt = prompt;
  }

  Future<void> startSession({String? scenarioId, String? scenarioName}) async {
    final user = FirebaseConfig.auth.currentUser;
    if (user == null) return;

    final sessionId = await _repository.startSession(
      userId: user.uid,
      scenarioId: scenarioId,
      scenarioName: scenarioName,
    );
    _sessionStartTime = DateTime.now();
    state = ConversationIdle(
      sessionId: sessionId,
      scenarioId: scenarioId,
      scenarioName: scenarioName,
    );
  }

  void startRecording() {
    final sessionId = currentSessionId;
    if (sessionId == null) return;

    state = ConversationRecording(
      messages: _currentMessages,
      sessionId: sessionId,
      scenarioId: currentScenarioId,
      scenarioName: currentScenarioName,
    );
  }

  Future<void> processTurn(String audioFilePath) async {
    final sessionId = currentSessionId;
    if (sessionId == null) return;

    state = ConversationProcessing(
      messages: _currentMessages,
      sessionId: sessionId,
      scenarioId: currentScenarioId,
      scenarioName: currentScenarioName,
    );

    try {
      final history =
          _currentMessages.whereType<ChatMessage>().toList();

      final turn = await _pipeline.processTurn(
        audioFilePath: audioFilePath,
        history: history,
        systemPrompt: _scenarioSystemPrompt,
      );

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

      final updatedMessages = [
        ..._currentMessages.whereType<ChatMessage>(),
        ChatMessage(role: 'user', content: turn.userTranscript),
        ChatMessage(role: 'assistant', content: turn.aiResponse),
      ];

      state = ConversationSpeaking(
        messages: updatedMessages,
        sessionId: sessionId,
        scenarioId: currentScenarioId,
        scenarioName: currentScenarioName,
      );

      final tempDir = await getTemporaryDirectory();
      final audioFile = File('${tempDir.path}/response.mp3');
      await audioFile.writeAsBytes(turn.audio);

      _player.onPlayerComplete.listen((_) {
        if (state is ConversationSpeaking) {
          state = ConversationIdle(
            messages: updatedMessages,
            sessionId: sessionId,
            scenarioId: currentScenarioId,
            scenarioName: currentScenarioName,
          );
        }
      });

      await _player.play(DeviceFileSource(audioFile.path));
    } catch (e) {
      state = ConversationError(
        message: e.toString(),
        messages: _currentMessages,
        sessionId: sessionId,
        scenarioId: currentScenarioId,
        scenarioName: currentScenarioName,
      );
    }
  }

  Future<SessionRecap> endSession() async {
    final sessionId = currentSessionId;
    final durationSeconds = _sessionStartTime != null
        ? DateTime.now().difference(_sessionStartTime!).inSeconds
        : 0;

    if (sessionId != null) {
      await _repository.endSession(sessionId, durationSeconds);
    }

    await _player.dispose();

    final messages = _currentMessages.whereType<ChatMessage>().toList();

    SessionRecap recap;
    if (messages.length >= 2) {
      try {
        final recapData = await _pipeline.generateRecap(
          messages: messages,
          durationSeconds: durationSeconds,
        );
        recap = SessionRecap(
          sessionId: sessionId ?? '',
          scenarioName: currentScenarioName,
          startedAt: _sessionStartTime ?? DateTime.now(),
          durationSeconds: durationSeconds,
          messageCount: messages.length,
          messages: messages,
          topMistakes: recapData.topMistakes,
          strength: recapData.strength,
        );

        if (sessionId != null) {
          await _repository.saveRecap(
            sessionId,
            topMistakes: recapData.topMistakes,
            strength: recapData.strength,
          );
        }
      } catch (_) {
        recap = _buildLocalRecap(messages, durationSeconds);
      }
    } else {
      recap = _buildLocalRecap(messages, durationSeconds);
    }

    state = ConversationIdle();
    return recap;
  }

  SessionRecap _buildLocalRecap(
      List<ChatMessage> messages, int durationSeconds) {
    return SessionRecap(
      sessionId: currentSessionId ?? '',
      scenarioName: currentScenarioName,
      startedAt: _sessionStartTime ?? DateTime.now(),
      durationSeconds: durationSeconds,
      messageCount: messages.length,
      messages: messages,
      topMistakes: const [],
      strength: 'You completed a conversation session! Keep practicing daily.',
    );
  }

  void clearError() {
    final sessionId = currentSessionId;
    state = ConversationIdle(
      messages: _currentMessages,
      sessionId: sessionId,
      scenarioId: currentScenarioId,
      scenarioName: currentScenarioName,
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
