import 'dart:ui';
import 'resource.dart';
import 'terrain.dart';

class Tile {
  final Offset coordinates;
  final Terrain terrain;
  final Resource? strategicResource;
  bool explored;
  String? owner;

  Tile({
    required this.coordinates,
    required this.terrain,
    this.strategicResource,
    this.explored = false,
    this.owner,
  });

  bool get isEmpty => owner == null && strategicResource == null;
  int get movementCost => terrain.movementCost;
  double get defenseBonus => terrain.defenseBonus;

  Tile copyWith({
    Offset? coordinates,
    Terrain? terrain,
    Resource? strategicResource,
    bool? explored,
    String? owner,
  }) {
    return Tile(
      coordinates: coordinates ?? this.coordinates,
      terrain: terrain ?? this.terrain,
      strategicResource: strategicResource ?? this.strategicResource,
      explored: explored ?? this.explored,
      owner: owner ?? this.owner,
    );
  }
}
