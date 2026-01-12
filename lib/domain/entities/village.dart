import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/types/typed_ids.dart';
import '../../core/types/json_converters.dart';
import '../value_objects/geo_coordinate.dart';
import '../value_objects/resources.dart';
import 'building.dart';

part 'village.freezed.dart';
part 'village.g.dart';

/// Village level progression.
enum VillageLevel {
  village(
    maxBuildings: 8,
    productionBonus: 0.1,
    defenseBonus: 0.0,
    populationCap: 200,
    garrisonBonus: 0,
  ),
  town(
    maxBuildings: 12,
    productionBonus: 0.2,
    defenseBonus: 0.0,
    populationCap: 500,
    garrisonBonus: 5,
  ),
  district(
    maxBuildings: 16,
    productionBonus: 0.3,
    defenseBonus: 0.0,
    populationCap: 1000,
    garrisonBonus: 10,
  ),
  castle(
    maxBuildings: 20,
    productionBonus: 0.4,
    defenseBonus: 0.05, // +5%
    populationCap: 2000,
    garrisonBonus: 20,
  ),
  city(
    maxBuildings: 30,
    productionBonus: 0.5,
    defenseBonus: 0.10, // +10%
    populationCap: 5000,
    garrisonBonus: 30,
  );

  final int maxBuildings;
  final double productionBonus;
  final double defenseBonus;
  final int populationCap;
  final int garrisonBonus;

  const VillageLevel({
    required this.maxBuildings,
    required this.productionBonus,
    required this.defenseBonus,
    required this.populationCap,
    required this.garrisonBonus,
  });
}

/// Immutable village entity.
@freezed
class Village with _$Village {
  const Village._();

  const factory Village({
    @VillageIdConverter() required VillageId id,
    required String name,
    @NationalityIdConverter() required NationalityId originalNationality,
    required GeoCoordinate coordinates,
    @PlayerIdConverter() required PlayerId owner,
    @Default(VillageLevel.village) VillageLevel level,
    @Default([]) List<Building> buildings,
    @Default(ResourceBundle.starter) ResourceBundle resources,
    @Default(1000.0) double treasury,
    @Default(100) int population,
    @Default(75) int happiness,
    @Default(5) int garrisonStrength,
    @Default(10) int garrisonMaxStrength,
    @Default(false) bool underSiege,
    @Default(0) int recruitsThisTurn,
  }) = _Village;

  factory Village.fromJson(Map<String, dynamic> json) => _$VillageFromJson(json);

  // === Computed properties ===

  int get maxBuildings => level.maxBuildings;
  double get productionBonus => level.productionBonus;
  int get populationCap => level.populationCap;

  double get defenseBonus {
    var bonus = 0.2;
    for (final b in buildings) {
      bonus += b.defenseBonus;
    }
    return bonus + level.defenseBonus;
  }

  bool get canBuildMore => buildings.length < maxBuildings;

  int get maxRecruitsPerTurn {
    var cap = 3;
    final barracks = buildings.where((b) => b.type == BuildingType.barracks).firstOrNull;
    if (barracks != null) cap += barracks.level;
    if (buildings.any((b) => b.type == BuildingType.archeryRange)) cap += 1;
    return cap;
  }

  int get computedGarrisonMax {
    var maxGarrison = 10;
    final barracks = buildings.where((b) => b.type == BuildingType.barracks).firstOrNull;
    if (barracks != null) maxGarrison += 5 * barracks.level;
    final fortress = buildings.where((b) => b.type == BuildingType.fortress).firstOrNull;
    if (fortress != null) maxGarrison += 15 * fortress.level;
    maxGarrison += level.garrisonBonus;
    return maxGarrison;
  }

  bool get isNeutral => owner == PlayerId.neutral;

  /// Check if village has a specific building type.
  bool hasBuilding(BuildingType type) => buildings.any((b) => b.type == type);

  /// Get building of specific type (if exists).
  Building? getBuilding(BuildingType type) =>
      buildings.where((b) => b.type == type).firstOrNull;

  // === Factory methods ===

  /// Create a new village with starter buildings.
  factory Village.create({
    required String name,
    required NationalityId originalNationality,
    required GeoCoordinate coordinates,
    required PlayerId owner,
    VillageLevel level = VillageLevel.village,
  }) {
    final isNeutral = owner == PlayerId.neutral;
    return Village(
      id: VillageId.generate(),
      name: name,
      originalNationality: originalNationality,
      coordinates: coordinates,
      owner: owner,
      level: level,
      buildings: Building.starter(),
      resources: isNeutral ? ResourceBundle.neutralVillage : ResourceBundle.starter,
      treasury: isNeutral ? 100.0 : 1000.0,
      population: isNeutral ? 50 : 100,
      happiness: 75,
      garrisonStrength: isNeutral ? 8 : 5,
      garrisonMaxStrength: isNeutral ? 15 : 10,
    );
  }
}
