import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LegacyStore implements SKTransactionObserverWrapper {
  LegacyStore(
    this.id,
    this.onOwned,
    this.onStatus, {
    Future<String> Function()? receipt,
    Future<void> Function(SKPaymentTransactionWrapper)? finish,
    Future<void> Function()? restoreTransactions,
  }) : _receipt = receipt ?? SKReceiptManager.retrieveReceiptData,
       _finish = finish,
       _restoreTransactions = restoreTransactions;
  final String id;
  final void Function(bool) onOwned;
  final void Function(String, {bool waiting, bool pending}) onStatus;
  final Future<String> Function() _receipt;
  final Future<void> Function(SKPaymentTransactionWrapper)? _finish;
  final Future<void> Function()? _restoreTransactions;
  final queue = SKPaymentQueueWrapper();
  final _inFlight = <Future<void>>{};
  Completer<void>? _restore;
  bool _found = false;

  Future<void> start() async {
    final prefs = await SharedPreferences.getInstance();
    final confirmed = prefs.getString(id);
    if (confirmed != null) {
      final receipt = await _receipt().then<String?>(
        (value) => value,
        onError: (_) => null,
      );
      if (receipt != null) onOwned(confirmed == receipt);
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
    await (_restoreTransactions?.call() ?? queue.restoreTransactions());
    await result.future;
    while (_inFlight.isNotEmpty) {
      await Future.wait(_inFlight.toList());
    }
    if (!_found) {
      onOwned(false);
      await (await SharedPreferences.getInstance()).remove(id);
    }
  }

  @override
  void updatedTransactions({
    required List<SKPaymentTransactionWrapper> transactions,
  }) {
    late final Future<void> work;
    work = handleTransactions(
      transactions,
    ).whenComplete(() => _inFlight.remove(work));
    _inFlight.add(work);
  }

  @visibleForTesting
  Future<void> handleTransactions(
    List<SKPaymentTransactionWrapper> transactions,
  ) async {
    for (final tx in transactions.where(
      (tx) => tx.payment.productIdentifier == id,
    )) {
      try {
        switch (tx.transactionState) {
          case SKPaymentTransactionStateWrapper.purchased:
          case SKPaymentTransactionStateWrapper.restored:
            final receipt = await _receipt();
            if (receipt.isEmpty) throw StateError('Receipt missing');
            final saved = await (await SharedPreferences.getInstance())
                .setString(id, receipt);
            if (!saved) throw StateError('Receipt not saved');
            _found = true;
            onOwned(true);
            await _finishTransaction(tx);
          case SKPaymentTransactionStateWrapper.failed:
            onStatus('Purchase did not complete. You can try again.');
            await _finishTransaction(tx);
          case SKPaymentTransactionStateWrapper.deferred:
            onStatus('Waiting for store approval.', pending: true);
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

  Future<void> _finishTransaction(SKPaymentTransactionWrapper tx) =>
      _finish?.call(tx) ?? queue.finishTransaction(tx);

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
