import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../data/models/army.dart';
import '../../data/models/nationality.dart';
import '../../data/models/player_character.dart';
import '../../data/models/village.dart';
import '../../engines/game_manager.dart';
import '../../providers/game_provider.dart';
import '../components/countryball_avatar.dart';
import 'village_marker.dart';
import 'army_visual_marker.dart';
import 'land_mask_layer.dart';

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
  double _currentZoom = 5.0;
  bool _hasCenteredOnPlayer = false;

  // Map bounds for the Byzantine/Ottoman region
  static const _initialCenter = LatLng(38.5, 30.0);
  static const _initialZoom = 5.0;
  static const _minZoom = 4.0;
  static const _maxZoom = 8.0;

  @override
  void didUpdateWidget(MapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Center on player's village once at game start
    if (!_hasCenteredOnPlayer && widget.selectedVillage != null) {
      _hasCenteredOnPlayer = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(
          widget.selectedVillage!.coordinates.toLatLng(),
          6.0,
        );
      });
    }
  }

  void _onMapEvent(MapEvent event) {
    if (event is MapEventMove || event is MapEventDoubleTapZoom || event is MapEventScrollWheelZoom) {
      setState(() {
        _currentZoom = _mapController.camera.zoom;
      });
    }
  }

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
        // Filter villages by visibility (fog of war)
        final visibleVillages = game.map.villages.where((v) => game.isVillageVisible(v, 'player')).toList();
        final visibleArmies = game.getVisibleArmies('player');

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
            onMapEvent: _onMapEvent,
          ),
          children: [
            // Dark map tiles
            TileLayer(
              urlTemplate: 'https://cartodb-basemaps-{s}.global.ssl.fastly.net/dark_all/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.villages.town',
              retinaMode: true,
            ),

            // Territory polygons
            LandMaskTerritoryLayer(
              villages: visibleVillages,
              game: game,
            ),

            // March paths for moving armies
            PolylineLayer(
              polylines: _buildMarchPaths(visibleArmies, game),
            ),

            // Village markers
            MarkerLayer(
              markers: _buildVillageMarkers(visibleVillages, game),
            ),

            // Marching army markers (stationed armies now shown via village marker)
            MarkerLayer(
              markers: _buildMarchingArmyMarkers(visibleArmies, game),
            ),

            // Player character marker (while traveling)
            MarkerLayer(
              markers: _buildPlayerMarker(game),
            ),
          ],
        );
      },
    );
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

    // Player travel path
    final pc = game.playerCharacter;
    if (pc != null && pc.state == PlayerState.traveling) {
      final pOrigin = game.map.villages.cast<Village?>().firstWhere(
        (v) => v!.id == pc.travelOriginId,
        orElse: () => null,
      );
      final pDest = game.map.villages.cast<Village?>().firstWhere(
        (v) => v!.id == pc.travelDestinationId,
        orElse: () => null,
      );
      if (pOrigin != null && pDest != null) {
        lines.add(Polyline(
          points: [
            pOrigin.coordinates.toLatLng(),
            pDest.coordinates.toLatLng(),
          ],
          color: Colors.blue.withValues(alpha: 0.8),
          strokeWidth: 3,
          pattern: const StrokePattern.dotted(),
        ));
      }
    }

    return lines;
  }

  (double, double) _getMarkerDimensions() {
    // Width just needs to fit circle + ring
    // Height needs extra space for label when zoom >= 5.5
    final showLabel = _currentZoom >= 5.5;
    final labelHeight = showLabel ? 22.0 : 0.0;

    if (_currentZoom >= 7) return (70, 70 + labelHeight);
    if (_currentZoom >= 6) return (60, 60 + labelHeight);
    if (_currentZoom >= 5) return (50, 50 + labelHeight);
    return (40, 40);
  }

  List<Marker> _buildVillageMarkers(List<Village> villages, GameManager game) {
    final (markerWidth, markerHeight) = _getMarkerDimensions();

    return villages.map((village) {
      final totalDefenders = game.getTotalDefenders(village);

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
        width: markerWidth,
        height: markerHeight,
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
                armyCount: totalDefenders,
                hasThreat: _hasIncomingThreat(village, game.armies),
                onTap: () => widget.onVillageSelected(village),
                zoom: _currentZoom,
              ),
            );
          },
        ),
      );
    }).toList();
  }

  List<Marker> _buildMarchingArmyMarkers(List<Army> armies, GameManager game) {
    final markers = <Marker>[];

    // Marching armies
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

    // Besieging armies - show near the village they're besieging
    for (final army in armies.where((a) => a.isBesieging)) {
      final village = game.map.villages.cast<Village?>().firstWhere(
        (v) => v!.id == army.stationedAt,
        orElse: () => null,
      );
      if (village == null) continue;

      final nationality = _getNationality(army.owner, game);

      // Offset slightly from village center to show siege
      final offset = 0.03;
      markers.add(Marker(
        point: LatLng(
          village.coordinates.latitude + offset,
          village.coordinates.longitude - offset,
        ),
        width: 52,
        height: 60,
        child: GestureDetector(
          onTap: () => widget.onArmySelected(army),
          child: ArmyVisualMarker(
            army: army,
            nationality: nationality,
            isSelected: widget.selectedArmy?.id == army.id,
            isBesieging: true,
          ),
        ),
      ));
    }

    return markers;
  }

  List<Marker> _buildPlayerMarker(GameManager game) {
    final pc = game.playerCharacter;
    if (pc == null) return [];

    if (pc.state == PlayerState.traveling) {
      final originId = pc.travelOriginId;
      final destId = pc.travelDestinationId;
      if (originId == null || destId == null) return [];

      final origin = game.map.villages.cast<Village?>().firstWhere(
        (v) => v!.id == originId,
        orElse: () => null,
      );
      final dest = game.map.villages.cast<Village?>().firstWhere(
        (v) => v!.id == destId,
        orElse: () => null,
      );
      if (origin == null || dest == null) return [];

      final progress = pc.travelProgress.clamp(0.0, 1.0);
      final lat = origin.coordinates.latitude + (dest.coordinates.latitude - origin.coordinates.latitude) * progress;
      final lng = origin.coordinates.longitude + (dest.coordinates.longitude - origin.coordinates.longitude) * progress;

      return [
        Marker(
          point: LatLng(lat, lng),
          width: 36,
          height: 36,
          child: CountryballAvatar.player(size: 36, showGlow: true),
        ),
      ];
    }

    // Show at current city when stationed
    if (pc.state == PlayerState.atCity && pc.currentCityId != null) {
      final city = game.map.villages.cast<Village?>().firstWhere(
        (v) => v!.id == pc.currentCityId,
        orElse: () => null,
      );
      if (city == null) return [];

      // Offset slightly so it doesn't overlap the village marker
      return [
        Marker(
          point: LatLng(
            city.coordinates.latitude + 0.15,
            city.coordinates.longitude + 0.15,
          ),
          width: 30,
          height: 30,
          child: CountryballAvatar.player(size: 30),
        ),
      ];
    }

    return [];
  }

  Nationality _getNationality(String ownerId, GameManager game) {
    final player = game.players.cast().firstWhere(
      (p) => p.id == ownerId,
      orElse: () => null,
    );
    return player?.nationality ?? Nationality.ottomans;
  }
}
