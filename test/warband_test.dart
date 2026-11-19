import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:villages_town/data/models/nationality.dart';
import 'package:villages_town/data/models/unit_type.dart';
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
}
