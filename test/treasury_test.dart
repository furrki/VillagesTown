import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:villages_town/data/models/nationality.dart';
import 'package:villages_town/data/models/resource.dart';
import 'package:villages_town/engines/game_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('income added to the treasury survives the next projection', () {
    final game = GameManager.shared..resetGame();
    game.setupGame(Nationality.ottomans);
    game.initializeGame(characterName: 'Test');
    final before = game.getGlobalResources('player')[Resource.gold]!;
    game.modifyGlobalResource('player', Resource.gold, 50);
    game.syncGlobalResources();
    expect(game.getGlobalResources('player')[Resource.gold], before + 50);
  });
}
