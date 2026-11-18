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

  /// The plan that wins most often at this strength ratio, yours over theirs from
  /// GameManager.fightingPower. Measured by the matchups table in tool/balance_sim.dart.
  static BattlePlan bestFor(double powerRatio) =>
      powerRatio >= 0.9 ? aggressive : (powerRatio >= 0.7 ? defensive : gambit);

  /// The odds in words, with the best plan. Same table.
  static String oddsLabel(double powerRatio) => switch (powerRatio) {
        >= 1.3 => 'Easy win',
        >= 0.9 => 'You should win',
        >= 0.7 => 'Close fight',
        >= 0.5 => 'Long odds',
        _ => 'Hopeless',
      };

  String get bestWhen => switch (this) {
        aggressive => 'Best when you are stronger',
        defensive => 'Best when outnumbered',
        gambit => 'A long shot when nothing else works',
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
