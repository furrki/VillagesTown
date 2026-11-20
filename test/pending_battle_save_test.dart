import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:villages_town/data/models/army.dart';
import 'package:villages_town/data/models/battle_terrain.dart';
import 'package:villages_town/data/models/combat_log.dart';
import 'package:villages_town/data/models/geo_coordinate.dart';
import 'package:villages_town/data/models/nationality.dart';
import 'package:villages_town/data/models/player_character.dart';
import 'package:villages_town/data/models/unit.dart';
import 'package:villages_town/data/models/unit_type.dart';
import 'package:villages_town/domain/entities/unit.dart' show UnitCategory;
import 'package:villages_town/engines/game_manager.dart';
import 'package:villages_town/engines/save_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('restores and finalizes a queued siege, including old saves', () async {
    final game = GameManager.shared..resetGame();
    game.setupGame(Nationality.ottomans);
    game.gameStarted = true;
    final origin = game.map.villages.first;
    final target = game.map.villages[1];
    target.owner = 'enemy';
    target.garrisonStrength = 3;
    target.underSiege = true;
    game.playerCharacter = PlayerCharacter(name: 'Test', currentCityId: origin.id);
    final army = Army(id: 'siege-army', name: 'Siege', owner: 'player',
      stationedAt: target.id, state: ArmyState.besieging,
      units: List.generate(3, (_) => Unit.create(UnitType.militia, 'player', const GeoCoordinate(0, 0))));
    game.armies.add(army);
    final time = DateTime.utc(2020, 1, 2, 3, 4, 5);
    final battle = BattleRecord(id: 'battle', attackerName: 'Attack', defenderName: 'Defend',
      attackerId: army.id, defenderId: target.id, originVillageId: origin.id,
      attackerOwnerId: 'player', defenderOwnerId: 'enemy', locationName: target.name,
      rounds: [BattleRound(attackerRolls: [1], defenderRolls: [2], attackerBonus: 2,
        defenderBonus: 3, attackerLosses: 1, defenderLosses: 2, narration: 'round')],
      phases: [PhaseResult(phase: CombatPhase.melee, attackerLuckRoll: 4, defenderLuckRoll: 5,
        attackerLuckModifier: 1.1, defenderLuckModifier: 0.9, attackerKills: 2, defenderKills: 1,
        attackerCasualtiesByType: {UnitCategory.infantry: 1},
        defenderCasualtiesByType: {UnitCategory.cavalry: 2}, narration: 'phase')],
      engagements: [const BattleEngagement(isCityAssault: true, attackerStart: 3,
        defenderStart: 3, attackerSurvivors: 2, defenderSurvivors: 1, attackerWon: true)],
      attackerWon: true, initialAttackerCount: 3, initialDefenderCount: 3,
      initialGarrisonCount: 3, timestamp: time, terrain: BattleTerrain.hill,
      attackerFormation: BattleFormation.crescent, defenderFormation: BattleFormation.shieldWall,
      formationBonus: 1.02, attackerBarracksLevel: 1, attackerArcheryLevel: 2,
      attackerStablesLevel: 3, defenderBarracksLevel: 4, defenderArcheryLevel: 5, defenderStablesLevel: 6);
    game.pendingBattles.add(battle);
    expect(await SaveEngine.saveGame(game), isTrue);
    game.resetGame();
    expect(await SaveEngine.loadGame(game), isTrue);
    final restored = game.pendingBattles.single;
    final restoredTarget = game.getVillage(target.name)!;
    expect(restored.attackerId, army.id);
    expect(restored.defenderId, restoredTarget.id);
    expect(restored.originVillageId, game.getVillage(origin.name)!.id);
    final originalJson = battle.toJson()..['defenderId'] = restoredTarget.id
      ..['originVillageId'] = game.getVillage(origin.name)!.id;
    expect(restored.toJson(), originalJson);
    game.finalizeBattle(restored, 1, false);
    expect(restoredTarget.owner, 'player');
    expect(game.getArmyById(army.id)!.units.length, 2);
    expect(game.pendingBattles, isEmpty);
    expect(await SaveEngine.saveGame(game), isTrue);
    game.resetGame();
    expect(await SaveEngine.loadGame(game), isTrue);
    expect(game.getVillage(target.name)!.owner, 'player');
    expect(game.getArmyById(army.id)!.units.length, 2);
    expect(game.pendingBattles, isEmpty);
    final prefs = await SharedPreferences.getInstance();
    final old = jsonDecode(prefs.getString('game_save_v1')!) as Map<String, dynamic>;
    old.remove('pendingBattles');
    await prefs.setString('game_save_v1', jsonEncode(old));
    game.pendingBattles.add(battle);
    expect(await SaveEngine.loadGame(game), isTrue);
    expect(game.pendingBattles, isEmpty);
    game.resetGame();
  });
}
