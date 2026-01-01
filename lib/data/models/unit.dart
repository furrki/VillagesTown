import 'dart:math';
import 'dart:ui';
import 'package:uuid/uuid.dart';
import 'unit_type.dart';

class Unit {
  final String id;
  final String name;
  final UnitType unitType;
  int attack;
  int defense;
  int maxHP;
  int currentHP;
  int movement;
  int movementRemaining;
  int level;
  int experience;
  int morale; // 0-100
  String owner;
  Offset coordinates;

  Unit({
    String? id,
    required this.name,
    required this.unitType,
    required this.attack,
    required this.defense,
    required this.maxHP,
    required this.currentHP,
    required this.movement,
    required this.movementRemaining,
    this.level = 1,
    this.experience = 0,
    this.morale = 100,
    required this.owner,
    required this.coordinates,
  }) : id = id ?? const Uuid().v4();

  bool get isAlive => currentHP > 0;
  bool get isMovable => true;

  factory Unit.create(UnitType type, String owner, Offset coordinates) {
    final stats = type.stats;
    return Unit(
      name: stats.name,
      unitType: type,
      attack: stats.attack,
      defense: stats.defense,
      maxHP: stats.hp,
      currentHP: stats.hp,
      movement: stats.movement,
      movementRemaining: stats.movement,
      owner: owner,
      coordinates: coordinates,
    );
  }

  Unit copyWith({
    String? id,
    String? name,
    UnitType? unitType,
    int? attack,
    int? defense,
    int? maxHP,
    int? currentHP,
    int? movement,
    int? movementRemaining,
    int? level,
    int? experience,
    int? morale,
    String? owner,
    Offset? coordinates,
  }) {
    return Unit(
      id: id ?? this.id,
      name: name ?? this.name,
      unitType: unitType ?? this.unitType,
      attack: attack ?? this.attack,
      defense: defense ?? this.defense,
      maxHP: maxHP ?? this.maxHP,
      currentHP: currentHP ?? this.currentHP,
      movement: movement ?? this.movement,
      movementRemaining: movementRemaining ?? this.movementRemaining,
      level: level ?? this.level,
      experience: experience ?? this.experience,
      morale: morale ?? this.morale,
      owner: owner ?? this.owner,
      coordinates: coordinates ?? this.coordinates,
    );
  }

  void takeDamage(int amount) {
    currentHP = max(0, currentHP - amount);
  }

  void heal(int amount) {
    currentHP = min(maxHP, currentHP + amount);
  }

  void gainExperience(int amount) {
    experience += amount;
    if (experience >= level * 100) {
      levelUp();
    }
  }

  void levelUp() {
    level++;
    attack = (attack * 1.1).toInt();
    defense = (defense * 1.1).toInt();
    maxHP = (maxHP * 1.1).toInt();
    currentHP = maxHP;
  }

  void resetMovement() {
    movementRemaining = movement;
  }
}
