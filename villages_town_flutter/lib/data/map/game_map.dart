import 'dart:ui';
import '../models/tile.dart';
import '../models/unit.dart';
import '../models/village.dart';

abstract class GameMap {
  Size get size;
  List<Village> get villages;
  set villages(List<Village> value);
  List<List<Tile>> get tiles;
  List<Unit> get units;
  set units(List<Unit> value);

  Tile? getTile(int x, int y);
  void updateTile(int x, int y, Tile tile);
  Village? getVillageAt(int x, int y);
  List<Unit> getUnitsAt(int x, int y);
  Offset? findEmptyAdjacentTile(Offset center);
}
