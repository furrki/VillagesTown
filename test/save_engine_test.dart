import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:villages_town/data/models/nationality.dart';
import 'package:villages_town/data/models/player_character.dart';
import 'package:villages_town/engines/game_manager.dart';
import 'package:villages_town/engines/save_engine.dart';
import 'package:villages_town/ui/screens/game_view_rts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  GameManager started() {
    final game = GameManager.shared..resetGame();
    game.setupGame(Nationality.ottomans);
    game.gameStarted = true;
    game.playerCharacter = PlayerCharacter(name: 'Test', currentCityId: game.map.villages.first.id);
    return game;
  }

  test('immediate menu exit saves a city action', () async {
    final game = started();
    game.playerCharacter!.gold = 1234;
    game.notifyListeners();
    final gold = game.gold;
    await saveAndReturnToMenu(game);
    expect(await SaveEngine.loadGame(game), isTrue);
    expect(game.gold, gold);
    game.resetGame();
  });

  test('immediate menu exit saves travel progress', () async {
    final game = started();
    final pc = game.playerCharacter!;
    pc.state = PlayerState.traveling;
    pc.travelOriginId = game.map.villages.first.id;
    pc.travelDestinationId = game.map.villages[1].id;
    pc.travelProgress = 0.42;
    await saveAndReturnToMenu(game);
    expect(await SaveEngine.loadGame(game), isTrue);
    expect(game.playerCharacter!.state, PlayerState.traveling);
    expect(game.playerCharacter!.travelProgress, 0.42);
    game.resetGame();
  });
}
