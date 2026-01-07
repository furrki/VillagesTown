// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'army.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ArmyImpl _$$ArmyImplFromJson(Map<String, dynamic> json) => _$ArmyImpl(
  id: const ArmyIdConverter().fromJson(json['id'] as String),
  name: json['name'] as String,
  units: (json['units'] as List<dynamic>)
      .map((e) => Unit.fromJson(e as Map<String, dynamic>))
      .toList(),
  owner: const PlayerIdConverter().fromJson(json['owner'] as String),
  stationedAt: const NullableVillageIdConverter().fromJson(
    json['stationedAt'] as String?,
  ),
  destination: const NullableVillageIdConverter().fromJson(
    json['destination'] as String?,
  ),
  turnsUntilArrival: (json['turnsUntilArrival'] as num?)?.toInt() ?? 0,
  origin: const NullableVillageIdConverter().fromJson(
    json['origin'] as String?,
  ),
);

Map<String, dynamic> _$$ArmyImplToJson(_$ArmyImpl instance) =>
    <String, dynamic>{
      'id': const ArmyIdConverter().toJson(instance.id),
      'name': instance.name,
      'units': instance.units,
      'owner': const PlayerIdConverter().toJson(instance.owner),
      'stationedAt': const NullableVillageIdConverter().toJson(
        instance.stationedAt,
      ),
      'destination': const NullableVillageIdConverter().toJson(
        instance.destination,
      ),
      'turnsUntilArrival': instance.turnsUntilArrival,
      'origin': const NullableVillageIdConverter().toJson(instance.origin),
    };
