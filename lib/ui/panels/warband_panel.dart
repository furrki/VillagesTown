import 'package:flutter/material.dart';
import '../../engines/game_manager.dart';
import '../components/countryball_avatar.dart';

class WarbandPanel extends StatelessWidget {
  final VoidCallback onClose;

  const WarbandPanel({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final game = GameManager.shared;
    final warband = game.playerWarband;
    final units = warband?.units ?? [];

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
                CountryballAvatar.player(size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Warband',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 6),
                Text(
                  '${units.length}',
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
          if (units.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No soldiers in your warband',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: units.length,
                itemBuilder: (context, index) {
                  final unit = units[index];
                  final hpRatio = unit.currentHP / unit.maxHP;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    child: Row(
                      children: [
                        Text(unit.unitType.emoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${unit.name} Lv.${unit.level}',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                              const SizedBox(height: 2),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: hpRatio,
                                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                                  valueColor: AlwaysStoppedAnimation(
                                    hpRatio > 0.5 ? Colors.green : hpRatio > 0.25 ? Colors.orange : Colors.red,
                                  ),
                                  minHeight: 4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ATK ${unit.attack} DEF ${unit.defense}',
                          style: const TextStyle(color: Colors.white54, fontSize: 10),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
