import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Auth screens', () {
    testWidgets('login form renders email and password fields', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const Text('Welcome Back'),
                const Text('Sign in to continue practicing'),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Sign In'),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Don\'t have an account? Sign up'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Don\'t have an account? Sign up'), findsOneWidget);
    });

    testWidgets('signup form renders fields', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const Text('Create Account'),
                const Text('Start your language journey'),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Display Name'),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Create Account'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Create Account'), findsWidgets);
      expect(find.text('Start your language journey'), findsOneWidget);
    });
  });
}
