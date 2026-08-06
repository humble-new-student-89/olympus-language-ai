import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:olympus_language_ai/core/voice/openrouter_service.dart';

class MockHttpClient extends Mock implements http.Client {}

class FakeUri extends Fake implements Uri {}

void main() {
  late OpenRouterService service;
  late MockHttpClient mockClient;

  setUpAll(() {
    registerFallbackValue(FakeUri());
  });

  setUp(() {
    mockClient = MockHttpClient();
    service = OpenRouterService.test(apiKey: 'test-key', model: 'test-model', client: mockClient);
  });

  group('chat', () {
    test('returns OpenRouterChatResult with response and correction', () async {
      final jsonResponse = jsonEncode({
        'choices': [
          {
            'message': {
              'content': jsonEncode({
                'response': 'I went to the park yesterday.',
                'correction': 'Use "went" not "goed"',
              }),
            }
          }
        ]
      });

      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(jsonResponse, 200));

      final result = await service.chat([]);

      expect(result.response, 'I went to the park yesterday.');
      expect(result.correction, 'Use "went" not "goed"');
    });

    test('returns null correction when correction is null in JSON', () async {
      final jsonResponse = jsonEncode({
        'choices': [
          {
            'message': {
              'content': jsonEncode({
                'response': 'Great job!',
                'correction': null,
              }),
            }
          }
        ]
      });

      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(jsonResponse, 200));

      final result = await service.chat([]);

      expect(result.response, 'Great job!');
      expect(result.correction, null);
    });

    test('handles malformed JSON gracefully by using raw text', () async {
      final rawText = 'Hello, how are you?';
      final jsonResponse = jsonEncode({
        'choices': [
          {
            'message': {
              'content': rawText,
            }
          }
        ]
      });

      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(jsonResponse, 200));

      final result = await service.chat([]);

      expect(result.response, rawText);
      expect(result.correction, null);
    });

    test('throws OpenRouterException on non-200 response', () async {
      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('Error', 500));

      expect(() => service.chat([]), throwsA(isA<OpenRouterException>()));
    });
  });

  group('recap', () {
    test('returns parsed recap data', () async {
      final recapJson = jsonEncode({
        'mistakes': ['Used wrong tense'],
        'strength': 'Good pronunciation',
      });
      final jsonResponse = jsonEncode({
        'choices': [
          {
            'message': {
              'content': recapJson,
            }
          }
        ]
      });

      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(jsonResponse, 200));

      final result = await service.recap('test conversation');

      expect(result['mistakes'], ['Used wrong tense']);
      expect(result['strength'], 'Good pronunciation');
    });
  });
}
