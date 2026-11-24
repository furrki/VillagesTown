import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'legacy_store.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/layout_constants.dart';
import '../data/models/player_character.dart';
import 'town_hero.dart';

const fullGameId = 'com.appgea.villages_town.full';
const _playOwnedKey = 'com.appgea.villages_town.full.play_owned';

class FullGame extends ChangeNotifier {
  static final instance = FullGame();
  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  LegacyStore? _legacy;
  bool owned = false;
  bool busy = false;
  bool pending = false;
  bool restoring = false;
  String message = '';
  ProductDetails? product;
  Future<void>? _startup;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  InAppPurchase get _store => InAppPurchase.instance;
  bool get _android => platformIsAndroid;

  @visibleForTesting
  bool get platformIsAndroid => defaultTargetPlatform == TargetPlatform.android;

  @visibleForTesting
  Future<bool> storeKit2Owned() async =>
      (await SK2Transaction.currentEntitlements()).any(
        (p) => p.productId == fullGameId,
      );

  @visibleForTesting
  Future<void> storeRestore() => _store.restorePurchases();

  @visibleForTesting
  Future<List<PurchaseDetails>> playPurchases() async {
    final play = _store
        .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
    final result = await play.queryPastPurchases();
    if (result.error != null) throw StateError('Play ownership check failed');
    return result.pastPurchases;
  }

  @visibleForTesting
  Future<void> completeStorePurchase(PurchaseDetails p) =>
      _store.completePurchase(p);

  Future<void> start() => _startup ??= _connect();

  Future<void> _connect() async {
    if (!supported) return;
    try {
      if (!_android && !await SKRequestMaker.supportsStoreKit2()) {
        _legacy = LegacyStore(fullGameId, legacyOwned, legacyStatus);
        await _legacy!.start();
        await refresh();
        return;
      }
      if (_android && await _cachedPlayOwnership()) owned = true;
      _subscription ??= _store.purchaseStream.listen(
        handleUpdates,
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
    if (!supported || (_subscription == null && _legacy == null)) return;
    try {
      await refresh();
    } catch (_) {
      if (!busy && !pending) _status('The store is unavailable. Try again.');
    }
  }

  Future<void> refresh() async {
    if (_legacy != null) {
      product = await _legacy!.offer();
      notifyListeners();
      return;
    }
    if (_android) {
      await _checkPlayOwnership();
    } else {
      owned = await storeKit2Owned();
    }
    notifyListeners();
    final response = await _store.queryProductDetails({fullGameId});
    product = response.productDetails
        .where((p) => p.id == fullGameId)
        .firstOrNull;
    if (!busy && !pending) {
      _status(product == null ? 'The store could not load the price.' : '');
    }
  }

  @visibleForTesting
  void legacyOwned(bool value) {
    owned = value;
    _status('', pending: value ? false : null);
  }

  @visibleForTesting
  void legacyStatus(
    String text, {
    bool waiting = false,
    bool pending = false,
  }) => _status(text, waiting: waiting, pending: pending);

  Future<bool> _cachedPlayOwnership() async {
    try {
      return (await SharedPreferences.getInstance()).getBool(_playOwnedKey) ??
          false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _cachePlayOwnership(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value) {
        await prefs.setBool(_playOwnedKey, true);
      } else {
        await prefs.remove(_playOwnedKey);
      }
    } catch (_) {
      return;
    }
  }

  Future<void> _checkPlayOwnership() async {
    final List<PurchaseDetails> past;
    try {
      past = await playPurchases();
    } catch (_) {
      if (await _cachedPlayOwnership()) owned = true;
      rethrow;
    }
    final purchases = past.where(
      (p) => p.productID == fullGameId && p.status == PurchaseStatus.purchased,
    );
    owned = purchases.isNotEmpty;
    await _cachePlayOwnership(owned);
    for (final p in purchases) {
      if (p.pendingCompletePurchase) await completeStorePurchase(p);
    }
  }

  void _status(String text, {bool waiting = false, bool? pending}) {
    busy = waiting;
    this.pending = pending ?? this.pending;
    message = text;
    notifyListeners();
  }

  @visibleForTesting
  Future<void> handleUpdates(List<PurchaseDetails> updates) async {
    for (final p in updates.where((p) => p.productID == fullGameId)) {
      switch (p.status) {
        case PurchaseStatus.pending:
          _status('Waiting for store approval.', pending: true);
        case PurchaseStatus.canceled:
          _status('', pending: false);
        case PurchaseStatus.error:
          _status('Purchase failed. You can try again.', pending: false);
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          try {
            if (!_android) {
              if (!await storeKit2Owned()) {
                _status(
                  'The App Store could not confirm this purchase.',
                  pending: false,
                );
                continue;
              }
            }
            owned = true;
            _status('', pending: false);
            if (_android) await _cachePlayOwnership(true);
            if (p.pendingCompletePurchase) await completeStorePurchase(p);
          } catch (_) {
            _status(
              'The store could not finish confirming your purchase.',
              pending: false,
            );
          }
      }
    }
  }

  Future<void> buy() async {
    if (busy || pending || restoring) return;
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
      if (_legacy != null) {
        await _legacy!.buy();
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
    if (busy || restoring) return;
    restoring = true;
    _status('Checking your purchases…', waiting: true);
    try {
      await start();
      if (_android) {
        await _checkPlayOwnership();
      } else if (_legacy != null) {
        await _legacy!.restore();
      } else {
        await storeRestore();
        owned = await storeKit2Owned();
      }
      if (owned) {
        _status('', pending: false);
      } else if (pending) {
        _status('Waiting for store approval.');
      } else {
        _status('No full-game purchase found for this store account.');
      }
    } on ConfirmationFailed {
      _status('The store could not finish confirming your purchase.');
    } catch (_) {
      _status('Restore failed. Check your connection and try again.');
    } finally {
      restoring = false;
      notifyListeners();
    }
  }
}

bool canEnterCity(PlayerCharacter pc, String city, {required bool owned}) =>
    owned || pc.trialCities.contains(city) || pc.trialCities.length < 2;

Future<bool> allowCity(
  BuildContext context,
  PlayerCharacter pc,
  String city, {
  required bool Function() travel,
  FullGame? billing,
}) async {
  final store = billing ?? FullGame.instance;
  if (!store.supported) return travel();
  if (!canEnterCity(pc, city, owned: store.owned)) {
    await store.start();
    if (!context.mounted || ModalRoute.of(context)?.isCurrent != true) {
      return false;
    }
    if (!store.owned) {
      final bought = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        useSafeArea: true,
        builder: (_) => _FullGameSheet(store),
      );
      if (bought != true && !store.owned) return false;
    }
  }
  if (!context.mounted || !travel()) return false;
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
  bool _buying = false;
  bool _won = false;

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_changed);
  }

  @override
  void dispose() {
    widget.store.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    final store = widget.store;
    if (!_buying) return;
    if (store.owned) {
      _buying = false;
      setState(() => _won = true);
      _celebrate();
    } else if (store.pending) {
      _buying = false;
    } else if (!store.busy) {
      _buying = false;
      if (store.message.isNotEmpty) _failed();
    }
  }

  Future<void> _celebrate() async {
    LayoutConstants.impactFeedback(style: HapticStyle.heavy);
    await Future<void>.delayed(const Duration(milliseconds: 110));
    LayoutConstants.impactFeedback(style: HapticStyle.medium);
    await Future<void>.delayed(const Duration(milliseconds: 110));
    LayoutConstants.impactFeedback(style: HapticStyle.heavy);
  }

  Future<void> _failed() async {
    LayoutConstants.impactFeedback();
    await Future<void>.delayed(const Duration(milliseconds: 90));
    LayoutConstants.impactFeedback();
  }

  void _buy() {
    LayoutConstants.impactFeedback(style: HapticStyle.medium);
    _buying = true;
    widget.store.buy();
  }

  void _close() {
    if (mounted && ModalRoute.of(context)?.isCurrent == true) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final still = MediaQuery.disableAnimationsOf(context);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final won = _won && store.owned;
        if (store.owned && !won && !_buying && !closing) {
          closing = true;
          WidgetsBinding.instance.addPostFrameCallback((_) => _close());
        }
        return PopScope(
          canPop: !won,
          onPopInvokedWithResult: (popped, _) {
            if (!popped) Navigator.pop(context, true);
          },
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TownHero(won: won, still: still),
                  const SizedBox(height: 16),
                  Text(
                    'Travel beyond the first two cities',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (!won) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Unlock every city with one purchase.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (store.message.isNotEmpty && !won)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(store.message, textAlign: TextAlign.center),
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (won)
                    FilledButton(
                      onPressed: _close,
                      child: const Text('Continue'),
                    )
                  else ...[
                    FilledButton(
                      onPressed: store.busy || store.pending || store.restoring
                          ? null
                          : _buy,
                      child: Text(
                        store.product == null
                            ? 'Check price'
                            : 'Unlock full game · ${store.product!.price}',
                      ),
                    ),
                    TextButton(
                      onPressed: store.busy || store.restoring
                          ? null
                          : store.restore,
                      child: const Text('Restore purchase'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
