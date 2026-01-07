// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'building.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BuildingImpl _$$BuildingImplFromJson(Map<String, dynamic> json) =>
    _$BuildingImpl(
      id: const BuildingIdConverter().fromJson(json['id'] as String),
      type: $enumDecode(_$BuildingTypeEnumMap, json['type']),
      level: (json['level'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$$BuildingImplToJson(_$BuildingImpl instance) =>
    <String, dynamic>{
      'id': const BuildingIdConverter().toJson(instance.id),
      'type': _$BuildingTypeEnumMap[instance.type]!,
      'level': instance.level,
    };

const _$BuildingTypeEnumMap = {
  BuildingType.farm: 'farm',
  BuildingType.lumberMill: 'lumberMill',
  BuildingType.ironMine: 'ironMine',
  BuildingType.market: 'market',
  BuildingType.barracks: 'barracks',
  BuildingType.archeryRange: 'archeryRange',
  BuildingType.stables: 'stables',
  BuildingType.fortress: 'fortress',
};
