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

  String get assetPath {
    if (owner == 'neutral') return 'assets/rebels.png';

    final game = GameManager.shared;
    final player = game.getPlayerById(owner);

    return player?.nationality.assetPath ?? 'assets/rebels.png';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.ownerColor(owner).withValues(alpha: 0.3),
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: animation,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: ClipOval(
            key: ValueKey(owner),
            child: Image.asset(
              assetPath,
              width: size * 0.9,
              height: size * 0.9,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Text('🏳️', style: TextStyle(fontSize: size * 0.7)),
            ),
          ),
        ),
      ),
    );
  }
}
