import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';

import '../data/models/player_character.dart';

const fullGameId = 'com.appgea.villages_town.full';

class FullGame extends ChangeNotifier {
  static final instance = FullGame();
  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  bool owned = false;
  bool busy = false;
  String message = '';
  ProductDetails? product;
  Future<void>? _startup;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  InAppPurchase get _store => InAppPurchase.instance;
  bool get _android => defaultTargetPlatform == TargetPlatform.android;

  Future<void> start() => _startup ??= _connect();

  Future<void> _connect() async {
    if (!supported) return;
    try {
      if (!_android) {
        // The plugin chooses StoreKit 1 only on devices without StoreKit 2.
        // ignore: deprecated_member_use
        await InAppPurchaseStoreKitPlatform.enableStoreKit1();
      }
      _subscription ??= _store.purchaseStream.listen(
        _updates,
        onError: (_) {
          _status(
            'The store could not confirm your purchase. Try Restore purchase.',
          );
        },
      );
      await refresh();
    } catch (_) {
      _startup = null;
      _status('The store is unavailable. Try again.');
    }
  }

  Future<void> onResume() async {
    if (!supported || _subscription == null) return;
    try {
      await refresh();
    } catch (_) {
      if (!busy) _status('The store is unavailable. Try again.');
    }
  }

  Future<void> refresh() async {
    if (!await _store.isAvailable()) {
      _status('The store is unavailable. Try again.');
      return;
    }
    if (_android) {
      await _checkPlayOwnership();
    } else if (InAppPurchaseStoreKitPlatform.isStoreKit2Enabled) {
      final purchases = await SK2Transaction.currentEntitlements();
      owned = purchases.any((p) => p.productId == fullGameId);
    }
    notifyListeners();
    final response = await _store.queryProductDetails({fullGameId});
    product = response.productDetails
        .where((p) => p.id == fullGameId)
        .firstOrNull;
    if (!busy) {
      _status(product == null ? 'The store could not load the price.' : '');
    }
  }

  Future<void> _checkPlayOwnership() async {
    final play = _store
        .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
    final result = await play.queryPastPurchases();
    if (result.error != null) throw StateError('Play ownership check failed');
    final purchases = result.pastPurchases.where(
      (p) => p.productID == fullGameId && p.status == PurchaseStatus.purchased,
    );
    owned = purchases.isNotEmpty;
    for (final p in purchases) {
      if (p.pendingCompletePurchase) await _store.completePurchase(p);
    }
  }

  void _status(String text, {bool waiting = false}) {
    busy = waiting;
    message = text;
    notifyListeners();
  }

  Future<void> _updates(List<PurchaseDetails> updates) async {
    for (final p in updates.where((p) => p.productID == fullGameId)) {
      switch (p.status) {
        case PurchaseStatus.pending:
          _status('Waiting for store approval.', waiting: true);
        case PurchaseStatus.canceled:
          _status('');
        case PurchaseStatus.error:
          _status('Purchase failed. You can try again.');
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          try {
            if (!_android && InAppPurchaseStoreKitPlatform.isStoreKit2Enabled) {
              final entries = await SK2Transaction.currentEntitlements();
              if (!entries.any((entry) => entry.productId == fullGameId)) {
                _status('The App Store could not confirm this purchase.');
                continue;
              }
            }
            owned = true;
            _status('');
            if (p.pendingCompletePurchase) await _store.completePurchase(p);
          } catch (_) {
            _status('The store could not finish confirming your purchase.');
          }
      }
    }
  }

  Future<void> buy() async {
    if (busy) return;
    _status('Contacting the store…', waiting: true);
    try {
      await start();
      if (product == null) {
        await refresh();
        _status(product == null ? 'The store could not load the price.' : '');
        return;
      }
      if (owned) {
        _status('');
        return;
      }
      final offer = product;
      if (offer == null ||
          !await _store.buyNonConsumable(
            purchaseParam: PurchaseParam(productDetails: offer),
          )) {
        _status('The store could not start the purchase. Try again.');
      }
    } catch (_) {
      _status('The store is unavailable. Try again.');
    }
  }

  Future<void> restore() async {
    if (busy) return;
    _status('Checking your purchases…', waiting: true);
    try {
      await start();
      if (_android) {
        // Play restore marks even pending transactions restored. Query their
        // original billing state before delivering or acknowledging the unlock.
        await _checkPlayOwnership();
      } else {
        await _store.restorePurchases();
      }
      _status(
        owned ? '' : 'No full-game purchase found for this store account.',
      );
    } catch (_) {
      _status('Restore failed. Check your connection and try again.');
    }
  }
}

bool canEnterCity(PlayerCharacter pc, String city, {required bool owned}) =>
    owned || pc.trialCities.contains(city) || pc.trialCities.length < 2;

Future<bool> allowCity(
  BuildContext context,
  PlayerCharacter pc,
  String city, {
  FullGame? billing,
}) async {
  final store = billing ?? FullGame.instance;
  if (!store.supported) return true;
  if (!canEnterCity(pc, city, owned: store.owned)) {
    await store.start();
    if (!context.mounted || ModalRoute.of(context)?.isCurrent != true)
      return false;
    if (!store.owned) {
      final bought = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        useSafeArea: true,
        builder: (_) => _FullGameSheet(store),
      );
      if (bought != true) return false;
    }
  }
  if (pc.trialCities.length < 2) pc.trialCities.add(city);
  return true;
}

class _FullGameSheet extends StatefulWidget {
  const _FullGameSheet(this.store);
  final FullGame store;
  @override
  State<_FullGameSheet> createState() => _FullGameSheetState();
}

class _FullGameSheetState extends State<_FullGameSheet> {
  bool closing = false;

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        if (store.owned && !closing) {
          closing = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && ModalRoute.of(context)?.isCurrent == true) {
              Navigator.pop(context, true);
            }
          });
        }
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Travel beyond the first two cities',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Unlock every city with one purchase.',
                  textAlign: TextAlign.center,
                ),
                if (store.message.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(store.message, textAlign: TextAlign.center),
                    ),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: store.busy ? null : store.buy,
                  child: Text(
                    store.product == null
                        ? 'Check price'
                        : 'Unlock full game · ${store.product!.price}',
                  ),
                ),
                TextButton(
                  onPressed: store.busy ? null : store.restore,
                  child: const Text('Restore purchase'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
