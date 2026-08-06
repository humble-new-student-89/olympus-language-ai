import 'package:flutter_test/flutter_test.dart';
import 'package:olympus_language_ai/features/billing/domain/subscription.dart';

void main() {
  group('PlanTier', () {
    test('free tier exists', () {
      expect(PlanTier.free, isNotNull);
    });

    test('core tier exists', () {
      expect(PlanTier.core, isNotNull);
    });

    test('unlimited tier exists', () {
      expect(PlanTier.unlimited, isNotNull);
    });
  });

  group('SubscriptionStatus.canUseApp', () {
    test('free tier with 0 minutes used can use app', () {
      final status = SubscriptionStatus(
        tier: PlanTier.free,
        minutesUsed: 0,
      );
      expect(status.canUseApp, true);
    });

    test('free tier with 5 minutes used can use app', () {
      final status = SubscriptionStatus(
        tier: PlanTier.free,
        minutesUsed: 5,
      );
      expect(status.canUseApp, true);
    });

    test('free tier with 10 minutes used cannot use app', () {
      final status = SubscriptionStatus(
        tier: PlanTier.free,
        minutesUsed: 10,
      );
      expect(status.canUseApp, false);
    });

    test('free tier with 15 minutes used cannot use app', () {
      final status = SubscriptionStatus(
        tier: PlanTier.free,
        minutesUsed: 15,
      );
      expect(status.canUseApp, false);
    });

    test('trial tier with 5 minutes can use app', () {
      final status = SubscriptionStatus(
        tier: PlanTier.trial,
        minutesUsed: 5,
      );
      expect(status.canUseApp, true);
    });

    test('trial tier with 10 minutes cannot use app', () {
      final status = SubscriptionStatus(
        tier: PlanTier.trial,
        minutesUsed: 10,
      );
      expect(status.canUseApp, false);
    });

    test('core tier always can use app', () {
      final status = SubscriptionStatus(
        tier: PlanTier.core,
        minutesUsed: 500,
      );
      expect(status.canUseApp, true);
    });

    test('unlimited tier always can use app', () {
      final status = SubscriptionStatus(
        tier: PlanTier.unlimited,
        minutesUsed: 9999,
      );
      expect(status.canUseApp, true);
    });
  });

  group('SubscriptionStatus.isSubscribed', () {
    test('free tier is not subscribed', () {
      final status = SubscriptionStatus(tier: PlanTier.free);
      expect(status.isSubscribed, false);
    });

    test('trial tier is not subscribed', () {
      final status = SubscriptionStatus(tier: PlanTier.trial);
      expect(status.isSubscribed, false);
    });

    test('core tier is subscribed', () {
      final status = SubscriptionStatus(tier: PlanTier.core);
      expect(status.isSubscribed, true);
    });

    test('unlimited tier is subscribed', () {
      final status = SubscriptionStatus(tier: PlanTier.unlimited);
      expect(status.isSubscribed, true);
    });
  });

  group('ProductInfo', () {
    test('creates correctly with all fields', () {
      final product = ProductInfo(
        id: 'test_id',
        title: 'Test Plan',
        price: '\$9.99/mo',
        description: 'A test plan',
        tier: PlanTier.core,
      );

      expect(product.id, 'test_id');
      expect(product.title, 'Test Plan');
      expect(product.price, '\$9.99/mo');
      expect(product.tier, PlanTier.core);
    });
  });
}
