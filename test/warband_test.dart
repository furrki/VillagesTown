import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:villages_town/data/models/nationality.dart';
import 'package:villages_town/data/models/player_character.dart';
import 'package:villages_town/data/models/resource.dart';
import 'package:villages_town/data/models/unit_type.dart';
import 'package:villages_town/engines/game_loop.dart';
import 'package:villages_town/engines/game_manager.dart';
import 'package:villages_town/engines/save_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  GameManager started() {
    final game = GameManager.shared..resetGame();
    game.setupGame(Nationality.ottomans);
    game.initializeGame(characterName: 'Test');
    return game;
  }

  GameManager withFourTroops() {
    final game = started();
    final warband = game.playerWarband!;
    warband.units.removeRange(4, warband.units.length);
    game.updateArmy(warband);
    for (final city in game.getPlayerVillages('player')) {
      city.addResource(Resource.food, 100000);
    }
    game.syncGlobalResources();
    game.spendGold(game.gold - 100);
    return game;
  }

  void setOnRoad(GameManager game, {required double progress, required int totalTicks}) {
    final pc = game.playerCharacter!;
    pc.state = PlayerState.traveling;
    pc.travelOriginId = pc.currentCityId;
    pc.travelDestinationId = game.map.villages.firstWhere((v) => v.id != pc.currentCityId).id;
    pc.travelTotalTicks = totalTicks;
    pc.travelProgress = progress;
  }

  test('a new game warband is the starting roster, not a city garrison', () {
    final game = started();
    expect(
        game.playerWarband!.units
            .any((u) => u.unitType == UnitType.spearman),
        isTrue);
  });

  test('the same warband comes back after a save and a load', () async {
    final game = started();
    final id = game.playerWarband!.id;
    await SaveEngine.saveGame(game);
    game.resetGame();
    expect(await SaveEngine.loadGame(game), isTrue);
    expect(game.playerWarband?.id, id);
  });

  for (final gold in [7, 8]) {
    test('an arrival on a scheduled tick with ${gold}g ${gold < 8 ? 'cannot pay' : 'pays'} the 8g wage', () {
      final game = withFourTroops();
      final pc = game.playerCharacter!;
      game.spendGold(game.gold - gold);
      setOnRoad(game, progress: 0.5, totalTicks: 2);
      final destination = pc.travelDestinationId;
      game.gameLoop.tickCount = 5;
      final turn = game.currentTurn;
      game.onGameTickCallback();
      expect(game.currentTurn, turn + 1);
      expect(game.playerWarband!.unitCount, gold < 8 ? 3 : 4);
      expect(pc.state, PlayerState.atCity);
      expect(pc.currentCityId, destination);
      expect(game.gameLoop.speed, GameSpeed.paused);
      expect(game.currentEncounter, isNull);
    });
  }

  test('an arrival off the schedule charges no wage and runs no world turn', () {
    final game = withFourTroops();
    final pc = game.playerCharacter!;
    setOnRoad(game, progress: 0.5, totalTicks: 2);
    game.gameLoop.tickCount = 6;
    final gold = game.gold;
    final turn = game.currentTurn;
    game.onGameTickCallback();
    expect(game.currentTurn, turn);
    expect(game.gold, gold);
    expect(pc.state, PlayerState.atCity);
    expect(game.gameLoop.speed, GameSpeed.paused);
  });

  test('an encounter on a scheduled tick finishes the tick once, then pauses', () {
    final game = withFourTroops();
    final pc = game.playerCharacter!;
    final turn = game.currentTurn;
    var rolls = 0;
    while (game.currentEncounter == null && rolls < 500) {
      rolls++;
      setOnRoad(game, progress: 0, totalTicks: 2);
      game.gameLoop.tickCount = 5;
      game.onGameTickCallback();
    }
    expect(game.currentEncounter, isNotNull);
    expect(game.currentTurn - turn, rolls);
    expect(game.playerWarband!.unitCount, 4);
    expect(pc.state, PlayerState.traveling);
    expect(game.gameLoop.speed, GameSpeed.paused);
  });
}
