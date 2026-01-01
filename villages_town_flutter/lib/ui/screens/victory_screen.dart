import 'package:flutter/material.dart';
import '../../data/models/player.dart';
import '../../engines/game_manager.dart';

class VictoryScreen extends StatelessWidget {
  final Player winner;

  const VictoryScreen({super.key, required this.winner});

  @override
  Widget build(BuildContext context) {
    final game = GameManager.shared;

    return Container(
      color: Colors.black.withOpacity(0.9),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: const Text(
                    '🏆',
                    style: TextStyle(fontSize: 100),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              winner.isHuman ? 'VICTORY!' : 'DEFEAT',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: winner.isHuman ? Colors.amber : Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              winner.isHuman ? 'You have conquered the realm!' : '${winner.name} has won the game.',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Turn ${game.currentTurn}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () {
                game.resetGame();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              ),
              child: const Text(
                'Play Again',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
