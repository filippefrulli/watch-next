import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_next/services/user_action_service.dart';

class PurchaseService {
  static const String _productId = 'watch_next_remove_ads';
  static const String _prefsKey = 'ads_removed';
  static const String _restoreDoneKey = 'iap_restore_done';

  static StreamSubscription<List<PurchaseDetails>>? _subscription;
  static ProductDetails? _product;

  static final ValueNotifier<bool> adsRemovedNotifier = ValueNotifier(false);

  static bool get adsRemoved => adsRemovedNotifier.value;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    adsRemovedNotifier.value = prefs.getBool(_prefsKey) ?? false;

    if (adsRemovedNotifier.value) return;

    final available = await InAppPurchase.instance.isAvailable();
    if (!available) return;

    _subscription = InAppPurchase.instance.purchaseStream.listen(
      _handlePurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (_) {},
    );

    final response = await InAppPurchase.instance.queryProductDetails({_productId});
    if (response.productDetails.isNotEmpty) {
      _product = response.productDetails.first;
    }

    final restoreDone = prefs.getBool(_restoreDoneKey) ?? false;
    if (!restoreDone) {
      await prefs.setBool(_restoreDoneKey, true);
      await InAppPurchase.instance.restorePurchases();
    }
  }

  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  static ProductDetails? get product => _product;

  static Future<void> buyRemoveAds() async {
    if (_product == null) return;
    await InAppPurchase.instance.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: _product!),
    );
  }

  static Future<void> restorePurchases() async {
    await InAppPurchase.instance.restorePurchases();
  }

  static Future<void> _handlePurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID == _productId) {
        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          await _onPurchaseSuccess();
        }
        if (purchase.pendingCompletePurchase) {
          await InAppPurchase.instance.completePurchase(purchase);
        }
      }
    }
  }

  static Future<void> _onPurchaseSuccess() async {
    adsRemovedNotifier.value = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
    if (!kDebugMode) {
      await UserActionService.markPremium();
    }
  }
}
