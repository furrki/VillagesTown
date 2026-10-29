// Continue must find the cities again, and a city action must reach the save. Board Appgea/ops#147.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:villages_town/data/models/army.dart';
import 'package:villages_town/data/models/geo_coordinate.dart';
import 'package:villages_town/data/models/nationality.dart';
import 'package:villages_town/data/models/player_character.dart';
import 'package:villages_town/data/models/unit.dart';
import 'package:villages_town/data/models/unit_type.dart';
import 'package:villages_town/engines/game_manager.dart';
import 'package:villages_town/engines/save_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // GameManager is one shared object: each test starts from a reset one.
  GameManager started() {
    final game = GameManager.shared..resetGame();
    game.setupGame(Nationality.ottomans);
    game.gameStarted = true;
    return game;
  }

  test('a loaded game finds the cities its army, character and capital point at', () async {
    final game = started();
    final here = game.map.villages[0], there = game.map.villages[1];
    game.armies
      ..clear()
      ..add(Army(
        name: 'Guard',
        owner: 'player',
        stationedAt: here.id,
        destination: there.id,
        origin: here.id,
        units: [Unit.create(UnitType.values.first, 'player', const GeoCoordinate(0, 0))],
      ));
    game.playerCharacter = PlayerCharacter(name: 'Test', currentCityId: there.id, travelOriginId: here.id);
    game.capitalVillageId = here.id;
    await SaveEngine.saveGame(game);

    // the app starts again: nothing of the old game is left in memory
    game.resetGame();
    final loaded = game;
    expect(loaded.armies, isEmpty);
    expect(await SaveEngine.loadGame(loaded), isTrue);
    final hereNow = loaded.getVillage(here.name)!, thereNow = loaded.getVillage(there.name)!;
    expect(hereNow.id, isNot(here.id), reason: 'a rebuilt map gives every city a new id');
    final army = loaded.armies.single;
    expect(loaded.getVillageById(army.stationedAt)?.name, here.name);
    expect(loaded.getVillageById(army.destination)?.name, there.name);
    expect(loaded.getVillageById(army.origin)?.name, here.name);
    expect(loaded.getVillageById(loaded.playerCharacter!.currentCityId)?.name, there.name);
    expect(loaded.getVillageById(loaded.playerCharacter!.travelOriginId)?.name, here.name);
    expect(loaded.capitalVillageId, hereNow.id);
    expect(thereNow.id, isNot(there.id));
    game.resetGame();
  });

  test('a city action is saved soon after, with the loop paused', () async {
    final game = started();
    game.playerCharacter = PlayerCharacter(name: 'Test', currentCityId: game.map.villages[0].id);
    expect(await SaveEngine.hasSave(), isFalse);
    game.notifyListeners();
    game.notifyListeners();
    game.notifyListeners();
    expect(await SaveEngine.hasSave(), isFalse, reason: 'the save waits a moment so a burst of actions writes once');
    await Future<void>.delayed(const Duration(milliseconds: 2400));
    expect(await SaveEngine.hasSave(), isTrue);
    game.resetGame();
  });
}
