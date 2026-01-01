import 'package:uuid/uuid.dart';
import 'building_type.dart';
import 'resource.dart';

class Building {
  final String id;
  final BuildingType type;
  final String name;
  final Map<Resource, int> baseCost;
  int level;
  final Map<Resource, int> resourcesProduction;
  final Map<Resource, int> resourcesConsumption;
  final String description;
  final double productionBonus;
  final double defenseBonus;
  final int happinessBonus;
  final bool canRecruitUnits;

  Building({
    String? id,
    required this.type,
    required this.name,
    required this.baseCost,
    this.level = 1,
    this.resourcesProduction = const {},
    this.resourcesConsumption = const {},
    required this.description,
    this.productionBonus = 0.0,
    this.defenseBonus = 0.0,
    this.happinessBonus = 0,
    this.canRecruitUnits = false,
  }) : id = id ?? const Uuid().v4();

  Building copyWith({
    String? id,
    BuildingType? type,
    String? name,
    Map<Resource, int>? baseCost,
    int? level,
    Map<Resource, int>? resourcesProduction,
    Map<Resource, int>? resourcesConsumption,
    String? description,
    double? productionBonus,
    double? defenseBonus,
    int? happinessBonus,
    bool? canRecruitUnits,
  }) {
    return Building(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      baseCost: baseCost ?? this.baseCost,
      level: level ?? this.level,
      resourcesProduction: resourcesProduction ?? this.resourcesProduction,
      resourcesConsumption: resourcesConsumption ?? this.resourcesConsumption,
      description: description ?? this.description,
      productionBonus: productionBonus ?? this.productionBonus,
      defenseBonus: defenseBonus ?? this.defenseBonus,
      happinessBonus: happinessBonus ?? this.happinessBonus,
      canRecruitUnits: canRecruitUnits ?? this.canRecruitUnits,
    );
  }

  // Static building definitions
  static Building get farm => Building(
        type: BuildingType.production,
        name: 'Farm',
        baseCost: const {Resource.gold: 50, Resource.wood: 20},
        resourcesProduction: const {Resource.food: 10},
        description: 'Produces food for your population',
      );

  static Building get lumberMill => Building(
        type: BuildingType.production,
        name: 'Lumber Mill',
        baseCost: const {Resource.gold: 40},
        resourcesProduction: const {Resource.wood: 8},
        description: 'Produces wood for construction',
      );

  static Building get ironMine => Building(
        type: BuildingType.production,
        name: 'Iron Mine',
        baseCost: const {Resource.gold: 60, Resource.wood: 10},
        resourcesProduction: const {Resource.iron: 5},
        description: 'Produces iron for military units',
      );

  static Building get market => Building(
        type: BuildingType.production,
        name: 'Market',
        baseCost: const {Resource.gold: 100, Resource.wood: 30},
        resourcesProduction: const {Resource.gold: 15},
        description: 'Generates gold through trade',
      );

  static Building get barracks => Building(
        type: BuildingType.military,
        name: 'Barracks',
        baseCost: const {Resource.gold: 150, Resource.wood: 50, Resource.iron: 20},
        description: 'Enables recruitment of infantry units',
        canRecruitUnits: true,
      );

  static Building get archeryRange => Building(
        type: BuildingType.military,
        name: 'Archery Range',
        baseCost: const {Resource.gold: 140, Resource.wood: 60, Resource.iron: 15},
        description: 'Enables recruitment of ranged units',
        canRecruitUnits: true,
      );

  static Building get stables => Building(
        type: BuildingType.military,
        name: 'Stables',
        baseCost: const {Resource.gold: 200, Resource.wood: 80, Resource.food: 30},
        description: 'Enables recruitment of cavalry units',
        canRecruitUnits: true,
      );

  static Building get fortress => Building(
        type: BuildingType.military,
        name: 'Fortress',
        baseCost: const {Resource.gold: 300, Resource.wood: 100, Resource.iron: 50},
        description: 'Provides strong defensive bonus',
        defenseBonus: 0.5,
      );

  static Building get granary => Building(
        type: BuildingType.infrastructure,
        name: 'Granary',
        baseCost: const {Resource.gold: 80, Resource.wood: 40},
        resourcesProduction: const {Resource.food: 5},
        description: 'Increases food storage and production',
        productionBonus: 0.1,
      );

  static Building get temple => Building(
        type: BuildingType.special,
        name: 'Temple',
        baseCost: const {Resource.gold: 200, Resource.wood: 60},
        description: 'Increases happiness and culture',
        happinessBonus: 15,
      );

  static Building get library => Building(
        type: BuildingType.special,
        name: 'Library',
        baseCost: const {Resource.gold: 150, Resource.wood: 50},
        description: 'Generates science points for research',
      );

  static List<Building> get allEconomic => [farm, lumberMill, ironMine, market];
  static List<Building> get allMilitary => [barracks, archeryRange, stables, fortress];
  static List<Building> get allInfrastructure => [granary];
  static List<Building> get allSpecial => [temple, library];
  static List<Building> get all => [...allEconomic, ...allMilitary, ...allInfrastructure, ...allSpecial];

  static List<Building> starter() => [farm, lumberMill, ironMine, barracks];
}
