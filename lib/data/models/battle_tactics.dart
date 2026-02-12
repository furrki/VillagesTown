import 'battle_terrain.dart';
import 'combat_log.dart';
import 'unit_type.dart';

/// Tactical role for a unit group in battle.
enum UnitRole {
  vanguard('Vanguard', 'First to engage, +10% attack, -10% defense'),
  mainBody('Main Body', 'Balanced, no modifier'),
  reserve('Reserve', 'Enters after 40% duration, +15% flanking bonus'),
  flankers('Flankers', 'Cavalry-only, bypass infantry, +20% vs ranged');

  final String displayName;
  final String description;
  const UnitRole(this.displayName, this.description);
}

/// Overall battle strategy.
enum EngagementOrder {
  aggressivePush('Aggressive Push', '+15% attack, -10% defense', '⚔️'),
  holdGround('Hold Ground', '+15% defense, -10% attack, +1 range', '🛡️'),
  feignedRetreat('Feigned Retreat', '50/50: +30% attack or -20% attack', '🎭');

  final String displayName;
  final String description;
  final String emoji;
  const EngagementOrder(this.displayName, this.description, this.emoji);
}

/// Complete pre-battle tactical configuration for one side.
class BattleTactics {
  final BattleTerrain? terrain; // Only defender chooses
  final BattleFormation formation;
  final EngagementOrder engagementOrder;
  final Map<UnitType, UnitRole> roleAssignments;

  const BattleTactics({
    this.terrain,
    this.formation = BattleFormation.shieldWall,
    this.engagementOrder = EngagementOrder.aggressivePush,
    this.roleAssignments = const {},
  });

  /// Get synergies for this tactical setup.
  List<String> getSynergies(BattleTactics? opponentTactics) {
    final synergies = <String>[];
    final t = terrain;

    // Cavalry flankers + Open Field → +10% extra charge
    if (t == BattleTerrain.openField &&
        roleAssignments.values.any((r) => r == UnitRole.flankers) &&
        roleAssignments.entries.any((e) =>
            e.value == UnitRole.flankers && e.key.category == 'Cavalry')) {
      synergies.add('Cavalry Charge: +10% charge on open field');
    }

    // Archers in reserve + Hill + Hold Ground → +10% extra ranged
    if (t == BattleTerrain.hill &&
        engagementOrder == EngagementOrder.holdGround &&
        roleAssignments.entries.any((e) =>
            e.value == UnitRole.reserve && e.key.category == 'Ranged')) {
      synergies.add('Hilltop Archers: +10% ranged from reserve position');
    }

    // Feigned Retreat + Reserve → Reserve gets +25% instead of +15%
    if (engagementOrder == EngagementOrder.feignedRetreat &&
        roleAssignments.values.any((r) => r == UnitRole.reserve)) {
      synergies.add('Counter-Attack: Reserve gets +25% on feigned retreat');
    }

    // Forest + Skirmish → ambush chance
    if (t == BattleTerrain.forest && formation == BattleFormation.skirmish) {
      synergies.add('Forest Ambush: 5% chance to instant-kill enemies');
    }

    return synergies;
  }
}
