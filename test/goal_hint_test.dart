import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:villages_town/data/models/character_origin.dart';
import 'package:villages_town/data/models/mission.dart';
import 'package:villages_town/data/models/nationality.dart';
import 'package:villages_town/data/models/player_character.dart';
import 'package:villages_town/engines/game_manager.dart';
import 'package:villages_town/engines/victory_engine.dart';
import 'package:villages_town/ui/map/village_marker.dart';
import 'package:villages_town/ui/screens/game_view_rts.dart';

void main() {
  testWidgets('saved mission moves from cargo to destination to victory', (
    tester,
  ) async {
    final game = GameManager.shared
      ..resetGame()
      ..setupGame(Nationality.ottomans);
    addTearDown(game.resetGame);
    final cities = game.map.villages.take(2).toList();
    final mission = CharacterOrigin.merchantSon.createInitialMission(
      startCityId: cities.first.id,
      nearestCityId: cities.last.id,
      nearestCityName: cities.last.name,
    );
    mission.objectives.first.currentAmount = 2;
    final character = PlayerCharacter(
      name: 'Merchant',
      currentCityId: cities.first.id,
    );

    Future<void> showSavedMission() async {
      character.activeMissions
        ..clear()
        ..add(Mission.fromJson(mission.toJson()));
      game.playerCharacter = character;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 288,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        for (final city in cities)
                          VillageMarker(
                            village: city,
                            displayName: city.name,
                            isSelected: false,
                            isGoal: city.id == game.goalCityIdFor('player'),
                            armyCount: 0,
                            hasThreat: false,
                            inVision: true,
                            onTap: () {},
                          ),
                      ],
                    ),
                    MapGoalHintBar(
                      game: game,
                      cityName: 'Constantinople',
                      openCity: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    await showSavedMission();
    final pennant = find.byKey(const ValueKey('goal-pennant'));
    expect(game.goalCityIdFor('player'), cities.last.id);
    expect(pennant, findsOneWidget);
    expect(
      tester
          .widget<VillageMarker>(
            find.ancestor(of: pennant, matching: find.byType(VillageMarker)),
          )
          .village
          .id,
      cities.last.id,
    );
    expect(find.text('Carry 3 grain 2/3'), findsOneWidget);

    mission.objectives.first.markComplete();
    await showSavedMission();
    expect(find.text('Deliver to ${cities.last.name}'), findsOneWidget);

    mission.objectives.last.markComplete();
    mission.checkCompletion();
    await showSavedMission();
    expect(game.goalCityIdFor('player'), isNull);
    expect(pennant, findsNothing);
    final best = VictoryEngine.getAllProgress(
      game,
      'player',
    ).reduce((a, b) => a.progress >= b.progress ? a : b);
    expect(
      find.text(
        '${best.type.emoji} ${best.type.displayName} ${(best.progress * 100).round()}%',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
