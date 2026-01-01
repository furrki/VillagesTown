import 'package:flutter/material.dart';
import '../../engines/game_manager.dart';
import '../theme/app_theme.dart';

class OwnerFlagView extends StatelessWidget {
  final String owner;
  final double size;

  const OwnerFlagView({
    super.key,
    required this.owner,
    required this.size,
  });

  String get flag {
    final game = GameManager.shared;
    final player = game.players.cast().firstWhere(
          (p) => p.id == owner,
          orElse: () => null,
        );
    return player?.nationality.flag ?? '🏳️';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.ownerColor(owner).withOpacity(0.3),
      ),
      child: Center(
        child: Text(
          flag,
          style: TextStyle(fontSize: size * 0.7),
        ),
      ),
    );
  }
}
