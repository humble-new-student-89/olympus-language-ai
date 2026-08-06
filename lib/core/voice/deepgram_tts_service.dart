import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DeepgramTtsService {
  final String _apiKey;
  final http.Client _client;

  DeepgramTtsService({http.Client? client})
      : _apiKey = dotenv.env['DEEPGRAM_API_KEY'] ?? '',
        _client = client ?? http.Client();

  Future<Uint8List> synthesize(String text) async {
    final uri = Uri.parse(
      'https://api.deepgram.com/v1/speak?model=aura-asteria-en',
    );

    final response = await _client.post(
      uri,
      headers: {
        'Authorization': 'Token $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'text': text}),
    );

    if (response.statusCode != 200) {
      throw DeepgramTtsException('TTS failed: ${response.statusCode} ${response.body}');
    }

    return response.bodyBytes;
  }

  void dispose() => _client.close();
}

class DeepgramTtsException implements Exception {
  final String message;
  DeepgramTtsException(this.message);

  @override
  String toString() => message;
}
