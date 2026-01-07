import 'entity_id.dart';

/// Unique identifier for a Village entity.
class VillageId extends EntityId {
  const VillageId(super.value);

  factory VillageId.generate() => VillageId(EntityId.generateUuid());

  /// For cities with stable names (backwards compatibility during migration)
  factory VillageId.fromName(String name) => VillageId('village_$name');
}

/// Unique identifier for an Army entity.
class ArmyId extends EntityId {
  const ArmyId(super.value);

  factory ArmyId.generate() => ArmyId(EntityId.generateUuid());
}

/// Unique identifier for a Player entity.
/// Uses predefined constants for known players/factions.
class PlayerId extends EntityId {
  const PlayerId(super.value);

  // Human player
  static const player = PlayerId('player');

  // Major factions (singular form - standardized)
  static const byzantine = PlayerId('byzantine');
  static const ottoman = PlayerId('ottoman');
  static const crusader = PlayerId('crusader');

  // Minor factions
  static const bulgarian = PlayerId('bulgarian');
  static const serbian = PlayerId('serbian');
  static const armenian = PlayerId('armenian');
  static const mamluk = PlayerId('mamluk');

  // Special
  static const neutral = PlayerId('neutral');

  /// All AI player IDs
  static const List<PlayerId> allAI = [
    byzantine,
    ottoman,
    crusader,
    bulgarian,
    serbian,
    armenian,
    mamluk,
  ];

  /// All playable factions (excludes neutral)
  static const List<PlayerId> allFactions = [
    player,
    byzantine,
    ottoman,
    crusader,
    bulgarian,
    serbian,
    armenian,
    mamluk,
  ];

  bool get isHuman => this == player;
  bool get isNeutral => this == neutral;
  bool get isAI => !isHuman && !isNeutral;
}

/// Unique identifier for a Unit entity.
class UnitId extends EntityId {
  const UnitId(super.value);

  factory UnitId.generate() => UnitId(EntityId.generateUuid());
}

/// Unique identifier for a Building entity.
class BuildingId extends EntityId {
  const BuildingId(super.value);

  factory BuildingId.generate() => BuildingId(EntityId.generateUuid());
}

/// Identifier for a Nationality/Faction definition.
/// Matches PlayerId values for consistency.
class NationalityId extends EntityId {
  const NationalityId(super.value);

  // Major factions
  static const byzantine = NationalityId('byzantine');
  static const ottoman = NationalityId('ottoman');
  static const crusader = NationalityId('crusader');

  // Minor factions
  static const bulgarian = NationalityId('bulgarian');
  static const serbian = NationalityId('serbian');
  static const armenian = NationalityId('armenian');
  static const mamluk = NationalityId('mamluk');

  /// All nationalities
  static const List<NationalityId> all = [
    byzantine,
    ottoman,
    crusader,
    bulgarian,
    serbian,
    armenian,
    mamluk,
  ];

  /// Major faction nationalities
  static const List<NationalityId> major = [
    byzantine,
    ottoman,
    crusader,
  ];

  /// Minor faction nationalities
  static const List<NationalityId> minor = [
    bulgarian,
    serbian,
    armenian,
    mamluk,
  ];

  bool get isMajor => major.contains(this);

  /// Convert to matching PlayerId
  PlayerId toPlayerId() => PlayerId(value);
}

/// Unique identifier for a BattleRecord.
class BattleId extends EntityId {
  const BattleId(super.value);

  factory BattleId.generate() => BattleId(EntityId.generateUuid());
}
