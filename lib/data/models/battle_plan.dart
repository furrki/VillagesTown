import 'army.dart';
import 'battle_tactics.dart';
import 'combat_log.dart';
import 'unit_type.dart';

enum BattlePlan {
  aggressive('Aggressive', '⚔️', 'All-out attack, weakened defense'),
  defensive('Defensive', '🛡️', 'Hold the line, reduced offense'),
  gambit('Gambit', '🎲', 'High risk feint, outcome varies');

  final String displayName;
  final String emoji;
  final String description;
  const BattlePlan(this.displayName, this.emoji, this.description);

  double get attackModifier => switch (this) {
        aggressive => 1.15,
        defensive => 0.90,
        gambit => 1.0,
      };

  double get defenseModifier => switch (this) {
        aggressive => 0.85,
        defensive => 1.15,
        gambit => 1.0,
      };

  BattleTactics toTactics(Army army) => switch (this) {
        aggressive => BattleTactics(
            formation: BattleFormation.crescent,
            engagementOrder: EngagementOrder.aggressivePush,
            roleAssignments: _buildRoles(army, {
              'Cavalry': UnitRole.flankers,
              'Infantry': UnitRole.vanguard,
            }),
          ),
        defensive => BattleTactics(
            formation: BattleFormation.shieldWall,
            engagementOrder: EngagementOrder.holdGround,
            roleAssignments: _buildRoles(army, {
              'Ranged': UnitRole.reserve,
              'Cavalry': UnitRole.flankers,
              'Infantry': UnitRole.mainBody,
            }),
          ),
        gambit => BattleTactics(
            formation: BattleFormation.skirmish,
            engagementOrder: EngagementOrder.feignedRetreat,
            roleAssignments: _buildRoles(army, {}),
          ),
      };

  Map<UnitType, UnitRole> _buildRoles(
    Army army,
    Map<String, UnitRole> categoryRoles,
  ) {
    final roles = <UnitType, UnitRole>{};
    final presentTypes = army.units.map((u) => u.unitType).toSet();
    for (final type in presentTypes) {
      roles[type] = categoryRoles[type.category] ?? UnitRole.mainBody;
    }
    return roles;
  }
}
