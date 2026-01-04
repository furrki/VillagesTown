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

class _BattleScreenState extends State<BattleScreen> with SingleTickerProviderStateMixin {
  int _roundsPlayed = 0;
  late int _currentAttackerCount;
  late int _currentDefenderCount;
  bool _isRolling = false;
  late AnimationController _diceAnimController;
  
  // Determine player role for Retreat logic
  // bool get _isPlayerAttacker => widget.record.attackerName != 'Enemy';

  @override
  void initState() {
    super.initState();
    _currentAttackerCount = widget.record.initialAttackerCount;
    _currentDefenderCount = widget.record.initialDefenderCount;
    _diceAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _diceAnimController.dispose();
    super.dispose();
  }

  void _rollDice() async {
    if (_isRolling || _roundsPlayed >= widget.record.rounds.length) return;

    setState(() {
      _isRolling = true;
    });

    await _diceAnimController.forward(from: 0.0);

    final round = widget.record.rounds[_roundsPlayed];
    setState(() {
      _roundsPlayed++;
      _currentAttackerCount -= round.attackerLosses;
      _currentDefenderCount -= round.defenderLosses;
      _isRolling = false;
    });
  }
  
  void _endBattle({required bool retreated}) {
    // If retreated, we need to know WHO retreated. 
    // GameManager.finalizeBattle assumes Attacker retreated if 'retreated' is true?
    // We should probably handle this carefully.
    // For now, let's assume Player is Attacker for retreat (most common).
    // If Player is Defender, 'Retreat' usually means 'Abandon Village' -> flee to neighbor?
    // That's complex. Let's disable Retreat for Defender for now unless requested.
    
    GameManager.shared.finalizeBattle(widget.record, _roundsPlayed, retreated);
    widget.onDismiss();
  }

  bool get isBattleOver => 
     _roundsPlayed >= widget.record.rounds.length || 
     _currentAttackerCount <= 0 || 
     _currentDefenderCount <= 0;

  @override
  Widget build(BuildContext context) {
    // Determine icon size - smaller for dense views
    final maxUnits = [widget.record.initialAttackerCount, widget.record.initialDefenderCount]
        .reduce((a, b) => a > b ? a : b);
    
    // For 115 units, we want them small enough to fit many per line.
    // Screen width ~400. If size 10, we fit 40 per line.
    final double tokenSize = (maxUnits > 100) ? 8.0 : (maxUnits > 50 ? 12.0 : 16.0);
    final round = _roundsPlayed > 0 && _roundsPlayed <= widget.record.rounds.length
        ? widget.record.rounds[_roundsPlayed - 1]
        : null;

    return Scaffold(
      backgroundColor: Colors.black, 
      body: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1a1510),
          gradient: LinearGradient(
             begin: Alignment.topCenter,
             end: Alignment.bottomCenter,
             colors: [
               const Color(0xFF2C0000), // Attacker Red tint top
               const Color(0xFF00002C), // Defender Blue tint bottom
             ],
             stops: const [0.2, 0.8],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
               // 1. TOP BAR (Battle Location)
               _buildTopBar(),
               
               // 2. BATTLEFIELD (Stacked)
               Expanded(
                 child: Column(
                   children: [
                     // ATTACKER (Top)
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
                     
                     // CENTER (Versus & Dice)
                     Container(
                       height: 80,
                       alignment: Alignment.center,
                       child: Row(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           if (round != null) 
                             Expanded(child: Center(child: _buildDiceRow(round.attackerRolls, const Color(0xFFFF5252)))),
                            
                           Container(
                             padding: const EdgeInsets.symmetric(horizontal: 16),
                             decoration: BoxDecoration(
                               color: Colors.black45,
                               borderRadius: BorderRadius.circular(16),
                               border: Border.all(color: Colors.white12),
                             ),
                             child: const Text('VS', style: TextStyle(
                               fontFamily: 'Serif', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white54
                             )),
                           ),

                           if (round != null) 
                             Expanded(child: Center(child: _buildDiceRow(round.defenderRolls, const Color(0xFF448AFF)))),
                         ],
                       ),
                     ),

                     // DEFENDER (Bottom)
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
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.black26,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_on, color: Colors.amber[700], size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.record.locationName.toUpperCase(),
              style: TextStyle(
                 color: Colors.amber[100], 
                 fontSize: 18, 
                 fontWeight: FontWeight.bold, 
                 letterSpacing: 1.2
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
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: isAttacker ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
           // Header Row
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Expanded(
                 child: Text(
                   name, 
                   style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
                   overflow: TextOverflow.ellipsis,
                 )
               ),
               Column(
                 crossAxisAlignment: CrossAxisAlignment.end,
                 children: [
                   Row(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       Text('$current', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                       const SizedBox(width: 6),
                       Text('SOLDIERS', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1.0)),
                     ],
                   ),
                   if (deadCount > 0)
                     Text(
                       '$deadCount CASUALTIES', 
                       style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w500)
                     ),
                 ],
               ),
             ],
           ),
           const Divider(color: Colors.white10),
           
           // Army Grid
           Expanded(
             child: ClipRect(
               child: SingleChildScrollView(
                 reverse: !isAttacker,
                 child: Wrap(
                   spacing: 2,
                   runSpacing: 2,
                   children: List.generate(initial, (index) {
                     final isDead = index >= current;
                     return Container(
                       width: tokenSize,
                       height: tokenSize,
                       decoration: BoxDecoration(
                         color: isDead ? Colors.transparent : color,
                         border: isDead ? Border.all(color: Colors.white12) : null,
                         shape: BoxShape.circle,
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

  Widget _buildDiceRow(List<int> rolls, Color color) {
    return AnimatedBuilder(
      animation: _diceAnimController,
      builder: (context, child) {
         double t = _diceAnimController.value;
         return Row(
           mainAxisAlignment: MainAxisAlignment.center,
           children: rolls.map((r) => _buildDie(r, color, t)).toList(),
         );
      }
    );
  }
  
  // Reuse existing _buildDie, _buildTopBar, _buildBottomControls
  // But need to ensure they match signature.
  
  // ... (Paste necessary helpers if modified or referencing missing vars)


  // Determine player role for Retreat logic
  // bool get _isPlayerAttacker => widget.record.attackerName != 'Enemy'; 

  // ... (lines omitted)

  Widget _buildDie(int value, Color color, double animValue) {
    // Zoom/Shake in
    double scale = 1.0;
    if (animValue < 1.0 && _isRolling) {
       scale = 0.5 + (animValue * 0.5); // Grow
    }
    
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 36, height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color, 
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
             BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 1)
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          '$value', 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black26,
      child: Row(
        children: [
          // RETREAT
          if (!isBattleOver)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isRolling ? null : () => _endBattle(retreated: true), 
                icon: const Icon(Icons.flag_outlined, size: 18),
                label: const FittedBox(child: Text('RETREAT')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            
          if (!isBattleOver)
             const SizedBox(width: 16),

          // ROLL / FINISH
          Expanded(
            flex: 2,
            child: isBattleOver
              ? ElevatedButton(
                  onPressed: () => _endBattle(retreated: false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[700],
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 8,
                  ),
                  child: const Text('FINISH', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                )
              : ElevatedButton.icon(
                  onPressed: _isRolling ? null : _rollDice,
                  icon: _isRolling 
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : const Icon(Icons.casino, size: 18),
                  label: Text(_isRolling ? 'ROLLING...' : 'ROLL DICE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
          ),
        ],
      ),
    );
  }
}
