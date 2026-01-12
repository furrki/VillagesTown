import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/types/typed_ids.dart';
import '../../core/types/json_converters.dart';
import '../value_objects/resources.dart';

part 'building.freezed.dart';
part 'building.g.dart';

/// Building type categories.
enum BuildingCategory {
  production,
  military,
  infrastructure,
}

/// Predefined building types with their stats.
enum BuildingType {
  farm(
    category: BuildingCategory.production,
    displayName: 'Farm',
    description: 'Produces food for your population',
    baseCost: ResourceBundle(gold: 50, wood: 20),
    production: ResourceBundle(food: 10),
    consumption: ResourceBundle.empty,
    defenseBonus: 0.0,
    canRecruitUnits: false,
    isUnique: false,
  ),
  lumberMill(
    category: BuildingCategory.production,
    displayName: 'Lumber Mill',
    description: 'Produces wood for construction',
    baseCost: ResourceBundle(gold: 40),
    production: ResourceBundle(wood: 8),
    consumption: ResourceBundle.empty,
    defenseBonus: 0.0,
    canRecruitUnits: false,
    isUnique: false,
  ),
  ironMine(
    category: BuildingCategory.production,
    displayName: 'Iron Mine',
    description: 'Produces iron for military units',
    baseCost: ResourceBundle(gold: 60, wood: 10),
    production: ResourceBundle(iron: 5),
    consumption: ResourceBundle.empty,
    defenseBonus: 0.0,
    canRecruitUnits: false,
    isUnique: false,
  ),
  market(
    category: BuildingCategory.production,
    displayName: 'Market',
    description: 'Generates gold through trade',
    baseCost: ResourceBundle(gold: 100, wood: 30),
    production: ResourceBundle(gold: 15),
    consumption: ResourceBundle.empty,
    defenseBonus: 0.0,
    canRecruitUnits: false,
    isUnique: true,
  ),
  barracks(
    category: BuildingCategory.military,
    displayName: 'Barracks',
    description: 'Enables recruitment of infantry units',
    baseCost: ResourceBundle(gold: 150, wood: 50, iron: 20),
    production: ResourceBundle.empty,
    consumption: ResourceBundle.empty,
    defenseBonus: 0.0,
    canRecruitUnits: true,
    isUnique: true,
  ),
  archeryRange(
    category: BuildingCategory.military,
    displayName: 'Archery Range',
    description: 'Enables recruitment of ranged units',
    baseCost: ResourceBundle(gold: 140, wood: 60, iron: 15),
    production: ResourceBundle.empty,
    consumption: ResourceBundle.empty,
    defenseBonus: 0.0,
    canRecruitUnits: true,
    isUnique: true,
  ),
  stables(
    category: BuildingCategory.military,
    displayName: 'Stables',
    description: 'Enables recruitment of cavalry units',
    baseCost: ResourceBundle(gold: 200, wood: 80, food: 30),
    production: ResourceBundle.empty,
    consumption: ResourceBundle.empty,
    defenseBonus: 0.0,
    canRecruitUnits: true,
    isUnique: true,
  ),
  fortress(
    category: BuildingCategory.military,
    displayName: 'Fortress',
    description: 'Provides defensive bonus',
    baseCost: ResourceBundle(gold: 300, wood: 100, iron: 50),
    production: ResourceBundle.empty,
    consumption: ResourceBundle.empty,
    defenseBonus: 0.05, // +5% per level
    canRecruitUnits: false,
    isUnique: true,
  );

  final BuildingCategory category;
  final String displayName;
  final String description;
  final ResourceBundle baseCost;
  final ResourceBundle production;
  final ResourceBundle consumption;
  final double defenseBonus;
  final bool canRecruitUnits;
  final bool isUnique;

  const BuildingType({
    required this.category,
    required this.displayName,
    required this.description,
    required this.baseCost,
    required this.production,
    required this.consumption,
    required this.defenseBonus,
    required this.canRecruitUnits,
    required this.isUnique,
  });

  /// Cost at a given level (scales by 1.5x per level).
  ResourceBundle costAtLevel(int level) => baseCost.scale(1.5 * level);

  /// Production at a given level.
  ResourceBundle productionAtLevel(int level) => production * level;

  /// Consumption at a given level.
  ResourceBundle consumptionAtLevel(int level) => consumption * level;

  /// Unit bonus attack from this building at given level.
  int unitBonusAttack(int level) => switch (this) {
        BuildingType.barracks => level, // +1 ATK per level for infantry
        BuildingType.archeryRange => level, // +1 ATK per level for ranged
        BuildingType.stables => level, // +1 ATK per level for cavalry
        _ => 0,
      };

  /// Unit bonus defense from barracks.
  int unitBonusDefense(int level) => switch (this) {
        BuildingType.barracks => level * 2, // +2 DEF per level for infantry
        _ => 0,
      };

  /// Unit bonus accuracy from archery range.
  double unitBonusAccuracy(int level) => switch (this) {
        BuildingType.archeryRange => level * 0.03, // +3% per level for ranged
        _ => 0.0,
      };

  /// Unit bonus kill potential from stables.
  double unitBonusKillPotential(int level) => switch (this) {
        BuildingType.stables => level * 0.1, // +0.1 per level for cavalry
        _ => 0.0,
      };

  /// Unit bonus kill rate from barracks.
  double unitBonusKillRate(int level) => switch (this) {
        BuildingType.barracks => level * 0.02, // +0.02 per level for infantry
        _ => 0.0,
      };

  static List<BuildingType> get economic => [farm, lumberMill, ironMine, market];
  static List<BuildingType> get military => [barracks, archeryRange, stables, fortress];
  static List<BuildingType> get starter => [farm, lumberMill, ironMine, barracks];
}

/// Immutable building entity.
@freezed
class Building with _$Building {
  const Building._();

  const factory Building({
    @BuildingIdConverter() required BuildingId id,
    required BuildingType type,
    @Default(1) int level,
  }) = _Building;

  factory Building.fromJson(Map<String, dynamic> json) => _$BuildingFromJson(json);

  /// Create a new building of a specific type.
  factory Building.create(BuildingType type) => Building(
        id: BuildingId.generate(),
        type: type,
      );

  // Convenience getters
  String get name => type.displayName;
  String get description => type.description;
  BuildingCategory get category => type.category;
  bool get canRecruitUnits => type.canRecruitUnits;

  ResourceBundle get baseCost => type.baseCost;
  ResourceBundle get currentCost => type.costAtLevel(level);
  ResourceBundle get upgradeCost => type.costAtLevel(level + 1);

  ResourceBundle get production => type.productionAtLevel(level);
  ResourceBundle get consumption => type.consumptionAtLevel(level);

  double get defenseBonus => type.defenseBonus * level;

  /// Starter buildings for a new village.
  static List<Building> starter() => BuildingType.starter
      .map((type) => Building.create(type))
      .toList();
}
