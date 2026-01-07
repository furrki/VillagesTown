import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/types/typed_ids.dart';
import '../../core/types/json_converters.dart';
import 'nationality.dart';

part 'player.freezed.dart';
part 'player.g.dart';

/// Immutable player entity.
@freezed
class Player with _$Player {
  const Player._();

  const factory Player({
    @PlayerIdConverter() required PlayerId id,
    required String name,
    @NationalityIdConverter() required NationalityId nationalityId,
    required bool isHuman,
    @VillageIdListConverter() @Default([]) List<VillageId> villageIds,
    @Default(false) bool isEliminated,
    AIPersonality? aiPersonality,
  }) = _Player;

  factory Player.fromJson(Map<String, dynamic> json) => _$PlayerFromJson(json);

  // === Computed properties ===

  bool get isAI => !isHuman;
  bool get isNeutral => id == PlayerId.neutral;
  bool get isActive => !isEliminated && villageIds.isNotEmpty;
  int get villageCount => villageIds.length;

  /// Get the nationality definition.
  Nationality? get nationality => Nationality.byId(nationalityId);

  // === Factory methods ===

  /// Create human player.
  factory Player.human(NationalityId nationalityId) => Player(
        id: PlayerId.player,
        name: 'Player',
        nationalityId: nationalityId,
        isHuman: true,
      );

  /// Create AI player for a faction.
  factory Player.ai({
    required PlayerId id,
    required String name,
    required NationalityId nationalityId,
    AIPersonality? personality,
  }) =>
      Player(
        id: id,
        name: name,
        nationalityId: nationalityId,
        isHuman: false,
        aiPersonality: personality ?? Nationality.byId(nationalityId)?.defaultPersonality,
      );

  /// Create neutral "player" for unowned villages.
  static const neutral = Player(
    id: PlayerId.neutral,
    name: 'Neutral',
    nationalityId: NationalityId.byzantine, // Placeholder
    isHuman: false,
    isEliminated: false,
  );

  /// Create all default players for a new game.
  static List<Player> createAllPlayers(NationalityId humanNationality) => [
        Player.human(humanNationality),
        Player.ai(
          id: PlayerId.byzantine,
          name: 'Byzantines',
          nationalityId: NationalityId.byzantine,
          personality: AIPersonality.balanced,
        ),
        Player.ai(
          id: PlayerId.ottoman,
          name: 'Ottomans',
          nationalityId: NationalityId.ottoman,
          personality: AIPersonality.aggressive,
        ),
        Player.ai(
          id: PlayerId.crusader,
          name: 'Crusaders',
          nationalityId: NationalityId.crusader,
          personality: AIPersonality.aggressive,
        ),
        Player.ai(
          id: PlayerId.bulgarian,
          name: 'Bulgaria',
          nationalityId: NationalityId.bulgarian,
          personality: AIPersonality.defensive,
        ),
        Player.ai(
          id: PlayerId.serbian,
          name: 'Serbia',
          nationalityId: NationalityId.serbian,
          personality: AIPersonality.defensive,
        ),
        Player.ai(
          id: PlayerId.armenian,
          name: 'Armenia',
          nationalityId: NationalityId.armenian,
          personality: AIPersonality.defensive,
        ),
        Player.ai(
          id: PlayerId.mamluk,
          name: 'Mamluks',
          nationalityId: NationalityId.mamluk,
          personality: AIPersonality.balanced,
        ),
      ];
}
