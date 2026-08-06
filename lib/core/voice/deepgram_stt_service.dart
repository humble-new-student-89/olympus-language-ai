import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DeepgramSttService {
  final String _apiKey;
  final http.Client _client;

  DeepgramSttService({http.Client? client})
      : _apiKey = dotenv.env['DEEPGRAM_API_KEY'] ?? '',
        _client = client ?? http.Client();

  Future<String> transcribe(String audioFilePath) async {
    final uri = Uri.parse(
      'https://api.deepgram.com/v1/listen?model=nova-3&language=en&smart_format=true',
    );
    final file = File(audioFilePath);
    final bytes = await file.readAsBytes();

    final response = await _client.post(
      uri,
      headers: {
        'Authorization': 'Token $_apiKey',
        'Content-Type': 'audio/wav',
      },
      body: bytes,
    );

    if (response.statusCode != 200) {
      throw DeepgramException('STT failed: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final transcript = data['results']?['channels']?[0]?['alternatives']?[0]?['transcript'] as String?;
    return transcript ?? '';
  }

  void dispose() => _client.close();
}

class DeepgramException implements Exception {
  final String message;
  DeepgramException(this.message);

  @override
  String toString() => message;
}
