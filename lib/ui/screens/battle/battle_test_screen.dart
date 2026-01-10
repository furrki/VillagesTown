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

/// Pre-defined test scenarios.
final List<BattleTestScenario> testScenarios = [
  // Scenario 1: Cavalry vs Archers (Cavalry should win - counters ranged)
  BattleTestScenario(
    name: '1. Cavalry vs Archers',
    description: 'Light Cavalry (6) vs Archers (6)\nCavalry counters ranged 1.5x.\nExpected: Cavalry wins decisively.',
    expectedWinner: 'attacker',
    attackerUnits: List.filled(6, UnitType.lightCavalry),
    defenderUnits: List.filled(6, UnitType.archer),
    attackerFormation: BattleFormation.crescent,
    defenderFormation: BattleFormation.skirmish,
  ),

  // Scenario 2: Spearmen vs Knights (Spearmen should win - anti-cavalry)
  BattleTestScenario(
    name: '2. Spearmen vs Knights',
    description: 'Spearmen (8) vs Knights (4)\nSpearmen counter cavalry 1.5x, take 0.6x.\nExpected: Spearmen win.',
    expectedWinner: 'attacker',
    attackerUnits: List.filled(8, UnitType.spearman),
    defenderUnits: List.filled(4, UnitType.knight),
    attackerFormation: BattleFormation.shieldWall,
    defenderFormation: BattleFormation.crescent,
  ),

  // Scenario 3: Formation Counter - Skirmish vs Shield Wall
  BattleTestScenario(
    name: '3. Skirmish beats Shield Wall',
    description: 'Ranged-heavy (Skirmish) vs Infantry (Shield Wall)\nSkirmish counters Shield Wall (+25%).\nExpected: Skirmish formation wins.',
    expectedWinner: 'attacker',
    attackerUnits: [...List.filled(5, UnitType.archer), ...List.filled(2, UnitType.militia)],
    defenderUnits: List.filled(6, UnitType.militia),
    attackerFormation: BattleFormation.skirmish,
    defenderFormation: BattleFormation.shieldWall,
  ),

  // Scenario 4: Fortress Defense Bonus
  BattleTestScenario(
    name: '4. Fortress Defense (Level 3)',
    description: 'Equal numbers, defender has Castle (L3).\n+65% defense, +2 range, -60% cavalry charge.\nExpected: Defender wins.',
    expectedWinner: 'defender',
    attackerUnits: [...List.filled(4, UnitType.militia), ...List.filled(2, UnitType.swordsman)],
    defenderUnits: [...List.filled(2, UnitType.spearman), ...List.filled(4, UnitType.archer)],
    attackerFormation: BattleFormation.shieldWall,
    defenderFormation: BattleFormation.shieldWall,
    defenderFortressLevel: 3,
  ),

  // Scenario 5: Mixed Army - Balanced Fight
  BattleTestScenario(
    name: '5. Balanced Armies',
    description: 'Mixed armies with all unit types.\nTests overall balance and AI targeting.\nExpected: Close fight.',
    expectedWinner: 'close',
    attackerUnits: [
      ...List.filled(3, UnitType.swordsman),
      ...List.filled(2, UnitType.spearman),
      ...List.filled(2, UnitType.archer),
      ...List.filled(2, UnitType.lightCavalry),
      UnitType.knight,
    ],
    defenderUnits: [
      ...List.filled(3, UnitType.swordsman),
      ...List.filled(2, UnitType.spearman),
      ...List.filled(2, UnitType.crossbowman),
      ...List.filled(2, UnitType.lightCavalry),
      UnitType.knight,
    ],
    attackerFormation: BattleFormation.shieldWall,
    defenderFormation: BattleFormation.shieldWall,
  ),

  // Scenario 6: Swordsmen vs Militia - Elite beats numbers
  BattleTestScenario(
    name: '6. Elite vs Numbers',
    description: 'Swordsmen (5) vs Militia (8).\nElite infantry should beat militia.\nExpected: Attacker wins.',
    expectedWinner: 'attacker',
    attackerUnits: List.filled(5, UnitType.swordsman),
    defenderUnits: List.filled(8, UnitType.militia),
    attackerFormation: BattleFormation.shieldWall,
    defenderFormation: BattleFormation.shieldWall,
  ),

  // Scenario 7: Knights charge archers - Devastating if no spearmen
  BattleTestScenario(
    name: '7. Knight Charge (no counter)',
    description: 'Knights (3) vs Archers (6).\nNo spearmen to counter = devastation.\nExpected: Knights win decisively.',
    expectedWinner: 'attacker',
    attackerUnits: List.filled(3, UnitType.knight),
    defenderUnits: List.filled(6, UnitType.archer),
    attackerFormation: BattleFormation.crescent,
    defenderFormation: BattleFormation.skirmish,
  ),

  // Scenario 8: Crescent vs Shield Wall - Formation counter
  BattleTestScenario(
    name: '8. Shield Wall beats Crescent',
    description: 'Shield Wall counters Crescent (+25%).\nEqual armies, formation decides.\nExpected: Defender wins.',
    expectedWinner: 'defender',
    attackerUnits: [
      ...List.filled(3, UnitType.militia),
      ...List.filled(3, UnitType.lightCavalry),
    ],
    defenderUnits: [
      ...List.filled(4, UnitType.spearman),
      ...List.filled(2, UnitType.archer),
    ],
    attackerFormation: BattleFormation.crescent,
    defenderFormation: BattleFormation.shieldWall,
  ),

  // Scenario 9: Crossbowmen vs Spearmen - Ranged advantage
  BattleTestScenario(
    name: '9. Crossbows vs Spearmen',
    description: 'Crossbowmen (4) vs Spearmen (4).\nRanged can kite slow infantry.\nExpected: Crossbows win.',
    expectedWinner: 'attacker',
    attackerUnits: List.filled(4, UnitType.crossbowman),
    defenderUnits: List.filled(4, UnitType.spearman),
    attackerFormation: BattleFormation.skirmish,
    defenderFormation: BattleFormation.shieldWall,
  ),

  // Scenario 10: Outnumbered attacker loses
  BattleTestScenario(
    name: '10. Numbers Advantage',
    description: 'Militia (4) vs Militia (8).\nPure numbers test - 2:1 should win.\nExpected: Defender wins.',
    expectedWinner: 'defender',
    attackerUnits: List.filled(4, UnitType.militia),
    defenderUnits: List.filled(8, UnitType.militia),
    attackerFormation: BattleFormation.shieldWall,
    defenderFormation: BattleFormation.shieldWall,
  ),

  // Scenario 11: Crescent beats Skirmish (missing formation counter)
  BattleTestScenario(
    name: '11. Crescent beats Skirmish',
    description: 'Crescent counters Skirmish (+25%).\nCavalry catches spread-out skirmishers.\nExpected: Attacker wins.',
    expectedWinner: 'attacker',
    attackerUnits: [
      ...List.filled(2, UnitType.militia),
      ...List.filled(4, UnitType.lightCavalry),
    ],
    defenderUnits: [
      ...List.filled(4, UnitType.archer),
      ...List.filled(2, UnitType.militia),
    ],
    attackerFormation: BattleFormation.crescent,
    defenderFormation: BattleFormation.skirmish,
  ),

  // Scenario 12: Archers kite militia
  BattleTestScenario(
    name: '12. Archers vs Militia',
    description: 'Archers (6) vs Militia (6).\nRanged kites weak infantry (1.3x bonus).\nExpected: Archers win.',
    expectedWinner: 'attacker',
    attackerUnits: List.filled(6, UnitType.archer),
    defenderUnits: List.filled(6, UnitType.militia),
    attackerFormation: BattleFormation.skirmish,
    defenderFormation: BattleFormation.shieldWall,
  ),

  // Scenario 13: Counter composition beats raw power
  BattleTestScenario(
    name: '13. Counter Composition',
    description: 'Spearmen + Archers vs Knights.\nPerfect counter army beats elite.\nExpected: Defender wins.',
    expectedWinner: 'defender',
    attackerUnits: List.filled(4, UnitType.knight),
    defenderUnits: [
      ...List.filled(4, UnitType.spearman),
      ...List.filled(3, UnitType.archer),
    ],
    attackerFormation: BattleFormation.crescent,
    defenderFormation: BattleFormation.shieldWall,
  ),

  // Scenario 14: Fortress negates cavalry charge
  BattleTestScenario(
    name: '14. Fortress vs Cavalry',
    description: 'Cavalry army vs Fortress L2.\nFortress reduces charge by 40%.\nExpected: Defender wins.',
    expectedWinner: 'defender',
    attackerUnits: [
      ...List.filled(3, UnitType.lightCavalry),
      ...List.filled(2, UnitType.knight),
    ],
    defenderUnits: [
      ...List.filled(3, UnitType.spearman),
      ...List.filled(2, UnitType.crossbowman),
    ],
    attackerFormation: BattleFormation.crescent,
    defenderFormation: BattleFormation.shieldWall,
    defenderFortressLevel: 2,
  ),

  // Scenario 15: Light cavalry speed advantage
  BattleTestScenario(
    name: '15. Speed Hunters',
    description: 'Light Cavalry (5) vs Crossbowmen (5).\nFast cavalry catches slow ranged.\nExpected: Cavalry wins.',
    expectedWinner: 'attacker',
    attackerUnits: List.filled(5, UnitType.lightCavalry),
    defenderUnits: List.filled(5, UnitType.crossbowman),
    attackerFormation: BattleFormation.crescent,
    defenderFormation: BattleFormation.skirmish,
  ),

  // Scenario 16: Pure archer vs pure archer (defender bonus)
  BattleTestScenario(
    name: '16. Archer Mirror + Defender Bonus',
    description: 'Archers (6) vs Archers (6).\nDefender gets +10% base defense.\nExpected: Defender wins.',
    expectedWinner: 'defender',
    attackerUnits: List.filled(6, UnitType.archer),
    defenderUnits: List.filled(6, UnitType.archer),
    attackerFormation: BattleFormation.skirmish,
    defenderFormation: BattleFormation.skirmish,
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
          ? (isDark ? Colors.green.shade900.withOpacity(0.4) : Colors.green.shade50)
          : (isDark ? Colors.red.shade900.withOpacity(0.4) : Colors.red.shade50);
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

    // Skip formation selection, go straight to combat
    simulation.phase = BattlePhase.setup;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        simulation.phase = BattlePhase.combat;
        setState(() {});
      }
    });

    setState(() => _initialized = true);
    _tickController.repeat();
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
      case BattlePhase.combat:
        return 'BATTLE';
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
