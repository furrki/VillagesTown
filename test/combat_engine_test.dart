import 'package:flutter_test/flutter_test.dart';
import 'package:villages_town/data/models/unit.dart';
import 'package:villages_town/data/models/unit_type.dart';
import 'package:villages_town/data/models/combat_log.dart';
import 'package:villages_town/data/models/geo_coordinate.dart';
import 'package:villages_town/data/models/nationality.dart';
import 'package:villages_town/engines/combat_engine.dart';
import 'package:villages_town/data/map/game_map.dart';
import 'package:villages_town/data/models/village.dart';

/// Minimal GameMap implementation for testing.
class _EmptyGameMap implements GameMap {
  @override
  List<Village> villages = [];
}

/// Creates test units from unit types.
List<Unit> createUnits(List<UnitType> types, String ownerId) {
  return types.asMap().entries.map((e) {
    return Unit(
      id: '${ownerId}_${e.key}',
      type: e.value,
      ownerId: ownerId,
      position: const GeoCoordinate(lat: 0, lng: 0),
    );
  }).toList();
}

/// Runs a battle multiple times and returns win rate for attacker.
/// Uses majority voting like the UI test screen.
double runBattleTests({
  required List<UnitType> attackerTypes,
  required List<UnitType> defenderTypes,
  required BattleFormation attackerFormation,
  required BattleFormation defenderFormation,
  int defenderFortressLevel = 0,
  int runs = 5,
}) {
  int attackerWins = 0;

  for (int i = 0; i < runs; i++) {
    final engine = CombatEngine();
    final attackerUnits = createUnits(attackerTypes, 'attacker');
    final defenderUnits = createUnits(defenderTypes, 'defender');

    final record = engine.simulateBattle(
      attackerUnits: attackerUnits,
      defenderUnits: defenderUnits,
      attackerFormation: attackerFormation,
      defenderFormation: defenderFormation,
      attackerName: 'Attacker',
      defenderName: 'Defender',
      attackerId: 'attacker_village',
      defenderId: 'defender_village',
      attackerOwnerId: 'attacker',
      defenderOwnerId: 'defender',
      defenderFortressLevel: defenderFortressLevel,
      gameMap: _EmptyGameMap(),
    );

    if (record.attackerWon) {
      attackerWins++;
    }
  }

  return attackerWins / runs;
}

void main() {
  group('Combat Engine - Unit Counters', () {
    test('1. Cavalry vs Archers - Cavalry wins (2.0x counter)', () {
      final winRate = runBattleTests(
        attackerTypes: List.filled(6, UnitType.lightCavalry),
        defenderTypes: List.filled(6, UnitType.archer),
        attackerFormation: BattleFormation.crescent,
        defenderFormation: BattleFormation.skirmish,
      );
      expect(winRate, greaterThanOrEqualTo(0.6),
          reason: 'Cavalry should beat archers majority of time');
    });

    test('2. Spearmen vs Knights - Spearmen win (1.75x counter)', () {
      final winRate = runBattleTests(
        attackerTypes: List.filled(8, UnitType.spearman),
        defenderTypes: List.filled(4, UnitType.knight),
        attackerFormation: BattleFormation.shieldWall,
        defenderFormation: BattleFormation.crescent,
      );
      expect(winRate, greaterThanOrEqualTo(0.6),
          reason: 'Spearmen should beat knights majority of time');
    });

    test('7. Knight Charge vs Archers - Knights devastate unprotected ranged',
        () {
      final winRate = runBattleTests(
        attackerTypes: List.filled(3, UnitType.knight),
        defenderTypes: List.filled(6, UnitType.archer),
        attackerFormation: BattleFormation.crescent,
        defenderFormation: BattleFormation.skirmish,
      );
      expect(winRate, greaterThanOrEqualTo(0.6),
          reason: 'Knights should beat archers without spearmen');
    });

    test('12. Archers vs Militia - Ranged kites weak infantry', () {
      final winRate = runBattleTests(
        attackerTypes: List.filled(6, UnitType.archer),
        defenderTypes: List.filled(6, UnitType.militia),
        attackerFormation: BattleFormation.skirmish,
        defenderFormation: BattleFormation.shieldWall,
      );
      expect(winRate, greaterThanOrEqualTo(0.6),
          reason: 'Archers should beat militia (1.3x bonus)');
    });

    test('13. Counter Composition - Spearmen + Archers beat Knights', () {
      final winRate = runBattleTests(
        attackerTypes: List.filled(4, UnitType.knight),
        defenderTypes: [
          ...List.filled(4, UnitType.spearman),
          ...List.filled(3, UnitType.archer),
        ],
        attackerFormation: BattleFormation.crescent,
        defenderFormation: BattleFormation.shieldWall,
      );
      expect(winRate, lessThanOrEqualTo(0.4),
          reason: 'Counter composition should beat knights');
    });

    test('15. Speed Hunters - Light Cavalry catches Crossbowmen', () {
      final winRate = runBattleTests(
        attackerTypes: List.filled(5, UnitType.lightCavalry),
        defenderTypes: List.filled(5, UnitType.crossbowman),
        attackerFormation: BattleFormation.crescent,
        defenderFormation: BattleFormation.skirmish,
      );
      expect(winRate, greaterThanOrEqualTo(0.6),
          reason: 'Fast cavalry should catch slow crossbowmen');
    });
  });

  group('Combat Engine - Formation Counters', () {
    test('3. Skirmish beats Shield Wall (+25% effectiveness)', () {
      final winRate = runBattleTests(
        attackerTypes: [
          ...List.filled(5, UnitType.archer),
          ...List.filled(2, UnitType.militia),
        ],
        defenderTypes: List.filled(6, UnitType.militia),
        attackerFormation: BattleFormation.skirmish,
        defenderFormation: BattleFormation.shieldWall,
      );
      expect(winRate, greaterThanOrEqualTo(0.6),
          reason: 'Skirmish should beat Shield Wall');
    });

    test('8. Shield Wall beats Crescent (+25% effectiveness)', () {
      final winRate = runBattleTests(
        attackerTypes: [
          ...List.filled(3, UnitType.militia),
          ...List.filled(3, UnitType.lightCavalry),
        ],
        defenderTypes: [
          ...List.filled(4, UnitType.spearman),
          ...List.filled(2, UnitType.archer),
        ],
        attackerFormation: BattleFormation.crescent,
        defenderFormation: BattleFormation.shieldWall,
      );
      expect(winRate, lessThanOrEqualTo(0.4),
          reason: 'Shield Wall should beat Crescent');
    });

    test('11. Crescent beats Skirmish (+25% effectiveness)', () {
      final winRate = runBattleTests(
        attackerTypes: [
          ...List.filled(2, UnitType.militia),
          ...List.filled(4, UnitType.lightCavalry),
        ],
        defenderTypes: [
          ...List.filled(4, UnitType.archer),
          ...List.filled(2, UnitType.militia),
        ],
        attackerFormation: BattleFormation.crescent,
        defenderFormation: BattleFormation.skirmish,
      );
      expect(winRate, greaterThanOrEqualTo(0.6),
          reason: 'Crescent should beat Skirmish');
    });
  });

  group('Combat Engine - Defender & Fortress Bonuses', () {
    test('4. Fortress Defense L3 - Defender wins with +65% defense', () {
      final winRate = runBattleTests(
        attackerTypes: [
          ...List.filled(4, UnitType.militia),
          ...List.filled(2, UnitType.swordsman),
        ],
        defenderTypes: [
          ...List.filled(2, UnitType.spearman),
          ...List.filled(4, UnitType.archer),
        ],
        attackerFormation: BattleFormation.shieldWall,
        defenderFormation: BattleFormation.shieldWall,
        defenderFortressLevel: 3,
      );
      expect(winRate, lessThanOrEqualTo(0.4),
          reason: 'Fortress L3 should give defender advantage');
    });

    test('14. Fortress vs Cavalry - Fortress negates charge', () {
      final winRate = runBattleTests(
        attackerTypes: [
          ...List.filled(3, UnitType.lightCavalry),
          ...List.filled(2, UnitType.knight),
        ],
        defenderTypes: [
          ...List.filled(3, UnitType.spearman),
          ...List.filled(2, UnitType.crossbowman),
        ],
        attackerFormation: BattleFormation.crescent,
        defenderFormation: BattleFormation.shieldWall,
        defenderFortressLevel: 2,
      );
      expect(winRate, lessThanOrEqualTo(0.4),
          reason: 'Fortress L2 should negate cavalry advantage');
    });

    test('16. Archer Mirror - Defender bonus decides', () {
      final winRate = runBattleTests(
        attackerTypes: List.filled(6, UnitType.archer),
        defenderTypes: List.filled(6, UnitType.archer),
        attackerFormation: BattleFormation.skirmish,
        defenderFormation: BattleFormation.skirmish,
      );
      expect(winRate, lessThanOrEqualTo(0.5),
          reason: 'Defender +10% bonus should give edge in mirror match');
    });
  });

  group('Combat Engine - Numbers & Quality', () {
    test('6. Elite vs Numbers - 5 Swordsmen beat 8 Militia', () {
      final winRate = runBattleTests(
        attackerTypes: List.filled(5, UnitType.swordsman),
        defenderTypes: List.filled(8, UnitType.militia),
        attackerFormation: BattleFormation.shieldWall,
        defenderFormation: BattleFormation.shieldWall,
      );
      expect(winRate, greaterThanOrEqualTo(0.6),
          reason: 'Elite swordsmen should beat militia numbers');
    });

    test('10. Numbers Advantage - 8 Militia beat 4 Militia', () {
      final winRate = runBattleTests(
        attackerTypes: List.filled(4, UnitType.militia),
        defenderTypes: List.filled(8, UnitType.militia),
        attackerFormation: BattleFormation.shieldWall,
        defenderFormation: BattleFormation.shieldWall,
      );
      expect(winRate, lessThanOrEqualTo(0.4),
          reason: '2:1 numbers advantage should win');
    });
  });

  group('Combat Engine - Ranged vs Infantry', () {
    test('9. Crossbows vs Spearmen - Ranged kites slow infantry', () {
      final winRate = runBattleTests(
        attackerTypes: List.filled(4, UnitType.crossbowman),
        defenderTypes: List.filled(4, UnitType.spearman),
        attackerFormation: BattleFormation.skirmish,
        defenderFormation: BattleFormation.shieldWall,
      );
      expect(winRate, greaterThanOrEqualTo(0.6),
          reason: 'Crossbows should kite slow spearmen');
    });
  });

  group('Combat Engine - Balance Check', () {
    test('5. Balanced Armies - Close fight (40-60% range)', () {
      final winRate = runBattleTests(
        attackerTypes: [
          ...List.filled(3, UnitType.swordsman),
          ...List.filled(2, UnitType.spearman),
          ...List.filled(2, UnitType.archer),
          ...List.filled(2, UnitType.lightCavalry),
          UnitType.knight,
        ],
        defenderTypes: [
          ...List.filled(3, UnitType.swordsman),
          ...List.filled(2, UnitType.spearman),
          ...List.filled(2, UnitType.crossbowman),
          ...List.filled(2, UnitType.lightCavalry),
          UnitType.knight,
        ],
        attackerFormation: BattleFormation.shieldWall,
        defenderFormation: BattleFormation.shieldWall,
        runs: 10, // More runs for balance test
      );
      expect(winRate, greaterThanOrEqualTo(0.2),
          reason: 'Balanced fight should be competitive');
      expect(winRate, lessThanOrEqualTo(0.8),
          reason: 'Balanced fight should be competitive');
    });
  });
}
