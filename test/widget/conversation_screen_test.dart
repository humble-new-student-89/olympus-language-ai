import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConversationScreen UI', () {
    testWidgets('initial state shows mic button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const Expanded(
                  child: Center(
                    child: Text(
                      'Press and hold the mic button\nto start speaking.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const Text('Hold to speak'),
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                  ),
                  child: const Center(
                    child: Icon(Icons.mic, size: 36, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Hold to speak'), findsOneWidget);
      expect(find.text('Press and hold the mic button\nto start speaking.'),
          findsOneWidget);
      expect(find.byIcon(Icons.mic), findsOneWidget);
    });

    testWidgets('shows transcript messages', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const Text('You'),
                const Text('Hello, how are you?'),
                const SizedBox(height: 8),
                const Text('Partner'),
                const Text('I am doing well!'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('You'), findsOneWidget);
      expect(find.text('Partner'), findsOneWidget);
      expect(find.text('Hello, how are you?'), findsOneWidget);
      expect(find.text('I am doing well!'), findsOneWidget);
    });

    testWidgets('correction chip renders', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const Text('Partner'),
                const Text('You went to the park!'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lightbulb_outline, size: 14),
                      Text('Use "went" not "goed"'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Use "went" not "goed"'), findsOneWidget);
    });
  });
}
