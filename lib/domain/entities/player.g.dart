// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PlayerImpl _$$PlayerImplFromJson(Map<String, dynamic> json) => _$PlayerImpl(
  id: const PlayerIdConverter().fromJson(json['id'] as String),
  name: json['name'] as String,
  nationalityId: const NationalityIdConverter().fromJson(
    json['nationalityId'] as String,
  ),
  isHuman: json['isHuman'] as bool,
  villageIds: json['villageIds'] == null
      ? const []
      : const VillageIdListConverter().fromJson(json['villageIds'] as List),
  isEliminated: json['isEliminated'] as bool? ?? false,
  aiPersonality: $enumDecodeNullable(
    _$AIPersonalityEnumMap,
    json['aiPersonality'],
  ),
);

Map<String, dynamic> _$$PlayerImplToJson(_$PlayerImpl instance) =>
    <String, dynamic>{
      'id': const PlayerIdConverter().toJson(instance.id),
      'name': instance.name,
      'nationalityId': const NationalityIdConverter().toJson(
        instance.nationalityId,
      ),
      'isHuman': instance.isHuman,
      'villageIds': const VillageIdListConverter().toJson(instance.villageIds),
      'isEliminated': instance.isEliminated,
      'aiPersonality': _$AIPersonalityEnumMap[instance.aiPersonality],
    };

const _$AIPersonalityEnumMap = {
  AIPersonality.aggressive: 'aggressive',
  AIPersonality.economic: 'economic',
  AIPersonality.balanced: 'balanced',
  AIPersonality.defensive: 'defensive',
};
