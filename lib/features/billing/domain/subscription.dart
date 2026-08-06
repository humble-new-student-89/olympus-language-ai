enum PlanTier { free, trial, core, unlimited }

class SubscriptionStatus {
  final PlanTier tier;
  final DateTime? expiry;
  final bool isTrialActive;
  final int minutesUsed;

  SubscriptionStatus({
    required this.tier,
    this.expiry,
    this.isTrialActive = false,
    this.minutesUsed = 0,
  });

  bool get isSubscribed =>
      tier == PlanTier.core || tier == PlanTier.unlimited;

  bool get canUseApp {
    if (isSubscribed) return true;
    if (tier == PlanTier.trial) return minutesUsed < 10;
    return minutesUsed < 10; // free tier, 10 min trial
  }
}

class ProductInfo {
  final String id;
  final String title;
  final String price;
  final String description;
  final PlanTier tier;

  ProductInfo({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.tier,
  });
}
