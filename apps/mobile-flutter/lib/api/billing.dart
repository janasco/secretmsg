import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import 'api_client.dart';

/// Product IDs. These must match the in-app products defined in the Play
/// Console *and* the PLAY_PRODUCTS map in the API worker, or verification
/// will reject the purchase.
class BillingProducts {
  /// The only purchasable product. The app is ad-supported; this removes ads.
  static const removeAds = 'remove_ads';

  /// Products retired when the app moved to an ad-supported model. They are
  /// kept here as a named set rather than deleted so the client can actively
  /// refuse to offer them.
  ///
  /// This matters because the store listing is not under our control at
  /// runtime: if a retired product is still active in Play Console, it appears
  /// in the billing query and the UI would render it as purchasable. The worker
  /// answers 400 "Unknown product" for anything outside `PLAY_PRODUCTS`, so a
  /// user who bought one would be charged, granted nothing, and refunded by
  /// Google three days later. Filtering on the client turns that into a product
  /// that simply is not shown.
  static const retired = <String>{
    'verified_badge',
    'viewer_hints',
    'sender_hints',
    'supporter_bundle',
  };

  static const all = <String>{removeAds};

  /// True only for products the worker will actually honour.
  static bool isPurchasable(String id) => all.contains(id);

  static String labelFor(String id) {
    switch (id) {
      case removeAds:
        return 'Remove Ads';
      case 'verified_badge':
        return 'Verified Badge';
      case 'viewer_hints':
        return 'Viewer Hints';
      case 'sender_hints':
        return 'Sender Hints';
      case 'supporter_bundle':
        return 'Supporter Bundle';
      default:
        return id;
    }
  }
}

enum BillingStage { pending, granted, failed, cancelled }

class BillingEvent {
  final BillingStage stage;
  final String productId;
  final String? message;
  const BillingEvent(this.stage, this.productId, [this.message]);
}

/// Thin wrapper over Play Billing.
///
/// Perks are never unlocked here. The purchase token is handed to the API,
/// which checks it against Google before granting anything — the client is
/// not trusted, and a tampered build cannot award itself features.
class Billing {
  Billing._();

  static final InAppPurchase _iap = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _sub;

  static bool _available = false;
  static bool get isAvailable => _available;

  static List<ProductDetails> products = <ProductDetails>[];

  static final StreamController<BillingEvent> _events =
      StreamController<BillingEvent>.broadcast();
  static Stream<BillingEvent> get events => _events.stream;

  /// Safe to call more than once; the purchase listener is only attached once.
  static Future<void> init() async {
    try {
      _available = await _iap.isAvailable();
    } catch (_) {
      _available = false;
    }
    if (!_available) return;

    _sub ??= _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (Object e) => _events.add(
        const BillingEvent(BillingStage.failed, '', 'The purchase could not be completed.'),
      ),
    );

    try {
      final res = await _iap.queryProductDetails(BillingProducts.all);
      products = res.productDetails;
    } catch (_) {
      products = <ProductDetails>[];
    }
  }

  static Future<void> buy(ProductDetails product) async {
    await _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
  }

  /// Re-delivers purchases the account already owns, e.g. on a new device.
  static Future<void> restore() => _iap.restorePurchases();

  static Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _events.add(BillingEvent(BillingStage.pending, purchase.productID));
          break;

        case PurchaseStatus.canceled:
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          _events.add(BillingEvent(BillingStage.cancelled, purchase.productID));
          break;

        case PurchaseStatus.error:
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          _events.add(BillingEvent(
            BillingStage.failed,
            purchase.productID,
            purchase.error?.message ?? 'The purchase could not be completed.',
          ));
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          try {
            await ApiClient.verifyGooglePurchase(
              purchaseToken: purchase.verificationData.serverVerificationData,
              productId: purchase.productID,
            );
          } catch (e) {
            // Deliberately NOT completed: leaving the purchase pending means
            // Play re-delivers it on the next launch so verification can be
            // retried instead of the user paying for nothing.
            _events.add(BillingEvent(
              BillingStage.failed,
              purchase.productID,
              'Payment received, but unlocking failed. It will retry automatically.',
            ));
            break;
          }

          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          _events.add(BillingEvent(BillingStage.granted, purchase.productID));
          break;
      }
    }
  }
}
