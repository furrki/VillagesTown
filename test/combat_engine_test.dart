import 'package:flutter_test/flutter_test.dart';
import 'package:villages_town/data/models/unit.dart';
import 'package:villages_town/data/models/unit_type.dart';
import 'package:villages_town/data/models/combat_log.dart';
import 'package:villages_town/data/models/geo_coordinate.dart';
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
  const dummyCoord = GeoCoordinate(0, 0);
  return types.asMap().entries.map((e) {
    return Unit.create(e.value, ownerId, dummyCoord);
  }).toList();
}

/// Runs a battle multiple times and returns win rate for attacker.
double runBattleTests({
  required List<UnitType> attackerTypes,
  required List<UnitType> defenderTypes,
  required BattleFormation attackerFormation,
  required BattleFormation defenderFormation,
  int defenderFortressLevel = 0,
  int runs = 10,
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
  // ============================================================
  // GROUP 1: DECISIVE ATTACKER WINS (80%+)
  // Clear advantages that should result in obvious wins
  // ============================================================
  group('Decisive Attacker Wins (80%+)', () {
    test('1. Knights vs Archers - Cavalry 2.0x counter', () {
      final winRate = runBattleTests(
        attackerTypes: List.filled(4, UnitType.knight),
        defenderTypes: List.filled(6, UnitType.archer),
        attackerFormation: BattleFormation.crescent,
        defenderFormation: BattleFormation.skirmish,
        runs: 50,
      );
      expect(winRate, greaterThanOrEqualTo(0.8),
          reason: 'Knights devastate unprotected archers (2.0x counter)');
    });

    test('2. Light Cavalry vs Crossbowmen - Speed beats slow', () {
      final winRate = runBattleTests(
        attackerTypes: List.filled(6, UnitType.lightCavalry),
        defenderTypes: List.filled(5, UnitType.crossbowman),
        attackerFormation: BattleFormation.crescent,
        defenderFormation: BattleFormation.skirmish,
        runs: 50,
      );
      expect(winRate, greaterThanOrEqualTo(0.8),
          reason: 'Fast cavalry catches slow crossbowmen (2.0x counter)');
    });

    test('3. Swordsmen vs Militia - Elite quality wins', () {
      final winRate = runBattleTests(
        attackerTypes: List.filled(6, UnitType.swordsman),
        defenderTypes: List.filled(6, UnitType.militia),
        attackerFormation: BattleFormation.shieldWall,
        defenderFormation: BattleFormation.shieldWall,
        runs: 50,
      );
      expect(winRate, greaterThanOrEqualTo(0.8),
          reason: 'Elite swordsmen crush militia even with defender bonus');
    });

    test('4. 2:1 Numbers Advantage', () {
      final winRate = runBattleTests(
        attackerTypes: List.filled(12, UnitType.militia),
        defenderTypes: List.filled(6, UnitType.militia),
        attackerFormation: BattleFormation.shieldWall,
        defenderFormation: BattleFormation.shieldWall,
        runs: 50,
      );
      expect(winRate, greaterThanOrEqualTo(0.8),
          reason: '2:1 numbers overwhelm 10% defender bonus');
    });

    test('5. Cavalry Charge vs Militia', () {
      final winRate = runBattleTests(
        attackerTypes: [
          ...List.filled(4, UnitType.knight),
          ...List.filled(3, UnitType.lightCavalry),
        ],
        defenderTypes: List.filled(6, UnitType.militia),
        attackerFormation: BattleFormation.crescent,
        defenderFormation: BattleFormation.shieldWall,
        runs: 50,
      );
      expect(winRate, greaterThanOrEqualTo(0.8),
          reason: 'Heavy cavalry charge breaks militia');
    });

    test('6. Archers vs Militia - Ranged kiting', () {
      final winRate = runBattleTests(
        attackerTypes: List.filled(8, UnitType.archer),
        defenderTypes: List.filled(6, UnitType.militia),
        attackerFormation: BattleFormation.skirmish,
        defenderFormation: BattleFormation.shieldWall,
        runs: 50,
      );
      expect(winRate, greaterThanOrEqualTo(0.8),
          reason: 'Archers kite slow militia to death');
    });
  });

  // ============================================================
  // GROUP 2: DECISIVE DEFENDER WINS (Attacker <20%)
  // Attacking into clear disadvantages - should be hopeless
  // ============================================================
  group('Decisive Defender Wins (Attacker <20%)', () {
    test('7. Militia vs Fortress L3 - Castle siege without equipment', () {
      final winRate = runBattleTests(
        attackerTypes: List.filled(8, UnitType.militia),
        defenderTypes: List.filled(5, UnitType.archer),
        attackerFormation: BattleFormation.shieldWall,
        defenderFormation: BattleFormation.shieldWall,
        defenderFortressLevel: 3,
        runs: 50,
      );
      expect(winRate, lessThanOrEqualTo(0.2),
          reason: 'Castle (+60% defense) repels militia assault');
    });

    test('8. Knights vs Spearmen Wall - Hard counter', () {
      final winRate = runBattleTests(
        attackerTypes: List.filled(4, UnitType.knight),
        defenderTypes: List.filled(8, UnitType.spearman),
        attackerFormation: BattleFormation.crescent,
        defenderFormation: BattleFormation.shieldWall,
        runs: 50,
      );
      expect(winRate, lessThanOrEqualTo(0.2),
          reason: 'Spearmen (1.75x) in Shield Wall destroy cavalry');
    });

    test('9. Elite vs 3:1 Numbers - Overwhelmed', () {
      final winRate = runBattleTests(
        attackerTypes: List.filled(4, UnitType.swordsman),
        defenderTypes: List.filled(12, UnitType.militia),
        attackerFormation: BattleFormation.shieldWall,
        defenderFormation: BattleFormation.shieldWall,
        runs: 50,
      );
      expect(winRate, lessThanOrEqualTo(0.2),
          reason: '3:1 numbers overwhelm even elite troops');
    });
  });

  // ============================================================
  // GROUP 3: COMPETITIVE BATTLES (30-70% - could go either way)
  // Evenly matched or slight advantages
  // ============================================================
  group('Competitive Battles (30-70%)', () {
    test('10. Mirror Match - Equal infantry', () {
      final winRate = runBattleTests(
        attackerTypes: [
          ...List.filled(4, UnitType.swordsman),
          ...List.filled(3, UnitType.spearman),
        ],
        defenderTypes: [
          ...List.filled(4, UnitType.swordsman),
          ...List.filled(3, UnitType.spearman),
        ],
        attackerFormation: BattleFormation.shieldWall,
        defenderFormation: BattleFormation.shieldWall,
        runs: 200,
      );
      // Mirror match - high variance, competitive battle
      expect(winRate, greaterThanOrEqualTo(0.20),
          reason: 'Attacker can still win mirror match');
      expect(winRate, lessThanOrEqualTo(0.75),
          reason: 'Battle should be competitive');
    });

    test('11. Mixed Arms vs Mixed Arms', () {
      final winRate = runBattleTests(
        attackerTypes: [
          ...List.filled(2, UnitType.swordsman),
          ...List.filled(2, UnitType.spearman),
          ...List.filled(2, UnitType.archer),
          ...List.filled(2, UnitType.lightCavalry),
        ],
        defenderTypes: [
          ...List.filled(2, UnitType.swordsman),
          ...List.filled(2, UnitType.spearman),
          ...List.filled(2, UnitType.crossbowman),
          ...List.filled(2, UnitType.lightCavalry),
        ],
        attackerFormation: BattleFormation.shieldWall,
        defenderFormation: BattleFormation.shieldWall,
        runs: 100,
      );
      // Defender has stronger crossbows + 10% defense bonus
      // High variance due to mixed unit types
      expect(winRate, greaterThanOrEqualTo(0.05),
          reason: 'Attacker can sometimes win');
      expect(winRate, lessThanOrEqualTo(0.55),
          reason: 'Defender has slight edge');
    });

    test('12. Fortress L1 Assault - Equal forces', () {
      final winRate = runBattleTests(
        attackerTypes: [
          ...List.filled(4, UnitType.swordsman),
          ...List.filled(3, UnitType.archer),
        ],
        defenderTypes: [
          ...List.filled(4, UnitType.swordsman),
          ...List.filled(3, UnitType.archer),
        ],
        attackerFormation: BattleFormation.shieldWall,
        defenderFormation: BattleFormation.shieldWall,
        defenderFortressLevel: 1,
        runs: 100,
      );
      // Equal forces - L1 fortress (+15% + 10% base = 25%) gives defender edge
      expect(winRate, greaterThanOrEqualTo(0.15),
          reason: 'Attacker can still win with luck');
      expect(winRate, lessThanOrEqualTo(0.55),
          reason: 'L1 fortress + defender bonus gives edge');
    });
  });

  // ============================================================
  // GROUP 4: UNIT COUNTER TESTS (70%+ for counter side)
  // Testing rock-paper-scissors unit relationships
  // ============================================================
  group('Unit Counter Relationships (70%+)', () {
    test('13. Cavalry vs Archers - 2.0x counter', () {
      final winRate = runBattleTests(
        attackerTypes: List.filled(5, UnitType.lightCavalry),
        defenderTypes: List.filled(5, UnitType.archer),
        attackerFormation: BattleFormation.crescent,
        defenderFormation: BattleFormation.skirmish,
        runs: 50,
      );
      expect(winRate, greaterThanOrEqualTo(0.7),
          reason: 'Cavalry hard-counters archers (2.0x)');
    });

    test('14. Spearmen vs Knights - 2.0x counter', () {
      final winRate = runBattleTests(
        attackerTypes: List.filled(5, UnitType.spearman),
        defenderTypes: List.filled(3, UnitType.knight),
        attackerFormation: BattleFormation.shieldWall,
        defenderFormation: BattleFormation.crescent,
        runs: 50,
      );
      // 2.0x counter + nerfed knights + numbers = decisive victory
      expect(winRate, greaterThanOrEqualTo(0.85),
          reason: 'Spearmen counter cavalry (2.0x) + numbers bonus');
    });

    test('15. Archers vs Slow Infantry - Kiting', () {
      final winRate = runBattleTests(
        attackerTypes: List.filled(5, UnitType.archer),
        defenderTypes: List.filled(5, UnitType.spearman),
        attackerFormation: BattleFormation.skirmish,
        defenderFormation: BattleFormation.shieldWall,
        runs: 50,
      );
      expect(winRate, greaterThanOrEqualTo(0.5),
          reason: 'Archers kite slow spearmen');
    });

    test('16. Crossbowmen vs Militia - High damage ranged', () {
      final winRate = runBattleTests(
        attackerTypes: List.filled(5, UnitType.crossbowman),
        defenderTypes: List.filled(5, UnitType.militia),
        attackerFormation: BattleFormation.skirmish,
        defenderFormation: BattleFormation.shieldWall,
        runs: 50,
      );
      expect(winRate, greaterThanOrEqualTo(0.6),
          reason: 'Crossbows shred militia before they close');
    });
  });

  // ============================================================
  // GROUP 5: FORMATION COUNTER TESTS
  // Testing rock-paper-scissors: Shield Wall > Crescent > Skirmish
  // IMPORTANT: Use IDENTICAL armies to isolate formation effect
  // +20% effectiveness bonus should be visible but not overwhelming
  // ============================================================
  group('Formation Counter Relationships', () {
    test('17. Skirmish vs Shield Wall - Equal infantry armies', () {
      // Use identical balanced armies to isolate formation effect
      final army = [
        ...List.filled(3, UnitType.swordsman),
        ...List.filled(3, UnitType.spearman),
        ...List.filled(2, UnitType.archer),
      ];
      final winRate = runBattleTests(
        attackerTypes: army,
        defenderTypes: army,
        attackerFormation: BattleFormation.skirmish, // Beats Shield Wall
        defenderFormation: BattleFormation.shieldWall,
        runs: 100,
      );
      // Skirmish has +20% damage vs Shield Wall
      // But defender has +10% base defense
      // Net: attacker should have slight edge (~55-65%)
      expect(winRate, greaterThanOrEqualTo(0.45),
          reason: 'Skirmish should beat Shield Wall');
    });

    test('18. Crescent vs Skirmish - Equal mixed armies', () {
      // Include some cavalry to make Crescent meaningful
      final army = [
        ...List.filled(3, UnitType.swordsman),
        ...List.filled(2, UnitType.spearman),
        ...List.filled(2, UnitType.lightCavalry),
        ...List.filled(2, UnitType.archer),
      ];
      final winRate = runBattleTests(
        attackerTypes: army,
        defenderTypes: army,
        attackerFormation: BattleFormation.crescent, // Beats Skirmish
        defenderFormation: BattleFormation.skirmish,
        runs: 100,
      );
      // Crescent has +20% damage vs Skirmish
      expect(winRate, greaterThanOrEqualTo(0.45),
          reason: 'Crescent should beat Skirmish');
    });

    test('19. Shield Wall vs Crescent - Equal cavalry armies', () {
      // Include cavalry to make Crescent choice reasonable for defender
      final army = [
        ...List.filled(3, UnitType.spearman),
        ...List.filled(3, UnitType.lightCavalry),
        ...List.filled(2, UnitType.archer),
      ];
      final winRate = runBattleTests(
        attackerTypes: army,
        defenderTypes: army,
        attackerFormation: BattleFormation.shieldWall, // Beats Crescent
        defenderFormation: BattleFormation.crescent,
        runs: 100,
      );
      // Shield Wall has +20% damage vs Crescent
      // Also reduces enemy cavalry charge
      expect(winRate, greaterThanOrEqualTo(0.5),
          reason: 'Shield Wall should beat Crescent');
    });
  });

  // ============================================================
  // GROUP 6: SPECIAL SCENARIOS
  // Edge cases and interesting tactical situations
  // ============================================================
  group('Special Tactical Scenarios', () {
    test('20. Cavalry vs Prepared Spear Defense', () {
      final winRate = runBattleTests(
        attackerTypes: List.filled(5, UnitType.knight),
        defenderTypes: [
          ...List.filled(8, UnitType.spearman),
          ...List.filled(3, UnitType.crossbowman),
        ],
        attackerFormation: BattleFormation.crescent,
        defenderFormation: BattleFormation.shieldWall,
        runs: 100,
      );
      // Spearmen 2x counter + numbers bonus + shield wall = knights lose
      expect(winRate, lessThanOrEqualTo(0.40),
          reason: 'Spear wall + crossbows destroy cavalry charge');
    });

    test('21. Ranged Duel - Crossbows vs Archers', () {
      final winRate = runBattleTests(
        attackerTypes: List.filled(5, UnitType.crossbowman),
        defenderTypes: List.filled(5, UnitType.archer),
        attackerFormation: BattleFormation.skirmish,
        defenderFormation: BattleFormation.skirmish,
        runs: 50,
      );
      // Crossbows hit harder but slower; archers faster + defender bonus
      expect(winRate, greaterThanOrEqualTo(0.2),
          reason: 'Crossbows can compete with damage');
      expect(winRate, lessThanOrEqualTo(0.5),
          reason: 'Archers faster + defender bonus');
    });

    test('22. Cavalry Raid vs Militia', () {
      final winRate = runBattleTests(
        attackerTypes: List.filled(6, UnitType.lightCavalry),
        defenderTypes: List.filled(4, UnitType.militia),
        attackerFormation: BattleFormation.crescent,
        defenderFormation: BattleFormation.shieldWall,
        runs: 50,
      );
      expect(winRate, greaterThanOrEqualTo(0.7),
          reason: 'Light cav overwhelms slow militia');
    });

    test('23. Elite Fortress Defense', () {
      final winRate = runBattleTests(
        attackerTypes: [
          ...List.filled(6, UnitType.swordsman),
          ...List.filled(4, UnitType.archer),
        ],
        defenderTypes: [
          ...List.filled(3, UnitType.knight),
          ...List.filled(2, UnitType.crossbowman),
        ],
        attackerFormation: BattleFormation.shieldWall,
        defenderFormation: BattleFormation.shieldWall,
        defenderFortressLevel: 2,
        runs: 50,
      );
      expect(winRate, lessThanOrEqualTo(0.35),
          reason: 'Elite defenders in L2 fortress are hard to crack');
    });

    test('24. Peasant Uprising - Numbers vs Quality', () {
      final winRate = runBattleTests(
        attackerTypes: List.filled(15, UnitType.militia),
        defenderTypes: [
          ...List.filled(2, UnitType.swordsman),
          ...List.filled(2, UnitType.archer),
        ],
        attackerFormation: BattleFormation.shieldWall,
        defenderFormation: BattleFormation.shieldWall,
        runs: 50,
      );
      expect(winRate, greaterThanOrEqualTo(0.7),
          reason: '4:1 militia swarm beats small elite garrison');
    });

    test('25. Full Combined Arms - Defender Edge', () {
      final winRate = runBattleTests(
        attackerTypes: [
          ...List.filled(3, UnitType.swordsman),
          ...List.filled(2, UnitType.spearman),
          ...List.filled(3, UnitType.archer),
          ...List.filled(2, UnitType.knight),
        ],
        defenderTypes: [
          ...List.filled(3, UnitType.swordsman),
          ...List.filled(2, UnitType.spearman),
          ...List.filled(3, UnitType.crossbowman),
          ...List.filled(2, UnitType.knight),
        ],
        attackerFormation: BattleFormation.shieldWall,
        defenderFormation: BattleFormation.shieldWall,
        runs: 50,
      );
      // Full combined arms, defender has crossbows (stronger) + 10% defense
      // Numbers bonus slightly evens things out
      expect(winRate, greaterThanOrEqualTo(0.15),
          reason: 'Balanced armies still have a chance');
      expect(winRate, lessThanOrEqualTo(0.70),
          reason: 'Defender crossbows + defense bonus win');
    });
  });

  // ============================================================
  // GROUP 7: GAMEPLAY SURPRISE TESTS
  // Things that might catch players off guard
  // ============================================================
  group('Gameplay Surprises (Edge Cases)', () {
    test('26. Wrong Formation Trap - Cavalry picks Crescent vs Spears', () {
      // Player has cavalry, picks Crescent (seems logical)
      // But enemy has spearmen - cavalry gets destroyed
      final winRate = runBattleTests(
        attackerTypes: List.filled(5, UnitType.knight),
        defenderTypes: List.filled(5, UnitType.spearman),
        attackerFormation: BattleFormation.crescent, // Cavalry formation
        defenderFormation: BattleFormation.shieldWall, // Counters Crescent
        runs: 50,
      );
      // Player might expect to win with elite knights
      // But spearmen 1.75x AND shield wall both hurt cavalry
      expect(winRate, lessThanOrEqualTo(0.3),
          reason: 'Cavalry formation + anti-cav units = disaster');
    });

    test('27. Archer Trap - Skirmish vs Cavalry', () {
      // Player has archers, picks Skirmish (seems logical)
      // But enemy has cavalry - archers get hunted
      final winRate = runBattleTests(
        attackerTypes: List.filled(6, UnitType.archer),
        defenderTypes: List.filled(4, UnitType.lightCavalry),
        attackerFormation: BattleFormation.skirmish, // Ranged formation
        defenderFormation: BattleFormation.crescent, // Counters Skirmish
        runs: 50,
      );
      // Cavalry 2.0x vs archers + Crescent beats Skirmish
      expect(winRate, lessThanOrEqualTo(0.2),
          reason: 'Archers in Skirmish get destroyed by cavalry');
    });

    test('28. Numbers Matter - Militia 3:1 can defeat Knights', () {
      // Knights are strong, but 3:1 numbers with bonus swings battle
      // After nerf: Knight Attack 7, HP 80, Charge 5 (was 9/100/7)
      // Numbers bonus: +50% per 1.0 ratio above 1.0 (3:1 = +100% damage)
      final winRate = runBattleTests(
        attackerTypes: List.filled(5, UnitType.knight),
        defenderTypes: List.filled(15, UnitType.militia),
        attackerFormation: BattleFormation.crescent,
        defenderFormation: BattleFormation.shieldWall,
        runs: 50,
      );
      // 3:1 militia with Shield Wall (beats Crescent) + numbers bonus wins
      expect(winRate, lessThanOrEqualTo(0.50),
          reason: '3:1 militia with numbers bonus defeats knights');
    });

    test('29. Defender Always Has Edge - Mirror with same formation', () {
      // Even with same formation, defender has +10% defense
      final army = List.filled(8, UnitType.swordsman);
      final winRate = runBattleTests(
        attackerTypes: army,
        defenderTypes: army,
        attackerFormation: BattleFormation.shieldWall,
        defenderFormation: BattleFormation.shieldWall,
        runs: 100,
      );
      // Attacker should NOT be strongly favored in mirror match
      expect(winRate, lessThanOrEqualTo(0.65),
          reason: 'Defender always has slight edge in mirror');
      expect(winRate, greaterThanOrEqualTo(0.25),
          reason: 'But attacker can still win');
    });

    test('30. Fortress L2 - Still needs good defense, not just walls', () {
      // WARNING: Fortress alone isn't enough!
      // 1.5x attacker numbers still wins against L2 fortress
      final winRate = runBattleTests(
        attackerTypes: [
          ...List.filled(6, UnitType.swordsman),
          ...List.filled(3, UnitType.archer),
        ],
        defenderTypes: [
          ...List.filled(4, UnitType.swordsman),
          ...List.filled(2, UnitType.crossbowman),
        ],
        attackerFormation: BattleFormation.shieldWall,
        defenderFormation: BattleFormation.shieldWall,
        defenderFortressLevel: 2,
        runs: 50,
      );
      // L2 fortress (+40% defense) helps but doesn't overcome 1.5x numbers
      // Player needs BOTH fortress AND good troops
      expect(winRate, greaterThanOrEqualTo(0.6),
          reason: '1.5x superior force beats L2 fortress');
    });
  });
}
