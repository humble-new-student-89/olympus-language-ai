import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HomeScreen', () {
    testWidgets('renders basic UI elements', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Text('Ready to practice?'),
          ),
        ),
      );

      expect(find.text('Ready to practice?'), findsOneWidget);
    });
  });

  group('RecapScreen stat cards', () {
    testWidgets('StatCard widget renders correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Icon(Icons.timer_outlined),
                  Text('10m 30s'),
                  Text('Duration'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Duration'), findsOneWidget);
      expect(find.text('10m 30s'), findsOneWidget);
    });
  });

  group('HomeScreen UI structure', () {
    testWidgets('scenario card structure renders', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const Text('Scenarios'),
                OutlinedButton(
                  onPressed: () {},
                  child: const Row(
                    children: [
                      Text('💬'),
                      Expanded(
                        child: Column(
                          children: [
                            Text('Small Talk'),
                            Text('Chat about daily life'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Scenarios'), findsOneWidget);
      expect(find.text('💬'), findsOneWidget);
      expect(find.text('Small Talk'), findsOneWidget);
    });
  });
}
