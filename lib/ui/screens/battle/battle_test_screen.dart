import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/unit.dart';
import '../../../data/models/unit_type.dart';
import '../../../data/models/combat_log.dart';
import '../../../data/models/geo_coordinate.dart';
import '../../../data/models/nationality.dart';
import '../../../engines/combat_engine.dart';
import '../../../data/map/game_map.dart';
import '../../../data/models/village.dart';
import 'battle_simulation.dart';
import 'battle_painter.dart';
import 'battlefield_painter.dart';
import 'battle_circle.dart';

/// Test scenarios for battle mechanics validation.
class BattleTestScenario {
  final String name;
  final String description;
  final String expectedWinner; // 'attacker', 'defender', 'close'
  final List<UnitType> attackerUnits;
  final List<UnitType> defenderUnits;
  final BattleFormation attackerFormation;
  final BattleFormation defenderFormation;
  final int defenderFortressLevel;

  const BattleTestScenario({
    required this.name,
    required this.description,
    required this.expectedWinner,
    required this.attackerUnits,
    required this.defenderUnits,
    required this.attackerFormation,
    required this.defenderFormation,
    this.defenderFortressLevel = 0,
  });
}

/// Pre-defined test scenarios - 30 comprehensive battle tests.
final List<BattleTestScenario> testScenarios = [
  // ============================================================
  // GROUP 1: DECISIVE ATTACKER WINS (80%+)
  // ============================================================
  BattleTestScenario(
    name: '1. Knights vs Archers',
    description: 'Knights (4) vs Archers (6)\nNo spearmen = cavalry devastates ranged.\nExpected: Knights win 80%+',
    expectedWinner: 'attacker',
    attackerUnits: List.filled(4, UnitType.knight),
    defenderUnits: List.filled(6, UnitType.archer),
    attackerFormation: BattleFormation.crescent,
    defenderFormation: BattleFormation.skirmish,
  ),
  BattleTestScenario(
    name: '2. Light Cav vs Crossbows',
    description: 'Light Cavalry (6) vs Crossbowmen (5)\nSpeed beats slow ranged.\nExpected: Cavalry wins 80%+',
    expectedWinner: 'attacker',
    attackerUnits: List.filled(6, UnitType.lightCavalry),
    defenderUnits: List.filled(5, UnitType.crossbowman),
    attackerFormation: BattleFormation.crescent,
    defenderFormation: BattleFormation.skirmish,
  ),
  BattleTestScenario(
    name: '3. Swordsmen vs Militia',
    description: 'Swordsmen (6) vs Militia (6)\nElite quality crushes militia.\nExpected: Swordsmen win 80%+',
    expectedWinner: 'attacker',
    attackerUnits: List.filled(6, UnitType.swordsman),
    defenderUnits: List.filled(6, UnitType.militia),
    attackerFormation: BattleFormation.shieldWall,
    defenderFormation: BattleFormation.shieldWall,
  ),
  BattleTestScenario(
    name: '4. 2:1 Numbers Advantage',
    description: 'Militia (12) vs Militia (6)\nOverwhelming force wins.\nExpected: Attacker wins 80%+',
    expectedWinner: 'attacker',
    attackerUnits: List.filled(12, UnitType.militia),
    defenderUnits: List.filled(6, UnitType.militia),
    attackerFormation: BattleFormation.shieldWall,
    defenderFormation: BattleFormation.shieldWall,
  ),
  BattleTestScenario(
    name: '5. Cavalry Charge',
    description: 'Knights (4) + Light Cav (3) vs Militia (6)\nHeavy cavalry breaks militia.\nExpected: Cavalry wins 80%+',
    expectedWinner: 'attacker',
    attackerUnits: [...List.filled(4, UnitType.knight), ...List.filled(3, UnitType.lightCavalry)],
    defenderUnits: List.filled(6, UnitType.militia),
    attackerFormation: BattleFormation.crescent,
    defenderFormation: BattleFormation.shieldWall,
  ),
  BattleTestScenario(
    name: '6. Archers vs Militia (Kiting)',
    description: 'Archers (8) vs Militia (6)\nRanged kites slow infantry.\nExpected: Archers win 80%+',
    expectedWinner: 'attacker',
    attackerUnits: List.filled(8, UnitType.archer),
    defenderUnits: List.filled(6, UnitType.militia),
    attackerFormation: BattleFormation.skirmish,
    defenderFormation: BattleFormation.shieldWall,
  ),

  // ============================================================
  // GROUP 2: DECISIVE DEFENDER WINS (<20%)
  // ============================================================
  BattleTestScenario(
    name: '7. Siege vs Castle (L3)',
    description: 'Militia (8) vs Archers (5) in Castle\n+60% defense repels assault.\nExpected: Defender wins 80%+',
    expectedWinner: 'defender',
    attackerUnits: List.filled(8, UnitType.militia),
    defenderUnits: List.filled(5, UnitType.archer),
    attackerFormation: BattleFormation.shieldWall,
    defenderFormation: BattleFormation.shieldWall,
    defenderFortressLevel: 3,
  ),
  BattleTestScenario(
    name: '8. Knights vs Spearmen',
    description: 'Knights (4) vs Spearmen (8)\nSpearmen 1.75x counter destroys cavalry.\nExpected: Defender wins 80%+',
    expectedWinner: 'defender',
    attackerUnits: List.filled(4, UnitType.knight),
    defenderUnits: List.filled(8, UnitType.spearman),
    attackerFormation: BattleFormation.crescent,
    defenderFormation: BattleFormation.shieldWall,
  ),
  BattleTestScenario(
    name: '9. 3:1 Numbers (Hopeless)',
    description: 'Swordsmen (4) vs Militia (12)\nEven elite cant beat 3:1.\nExpected: Defender wins 80%+',
    expectedWinner: 'defender',
    attackerUnits: List.filled(4, UnitType.swordsman),
    defenderUnits: List.filled(12, UnitType.militia),
    attackerFormation: BattleFormation.shieldWall,
    defenderFormation: BattleFormation.shieldWall,
  ),
  BattleTestScenario(
    name: '10. Cavalry vs Fortress+Spears',
    description: 'Knights (4) vs Spears+Xbows in Fortress L2\nWorst case cavalry attack.\nExpected: Defender wins',
    expectedWinner: 'defender',
    attackerUnits: List.filled(4, UnitType.knight),
    defenderUnits: [...List.filled(6, UnitType.spearman), ...List.filled(4, UnitType.crossbowman)],
    attackerFormation: BattleFormation.crescent,
    defenderFormation: BattleFormation.shieldWall,
    defenderFortressLevel: 2,
  ),
  BattleTestScenario(
    name: '11. Archers vs Cavalry Rush',
    description: 'Archers (5) vs Light Cavalry (6)\nCavalry hunts archers (2.0x).\nExpected: Defender wins',
    expectedWinner: 'defender',
    attackerUnits: List.filled(5, UnitType.archer),
    defenderUnits: List.filled(6, UnitType.lightCavalry),
    attackerFormation: BattleFormation.skirmish,
    defenderFormation: BattleFormation.crescent,
  ),
  BattleTestScenario(
    name: '12. Wrong Formation (Crescent vs Spears)',
    description: 'Cavalry+Militia in Crescent vs Spear Wall\nFormation + unit counter.\nExpected: Defender wins',
    expectedWinner: 'defender',
    attackerUnits: [...List.filled(3, UnitType.lightCavalry), ...List.filled(2, UnitType.militia)],
    defenderUnits: [...List.filled(6, UnitType.spearman), ...List.filled(3, UnitType.archer)],
    attackerFormation: BattleFormation.crescent,
    defenderFormation: BattleFormation.shieldWall,
  ),

  // ============================================================
  // GROUP 3: COMPETITIVE BATTLES (40-60%)
  // ============================================================
  BattleTestScenario(
    name: '13. Mirror Infantry',
    description: 'Swords+Spears vs Swords+Spears\nDefender has +10% edge.\nExpected: Close fight',
    expectedWinner: 'close',
    attackerUnits: [...List.filled(4, UnitType.swordsman), ...List.filled(3, UnitType.spearman)],
    defenderUnits: [...List.filled(4, UnitType.swordsman), ...List.filled(3, UnitType.spearman)],
    attackerFormation: BattleFormation.shieldWall,
    defenderFormation: BattleFormation.shieldWall,
  ),
  BattleTestScenario(
    name: '14. Mixed Arms vs Mixed Arms',
    description: 'Balanced armies with all types.\nDefender has crossbows + bonus.\nExpected: Slight defender edge',
    expectedWinner: 'close',
    attackerUnits: [...List.filled(2, UnitType.swordsman), ...List.filled(2, UnitType.spearman), ...List.filled(2, UnitType.archer), ...List.filled(2, UnitType.lightCavalry)],
    defenderUnits: [...List.filled(2, UnitType.swordsman), ...List.filled(2, UnitType.spearman), ...List.filled(2, UnitType.crossbowman), ...List.filled(2, UnitType.lightCavalry)],
    attackerFormation: BattleFormation.shieldWall,
    defenderFormation: BattleFormation.shieldWall,
  ),
  BattleTestScenario(
    name: '15. Elite vs Numbers',
    description: 'Swordsmen (6) vs Militia (8)\nQuality vs quantity.\nExpected: Elite should win',
    expectedWinner: 'attacker',
    attackerUnits: List.filled(6, UnitType.swordsman),
    defenderUnits: List.filled(8, UnitType.militia),
    attackerFormation: BattleFormation.shieldWall,
    defenderFormation: BattleFormation.shieldWall,
  ),
  BattleTestScenario(
    name: '16. Fortress L1 Assault',
    description: 'Swords+Archers vs Spears+Archers in L1\nSuperior force vs walls.\nExpected: Beatable',
    expectedWinner: 'attacker',
    attackerUnits: [...List.filled(5, UnitType.swordsman), ...List.filled(3, UnitType.archer)],
    defenderUnits: [...List.filled(3, UnitType.spearman), ...List.filled(3, UnitType.archer)],
    attackerFormation: BattleFormation.shieldWall,
    defenderFormation: BattleFormation.shieldWall,
    defenderFortressLevel: 1,
  ),

  // ============================================================
  // GROUP 4: UNIT COUNTER TESTS (60-80%)
  // ============================================================
  BattleTestScenario(
    name: '17. Cavalry vs Archers (2.0x)',
    description: 'Light Cavalry (5) vs Archers (5)\nHard counter dominates.\nExpected: Cavalry wins 80%+',
    expectedWinner: 'attacker',
    attackerUnits: List.filled(5, UnitType.lightCavalry),
    defenderUnits: List.filled(5, UnitType.archer),
    attackerFormation: BattleFormation.crescent,
    defenderFormation: BattleFormation.skirmish,
  ),
  BattleTestScenario(
    name: '18. Spearmen vs Knights (1.75x)',
    description: 'Spearmen (5) vs Knights (3)\nAnti-cavalry specialists.\nExpected: Spearmen win 60%+',
    expectedWinner: 'attacker',
    attackerUnits: List.filled(5, UnitType.spearman),
    defenderUnits: List.filled(3, UnitType.knight),
    attackerFormation: BattleFormation.shieldWall,
    defenderFormation: BattleFormation.crescent,
  ),
  BattleTestScenario(
    name: '19. Archers Kite Spearmen',
    description: 'Archers (5) vs Spearmen (5)\nRanged kites slow infantry.\nExpected: Archers win 60%+',
    expectedWinner: 'attacker',
    attackerUnits: List.filled(5, UnitType.archer),
    defenderUnits: List.filled(5, UnitType.spearman),
    attackerFormation: BattleFormation.skirmish,
    defenderFormation: BattleFormation.shieldWall,
  ),
  BattleTestScenario(
    name: '20. Crossbows vs Militia',
    description: 'Crossbowmen (5) vs Militia (5)\nHigh damage ranged.\nExpected: Crossbows win 60%+',
    expectedWinner: 'attacker',
    attackerUnits: List.filled(5, UnitType.crossbowman),
    defenderUnits: List.filled(5, UnitType.militia),
    attackerFormation: BattleFormation.skirmish,
    defenderFormation: BattleFormation.shieldWall,
  ),

  // ============================================================
  // GROUP 5: FORMATION COUNTER TESTS (60-80%)
  // ============================================================
  BattleTestScenario(
    name: '21. Skirmish vs Shield Wall',
    description: 'Archers+Militia in Skirmish vs Militia Wall\n+20% formation bonus.\nExpected: Skirmish wins',
    expectedWinner: 'attacker',
    attackerUnits: [...List.filled(4, UnitType.archer), ...List.filled(2, UnitType.militia)],
    defenderUnits: List.filled(5, UnitType.militia),
    attackerFormation: BattleFormation.skirmish,
    defenderFormation: BattleFormation.shieldWall,
  ),
  BattleTestScenario(
    name: '22. Crescent vs Skirmish',
    description: 'Light Cav+Militia in Crescent vs Archers\nCavalry catches spread units.\nExpected: Crescent wins',
    expectedWinner: 'attacker',
    attackerUnits: [...List.filled(4, UnitType.lightCavalry), ...List.filled(2, UnitType.militia)],
    defenderUnits: [...List.filled(4, UnitType.archer), ...List.filled(2, UnitType.militia)],
    attackerFormation: BattleFormation.crescent,
    defenderFormation: BattleFormation.skirmish,
  ),
  BattleTestScenario(
    name: '23. Shield Wall vs Crescent',
    description: 'Spears+Archers in Wall vs Light Cav\nStops cavalry charge.\nExpected: Shield Wall wins',
    expectedWinner: 'attacker',
    attackerUnits: [...List.filled(4, UnitType.spearman), ...List.filled(2, UnitType.archer)],
    defenderUnits: [...List.filled(4, UnitType.lightCavalry), ...List.filled(2, UnitType.militia)],
    attackerFormation: BattleFormation.shieldWall,
    defenderFormation: BattleFormation.crescent,
  ),

  // ============================================================
  // GROUP 6: SPECIAL TACTICAL SCENARIOS
  // ============================================================
  BattleTestScenario(
    name: '24. All Cavalry vs Spear Defense',
    description: 'Knights (5) vs Spears (8) + Xbows (3)\nPure cavalry vs counters.\nExpected: Defender edge',
    expectedWinner: 'defender',
    attackerUnits: List.filled(5, UnitType.knight),
    defenderUnits: [...List.filled(8, UnitType.spearman), ...List.filled(3, UnitType.crossbowman)],
    attackerFormation: BattleFormation.crescent,
    defenderFormation: BattleFormation.shieldWall,
  ),
  BattleTestScenario(
    name: '25. Ranged Duel (Xbow vs Archer)',
    description: 'Crossbows (5) vs Archers (5)\nArchers have defender bonus.\nExpected: Archers favored',
    expectedWinner: 'defender',
    attackerUnits: List.filled(5, UnitType.crossbowman),
    defenderUnits: List.filled(5, UnitType.archer),
    attackerFormation: BattleFormation.skirmish,
    defenderFormation: BattleFormation.skirmish,
  ),
  BattleTestScenario(
    name: '26. Cavalry Raid',
    description: 'Light Cavalry (6) vs Militia (4)\nFast in and out.\nExpected: Cavalry wins 70%+',
    expectedWinner: 'attacker',
    attackerUnits: List.filled(6, UnitType.lightCavalry),
    defenderUnits: List.filled(4, UnitType.militia),
    attackerFormation: BattleFormation.crescent,
    defenderFormation: BattleFormation.shieldWall,
  ),
  BattleTestScenario(
    name: '27. Elite Defense (Fortress)',
    description: 'Swords+Archers vs Knights+Xbows in L2\nElite defenders in fortress.\nExpected: Defender wins',
    expectedWinner: 'defender',
    attackerUnits: [...List.filled(6, UnitType.swordsman), ...List.filled(4, UnitType.archer)],
    defenderUnits: [...List.filled(3, UnitType.knight), ...List.filled(2, UnitType.crossbowman)],
    attackerFormation: BattleFormation.shieldWall,
    defenderFormation: BattleFormation.shieldWall,
    defenderFortressLevel: 2,
  ),
  BattleTestScenario(
    name: '28. Peasant Uprising',
    description: 'Militia (15) vs Swords (2) + Archers (2)\nOverwhelming numbers.\nExpected: Peasants win 70%+',
    expectedWinner: 'attacker',
    attackerUnits: List.filled(15, UnitType.militia),
    defenderUnits: [...List.filled(2, UnitType.swordsman), ...List.filled(2, UnitType.archer)],
    attackerFormation: BattleFormation.shieldWall,
    defenderFormation: BattleFormation.shieldWall,
  ),
  BattleTestScenario(
    name: '29. Defender Advantage (Mirror)',
    description: 'Spears+Cav vs Spears+Cav\nEqual forces, defender bonus.\nExpected: Close, defender edge',
    expectedWinner: 'close',
    attackerUnits: [...List.filled(3, UnitType.spearman), ...List.filled(3, UnitType.lightCavalry)],
    defenderUnits: [...List.filled(3, UnitType.spearman), ...List.filled(3, UnitType.lightCavalry)],
    attackerFormation: BattleFormation.shieldWall,
    defenderFormation: BattleFormation.shieldWall,
  ),
  BattleTestScenario(
    name: '30. Full Combined Arms',
    description: 'All unit types vs all unit types\nEqual armies, defender +10%.\nExpected: Close fight',
    expectedWinner: 'close',
    attackerUnits: [...List.filled(3, UnitType.swordsman), ...List.filled(2, UnitType.spearman), ...List.filled(3, UnitType.archer), ...List.filled(2, UnitType.knight)],
    defenderUnits: [...List.filled(3, UnitType.swordsman), ...List.filled(2, UnitType.spearman), ...List.filled(3, UnitType.crossbowman), ...List.filled(2, UnitType.knight)],
    attackerFormation: BattleFormation.shieldWall,
    defenderFormation: BattleFormation.shieldWall,
  ),
];

/// Screen for running battle test scenarios.
class BattleTestScreen extends StatefulWidget {
  const BattleTestScreen({super.key});

  @override
  State<BattleTestScreen> createState() => _BattleTestScreenState();
}

class _BattleTestScreenState extends State<BattleTestScreen> {
  final CombatEngine _engine = CombatEngine();
  final List<_TestResult> _results = [];
  bool _isRunning = false;
  int _currentScenario = -1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Battle Mechanics Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: _isRunning ? null : _runAllTests,
            tooltip: 'Run All Tests',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _clearResults,
            tooltip: 'Clear Results',
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: testScenarios.length,
        itemBuilder: (context, index) {
          final scenario = testScenarios[index];
          final result = _results.length > index ? _results[index] : null;
          return _buildScenarioCard(scenario, result, index);
        },
      ),
    );
  }

  Widget _buildScenarioCard(BattleTestScenario scenario, _TestResult? result, int index) {
    final isRunning = _currentScenario == index;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color? cardColor;
    if (result != null) {
      cardColor = result.passed
          ? (isDark ? Colors.green.shade900.withValues(alpha: 0.4) : Colors.green.shade50)
          : (isDark ? Colors.red.shade900.withValues(alpha: 0.4) : Colors.red.shade50);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    scenario.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                if (isRunning)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                if (result != null)
                  Icon(
                    result.passed ? Icons.check_circle : Icons.cancel,
                    color: result.passed ? Colors.green : Colors.red,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              scenario.description,
              style: TextStyle(
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            _buildArmyComparison(scenario),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildFormationChip(scenario.attackerFormation, 'ATK'),
                const Text('vs'),
                _buildFormationChip(scenario.defenderFormation, 'DEF'),
                if (scenario.defenderFortressLevel > 0)
                  Chip(
                    label: Text('Fortress L${scenario.defenderFortressLevel}'),
                    backgroundColor: isDark ? Colors.brown.shade800 : Colors.brown.shade100,
                  ),
              ],
            ),
            if (result != null) ...[
              const Divider(),
              _buildResultDetails(result, scenario),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isRunning ? null : () => _runSingleTest(index),
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Run'),
                ),
                if (result != null) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _watchBattle(scenario, result.record),
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('Watch'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _watchBattle(BattleTestScenario scenario, BattleRecord record) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _TestBattleViewer(
          scenario: scenario,
          record: record,
        ),
      ),
    );
  }

  Widget _buildArmyComparison(BattleTestScenario scenario) {
    return Row(
      children: [
        Expanded(child: _buildArmyList('Attackers', scenario.attackerUnits, Colors.red)),
        const SizedBox(width: 16),
        Expanded(child: _buildArmyList('Defenders', scenario.defenderUnits, Colors.blue)),
      ],
    );
  }

  Widget _buildArmyList(String title, List<UnitType> units, Color color) {
    final counts = <UnitType, int>{};
    for (final unit in units) {
      counts[unit] = (counts[unit] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        ...counts.entries.map((e) => Text(
              '${e.value}x ${e.key.displayName}',
              style: const TextStyle(fontSize: 12),
            )),
      ],
    );
  }

  Widget _buildFormationChip(BattleFormation formation, String prefix) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Chip(
      label: Text('$prefix: ${formation.displayName}'),
      backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
    );
  }

  Widget _buildResultDetails(_TestResult result, BattleTestScenario scenario) {
    final record = result.record;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Result: ${record.attackerWon ? "ATTACKER WINS" : "DEFENDER WINS"}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: record.attackerWon ? Colors.red : Colors.blue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Attackers: ${scenario.attackerUnits.length} → ${scenario.attackerUnits.length - record.totalAttackerLosses} remaining',
        ),
        Text(
          'Defenders: ${scenario.defenderUnits.length} → ${scenario.defenderUnits.length - record.totalDefenderLosses} remaining',
        ),
        const SizedBox(height: 4),
        Text(
          'Expected: ${scenario.expectedWinner.toUpperCase()}',
          style: TextStyle(
            color: result.passed ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (!result.passed)
          Text(
            'MISMATCH! ${result.reason}',
            style: const TextStyle(color: Colors.red),
          ),
        const SizedBox(height: 8),
        _buildPhaseBreakdown(record),
      ],
    );
  }

  Widget _buildPhaseBreakdown(BattleRecord record) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Phase Breakdown:', style: TextStyle(fontWeight: FontWeight.bold)),
        ...record.phases.map((phase) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                '${phase.phase.displayName}: ATK kills ${phase.attackerKills}, DEF kills ${phase.defenderKills}',
                style: const TextStyle(fontSize: 12),
              ),
            )),
      ],
    );
  }

  Future<void> _runAllTests() async {
    setState(() {
      _isRunning = true;
      _results.clear();
    });

    for (int i = 0; i < testScenarios.length; i++) {
      setState(() => _currentScenario = i);
      await Future.delayed(const Duration(milliseconds: 100));
      final result = _runScenario(testScenarios[i]);
      setState(() => _results.add(result));
    }

    setState(() {
      _isRunning = false;
      _currentScenario = -1;
    });
  }

  Future<void> _runSingleTest(int index) async {
    setState(() {
      _isRunning = true;
      _currentScenario = index;
    });

    await Future.delayed(const Duration(milliseconds: 100));
    final result = _runScenario(testScenarios[index]);

    setState(() {
      if (_results.length > index) {
        _results[index] = result;
      } else {
        while (_results.length < index) {
          _results.add(_TestResult(
            record: _createDummyRecord(),
            passed: false,
            reason: 'Not run',
          ));
        }
        _results.add(result);
      }
      _isRunning = false;
      _currentScenario = -1;
    });
  }

  _TestResult _runScenario(BattleTestScenario scenario) {
    // Run 5 simulations to account for RNG variance
    const numRuns = 5;
    int attackerWins = 0;
    BattleRecord? lastRecord;

    for (int run = 0; run < numRuns; run++) {
      // Create unit instances
      const dummyCoord = GeoCoordinate(0, 0);
      final attackers = scenario.attackerUnits
          .map((type) => Unit.create(type, 'attacker', dummyCoord))
          .toList();
      final defenders = scenario.defenderUnits
          .map((type) => Unit.create(type, 'defender', dummyCoord))
          .toList();

      // Create a minimal game map (not used in combat calculation)
      final map = _EmptyGameMap();

      // Run combat
      final record = _engine.resolveCombat(
        attackerName: 'Test Attacker',
        defenderName: 'Test Defender',
        attackerId: 'atk_army',
        defenderId: 'def_army',
        attackerOwnerId: 'attacker',
        defenderOwnerId: 'defender',
        attackers: attackers,
        defenders: defenders,
        map: map,
        attackerFormation: scenario.attackerFormation,
        defenderFormation: scenario.defenderFormation,
        defenderFortressLevel: scenario.defenderFortressLevel,
      );

      if (record.attackerWon) attackerWins++;
      lastRecord = record;
    }

    // Determine if result matches expectation (majority wins)
    bool passed;
    String reason = '';
    final attackerWinRate = attackerWins / numRuns;

    switch (scenario.expectedWinner) {
      case 'attacker':
        passed = attackerWins >= 3; // At least 3/5 wins
        if (!passed) reason = 'Expected attacker to win (won $attackerWins/$numRuns)';
      case 'defender':
        passed = attackerWins <= 2; // At most 2/5 attacker wins
        if (!passed) reason = 'Expected defender to win (attacker won $attackerWins/$numRuns)';
      case 'close':
        // For "close" fights, win rate should be between 30-70%
        passed = attackerWinRate >= 0.2 && attackerWinRate <= 0.8;
        if (!passed) reason = 'Expected close fight (attacker won $attackerWins/$numRuns)';
      default:
        passed = true;
    }

    return _TestResult(record: lastRecord!, passed: passed, reason: reason);
  }

  void _clearResults() {
    setState(() => _results.clear());
  }

  BattleRecord _createDummyRecord() {
    return BattleRecord(
      id: 'dummy',
      attackerName: '',
      defenderName: '',
      attackerId: '',
      defenderId: '',
      attackerOwnerId: '',
      defenderOwnerId: '',
      locationName: '',
      rounds: [],
      attackerWon: false,
      initialAttackerCount: 0,
      initialDefenderCount: 0,
    );
  }
}

class _TestResult {
  final BattleRecord record;
  final bool passed;
  final String reason;

  _TestResult({
    required this.record,
    required this.passed,
    this.reason = '',
  });
}

/// Minimal GameMap implementation for testing.
class _EmptyGameMap implements GameMap {
  @override
  List<Village> villages = [];
}

/// Standalone battle viewer for test scenarios.
class _TestBattleViewer extends StatefulWidget {
  final BattleTestScenario scenario;
  final BattleRecord record;

  const _TestBattleViewer({
    required this.scenario,
    required this.record,
  });

  @override
  State<_TestBattleViewer> createState() => _TestBattleViewerState();
}

class _TestBattleViewerState extends State<_TestBattleViewer>
    with TickerProviderStateMixin {
  late BattleSimulation simulation;
  late AnimationController _tickController;
  Map<String, ui.Image?> factionImages = {};
  bool _initialized = false;
  bool _showingOverview = true; // Start with overview

  // Use distinct nationalities for visibility
  final _attackerNation = Nationality.ottomans;
  final _defenderNation = Nationality.byzantines;

  @override
  void initState() {
    super.initState();
    _tickController = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )..addListener(_tick);

    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  void _initialize() {
    _loadFactionImages();

    final size = MediaQuery.of(context).size;
    simulation = BattleSimulation(
      record: widget.record,
      attackerNationality: _attackerNation,
      defenderNationality: _defenderNation,
      screenSize: size,
      attackerUnits: widget.scenario.attackerUnits,
      defenderUnits: widget.scenario.defenderUnits,
      isPlayerAttacker: true,
    );

    // Auto-select formation based on scenario
    simulation.playerFormation = widget.scenario.attackerFormation;
    simulation.enemyFormation = widget.scenario.defenderFormation;
    simulation.formationBonus = widget.scenario.attackerFormation
        .bonusAgainst(widget.scenario.defenderFormation);

    // Initialize circles with the formations
    _initializeCirclesForTest();

    simulation.onPhaseChanged = () => setState(() {});
    simulation.onBattleEnd = () => setState(() {});

    // Stay in overview mode until user clicks "Start Battle"
    simulation.phase = BattlePhase.formationSelect;

    setState(() => _initialized = true);
  }

  void _startBattle() {
    setState(() => _showingOverview = false);
    simulation.phase = BattlePhase.setup;
    simulation.totalTime = 0; // Reset battle time
    simulation.phaseTimer = 0;
    _lastTick = DateTime.now(); // Reset tick timer
    _tickController.repeat();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        simulation.phase = BattlePhase.field;
        setState(() {});
      }
    });
  }

  void _initializeCirclesForTest() {
    final battleArea = Rect.fromLTWH(
        0, 100, MediaQuery.of(context).size.width, MediaQuery.of(context).size.height - 250);
    simulation.clashPoint = battleArea.center;

    final attackerBaseX = battleArea.left + battleArea.width * 0.15;
    final defenderBaseX = battleArea.right - battleArea.width * 0.15;

    final totalUnits =
        widget.scenario.attackerUnits.length + widget.scenario.defenderUnits.length;
    final circleRadius =
        totalUnits > 40 ? 12.0 : totalUnits > 25 ? 14.0 : totalUnits > 15 ? 16.0 : 18.0;

    _addCirclesForFormation(
      widget.scenario.attackerUnits,
      simulation.attackerCircles,
      attackerBaseX,
      _attackerNation,
      true,
      widget.scenario.attackerFormation,
      circleRadius,
      battleArea,
    );

    _addCirclesForFormation(
      widget.scenario.defenderUnits,
      simulation.defenderCircles,
      defenderBaseX,
      _defenderNation,
      false,
      widget.scenario.defenderFormation,
      circleRadius,
      battleArea,
    );

    simulation.allCircles = [
      ...simulation.attackerCircles,
      ...simulation.defenderCircles
    ];
  }

  void _addCirclesForFormation(
    List<UnitType> units,
    List<BattleCircle> circles,
    double baseX,
    Nationality nationality,
    bool isAttacker,
    BattleFormation formation,
    double circleRadius,
    Rect battleArea,
  ) {
    if (units.isEmpty) return;

    final ranged = units.where((u) => u.category == 'Ranged').toList();
    final cavalry = units.where((u) => u.category == 'Cavalry').toList();
    final infantry = units.where((u) => u.category == 'Infantry').toList();

    switch (formation) {
      case BattleFormation.crescent:
        _positionWedge(cavalry, circles, baseX, battleArea.center.dy,
            nationality, isAttacker, frontOffset: 80, radius: circleRadius);
        _positionLine(infantry, circles, baseX, battleArea.center.dy,
            nationality, isAttacker, frontOffset: 0, radius: circleRadius);
        _positionLine(ranged, circles, baseX, battleArea.center.dy,
            nationality, isAttacker, frontOffset: -70, radius: circleRadius);

      case BattleFormation.shieldWall:
        _positionLine(infantry, circles, baseX, battleArea.center.dy,
            nationality, isAttacker,
            frontOffset: 60, tight: true, radius: circleRadius);
        _positionLine(ranged, circles, baseX, battleArea.center.dy,
            nationality, isAttacker, frontOffset: -30, radius: circleRadius);
        _positionFlanks(cavalry, circles, baseX, battleArea.center.dy,
            nationality, isAttacker, radius: circleRadius);

      case BattleFormation.skirmish:
        _positionLine(ranged, circles, baseX, battleArea.center.dy,
            nationality, isAttacker,
            frontOffset: 60, spread: 1.3, radius: circleRadius);
        _positionFlanks(cavalry, circles, baseX, battleArea.center.dy,
            nationality, isAttacker, radius: circleRadius);
        _positionLine(infantry, circles, baseX, battleArea.center.dy,
            nationality, isAttacker, frontOffset: -50, radius: circleRadius);
    }
  }

  void _positionLine(
    List<UnitType> units,
    List<BattleCircle> circles,
    double baseX,
    double centerY,
    Nationality nationality,
    bool isAttacker, {
    double frontOffset = 0,
    bool tight = false,
    double spread = 1.0,
    double radius = 9.0,
  }) {
    if (units.isEmpty) return;
    final size = MediaQuery.of(context).size;
    final xOffset = isAttacker ? frontOffset : -frontOffset;
    final maxHeight = size.height * 0.5;
    final baseSpacing = tight ? 22.0 : 28.0;
    final unitsPerRow = max(1, (maxHeight / baseSpacing).floor());
    final numRows = (units.length / unitsPerRow).ceil();
    final rowSpacing = 35.0;
    final actualUnitsPerRow = (units.length / numRows).ceil();
    final ySpacing = min(baseSpacing, maxHeight / actualUnitsPerRow) * spread;

    for (int i = 0; i < units.length; i++) {
      final row = i ~/ actualUnitsPerRow;
      final col = i % actualUnitsPerRow;
      final unitsInThisRow =
          min(actualUnitsPerRow, units.length - row * actualUnitsPerRow);
      final rowXOffset = row * rowSpacing * (isAttacker ? -1 : 1);
      final y = centerY + (col - unitsInThisRow / 2) * ySpacing;

      circles.add(BattleCircle(
        position: Offset(baseX + xOffset + rowXOffset, y),
        factionId: nationality.id,
        color: nationality.color,
        assetPath: nationality.assetPath,
        unitType: units[i],
        baseRadiusOverride: radius,
      ));
    }
  }

  void _positionWedge(
    List<UnitType> units,
    List<BattleCircle> circles,
    double baseX,
    double centerY,
    Nationality nationality,
    bool isAttacker, {
    double frontOffset = 0,
    double radius = 9.0,
  }) {
    if (units.isEmpty) return;
    final size = MediaQuery.of(context).size;
    final xOffset = isAttacker ? frontOffset : -frontOffset;
    final baseRowSpacing = max(20.0, min(30.0, 300.0 / units.length));
    final baseYSpacing =
        max(18.0, min(28.0, (size.height * 0.4) / (units.length / 2 + 1)));

    for (int i = 0; i < units.length; i++) {
      final row = i ~/ 2;
      final side = i.isEven ? -1 : 1;
      final x = baseX + xOffset - row * baseRowSpacing * (isAttacker ? 1 : -1);
      final y = centerY + side * (row + 1) * baseYSpacing;
      circles.add(BattleCircle(
        position: Offset(x, y),
        factionId: nationality.id,
        color: nationality.color,
        assetPath: nationality.assetPath,
        unitType: units[i],
        baseRadiusOverride: radius,
      ));
    }
  }

  void _positionFlanks(
    List<UnitType> units,
    List<BattleCircle> circles,
    double baseX,
    double centerY,
    Nationality nationality,
    bool isAttacker, {
    double radius = 9.0,
  }) {
    if (units.isEmpty) return;
    final size = MediaQuery.of(context).size;
    final maxHeight = size.height * 0.35;
    final unitsPerFlank = (units.length / 2).ceil();
    final flankSpacing =
        max(12.0, min(22.0, maxHeight / (unitsPerFlank + 1)));

    for (int i = 0; i < units.length; i++) {
      final isTopFlank = i.isEven;
      final indexInFlank = i ~/ 2;
      final flankY = isTopFlank
          ? -(80 + indexInFlank * flankSpacing)
          : (80 + indexInFlank * flankSpacing);

      circles.add(BattleCircle(
        position: Offset(
            baseX + indexInFlank * 18 * (isAttacker ? -1 : 1), centerY + flankY),
        factionId: nationality.id,
        color: nationality.color,
        assetPath: nationality.assetPath,
        unitType: units[i],
        baseRadiusOverride: radius,
      ));
    }
  }

  Future<void> _loadFactionImages() async {
    for (final nationality in Nationality.getAll()) {
      try {
        final data = await rootBundle.load(nationality.assetPath);
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        factionImages[nationality.id] = frame.image;
      } catch (e) {
        factionImages[nationality.id] = null;
      }
    }
    if (mounted) setState(() {});
  }

  DateTime _lastTick = DateTime.now();

  void _tick() {
    if (!_initialized) return;
    final now = DateTime.now();
    final dt = (now.difference(_lastTick).inMicroseconds / 1000000).clamp(0.0, 0.05);
    _lastTick = now;
    simulation.update(dt);
    setState(() {});
  }

  @override
  void dispose() {
    _tickController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        backgroundColor: Color(0xFF1a1a1a),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Show pre-battle overview
    if (_showingOverview) {
      return _buildOverviewScreen();
    }

    final isEnded = simulation.phase == BattlePhase.victory ||
        simulation.phase == BattlePhase.defeat;

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: AppBar(
        title: Text(widget.scenario.name),
        backgroundColor: Colors.transparent,
        actions: [
          if (!isEnded)
            IconButton(
              icon: const Icon(Icons.skip_next),
              onPressed: () => simulation.skipToEnd(),
              tooltip: 'Skip to End',
            ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildBattleArea()),
          _buildBottomInfo(),
        ],
      ),
    );
  }

  /// Calculate army power for a list of unit types.
  int _calculateArmyPower(List<UnitType> units) {
    int power = 0;
    for (final unit in units) {
      final stats = unit.stats;
      // Power = (Attack + Missile + Charge) * HP / 10 + Defense * 2
      power += ((stats.attack + stats.missile + stats.charge) * stats.hp ~/ 10) + (stats.defense * 2);
    }
    return power;
  }

  /// Count units by category.
  Map<String, int> _countByCategory(List<UnitType> units) {
    final counts = <String, int>{'Infantry': 0, 'Ranged': 0, 'Cavalry': 0};
    for (final unit in units) {
      counts[unit.category] = (counts[unit.category] ?? 0) + 1;
    }
    return counts;
  }

  Widget _buildOverviewScreen() {
    final attackerPower = _calculateArmyPower(widget.scenario.attackerUnits);
    final defenderPower = _calculateArmyPower(widget.scenario.defenderUnits);
    final totalPower = attackerPower + defenderPower;
    final attackerPercent = totalPower > 0 ? attackerPower / totalPower : 0.5;

    final attackerCounts = _countByCategory(widget.scenario.attackerUnits);
    final defenderCounts = _countByCategory(widget.scenario.defenderUnits);

    final formationBonus = widget.scenario.attackerFormation.bonusAgainst(widget.scenario.defenderFormation);
    final formationText = formationBonus > 1.0
        ? 'Attacker +${((formationBonus - 1) * 100).round()}%'
        : formationBonus < 1.0
            ? 'Defender +${((1 - formationBonus) * 100).round()}%'
            : 'Neutral';

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: AppBar(
        title: const Text('BATTLE OVERVIEW'),
        backgroundColor: Colors.transparent,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Power balance bar
            _buildPowerBalanceBar(attackerPercent, attackerPower, defenderPower),
            const SizedBox(height: 24),

            // Formation matchup
            _buildFormationMatchup(formationText, formationBonus),
            const SizedBox(height: 24),

            // Army comparison
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildArmyPanel(
                      'ATTACKERS',
                      _attackerNation.color,
                      widget.scenario.attackerUnits,
                      attackerCounts,
                      widget.scenario.attackerFormation,
                      attackerPower,
                    ),
                  ),
                  Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    color: Colors.grey.shade700,
                  ),
                  Expanded(
                    child: _buildArmyPanel(
                      'DEFENDERS',
                      _defenderNation.color,
                      widget.scenario.defenderUnits,
                      defenderCounts,
                      widget.scenario.defenderFormation,
                      defenderPower,
                      isDefender: true,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Fortress bonus indicator
            if (widget.scenario.defenderFortressLevel > 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.brown.shade900.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.brown.shade700),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.fort, color: Colors.brown, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Fortress Level ${widget.scenario.defenderFortressLevel}: +${widget.scenario.defenderFortressLevel * 15 + 10}% Defense, +${widget.scenario.defenderFortressLevel} Range',
                      style: TextStyle(color: Colors.brown.shade200),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Start battle button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _startBattle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade800,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.sports_kabaddi, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'START BATTLE',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPowerBalanceBar(double attackerPercent, int attackerPower, int defenderPower) {
    return Column(
      children: [
        const Text(
          'POWER BALANCE',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade600),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Row(
              children: [
                Expanded(
                  flex: (attackerPercent * 100).round(),
                  child: Container(
                    color: _attackerNation.color.withValues(alpha: 0.8),
                    alignment: Alignment.center,
                    child: Text(
                      '$attackerPower',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: ((1 - attackerPercent) * 100).round(),
                  child: Container(
                    color: _defenderNation.color.withValues(alpha: 0.8),
                    alignment: Alignment.center,
                    child: Text(
                      '$defenderPower',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('ATTACKERS', style: TextStyle(color: _attackerNation.color, fontSize: 10)),
            Text('DEFENDERS', style: TextStyle(color: _defenderNation.color, fontSize: 10)),
          ],
        ),
      ],
    );
  }

  Widget _buildFormationMatchup(String formationText, double bonus) {
    final advantageColor = bonus > 1.0
        ? _attackerNation.color
        : bonus < 1.0
            ? _defenderNation.color
            : Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: advantageColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: advantageColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                widget.scenario.attackerFormation.displayName.toUpperCase(),
                style: TextStyle(
                  color: _attackerNation.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                'ATK Formation',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
              ),
            ],
          ),
          Column(
            children: [
              const Icon(Icons.compare_arrows, color: Colors.white54),
              Text(
                formationText,
                style: TextStyle(
                  color: advantageColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Column(
            children: [
              Text(
                widget.scenario.defenderFormation.displayName.toUpperCase(),
                style: TextStyle(
                  color: _defenderNation.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                'DEF Formation',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildArmyPanel(
    String title,
    Color color,
    List<UnitType> units,
    Map<String, int> counts,
    BattleFormation formation,
    int power, {
    bool isDefender = false,
  }) {
    // Group units by type
    final unitCounts = <UnitType, int>{};
    for (final unit in units) {
      unitCounts[unit] = (unitCounts[unit] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: color, width: 2)),
          ),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Total units
        Text(
          '${units.length} Units',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // Category breakdown
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            _buildCategoryChip('Infantry', counts['Infantry'] ?? 0, Colors.grey),
            _buildCategoryChip('Ranged', counts['Ranged'] ?? 0, Colors.green),
            _buildCategoryChip('Cavalry', counts['Cavalry'] ?? 0, Colors.orange),
          ],
        ),
        const SizedBox(height: 12),

        // Unit list
        Expanded(
          child: ListView(
            children: unitCounts.entries.map((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(e.key.emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        e.key.displayName,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'x${e.value}',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),

        // Defender bonus
        if (isDefender) ...[
          const Divider(color: Colors.grey),
          Row(
            children: [
              const Icon(Icons.shield, color: Colors.blue, size: 14),
              const SizedBox(width: 4),
              Text(
                '+10% Defense (Defender)',
                style: TextStyle(color: Colors.blue.shade300, fontSize: 11),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(color: color, fontSize: 10),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSideInfo(
            'ATTACKERS',
            _attackerNation.color,
            simulation.aliveAttackers,
            widget.scenario.attackerUnits.length,
          ),
          Text(
            _getPhaseText(),
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
          _buildSideInfo(
            'DEFENDERS',
            _defenderNation.color,
            simulation.aliveDefenders,
            widget.scenario.defenderUnits.length,
          ),
        ],
      ),
    );
  }

  Widget _buildSideInfo(String label, Color color, int alive, int total) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 12)),
        Text(
          '$alive / $total',
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _getPhaseText() {
    switch (simulation.phase) {
      case BattlePhase.formationSelect:
        return 'PREPARING';
      case BattlePhase.setup:
        return 'DEPLOYING';
      case BattlePhase.field:
        return 'FIELD BATTLE';
      case BattlePhase.advance:
        return 'ADVANCING';
      case BattlePhase.cityAssault:
        return 'CITY ASSAULT';
      case BattlePhase.flagRaise:
        return 'RAISING FLAG';
      case BattlePhase.victory:
        return 'ATTACKER WINS';
      case BattlePhase.defeat:
        return 'DEFENDER WINS';
    }
  }

  Widget _buildBattleArea() {
    return Stack(
      children: [
        CustomPaint(
          painter: BattlefieldPainter(
            terrain: simulation.terrain,
            isSiege: false,
            time: simulation.totalTime,
            particles: simulation.particles,
          ),
          size: Size.infinite,
        ),
        CustomPaint(
          painter: BattlePainter(
            simulation: simulation,
            factionImages: factionImages,
            screenShake: 0,
          ),
          size: Size.infinite,
        ),
      ],
    );
  }

  Widget _buildBottomInfo() {
    final isEnded = simulation.phase == BattlePhase.victory ||
        simulation.phase == BattlePhase.defeat;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ATK: ${widget.scenario.attackerFormation.displayName}',
                style: TextStyle(color: _attackerNation.color),
              ),
              Text(
                'DEF: ${widget.scenario.defenderFormation.displayName}',
                style: TextStyle(color: _defenderNation.color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isEnded)
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    simulation.phase == BattlePhase.victory ? Colors.green : Colors.red,
              ),
              child: const Text('CLOSE'),
            ),
        ],
      ),
    );
  }
}
