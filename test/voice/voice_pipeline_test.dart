import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:olympus_language_ai/core/voice/voice_pipeline.dart';
import 'package:olympus_language_ai/core/voice/deepgram_stt_service.dart';
import 'package:olympus_language_ai/core/voice/deepgram_tts_service.dart';
import 'package:olympus_language_ai/core/voice/openrouter_service.dart';
import 'package:olympus_language_ai/features/conversation/domain/models.dart';

class MockStt extends Mock implements DeepgramSttService {}

class MockTts extends Mock implements DeepgramTtsService {}

class MockLlm extends Mock implements OpenRouterService {}

void main() {
  late VoicePipeline pipeline;
  late MockStt mockStt;
  late MockLlm mockLlm;
  late MockTts mockTts;

  setUp(() {
    mockStt = MockStt();
    mockLlm = MockLlm();
    mockTts = MockTts();
    pipeline = VoicePipeline(stt: mockStt, llm: mockLlm, tts: mockTts);
  });

  group('processTurn', () {
    test('orchestrates STT -> LLM -> TTS and returns VoiceTurn', () async {
      when(() => mockStt.transcribe(any()))
          .thenAnswer((_) async => 'Hello, how are you?');
      when(() => mockLlm.chat(any(),
              systemPrompt: any(named: 'systemPrompt'),
              fluencyLevel: any(named: 'fluencyLevel')))
          .thenAnswer((_) async => OpenRouterChatResult(
              response: 'I am doing well, thank you!',
              correction: null));
      when(() => mockTts.synthesize(any()))
          .thenAnswer((_) async => Uint8List.fromList([1, 2, 3]));

      final turn = await pipeline.processTurn(
        audioFilePath: '/tmp/test.wav',
        history: [],
      );

      expect(turn.userTranscript, 'Hello, how are you?');
      expect(turn.aiResponse, 'I am doing well, thank you!');
      expect(turn.correction, null);
      expect(turn.audio, isNotEmpty);
    });

    test('carries correction when LLM returns one', () async {
      when(() => mockStt.transcribe(any()))
          .thenAnswer((_) async => 'I goed to the park');
      when(() => mockLlm.chat(any(),
              systemPrompt: any(named: 'systemPrompt'),
              fluencyLevel: any(named: 'fluencyLevel')))
          .thenAnswer((_) async => OpenRouterChatResult(
              response: 'You went to the park!',
              correction: 'Use "went" not "goed"'));
      when(() => mockTts.synthesize(any()))
          .thenAnswer((_) async => Uint8List.fromList([1, 2, 3]));

      final turn = await pipeline.processTurn(
        audioFilePath: '/tmp/test.wav',
        history: [],
      );

      expect(turn.correction, 'Use "went" not "goed"');
    });

    test('throws VoicePipelineException on empty transcript', () async {
      when(() => mockStt.transcribe(any())).thenAnswer((_) async => '');

      expect(
        () => pipeline.processTurn(audioFilePath: '/tmp/test.wav', history: []),
        throwsA(isA<VoicePipelineException>()),
      );
    });
  });

  group('generateRecap', () {
    test('returns SessionRecapData from LLM recap', () async {
      when(() => mockLlm.recap(any())).thenAnswer((_) async => {
            'mistakes': ['Used wrong tense'],
            'strength': 'Good job!',
          });

      final recapData = await pipeline.generateRecap(
        messages: [
          ChatMessage(role: 'user', content: 'Hi'),
          ChatMessage(role: 'assistant', content: 'Hello!'),
        ],
        durationSeconds: 60,
      );

      expect(recapData.topMistakes, ['Used wrong tense']);
      expect(recapData.strength, 'Good job!');
    });

    test('handles null mistakes in recap response', () async {
      when(() => mockLlm.recap(any())).thenAnswer((_) async => {
            'strength': 'Great conversation flow',
          });

      final recapData = await pipeline.generateRecap(
        messages: [
          ChatMessage(role: 'user', content: 'Hello'),
        ],
        durationSeconds: 30,
      );

      expect(recapData.topMistakes, isEmpty);
      expect(recapData.strength, 'Great conversation flow');
    });
  });
}
