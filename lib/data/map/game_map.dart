import '../models/village.dart';

abstract class GameMap {
  List<Village> get villages;
  set villages(List<Village> value);
}
