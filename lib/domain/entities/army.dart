import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/types/typed_ids.dart';
import '../../core/types/json_converters.dart';
import 'unit.dart';

part 'army.freezed.dart';
part 'army.g.dart';

/// Immutable army entity.
@freezed
class Army with _$Army {
  const Army._();

  const factory Army({
    @ArmyIdConverter() required ArmyId id,
    required String name,
    required List<Unit> units,
    @PlayerIdConverter() required PlayerId owner,
    @NullableVillageIdConverter() VillageId? stationedAt,
    @NullableVillageIdConverter() VillageId? destination,
    @Default(0) int turnsUntilArrival,
    @NullableVillageIdConverter() VillageId? origin,
  }) = _Army;

  factory Army.fromJson(Map<String, dynamic> json) => _$ArmyFromJson(json);

  // === Computed properties ===

  bool get isMarching => destination != null && turnsUntilArrival > 0;
  bool get hasArrived => destination != null && turnsUntilArrival == 0;
  bool get isStationed => stationedAt != null && !isMarching;
  bool get isEmpty => units.isEmpty;
  int get unitCount => units.length;

  int get totalAttack => units.fold(0, (sum, u) => sum + u.attack);
  int get totalDefense => units.fold(0, (sum, u) => sum + u.defense);
  int get totalHP => units.fold(0, (sum, u) => sum + u.currentHP);
  int get totalMaxHP => units.fold(0, (sum, u) => sum + u.maxHP);

  /// Composite strength score for AI targeting.
  int get strength => totalAttack + totalDefense + (totalHP ~/ 10);

  /// Get the most common unit type in the army.
  UnitType? get primaryUnitType {
    if (units.isEmpty) return null;
    final counts = <UnitType, int>{};
    for (final u in units) {
      counts[u.unitType] = (counts[u.unitType] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Emoji representation based on primary unit type.
  String get emoji => primaryUnitType?.emoji ?? '⚔️';

  /// Living units only.
  List<Unit> get aliveUnits => units.where((u) => u.isAlive).toList();

  /// Dead units.
  List<Unit> get deadUnits => units.where((u) => !u.isAlive).toList();

  // === Army modifications (return new army) ===

  /// Add units to the army.
  Army addUnits(List<Unit> newUnits) => copyWith(
        units: [...units, ...newUnits],
      );

  /// Remove dead units.
  Army removeDeadUnits() => copyWith(
        units: aliveUnits,
      );

  /// Start marching to a destination.
  Army marchTo(VillageId destinationId, int turns) => copyWith(
        origin: stationedAt,
        stationedAt: null,
        destination: destinationId,
        turnsUntilArrival: turns,
      );

  /// Advance march by one turn.
  Army advanceMarch() {
    if (turnsUntilArrival <= 0) return this;

    final newTurns = turnsUntilArrival - 1;
    if (newTurns == 0 && destination != null) {
      // Arrived at destination
      return copyWith(
        stationedAt: destination,
        destination: null,
        turnsUntilArrival: 0,
        origin: null,
      );
    }
    return copyWith(turnsUntilArrival: newTurns);
  }

  /// Station at a village.
  Army stationAt(VillageId villageId) => copyWith(
        stationedAt: villageId,
        destination: null,
        turnsUntilArrival: 0,
        origin: null,
      );

  // === Factory methods ===

  /// Create a new army.
  factory Army.create({
    required List<Unit> units,
    required PlayerId owner,
    VillageId? stationedAt,
  }) {
    return Army(
      id: ArmyId.generate(),
      name: _generateName(units, owner),
      units: units,
      owner: owner,
      stationedAt: stationedAt,
    );
  }

  /// Generate army name based on size.
  static String _generateName(List<Unit> units, PlayerId owner) {
    final prefix = owner == PlayerId.player ? '' : 'Enemy ';
    final count = units.length;
    if (count <= 3) return '${prefix}Squad';
    if (count <= 10) return '${prefix}Warband';
    if (count <= 25) return '${prefix}Company';
    return '${prefix}Legion';
  }
}
