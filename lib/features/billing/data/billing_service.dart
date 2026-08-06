import 'package:in_app_purchase/in_app_purchase.dart';
import '../domain/subscription.dart';

class BillingService {
  final InAppPurchase _iap = InAppPurchase.instance;
  bool _available = false;

  static const coreMonthlyId = 'olympus_core_monthly';
  static const unlimitedMonthlyId = 'olympus_unlimited_monthly';

  bool get isAvailable => _available;

  Future<void> initialize() async {
    _available = await _iap.isAvailable();
  }

  Future<List<ProductInfo>> getProducts() async {
    if (!_available) return _getFallbackProducts();

    const ids = <String>{coreMonthlyId, unlimitedMonthlyId};
    final response = await _iap.queryProductDetails(ids);

    if (response.notFoundIDs.isNotEmpty) {
      // Products not found in Play Console, use fallback
      return _getFallbackProducts();
    }

    return response.productDetails.map((p) {
      return ProductInfo(
        id: p.id,
        title: p.title,
        price: p.price,
        description: p.description,
        tier: p.id == coreMonthlyId ? PlanTier.core : PlanTier.unlimited,
      );
    }).toList();
  }

  Future<bool> purchase(ProductInfo product) async {
    if (!_available) return false;

    final productDetails = await _iap.queryProductDetails({product.id});
    final details = productDetails.productDetails.firstWhere(
      (p) => p.id == product.id,
      orElse: () => throw Exception('Product not found'),
    );

    final param = PurchaseParam(productDetails: details);
    return _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restorePurchases() async {
    if (!_available) return;
    await _iap.restorePurchases();
  }

  Stream<List<PurchaseDetails>> get purchaseStream =>
      _iap.purchaseStream;

  void dispose() {
    // IAP instance is managed by the plugin
  }

  List<ProductInfo> _getFallbackProducts() {
    return [
      ProductInfo(
        id: coreMonthlyId,
        title: 'Olympus Core',
        price: '\$12.99/mo',
        description: '300 minutes of conversation per month',
        tier: PlanTier.core,
      ),
      ProductInfo(
        id: unlimitedMonthlyId,
        title: 'Olympus Unlimited',
        price: '\$19.99/mo',
        description: 'Unlimited conversation practice',
        tier: PlanTier.unlimited,
      ),
    ];
  }
}
