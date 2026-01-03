import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/army.dart';
import '../../data/models/tile.dart';
import '../../data/models/village.dart';
import '../../engines/game_manager.dart';
import '../../providers/game_provider.dart';
import 'village_marker.dart';
import 'army_visual_marker.dart';

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
  bool _initialPositionSet = false;

  void _setInitialPosition(Size size) {
    if (_initialPositionSet) return;
    _initialPositionSet = true;

    // Start with view shifted down so player village (top area) is centered
    const offsetY = 100.0;

    _transformController.value = Matrix4.identity()
      ..translate(0.0, offsetY);
  }

  Offset _villagePosition(Village village, Size size) {
    final game = GameManager.shared;
    final mapW = game.map.size.width;
    final mapH = game.map.size.height;
    final padX = size.width * 0.12;
    final padY = size.height * 0.12;

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
      return sqrt(dx * dx + dy * dy) < 6;
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

            // Set initial zoom/position once
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _setInitialPosition(size);
            });

            return Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A2A1A), Color(0xFF0D1A0D), Color(0xFF152015)],
                ),
              ),
              child: InteractiveViewer(
                transformationController: _transformController,
                minScale: 0.5,
                maxScale: 3.0,
                boundaryMargin: const EdgeInsets.all(double.infinity), // Allow infinite panning
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: CustomPaint(
                    painter: _TerrainPainter(
                      tiles: game.map.tiles,
                      mapSize: game.map.size,
                    ),
                    child: CustomPaint(
                      painter: _ConnectionsPainter(
                        villages: visibleVillages,
                        positionForVillage: (v) => _villagePosition(v, size),
                        connectedVillages: (v) => _getConnectedVillages(v, visibleVillages),
                      ),
                      child: CustomPaint(
                        painter: _MarchPathPainter(
                          marchingArmies: visibleArmies.where((a) => a.isMarching).toList(),
                          villages: {for (var v in game.map.villages) v.id: v},
                          positionForVillage: (v) => _villagePosition(v, size),
                          progressCalculator: _calculateMarchProgress,
                        ),
                        child: Stack(
                          children: [
                            // Marching armies (Using builder for position calc)
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
                                        child: ArmyVisualMarker(
                                          army: army,
                                          isSelected: widget.selectedArmy?.id == army.id,
                                          isMarching: true,
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
                                                      color: Colors.yellow.withValues(alpha: 0.5),
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
                                        child: ArmyVisualMarker(
                                          army: army,
                                          isSelected: true, // Highlight when dragging
                                        ),
                                      ),
                                      childWhenDragging: Opacity(
                                        opacity: 0.3,
                                        child: ArmyVisualMarker(army: army, isSelected: false),
                                      ),
                                      child: GestureDetector(
                                        onTap: () => widget.onArmySelected(army),
                                        child: ArmyVisualMarker(
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

class _TerrainPainter extends CustomPainter {
  final List<List<Tile>> tiles;
  final Size mapSize;

  _TerrainPainter({required this.tiles, required this.mapSize});

  @override
  void paint(Canvas canvas, Size size) {
    if (tiles.isEmpty) return;

    final rows = tiles.length;
    final cols = tiles.first.length;

    // Sample at lower resolution for smoother look
    const sampleStep = 4;
    final blobRadius = size.width / (cols / sampleStep) * 0.8;

    for (var y = 0; y < rows; y += sampleStep) {
      for (var x = 0; x < cols; x += sampleStep) {
        final tile = tiles[y][x];
        final centerX = (x + sampleStep / 2) / cols * size.width;
        final centerY = (y + sampleStep / 2) / rows * size.height;

        // Muted, darker terrain colors
        final baseColor = _getMutedColor(tile.terrain.color);

        // Radial gradient blob
        final gradient = RadialGradient(
          colors: [
            baseColor.withAlpha(60),
            baseColor.withAlpha(20),
            baseColor.withAlpha(0),
          ],
          stops: const [0.0, 0.5, 1.0],
        );

        final blobPaint = Paint()
          ..shader = gradient.createShader(
            Rect.fromCircle(center: Offset(centerX, centerY), radius: blobRadius),
          );

        canvas.drawCircle(Offset(centerX, centerY), blobRadius, blobPaint);
      }
    }
  }

  Color _getMutedColor(Color color) {
    // Darken and desaturate
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withSaturation((hsl.saturation * 0.5).clamp(0, 1))
        .withLightness((hsl.lightness * 0.4).clamp(0, 1))
        .toColor();
  }

  @override
  bool shouldRepaint(covariant _TerrainPainter oldDelegate) => false;
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
      ..color = Colors.white.withValues(alpha: 0.12)
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

class _MarchPathPainter extends CustomPainter {
  final List<Army> marchingArmies;
  final Map<String, Village> villages;
  final Offset Function(Village) positionForVillage;
  final double Function(Army, Village, Village) progressCalculator;

  _MarchPathPainter({
    required this.marchingArmies,
    required this.villages,
    required this.positionForVillage,
    required this.progressCalculator,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final army in marchingArmies) {
      final origin = villages[army.origin];
      final dest = villages[army.destination];
      
      if (origin == null || dest == null) continue;

      final from = positionForVillage(origin);
      final to = positionForVillage(dest);
      // final progress = progressCalculator(army, origin, dest);

      // Determine color based on owner
      final color = army.owner == 'player' ? const Color(0xFF3B82F6) : const Color(0xFFEF4444);

      final paint = Paint()
        ..color = color.withValues(alpha: 0.6)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      // Draw dashed line from Start to End
      final path = Path()
        ..moveTo(from.dx, from.dy)
        ..lineTo(to.dx, to.dy);

      final dashed = _dashPath(path, 10, 8);
      canvas.drawPath(dashed, paint);

      // Draw faint "trace" of progress (solid line behind the dash up to current pos?)
      // Or just a target marker at destination
      
      // Target Marker
      final targetPaint = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(to, 6, targetPaint);
      
      final targetStroke = Paint()
         ..color = color.withValues(alpha: 0.8)
         ..strokeWidth = 1.5
         ..style = PaintingStyle.stroke;

      canvas.drawCircle(to, 6, targetStroke);
    }
  }

  Path _dashPath(Path source, double dashLength, double gapLength) {
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
