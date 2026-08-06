import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenRouterService {
  final String _apiKey;
  final String _model;
  final http.Client _client;

  OpenRouterService({http.Client? client})
      : _apiKey = dotenv.env['OPENROUTER_API_KEY'] ?? '',
        _model = dotenv.env['OPENROUTER_MODEL'] ?? 'openai/gpt-4o-mini',
        _client = client ?? http.Client();

  Future<String> chat(
    List<Map<String, String>> messages, {
    String? systemPrompt,
  }) async {
    final allMessages = <Map<String, String>>[];

    final prompt = systemPrompt ?? _defaultSystemPrompt();

    allMessages.add({'role': 'system', 'content': prompt});
    allMessages.addAll(messages);

    final response = await _client.post(
      Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://olympuslanguage.ai',
        'X-Title': 'Olympus Language AI',
      },
      body: jsonEncode({
        'model': _model,
        'messages': allMessages,
        'max_tokens': 300,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode != 200) {
      throw OpenRouterException(
        'LLM failed: ${response.statusCode} ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>;
    return choices[0]['message']['content'] as String;
  }

  String _defaultSystemPrompt() => '''
You are a patient, friendly language tutor. You are speaking with a language learner.

Guidelines:
- Keep responses SHORT — 1 to 3 sentences maximum.
- Speak naturally, like a real person in conversation.
- If the learner makes a mistake, gently correct it within your response without breaking flow. Example: "Actually, it's 'went' not 'goed'. So you went to the park yesterday? That sounds nice!"
- Match the learner's pace and vocabulary level.
- Stay on topic — don't switch subjects abruptly.
- End most responses with a natural follow-up question.
- You are SPEAKING, not writing. No markdown, no lists, no emoji.''';

  void dispose() => _client.close();
}

class OpenRouterException implements Exception {
  final String message;
  OpenRouterException(this.message);

  @override
  String toString() => message;
}
