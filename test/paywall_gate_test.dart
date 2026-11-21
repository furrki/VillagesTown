import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:villages_town/data/models/player_character.dart';
import 'package:villages_town/purchases/full_game.dart';
import 'package:villages_town/purchases/legacy_store.dart';

class TestStore extends FullGame {
  @override
  bool get supported => true;
  @override
  Future<void> start() async {}
  @override
  Future<void> restore() async {
    owned = true;
    notifyListeners();
  }
}

class FakeStore extends FullGame {
  FakeStore({this.android = false});
  final bool android;
  int restores = 0;
  Future<void>? gate;
  Future<bool> Function() sk2 = () async => false;
  Future<List<PurchaseDetails>> Function() play = () async => [];
  @override
  bool get supported => true;
  @override
  bool get platformIsAndroid => android;
  @override
  Future<void> start() async {}
  @override
  Future<bool> storeKit2Owned() => sk2();
  @override
  Future<void> storeRestore() async {
    restores++;
    await gate;
  }

  @override
  Future<List<PurchaseDetails>> playPurchases() => play();
}

PurchaseDetails playPurchase(PurchaseStatus status) => PurchaseDetails(
  productID: fullGameId,
  verificationData: PurchaseVerificationData(
    localVerificationData: '',
    serverVerificationData: '',
    source: 'test',
  ),
  transactionDate: null,
  status: status,
);

SKPaymentTransactionWrapper tx(SKPaymentTransactionStateWrapper state) =>
    SKPaymentTransactionWrapper(
      payment: const SKPaymentWrapper(productIdentifier: fullGameId),
      transactionState: state,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'pending approval blocks Buy, keeps Restore, clears on purchase',
    () async {
      final store = FakeStore()..sk2 = () async => true;
      await store.handleUpdates([playPurchase(PurchaseStatus.pending)]);
      expect(store.pending, isTrue);
      expect(store.busy, isFalse);
      store.restore();
      await Future<void>.delayed(Duration.zero);
      await store.buy();
      expect(store.restores, 1);
      await store.handleUpdates([playPurchase(PurchaseStatus.pending)]);
      for (final status in [PurchaseStatus.canceled, PurchaseStatus.error]) {
        await store.handleUpdates([playPurchase(PurchaseStatus.pending)]);
        await store.handleUpdates([playPurchase(status)]);
        expect(store.pending, isFalse);
      }
      await store.handleUpdates([playPurchase(PurchaseStatus.pending)]);
      await store.handleUpdates([playPurchase(PurchaseStatus.restored)]);
      expect(store.pending, isFalse);
      expect(store.owned, isTrue);
    },
  );

  test('restore stays available while approval is pending', () async {
    final store = FakeStore();
    await store.handleUpdates([playPurchase(PurchaseStatus.pending)]);
    await store.restore();
    expect(store.restores, 1);
    expect(store.pending, isTrue);
    expect(store.busy, isFalse);
    expect(store.message, 'Waiting for store approval.');
  });

  test('a transaction callback does not allow a second restore', () async {
    final store = FakeStore();
    final gate = Completer<void>();
    store.gate = gate.future;
    final first = store.restore();
    await Future<void>.delayed(Duration.zero);
    await store.handleUpdates([playPurchase(PurchaseStatus.canceled)]);
    expect(store.busy, isFalse);
    await store.restore();
    expect(store.restores, 1);
    gate.complete();
    await first;
    expect(store.restoring, isFalse);
  });

  test(
    'StoreKit 2 restore reports the entitlement result after the call',
    () async {
      final store = FakeStore();
      var delivered = false;
      store.sk2 = () async => delivered;
      store.restore();
      delivered = true;
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(store.owned, isTrue);
      expect(store.message, '');

      final empty = FakeStore();
      await empty.restore();
      expect(empty.owned, isFalse);
      expect(empty.busy, isFalse);
      expect(empty.message, startsWith('No full-game purchase'));

      final failing = FakeStore()..sk2 = () async => throw StateError('x');
      await failing.restore();
      expect(failing.owned, isFalse);
      expect(failing.busy, isFalse);
      expect(failing.message, startsWith('Restore failed'));
    },
  );

  test(
    'Android keeps a confirmed unlock through a failed Play query',
    () async {
      final first = FakeStore(android: true)
        ..play = () async => [playPurchase(PurchaseStatus.purchased)];
      await first.restore();
      expect(first.owned, isTrue);

      final relaunch = FakeStore(android: true)
        ..play = () async => throw StateError('billing unavailable');
      await relaunch.restore();
      expect(relaunch.owned, isTrue);

      final refund = FakeStore(android: true)..play = () async => [];
      await refund.restore();
      expect(refund.owned, isFalse);

      final later = FakeStore(android: true)
        ..play = () async => throw StateError('billing unavailable');
      await later.restore();
      expect(later.owned, isFalse);
    },
  );

  group('legacy StoreKit 1', () {
    late bool owned;
    late List<String> statuses;
    late List<bool> pendingFlags;
    late int finished;
    late bool saveOk;
    late List<String> saved;
    late Future<String> Function() receipt;
    late void Function(LegacyStore) onRestore;
    late LegacyStore legacy;

    setUp(() {
      owned = false;
      statuses = [];
      pendingFlags = [];
      finished = 0;
      saveOk = true;
      saved = [];
      receipt = () async => 'R';
      onRestore = (_) {};
      legacy = LegacyStore(
        fullGameId,
        (v) => owned = v,
        (text, {bool waiting = false, bool pending = false}) {
          statuses.add(text);
          pendingFlags.add(pending);
        },
        receipt: () => receipt(),
        finish: (_) async => finished++,
        saveReceipt: (r) async {
          if (saveOk) saved.add(r);
          return saveOk;
        },
        restoreTransactions: () async {
          onRestore(legacy);
          legacy.paymentQueueRestoreCompletedTransactionsFinished();
        },
      );
    });

    test('deferred transaction reports pending, not busy', () async {
      await legacy.handleTransactions([
        tx(SKPaymentTransactionStateWrapper.deferred),
      ]);
      expect(pendingFlags, [true]);
      expect(owned, isFalse);
    });

    test(
      'a rejected receipt save delivers nothing, restore then recovers',
      () async {
        saveOk = false;
        await legacy.handleTransactions([
          tx(SKPaymentTransactionStateWrapper.purchased),
        ]);
        expect(owned, isFalse);
        expect(finished, 0);
        expect(statuses.single, startsWith('The store could not finish'));

        saveOk = true;
        onRestore = (l) => l.updatedTransactions(
          transactions: [tx(SKPaymentTransactionStateWrapper.restored)],
        );
        await legacy.restore();
        expect(owned, isTrue);
        expect(finished, 1);
        expect(saved, ['R']);
      },
    );

    test(
      'restore keeps saved ownership and reports a failed confirmation',
      () async {
        SharedPreferences.setMockInitialValues({fullGameId: 'OLD'});
        saveOk = false;
        onRestore = (l) => l.updatedTransactions(
          transactions: [tx(SKPaymentTransactionStateWrapper.restored)],
        );
        await expectLater(legacy.restore(), throwsA(isA<ConfirmationFailed>()));
        expect(
          (await SharedPreferences.getInstance()).getString(fullGameId),
          'OLD',
        );
      },
    );

    test('an empty receipt delivers nothing', () async {
      receipt = () async => '';
      await legacy.handleTransactions([
        tx(SKPaymentTransactionStateWrapper.purchased),
      ]);
      expect(owned, isFalse);
      expect(finished, 0);
    });

    test(
      'restore waits for in-flight persistence before it completes',
      () async {
        receipt = () async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return 'R';
        };
        onRestore = (l) => l.updatedTransactions(
          transactions: [tx(SKPaymentTransactionStateWrapper.restored)],
        );
        await legacy.restore();
        expect(owned, isTrue);
        expect(finished, 1);
      },
    );
  });

  testWidgets(
    'third distinct city shows the offer until ownership is restored',
    (tester) async {
      final player = PlayerCharacter(currentCityId: 'A');
      final billing = TestStore();
      String? entered;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  for (final city in ['A', 'B', 'C'])
                    TextButton(
                      onPressed: () async {
                        if (await allowCity(
                          context,
                          player,
                          city,
                          billing: billing,
                          travel: () => true,
                        )) {
                          entered = city;
                        }
                      },
                      child: Text(city),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      for (final city in ['B', 'A', 'C']) {
        await tester.tap(find.text(city));
        await tester.pumpAndSettle();
      }
      expect(entered, 'A');
      expect(find.text('Travel beyond the first two cities'), findsOneWidget);
      final reloaded = PlayerCharacter.fromJson(player.toJson());
      expect(canEnterCity(reloaded, 'C', owned: false), isFalse);
      await tester.tap(find.text('Restore purchase'));
      await tester.pumpAndSettle();
      expect(entered, 'C');
      expect(find.text('Restore purchase'), findsNothing);
      await tester.tap(find.text('C'));
      await tester.pumpAndSettle();
      expect(find.text('Restore purchase'), findsNothing);
    },
  );
}
