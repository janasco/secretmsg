import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import 'api_client.dart';

/// Product IDs. These must match the in-app products defined in the Play
/// Console *and* the PLAY_PRODUCTS map in the API worker, or verification
/// will reject the purchase.
class BillingProducts {
  static const verifiedBadge = 'verified_badge';
  static const viewerHints = 'viewer_hints';
  static const senderHints = 'sender_hints';
  static const supporterBundle = 'supporter_bundle';

  static const all = <String>{
    verifiedBadge,
    viewerHints,
    senderHints,
    supporterBundle,
  };

  static String labelFor(String id) {
    switch (id) {
      case verifiedBadge:
        return 'Verified Badge';
      case viewerHints:
        return 'Viewer Hints';
      case senderHints:
        return 'Sender Hints';
      case supporterBundle:
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
        BillingEvent(BillingStage.failed, '', e.toString()),
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
