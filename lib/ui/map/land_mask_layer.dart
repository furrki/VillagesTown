import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../data/models/village.dart';
import '../../engines/game_manager.dart';

/// The map's base: land over the dark sea, drawn on the device. No web tiles, so the map
/// needs no tile service, key or network. The coast is Natural Earth's 1:50m land, which
/// is public domain. `tool/make_coast.py` clips and simplifies it into the asset.
class LandLayer extends StatelessWidget {
  const LandLayer({super.key});

  static const land = Color(0xFF2B2B45);
  static const coast = Color(0xFF4A4A6A);

  /// Loaded once per run. Each entry is one landmass: its outer ring, then any inland
  /// seas cut out of it, each ring as [lng, lat] pairs.
  static final Future<List<Polygon<Object>>> _polygons = _load();

  static List<LatLng> _ring(List ring) => [
        for (final p in ring) LatLng((p[1] as num).toDouble(), (p[0] as num).toDouble()),
      ];

  static Future<List<Polygon<Object>>> _load() async {
    final raw = jsonDecode(await rootBundle.loadString('assets/land_coast.json')) as List;
    return [
      for (final shape in raw.cast<List>())
        Polygon<Object>(
          points: _ring(shape.first as List),
          holePointsList: [for (final hole in shape.skip(1)) _ring(hole as List)],
          color: land,
          borderColor: coast,
          borderStrokeWidth: 1.5,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Polygon<Object>>>(
      future: _polygons,
      builder: (context, snap) => PolygonLayer(polygons: snap.data ?? const <Polygon<Object>>[]),
    );
  }
}

/// Simple Voronoi territory layer
class LandMaskTerritoryLayer extends StatefulWidget {
  final List<Village> villages;
  final GameManager game;

  const LandMaskTerritoryLayer({
    super.key,
    required this.villages,
    required this.game,
  });

  @override
  State<LandMaskTerritoryLayer> createState() => _LandMaskTerritoryLayerState();
}

class _LandMaskTerritoryLayerState extends State<LandMaskTerritoryLayer> {
  /// Rebuilt only when an owner, a custom border or the village list changes. The map rebuilds every tick.
  List<Polygon> _polygons = const [];
  String? _sig;

  List<Village> get villages => widget.villages;
  GameManager get game => widget.game;

  @override
  Widget build(BuildContext context) {
    final sig = villages.map((v) => '${v.id}:${v.owner}:${v.customTerritory?.length ?? 0}').join('|');
    if (sig != _sig) {
      _sig = sig;
      _polygons = _computeTerritoryPolygons();
    }
    return PolygonLayer(polygons: _polygons);
  }

  List<Polygon> _computeTerritoryPolygons() {
    if (villages.isEmpty) return [];

    final result = <Polygon>[];

    const minLat = 28.0;
    const maxLat = 48.0;
    const minLng = 12.0;
    const maxLng = 48.0;

    for (final village in villages) {
      final color = _getOwnerColor(village);

      // Use custom territory if available, otherwise compute Voronoi
      List<LatLng> points;
      if (village.customTerritory != null && village.customTerritory!.length >= 3) {
        points = village.customTerritory!;
      } else {
        final cell = _computeVoronoiCell(village, villages, minLat, maxLat, minLng, maxLng);
        if (cell.length < 3) continue;
        points = cell.map((p) => LatLng(p.y, p.x)).toList();
      }

      result.add(Polygon(
        points: points,
        color: color.withValues(alpha: 0.2),
        borderColor: color.withValues(alpha: 0.5),
        borderStrokeWidth: 1.0,
      ));
    }

    return result;
  }

  List<_Point> _computeVoronoiCell(
    Village site,
    List<Village> allSites,
    double minLat,
    double maxLat,
    double minLng,
    double maxLng,
  ) {
    List<_Point> polygon = [
      _Point(minLng, minLat),
      _Point(maxLng, minLat),
      _Point(maxLng, maxLat),
      _Point(minLng, maxLat),
    ];

    final sitePoint = _Point(site.coordinates.longitude, site.coordinates.latitude);

    for (final other in allSites) {
      if (other.id == site.id) continue;

      final otherPoint = _Point(other.coordinates.longitude, other.coordinates.latitude);
      polygon = _clipToHalfPlane(polygon, sitePoint, otherPoint);
      if (polygon.isEmpty) break;
    }

    return polygon;
  }

  List<_Point> _clipToHalfPlane(List<_Point> polygon, _Point site, _Point other) {
    if (polygon.isEmpty) return [];

    final mid = _Point((site.x + other.x) / 2, (site.y + other.y) / 2);
    final nx = site.x - other.x;
    final ny = site.y - other.y;

    final result = <_Point>[];

    for (int i = 0; i < polygon.length; i++) {
      final current = polygon[i];
      final next = polygon[(i + 1) % polygon.length];

      final currentInside = (current.x - mid.x) * nx + (current.y - mid.y) * ny >= 0;
      final nextInside = (next.x - mid.x) * nx + (next.y - mid.y) * ny >= 0;

      if (currentInside) {
        result.add(current);
        if (!nextInside) {
          final inter = _intersectLine(current, next, mid, nx, ny);
          if (inter != null) result.add(inter);
        }
      } else if (nextInside) {
        final inter = _intersectLine(current, next, mid, nx, ny);
        if (inter != null) result.add(inter);
      }
    }

    return result;
  }

  _Point? _intersectLine(_Point p1, _Point p2, _Point mid, double nx, double ny) {
    final dx = p2.x - p1.x;
    final dy = p2.y - p1.y;
    final denom = dx * nx + dy * ny;
    if (denom.abs() < 1e-10) return null;
    final t = ((mid.x - p1.x) * nx + (mid.y - p1.y) * ny) / denom;
    if (t < 0 || t > 1) return null;
    return _Point(p1.x + t * dx, p1.y + t * dy);
  }

  Color _getOwnerColor(Village village) {
    if (village.owner == 'neutral') {
      return Colors.grey;
    }

    final player = game.players.cast().firstWhere(
          (p) => p?.id == village.owner,
          orElse: () => null,
        );

    if (player != null) {
      return player.nationality.color;
    }

    return village.nationality.color;
  }
}

class _Point {
  final double x;
  final double y;
  const _Point(this.x, this.y);
}
