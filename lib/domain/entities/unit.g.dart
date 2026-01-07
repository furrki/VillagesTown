// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UnitImpl _$$UnitImplFromJson(Map<String, dynamic> json) => _$UnitImpl(
  id: const UnitIdConverter().fromJson(json['id'] as String),
  unitType: $enumDecode(_$UnitTypeEnumMap, json['unitType']),
  owner: const PlayerIdConverter().fromJson(json['owner'] as String),
  attack: (json['attack'] as num).toInt(),
  defense: (json['defense'] as num).toInt(),
  maxHP: (json['maxHP'] as num).toInt(),
  currentHP: (json['currentHP'] as num).toInt(),
  movement: (json['movement'] as num).toInt(),
  level: (json['level'] as num?)?.toInt() ?? 1,
  experience: (json['experience'] as num?)?.toInt() ?? 0,
  morale: (json['morale'] as num?)?.toInt() ?? 100,
  producedFromBuildingLevel:
      (json['producedFromBuildingLevel'] as num?)?.toInt() ?? 0,
  bonusAttack: (json['bonusAttack'] as num?)?.toInt() ?? 0,
  bonusDefense: (json['bonusDefense'] as num?)?.toInt() ?? 0,
  bonusAccuracy: (json['bonusAccuracy'] as num?)?.toDouble() ?? 0.0,
  bonusKillPotential: (json['bonusKillPotential'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$$UnitImplToJson(_$UnitImpl instance) =>
    <String, dynamic>{
      'id': const UnitIdConverter().toJson(instance.id),
      'unitType': _$UnitTypeEnumMap[instance.unitType]!,
      'owner': const PlayerIdConverter().toJson(instance.owner),
      'attack': instance.attack,
      'defense': instance.defense,
      'maxHP': instance.maxHP,
      'currentHP': instance.currentHP,
      'movement': instance.movement,
      'level': instance.level,
      'experience': instance.experience,
      'morale': instance.morale,
      'producedFromBuildingLevel': instance.producedFromBuildingLevel,
      'bonusAttack': instance.bonusAttack,
      'bonusDefense': instance.bonusDefense,
      'bonusAccuracy': instance.bonusAccuracy,
      'bonusKillPotential': instance.bonusKillPotential,
    };

const _$UnitTypeEnumMap = {
  UnitType.militia: 'militia',
  UnitType.spearman: 'spearman',
  UnitType.swordsman: 'swordsman',
  UnitType.archer: 'archer',
  UnitType.crossbowman: 'crossbowman',
  UnitType.lightCavalry: 'lightCavalry',
  UnitType.knight: 'knight',
};
