// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nationality.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NationalityImpl _$$NationalityImplFromJson(Map<String, dynamic> json) =>
    _$NationalityImpl(
      id: const NationalityIdConverter().fromJson(json['id'] as String),
      name: json['name'] as String,
      assetPath: json['assetPath'] as String,
      colorValue: (json['colorValue'] as num).toInt(),
      isMajor: json['isMajor'] as bool? ?? true,
      aggression: (json['aggression'] as num?)?.toDouble() ?? 0.7,
    );

Map<String, dynamic> _$$NationalityImplToJson(_$NationalityImpl instance) =>
    <String, dynamic>{
      'id': const NationalityIdConverter().toJson(instance.id),
      'name': instance.name,
      'assetPath': instance.assetPath,
      'colorValue': instance.colorValue,
      'isMajor': instance.isMajor,
      'aggression': instance.aggression,
    };
