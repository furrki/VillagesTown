import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/models/geo_coordinate.dart';
import '../data/models/nationality.dart';
import '../data/models/village.dart';

class TerritoryEditorScreen extends StatefulWidget {
  const TerritoryEditorScreen({super.key});

  @override
  State<TerritoryEditorScreen> createState() => _TerritoryEditorScreenState();
}

class _TerritoryEditorScreenState extends State<TerritoryEditorScreen> {
  final _mapController = MapController();
  final _focusNode = FocusNode();

  late List<Village> _villages;

  // Multiple land polygons support
  List<List<LatLng>> _landPolygons = [];
  int _currentPolygonIndex = -1; // -1 = no polygon selected
  int? _selectedVertexIndex;
  int? _draggingIndex;
  bool _editingLand = true;

  // Undo stack
  final List<List<List<LatLng>>> _undoStack = [];

  @override
  void initState() {
    super.initState();
    _villages = _buildVillages();
    _loadData();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _mapController.dispose();
    super.dispose();
  }

  List<LatLng>? get _currentPolygon =>
      _currentPolygonIndex >= 0 && _currentPolygonIndex < _landPolygons.length
          ? _landPolygons[_currentPolygonIndex]
          : null;

  void _saveUndo() {
    _undoStack.add(_landPolygons.map((p) => List<LatLng>.from(p)).toList());
    if (_undoStack.length > 50) _undoStack.removeAt(0);
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    setState(() {
      _landPolygons = _undoStack.removeLast();
      if (_currentPolygonIndex >= _landPolygons.length) {
        _currentPolygonIndex = _landPolygons.isEmpty ? -1 : _landPolygons.length - 1;
      }
      _selectedVertexIndex = null;
    });
  }

  List<Village> _buildVillages() {
    return [
      Village(name: 'Constantinople', nationality: Nationality.byzantines, coordinates: const GeoCoordinate(41.0082, 28.9784), owner: 'byzantine'),
      Village(name: 'Bursa', nationality: Nationality.ottomans, coordinates: const GeoCoordinate(40.1826, 29.0665), owner: 'ottoman'),
      Village(name: 'Acre', nationality: Nationality.crusaders, coordinates: const GeoCoordinate(32.9226, 35.0690), owner: 'crusader'),
      Village(name: 'Tarnovo', nationality: Nationality.bulgaria, coordinates: const GeoCoordinate(43.0757, 25.6172), owner: 'bulgarian'),
      Village(name: 'Belgrade', nationality: Nationality.serbia, coordinates: const GeoCoordinate(44.7866, 20.4489), owner: 'serbian'),
      Village(name: 'Ani', nationality: Nationality.armenia, coordinates: const GeoCoordinate(40.5053, 43.5728), owner: 'armenian'),
      Village(name: 'Cairo', nationality: Nationality.mamluks, coordinates: const GeoCoordinate(30.0444, 31.2357), owner: 'mamluk'),
      Village(name: 'Thessaloniki', nationality: Nationality.byzantines, coordinates: const GeoCoordinate(40.6401, 22.9444), owner: 'byzantine'),
      Village(name: 'Nicaea', nationality: Nationality.byzantines, coordinates: const GeoCoordinate(40.4292, 29.7211), owner: 'byzantine'),
      Village(name: 'Konya', nationality: Nationality.ottomans, coordinates: const GeoCoordinate(37.8714, 32.4846), owner: 'ottoman'),
      Village(name: 'Ankara', nationality: Nationality.ottomans, coordinates: const GeoCoordinate(39.9334, 32.8597), owner: 'ottoman'),
      Village(name: 'Jerusalem', nationality: Nationality.crusaders, coordinates: const GeoCoordinate(31.7683, 35.2137), owner: 'crusader'),
      Village(name: 'Antioch', nationality: Nationality.crusaders, coordinates: const GeoCoordinate(36.2028, 36.1600), owner: 'crusader'),
      Village(name: 'Sofia', nationality: Nationality.bulgaria, coordinates: const GeoCoordinate(42.6977, 23.3219), owner: 'bulgarian'),
      Village(name: 'Nis', nationality: Nationality.serbia, coordinates: const GeoCoordinate(43.3209, 21.8954), owner: 'serbian'),
      Village(name: 'Van', nationality: Nationality.armenia, coordinates: const GeoCoordinate(38.4891, 43.4089), owner: 'armenian'),
      Village(name: 'Alexandria', nationality: Nationality.mamluks, coordinates: const GeoCoordinate(31.2001, 29.9187), owner: 'mamluk'),
      Village(name: 'Damascus', nationality: Nationality.mamluks, coordinates: const GeoCoordinate(33.5138, 36.2765), owner: 'mamluk'),
      Village(name: 'Smyrna', nationality: Nationality.byzantines, coordinates: const GeoCoordinate(38.4237, 27.1428), owner: 'neutral'),
      Village(name: 'Trebizond', nationality: Nationality.byzantines, coordinates: const GeoCoordinate(41.0027, 39.7168), owner: 'neutral'),
      Village(name: 'Sinope', nationality: Nationality.byzantines, coordinates: const GeoCoordinate(42.0231, 35.1531), owner: 'neutral'),
      Village(name: 'Edirne', nationality: Nationality.ottomans, coordinates: const GeoCoordinate(41.6771, 26.5557), owner: 'neutral'),
      Village(name: 'Erzurum', nationality: Nationality.armenia, coordinates: const GeoCoordinate(39.9043, 41.2679), owner: 'neutral'),
      Village(name: 'Athens', nationality: Nationality.byzantines, coordinates: const GeoCoordinate(37.9838, 23.7275), owner: 'neutral'),
      Village(name: 'Plovdiv', nationality: Nationality.bulgaria, coordinates: const GeoCoordinate(42.1354, 24.7453), owner: 'neutral'),
      Village(name: 'Skopje', nationality: Nationality.serbia, coordinates: const GeoCoordinate(41.9973, 21.4280), owner: 'neutral'),
      Village(name: 'Kars', nationality: Nationality.armenia, coordinates: const GeoCoordinate(40.6013, 43.0975), owner: 'neutral'),
      Village(name: 'Tripoli', nationality: Nationality.crusaders, coordinates: const GeoCoordinate(34.4367, 35.8497), owner: 'neutral'),
      Village(name: 'Aleppo', nationality: Nationality.mamluks, coordinates: const GeoCoordinate(36.2021, 37.1343), owner: 'neutral'),
      Village(name: 'Gaza', nationality: Nationality.mamluks, coordinates: const GeoCoordinate(31.5017, 34.4668), owner: 'neutral'),
      Village(name: 'Rhodes', nationality: Nationality.crusaders, coordinates: const GeoCoordinate(36.4349, 28.2176), owner: 'neutral'),
      Village(name: 'Crete', nationality: Nationality.byzantines, coordinates: const GeoCoordinate(35.2401, 24.8093), owner: 'neutral'),
      Village(name: 'Cyprus', nationality: Nationality.crusaders, coordinates: const GeoCoordinate(35.1264, 33.4299), owner: 'neutral'),
    ];
  }

  // Use app container for sandboxed macOS app
  static const _dataRoot = '/Users/appgea/Library/Containers/com.appgea.villagesTown/Data';
  static const _projectRoot = '/Users/appgea/Desktop/projects/appgea-apps/VillagesTown';

  Future<void> _loadData() async {
    // Load land polygons
    try {
      final file = File('$_dataRoot/land_boundary.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = json.decode(content);
        setState(() {
          if (data is List && data.isNotEmpty) {
            if (data[0] is List && data[0].isNotEmpty && data[0][0] is List) {
              // New format: array of polygons
              _landPolygons = data.map((poly) =>
                (poly as List).map((c) => LatLng(c[1] as double, c[0] as double)).toList()
              ).toList();
            } else {
              // Old format: single polygon
              _landPolygons = [data.map((c) => LatLng(c[1] as double, c[0] as double)).toList().cast<LatLng>()];
            }
            _currentPolygonIndex = 0;
          }
        });
      }
    } catch (e) {
      debugPrint('No land boundary found: $e');
    }

    // Load territories
    try {
      final file = File('$_dataRoot/territories.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = json.decode(content) as Map<String, dynamic>;
        setState(() {
          for (final village in _villages) {
            if (data.containsKey(village.name)) {
              final coords = data[village.name] as List;
              village.customTerritory = coords.map((c) => LatLng(c[1] as double, c[0] as double)).toList();
            }
          }
        });
      }
    } catch (e) {
      debugPrint('No territories found: $e');
    }
  }

  Future<void> _saveLandBoundary() async {
    final data = _landPolygons.map((poly) =>
      poly.map((p) => [p.longitude, p.latitude]).toList()
    ).toList();
    final file = File('$_dataRoot/land_boundary.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved ${_landPolygons.length} land polygons')),
      );
    }
  }

  Future<void> _saveAllTerritories() async {
    final data = <String, dynamic>{};
    for (final village in _villages) {
      if (village.customTerritory != null && village.customTerritory!.length >= 3) {
        data[village.name] = village.customTerritory!.map((p) => [p.longitude, p.latitude]).toList();
      }
    }
    final jsonContent = const JsonEncoder.withIndent('  ').convert(data);

    // Save to app container (sandboxed)
    final file = File('$_dataRoot/territories.json');
    await file.writeAsString(jsonContent);

    // Try to save to assets folder for the game (may fail if sandboxed)
    try {
      final assetsFile = File('$_projectRoot/assets/territories.json');
      await assetsFile.writeAsString(jsonContent);
    } catch (e) {
      debugPrint('Could not save to assets (sandbox): $e');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved ${data.length} territories')),
      );
    }
  }

  void _createNewPolygon() {
    _saveUndo();
    setState(() {
      _landPolygons.add([]);
      _currentPolygonIndex = _landPolygons.length - 1;
      _selectedVertexIndex = null;
    });
  }

  void _deleteCurrentPolygon() {
    if (_currentPolygon == null) return;
    _saveUndo();
    setState(() {
      _landPolygons.removeAt(_currentPolygonIndex);
      _currentPolygonIndex = _landPolygons.isEmpty ? -1 : math.min(_currentPolygonIndex, _landPolygons.length - 1);
      _selectedVertexIndex = null;
    });
  }

  void _generateAllTerritories() {
    if (_landPolygons.isEmpty || _landPolygons.every((p) => p.length < 3)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draw at least one land polygon first')),
      );
      return;
    }

    // Clear existing territories
    for (final village in _villages) {
      village.customTerritory = null;
    }

    // First pass: map each land polygon to the cities it contains
    final landToCities = <int, List<Village>>{};
    for (int i = 0; i < _landPolygons.length; i++) {
      final landPoly = _landPolygons[i];
      if (landPoly.length < 3) continue;
      landToCities[i] = [];
      for (final village in _villages) {
        final cityPoint = LatLng(village.coordinates.latitude, village.coordinates.longitude);
        if (_isPointInPolygon(cityPoint, landPoly)) {
          landToCities[i]!.add(village);
        }
      }
    }

    // Count assigned cities
    int totalAssigned = 0;
    for (final entry in landToCities.entries) {
      totalAssigned += entry.value.length;
    }

    if (totalAssigned == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No cities found inside ${_landPolygons.length} land polygons! Check polygon winding.')),
      );
      return;
    }

    // Clear pair biases so we get new borders each generation
    _pairBiases.clear();

    setState(() {
      // Process each land polygon
      for (final entry in landToCities.entries) {
        final originalLandPoly = _landPolygons[entry.key];
        final citiesInLand = entry.value;

        if (citiesInLand.isEmpty) continue;

        if (citiesInLand.length == 1) {
          // Single city island: use land polygon directly
          citiesInLand[0].customTerritory = List<LatLng>.from(originalLandPoly);
        } else {
          // Multiple cities: Voronoi only against cities in SAME land (not all cities)
          for (final village in citiesInLand) {
            village.customTerritory = _computeVoronoiInLand(village, citiesInLand, originalLandPoly);
          }
        }
      }

      // Cities not in any land polygon get plain Voronoi
      for (final village in _villages) {
        village.customTerritory ??= _computeVoronoiCell(village);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Generated territories for $totalAssigned cities in ${landToCities.length} land masses')),
    );

    _saveAllTerritories();
  }

  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    bool inside = false;
    int j = polygon.length - 1;
    for (int i = 0; i < polygon.length; i++) {
      if (((polygon[i].latitude > point.latitude) != (polygon[j].latitude > point.latitude)) &&
          (point.longitude < (polygon[j].longitude - polygon[i].longitude) *
              (point.latitude - polygon[i].latitude) /
              (polygon[j].latitude - polygon[i].latitude) +
              polygon[i].longitude)) {
        inside = !inside;
      }
      j = i;
    }
    return inside;
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    if (!_editingLand || _currentPolygon == null) return;

    _saveUndo();
    setState(() {
      if (_selectedVertexIndex != null) {
        // Insert after selected vertex
        _currentPolygon!.insert(_selectedVertexIndex! + 1, point);
        _selectedVertexIndex = _selectedVertexIndex! + 1;
      } else {
        // Add to end
        _currentPolygon!.add(point);
        _selectedVertexIndex = _currentPolygon!.length - 1;
      }
    });
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if ((event.logicalKey == LogicalKeyboardKey.delete ||
           event.logicalKey == LogicalKeyboardKey.backspace) &&
          _editingLand && _selectedVertexIndex != null && _currentPolygon != null) {
        _saveUndo();
        setState(() {
          _currentPolygon!.removeAt(_selectedVertexIndex!);
          _selectedVertexIndex = _currentPolygon!.isEmpty ? null :
              math.min(_selectedVertexIndex!, _currentPolygon!.length - 1);
        });
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        setState(() => _selectedVertexIndex = null);
      } else if (event.logicalKey == LogicalKeyboardKey.keyZ &&
                 (HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed)) {
        _undo();
      }
    }
  }

  // ========== VORONOI + CLIPPING ==========

  /// Jitter all vertices of a polygon randomly
  List<LatLng> _jitterPolygon(List<LatLng> polygon, math.Random random, double amount) {
    return polygon.map((p) {
      final latOffset = (random.nextDouble() - 0.5) * amount;
      final lngOffset = (random.nextDouble() - 0.5) * amount;
      return LatLng(p.latitude + latOffset, p.longitude + lngOffset);
    }).toList();
  }

  /// Add organic detail to land polygon coastlines
  List<LatLng> _addCoastlineDetail(List<LatLng> polygon, math.Random random) {
    const maxSegment = 0.12; // ~12km between points
    const noiseAmount = 0.04; // ~4km perpendicular offset

    final result = <LatLng>[];
    for (int i = 0; i < polygon.length; i++) {
      final p1 = polygon[i];
      final p2 = polygon[(i + 1) % polygon.length];

      result.add(p1);

      final dx = p2.longitude - p1.longitude;
      final dy = p2.latitude - p1.latitude;
      final dist = math.sqrt(dx * dx + dy * dy);

      if (dist > maxSegment) {
        final segments = (dist / maxSegment).ceil();
        for (int j = 1; j < segments; j++) {
          final t = j / segments;
          // Perpendicular offset for natural coastline wiggle
          final perpX = -dy / dist;
          final perpY = dx / dist;
          final offset = (random.nextDouble() - 0.5) * noiseAmount;

          result.add(LatLng(
            p1.latitude + dy * t + perpY * offset,
            p1.longitude + dx * t + perpX * offset,
          ));
        }
      }
    }
    return result;
  }

  /// Simple Voronoi within land - guaranteed to fill with no gaps
  List<LatLng> _computeVoronoiWithinLand(Village site, List<LatLng> landPoly) {
    var polygon = landPoly.map((p) => _Point(p.longitude, p.latitude)).toList();
    final sitePoint = _Point(site.coordinates.longitude, site.coordinates.latitude);

    for (final other in _villages) {
      if (other.id == site.id) continue;
      final otherPoint = _Point(other.coordinates.longitude, other.coordinates.latitude);
      polygon = _clipToHalfPlane(polygon, sitePoint, otherPoint);
      if (polygon.isEmpty) break;
    }

    return polygon.map((p) => LatLng(p.y, p.x)).toList();
  }

  /// Voronoi clipped only against cities in the SAME land mass
  /// This prevents Istanbul from being clipped against Constanta etc.
  List<LatLng> _computeVoronoiInLand(Village site, List<Village> citiesInLand, List<LatLng> landPoly) {
    var polygon = landPoly.map((p) => _Point(p.longitude, p.latitude)).toList();
    final sitePoint = _Point(site.coordinates.longitude, site.coordinates.latitude);

    // Only clip against cities in the SAME land mass
    for (final other in citiesInLand) {
      if (other.id == site.id) continue;
      final otherPoint = _Point(other.coordinates.longitude, other.coordinates.latitude);
      polygon = _clipToHalfPlane(polygon, sitePoint, otherPoint);
      if (polygon.isEmpty) break;
    }

    return polygon.map((p) => LatLng(p.y, p.x)).toList();
  }

  /// Assign territory by finding closest city for each boundary point
  void _assignTerritoryByClosestCity(List<Village> cities, List<LatLng> landPoly, math.Random random) {
    // Densify the land polygon - add many points along edges
    final densePoints = <LatLng>[];
    const segmentLength = 0.02; // ~2km between points

    for (int i = 0; i < landPoly.length; i++) {
      final p1 = landPoly[i];
      final p2 = landPoly[(i + 1) % landPoly.length];

      densePoints.add(p1);

      final dx = p2.longitude - p1.longitude;
      final dy = p2.latitude - p1.latitude;
      final dist = math.sqrt(dx * dx + dy * dy);

      if (dist > segmentLength) {
        final segments = (dist / segmentLength).ceil();
        for (int j = 1; j < segments; j++) {
          final t = j / segments;
          densePoints.add(LatLng(
            p1.latitude + dy * t,
            p1.longitude + dx * t,
          ));
        }
      }
    }

    // For each point, find closest city (with random bias for variation)
    final cityBiases = <String, double>{};
    for (final city in cities) {
      cityBiases[city.name] = 1.0 + (random.nextDouble() - 0.5) * 0.4; // 0.8 to 1.2 distance multiplier
    }

    final pointAssignments = <LatLng, Village>{};
    for (final point in densePoints) {
      Village? closest;
      double minDist = double.infinity;

      for (final city in cities) {
        final dx = point.longitude - city.coordinates.longitude;
        final dy = point.latitude - city.coordinates.latitude;
        final dist = math.sqrt(dx * dx + dy * dy) * cityBiases[city.name]!;

        if (dist < minDist) {
          minDist = dist;
          closest = city;
        }
      }

      if (closest != null) {
        pointAssignments[point] = closest;
      }
    }

    // Build territory for each city by collecting consecutive points
    for (final city in cities) {
      final territoryPoints = <LatLng>[];

      // Find all points assigned to this city, in order around the polygon
      for (int i = 0; i < densePoints.length; i++) {
        final point = densePoints[i];
        if (pointAssignments[point] == city) {
          territoryPoints.add(point);
        } else if (territoryPoints.isNotEmpty) {
          // We've left this city's region, add border point from next city
          // This ensures territories meet at exact same points
          final prevPoint = densePoints[(i - 1) % densePoints.length];
          final nextAssigned = pointAssignments[point];
          if (nextAssigned != null) {
            // Add midpoint between last owned point and first non-owned as border
            territoryPoints.add(LatLng(
              (prevPoint.latitude + point.latitude) / 2,
              (prevPoint.longitude + point.longitude) / 2,
            ));
          }
        }
      }

      // Handle wrap-around: check if first and last points connect
      if (territoryPoints.isNotEmpty) {
        // Add city center to create proper polygon interior
        territoryPoints.add(LatLng(city.coordinates.latitude, city.coordinates.longitude));
      }

      city.customTerritory = territoryPoints.length >= 3 ? territoryPoints : null;
    }
  }

  // Store computed biases for city pairs to ensure consistent borders
  final Map<String, double> _pairBiases = {};

  /// Compute territory with randomized but gap-free borders (no curves)
  List<LatLng> _computeRandomizedTerritoryNoCurves(Village site, List<LatLng> landPoly, math.Random random) {
    // Start with land polygon
    var polygon = landPoly.map((p) => _Point(p.longitude, p.latitude)).toList();
    final sitePoint = _Point(site.coordinates.longitude, site.coordinates.latitude);

    // Clip by randomized half-planes - but use CONSISTENT bias for each city pair
    for (final other in _villages) {
      if (other.id == site.id) continue;
      final otherPoint = _Point(other.coordinates.longitude, other.coordinates.latitude);

      // Get or create consistent bias for this city pair
      final pairKey = _getPairKey(site.name, other.name);
      if (!_pairBiases.containsKey(pairKey)) {
        _pairBiases[pairKey] = (random.nextDouble() - 0.5) * 0.35; // -0.175 to +0.175 shift
      }

      // Use bias in correct direction
      final bias = site.name.compareTo(other.name) < 0
          ? _pairBiases[pairKey]!
          : -_pairBiases[pairKey]!;

      polygon = _clipToRandomizedHalfPlane(polygon, sitePoint, otherPoint, bias, random);
      if (polygon.isEmpty) break;
    }

    // Return straight borders - no curves to avoid gaps
    return polygon.map((p) => LatLng(p.y, p.x)).toList();
  }

  /// Get consistent key for a pair of cities (order-independent)
  String _getPairKey(String a, String b) {
    return a.compareTo(b) < 0 ? '$a-$b' : '$b-$a';
  }

  /// Clip polygon by a randomized half-plane (not exactly at midpoint)
  List<_Point> _clipToRandomizedHalfPlane(List<_Point> polygon, _Point site, _Point other, double bias, math.Random random) {
    if (polygon.isEmpty) return [];

    // Midpoint shifted by bias (0 = midpoint, negative = closer to site, positive = closer to other)
    final t = 0.5 + bias;
    final dividePoint = _Point(
      site.x + (other.x - site.x) * t,
      site.y + (other.y - site.y) * t,
    );
    final nx = site.x - other.x, ny = site.y - other.y;
    final result = <_Point>[];

    for (int i = 0; i < polygon.length; i++) {
      final current = polygon[i], next = polygon[(i + 1) % polygon.length];
      final currentInside = (current.x - dividePoint.x) * nx + (current.y - dividePoint.y) * ny >= 0;
      final nextInside = (next.x - dividePoint.x) * nx + (next.y - dividePoint.y) * ny >= 0;

      if (currentInside) {
        result.add(current);
        if (!nextInside) {
          final inter = _intersectHalfPlane(current, next, dividePoint, nx, ny);
          if (inter != null) result.add(inter);
        }
      } else if (nextInside) {
        final inter = _intersectHalfPlane(current, next, dividePoint, nx, ny);
        if (inter != null) result.add(inter);
      }
    }
    return result;
  }

  /// Add organic curves to polygon edges
  List<LatLng> _addOrganicCurves(List<LatLng> polygon, math.Random random) {
    if (polygon.length < 3) return polygon;

    final result = <LatLng>[];
    for (int i = 0; i < polygon.length; i++) {
      final p1 = polygon[i];
      final p2 = polygon[(i + 1) % polygon.length];

      result.add(p1);

      final dx = p2.longitude - p1.longitude;
      final dy = p2.latitude - p1.latitude;
      final dist = math.sqrt(dx * dx + dy * dy);

      if (dist > 0.1) { // Only add curves to longer edges
        // Add 2-4 intermediate points with random curves
        final numPoints = 2 + random.nextInt(3);
        for (int j = 1; j <= numPoints; j++) {
          final t = j / (numPoints + 1);
          final perpX = -dy / dist;
          final perpY = dx / dist;
          // Large random offset for organic look
          final offset = (random.nextDouble() - 0.5) * 0.15;

          result.add(LatLng(
            p1.latitude + dy * t + perpY * offset,
            p1.longitude + dx * t + perpX * offset,
          ));
        }
      }
    }
    return result;
  }

  /// Add BIG chunky noise visible at continental zoom
  List<LatLng> _addNoisyBorders(List<LatLng> polygon, List<LatLng> landPoly, math.Random random) {
    if (polygon.length < 3) return polygon;

    const segmentSize = 0.3; // ~30km between points
    const noiseAmount = 0.12; // ~12km random offset

    final result = <LatLng>[];
    for (int i = 0; i < polygon.length; i++) {
      final p1 = polygon[i];
      final p2 = polygon[(i + 1) % polygon.length];

      // Add p1 with noise applied to the VERTEX itself
      final p1Offset = (random.nextDouble() - 0.5) * noiseAmount * 0.5;
      result.add(LatLng(
        p1.latitude + p1Offset,
        p1.longitude + p1Offset,
      ));

      final dx = p2.longitude - p1.longitude;
      final dy = p2.latitude - p1.latitude;
      final dist = math.sqrt(dx * dx + dy * dy);

      // Always add at least one intermediate point with noise
      final segments = math.max(2, (dist / segmentSize).ceil());
      for (int j = 1; j < segments; j++) {
        final t = j / segments;
        // Perpendicular offset for dramatic border curves
        final perpX = -dy / dist;
        final perpY = dx / dist;
        final offset = (random.nextDouble() - 0.5) * noiseAmount;

        result.add(LatLng(
          p1.latitude + dy * t + perpY * offset,
          p1.longitude + dx * t + perpX * offset,
        ));
      }
    }
    return result;
  }

  String _edgeKey(LatLng a, LatLng b) {
    // Normalize so smaller point comes first
    if (a.latitude < b.latitude || (a.latitude == b.latitude && a.longitude < b.longitude)) {
      return '${a.latitude.toStringAsFixed(4)},${a.longitude.toStringAsFixed(4)}-${b.latitude.toStringAsFixed(4)},${b.longitude.toStringAsFixed(4)}';
    }
    return '${b.latitude.toStringAsFixed(4)},${b.longitude.toStringAsFixed(4)}-${a.latitude.toStringAsFixed(4)},${a.longitude.toStringAsFixed(4)}';
  }

  /// Check if edge p1-p2 lies on any edge of the land polygon
  bool _isEdgeOnLandBoundary(LatLng p1, LatLng p2, List<LatLng> landPoly) {
    const epsilon = 0.0001; // ~10m tolerance

    for (int i = 0; i < landPoly.length; i++) {
      final a = landPoly[i];
      final b = landPoly[(i + 1) % landPoly.length];

      // Check if both p1 and p2 lie on segment a-b
      if (_isPointOnSegment(p1, a, b, epsilon) && _isPointOnSegment(p2, a, b, epsilon)) {
        return true;
      }
    }
    return false;
  }

  /// Check if point p lies on segment a-b within tolerance
  bool _isPointOnSegment(LatLng p, LatLng a, LatLng b, double epsilon) {
    // Check if p is within bounding box of a-b (with tolerance)
    final minLat = math.min(a.latitude, b.latitude) - epsilon;
    final maxLat = math.max(a.latitude, b.latitude) + epsilon;
    final minLng = math.min(a.longitude, b.longitude) - epsilon;
    final maxLng = math.max(a.longitude, b.longitude) + epsilon;

    if (p.latitude < minLat || p.latitude > maxLat || p.longitude < minLng || p.longitude > maxLng) {
      return false;
    }

    // Check distance from point to line
    final dx = b.longitude - a.longitude;
    final dy = b.latitude - a.latitude;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < epsilon) return true; // a and b are same point

    // Distance from p to line a-b
    final dist = ((p.latitude - a.latitude) * dx - (p.longitude - a.longitude) * dy).abs() / len;
    return dist < epsilon;
  }

  List<LatLng> _computeVoronoiCell(Village site) {
    const minLat = 28.0, maxLat = 48.0, minLng = 12.0, maxLng = 48.0;
    var polygon = [_Point(minLng, minLat), _Point(maxLng, minLat), _Point(maxLng, maxLat), _Point(minLng, maxLat)];
    final sitePoint = _Point(site.coordinates.longitude, site.coordinates.latitude);

    for (final other in _villages) {
      if (other.id == site.id) continue;
      final otherPoint = _Point(other.coordinates.longitude, other.coordinates.latitude);
      polygon = _clipToHalfPlane(polygon, sitePoint, otherPoint);
      if (polygon.isEmpty) break;
    }
    return polygon.map((p) => LatLng(p.y, p.x)).toList();
  }

  List<_Point> _clipToHalfPlane(List<_Point> polygon, _Point site, _Point other) {
    if (polygon.isEmpty) return [];
    final mid = _Point((site.x + other.x) / 2, (site.y + other.y) / 2);
    final nx = site.x - other.x, ny = site.y - other.y;
    final result = <_Point>[];

    for (int i = 0; i < polygon.length; i++) {
      final current = polygon[i], next = polygon[(i + 1) % polygon.length];
      final currentInside = (current.x - mid.x) * nx + (current.y - mid.y) * ny >= 0;
      final nextInside = (next.x - mid.x) * nx + (next.y - mid.y) * ny >= 0;

      if (currentInside) {
        result.add(current);
        if (!nextInside) {
          final inter = _intersectHalfPlane(current, next, mid, nx, ny);
          if (inter != null) result.add(inter);
        }
      } else if (nextInside) {
        final inter = _intersectHalfPlane(current, next, mid, nx, ny);
        if (inter != null) result.add(inter);
      }
    }
    return result;
  }

  _Point? _intersectHalfPlane(_Point p1, _Point p2, _Point mid, double nx, double ny) {
    final dx = p2.x - p1.x, dy = p2.y - p1.y;
    final denom = dx * nx + dy * ny;
    if (denom.abs() < 1e-10) return null;
    final t = ((mid.x - p1.x) * nx + (mid.y - p1.y) * ny) / denom;
    if (t < 0 || t > 1) return null;
    return _Point(p1.x + t * dx, p1.y + t * dy);
  }

  List<LatLng> _clipPolygonToLand(List<LatLng> subject, List<LatLng> clipPoly) {
    if (clipPoly.length < 3 || subject.length < 3) return subject;

    var output = subject.map((p) => _Point(p.longitude, p.latitude)).toList();

    for (int i = 0; i < clipPoly.length; i++) {
      if (output.isEmpty) break;
      final input = output;
      output = [];

      final edgeStart = clipPoly[i];
      final edgeEnd = clipPoly[(i + 1) % clipPoly.length];
      final ex = edgeEnd.longitude - edgeStart.longitude;
      final ey = edgeEnd.latitude - edgeStart.latitude;

      for (int j = 0; j < input.length; j++) {
        final current = input[j];
        final next = input[(j + 1) % input.length];

        final currentInside = _isLeft(edgeStart, ex, ey, current);
        final nextInside = _isLeft(edgeStart, ex, ey, next);

        if (currentInside) {
          output.add(current);
          if (!nextInside) {
            final inter = _intersectEdge(current, next, edgeStart, edgeEnd);
            if (inter != null) output.add(inter);
          }
        } else if (nextInside) {
          final inter = _intersectEdge(current, next, edgeStart, edgeEnd);
          if (inter != null) output.add(inter);
        }
      }
    }

    return output.map((p) => LatLng(p.y, p.x)).toList();
  }

  bool _isLeft(LatLng edgeStart, double ex, double ey, _Point p) {
    return (p.x - edgeStart.longitude) * ey - (p.y - edgeStart.latitude) * ex >= 0;
  }

  _Point? _intersectEdge(_Point p1, _Point p2, LatLng e1, LatLng e2) {
    final dx1 = p2.x - p1.x, dy1 = p2.y - p1.y;
    final dx2 = e2.longitude - e1.longitude, dy2 = e2.latitude - e1.latitude;
    final denom = dx1 * dy2 - dy1 * dx2;
    if (denom.abs() < 1e-10) return null;
    final t = ((e1.longitude - p1.x) * dy2 - (e1.latitude - p1.y) * dx2) / denom;
    if (t < 0 || t > 1) return null;
    return _Point(p1.x + t * dx1, p1.y + t * dy1);
  }

  // ========== BUILD UI ==========

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_editingLand ? 'Edit Land Boundaries' : 'Territory Editor'),
          actions: [
            // Mode toggle
            ToggleButtons(
              isSelected: [_editingLand, !_editingLand],
              onPressed: (i) => setState(() {
                _editingLand = i == 0;
                _selectedVertexIndex = null;
              }),
              children: const [
                Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Land')),
                Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('View')),
              ],
            ),
            const SizedBox(width: 8),
            if (_editingLand) ...[
              IconButton(
                icon: const Icon(Icons.undo),
                tooltip: 'Undo (Cmd+Z)',
                onPressed: _undoStack.isNotEmpty ? _undo : null,
              ),
              IconButton(
                icon: const Icon(Icons.save),
                tooltip: 'Save land',
                onPressed: _saveLandBoundary,
              ),
            ] else ...[
              IconButton(
                icon: const Icon(Icons.auto_fix_high),
                tooltip: 'Generate All Territories',
                onPressed: _generateAllTerritories,
              ),
              IconButton(
                icon: const Icon(Icons.save),
                tooltip: 'Save territories',
                onPressed: _saveAllTerritories,
              ),
            ],
            const SizedBox(width: 8),
          ],
        ),
        body: Row(
          children: [
            // Side panel for polygon management (only in land edit mode)
            if (_editingLand)
              Container(
                width: 200,
                color: Colors.grey[100],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: ElevatedButton.icon(
                        onPressed: _createNewPolygon,
                        icon: const Icon(Icons.add),
                        label: const Text('New Land Mass'),
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _landPolygons.length,
                        itemBuilder: (context, i) {
                          final isSelected = i == _currentPolygonIndex;
                          final poly = _landPolygons[i];
                          return ListTile(
                            selected: isSelected,
                            selectedTileColor: Colors.blue[100],
                            leading: Icon(
                              Icons.terrain,
                              color: isSelected ? Colors.blue : Colors.grey,
                            ),
                            title: Text('Land ${i + 1}'),
                            subtitle: Text('${poly.length} points'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              onPressed: () {
                                setState(() => _currentPolygonIndex = i);
                                _deleteCurrentPolygon();
                              },
                            ),
                            onTap: () => setState(() {
                              _currentPolygonIndex = i;
                              _selectedVertexIndex = null;
                            }),
                          );
                        },
                      ),
                    ),
                    if (_currentPolygon != null) ...[
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          'Selected: Land ${_currentPolygonIndex + 1}\n'
                          '${_currentPolygon!.length} vertices\n'
                          '${_selectedVertexIndex != null ? "Vertex #${_selectedVertexIndex! + 1} selected" : "No vertex selected"}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            // Map
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: const LatLng(38.0, 32.0),
                        initialZoom: 5,
                        onTap: _onMapTap,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.territory_editor',
                        ),
                        // All land polygons
                        PolygonLayer(polygons: _buildLandPolygons()),
                        // Territories (only when not editing land)
                        if (!_editingLand) PolygonLayer(polygons: _buildTerritoryPolygons()),
                        // Vertices for current polygon (when editing)
                        if (_editingLand && _currentPolygon != null)
                          MarkerLayer(markers: _buildVertexMarkers()),
                        // Village markers
                        if (!_editingLand) MarkerLayer(markers: _buildVillageMarkers()),
                      ],
                    ),
                  ),
                  _buildStatusBar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Polygon> _buildLandPolygons() {
    return List.generate(_landPolygons.length, (i) {
      final poly = _landPolygons[i];
      if (poly.length < 3) return null;
      final isSelected = i == _currentPolygonIndex && _editingLand;
      return Polygon(
        points: poly,
        color: isSelected ? Colors.green.withValues(alpha: 0.3) : Colors.green.withValues(alpha: 0.1),
        borderColor: isSelected ? Colors.green : Colors.brown.withValues(alpha: 0.5),
        borderStrokeWidth: isSelected ? 3 : 1,
      );
    }).whereType<Polygon>().toList();
  }

  List<Polygon> _buildTerritoryPolygons() {
    final polygons = <Polygon>[];
    for (final village in _villages) {
      final color = village.nationality.color;
      List<LatLng>? points = village.customTerritory;

      if (points == null || points.length < 3) {
        points = _computeVoronoiCell(village);
        if (points.length < 3) continue;
      }

      polygons.add(Polygon(
        points: points,
        color: color.withValues(alpha: 0.25),
        borderColor: color.withValues(alpha: 0.6),
        borderStrokeWidth: 1.5,
      ));
    }
    return polygons;
  }

  List<Marker> _buildVertexMarkers() {
    if (_currentPolygon == null) return [];
    return List.generate(_currentPolygon!.length, (i) {
      final isSelected = _selectedVertexIndex == i;
      return Marker(
        point: _currentPolygon![i],
        width: 24,
        height: 24,
        child: GestureDetector(
          onTap: () => setState(() => _selectedVertexIndex = i),
          onSecondaryTap: () {
            _saveUndo();
            setState(() {
              _currentPolygon!.removeAt(i);
              _selectedVertexIndex = null;
            });
          },
          onPanStart: (_) {
            _draggingIndex = i;
            setState(() => _selectedVertexIndex = i);
          },
          onPanUpdate: (details) {
            if (_draggingIndex == i) {
              final renderBox = context.findRenderObject() as RenderBox;
              final localPos = renderBox.globalToLocal(details.globalPosition);
              final point = _mapController.camera.pointToLatLng(math.Point(localPos.dx, localPos.dy - kToolbarHeight));
              setState(() => _currentPolygon![i] = point);
            }
          },
          onPanEnd: (_) => _draggingIndex = null,
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Colors.orange : Colors.green[700],
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: Text(
                '${i + 1}',
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      );
    });
  }

  List<Marker> _buildVillageMarkers() {
    return _villages.map((village) {
      final hasCustom = village.customTerritory != null;
      return Marker(
        point: LatLng(village.coordinates.latitude, village.coordinates.longitude),
        width: 80,
        height: 20,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: hasCustom ? Colors.green[700] : village.nationality.color,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            village.name,
            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }).toList();
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[200],
      child: Row(
        children: [
          if (_editingLand) ...[
            Text('${_landPolygons.length} land masses'),
            const SizedBox(width: 16),
            if (_currentPolygon != null)
              Text(_selectedVertexIndex != null
                  ? 'Click map to insert after vertex #${_selectedVertexIndex! + 1}'
                  : 'Click map to add point | Select vertex to insert after it')
            else
              const Text('Create a new land mass to start'),
          ] else ...[
            Text('${_villages.where((v) => v.customTerritory != null).length}/${_villages.length} territories'),
            const SizedBox(width: 16),
            const Text('Click "Generate All" to compute from land boundaries'),
          ],
        ],
      ),
    );
  }
}

class _Point {
  final double x, y;
  const _Point(this.x, this.y);
}
