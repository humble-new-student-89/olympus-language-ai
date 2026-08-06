import 'package:flutter_test/flutter_test.dart';
import 'package:olympus_language_ai/features/conversation/domain/models.dart';

void main() {
  group('ChatMessage', () {
    test('creates correctly with required fields', () {
      final msg = ChatMessage(role: 'user', content: 'Hello');
      expect(msg.role, 'user');
      expect(msg.content, 'Hello');
      expect(msg.correction, null);
    });

    test('creates correctly with correction', () {
      final msg = ChatMessage(
        role: 'assistant',
        content: 'You went to the park?',
        correction: 'Use "went" not "goed"',
      );
      expect(msg.correction, 'Use "went" not "goed"');
    });

    test('toMap produces correct keys', () {
      final msg = ChatMessage(role: 'user', content: 'Hi');
      final map = msg.toMap();
      expect(map['role'], 'user');
      expect(map['content'], 'Hi');
      expect(map.containsKey('correction'), false);
    });

    test('toMap includes correction when present', () {
      final msg = ChatMessage(
        role: 'assistant',
        content: 'Hi',
        correction: 'fix this',
      );
      final map = msg.toMap();
      expect(map['correction'], 'fix this');
    });

    test('fromMap round-trips without correction', () {
      final original = ChatMessage(role: 'user', content: 'Hello');
      final map = original.toMap();
      final restored = ChatMessage.fromMap(map);
      expect(restored.role, original.role);
      expect(restored.content, original.content);
      expect(restored.correction, null);
    });

    test('fromMap round-trips with correction', () {
      final original = ChatMessage(
        role: 'assistant',
        content: 'Hello',
        correction: 'fix me',
      );
      final map = original.toMap();
      final restored = ChatMessage.fromMap(map);
      expect(restored.correction, 'fix me');
    });
  });

  group('Session', () {
    test('addMessage appends to list', () {
      final session = Session(
        id: 's1',
        userId: 'u1',
        startedAt: DateTime.now(),
      );
      expect(session.messages, isEmpty);

      session.addMessage(ChatMessage(role: 'user', content: 'Hi'));
      expect(session.messages.length, 1);
    });

    test('SessionRecap has all fields', () {
      final messages = [ChatMessage(role: 'user', content: 'Hi')];
      final recap = SessionRecap(
        sessionId: 's1',
        scenarioName: 'Small Talk',
        startedAt: DateTime.now(),
        durationSeconds: 120,
        messageCount: 1,
        messages: messages,
        topMistakes: ['Used wrong tense'],
        strength: 'Good pronunciation',
      );

      expect(recap.sessionId, 's1');
      expect(recap.scenarioName, 'Small Talk');
      expect(recap.durationSeconds, 120);
      expect(recap.topMistakes, ['Used wrong tense']);
      expect(recap.strength, 'Good pronunciation');
    });
  });
}
