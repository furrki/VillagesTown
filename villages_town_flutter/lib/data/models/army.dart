import 'dart:math';
import 'dart:ui';
import 'package:uuid/uuid.dart';
import 'unit.dart';
import 'unit_type.dart';

class Army {
  final String id;
  String name;
  List<Unit> units;
  String owner;
  String? stationedAt; // Village ID
  String? destination;
  int turnsUntilArrival;
  String? origin;

  Army({
    String? id,
    required this.name,
    required this.units,
    required this.owner,
    this.stationedAt,
    this.destination,
    this.turnsUntilArrival = 0,
    this.origin,
  }) : id = id ?? const Uuid().v4();

  bool get isMarching => destination != null && turnsUntilArrival > 0;

  int get totalAttack => units.fold(0, (sum, u) => sum + u.attack);
  int get totalDefense => units.fold(0, (sum, u) => sum + u.defense);
  int get totalHP => units.fold(0, (sum, u) => sum + u.currentHP);
  int get strength => totalAttack + totalDefense + (totalHP ~/ 10);
  int get unitCount => units.length;

  UnitType? get primaryUnitType {
    if (units.isEmpty) return null;
    final counts = <UnitType, int>{};
    for (final u in units) {
      counts[u.unitType] = (counts[u.unitType] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  String get emoji => primaryUnitType?.emoji ?? '⚔️';

  Army copyWith({
    String? id,
    String? name,
    List<Unit>? units,
    String? owner,
    String? stationedAt,
    String? destination,
    int? turnsUntilArrival,
    String? origin,
  }) {
    return Army(
      id: id ?? this.id,
      name: name ?? this.name,
      units: units ?? List.from(this.units),
      owner: owner ?? this.owner,
      stationedAt: stationedAt ?? this.stationedAt,
      destination: destination ?? this.destination,
      turnsUntilArrival: turnsUntilArrival ?? this.turnsUntilArrival,
      origin: origin ?? this.origin,
    );
  }

  void addUnits(List<Unit> newUnits) {
    units.addAll(newUnits);
  }

  void removeDeadUnits() {
    units.removeWhere((u) => !u.isAlive);
  }

  void marchTo(String villageId, int turns, String? fromId) {
    origin = fromId ?? stationedAt;
    stationedAt = null;
    destination = villageId;
    turnsUntilArrival = turns;
  }

  void advanceMarch() {
    if (turnsUntilArrival > 0) {
      turnsUntilArrival--;
    }
    if (turnsUntilArrival == 0 && destination != null) {
      stationedAt = destination;
      destination = null;
      origin = null;
    }
  }

  void station(String villageId) {
    stationedAt = villageId;
    destination = null;
    turnsUntilArrival = 0;
    origin = null;
  }

  static int calculateTravelTime(Offset from, Offset to) {
    final dx = (to.dx - from.dx).abs();
    final dy = (to.dy - from.dy).abs();
    final distance = sqrt(dx * dx + dy * dy);
    return max(1, (distance / 8.0).ceil());
  }

  static String generateName(List<Unit> units, String owner) {
    final prefix = owner == 'player' ? '' : 'Enemy ';
    final count = units.length;
    if (count <= 3) return '${prefix}Squad';
    if (count <= 10) return '${prefix}Warband';
    if (count <= 25) return '${prefix}Company';
    return '${prefix}Legion';
  }
}
