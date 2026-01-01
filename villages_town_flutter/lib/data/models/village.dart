import 'dart:math';
import 'dart:ui';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart';
import '../protocols/resource_holder.dart';
import '../protocols/treasury_holder.dart';
import 'building.dart';
import 'nationality.dart';
import 'resource.dart';
import 'village_level.dart';

class Village with ResourceHolder, TreasuryHolder {
  final String id;
  final String name;
  final Nationality nationality;
  Offset coordinates;
  String owner;
  VillageLevel level;
  List<Building> buildings;
  @override
  Map<Resource, int> resources;
  @override
  double money;
  int population;
  int happiness; // 0-100
  int garrisonStrength;
  int garrisonMaxStrength;
  bool underSiege;
  int recruitsThisTurn;

  Village({
    String? id,
    required this.name,
    required this.nationality,
    required this.coordinates,
    required this.owner,
    this.level = VillageLevel.village,
    List<Building>? buildings,
    Map<Resource, int>? resources,
    this.money = 1000.0,
    this.population = 100,
    this.happiness = 75,
    this.garrisonStrength = 5,
    this.garrisonMaxStrength = 10,
    this.underSiege = false,
    this.recruitsThisTurn = 0,
  })  : id = id ?? const Uuid().v4(),
        buildings = buildings ?? Building.starter(),
        resources = resources ??
            (owner == 'neutral'
                ? {
                    Resource.food: 20,
                    Resource.wood: 15,
                    Resource.iron: 5,
                    Resource.gold: 30,
                  }
                : {
                    Resource.food: 100,
                    Resource.wood: 100,
                    Resource.iron: 50,
                    Resource.gold: 300,
                  }) {
    // Neutral villages have different defaults
    if (owner == 'neutral') {
      garrisonStrength = 8;
      garrisonMaxStrength = 15;
      population = 50;
    }
  }

  // Computed properties
  int get maxBuildings => level.maxBuildings;
  double get productionBonus => level.productionBonus;

  double get defenseBonus {
    var bonus = 0.2;
    for (final b in buildings) {
      bonus += b.defenseBonus;
    }
    bonus += level.defenseBonus;
    return bonus;
  }

  int get totalHappiness {
    var total = happiness;
    for (final b in buildings) {
      total += b.happinessBonus;
    }
    return min(total, 100);
  }

  int get populationCapacity {
    var cap = level.populationCap;
    if (buildings.any((b) => b.name == 'Aqueduct')) {
      cap = (cap * 1.5).toInt();
    }
    return cap;
  }

  bool get canBuildMore => buildings.length < maxBuildings;

  int get maxRecruitsPerTurn {
    var cap = 3;
    final barracks = buildings.firstWhereOrNull((b) => b.name == 'Barracks');
    if (barracks != null) cap += barracks.level;
    if (buildings.any((b) => b.name == 'Archery Range')) cap += 1;
    return cap;
  }

  int get computedGarrisonMax {
    var maxGarrison = 10;
    final barracks = buildings.firstWhereOrNull((b) => b.name == 'Barracks');
    if (barracks != null) maxGarrison += 5 * barracks.level;
    final fortress = buildings.firstWhereOrNull((b) => b.name == 'Fortress');
    if (fortress != null) maxGarrison += 15 * fortress.level;
    maxGarrison += level.garrisonBonus;
    return maxGarrison;
  }

  Village copyWith({
    String? id,
    String? name,
    Nationality? nationality,
    Offset? coordinates,
    String? owner,
    VillageLevel? level,
    List<Building>? buildings,
    Map<Resource, int>? resources,
    double? money,
    int? population,
    int? happiness,
    int? garrisonStrength,
    int? garrisonMaxStrength,
    bool? underSiege,
    int? recruitsThisTurn,
  }) {
    return Village(
      id: id ?? this.id,
      name: name ?? this.name,
      nationality: nationality ?? this.nationality,
      coordinates: coordinates ?? this.coordinates,
      owner: owner ?? this.owner,
      level: level ?? this.level,
      buildings: buildings ?? List.from(this.buildings),
      resources: resources ?? Map.from(this.resources),
      money: money ?? this.money,
      population: population ?? this.population,
      happiness: happiness ?? this.happiness,
      garrisonStrength: garrisonStrength ?? this.garrisonStrength,
      garrisonMaxStrength: garrisonMaxStrength ?? this.garrisonMaxStrength,
      underSiege: underSiege ?? this.underSiege,
      recruitsThisTurn: recruitsThisTurn ?? this.recruitsThisTurn,
    );
  }

  void addBuilding(Building building) {
    if (canBuildMore) {
      buildings.add(building);
    }
  }

  void modifyPopulation(int amount) {
    population = max(0, min(population + amount, populationCapacity));
  }

  void modifyHappiness(int amount) {
    happiness = max(0, min(happiness + amount, 100));
  }

  void regenerateGarrison() {
    if (underSiege) {
      underSiege = false;
      return;
    }
    var recovery = 1;
    if (buildings.any((b) => b.name == 'Barracks')) recovery += 1;
    if (buildings.any((b) => b.name == 'Fortress')) recovery += 2;
    garrisonMaxStrength = computedGarrisonMax;
    garrisonStrength = min(garrisonStrength + recovery, garrisonMaxStrength);
  }

  void damageGarrison(int amount) {
    garrisonStrength = max(0, garrisonStrength - amount);
  }
}
