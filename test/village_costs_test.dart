import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:villages_town/data/models/building.dart';
import 'package:villages_town/data/models/game_modifier.dart';
import 'package:villages_town/data/models/resource.dart';
import 'package:villages_town/data/models/unit_type.dart';
import 'package:villages_town/engines/building_construction_engine.dart';
import 'package:villages_town/engines/game_manager.dart';
import 'package:villages_town/engines/recruitment_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GameManager.shared.resetGame();
  });

  test('farm build cost doubles only gold under Gold Standard', () {
    final engine = BuildingConstructionEngine();
    expect(engine.buildCost(Building.farm), {
      Resource.gold: 50,
      Resource.wood: 20,
    });

    GameManager.shared.activeModifiers.add(GameModifier.goldStandard);
    expect(engine.buildCost(Building.farm), {
      Resource.gold: 100,
      Resource.wood: 20,
    });
  });

  test('farm upgrade cost follows level and Gold Standard', () {
    final engine = BuildingConstructionEngine();
    final farm = Building.farm;
    final levelTwoFarm = farm.copyWith(level: 2);
    expect(engine.upgradeCostFor(farm), {
      Resource.gold: 75,
      Resource.wood: 30,
    });
    expect(engine.upgradeCostFor(levelTwoFarm), {
      Resource.gold: 150,
      Resource.wood: 60,
    });

    GameManager.shared.activeModifiers.add(GameModifier.goldStandard);
    expect(engine.upgradeCostFor(farm), {
      Resource.gold: 150,
      Resource.wood: 30,
    });
    expect(engine.upgradeCostFor(levelTwoFarm), {
      Resource.gold: 300,
      Resource.wood: 60,
    });
  });

  test('militia recruitment gold doubles under Gold Standard', () {
    final engine = RecruitmentEngine();
    final normalCost = engine.recruitCost(UnitType.militia, 1);
    GameManager.shared.activeModifiers.add(GameModifier.goldStandard);
    expect(engine.recruitCost(UnitType.militia, 1)[Resource.gold],
        normalCost[Resource.gold]! * 2);
  });
}
