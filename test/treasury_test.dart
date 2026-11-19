import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:villages_town/data/models/nationality.dart';
import 'package:villages_town/data/models/resource.dart';
import 'package:villages_town/engines/game_manager.dart';
import 'package:villages_town/engines/population_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  GameManager started() {
    final game = GameManager.shared..resetGame();
    game.setupGame(Nationality.ottomans);
    game.initializeGame(characterName: 'Test');
    return game;
  }

  // The villages are the one treasury: the top bar must show their sum.
  int villageGold(GameManager game) => game
      .getPlayerVillages('player')
      .fold(0, (sum, v) => sum + (v.resources[Resource.gold] ?? 0));

  test('a turn of taxes reaches the treasury and the villages agree', () {
    final game = started();
    final before = game.getGlobalResources('player')[Resource.gold]!;
    final taxes =
        game.getPlayerVillages('player').fold(0, (s, v) => s + v.population);
    PopulationEngine().collectTaxes(game.map.villages);
    game.syncGlobalResources();
    expect(game.getGlobalResources('player')[Resource.gold], before + taxes);
    expect(game.getGlobalResources('player')[Resource.gold], villageGold(game));
  });

  test('a purchase is debited from the villages and stays paid over a turn', () {
    final game = started();
    final before = game.getGlobalResources('player')[Resource.gold]!;
    expect(game.spendResources('player', {Resource.gold: 100}), isTrue);
    expect(villageGold(game), before - 100);
    game.turnEngine.doTurn();
    expect(game.getGlobalResources('player')[Resource.gold], villageGold(game));
  });
}
