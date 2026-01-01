import 'resource.dart';

class UnitStats {
  final String name;
  final int attack;
  final int defense;
  final int hp;
  final int movement;
  final Map<Resource, int> cost;
  final Map<Resource, int> upkeep;

  const UnitStats({
    required this.name,
    required this.attack,
    required this.defense,
    required this.hp,
    required this.movement,
    required this.cost,
    required this.upkeep,
  });
}

enum UnitType {
  // Infantry
  militia,
  spearman,
  swordsman,
  // Ranged
  archer,
  crossbowman,
  // Cavalry
  lightCavalry,
  knight;

  String get category => switch (this) {
        militia || spearman || swordsman => 'Infantry',
        archer || crossbowman => 'Ranged',
        lightCavalry || knight => 'Cavalry',
      };

  String get emoji => switch (this) {
        militia => '🗡️',
        spearman => '🛡️',
        swordsman => '⚔️',
        archer => '🏹',
        crossbowman => '🎯',
        lightCavalry => '🐴',
        knight => '🐎',
      };

  String get displayName => switch (this) {
        militia => 'Militia',
        spearman => 'Spearman',
        swordsman => 'Swordsman',
        archer => 'Archer',
        crossbowman => 'Crossbowman',
        lightCavalry => 'Light Cavalry',
        knight => 'Knight',
      };

  String get counterInfo => switch (this) {
        spearman => 'Strong vs Cavalry',
        lightCavalry || knight => 'Strong vs Ranged',
        archer || crossbowman => 'Strong vs Infantry',
        swordsman => 'Balanced fighter',
        militia => 'Cheap, weak',
      };

  Map<Resource, int> get cost => stats.cost;

  double damageMultiplier(UnitType target) {
    return switch (this) {
      // Spearmen are STRONG vs Cavalry
      spearman when target.category == 'Cavalry' => 1.5,
      // Cavalry STRONG vs Ranged, WEAK vs Spearmen
      lightCavalry || knight when target.category == 'Ranged' => 1.5,
      lightCavalry || knight when target == spearman => 0.6,
      // Archers STRONG vs Infantry (except shields)
      archer || crossbowman when target == militia => 1.3,
      archer || crossbowman when target == swordsman => 1.2,
      // Swordsmen balanced, slight bonus vs militia
      swordsman when target == militia => 1.2,
      _ => 1.0,
    };
  }

  UnitStats get stats => switch (this) {
        militia => const UnitStats(
            name: 'Militia',
            attack: 5,
            defense: 3,
            hp: 50,
            movement: 2,
            cost: {Resource.gold: 20, Resource.food: 5},
            upkeep: {Resource.gold: 2, Resource.food: 1},
          ),
        spearman => const UnitStats(
            name: 'Spearman',
            attack: 7,
            defense: 8,
            hp: 70,
            movement: 2,
            cost: {Resource.gold: 30, Resource.iron: 5},
            upkeep: {Resource.gold: 2, Resource.food: 1},
          ),
        swordsman => const UnitStats(
            name: 'Swordsman',
            attack: 10,
            defense: 6,
            hp: 80,
            movement: 2,
            cost: {Resource.gold: 35, Resource.iron: 10},
            upkeep: {Resource.gold: 2, Resource.food: 1},
          ),
        archer => const UnitStats(
            name: 'Archer',
            attack: 9,
            defense: 3,
            hp: 50,
            movement: 2,
            cost: {Resource.gold: 35, Resource.wood: 10},
            upkeep: {Resource.gold: 2, Resource.food: 1},
          ),
        crossbowman => const UnitStats(
            name: 'Crossbowman',
            attack: 12,
            defense: 4,
            hp: 60,
            movement: 2,
            cost: {Resource.gold: 50, Resource.iron: 10},
            upkeep: {Resource.gold: 3, Resource.food: 1},
          ),
        lightCavalry => const UnitStats(
            name: 'Light Cavalry',
            attack: 9,
            defense: 5,
            hp: 70,
            movement: 4,
            cost: {Resource.gold: 60, Resource.food: 15},
            upkeep: {Resource.gold: 4, Resource.food: 2},
          ),
        knight => const UnitStats(
            name: 'Knight',
            attack: 14,
            defense: 8,
            hp: 100,
            movement: 3,
            cost: {Resource.gold: 100, Resource.iron: 20},
            upkeep: {Resource.gold: 6, Resource.food: 2},
          ),
      };
}
