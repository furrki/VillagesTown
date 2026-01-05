import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../data/models/army.dart';
import '../../data/models/nationality.dart';
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
  final MapController _mapController = MapController();

  // Map bounds for the Byzantine/Ottoman region
  static const _initialCenter = LatLng(38.5, 30.0);
  static const _initialZoom = 5.0;
  static const _minZoom = 4.0;
  static const _maxZoom = 8.0;

  bool _hasIncomingThreat(Village village, List<Army> armies) {
    return armies.any((a) => a.isMarching && a.destination == village.id && a.owner != village.owner);
  }

  double _calculateMarchProgress(Army army, Village from, Village to) {
    final total = Army.calculateTravelTime(from.coordinates, to.coordinates);
    final remaining = army.turnsUntilArrival;
    return (total - remaining) / (total > 0 ? total : 1);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, provider, _) {
        final game = provider.gameManager;
        final visibleVillages = game.map.villages; // Show all cities
        final visibleArmies = game.getVisibleArmies('player');
        final stationedArmies = visibleArmies.where((a) => !a.isMarching && a.owner == 'player').toList();

        return FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _initialCenter,
            initialZoom: _initialZoom,
            minZoom: _minZoom,
            maxZoom: _maxZoom,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
            backgroundColor: const Color(0xFF1a1a2e),
          ),
          children: [
            // Dark map tiles
            TileLayer(
              urlTemplate: 'https://cartodb-basemaps-{s}.global.ssl.fastly.net/dark_all/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.villages.town',
              retinaMode: true,
            ),

            // Connection lines from selected location only
            PolylineLayer(
              polylines: _buildConnectionLines(visibleVillages, game),
            ),

            // March paths for moving armies
            PolylineLayer(
              polylines: _buildMarchPaths(visibleArmies, game),
            ),

            // Village markers
            MarkerLayer(
              markers: _buildVillageMarkers(visibleVillages, game),
            ),

            // Marching army markers
            MarkerLayer(
              markers: _buildMarchingArmyMarkers(visibleArmies, game),
            ),

            // Stationed army markers (draggable)
            MarkerLayer(
              markers: _buildStationedArmyMarkers(stationedArmies, game),
            ),
          ],
        );
      },
    );
  }

  List<Polyline> _buildConnectionLines(List<Village> villages, GameManager game) {
    // Only show connections from selected village or army's location
    String? focusVillageId;
    if (widget.selectedArmy?.stationedAt != null) {
      focusVillageId = widget.selectedArmy!.stationedAt;
    } else if (widget.selectedVillage != null) {
      focusVillageId = widget.selectedVillage!.id;
    }

    if (focusVillageId == null) return [];

    final focusVillage = villages.cast<Village?>().firstWhere(
      (v) => v!.id == focusVillageId,
      orElse: () => null,
    );
    if (focusVillage == null) return [];

    // Use pre-computed K-nearest neighbor connections
    final neighbors = game.getNeighbors(focusVillageId);

    final lines = <Polyline>[];
    for (final neighbor in neighbors) {
      lines.add(Polyline(
        points: [
          focusVillage.coordinates.toLatLng(),
          neighbor.coordinates.toLatLng(),
        ],
        color: Colors.white.withValues(alpha: 0.25),
        strokeWidth: 1.5,
        pattern: const StrokePattern.dotted(),
      ));
    }
    return lines;
  }

  List<Polyline> _buildMarchPaths(List<Army> armies, GameManager game) {
    final lines = <Polyline>[];

    for (final army in armies.where((a) => a.isMarching)) {
      final origin = game.map.villages.cast<Village?>().firstWhere(
        (v) => v!.id == army.origin,
        orElse: () => null,
      );
      final dest = game.map.villages.cast<Village?>().firstWhere(
        (v) => v!.id == army.destination,
        orElse: () => null,
      );

      if (origin == null || dest == null) continue;

      final color = army.owner == 'player'
          ? const Color(0xFF3B82F6)
          : const Color(0xFFEF4444);

      lines.add(Polyline(
        points: [
          origin.coordinates.toLatLng(),
          dest.coordinates.toLatLng(),
        ],
        color: color.withValues(alpha: 0.6),
        strokeWidth: 2,
        pattern: const StrokePattern.dotted(),
      ));
    }
    return lines;
  }

  List<Marker> _buildVillageMarkers(List<Village> villages, GameManager game) {
    return villages.map((village) {
      final armies = game.getArmiesAt(village.id);
      final armyCount = armies.fold(0, (sum, a) => sum + a.unitCount);

      // Check if this village is a valid march target for selected army
      final bool isValidMarchTarget;
      if (widget.selectedArmy != null && widget.selectedArmy!.stationedAt != null) {
        isValidMarchTarget = widget.selectedArmy!.stationedAt != village.id &&
            game.areNeighbors(widget.selectedArmy!.stationedAt!, village.id);
      } else {
        isValidMarchTarget = false;
      }

      return Marker(
        point: village.coordinates.toLatLng(),
        width: 80,
        height: 80,
        child: DragTarget<Army>(
          onWillAcceptWithDetails: (details) {
            final armyOrigin = details.data.stationedAt;
            if (armyOrigin == null || armyOrigin == village.id) return false;
            // Only accept if villages are neighbors
            return game.areNeighbors(armyOrigin, village.id);
          },
          onAcceptWithDetails: (details) {
            widget.onArmySent?.call(details.data, village);
          },
          builder: (context, candidateData, rejectedData) {
            final isDropTarget = candidateData.isNotEmpty;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: (isDropTarget || isValidMarchTarget)
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: isDropTarget
                              ? Colors.yellow.withValues(alpha: 0.6)
                              : Colors.greenAccent.withValues(alpha: 0.3),
                          blurRadius: isDropTarget ? 20 : 15,
                          spreadRadius: isDropTarget ? 5 : 2,
                        ),
                      ],
                    )
                  : null,
              child: VillageMarker(
                village: village,
                displayName: game.getVillageDisplayName(village),
                isSelected: widget.selectedVillage?.id == village.id,
                armyCount: armyCount,
                hasThreat: _hasIncomingThreat(village, game.armies),
                onTap: () => widget.onVillageSelected(village),
              ),
            );
          },
        ),
      );
    }).toList();
  }

  List<Marker> _buildMarchingArmyMarkers(List<Army> armies, GameManager game) {
    final markers = <Marker>[];

    for (final army in armies.where((a) => a.isMarching)) {
      final origin = game.map.villages.cast<Village?>().firstWhere(
        (v) => v!.id == army.origin,
        orElse: () => null,
      );
      final dest = game.map.villages.cast<Village?>().firstWhere(
        (v) => v!.id == army.destination,
        orElse: () => null,
      );

      if (origin == null || dest == null) continue;

      final progress = _calculateMarchProgress(army, origin, dest);
      final fromLat = origin.coordinates.latitude;
      final fromLng = origin.coordinates.longitude;
      final toLat = dest.coordinates.latitude;
      final toLng = dest.coordinates.longitude;

      final currentLat = fromLat + (toLat - fromLat) * progress;
      final currentLng = fromLng + (toLng - fromLng) * progress;

      final nationality = _getNationality(army.owner, game);

      markers.add(Marker(
        point: LatLng(currentLat, currentLng),
        width: 52,
        height: 60,
        child: GestureDetector(
          onTap: () => widget.onArmySelected(army),
          child: ArmyVisualMarker(
            army: army,
            nationality: nationality,
            isSelected: widget.selectedArmy?.id == army.id,
            isMarching: true,
          ),
        ),
      ));
    }
    return markers;
  }

  List<Marker> _buildStationedArmyMarkers(List<Army> stationedArmies, GameManager game) {
    final markers = <Marker>[];

    for (final army in stationedArmies) {
      final village = game.map.villages.cast<Village?>().firstWhere(
        (v) => v!.id == army.stationedAt,
        orElse: () => null,
      );
      if (village == null) continue;

      // Offset slightly from village center (small offset so it's visible near city)
      final offsetLat = village.coordinates.latitude + 0.08;
      final offsetLng = village.coordinates.longitude + 0.12;

      final nationality = _getNationality(army.owner, game);

      markers.add(Marker(
        point: LatLng(offsetLat, offsetLng),
        width: 52,
        height: 65,
        child: Draggable<Army>(
          data: army,
          feedback: Material(
            color: Colors.transparent,
            child: ArmyVisualMarker(
              army: army,
              nationality: nationality,
              isSelected: true,
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: ArmyVisualMarker(army: army, nationality: nationality, isSelected: false),
          ),
          child: GestureDetector(
            onTap: () => widget.onArmySelected(army),
            child: ArmyVisualMarker(
              army: army,
              nationality: nationality,
              isSelected: widget.selectedArmy?.id == army.id,
            ),
          ),
        ),
      ));
    }
    return markers;
  }

  Nationality _getNationality(String ownerId, GameManager game) {
    final player = game.players.cast().firstWhere(
      (p) => p.id == ownerId,
      orElse: () => null,
    );
    return player?.nationality ?? Nationality.ottomans;
  }
}
