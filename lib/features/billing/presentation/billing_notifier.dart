import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/providers.dart';
import '../../auth/domain/auth_state.dart';
import '../../conversation/presentation/providers.dart';
import '../domain/subscription.dart';
import '../data/billing_service.dart';

class BillingState {
  final bool isLoading;
  final List<ProductInfo> products;
  final bool isPurchasing;
  final PlanTier currentTier;
  final String? error;
  final String? purchaseSuccessId;

  BillingState({
    this.isLoading = true,
    this.products = const [],
    this.isPurchasing = false,
    this.currentTier = PlanTier.free,
    this.error,
    this.purchaseSuccessId,
  });

  BillingState copyWith({
    bool? isLoading,
    List<ProductInfo>? products,
    bool? isPurchasing,
    PlanTier? currentTier,
    String? error,
    String? purchaseSuccessId,
  }) =>
      BillingState(
        isLoading: isLoading ?? this.isLoading,
        products: products ?? this.products,
        isPurchasing: isPurchasing ?? this.isPurchasing,
        currentTier: currentTier ?? this.currentTier,
        error: error,
        purchaseSuccessId: purchaseSuccessId,
      );
}

class BillingNotifier extends StateNotifier<BillingState> {
  final BillingService _billingService;
  final Ref _ref;

  BillingNotifier(this._ref, {required BillingService billingService})
      : _billingService = billingService,
        super(BillingState());

  Future<void> loadProducts() async {
    state = state.copyWith(isLoading: true);

    try {
      final products = await _billingService.getProducts();

      final user = _ref.read(authStateProvider);
      PlanTier currentTier = PlanTier.free;

      if (user is AuthAuthenticated) {
        final firestore = _ref.read(firestoreServiceProvider);
        final status = await firestore.getSubscriptionStatus(user.user.uid);
        final plan = status?['plan'] as String? ?? 'free';
        currentTier = switch (plan) {
          'core' => PlanTier.core,
          'unlimited' => PlanTier.unlimited,
          'trial' => PlanTier.trial,
          _ => PlanTier.free,
        };
      }

      state = BillingState(
        isLoading: false,
        products: products,
        currentTier: currentTier,
      );
    } catch (e) {
      state = BillingState(isLoading: false, error: e.toString());
    }
  }

  Future<void> purchase(ProductInfo product) async {
    state = state.copyWith(isPurchasing: true, error: null);

    try {
      final success = await _billingService.purchase(product);
      if (success) {
        final user = _ref.read(authStateProvider);
        if (user is AuthAuthenticated) {
          final firestore = _ref.read(firestoreServiceProvider);
          final planName = product.tier == PlanTier.core ? 'core' : 'unlimited';
          final expiry = DateTime.now().add(const Duration(days: 30));
          await firestore.updatePlan(user.user.uid, planName, expiry: expiry);
        }
        state = state.copyWith(
          isPurchasing: false,
          currentTier: product.tier,
          purchaseSuccessId: product.id,
        );
      } else {
        state = state.copyWith(
            isPurchasing: false, error: 'Purchase was cancelled');
      }
    } catch (e) {
      state = state.copyWith(isPurchasing: false, error: e.toString());
    }
  }

  Future<void> startTrial() async {
    final user = _ref.read(authStateProvider);
    if (user is! AuthAuthenticated) return;

    final firestore = _ref.read(firestoreServiceProvider);
    await firestore.startTrial(user.user.uid);

    state = state.copyWith(currentTier: PlanTier.trial, error: null);
  }

  Future<void> restore() async {
    state = state.copyWith(isLoading: true);
    await _billingService.restorePurchases();
    state = state.copyWith(isLoading: false);
  }

  void clearError() => state = state.copyWith(error: null);
}
