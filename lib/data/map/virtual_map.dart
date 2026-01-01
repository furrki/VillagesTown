import 'dart:math';
import 'dart:ui';
import '../models/resource.dart';
import '../models/terrain.dart';
import '../models/tile.dart';
import '../models/unit.dart';
import '../models/village.dart';
import 'game_map.dart';

class VirtualMap implements GameMap {
  @override
  final Size size;

  @override
  List<Village> villages;

  @override
  List<List<Tile>> tiles;

  @override
  List<Unit> units;

  VirtualMap({
    required this.size,
    required this.villages,
    List<Unit>? units,
  })  : units = units ?? [],
        tiles = _generateTiles(size);

  static List<List<Tile>> _generateTiles(Size size) {
    final random = Random();
    final tiles = <List<Tile>>[];

    for (var y = 0; y < size.height.toInt(); y++) {
      final row = <Tile>[];
      for (var x = 0; x < size.width.toInt(); x++) {
        // Edge tiles are more likely to be coast
        final isEdge = x == 0 || y == 0 || x == size.width.toInt() - 1 || y == size.height.toInt() - 1;

        Terrain terrain;
        if (isEdge && random.nextDouble() < 0.6) {
          terrain = Terrain.coast;
        } else {
          final roll = random.nextDouble();
          if (roll < 0.4) {
            terrain = Terrain.plains;
          } else if (roll < 0.6) {
            terrain = Terrain.forest;
          } else if (roll < 0.75) {
            terrain = Terrain.hills;
          } else if (roll < 0.85) {
            terrain = Terrain.mountains;
          } else if (roll < 0.92) {
            terrain = Terrain.river;
          } else {
            terrain = Terrain.coast;
          }
        }

        row.add(Tile(
          coordinates: Offset(x.toDouble(), y.toDouble()),
          terrain: terrain,
        ));
      }
      tiles.add(row);
    }

    // Place strategic resources (8-12 iron/gold)
    final resourceCount = 8 + random.nextInt(5);
    for (var i = 0; i < resourceCount; i++) {
      final x = random.nextInt(size.width.toInt());
      final y = random.nextInt(size.height.toInt());
      final resource = random.nextBool() ? Resource.iron : Resource.gold;
      tiles[y][x] = tiles[y][x].copyWith(strategicResource: resource);
    }

    return tiles;
  }

  @override
  Tile? getTile(int x, int y) {
    if (x < 0 || y < 0 || x >= size.width.toInt() || y >= size.height.toInt()) {
      return null;
    }
    return tiles[y][x];
  }

  @override
  void updateTile(int x, int y, Tile tile) {
    if (x >= 0 && y >= 0 && x < size.width.toInt() && y < size.height.toInt()) {
      tiles[y][x] = tile;
    }
  }

  @override
  Village? getVillageAt(int x, int y) {
    return villages.cast<Village?>().firstWhere(
          (v) => v!.coordinates.dx.toInt() == x && v.coordinates.dy.toInt() == y,
          orElse: () => null,
        );
  }

  @override
  List<Unit> getUnitsAt(int x, int y) {
    return units
        .where((u) => u.coordinates.dx.toInt() == x && u.coordinates.dy.toInt() == y)
        .toList();
  }

  @override
  Offset? findEmptyAdjacentTile(Offset center) {
    final directions = [
      const Offset(0, -1),
      const Offset(1, 0),
      const Offset(0, 1),
      const Offset(-1, 0),
      const Offset(1, -1),
      const Offset(1, 1),
      const Offset(-1, 1),
      const Offset(-1, -1),
    ];

    for (final dir in directions) {
      final newX = (center.dx + dir.dx).toInt();
      final newY = (center.dy + dir.dy).toInt();
      final tile = getTile(newX, newY);
      if (tile != null && tile.isEmpty && tile.terrain.canBuildOn) {
        return Offset(newX.toDouble(), newY.toDouble());
      }
    }
    return null;
  }
}
