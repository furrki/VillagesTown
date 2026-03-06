import 'package:flutter/material.dart';
import '../../engines/game_manager.dart';

class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final game = GameManager.shared;
    final pc = game.playerCharacter;

    return Container(
      color: Colors.black.withValues(alpha: 0.9),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'GAME OVER',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 20),
              if (pc != null) ...[
                _statRow('Turns Survived', '${game.currentTurn}'),
                _statRow('Gold Earned', '${pc.totalGoldEarned}'),
                _statRow('Battles Won', '${pc.battlesWon}'),
                _statRow('Stage Reached', pc.stageTitle),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  game.resetGame();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.withValues(alpha: 0.3),
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('Return to Menu'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
