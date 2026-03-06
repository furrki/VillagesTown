import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/player_character.dart';
import '../../engines/game_loop.dart';
import '../../providers/game_provider.dart';
import 'countryball_avatar.dart';

class RtsHud extends StatelessWidget {
  final VoidCallback? onSpeedTap;
  final VoidCallback? onWarbandTap;
  final VoidCallback? onCargoTap;
  final VoidCallback? onMenuTap;

  const RtsHud({super.key, this.onSpeedTap, this.onWarbandTap, this.onCargoTap, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, provider, _) {
        final game = provider.gameManager;
        final pc = game.playerCharacter;
        if (pc == null) return const SizedBox.shrink();

        return SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                // Player countryball
                CountryballAvatar.player(size: 26),
                const SizedBox(width: 6),
                // Character info
                _badge(pc.stageTitle, Colors.amber),
                const SizedBox(width: 8),
                // Gold
                _stat('\u{1FA99}', '${pc.gold}', Colors.amber),
                const SizedBox(width: 8),
                // Cargo
                GestureDetector(
                  onTap: onCargoTap,
                  child: _stat('\u{1F4E6}', '${pc.currentCargoCount}/${pc.totalCargoCapacity}', Colors.white70),
                ),
                const SizedBox(width: 8),
                // Warband
                GestureDetector(
                  onTap: onWarbandTap,
                  child: _stat('\u{2694}\u{FE0F}', '${game.playerWarband?.unitCount ?? 0}/${pc.maxWarbandSize}', Colors.white70),
                ),
                const Spacer(),
                // Menu button
                if (onMenuTap != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: onMenuTap,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.settings, color: Colors.white54, size: 16),
                      ),
                    ),
                  ),
                // Speed control
                _speedButton(game.gameLoop, pc),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _stat(String emoji, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 3),
        Text(value, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _speedButton(GameLoop loop, PlayerCharacter pc) {
    final label = switch (loop.speed) {
      GameSpeed.paused => '\u23F8',
      GameSpeed.normal => '\u25B6',
      GameSpeed.fast => '\u25B6\u25B6',
      GameSpeed.fastest => '\u25B6\u25B6\u25B6',
    };

    final isPaused = loop.speed == GameSpeed.paused;

    return GestureDetector(
      onTap: () {
        if (onSpeedTap != null) {
          onSpeedTap!();
        } else {
          // Cycle through speeds
          final next = switch (loop.speed) {
            GameSpeed.paused => GameSpeed.normal,
            GameSpeed.normal => GameSpeed.fast,
            GameSpeed.fast => GameSpeed.fastest,
            GameSpeed.fastest => GameSpeed.paused,
          };
          loop.setSpeed(next);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isPaused
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.green.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isPaused
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.green.withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isPaused ? Colors.white60 : Colors.greenAccent,
          ),
        ),
      ),
    );
  }
}
