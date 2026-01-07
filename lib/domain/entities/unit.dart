import 'dart:math';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/types/typed_ids.dart';
import '../../core/types/json_converters.dart';
import '../value_objects/resources.dart';

part 'unit.freezed.dart';
part 'unit.g.dart';

/// Unit category for grouping.
enum UnitCategory {
  infantry('Infantry'),
  ranged('Ranged'),
  cavalry('Cavalry');

  final String displayName;
  const UnitCategory(this.displayName);
}

/// Unit type definitions with stats.
enum UnitType {
  militia(
    category: UnitCategory.infantry,
    displayName: 'Militia',
    emoji: '🗡️',
    attack: 5,
    defense: 3,
    hp: 50,
    movement: 2,
    cost: ResourceBundle(gold: 20, food: 5),
    upkeep: ResourceBundle(gold: 2, food: 1),
    counterInfo: 'Cheap, weak',
  ),
  spearman(
    category: UnitCategory.infantry,
    displayName: 'Spearman',
    emoji: '🛡️',
    attack: 7,
    defense: 8,
    hp: 70,
    movement: 2,
    cost: ResourceBundle(gold: 30, iron: 5),
    upkeep: ResourceBundle(gold: 2, food: 1),
    counterInfo: 'Strong vs Cavalry',
  ),
  swordsman(
    category: UnitCategory.infantry,
    displayName: 'Swordsman',
    emoji: '⚔️',
    attack: 10,
    defense: 6,
    hp: 80,
    movement: 2,
    cost: ResourceBundle(gold: 35, iron: 10),
    upkeep: ResourceBundle(gold: 2, food: 1),
    counterInfo: 'Balanced fighter',
  ),
  archer(
    category: UnitCategory.ranged,
    displayName: 'Archer',
    emoji: '🏹',
    attack: 9,
    defense: 3,
    hp: 50,
    movement: 2,
    cost: ResourceBundle(gold: 35, wood: 10),
    upkeep: ResourceBundle(gold: 2, food: 1),
    counterInfo: 'Strong vs Infantry',
  ),
  crossbowman(
    category: UnitCategory.ranged,
    displayName: 'Crossbowman',
    emoji: '🎯',
    attack: 12,
    defense: 4,
    hp: 60,
    movement: 2,
    cost: ResourceBundle(gold: 50, iron: 10),
    upkeep: ResourceBundle(gold: 3, food: 1),
    counterInfo: 'Strong vs Infantry',
  ),
  lightCavalry(
    category: UnitCategory.cavalry,
    displayName: 'Light Cavalry',
    emoji: '🐴',
    attack: 9,
    defense: 5,
    hp: 70,
    movement: 4,
    cost: ResourceBundle(gold: 60, food: 15),
    upkeep: ResourceBundle(gold: 4, food: 2),
    counterInfo: 'Strong vs Ranged',
  ),
  knight(
    category: UnitCategory.cavalry,
    displayName: 'Knight',
    emoji: '🐎',
    attack: 14,
    defense: 8,
    hp: 100,
    movement: 3,
    cost: ResourceBundle(gold: 100, iron: 20),
    upkeep: ResourceBundle(gold: 6, food: 2),
    counterInfo: 'Strong vs Ranged',
  );

  final UnitCategory category;
  final String displayName;
  final String emoji;
  final int attack;
  final int defense;
  final int hp;
  final int movement;
  final ResourceBundle cost;
  final ResourceBundle upkeep;
  final String counterInfo;

  const UnitType({
    required this.category,
    required this.displayName,
    required this.emoji,
    required this.attack,
    required this.defense,
    required this.hp,
    required this.movement,
    required this.cost,
    required this.upkeep,
    required this.counterInfo,
  });

  /// Calculate damage multiplier against another unit type.
  double damageMultiplier(UnitType target) {
    return switch (this) {
      // Spearmen STRONG vs Cavalry
      UnitType.spearman when target.category == UnitCategory.cavalry => 1.5,
      // Cavalry STRONG vs Ranged, WEAK vs Spearmen
      UnitType.lightCavalry || UnitType.knight
          when target.category == UnitCategory.ranged =>
        1.5,
      UnitType.lightCavalry || UnitType.knight when target == UnitType.spearman => 0.6,
      // Archers STRONG vs Infantry
      UnitType.archer || UnitType.crossbowman when target == UnitType.militia => 1.3,
      UnitType.archer || UnitType.crossbowman when target == UnitType.swordsman => 1.2,
      // Swordsmen slight bonus vs militia
      UnitType.swordsman when target == UnitType.militia => 1.2,
      _ => 1.0,
    };
  }

  /// Base accuracy for ranged units (0.0 for non-ranged).
  double get baseAccuracy => switch (this) {
        UnitType.archer => 0.55,
        UnitType.crossbowman => 0.70,
        _ => 0.0,
      };

  /// Base kill potential for cavalry (0.0 for non-cavalry).
  double get baseKillPotential => switch (this) {
        UnitType.lightCavalry => 1.5,
        UnitType.knight => 2.5,
        _ => 0.0,
      };

  /// Base kill rate for infantry melee (0.0 for non-infantry).
  double get baseKillRate => switch (this) {
        UnitType.militia => 0.25,
        UnitType.spearman => 0.35,
        UnitType.swordsman => 0.50,
        _ => 0.30, // Default for cavalry/ranged in melee
      };

  static List<UnitType> get infantry => [militia, spearman, swordsman];
  static List<UnitType> get ranged => [archer, crossbowman];
  static List<UnitType> get cavalry => [lightCavalry, knight];
}

/// Immutable unit entity.
@freezed
class Unit with _$Unit {
  const Unit._();

  const factory Unit({
    @UnitIdConverter() required UnitId id,
    required UnitType unitType,
    @PlayerIdConverter() required PlayerId owner,
    required int attack,
    required int defense,
    required int maxHP,
    required int currentHP,
    required int movement,
    @Default(1) int level,
    @Default(0) int experience,
    @Default(100) int morale,
    // Building-based bonuses (applied at creation time)
    @Default(0) int producedFromBuildingLevel,
    @Default(0) int bonusAttack,
    @Default(0) int bonusDefense,
    @Default(0.0) double bonusAccuracy,
    @Default(0.0) double bonusKillPotential,
  }) = _Unit;

  factory Unit.fromJson(Map<String, dynamic> json) => _$UnitFromJson(json);

  /// Create a new unit of a specific type with optional building bonuses.
  factory Unit.create(
    UnitType type,
    PlayerId owner, {
    int barracksLevel = 0,
    int archeryRangeLevel = 0,
    int stablesLevel = 0,
  }) {
    // Calculate bonuses based on unit category and building levels
    int bonusAtk = 0;
    int bonusDef = 0;
    double bonusAcc = 0.0;
    double bonusKillPot = 0.0;
    int buildingLevel = 0;

    switch (type.category) {
      case UnitCategory.infantry:
        buildingLevel = barracksLevel;
        bonusAtk = barracksLevel; // +1 ATK per level
        bonusDef = barracksLevel * 2; // +2 DEF per level
        break;
      case UnitCategory.ranged:
        buildingLevel = archeryRangeLevel;
        bonusAtk = archeryRangeLevel; // +1 ATK per level
        bonusAcc = archeryRangeLevel * 0.03; // +3% accuracy per level
        break;
      case UnitCategory.cavalry:
        buildingLevel = stablesLevel;
        bonusAtk = stablesLevel; // +1 ATK per level
        bonusKillPot = stablesLevel * 0.1; // +0.1 kill potential per level
        break;
    }

    return Unit(
      id: UnitId.generate(),
      unitType: type,
      owner: owner,
      attack: type.attack,
      defense: type.defense,
      maxHP: type.hp,
      currentHP: type.hp,
      movement: type.movement,
      producedFromBuildingLevel: buildingLevel,
      bonusAttack: bonusAtk,
      bonusDefense: bonusDef,
      bonusAccuracy: bonusAcc,
      bonusKillPotential: bonusKillPot,
    );
  }

  // Convenience getters
  String get name => unitType.displayName;
  String get emoji => unitType.emoji;
  UnitCategory get category => unitType.category;
  ResourceBundle get upkeep => unitType.upkeep;
  bool get isAlive => currentHP > 0;
  int get experienceToNextLevel => level * 100;
  bool get canLevelUp => experience >= experienceToNextLevel;

  // Effective stats (base + bonus)
  int get effectiveAttack => attack + bonusAttack;
  int get effectiveDefense => defense + bonusDefense;

  // Combat values with bonuses (capped where appropriate)
  double get effectiveAccuracy =>
      (unitType.baseAccuracy + bonusAccuracy).clamp(0.0, 0.90);
  double get effectiveKillPotential =>
      unitType.baseKillPotential + bonusKillPotential;
  double get effectiveKillRate =>
      unitType.baseKillRate + (producedFromBuildingLevel * 0.02);

  /// Take damage (returns new unit with updated HP).
  Unit takeDamage(int amount) => copyWith(
        currentHP: max(0, currentHP - amount),
      );

  /// Heal (returns new unit with updated HP).
  Unit heal(int amount) => copyWith(
        currentHP: min(maxHP, currentHP + amount),
      );

  /// Add experience (returns new unit, potentially leveled up).
  Unit addExperience(int amount) {
    var newExp = experience + amount;
    var newLevel = level;
    var newAttack = attack;
    var newDefense = defense;
    var newMaxHP = maxHP;
    var newCurrentHP = currentHP;

    // Level up if enough experience
    while (newExp >= newLevel * 100) {
      newExp -= newLevel * 100;
      newLevel++;
      newAttack = (newAttack * 1.1).toInt();
      newDefense = (newDefense * 1.1).toInt();
      newMaxHP = (newMaxHP * 1.1).toInt();
      newCurrentHP = newMaxHP; // Full heal on level up
    }

    return copyWith(
      experience: newExp,
      level: newLevel,
      attack: newAttack,
      defense: newDefense,
      maxHP: newMaxHP,
      currentHP: newCurrentHP,
    );
  }

  /// Calculate damage multiplier against another unit.
  double damageMultiplierAgainst(Unit target) =>
      unitType.damageMultiplier(target.unitType);
}
