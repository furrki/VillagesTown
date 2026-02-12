import 'dart:math';
import 'package:uuid/uuid.dart';
import 'geo_coordinate.dart';
import 'unit.dart';
import 'unit_type.dart';

enum ArmyState { stationed, marching, besieging }

class Army {
  final String id;
  String name;
  List<Unit> units;
  String owner;
  String? stationedAt; // Village ID
  String? destination;
  int turnsUntilArrival;
  String? origin;
  ArmyState state;
  int siegeTurns;

  int foodDeprivedTurns;
  int totalMarchTurns;

  Army({
    String? id,
    required this.name,
    required this.units,
    required this.owner,
    this.stationedAt,
    this.destination,
    this.turnsUntilArrival = 0,
    this.origin,
    this.state = ArmyState.stationed,
    this.siegeTurns = 0,
    this.foodDeprivedTurns = 0,
    this.totalMarchTurns = 0,
  }) : id = id ?? const Uuid().v4();

  bool get isMarching => state == ArmyState.marching;
  bool get isBesieging => state == ArmyState.besieging;

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

  /// Food-deprived armies fight at 80% effectiveness.
  double get foodDeprivationModifier => foodDeprivedTurns > 0 ? 0.8 : 1.0;

  /// March fatigue: -5% per turn beyond 1, floor at 75%.
  double get marchFatigueModifier {
    if (totalMarchTurns <= 1) return 1.0;
    return max(0.75, 1.0 - (totalMarchTurns - 1) * 0.05);
  }

  Army copyWith({
    String? id,
    String? name,
    List<Unit>? units,
    String? owner,
    String? stationedAt,
    String? destination,
    int? turnsUntilArrival,
    String? origin,
    ArmyState? state,
    int? siegeTurns,
    int? foodDeprivedTurns,
    int? totalMarchTurns,
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
      state: state ?? this.state,
      siegeTurns: siegeTurns ?? this.siegeTurns,
      foodDeprivedTurns: foodDeprivedTurns ?? this.foodDeprivedTurns,
      totalMarchTurns: totalMarchTurns ?? this.totalMarchTurns,
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
    totalMarchTurns = turns;
    state = ArmyState.marching;
    siegeTurns = 0;
  }

  /// Decrements march counter. Returns true if army just arrived at destination.
  bool advanceMarch() {
    if (turnsUntilArrival > 0) {
      turnsUntilArrival--;
    }
    return turnsUntilArrival == 0 && destination != null;
  }

  /// Called when army arrives at a friendly village.
  void arriveAtFriendly() {
    stationedAt = destination;
    destination = null;
    origin = null;
    state = ArmyState.stationed;
    siegeTurns = 0;
    totalMarchTurns = 0;
  }

  /// Called when army arrives at an enemy village to begin siege.
  void beginSiege() {
    stationedAt = destination; // stationed "at" but besieging
    destination = null;
    origin = null;
    state = ArmyState.besieging;
    siegeTurns = 0;
  }

  /// Advances siege by one turn. Returns true if siege is ready to assault.
  bool advanceSiege() {
    if (state == ArmyState.besieging) {
      siegeTurns++;
      return siegeTurns >= 1; // Ready to assault after 1 turn
    }
    return false;
  }

  void station(String villageId) {
    stationedAt = villageId;
    destination = null;
    turnsUntilArrival = 0;
    origin = null;
    state = ArmyState.stationed;
    siegeTurns = 0;
    totalMarchTurns = 0;
  }

  static int calculateTravelTime(GeoCoordinate from, GeoCoordinate to) {
    final distanceKm = GeoCoordinate.distanceKm(from, to);
    // ~80km per turn, minimum 1 turn (results in 2-5 turn marches)
    return max(1, (distanceKm / 80.0).ceil());
  }

  static String generateName(String villageName, String nationalityId) {
    const armySuffixes = {
      'ottoman': 'Ordusu',
      'byzantine': 'Στρατός',
      'crusader': 'Army',
      'bulgarian': 'Войска',
      'serbian': 'Војска',
      'armenian': 'Banaki',
      'mamluk': 'جيش',
    };
    final suffix = armySuffixes[nationalityId] ?? 'Army';
    return '$villageName $suffix';
  }
}
