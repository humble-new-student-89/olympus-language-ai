import 'dart:typed_data';
import '../../features/conversation/domain/models.dart';
import 'deepgram_stt_service.dart';
import 'deepgram_tts_service.dart';
import 'openrouter_service.dart';

class VoicePipeline {
  final DeepgramSttService _stt;
  final OpenRouterService _llm;
  final DeepgramTtsService _tts;

  VoicePipeline({
    required DeepgramSttService stt,
    required OpenRouterService llm,
    required DeepgramTtsService tts,
  })  : _stt = stt,
        _llm = llm,
        _tts = tts;

  Future<VoiceTurn> processTurn({
    required String audioFilePath,
    required List<ChatMessage> history,
    String? systemPrompt,
    String? fluencyLevel,
  }) async {
    final transcript = await _stt.transcribe(audioFilePath);

    if (transcript.isEmpty) {
      throw VoicePipelineException('No speech detected.');
    }

    final messages = history.map((m) => m.toMap()).toList();
    messages.add({'role': 'user', 'content': transcript});

    final result = await _llm.chat(
      messages,
      systemPrompt: systemPrompt,
      fluencyLevel: fluencyLevel,
    );

    final audioBytes = await _tts.synthesize(result.response);

    return VoiceTurn(
      userTranscript: transcript,
      aiResponse: result.response,
      correction: result.correction,
      audio: audioBytes,
    );
  }

  Future<SessionRecapData> generateRecap({
    required List<ChatMessage> messages,
    required int durationSeconds,
  }) async {
    final content = messages.map((m) => '${m.role}: ${m.content}').join('\n');

    final summary = await _llm.recap(content);
    final mistakes = summary['mistakes'] as List<String>? ?? [];
    final strength = summary['strength'] as String? ?? '';

    return SessionRecapData(
      topMistakes: mistakes,
      strength: strength,
    );
  }

  void dispose() {
    _stt.dispose();
    _llm.dispose();
    _tts.dispose();
  }
}

class VoicePipelineException implements Exception {
  final String message;
  VoicePipelineException(this.message);

  @override
  String toString() => message;
}

class VoiceTurn {
  final String userTranscript;
  final String aiResponse;
  final String? correction;
  final Uint8List audio;

  VoiceTurn({
    required this.userTranscript,
    required this.aiResponse,
    this.correction,
    required this.audio,
  });
}

class SessionRecapData {
  final List<String> topMistakes;
  final String strength;

  SessionRecapData({
    required this.topMistakes,
    required this.strength,
  });
}
