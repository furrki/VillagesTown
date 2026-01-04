import '../models/village.dart';
import 'game_map.dart';

class VirtualMap implements GameMap {
  @override
  List<Village> villages;

  VirtualMap({
    required this.villages,
  });
}
