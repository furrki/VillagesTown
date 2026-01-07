import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../data/models/combat_log.dart';
import '../../engines/game_manager.dart';

class BattleScreen extends StatefulWidget {
  final BattleRecord record;
  final VoidCallback onDismiss;

  const BattleScreen({
    super.key,
    required this.record,
    required this.onDismiss,
  });

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> with TickerProviderStateMixin {
  int _roundsPlayed = 0;
  late int _currentAttackerCount;
  late int _currentDefenderCount;
  bool _isRolling = false;
  bool _autoRollEnabled = false;
  Timer? _autoRollTimer;
  
  // Animations
  late AnimationController _diceAnimController;
  late AnimationController _shakeController;
  
  // Dashboard Visuals
  final List<DamagePopup> _damagePopups = [];

  @override
  void initState() {
    super.initState();
    _currentAttackerCount = widget.record.initialAttackerCount;
    _currentDefenderCount = widget.record.initialDefenderCount;
    
    _diceAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    // Auto-start battle visuals? No, let user roll.
  }

  @override
  void dispose() {
    _autoRollTimer?.cancel();
    _diceAnimController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _rollDice() async {
    if (_isRolling || _roundsPlayed >= widget.record.rounds.length) return;

    setState(() {
      _isRolling = true;
      _diceAnimController.forward(from: 0.0);
    });

    // Simulate roll duration
    await Future.delayed(const Duration(milliseconds: 600));

    // Impact!
    final round = widget.record.rounds[_roundsPlayed];
    
    setState(() {
      _roundsPlayed++;
      _currentAttackerCount -= round.attackerLosses;
      _currentDefenderCount -= round.defenderLosses;
      _isRolling = false;
      
      // Add Juice
      if (round.attackerLosses > 0 || round.defenderLosses > 0) {
        _shakeController.forward(from: 0.0);
        
        if (round.attackerLosses > 0) {
          _addDamagePopup(true, round.attackerLosses);
        }
        if (round.defenderLosses > 0) {
          _addDamagePopup(false, round.defenderLosses);
        }
      }
    });

    if (!mounted) return;
    if (_autoRollEnabled && !isBattleOver) {
      _scheduleAutoRoll();
    } else {
      _autoRollTimer?.cancel();
      if (isBattleOver && _autoRollEnabled) {
          setState(() {
            _autoRollEnabled = false;
          });
      }
    }
  }
  
  void _addDamagePopup(bool isAttacker, int amount) {
    setState(() {
      _damagePopups.add(DamagePopup(
        id: DateTime.now().millisecondsSinceEpoch.toString() + (isAttacker ? '_att' : '_def'),
        amount: amount,
        isAttacker: isAttacker,
      ));
    });
    
    // Cleanup after animation
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _damagePopups.removeWhere((p) => p.amount == amount && p.isAttacker == isAttacker); // Simple cleanup
        });
      }
    });
  }
  
  void _endBattle({required bool retreated}) {
    _autoRollTimer?.cancel();
    GameManager.shared.finalizeBattle(widget.record, _roundsPlayed, retreated);
    widget.onDismiss();
  }

  void _toggleAutoRoll() {
    if (isBattleOver) return;
    setState(() {
      _autoRollEnabled = !_autoRollEnabled;
    });

    if (_autoRollEnabled) {
      if (!_isRolling) {
        _rollDice();
      }
    } else {
      _autoRollTimer?.cancel();
    }
  }

  void _scheduleAutoRoll() {
    _autoRollTimer?.cancel();
    if (!_autoRollEnabled || isBattleOver || _isRolling) return;

    _autoRollTimer = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      if (_autoRollEnabled && !isBattleOver && !_isRolling) {
        _rollDice();
      }
    });
  }

  bool get isBattleOver => 
     _roundsPlayed >= widget.record.rounds.length || 
     _currentAttackerCount <= 0 || 
     _currentDefenderCount <= 0;

  @override
  Widget build(BuildContext context) {
    // Determine icon size - smaller for large armies
    final maxUnits = [widget.record.initialAttackerCount, widget.record.initialDefenderCount]
        .reduce((a, b) => a > b ? a : b);
    final double tokenSize = (maxUnits > 100) ? 6.0 : (maxUnits > 50 ? 10.0 : 14.0);
    
    final round = _roundsPlayed > 0 && _roundsPlayed <= widget.record.rounds.length
        ? widget.record.rounds[_roundsPlayed - 1]
        : null;

    return Scaffold(
      backgroundColor: Colors.black, 
      body: AnimatedBuilder(
        animation: _shakeController,
        builder: (context, child) {
          final shake = sin(_shakeController.value * pi * 8) * 4 * (1 - _shakeController.value);
          return Transform.translate(
            offset: Offset(shake, 0),
            child: child,
          );
        },
        child: Container(
          color: const Color(0xFF121212),
          child: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                     // 1. TOP BAR
                     _buildTopBar(),
                     
                     // 2. BATTLEFIELD
                     Expanded(
                       child: Column(
                         children: [
                           // ATTACKER
                           Expanded(
                             child: _buildArmyPanel(
                               name: widget.record.attackerName,
                               initial: widget.record.initialAttackerCount,
                               current: _currentAttackerCount,
                               color: const Color(0xFFFF5252), 
                               tokenSize: tokenSize,
                               isAttacker: true,
                             ),
                           ),
                           
                           // CENTER AREA (Dice & impact)
                           Container(
                             height: 100, // Taller for drama
                             alignment: Alignment.center,
                             child: _buildBattleCenter(round),
                           ),
      
                           // DEFENDER
                           Expanded(
                             child: _buildArmyPanel(
                               name: widget.record.defenderName,
                               initial: widget.record.initialDefenderCount,
                               current: _currentDefenderCount,
                               color: const Color(0xFF448AFF),
                               tokenSize: tokenSize,
                               isAttacker: false,
                             ),
                           ),
                         ],
                       ),
                     ),
                     
                     // 3. CONTROLS
                     _buildBottomControls(),
                  ],
                ),
                
                // POPUPS OVERLAY
                ..._damagePopups.map((p) => _buildDamagePopup(p)),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildDamagePopup(DamagePopup popup) {
    // Position based on attacker (top) or defender (bottom)
    final top = popup.isAttacker ? 150.0 : null;
    final bottom = popup.isAttacker ? null : 150.0;
    
    return Positioned(
      top: top, 
      bottom: bottom,
      left: 0, right: 0,
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, -50 * value), // Fly up
              child: Opacity(
                opacity: (1.0 - value).clamp(0.0, 1.0),
                child: Text(
                  '-${popup.amount}',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(color: Colors.black, blurRadius: 4, offset: Offset(2, 2)),
                      Shadow(color: Colors.black, blurRadius: 10),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.black38,
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flash_on, color: Colors.amber[700], size: 24), // Need custom icon or standard
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.record.locationName.toUpperCase(),
              style: TextStyle(
                 color: Colors.amber[100], 
                 fontSize: 18, 
                 fontWeight: FontWeight.w900, 
                 letterSpacing: 2.0,
                 shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArmyPanel({
    required String name, 
    required int initial, 
    required int current, 
    required Color color, 
    required double tokenSize,
    required bool isAttacker,
  }) {
    final deadCount = initial - current;
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 12, spreadRadius: 2),
        ],
      ),
      child: Column(
        crossAxisAlignment: isAttacker ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
           // Header Row
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             crossAxisAlignment: CrossAxisAlignment.end,
             children: [
               Expanded(
                 child: Text(
                   name, 
                   style: TextStyle(
                     color: color, 
                     fontSize: 22, 
                     fontWeight: FontWeight.w800,
                     letterSpacing: 0.5,
                   ),
                   overflow: TextOverflow.ellipsis,
                 )
               ),
               Column(
                 crossAxisAlignment: CrossAxisAlignment.end,
                 children: [
                   Row(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       Text('$current', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                       const SizedBox(width: 6),
                       const Text('UNITS', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.2)),
                     ],
                   ),
                   if (deadCount > 0)
                     Text(
                       '-$deadCount LOST', 
                       style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)
                     ),
                 ],
               ),
             ],
           ),
           const Divider(color: Colors.white10, height: 16),
           
           // Army Grid
           Expanded(
             child: ClipRect(
               child: SingleChildScrollView(
                 reverse: !isAttacker,
                 child: Wrap(
                   spacing: 2,
                   runSpacing: 2,
                   alignment: isAttacker ? WrapAlignment.start : WrapAlignment.end,
                   children: List.generate(initial, (index) {
                     // Reverse index for attacker so dead units (highest indices) are at the end?
                     // Currently index 0..initial.
                     // Alive are 0..current-1. Dead are current..initial-1.
                     
                     final isDead = index >= current;
                     return AnimatedContainer(
                       duration: const Duration(milliseconds: 300),
                       width: tokenSize,
                       height: tokenSize,
                       decoration: BoxDecoration(
                         color: isDead ? Colors.red.withValues(alpha: 0.1) : color,
                         border: isDead ? Border.all(color: Colors.red.withValues(alpha: 0.2)) : null,
                         shape: BoxShape.circle,
                         boxShadow: isDead ? null : [
                           BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 2, spreadRadius: 0),
                         ],
                       ),
                     );
                   }),
                 ),
               ),
             ),
           ),
        ],
      ),
    );
  }

  Widget _buildBattleCenter(BattleRound? round) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (round != null) 
          Expanded(child: Center(child: _buildDiceRow(round.attackerRolls, const Color(0xFFFF5252)))),
         
        // VS Badge
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.8, end: 1.0),
          duration: const Duration(seconds: 1),
          curve: Curves.easeInOut,
          builder: (context, val, child) {
            return Transform.scale(scale: val, child: child);
          },
          onEnd: () {}, // Could loop
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24, width: 2),
              boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 10)],
            ),
            child: const Text('VS', style: TextStyle(
              fontFamily: 'Serif', fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white70
            )),
          ),
        ),

        if (round != null) 
          Expanded(child: Center(child: _buildDiceRow(round.defenderRolls, const Color(0xFF448AFF)))),
      ],
    );
  }

  Widget _buildDiceRow(List<int> rolls, Color color) {
    return AnimatedBuilder(
      animation: _diceAnimController,
      builder: (context, child) {
         return Row(
           mainAxisAlignment: MainAxisAlignment.center,
           children: rolls.map((r) => _buildDie(r, color)).toList(),
         );
      }
    );
  }
  
  Widget _buildDie(int value, Color color) {
    // Spin/Pop animation
    final t = _diceAnimController.value;
    final angle = _isRolling ? t * pi * 4 : 0.0;
    final scale = _isRolling ? 0.8 + (sin(t * pi) * 0.2) : 1.0;
    
    // Randomize value while rolling
    final displayValue = _isRolling ? Random().nextInt(6) + 1 : value;
    
    return Transform.rotate(
      angle: angle,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: 44, height: 44,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: color, 
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
               BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 10, spreadRadius: 2)
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            '$displayValue', 
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.black45,
      child: Row(
        children: [
          // RETREAT
          if (!isBattleOver)
            Expanded(
              child: OutlinedButton(
                onPressed: _isRolling ? null : () => _endBattle(retreated: true), 
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flag_outlined, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'RETREAT',
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
          if (!isBattleOver)
             const SizedBox(width: 12),

          if (!isBattleOver)
            _buildAutoToggle(),

          if (!isBattleOver)
             const SizedBox(width: 12),

          // ROLL / FINISH
          Expanded(
            flex: 2,
            child: isBattleOver
              ? ElevatedButton(
                  onPressed: () => _endBattle(retreated: false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[700],
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    elevation: 12,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    shadowColor: Colors.amber.withValues(alpha: 0.5),
                  ),
                  child: const Text('VICTORY / DEFEAT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                )
              : ElevatedButton.icon(
                  onPressed: _isRolling ? null : _rollDice,
                  icon: _isRolling 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
                    : const Icon(Icons.casino, size: 22),
                  label: Text(_isRolling ? 'ROLLING...' : 'ROLL DICE', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    shadowColor: Colors.white.withValues(alpha: 0.5),
                    elevation: 10,
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoToggle() {
    final isActive = _autoRollEnabled && !isBattleOver;
    return SizedBox(
      width: 56,
      height: 56,
      child: Tooltip(
        message: isActive ? 'Auto rolling…' : 'Auto resolve battle',
        child: OutlinedButton(
          onPressed: isBattleOver ? null : _toggleAutoRoll,
          style: OutlinedButton.styleFrom(
            foregroundColor: isActive ? Colors.black : Colors.white70,
            backgroundColor: isActive ? Colors.amber[400] : Colors.transparent,
            side: BorderSide(color: isActive ? Colors.amber : Colors.white24, width: 2),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Icon(isActive ? Icons.pause : Icons.fast_forward, size: 22),
        ),
      ),
    );
  }
}

class DamagePopup {
  final String id;
  final int amount;
  final bool isAttacker;
  
  DamagePopup({required this.id, required this.amount, required this.isAttacker});
}
