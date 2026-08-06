import 'package:flutter_test/flutter_test.dart';
import 'package:olympus_language_ai/features/conversation/domain/scenarios.dart';

void main() {
  group('predefinedScenarios', () {
    test('contains exactly 6 scenarios', () {
      expect(predefinedScenarios.length, 6);
    });

    test('all scenarios have valid ids', () {
      for (final scenario in predefinedScenarios) {
        expect(scenario.id.isNotEmpty, true);
        expect(scenario.id.contains(' '), false);
      }
    });

    test('all scenarios have valid names', () {
      for (final scenario in predefinedScenarios) {
        expect(scenario.name.isNotEmpty, true);
      }
    });

    test('all scenarios have non-empty system prompts', () {
      for (final scenario in predefinedScenarios) {
        expect(scenario.systemPrompt.isNotEmpty, true);
      }
    });

    test('all scenarios have icons', () {
      for (final scenario in predefinedScenarios) {
        expect(scenario.icon.isNotEmpty, true);
      }
    });

    test('all scenarios have descriptions', () {
      for (final scenario in predefinedScenarios) {
        expect(scenario.description.isNotEmpty, true);
      }
    });

    test('all scenario IDs are unique', () {
      final ids = predefinedScenarios.map((s) => s.id).toSet();
      expect(ids.length, predefinedScenarios.length);
    });

    test('known scenario IDs are present', () {
      final ids = predefinedScenarios.map((s) => s.id).toSet();
      expect(ids, contains('casual-small-talk'));
      expect(ids, contains('ordering-food'));
      expect(ids, contains('job-interview'));
      expect(ids, contains('travel'));
      expect(ids, contains('shopping'));
      expect(ids, contains('doctor-visit'));
    });

    test('scenarios contain expected roleplay terms in system prompts', () {
      final allPrompts =
          predefinedScenarios.map((s) => s.systemPrompt).join(' ');
      expect(
          allPrompts.toLowerCase(), contains('gently correct'));
      expect(allPrompts.toLowerCase(), contains('language'));
    });
  });
}
