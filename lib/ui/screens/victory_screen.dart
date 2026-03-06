import 'package:flutter/material.dart';
import '../../data/models/achievement.dart';
import '../../data/models/player.dart';
import '../../data/models/victory_condition.dart';
import '../../engines/game_manager.dart';
import '../../engines/progression_engine.dart';
import '../../engines/victory_engine.dart';

class VictoryScreen extends StatefulWidget {
  final Player winner;

  const VictoryScreen({super.key, required this.winner});

  @override
  State<VictoryScreen> createState() => _VictoryScreenState();
}

class _VictoryScreenState extends State<VictoryScreen> {
  List<Achievement> _newAchievements = [];
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _saveAndCheckAchievements();
  }

  Future<void> _saveAndCheckAchievements() async {
    if (_saved) return;
    _saved = true;
    final game = GameManager.shared;
    final isVictory = widget.winner.isHuman;
    final achievements = await ProgressionEngine.onGameEnd(game, isVictory);
    if (mounted) {
      setState(() => _newAchievements = achievements);
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = GameManager.shared;
    final isHuman = widget.winner.isHuman;
    final victoryType = game.achievedVictoryType;
    final score = isHuman ? VictoryEngine.calculateScore(game) : null;

    return Container(
      color: Colors.black.withValues(alpha: 0.9),
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
                    : '${widget.winner.name} has won the game.',
                style: const TextStyle(fontSize: 16, color: Colors.white54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Turn ${game.currentTurn}',
                style: const TextStyle(fontSize: 14, color: Colors.white38),
              ),
              // Newly unlocked achievements
              if (_newAchievements.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildAchievements(),
              ],
              // Score breakdown
              if (score != null) ...[
                const SizedBox(height: 24),
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

  Widget _buildAchievements() {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Text(
            'ACHIEVEMENTS UNLOCKED',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: Colors.amber,
            ),
          ),
          const SizedBox(height: 12),
          ..._newAchievements.map((a) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(a.emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.displayName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            a.description,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.white54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildScoreCard(GameScore score) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
          if (score.difficultyMultiplier != 1.0 || score.modifierMultiplier != 1.0) ...[
            const Divider(color: Colors.white12, height: 16),
            if (score.difficultyMultiplier != 1.0)
              _scoreLine('Difficulty', 0, suffix: 'x${score.difficultyMultiplier}'),
            if (score.modifierMultiplier != 1.0)
              _scoreLine('Modifiers', 0, suffix: 'x${score.modifierMultiplier.toStringAsFixed(2)}'),
          ],
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

  Widget _scoreLine(String label, int value, {String? suffix}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 13, color: Colors.white54)),
          Text(suffix ?? '+$value',
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
