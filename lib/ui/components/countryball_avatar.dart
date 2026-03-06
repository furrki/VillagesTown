import 'package:flutter/material.dart';
import '../../data/models/nationality.dart';
import '../../engines/game_manager.dart';

class CountryballAvatar extends StatelessWidget {
  final double size;
  final String? owner;
  final Nationality? nationality;
  final Color? borderColor;
  final double borderWidth;
  final bool showGlow;
  final Color? glowColor;

  const CountryballAvatar({
    super.key,
    required this.size,
    this.owner,
    this.nationality,
    this.borderColor,
    this.borderWidth = 2,
    this.showGlow = false,
    this.glowColor,
  });

  factory CountryballAvatar.player({
    Key? key,
    required double size,
    bool showGlow = false,
  }) {
    return CountryballAvatar(
      key: key,
      size: size,
      owner: 'player',
      borderColor: Colors.white,
      showGlow: showGlow,
      glowColor: Colors.amber,
    );
  }

  String get _assetPath {
    if (nationality != null) return nationality!.assetPath;
    if (owner == null || owner == 'neutral') return 'assets/rebels.png';

    final game = GameManager.shared;
    final player = game.getPlayerById(owner);
    return player?.nationality.assetPath ?? 'assets/rebels.png';
  }

  @override
  Widget build(BuildContext context) {
    final eyeSize = (size * 0.14).clamp(2.0, 6.0);
    final eyeSpacing = size * 0.12;
    final eyeTop = size * 0.32;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Flag circle
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: borderColor ?? Colors.white54,
                width: borderWidth,
              ),
              boxShadow: showGlow
                  ? [
                      BoxShadow(
                        color: (glowColor ?? Colors.white).withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: ClipOval(
              child: Image.asset(
                _assetPath,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey,
                  child: Icon(Icons.flag, size: size * 0.5, color: Colors.white54),
                ),
              ),
            ),
          ),
          // Eyes
          Positioned(
            top: eyeTop,
            left: (size / 2) - eyeSpacing - eyeSize,
            child: _eye(eyeSize),
          ),
          Positioned(
            top: eyeTop,
            left: (size / 2) + eyeSpacing,
            child: _eye(eyeSize),
          ),
        ],
      ),
    );
  }

  Widget _eye(double eyeSize) {
    return Container(
      width: eyeSize,
      height: eyeSize,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: eyeSize * 0.2),
      ),
    );
  }
}
