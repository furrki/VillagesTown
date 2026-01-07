// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'army.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Army _$ArmyFromJson(Map<String, dynamic> json) {
  return _Army.fromJson(json);
}

/// @nodoc
mixin _$Army {
  @ArmyIdConverter()
  ArmyId get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  List<Unit> get units => throw _privateConstructorUsedError;
  @PlayerIdConverter()
  PlayerId get owner => throw _privateConstructorUsedError;
  @NullableVillageIdConverter()
  VillageId? get stationedAt => throw _privateConstructorUsedError;
  @NullableVillageIdConverter()
  VillageId? get destination => throw _privateConstructorUsedError;
  int get turnsUntilArrival => throw _privateConstructorUsedError;
  @NullableVillageIdConverter()
  VillageId? get origin => throw _privateConstructorUsedError;

  /// Serializes this Army to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Army
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ArmyCopyWith<Army> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ArmyCopyWith<$Res> {
  factory $ArmyCopyWith(Army value, $Res Function(Army) then) =
      _$ArmyCopyWithImpl<$Res, Army>;
  @useResult
  $Res call({
    @ArmyIdConverter() ArmyId id,
    String name,
    List<Unit> units,
    @PlayerIdConverter() PlayerId owner,
    @NullableVillageIdConverter() VillageId? stationedAt,
    @NullableVillageIdConverter() VillageId? destination,
    int turnsUntilArrival,
    @NullableVillageIdConverter() VillageId? origin,
  });
}

/// @nodoc
class _$ArmyCopyWithImpl<$Res, $Val extends Army>
    implements $ArmyCopyWith<$Res> {
  _$ArmyCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Army
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? units = null,
    Object? owner = null,
    Object? stationedAt = freezed,
    Object? destination = freezed,
    Object? turnsUntilArrival = null,
    Object? origin = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as ArmyId,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            units: null == units
                ? _value.units
                : units // ignore: cast_nullable_to_non_nullable
                      as List<Unit>,
            owner: null == owner
                ? _value.owner
                : owner // ignore: cast_nullable_to_non_nullable
                      as PlayerId,
            stationedAt: freezed == stationedAt
                ? _value.stationedAt
                : stationedAt // ignore: cast_nullable_to_non_nullable
                      as VillageId?,
            destination: freezed == destination
                ? _value.destination
                : destination // ignore: cast_nullable_to_non_nullable
                      as VillageId?,
            turnsUntilArrival: null == turnsUntilArrival
                ? _value.turnsUntilArrival
                : turnsUntilArrival // ignore: cast_nullable_to_non_nullable
                      as int,
            origin: freezed == origin
                ? _value.origin
                : origin // ignore: cast_nullable_to_non_nullable
                      as VillageId?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ArmyImplCopyWith<$Res> implements $ArmyCopyWith<$Res> {
  factory _$$ArmyImplCopyWith(
    _$ArmyImpl value,
    $Res Function(_$ArmyImpl) then,
  ) = __$$ArmyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @ArmyIdConverter() ArmyId id,
    String name,
    List<Unit> units,
    @PlayerIdConverter() PlayerId owner,
    @NullableVillageIdConverter() VillageId? stationedAt,
    @NullableVillageIdConverter() VillageId? destination,
    int turnsUntilArrival,
    @NullableVillageIdConverter() VillageId? origin,
  });
}

/// @nodoc
class __$$ArmyImplCopyWithImpl<$Res>
    extends _$ArmyCopyWithImpl<$Res, _$ArmyImpl>
    implements _$$ArmyImplCopyWith<$Res> {
  __$$ArmyImplCopyWithImpl(_$ArmyImpl _value, $Res Function(_$ArmyImpl) _then)
    : super(_value, _then);

  /// Create a copy of Army
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? units = null,
    Object? owner = null,
    Object? stationedAt = freezed,
    Object? destination = freezed,
    Object? turnsUntilArrival = null,
    Object? origin = freezed,
  }) {
    return _then(
      _$ArmyImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as ArmyId,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        units: null == units
            ? _value._units
            : units // ignore: cast_nullable_to_non_nullable
                  as List<Unit>,
        owner: null == owner
            ? _value.owner
            : owner // ignore: cast_nullable_to_non_nullable
                  as PlayerId,
        stationedAt: freezed == stationedAt
            ? _value.stationedAt
            : stationedAt // ignore: cast_nullable_to_non_nullable
                  as VillageId?,
        destination: freezed == destination
            ? _value.destination
            : destination // ignore: cast_nullable_to_non_nullable
                  as VillageId?,
        turnsUntilArrival: null == turnsUntilArrival
            ? _value.turnsUntilArrival
            : turnsUntilArrival // ignore: cast_nullable_to_non_nullable
                  as int,
        origin: freezed == origin
            ? _value.origin
            : origin // ignore: cast_nullable_to_non_nullable
                  as VillageId?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ArmyImpl extends _Army {
  const _$ArmyImpl({
    @ArmyIdConverter() required this.id,
    required this.name,
    required final List<Unit> units,
    @PlayerIdConverter() required this.owner,
    @NullableVillageIdConverter() this.stationedAt,
    @NullableVillageIdConverter() this.destination,
    this.turnsUntilArrival = 0,
    @NullableVillageIdConverter() this.origin,
  }) : _units = units,
       super._();

  factory _$ArmyImpl.fromJson(Map<String, dynamic> json) =>
      _$$ArmyImplFromJson(json);

  @override
  @ArmyIdConverter()
  final ArmyId id;
  @override
  final String name;
  final List<Unit> _units;
  @override
  List<Unit> get units {
    if (_units is EqualUnmodifiableListView) return _units;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_units);
  }

  @override
  @PlayerIdConverter()
  final PlayerId owner;
  @override
  @NullableVillageIdConverter()
  final VillageId? stationedAt;
  @override
  @NullableVillageIdConverter()
  final VillageId? destination;
  @override
  @JsonKey()
  final int turnsUntilArrival;
  @override
  @NullableVillageIdConverter()
  final VillageId? origin;

  @override
  String toString() {
    return 'Army(id: $id, name: $name, units: $units, owner: $owner, stationedAt: $stationedAt, destination: $destination, turnsUntilArrival: $turnsUntilArrival, origin: $origin)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ArmyImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(other._units, _units) &&
            (identical(other.owner, owner) || other.owner == owner) &&
            (identical(other.stationedAt, stationedAt) ||
                other.stationedAt == stationedAt) &&
            (identical(other.destination, destination) ||
                other.destination == destination) &&
            (identical(other.turnsUntilArrival, turnsUntilArrival) ||
                other.turnsUntilArrival == turnsUntilArrival) &&
            (identical(other.origin, origin) || other.origin == origin));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    const DeepCollectionEquality().hash(_units),
    owner,
    stationedAt,
    destination,
    turnsUntilArrival,
    origin,
  );

  /// Create a copy of Army
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ArmyImplCopyWith<_$ArmyImpl> get copyWith =>
      __$$ArmyImplCopyWithImpl<_$ArmyImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ArmyImplToJson(this);
  }
}

abstract class _Army extends Army {
  const factory _Army({
    @ArmyIdConverter() required final ArmyId id,
    required final String name,
    required final List<Unit> units,
    @PlayerIdConverter() required final PlayerId owner,
    @NullableVillageIdConverter() final VillageId? stationedAt,
    @NullableVillageIdConverter() final VillageId? destination,
    final int turnsUntilArrival,
    @NullableVillageIdConverter() final VillageId? origin,
  }) = _$ArmyImpl;
  const _Army._() : super._();

  factory _Army.fromJson(Map<String, dynamic> json) = _$ArmyImpl.fromJson;

  @override
  @ArmyIdConverter()
  ArmyId get id;
  @override
  String get name;
  @override
  List<Unit> get units;
  @override
  @PlayerIdConverter()
  PlayerId get owner;
  @override
  @NullableVillageIdConverter()
  VillageId? get stationedAt;
  @override
  @NullableVillageIdConverter()
  VillageId? get destination;
  @override
  int get turnsUntilArrival;
  @override
  @NullableVillageIdConverter()
  VillageId? get origin;

  /// Create a copy of Army
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ArmyImplCopyWith<_$ArmyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
