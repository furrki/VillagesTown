import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/army.dart';
import '../../data/models/village.dart';
import '../../engines/game_manager.dart';
import '../../providers/game_provider.dart';
import 'village_marker.dart';
import 'marching_army_marker.dart';

class MapView extends StatefulWidget {
  final Village? selectedVillage;
  final Army? selectedArmy;
  final void Function(Village) onVillageSelected;
  final void Function(Army) onArmySelected;
  final void Function(Army, Village)? onArmySent;

  const MapView({
    super.key,
    this.selectedVillage,
    this.selectedArmy,
    required this.onVillageSelected,
    required this.onArmySelected,
    this.onArmySent,
  });

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final TransformationController _transformController = TransformationController();
  Army? _draggingArmy;

  Offset _villagePosition(Village village, Size size) {
    final game = GameManager.shared;
    final mapW = game.map.size.width;
    final mapH = game.map.size.height;
    final padX = size.width * 0.08;
    final padY = size.height * 0.08;

    return Offset(
      padX + (village.coordinates.dx / mapW) * (size.width - padX * 2),
      padY + (village.coordinates.dy / mapH) * (size.height - padY * 2),
    );
  }

  List<Village> _getConnectedVillages(Village village, List<Village> allVillages) {
    return allVillages.where((other) {
      if (other.id == village.id) return false;
      final dx = other.coordinates.dx - village.coordinates.dx;
      final dy = other.coordinates.dy - village.coordinates.dy;
      return sqrt(dx * dx + dy * dy) < 8;
    }).toList();
  }

  double _calculateMarchProgress(Army army, Village from, Village to) {
    final total = Army.calculateTravelTime(from.coordinates, to.coordinates);
    final remaining = army.turnsUntilArrival;
    return (total - remaining) / max(total, 1);
  }

  bool _hasIncomingThreat(Village village, List<Army> armies) {
    return armies.any((a) => a.isMarching && a.destination == village.id && a.owner != village.owner);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, provider, _) {
        final game = provider.gameManager;
        final visibleVillages = game.getVisibleVillages('player');
        final visibleArmies = game.getVisibleArmies('player');
        final stationedArmies = visibleArmies.where((a) => !a.isMarching && a.owner == 'player').toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);

            return InteractiveViewer(
              transformationController: _transformController,
              minScale: 0.5,
              maxScale: 3.0,
              boundaryMargin: const EdgeInsets.all(100),
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: CustomPaint(
                  painter: _ConnectionsPainter(
                    villages: visibleVillages,
                    positionForVillage: (v) => _villagePosition(v, size),
                    connectedVillages: (v) => _getConnectedVillages(v, visibleVillages),
                  ),
                  child: Stack(
                    children: [
                      // Marching armies
                      for (final army in visibleArmies.where((a) => a.isMarching))
                        if (army.origin != null && army.destination != null)
                          Builder(
                            builder: (context) {
                              final origin = game.map.villages.cast<Village?>().firstWhere(
                                    (v) => v!.id == army.origin,
                                    orElse: () => null,
                                  );
                              final dest = game.map.villages.cast<Village?>().firstWhere(
                                    (v) => v!.id == army.destination,
                                    orElse: () => null,
                                  );

                              if (origin == null || dest == null) return const SizedBox();

                              final progress = _calculateMarchProgress(army, origin, dest);
                              final fromPos = _villagePosition(origin, size);
                              final toPos = _villagePosition(dest, size);
                              final pos = Offset(
                                fromPos.dx + (toPos.dx - fromPos.dx) * progress,
                                fromPos.dy + (toPos.dy - fromPos.dy) * progress,
                              );

                              return Positioned(
                                left: pos.dx - 25,
                                top: pos.dy - 25,
                                child: GestureDetector(
                                  onTap: () => widget.onArmySelected(army),
                                  child: MarchingArmyMarker(
                                    army: army,
                                    isSelected: widget.selectedArmy?.id == army.id,
                                  ),
                                ),
                              );
                            },
                          ),
                      // Villages with drag targets
                      for (final village in visibleVillages)
                        Builder(
                          builder: (context) {
                            final pos = _villagePosition(village, size);
                            final armies = game.getArmiesAt(village.id);
                            final armyStrength = armies.fold(0, (sum, a) => sum + a.strength);

                            return Positioned(
                              left: pos.dx - 35,
                              top: pos.dy - 35,
                              child: DragTarget<Army>(
                                onWillAcceptWithDetails: (details) {
                                  final army = details.data;
                                  // Can't send to same village
                                  return army.stationedAt != village.id;
                                },
                                onAcceptWithDetails: (details) {
                                  final army = details.data;
                                  widget.onArmySent?.call(army, village);
                                },
                                builder: (context, candidateData, rejectedData) {
                                  final isDropTarget = candidateData.isNotEmpty;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    decoration: isDropTarget
                                        ? BoxDecoration(
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.yellow.withOpacity(0.5),
                                                blurRadius: 20,
                                                spreadRadius: 5,
                                              ),
                                            ],
                                          )
                                        : null,
                                    child: VillageMarker(
                                      village: village,
                                      isSelected: widget.selectedVillage?.id == village.id,
                                      armyStrength: armyStrength,
                                      hasThreat: _hasIncomingThreat(village, game.armies),
                                      onTap: () => widget.onVillageSelected(village),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      // Draggable stationed armies (shown on their villages)
                      for (final army in stationedArmies)
                        Builder(
                          builder: (context) {
                            final village = game.map.villages.cast<Village?>().firstWhere(
                                  (v) => v!.id == army.stationedAt,
                                  orElse: () => null,
                                );
                            if (village == null) return const SizedBox();

                            final pos = _villagePosition(village, size);

                            return Positioned(
                              left: pos.dx + 15,
                              top: pos.dy - 40,
                              child: Draggable<Army>(
                                data: army,
                                onDragStarted: () => setState(() => _draggingArmy = army),
                                onDragEnd: (_) => setState(() => _draggingArmy = null),
                                feedback: Material(
                                  color: Colors.transparent,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(army.emoji, style: const TextStyle(fontSize: 20)),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${army.strength}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                childWhenDragging: Opacity(
                                  opacity: 0.3,
                                  child: _ArmyBadge(army: army, isSelected: false),
                                ),
                                child: GestureDetector(
                                  onTap: () => widget.onArmySelected(army),
                                  child: _ArmyBadge(
                                    army: army,
                                    isSelected: widget.selectedArmy?.id == army.id,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ArmyBadge extends StatelessWidget {
  final Army army;
  final bool isSelected;

  const _ArmyBadge({required this.army, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(army.emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 2),
          Text(
            '${army.strength}',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _ConnectionsPainter extends CustomPainter {
  final List<Village> villages;
  final Offset Function(Village) positionForVillage;
  final List<Village> Function(Village) connectedVillages;

  _ConnectionsPainter({
    required this.villages,
    required this.positionForVillage,
    required this.connectedVillages,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final drawn = <String>{};

    for (final village in villages) {
      final from = positionForVillage(village);
      for (final other in connectedVillages(village)) {
        final key = [village.id, other.id]..sort();
        final drawKey = key.join('-');
        if (drawn.contains(drawKey)) continue;
        drawn.add(drawKey);

        final to = positionForVillage(other);

        final path = Path()
          ..moveTo(from.dx, from.dy)
          ..lineTo(to.dx, to.dy);

        canvas.drawPath(
          dashPath(path, 4, 4),
          paint,
        );
      }
    }
  }

  Path dashPath(Path source, double dashLength, double gapLength) {
    final dest = Path();
    final metrics = source.computeMetrics();

    for (final metric in metrics) {
      var distance = 0.0;
      while (distance < metric.length) {
        final length = min(dashLength, metric.length - distance);
        dest.addPath(metric.extractPath(distance, distance + length), Offset.zero);
        distance += dashLength + gapLength;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
