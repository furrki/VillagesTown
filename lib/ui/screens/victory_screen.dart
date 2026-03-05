import 'package:flutter/material.dart';
import '../../data/models/player.dart';
import '../../data/models/victory_condition.dart';
import '../../engines/game_manager.dart';
import '../../engines/victory_engine.dart';

class VictoryScreen extends StatelessWidget {
  final Player winner;

  const VictoryScreen({super.key, required this.winner});

  @override
  Widget build(BuildContext context) {
    final game = GameManager.shared;
    final isHuman = winner.isHuman;
    final victoryType = game.achievedVictoryType;
    final score = isHuman ? VictoryEngine.calculateScore(game) : null;

    return Container(
      color: Colors.black.withOpacity(0.9),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 800),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Text(
                      isHuman ? (victoryType?.emoji ?? '🏆') : '💀',
                      style: const TextStyle(fontSize: 100),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                isHuman ? 'VICTORY!' : 'DEFEAT',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: isHuman ? Colors.amber : Colors.red,
                ),
              ),
              if (isHuman && victoryType != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${victoryType.displayName} Victory',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                isHuman
                    ? _victoryFlavor(victoryType)
                    : '${winner.name} has won the game.',
                style: const TextStyle(fontSize: 16, color: Colors.white54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Turn ${game.currentTurn}',
                style: const TextStyle(fontSize: 14, color: Colors.white38),
              ),
              // Score breakdown
              if (score != null) ...[
                const SizedBox(height: 32),
                _buildScoreCard(score),
              ],
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () => game.resetGame(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 48, vertical: 16),
                ),
                child: const Text(
                  'Play Again',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard(GameScore score) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          const Text(
            'SCORE',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 16),
          _scoreLine('Villages', score.villageScore),
          _scoreLine('Battles Won', score.battleScore),
          _scoreLine('Population', score.populationScore),
          _scoreLine('Gold', score.goldScore),
          if (score.speedBonus > 0) _scoreLine('Speed Bonus', score.speedBonus),
          if (score.victoryTypeBonus > 0)
            _scoreLine('Victory Bonus', score.victoryTypeBonus),
          const Divider(color: Colors.white24, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
              Text(
                '${score.total}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scoreLine(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 13, color: Colors.white54)),
          Text('+$value',
              style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _victoryFlavor(VictoryType? type) {
    return switch (type) {
      VictoryType.domination =>
        'Your empire spans the known world.\nThe remaining kingdoms bend the knee.',
      VictoryType.economic =>
        'Your merchants control every trade route.\nGold flows through your coffers like water.',
      VictoryType.military =>
        'Your armies are legendary.\nNo force can stand against you.',
      VictoryType.imperial =>
        'Five great cities stand as monuments to your civilization.\nYour empire will endure for a thousand years.',
      null => 'You have conquered the realm!',
    };
  }
}
