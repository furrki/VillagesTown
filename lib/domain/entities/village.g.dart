// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'village.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VillageImpl _$$VillageImplFromJson(Map<String, dynamic> json) =>
    _$VillageImpl(
      id: const VillageIdConverter().fromJson(json['id'] as String),
      name: json['name'] as String,
      originalNationality: const NationalityIdConverter().fromJson(
        json['originalNationality'] as String,
      ),
      coordinates: GeoCoordinate.fromJson(
        json['coordinates'] as Map<String, dynamic>,
      ),
      owner: const PlayerIdConverter().fromJson(json['owner'] as String),
      level:
          $enumDecodeNullable(_$VillageLevelEnumMap, json['level']) ??
          VillageLevel.village,
      buildings:
          (json['buildings'] as List<dynamic>?)
              ?.map((e) => Building.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      resources: json['resources'] == null
          ? ResourceBundle.starter
          : ResourceBundle.fromJson(json['resources'] as Map<String, dynamic>),
      treasury: (json['treasury'] as num?)?.toDouble() ?? 1000.0,
      population: (json['population'] as num?)?.toInt() ?? 100,
      happiness: (json['happiness'] as num?)?.toInt() ?? 75,
      garrisonStrength: (json['garrisonStrength'] as num?)?.toInt() ?? 5,
      garrisonMaxStrength: (json['garrisonMaxStrength'] as num?)?.toInt() ?? 10,
      underSiege: json['underSiege'] as bool? ?? false,
      recruitsThisTurn: (json['recruitsThisTurn'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$VillageImplToJson(_$VillageImpl instance) =>
    <String, dynamic>{
      'id': const VillageIdConverter().toJson(instance.id),
      'name': instance.name,
      'originalNationality': const NationalityIdConverter().toJson(
        instance.originalNationality,
      ),
      'coordinates': instance.coordinates,
      'owner': const PlayerIdConverter().toJson(instance.owner),
      'level': _$VillageLevelEnumMap[instance.level]!,
      'buildings': instance.buildings,
      'resources': instance.resources,
      'treasury': instance.treasury,
      'population': instance.population,
      'happiness': instance.happiness,
      'garrisonStrength': instance.garrisonStrength,
      'garrisonMaxStrength': instance.garrisonMaxStrength,
      'underSiege': instance.underSiege,
      'recruitsThisTurn': instance.recruitsThisTurn,
    };

const _$VillageLevelEnumMap = {
  VillageLevel.village: 'village',
  VillageLevel.town: 'town',
  VillageLevel.district: 'district',
  VillageLevel.castle: 'castle',
  VillageLevel.city: 'city',
};
