import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/billing_service.dart';
import 'billing_notifier.dart';

final billingServiceProvider = Provider<BillingService>((ref) {
  final service = BillingService();
  ref.onDispose(() => service.dispose());
  return service;
});

final billingStateProvider =
    StateNotifierProvider<BillingNotifier, BillingState>((ref) {
  return BillingNotifier(ref,
      billingService: ref.watch(billingServiceProvider));
});
