import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:villages_town/data/models/player_character.dart';
import 'package:villages_town/purchases/full_game.dart';

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

void main() {
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
