import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/combat_log.dart';
import '../../../data/models/nationality.dart';
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

    // Find attacker nationality
    final attackerArmy = game.armies.cast().firstWhere(
          (a) => a?.id == widget.record.attackerId,
          orElse: () => null,
        );
    _attackerNationality = game.getNationality(attackerArmy?.owner ?? 'player') ?? Nationality.ottomans;

    // Find defender nationality - check army first (field battle), then village
    final defenderArmy = game.armies.cast().firstWhere(
          (a) => a?.id == widget.record.defenderId,
          orElse: () => null,
        );
    if (defenderArmy != null) {
      _defenderNationality = game.getNationality(defenderArmy.owner) ?? Nationality.byzantines;
    } else {
      final defenderVillage = game.map.villages.cast().firstWhere(
            (v) => v?.id == widget.record.defenderId,
            orElse: () => null,
          );
      _defenderNationality = defenderVillage?.nationality ?? Nationality.byzantines;
    }

    // Load faction images
    _loadFactionImages();

    // Create simulation
    final size = MediaQuery.of(context).size;
    simulation = BattleSimulation(
      record: widget.record,
      attackerNationality: _attackerNationality!,
      defenderNationality: _defenderNationality!,
      screenSize: size,
    );

    simulation.onPhaseChanged = () {
      if (simulation.phase == BattlePhase.clash) {
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

  void _rollDice() {
    if (simulation.phase != BattlePhase.diceWait) return;
    HapticFeedback.lightImpact();
    simulation.rollDice();
  }

  void _retreat() {
    _retreated = true;
    _endBattle();
  }

  void _endBattle() {
    final roundsPlayed = simulation.currentRound;
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
                child: Text(
                  widget.record.locationName.toUpperCase(),
                  style: TextStyle(
                    color: Colors.amber.shade100,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                  overflow: TextOverflow.ellipsis,
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
                widget.record.initialDefenderCount,
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
            mainAxisSize: MainAxisSize.min,
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
              Flexible(
                child: Text(
                  name,
                  style: TextStyle(
                    color: nationality.color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
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

  String _getPhaseText() {
    switch (simulation.phase) {
      case BattlePhase.setup:
        return 'READY';
      case BattlePhase.approach:
        return 'CHARGE!';
      case BattlePhase.clash:
        return '⚔️ CLASH!';
      case BattlePhase.diceWait:
        return 'ROLL DICE';
      case BattlePhase.rolling:
        return 'ROLLING...';
      case BattlePhase.resolution:
        return 'IMPACT!';
      case BattlePhase.regroup:
        return 'REGROUP';
      case BattlePhase.victory:
        return '🏆 VICTORY!';
      case BattlePhase.defeat:
        return '💀 DEFEAT';
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
    final showDice = simulation.phase == BattlePhase.diceWait ||
        simulation.phase == BattlePhase.rolling ||
        simulation.phase == BattlePhase.resolution;

    if (!showDice) {
      return const SizedBox(height: 90);
    }

    return SizedBox(
      height: 90,
      child: Row(
        children: [
          // Attacker dice
          Expanded(
            child: CustomPaint(
              painter: DicePainter(
                values: simulation.attackerDice,
                color: _attackerNationality!.color,
                rollProgress: simulation.diceRollProgress,
                isWinner: _countWins(simulation.attackerDice, simulation.defenderDice) > 0,
              ),
              size: Size.infinite,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('vs', style: TextStyle(color: Colors.white38, fontSize: 12)),
          ),
          // Defender dice
          Expanded(
            child: CustomPaint(
              painter: DicePainter(
                values: simulation.defenderDice,
                color: _defenderNationality!.color,
                rollProgress: simulation.diceRollProgress,
              ),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    );
  }

  int _countWins(List<int> attacker, List<int> defender) {
    int wins = 0;
    final sorted1 = List<int>.from(attacker)..sort((a, b) => b.compareTo(a));
    final sorted2 = List<int>.from(defender)..sort((a, b) => b.compareTo(a));
    for (int i = 0; i < min(sorted1.length, sorted2.length); i++) {
      if (sorted1[i] > sorted2[i]) wins++;
    }
    return wins;
  }

  Widget _buildControls() {
    final isEnded = simulation.phase == BattlePhase.victory || simulation.phase == BattlePhase.defeat;
    final canRoll = simulation.phase == BattlePhase.diceWait;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          // Retreat button
          if (!isEnded)
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
          if (!isEnded) const SizedBox(width: 12),

          // Auto toggle
          if (!isEnded)
            IconButton(
              onPressed: () {
                setState(() {
                  simulation.setAutoPlay(!simulation.isAutoPlay);
                });
              },
              icon: Icon(
                simulation.isAutoPlay ? Icons.pause : Icons.fast_forward,
                color: simulation.isAutoPlay ? Colors.amber : Colors.white54,
              ),
              tooltip: simulation.isAutoPlay ? 'Pause Auto' : 'Auto Play',
            ),

          if (!isEnded) const SizedBox(width: 12),

          // Main action button
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: isEnded
                  ? _endBattle
                  : canRoll
                      ? _rollDice
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isEnded
                    ? (simulation.phase == BattlePhase.victory ? Colors.green : Colors.red.shade800)
                    : Colors.white,
                foregroundColor: isEnded ? Colors.white : Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 8,
              ),
              child: Text(
                isEnded
                    ? (simulation.phase == BattlePhase.victory ? 'CLAIM VICTORY' : 'ACCEPT DEFEAT')
                    : canRoll
                        ? '🎲 ROLL DICE'
                        : 'WAIT...',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
