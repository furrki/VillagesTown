import 'dart:async';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// StoreKit 1 for iOS 13 and 14, which cannot use currentEntitlements.
class LegacyStore implements SKTransactionObserverWrapper {
  LegacyStore(this.id, this.onOwned, this.onStatus);
  final String id;
  final void Function(bool) onOwned;
  final void Function(String, {bool waiting}) onStatus;
  final queue = SKPaymentQueueWrapper();
  Completer<void>? _restore;
  bool _found = false;

  Future<void> start() async {
    final prefs = await SharedPreferences.getInstance();
    final confirmed = prefs.getString(id);
    if (confirmed != null) {
      try {
        // Only reuse a receipt from a previously delivered store transaction.
        onOwned(confirmed == await SKReceiptManager.retrieveReceiptData());
      } catch (_) {
        /* Restore remains available if the receipt is missing. */
      }
    }
    queue.setTransactionObserver(this);
    await queue.startObservingTransactionQueue();
  }

  Future<AppStoreProductDetails?> offer() async {
    final result = await SKRequestMaker().startProductRequest([id]);
    final product = result.products
        .where((p) => p.productIdentifier == id)
        .firstOrNull;
    return product == null
        ? null
        : AppStoreProductDetails.fromSKProduct(product);
  }

  Future<void> buy() =>
      queue.addPayment(SKPaymentWrapper(productIdentifier: id));

  Future<void> restore() async {
    _found = false;
    final result = Completer<void>();
    _restore = result;
    await queue.restoreTransactions();
    await result.future;
    if (!_found) {
      onOwned(false);
      await (await SharedPreferences.getInstance()).remove(id);
    }
  }

  @override
  void updatedTransactions({
    required List<SKPaymentTransactionWrapper> transactions,
  }) async {
    for (final tx in transactions.where(
      (tx) => tx.payment.productIdentifier == id,
    )) {
      try {
        switch (tx.transactionState) {
          case SKPaymentTransactionStateWrapper.purchased:
          case SKPaymentTransactionStateWrapper.restored:
            _found = true;
            onOwned(true);
            final receipt = await SKReceiptManager.retrieveReceiptData();
            if (receipt.isNotEmpty) {
              await (await SharedPreferences.getInstance()).setString(
                id,
                receipt,
              );
            }
            await queue.finishTransaction(tx);
          case SKPaymentTransactionStateWrapper.failed:
            onStatus('Purchase did not complete. You can try again.');
            await queue.finishTransaction(tx);
          case SKPaymentTransactionStateWrapper.deferred:
          case SKPaymentTransactionStateWrapper.purchasing:
            onStatus('Waiting for store approval.', waiting: true);
          default:
            break;
        }
      } catch (_) {
        onStatus('The store could not finish confirming your purchase.');
      }
    }
  }

  @override
  void paymentQueueRestoreCompletedTransactionsFinished() {
    final request = _restore;
    _restore = null;
    request?.complete();
  }

  @override
  void restoreCompletedTransactionsFailed({required SKError error}) {
    final request = _restore;
    _restore = null;
    request?.completeError(StateError('Restore failed'));
  }

  @override
  void removedTransactions({
    required List<SKPaymentTransactionWrapper> transactions,
  }) {}
  @override
  bool shouldAddStorePayment({
    required SKPaymentWrapper payment,
    required SKProductWrapper product,
  }) => payment.productIdentifier == id;
}
