import 'package:flutter/material.dart';

/// Resource types in the game.
/// Kept compatible with existing Resource enum during migration.
enum ResourceType {
  food('Food', '🌾', Colors.green),
  wood('Wood', '🪵', Colors.brown),
  iron('Iron', '⚔️', Colors.grey),
  gold('Gold', '💰', Colors.amber);

  final String displayName;
  final String emoji;
  final Color color;

  const ResourceType(this.displayName, this.emoji, this.color);
}

/// Immutable bundle of resources.
/// Replaces mutable `Map<Resource, int>` with a type-safe, immutable value object.
class ResourceBundle {
  final int food;
  final int wood;
  final int iron;
  final int gold;

  const ResourceBundle({
    this.food = 0,
    this.wood = 0,
    this.iron = 0,
    this.gold = 0,
  });

  /// Create from a map (for migration from old code).
  factory ResourceBundle.fromMap(Map<dynamic, int> map) {
    return ResourceBundle(
      food: map.entries
              .firstWhere(
                (e) => e.key.toString().toLowerCase().contains('food'),
                orElse: () => MapEntry('', 0),
              )
              .value,
      wood: map.entries
              .firstWhere(
                (e) => e.key.toString().toLowerCase().contains('wood'),
                orElse: () => MapEntry('', 0),
              )
              .value,
      iron: map.entries
              .firstWhere(
                (e) => e.key.toString().toLowerCase().contains('iron'),
                orElse: () => MapEntry('', 0),
              )
              .value,
      gold: map.entries
              .firstWhere(
                (e) => e.key.toString().toLowerCase().contains('gold'),
                orElse: () => MapEntry('', 0),
              )
              .value,
    );
  }

  // === Predefined bundles ===

  static const empty = ResourceBundle();

  static const starter = ResourceBundle(
    food: 100,
    wood: 100,
    iron: 50,
    gold: 300,
  );

  static const neutralVillage = ResourceBundle(
    food: 20,
    wood: 15,
    iron: 5,
    gold: 30,
  );

  // === Operators ===

  ResourceBundle operator +(ResourceBundle other) => ResourceBundle(
        food: food + other.food,
        wood: wood + other.wood,
        iron: iron + other.iron,
        gold: gold + other.gold,
      );

  ResourceBundle operator -(ResourceBundle other) => ResourceBundle(
        food: (food - other.food).clamp(0, 999999),
        wood: (wood - other.wood).clamp(0, 999999),
        iron: (iron - other.iron).clamp(0, 999999),
        gold: (gold - other.gold).clamp(0, 999999),
      );

  ResourceBundle operator *(int multiplier) => ResourceBundle(
        food: food * multiplier,
        wood: wood * multiplier,
        iron: iron * multiplier,
        gold: gold * multiplier,
      );

  ResourceBundle operator ~/(int divisor) => ResourceBundle(
        food: food ~/ divisor,
        wood: wood ~/ divisor,
        iron: iron ~/ divisor,
        gold: gold ~/ divisor,
      );

  /// Unary negation.
  ResourceBundle operator -() => ResourceBundle(
        food: -food,
        wood: -wood,
        iron: -iron,
        gold: -gold,
      );

  /// Indexer for accessing by ResourceType.
  int operator [](ResourceType type) => switch (type) {
        ResourceType.food => food,
        ResourceType.wood => wood,
        ResourceType.iron => iron,
        ResourceType.gold => gold,
      };

  // === Queries ===

  /// Check if we can afford a cost.
  bool canAfford(ResourceBundle cost) =>
      food >= cost.food &&
      wood >= cost.wood &&
      iron >= cost.iron &&
      gold >= cost.gold;

  /// Check if all resources are zero.
  bool get isEmpty => food == 0 && wood == 0 && iron == 0 && gold == 0;

  /// Check if any resource is non-zero.
  bool get isNotEmpty => !isEmpty;

  /// Total sum of all resources.
  int get total => food + wood + iron + gold;

  /// Get the deficit when trying to afford a cost.
  ResourceBundle deficit(ResourceBundle cost) => ResourceBundle(
        food: (cost.food - food).clamp(0, 999999),
        wood: (cost.wood - wood).clamp(0, 999999),
        iron: (cost.iron - iron).clamp(0, 999999),
        gold: (cost.gold - gold).clamp(0, 999999),
      );

  // === Transformations ===

  /// Create a copy with modified values.
  ResourceBundle copyWith({
    int? food,
    int? wood,
    int? iron,
    int? gold,
  }) =>
      ResourceBundle(
        food: food ?? this.food,
        wood: wood ?? this.wood,
        iron: iron ?? this.iron,
        gold: gold ?? this.gold,
      );

  /// Scale by a double factor (rounds down).
  ResourceBundle scale(double factor) => ResourceBundle(
        food: (food * factor).floor(),
        wood: (wood * factor).floor(),
        iron: (iron * factor).floor(),
        gold: (gold * factor).floor(),
      );

  /// Convert to Map for compatibility with old code.
  Map<ResourceType, int> toMap() => {
        ResourceType.food: food,
        ResourceType.wood: wood,
        ResourceType.iron: iron,
        ResourceType.gold: gold,
      };

  /// Convert to JSON-serializable map.
  Map<String, int> toJson() => {
        'food': food,
        'wood': wood,
        'iron': iron,
        'gold': gold,
      };

  /// Create from JSON map.
  factory ResourceBundle.fromJson(Map<String, dynamic> json) => ResourceBundle(
        food: json['food'] as int? ?? 0,
        wood: json['wood'] as int? ?? 0,
        iron: json['iron'] as int? ?? 0,
        gold: json['gold'] as int? ?? 0,
      );

  // === Equality ===

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResourceBundle &&
          runtimeType == other.runtimeType &&
          food == other.food &&
          wood == other.wood &&
          iron == other.iron &&
          gold == other.gold;

  @override
  int get hashCode => Object.hash(food, wood, iron, gold);

  @override
  String toString() =>
      'ResourceBundle(food: $food, wood: $wood, iron: $iron, gold: $gold)';

  /// Display string with emojis.
  String toDisplayString() =>
      '🌾$food 🪵$wood ⚔️$iron 💰$gold';
}
