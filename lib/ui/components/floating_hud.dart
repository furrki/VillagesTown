import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/resource.dart';
import '../../providers/game_provider.dart';

class FloatingHUD extends StatelessWidget {
  const FloatingHUD({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, provider, _) {
        final game = provider.gameManager;
        final resources = game.getGlobalResources('player');
        final playerCount = game.getPlayerVillages('player').length;
        final totalCount = game.map.villages.length;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Turn badge
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue, Colors.purple],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${game.currentTurn}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Resources
              for (final r in [Resource.gold, Resource.food, Resource.iron, Resource.wood])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(r.emoji, style: const TextStyle(fontSize: 11)),
                      const SizedBox(width: 2),
                      Text(
                        '${resources[r] ?? 0}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: (resources[r] ?? 0) < 20 ? Colors.orange : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 4),
              // Victory progress
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events, size: 10, color: Colors.yellow),
                  const SizedBox(width: 2),
                  Text(
                    '$playerCount/$totalCount',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
