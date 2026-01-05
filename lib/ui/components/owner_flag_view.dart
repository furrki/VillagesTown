import 'package:flutter/material.dart';
import '../../engines/game_manager.dart';
import '../../data/models/player.dart';
import '../theme/app_theme.dart';

class OwnerFlagView extends StatelessWidget {
  final String owner;
  final double size;

  const OwnerFlagView({
    super.key,
    required this.owner,
    required this.size,
  });

  String get assetPath {
    if (owner == 'neutral') return 'assets/rebels.png';
    
    final game = GameManager.shared;
    final player = game.players.cast<Player?>().firstWhere(
          (p) => p?.id == owner,
          orElse: () => null,
        );
        
    // Fallback if player not found or eliminated
    return player?.nationality.assetPath ?? 'assets/rebels.png';
  }

  bool get isRectangular {
    if (owner == 'neutral') return false; // Rebels are round icon
    final game = GameManager.shared;
    final player = game.players.cast<Player?>().firstWhere(
          (p) => p?.id == owner,
          orElse: () => null,
        );
    return player?.nationality.isRectangular ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (isRectangular) {
      // Rectangular display
      return Container(
        width: size,
        height: size * 0.66, // Flag aspect ratio approx 3:2
        decoration: BoxDecoration(
          color: AppTheme.ownerColor(owner).withOpacity(0.3),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white24, width: 0.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.asset(
            assetPath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Text('🏳️', style: TextStyle(fontSize: size * 0.7)),
          ),
        ),
      );
    }

    // Circular display (Old logic)
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.ownerColor(owner).withOpacity(0.3),
      ),
      child: Center(
        child: ClipOval(
          child: Image.asset(
            assetPath,
            width: size * 0.9, 
            height: size * 0.9,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Text('🏳️', style: TextStyle(fontSize: size * 0.7)),
          ),
        ),
      ),
    );
  }
}
