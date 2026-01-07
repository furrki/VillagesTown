import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/types/typed_ids.dart';
import '../../core/types/json_converters.dart';

part 'nationality.freezed.dart';
part 'nationality.g.dart';

/// AI personality types for faction behavior.
enum AIPersonality {
  aggressive(
    description: 'Aggressive',
    aggressionBias: 0.9,
    economicBias: 0.3,
    expansionBias: 0.8,
  ),
  economic(
    description: 'Economic',
    aggressionBias: 0.3,
    economicBias: 0.9,
    expansionBias: 0.5,
  ),
  balanced(
    description: 'Balanced',
    aggressionBias: 0.6,
    economicBias: 0.6,
    expansionBias: 0.6,
  ),
  defensive(
    description: 'Defensive',
    aggressionBias: 0.3,
    economicBias: 0.5,
    expansionBias: 0.3,
  );

  final String description;
  final double aggressionBias;
  final double economicBias;
  final double expansionBias;

  const AIPersonality({
    required this.description,
    required this.aggressionBias,
    required this.economicBias,
    required this.expansionBias,
  });
}

/// Nationality/Faction definition.
@freezed
class Nationality with _$Nationality {
  const Nationality._();

  const factory Nationality({
    @NationalityIdConverter() required NationalityId id,
    required String name,
    required String assetPath,
    required int colorValue,
    @Default(true) bool isMajor,
    @Default(0.7) double aggression,
  }) = _Nationality;

  Color get color => Color(colorValue);

  factory Nationality.fromJson(Map<String, dynamic> json) =>
      _$NationalityFromJson(json);

  // === MAJOR FACTIONS ===
  static const byzantine = Nationality(
    id: NationalityId.byzantine,
    name: 'Byzantines',
    assetPath: 'assets/byzantium.png',
    colorValue: 0xFF7B1FA2,
    isMajor: true,
    aggression: 0.6,
  );

  static const ottoman = Nationality(
    id: NationalityId.ottoman,
    name: 'Ottomans',
    assetPath: 'assets/ottoman.png',
    colorValue: 0xFF2E7D32,
    isMajor: true,
    aggression: 0.75,
  );

  static const crusader = Nationality(
    id: NationalityId.crusader,
    name: 'Crusaders',
    assetPath: 'assets/crusaders.png',
    colorValue: 0xFFD32F2F,
    isMajor: true,
    aggression: 0.7,
  );

  // === MINOR FACTIONS ===
  static const bulgarian = Nationality(
    id: NationalityId.bulgarian,
    name: 'Bulgaria',
    assetPath: 'assets/bulgar.png',
    colorValue: 0xFF4E342E,
    isMajor: false,
    aggression: 0.4,
  );

  static const serbian = Nationality(
    id: NationalityId.serbian,
    name: 'Serbia',
    assetPath: 'assets/srb.png',
    colorValue: 0xFFC62828,
    isMajor: false,
    aggression: 0.45,
  );

  static const armenian = Nationality(
    id: NationalityId.armenian,
    name: 'Armenia',
    assetPath: 'assets/armenia.png',
    colorValue: 0xFFFF8F00,
    isMajor: false,
    aggression: 0.35,
  );

  static const mamluk = Nationality(
    id: NationalityId.mamluk,
    name: 'Mamluks',
    assetPath: 'assets/mamluk.png',
    colorValue: 0xFFFBC02D,
    isMajor: false,
    aggression: 0.5,
  );

  static List<Nationality> get major => [byzantine, ottoman, crusader];
  static List<Nationality> get minor => [bulgarian, serbian, armenian, mamluk];
  static List<Nationality> get all => [...major, ...minor];

  /// Get nationality by ID.
  static Nationality? byId(NationalityId id) {
    return all.where((n) => n.id == id).firstOrNull;
  }

  /// Get default AI personality for this faction.
  AIPersonality get defaultPersonality => switch (id) {
        NationalityId.byzantine => AIPersonality.balanced,
        NationalityId.ottoman => AIPersonality.aggressive,
        NationalityId.crusader => AIPersonality.aggressive,
        NationalityId.bulgarian => AIPersonality.defensive,
        NationalityId.serbian => AIPersonality.defensive,
        NationalityId.armenian => AIPersonality.defensive,
        NationalityId.mamluk => AIPersonality.balanced,
        _ => AIPersonality.balanced,
      };
}
