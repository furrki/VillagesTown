import 'package:flutter/material.dart';
import '../../data/models/village.dart';
import '../theme/app_theme.dart';
import '../components/owner_flag_view.dart';
import '../../engines/game_manager.dart';

class VillageMarker extends StatefulWidget {
  final Village village;
  final String displayName;
  final bool isSelected;
  final int armyCount;
  final bool hasThreat;
  final VoidCallback onTap;
  final double zoom;

  const VillageMarker({
    super.key,
    required this.village,
    required this.displayName,
    required this.isSelected,
    required this.armyCount,
    required this.hasThreat,
    required this.onTap,
    this.zoom = 5.0,
  });

  @override
  State<VillageMarker> createState() => _VillageMarkerState();
}

class _VillageMarkerState extends State<VillageMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.hasThreat) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(VillageMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasThreat && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.hasThreat && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color get ownerColor => AppTheme.ownerColor(widget.village.owner);
  bool get isNeutral => widget.village.owner == 'neutral';
  bool get isPlayerOwned => widget.village.owner == 'player';

  // Fog of war states
  bool get isInVisionRange {
    final game = GameManager.shared;
    return game.isVillageInVisionRange(widget.village, 'player');
  }

  bool get isDiscoveredButOutOfRange {
    final game = GameManager.shared;
    return !isPlayerOwned && !isInVisionRange && game.discoveredVillageIDs.contains(widget.village.id);
  }

  double get markerSize {
    if (widget.zoom >= 7) return 44;
    if (widget.zoom >= 6) return 36;
    if (widget.zoom >= 5) return 30;
    return 22;
  }

  double get flagSize {
    if (widget.zoom >= 7) return 28;
    if (widget.zoom >= 6) return 22;
    if (widget.zoom >= 5) return 18;
    return 14;
  }

  bool get showLabel => widget.zoom >= 5.5;
  bool get showArmyBadge => widget.zoom >= 5.0 && widget.armyCount > 0;
  bool get hasArmy => widget.armyCount > 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMarkerCircle(),
          if (showLabel) ...[
            const SizedBox(height: 3),
            _buildLabel(),
          ],
        ],
      ),
    );
  }

  Widget _buildMarkerCircle() {
    final baseSize = markerSize;
    final ringSize = baseSize + 10;

    return SizedBox(
      width: ringSize + 4,
      height: ringSize + 4,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Outer glow for owned cities (enhanced when army present)
          if (!isNeutral)
            Container(
              width: baseSize + 16,
              height: baseSize + 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: ownerColor.withValues(alpha: hasArmy ? 0.5 : 0.3),
                    blurRadius: hasArmy ? 16 : 12,
                    spreadRadius: hasArmy ? 4 : 2,
                  ),
                  if (hasArmy)
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.2),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                ],
              ),
            ),

          // Military ring when army stationed
          if (hasArmy && !widget.hasThreat && !widget.isSelected)
            Container(
              width: ringSize - 2,
              height: ringSize - 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.6),
                  width: 2,
                ),
              ),
            ),

          // Threat pulse ring
          if (widget.hasThreat)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  width: ringSize + 4,
                  height: ringSize + 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.red.withValues(alpha: _pulseAnimation.value),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: _pulseAnimation.value * 0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                );
              },
            ),

          // Selection ring
          if (widget.isSelected && !widget.hasThreat)
            Container(
              width: ringSize,
              height: ringSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: ownerColor,
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: ownerColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),

          // Main circle
          Opacity(
            opacity: isDiscoveredButOutOfRange ? 0.4 : 1.0,
            child: Container(
              width: baseSize,
              height: baseSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isNeutral
                      ? [
                          Colors.grey.shade800,
                          Colors.grey.shade900,
                        ]
                      : [
                          Colors.grey.shade900,
                          Colors.black,
                        ],
                ),
                border: Border.all(
                  color: isDiscoveredButOutOfRange
                      ? Colors.grey.shade700
                      : (isNeutral
                          ? Colors.grey.shade600
                          : ownerColor.withValues(alpha: widget.isSelected ? 1.0 : 0.8)),
                  width: widget.isSelected ? 2.5 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                  // Inner highlight
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.05),
                    blurRadius: 2,
                    offset: const Offset(-1, -1),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: OwnerFlagView(owner: widget.village.owner, size: flagSize),
                  ),
                  // "?" overlay for discovered but out of range
                  if (isDiscoveredButOutOfRange)
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.6),
                      ),
                      child: Center(
                        child: Text(
                          '?',
                          style: TextStyle(
                            fontSize: flagSize * 0.8,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Army badge (bottom center) - enhanced military style
          if (showArmyBadge)
            Positioned(
              bottom: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.amber.shade700,
                      Colors.amber.shade900,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.9),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shield,
                      size: widget.zoom >= 6 ? 10 : 8,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${widget.armyCount}',
                      style: TextStyle(
                        fontSize: widget.zoom >= 6 ? 10 : 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: const [
                          Shadow(color: Colors.black, blurRadius: 2),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLabel() {
    return Opacity(
      opacity: isDiscoveredButOutOfRange ? 0.5 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isDiscoveredButOutOfRange
                ? Colors.grey.shade700.withValues(alpha: 0.3)
                : ownerColor.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Text(
          isDiscoveredButOutOfRange ? '${widget.displayName} (?)' : widget.displayName,
          style: TextStyle(
            fontSize: widget.zoom >= 7 ? 10 : 8,
            fontWeight: FontWeight.w600,
            color: isDiscoveredButOutOfRange
                ? Colors.grey.shade500
                : (isNeutral ? Colors.grey.shade400 : Colors.white),
            letterSpacing: 0.3,
            shadows: const [
              Shadow(color: Colors.black, blurRadius: 2),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.visible,
          softWrap: false,
        ),
      ),
    );
  }
}
