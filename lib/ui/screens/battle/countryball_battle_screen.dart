import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/battle_tactics.dart';
import '../../../data/models/battle_terrain.dart';
import '../../../data/models/combat_log.dart';
import '../../../data/models/nationality.dart';
import '../../../data/models/unit_type.dart';
import '../../../engines/game_manager.dart';
import 'battle_painter.dart';
import 'battle_simulation.dart';
import 'battlefield_painter.dart';

class CountryballBattleScreen extends StatefulWidget {
  final BattleRecord record;
  final VoidCallback onDismiss;

  const CountryballBattleScreen({
    super.key,
    required this.record,
    required this.onDismiss,
  });

  @override
  State<CountryballBattleScreen> createState() => _CountryballBattleScreenState();
}

class _CountryballBattleScreenState extends State<CountryballBattleScreen>
    with TickerProviderStateMixin {
  late BattleSimulation simulation;
  late AnimationController _tickController;
  late AnimationController _shakeController;
  late AnimationController _zoomController;
  late Animation<double> _zoomAnimation;
  late Animation<double> _fadeAnimation;

  Map<String, ui.Image?> factionImages = {};
  bool _initialized = false;
  bool _retreated = false;

  Nationality? _attackerNationality;
  Nationality? _defenderNationality;
  bool _isPlayerAttacker = true;

  @override
  void initState() {
    super.initState();

    _tickController = AnimationController(
      vsync: this,
      duration: const Duration(days: 1), // Continuous
    )..addListener(_tick);

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _zoomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _zoomAnimation = Tween<double>(begin: 5.0, end: 1.0).animate(
      CurvedAnimation(parent: _zoomController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _zoomController, curve: const Interval(0.3, 1.0)),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  void _initialize() {
    final game = GameManager.shared;

    // Use stored owner IDs from battle creation time (not current ownership!)
    _isPlayerAttacker = widget.record.attackerOwnerId == 'player';
    _attackerNationality = game.getNationality(widget.record.attackerOwnerId) ?? Nationality.ottomans;

    // For neutral defenders, use the village's original nationality
    if (widget.record.defenderOwnerId == 'neutral') {
      final village = game.getVillageById(widget.record.defenderId);
      _defenderNationality = village?.nationality ?? Nationality.byzantines;
    } else {
      _defenderNationality = game.getNationality(widget.record.defenderOwnerId) ?? Nationality.byzantines;
    }

    // Load faction images
    _loadFactionImages();

    // Build unit lists using RECORD counts (not current army state, which has casualties applied).
    // initialDefenderCount already includes the garrison; split it into the mobile
    // field army and the troops behind the walls.
    final attackerCount = widget.record.initialAttackerCount;
    final garrisonCount = widget.record.initialGarrisonCount;
    final fieldDefenderCount = max(0, widget.record.initialDefenderCount - garrisonCount);

    // Get unit type samples for visual variety (look up armies if they still exist)
    List<UnitType> attackerSampleTypes = [];
    List<UnitType> defenderSampleTypes = [];

    final attackerArmy = game.getArmyById(widget.record.attackerId);
    final defenderArmy = game.getArmyById(widget.record.defenderId);

    if (attackerArmy != null) {
      for (final u in attackerArmy.units) {
        attackerSampleTypes.add(u.unitType);
      }
    }
    if (defenderArmy != null) {
      for (final u in defenderArmy.units) {
        defenderSampleTypes.add(u.unitType);
      }
    }

    // Default to militia if no samples
    if (attackerSampleTypes.isEmpty) attackerSampleTypes = [UnitType.militia];
    if (defenderSampleTypes.isEmpty) defenderSampleTypes = [UnitType.militia];

    // Create full unit lists using record counts, cycling through sample types
    _attackerUnits = List.generate(
      attackerCount,
      (i) => attackerSampleTypes[i % attackerSampleTypes.length],
    );
    _fieldDefenderUnits = List.generate(
      fieldDefenderCount,
      (i) => defenderSampleTypes[i % defenderSampleTypes.length],
    );
    // Garrison troops are city militia behind the walls.
    _garrisonUnits = List.generate(garrisonCount, (_) => UnitType.militia);
    _defenderUnits = [..._fieldDefenderUnits, ..._garrisonUnits]; // for overview display

    // Create simulation
    final size = MediaQuery.of(context).size;
    simulation = BattleSimulation(
      record: widget.record,
      attackerNationality: _attackerNationality!,
      defenderNationality: _defenderNationality!,
      screenSize: size,
      isSiege: widget.record.hasCityAssault,
      attackerUnits: _attackerUnits,
      defenderUnits: _fieldDefenderUnits,
      garrisonUnits: _garrisonUnits,
      isPlayerAttacker: _isPlayerAttacker,
    );

    simulation.onPhaseChanged = () {
      if (simulation.isFighting) {
        _triggerShake();
      }
      setState(() {});
    };

    simulation.onBattleEnd = () {
      setState(() {});
    };

    setState(() => _initialized = true);
    _tickController.repeat();
    _zoomController.forward();
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

  void _triggerShake() {
    _shakeController.forward(from: 0);
    HapticFeedback.mediumImpact();
  }

  void _retreat() {
    _retreated = true;
    _endBattle();
  }

  void _endBattle() {
    // A battle watched to its conclusion applies its full result (all casualties +
    // conquest). Only a retreat stops short, banking just what played out.
    final roundsPlayed = _retreated ? simulation.currentRound : widget.record.rounds.length;
    GameManager.shared.finalizeBattle(widget.record, roundsPlayed, _retreated);
    widget.onDismiss();
  }

  @override
  void dispose() {
    _tickController.dispose();
    _shakeController.dispose();
    _zoomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        backgroundColor: Color(0xFF0a0a0a),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Formation selection screen
    if (simulation.phase == BattlePhase.formationSelect) {
      return Scaffold(
        backgroundColor: const Color(0xFF0a0a0a),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildFormationSelection()),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBattleArea()),
            _buildDiceArea(),
            _buildControls(),
          ],
        ),
      ),
    );
  }

  // Store unit lists for overview display
  List<UnitType> _attackerUnits = [];
  List<UnitType> _defenderUnits = [];
  List<UnitType> _fieldDefenderUnits = [];
  List<UnitType> _garrisonUnits = [];
  BattleFormation? _selectedFormation;
  BattleTerrain _selectedTerrain = BattleTerrain.openField;
  EngagementOrder _selectedEngagement = EngagementOrder.aggressivePush;

  Widget _buildFormationSelection() {
    // Count units by category
    final attackerCounts = _countByCategory(_attackerUnits);
    final defenderCounts = _countByCategory(_defenderUnits);

    // Calculate power balance
    final attackerPower = _calculateArmyPower(_attackerUnits);
    final defenderPower = _calculateArmyPower(_defenderUnits);
    final totalPower = attackerPower + defenderPower;
    final attackerPercent = totalPower > 0 ? attackerPower / totalPower : 0.5;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Battle Location
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on, color: Colors.amber.shade400, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Battle at ${widget.record.locationName}',
                  style: TextStyle(
                    color: Colors.amber.shade200,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Power Balance Bar
          _buildPowerBalanceBar(attackerPercent, attackerPower, defenderPower),
          const SizedBox(height: 16),

          // Army Overview (compact) - enemy composition hidden
          _buildArmyOverviewRow(attackerCounts, defenderCounts),
          const SizedBox(height: 20),

          // Terrain Selection (defender chooses, attacker sees it)
          if (!_isPlayerAttacker) ...[
            const Text('CHOOSE TERRAIN', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: BattleTerrain.values.map((t) => _buildTerrainChip(t)).toList(),
            ),
            const SizedBox(height: 16),
          ] else if (widget.record.terrain != null) ...[
            Text('Terrain: ${widget.record.terrain!.emoji} ${widget.record.terrain!.displayName}', style: TextStyle(color: Colors.amber.shade200, fontSize: 14)),
            const SizedBox(height: 16),
          ],

          // Engagement Order
          const Text('BATTLE STRATEGY', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: EngagementOrder.values.map((e) => _buildEngagementChip(e)).toList(),
          ),
          const SizedBox(height: 16),

          // Formation Selection Title
          const Text(
            'CHOOSE YOUR FORMATION',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),

          // Formation Cards with preview
          ...BattleFormation.values.map((formation) => _buildFormationCardWithPreview(formation)),

          const SizedBox(height: 16),

          // Active synergies
          if (_selectedFormation != null) ...[
            Builder(builder: (_) {
              final tactics = BattleTactics(
                terrain: !_isPlayerAttacker ? _selectedTerrain : null,
                formation: _selectedFormation!,
                engagementOrder: _selectedEngagement,
              );
              final synergies = tactics.getSynergies(null);
              if (synergies.isEmpty) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ACTIVE SYNERGIES', style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    ...synergies.map((s) => Text('• $s', style: const TextStyle(color: Colors.white70, fontSize: 12))),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
          ],

          // Rock-paper-scissors hint
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: const Column(
              children: [
                Text(
                  '🛡️ Shield Wall > 🐴 Crescent > 🏹 Skirmish > 🛡️',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
                SizedBox(height: 4),
                Text(
                  'Counter formations gain damage bonus',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerrainChip(BattleTerrain t) {
    final selected = _selectedTerrain == t;
    return GestureDetector(
      onTap: () => setState(() => _selectedTerrain = t),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.amber.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? Colors.amber : Colors.white24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 2),
            Text(t.displayName, style: TextStyle(color: selected ? Colors.amber : Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildEngagementChip(EngagementOrder e) {
    final selected = _selectedEngagement == e;
    return GestureDetector(
      onTap: () => setState(() => _selectedEngagement = e),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.blue.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? Colors.blue : Colors.white24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(e.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 2),
            Text(e.displayName, style: TextStyle(color: selected ? Colors.blue.shade200 : Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
            Text(e.description, style: const TextStyle(color: Colors.white38, fontSize: 9)),
          ],
        ),
      ),
    );
  }

  int _calculateArmyPower(List<UnitType> units) {
    int power = 0;
    for (final unit in units) {
      final stats = unit.stats;
      power += ((stats.attack + stats.missile + stats.charge) * stats.hp ~/ 10) + (stats.defense * 2);
    }
    return power;
  }

  Map<String, int> _countByCategory(List<UnitType> units) {
    final counts = <String, int>{'Infantry': 0, 'Ranged': 0, 'Cavalry': 0};
    for (final unit in units) {
      counts[unit.category] = (counts[unit.category] ?? 0) + 1;
    }
    return counts;
  }

  Widget _buildPowerBalanceBar(double attackerPercent, int attackerPower, int defenderPower) {
    return Column(
      children: [
        const Text(
          'POWER BALANCE',
          style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Container(
          height: 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white24),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Row(
              children: [
                Expanded(
                  flex: max(1, (attackerPercent * 100).round()),
                  child: Container(
                    color: _attackerNationality?.color.withValues(alpha: 0.8) ?? Colors.red,
                    alignment: Alignment.center,
                    child: Text(
                      '$attackerPower',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
                Expanded(
                  flex: max(1, ((1 - attackerPercent) * 100).round()),
                  child: Container(
                    color: _defenderNationality?.color.withValues(alpha: 0.8) ?? Colors.blue,
                    alignment: Alignment.center,
                    child: Text(
                      '$defenderPower',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildArmyOverviewRow(Map<String, int> attackerCounts, Map<String, int> defenderCounts) {
    final inBattle = simulation.phase != BattlePhase.formationSelect;

    return Row(
      children: [
        Expanded(
          child: _buildArmySummary(
            widget.record.attackerName,
            _isPlayerAttacker ? 'YOUR ARMY' : 'ENEMY',
            _attackerNationality?.color ?? Colors.red,
            _isPlayerAttacker || inBattle ? attackerCounts : {},
            _attackerUnits.length,
          ),
        ),
        Container(
          width: 1,
          height: 80,
          color: Colors.white24,
          margin: const EdgeInsets.symmetric(horizontal: 12),
        ),
        Expanded(
          child: _buildArmySummary(
            widget.record.defenderName,
            _isPlayerAttacker ? 'ENEMY' : 'DEFENDING',
            _defenderNationality?.color ?? Colors.blue,
            !_isPlayerAttacker || inBattle ? defenderCounts : {},
            _defenderUnits.length,
          ),
        ),
      ],
    );
  }

  Widget _buildArmySummary(String name, String subtitle, Color color, Map<String, int> counts, int? total) {
    final showComposition = counts.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(subtitle, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(
          name,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          '$total Units',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
        ),
        if (showComposition) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            children: [
              if ((counts['Infantry'] ?? 0) > 0)
                _buildCategoryBadge('⚔️${counts['Infantry']}', Colors.grey),
              if ((counts['Ranged'] ?? 0) > 0)
                _buildCategoryBadge('🏹${counts['Ranged']}', Colors.green),
              if ((counts['Cavalry'] ?? 0) > 0)
                _buildCategoryBadge('🐴${counts['Cavalry']}', Colors.orange),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10)),
    );
  }

  Widget _buildFormationCardWithPreview(BattleFormation formation) {
    final isSelected = _selectedFormation == formation;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        setState(() => _selectedFormation = formation);
        // Brief delay to show selection before transitioning
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            simulation.selectFormation(formation);
            _lastTick = DateTime.now(); // Reset tick timer
            setState(() {});
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSelected
                ? [Colors.amber.withValues(alpha: 0.3), Colors.amber.withValues(alpha: 0.1)]
                : [Colors.white.withValues(alpha: 0.1), Colors.white.withValues(alpha: 0.05)],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.amber : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(formation.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        formation.displayName,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formation.shortDescription,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.chevron_right,
              color: isSelected ? Colors.amber : Colors.white38,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withValues(alpha: 0.8),
            Colors.black.withValues(alpha: 0.4),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.flash_on, color: Colors.amber.shade700, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  children: [
                    Text(
                      widget.record.locationName.toUpperCase(),
                      style: TextStyle(
                        color: Colors.amber.shade100,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.record.terrain != null)
                      Text(
                        '${widget.record.terrain!.emoji} ${widget.record.terrain!.displayName}',
                        style: TextStyle(color: Colors.amber.shade300, fontSize: 11),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildFactionBadge(
                _attackerNationality!,
                widget.record.attackerName,
                simulation.aliveAttackers,
                widget.record.initialAttackerCount,
                simulation.attackerMorale,
                isLeft: true,
              ),
              _buildVsIndicator(),
              _buildFactionBadge(
                _defenderNationality!,
                widget.record.defenderName,
                simulation.aliveDefenders,
                simulation.defenderInitialNow,
                simulation.defenderMorale,
                isLeft: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFactionBadge(
    Nationality nationality,
    String name,
    int alive,
    int initial,
    double morale, {
    required bool isLeft,
  }) {
    final losses = initial - alive;
    return Expanded(
      child: Column(
        crossAxisAlignment: isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              if (isLeft)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: nationality.color,
                    border: Border.all(color: Colors.white54, width: 1),
                  ),
                ),
              if (isLeft) const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    color: nationality.color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: isLeft ? TextAlign.left : TextAlign.right,
                ),
              ),
              if (!isLeft) const SizedBox(width: 8),
              if (!isLeft)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: nationality.color,
                    border: Border.all(color: Colors.white54, width: 1),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$alive',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 4),
              if (losses > 0)
                Text(
                  '(-$losses)',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          // Morale bar
          Container(
            width: 60,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
              widthFactor: morale.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: morale > 0.5
                        ? [Colors.green, Colors.greenAccent]
                        : morale > 0.25
                            ? [Colors.orange, Colors.yellow]
                            : [Colors.red, Colors.redAccent],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVsIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        _getPhaseText(),
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Determine if player won (accounting for attacker/defender role)
  bool get _playerWon {
    final attackerWon = simulation.phase == BattlePhase.victory;
    return _isPlayerAttacker ? attackerWon : !attackerWon;
  }

  String _getPhaseText() {
    switch (simulation.phase) {
      case BattlePhase.formationSelect:
        return 'SELECT FORMATION';
      case BattlePhase.setup:
        return '${simulation.playerFormation?.emoji ?? ''} vs ???';
      case BattlePhase.field:
        return '⚔️ FIELD BATTLE';
      case BattlePhase.advance:
        return '🏰 BREACH THE GATE';
      case BattlePhase.cityAssault:
        return '🔥 STREET FIGHT';
      case BattlePhase.flagRaise:
        return '🚩 RAISING THE FLAG';
      case BattlePhase.victory:
      case BattlePhase.defeat:
        return _playerWon ? '🏆 VICTORY!' : '💀 DEFEAT';
    }
  }

  Widget _buildBattleArea() {
    return AnimatedBuilder(
      animation: Listenable.merge([_shakeController, _zoomController]),
      builder: (context, child) {
        final shake = sin(_shakeController.value * pi * 4) * 3 * (1 - _shakeController.value);
        final zoom = _zoomAnimation.value;
        final fade = _fadeAnimation.value;

        return Transform.scale(
          scale: zoom,
          child: Opacity(
            opacity: fade.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(shake, 0),
              child: child,
            ),
          ),
        );
      },
      child: Stack(
        children: [
          // Battlefield background
          CustomPaint(
            painter: BattlefieldPainter(
              terrain: simulation.terrain,
              isSiege: simulation.isSiege,
              time: simulation.totalTime,
              particles: simulation.particles,
              cityProgress: simulation.cityProgress,
              flagRaiseProgress: simulation.flagRaiseProgress,
              attackerColor: _attackerNationality!.color,
              defenderColor: _defenderNationality!.color,
            ),
            size: Size.infinite,
          ),
          // Battle units
          CustomPaint(
            painter: BattlePainter(
              simulation: simulation,
              factionImages: factionImages,
              screenShake: _shakeController.value,
            ),
            size: Size.infinite,
          ),
        ],
      ),
    );
  }

  Widget _buildDiceArea() {
    // Show combat progress during battle
    if (!simulation.isFighting) {
      return const SizedBox(height: 60);
    }

    // Combat progress indicator instead of dice
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Progress bar showing battle intensity
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (simulation.totalTime / 15).clamp(0.0, 1.0),
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(
                simulation.attackerMorale > simulation.defenderMorale
                    ? _attackerNationality!.color
                    : _defenderNationality!.color,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kills: ${simulation.defenderLossesThisRound}',
                style: TextStyle(
                  color: _attackerNationality!.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                'Kills: ${simulation.attackerLossesThisRound}',
                style: TextStyle(
                  color: _defenderNationality!.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    final isEnded = simulation.phase == BattlePhase.victory || simulation.phase == BattlePhase.defeat;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          // Retreat button — only while actually fighting
          if (simulation.isFighting)
            Expanded(
              child: OutlinedButton(
                onPressed: _retreat,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flag_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('RETREAT', maxLines: 1, overflow: TextOverflow.fade),
                    ],
                  ),
                ),
              ),
            ),
          if (simulation.isFighting) const SizedBox(width: 12),

          // Skip to end button
          if (!isEnded)
            IconButton(
              onPressed: () => simulation.skipToEnd(),
              icon: const Icon(Icons.skip_next, color: Colors.white54),
              tooltip: 'Skip to End',
            ),

          if (!isEnded) const SizedBox(width: 12),

          // Main action button (only shown when battle ends)
          if (isEnded)
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _endBattle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _playerWon ? Colors.green : Colors.red.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 8,
                ),
                child: Text(
                  _playerWon ? 'CLAIM VICTORY' : 'ACCEPT DEFEAT',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
              ),
            ),
          // Battle in progress indicator
          if (!isEnded)
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    '⚔️ BATTLE IN PROGRESS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
