import 'package:flutter/material.dart';
import '../../data/models/player_character.dart';

class CargoPanel extends StatelessWidget {
  final PlayerCharacter player;
  final VoidCallback onClose;

  const CargoPanel({super.key, required this.player, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final entries = player.cargo.entries.where((e) => e.value > 0).toList();

    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                const Text('\u{1F4E6}', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                const Text(
                  'Cargo',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 6),
                Text(
                  '${player.currentCargoCount}/${player.totalCargoCapacity}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onClose,
                  child: const Icon(Icons.close, color: Colors.white38, size: 18),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF333333)),
          if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Your bags are empty',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Row(
                      children: [
                        Text(entry.key.emoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.key.displayName,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                        Text(
                          'x${entry.value}',
                          style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          // Pack mule / trade wagon info
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Text(
                  'Mules: ${player.packMules}',
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
                const SizedBox(width: 12),
                Text(
                  'Wagons: ${player.tradeWagons}',
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
