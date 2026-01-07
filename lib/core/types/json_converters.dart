import 'package:json_annotation/json_annotation.dart';
import 'typed_ids.dart';

/// JSON converter for VillageId.
class VillageIdConverter implements JsonConverter<VillageId, String> {
  const VillageIdConverter();

  @override
  VillageId fromJson(String json) => VillageId(json);

  @override
  String toJson(VillageId object) => object.value;
}

/// JSON converter for nullable VillageId.
class NullableVillageIdConverter implements JsonConverter<VillageId?, String?> {
  const NullableVillageIdConverter();

  @override
  VillageId? fromJson(String? json) => json != null ? VillageId(json) : null;

  @override
  String? toJson(VillageId? object) => object?.value;
}

/// JSON converter for ArmyId.
class ArmyIdConverter implements JsonConverter<ArmyId, String> {
  const ArmyIdConverter();

  @override
  ArmyId fromJson(String json) => ArmyId(json);

  @override
  String toJson(ArmyId object) => object.value;
}

/// JSON converter for nullable ArmyId.
class NullableArmyIdConverter implements JsonConverter<ArmyId?, String?> {
  const NullableArmyIdConverter();

  @override
  ArmyId? fromJson(String? json) => json != null ? ArmyId(json) : null;

  @override
  String? toJson(ArmyId? object) => object?.value;
}

/// JSON converter for PlayerId.
class PlayerIdConverter implements JsonConverter<PlayerId, String> {
  const PlayerIdConverter();

  @override
  PlayerId fromJson(String json) => PlayerId(json);

  @override
  String toJson(PlayerId object) => object.value;
}

/// JSON converter for nullable PlayerId.
class NullablePlayerIdConverter implements JsonConverter<PlayerId?, String?> {
  const NullablePlayerIdConverter();

  @override
  PlayerId? fromJson(String? json) => json != null ? PlayerId(json) : null;

  @override
  String? toJson(PlayerId? object) => object?.value;
}

/// JSON converter for UnitId.
class UnitIdConverter implements JsonConverter<UnitId, String> {
  const UnitIdConverter();

  @override
  UnitId fromJson(String json) => UnitId(json);

  @override
  String toJson(UnitId object) => object.value;
}

/// JSON converter for BuildingId.
class BuildingIdConverter implements JsonConverter<BuildingId, String> {
  const BuildingIdConverter();

  @override
  BuildingId fromJson(String json) => BuildingId(json);

  @override
  String toJson(BuildingId object) => object.value;
}

/// JSON converter for NationalityId.
class NationalityIdConverter implements JsonConverter<NationalityId, String> {
  const NationalityIdConverter();

  @override
  NationalityId fromJson(String json) => NationalityId(json);

  @override
  String toJson(NationalityId object) => object.value;
}

/// JSON converter for BattleId.
class BattleIdConverter implements JsonConverter<BattleId, String> {
  const BattleIdConverter();

  @override
  BattleId fromJson(String json) => BattleId(json);

  @override
  String toJson(BattleId object) => object.value;
}

/// JSON converter for List<VillageId>.
class VillageIdListConverter implements JsonConverter<List<VillageId>, List<dynamic>> {
  const VillageIdListConverter();

  @override
  List<VillageId> fromJson(List<dynamic> json) =>
      json.map((e) => VillageId(e as String)).toList();

  @override
  List<dynamic> toJson(List<VillageId> object) =>
      object.map((e) => e.value).toList();
}

/// JSON converter for Set<VillageId>.
class VillageIdSetConverter implements JsonConverter<Set<VillageId>, List<dynamic>> {
  const VillageIdSetConverter();

  @override
  Set<VillageId> fromJson(List<dynamic> json) =>
      json.map((e) => VillageId(e as String)).toSet();

  @override
  List<dynamic> toJson(Set<VillageId> object) =>
      object.map((e) => e.value).toList();
}

/// JSON converter for Map<VillageId, Village> - handled by json_serializable with custom key.
class VillageMapConverter implements JsonConverter<Map<VillageId, dynamic>, Map<String, dynamic>> {
  const VillageMapConverter();

  @override
  Map<VillageId, dynamic> fromJson(Map<String, dynamic> json) =>
      json.map((k, v) => MapEntry(VillageId(k), v));

  @override
  Map<String, dynamic> toJson(Map<VillageId, dynamic> object) =>
      object.map((k, v) => MapEntry(k.value, v));
}

/// JSON converter for Map<ArmyId, Army>.
class ArmyMapConverter implements JsonConverter<Map<ArmyId, dynamic>, Map<String, dynamic>> {
  const ArmyMapConverter();

  @override
  Map<ArmyId, dynamic> fromJson(Map<String, dynamic> json) =>
      json.map((k, v) => MapEntry(ArmyId(k), v));

  @override
  Map<String, dynamic> toJson(Map<ArmyId, dynamic> object) =>
      object.map((k, v) => MapEntry(k.value, v));
}

/// JSON converter for Map<PlayerId, Player>.
class PlayerMapConverter implements JsonConverter<Map<PlayerId, dynamic>, Map<String, dynamic>> {
  const PlayerMapConverter();

  @override
  Map<PlayerId, dynamic> fromJson(Map<String, dynamic> json) =>
      json.map((k, v) => MapEntry(PlayerId(k), v));

  @override
  Map<String, dynamic> toJson(Map<PlayerId, dynamic> object) =>
      object.map((k, v) => MapEntry(k.value, v));
}

/// JSON converter for Map<VillageId, Set<VillageId>> (connections).
class ConnectionsMapConverter implements JsonConverter<Map<VillageId, Set<VillageId>>, Map<String, dynamic>> {
  const ConnectionsMapConverter();

  @override
  Map<VillageId, Set<VillageId>> fromJson(Map<String, dynamic> json) =>
      json.map((k, v) => MapEntry(
          VillageId(k),
          (v as List<dynamic>).map((e) => VillageId(e as String)).toSet()));

  @override
  Map<String, dynamic> toJson(Map<VillageId, Set<VillageId>> object) =>
      object.map((k, v) => MapEntry(k.value, v.map((e) => e.value).toList()));
}

/// JSON converter for nullable PlayerId.
class NullablePlayerIdConverterForJson implements JsonConverter<PlayerId?, String?> {
  const NullablePlayerIdConverterForJson();

  @override
  PlayerId? fromJson(String? json) => json != null ? PlayerId(json) : null;

  @override
  String? toJson(PlayerId? object) => object?.value;
}
