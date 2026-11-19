import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:villages_town/data/models/game_modifier.dart';
import 'package:villages_town/data/models/nationality.dart';
import 'package:villages_town/data/models/resource.dart';
import 'package:villages_town/data/models/unit_type.dart';
import 'package:villages_town/engines/game_manager.dart';
import 'package:villages_town/engines/recruitment_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('city hire charges the same doubled Gold Standard cost', () {
    SharedPreferences.setMockInitialValues({});
    final game = GameManager.shared..resetGame();
    game.setupGame(Nationality.ottomans);
    game.initializeGame(characterName: 'Test');
    final city = game.getVillageById(game.playerCharacter!.currentCityId)!;
    game.activeModifiers.add(GameModifier.goldStandard);
    final cost = RecruitmentEngine().recruitCost(UnitType.militia, 1)[Resource.gold]!;
    expect(cost, UnitType.militia.stats.cost[Resource.gold]! * 2);
    final before = game.gold;
    expect(game.recruitToWarband(UnitType.militia, city), isTrue);
    expect(game.gold, before - cost);
  });
}
