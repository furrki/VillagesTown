import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:villages_town/data/models/nationality.dart';
import 'package:villages_town/engines/game_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('the vision set matches isVillageInVisionRange for every village', () {
    final game = GameManager.shared..resetGame();
    game.setupGame(Nationality.ottomans);
    game.initializeGame(characterName: 'Test');
    game.map.villages.firstWhere((v) => v.owner == 'neutral').owner = 'player';

    final inVision = game.villageIdsInVisionRange('player');
    for (final village in game.map.villages) {
      expect(
        inVision.contains(village.id),
        game.isVillageInVisionRange(village, 'player'),
        reason: village.name,
      );
    }
  });
}
