// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'village.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Village _$VillageFromJson(Map<String, dynamic> json) {
  return _Village.fromJson(json);
}

/// @nodoc
mixin _$Village {
  @VillageIdConverter()
  VillageId get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @NationalityIdConverter()
  NationalityId get originalNationality => throw _privateConstructorUsedError;
  GeoCoordinate get coordinates => throw _privateConstructorUsedError;
  @PlayerIdConverter()
  PlayerId get owner => throw _privateConstructorUsedError;
  VillageLevel get level => throw _privateConstructorUsedError;
  List<Building> get buildings => throw _privateConstructorUsedError;
  ResourceBundle get resources => throw _privateConstructorUsedError;
  double get treasury => throw _privateConstructorUsedError;
  int get population => throw _privateConstructorUsedError;
  int get happiness => throw _privateConstructorUsedError;
  int get garrisonStrength => throw _privateConstructorUsedError;
  int get garrisonMaxStrength => throw _privateConstructorUsedError;
  bool get underSiege => throw _privateConstructorUsedError;
  int get recruitsThisTurn => throw _privateConstructorUsedError;

  /// Serializes this Village to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Village
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VillageCopyWith<Village> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VillageCopyWith<$Res> {
  factory $VillageCopyWith(Village value, $Res Function(Village) then) =
      _$VillageCopyWithImpl<$Res, Village>;
  @useResult
  $Res call({
    @VillageIdConverter() VillageId id,
    String name,
    @NationalityIdConverter() NationalityId originalNationality,
    GeoCoordinate coordinates,
    @PlayerIdConverter() PlayerId owner,
    VillageLevel level,
    List<Building> buildings,
    ResourceBundle resources,
    double treasury,
    int population,
    int happiness,
    int garrisonStrength,
    int garrisonMaxStrength,
    bool underSiege,
    int recruitsThisTurn,
  });

  $GeoCoordinateCopyWith<$Res> get coordinates;
}

/// @nodoc
class _$VillageCopyWithImpl<$Res, $Val extends Village>
    implements $VillageCopyWith<$Res> {
  _$VillageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Village
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? originalNationality = null,
    Object? coordinates = null,
    Object? owner = null,
    Object? level = null,
    Object? buildings = null,
    Object? resources = null,
    Object? treasury = null,
    Object? population = null,
    Object? happiness = null,
    Object? garrisonStrength = null,
    Object? garrisonMaxStrength = null,
    Object? underSiege = null,
    Object? recruitsThisTurn = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as VillageId,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            originalNationality: null == originalNationality
                ? _value.originalNationality
                : originalNationality // ignore: cast_nullable_to_non_nullable
                      as NationalityId,
            coordinates: null == coordinates
                ? _value.coordinates
                : coordinates // ignore: cast_nullable_to_non_nullable
                      as GeoCoordinate,
            owner: null == owner
                ? _value.owner
                : owner // ignore: cast_nullable_to_non_nullable
                      as PlayerId,
            level: null == level
                ? _value.level
                : level // ignore: cast_nullable_to_non_nullable
                      as VillageLevel,
            buildings: null == buildings
                ? _value.buildings
                : buildings // ignore: cast_nullable_to_non_nullable
                      as List<Building>,
            resources: null == resources
                ? _value.resources
                : resources // ignore: cast_nullable_to_non_nullable
                      as ResourceBundle,
            treasury: null == treasury
                ? _value.treasury
                : treasury // ignore: cast_nullable_to_non_nullable
                      as double,
            population: null == population
                ? _value.population
                : population // ignore: cast_nullable_to_non_nullable
                      as int,
            happiness: null == happiness
                ? _value.happiness
                : happiness // ignore: cast_nullable_to_non_nullable
                      as int,
            garrisonStrength: null == garrisonStrength
                ? _value.garrisonStrength
                : garrisonStrength // ignore: cast_nullable_to_non_nullable
                      as int,
            garrisonMaxStrength: null == garrisonMaxStrength
                ? _value.garrisonMaxStrength
                : garrisonMaxStrength // ignore: cast_nullable_to_non_nullable
                      as int,
            underSiege: null == underSiege
                ? _value.underSiege
                : underSiege // ignore: cast_nullable_to_non_nullable
                      as bool,
            recruitsThisTurn: null == recruitsThisTurn
                ? _value.recruitsThisTurn
                : recruitsThisTurn // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }

  /// Create a copy of Village
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GeoCoordinateCopyWith<$Res> get coordinates {
    return $GeoCoordinateCopyWith<$Res>(_value.coordinates, (value) {
      return _then(_value.copyWith(coordinates: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$VillageImplCopyWith<$Res> implements $VillageCopyWith<$Res> {
  factory _$$VillageImplCopyWith(
    _$VillageImpl value,
    $Res Function(_$VillageImpl) then,
  ) = __$$VillageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @VillageIdConverter() VillageId id,
    String name,
    @NationalityIdConverter() NationalityId originalNationality,
    GeoCoordinate coordinates,
    @PlayerIdConverter() PlayerId owner,
    VillageLevel level,
    List<Building> buildings,
    ResourceBundle resources,
    double treasury,
    int population,
    int happiness,
    int garrisonStrength,
    int garrisonMaxStrength,
    bool underSiege,
    int recruitsThisTurn,
  });

  @override
  $GeoCoordinateCopyWith<$Res> get coordinates;
}

/// @nodoc
class __$$VillageImplCopyWithImpl<$Res>
    extends _$VillageCopyWithImpl<$Res, _$VillageImpl>
    implements _$$VillageImplCopyWith<$Res> {
  __$$VillageImplCopyWithImpl(
    _$VillageImpl _value,
    $Res Function(_$VillageImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Village
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? originalNationality = null,
    Object? coordinates = null,
    Object? owner = null,
    Object? level = null,
    Object? buildings = null,
    Object? resources = null,
    Object? treasury = null,
    Object? population = null,
    Object? happiness = null,
    Object? garrisonStrength = null,
    Object? garrisonMaxStrength = null,
    Object? underSiege = null,
    Object? recruitsThisTurn = null,
  }) {
    return _then(
      _$VillageImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as VillageId,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        originalNationality: null == originalNationality
            ? _value.originalNationality
            : originalNationality // ignore: cast_nullable_to_non_nullable
                  as NationalityId,
        coordinates: null == coordinates
            ? _value.coordinates
            : coordinates // ignore: cast_nullable_to_non_nullable
                  as GeoCoordinate,
        owner: null == owner
            ? _value.owner
            : owner // ignore: cast_nullable_to_non_nullable
                  as PlayerId,
        level: null == level
            ? _value.level
            : level // ignore: cast_nullable_to_non_nullable
                  as VillageLevel,
        buildings: null == buildings
            ? _value._buildings
            : buildings // ignore: cast_nullable_to_non_nullable
                  as List<Building>,
        resources: null == resources
            ? _value.resources
            : resources // ignore: cast_nullable_to_non_nullable
                  as ResourceBundle,
        treasury: null == treasury
            ? _value.treasury
            : treasury // ignore: cast_nullable_to_non_nullable
                  as double,
        population: null == population
            ? _value.population
            : population // ignore: cast_nullable_to_non_nullable
                  as int,
        happiness: null == happiness
            ? _value.happiness
            : happiness // ignore: cast_nullable_to_non_nullable
                  as int,
        garrisonStrength: null == garrisonStrength
            ? _value.garrisonStrength
            : garrisonStrength // ignore: cast_nullable_to_non_nullable
                  as int,
        garrisonMaxStrength: null == garrisonMaxStrength
            ? _value.garrisonMaxStrength
            : garrisonMaxStrength // ignore: cast_nullable_to_non_nullable
                  as int,
        underSiege: null == underSiege
            ? _value.underSiege
            : underSiege // ignore: cast_nullable_to_non_nullable
                  as bool,
        recruitsThisTurn: null == recruitsThisTurn
            ? _value.recruitsThisTurn
            : recruitsThisTurn // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$VillageImpl extends _Village {
  const _$VillageImpl({
    @VillageIdConverter() required this.id,
    required this.name,
    @NationalityIdConverter() required this.originalNationality,
    required this.coordinates,
    @PlayerIdConverter() required this.owner,
    this.level = VillageLevel.village,
    final List<Building> buildings = const [],
    this.resources = ResourceBundle.starter,
    this.treasury = 1000.0,
    this.population = 100,
    this.happiness = 75,
    this.garrisonStrength = 5,
    this.garrisonMaxStrength = 10,
    this.underSiege = false,
    this.recruitsThisTurn = 0,
  }) : _buildings = buildings,
       super._();

  factory _$VillageImpl.fromJson(Map<String, dynamic> json) =>
      _$$VillageImplFromJson(json);

  @override
  @VillageIdConverter()
  final VillageId id;
  @override
  final String name;
  @override
  @NationalityIdConverter()
  final NationalityId originalNationality;
  @override
  final GeoCoordinate coordinates;
  @override
  @PlayerIdConverter()
  final PlayerId owner;
  @override
  @JsonKey()
  final VillageLevel level;
  final List<Building> _buildings;
  @override
  @JsonKey()
  List<Building> get buildings {
    if (_buildings is EqualUnmodifiableListView) return _buildings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_buildings);
  }

  @override
  @JsonKey()
  final ResourceBundle resources;
  @override
  @JsonKey()
  final double treasury;
  @override
  @JsonKey()
  final int population;
  @override
  @JsonKey()
  final int happiness;
  @override
  @JsonKey()
  final int garrisonStrength;
  @override
  @JsonKey()
  final int garrisonMaxStrength;
  @override
  @JsonKey()
  final bool underSiege;
  @override
  @JsonKey()
  final int recruitsThisTurn;

  @override
  String toString() {
    return 'Village(id: $id, name: $name, originalNationality: $originalNationality, coordinates: $coordinates, owner: $owner, level: $level, buildings: $buildings, resources: $resources, treasury: $treasury, population: $population, happiness: $happiness, garrisonStrength: $garrisonStrength, garrisonMaxStrength: $garrisonMaxStrength, underSiege: $underSiege, recruitsThisTurn: $recruitsThisTurn)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VillageImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.originalNationality, originalNationality) ||
                other.originalNationality == originalNationality) &&
            (identical(other.coordinates, coordinates) ||
                other.coordinates == coordinates) &&
            (identical(other.owner, owner) || other.owner == owner) &&
            (identical(other.level, level) || other.level == level) &&
            const DeepCollectionEquality().equals(
              other._buildings,
              _buildings,
            ) &&
            (identical(other.resources, resources) ||
                other.resources == resources) &&
            (identical(other.treasury, treasury) ||
                other.treasury == treasury) &&
            (identical(other.population, population) ||
                other.population == population) &&
            (identical(other.happiness, happiness) ||
                other.happiness == happiness) &&
            (identical(other.garrisonStrength, garrisonStrength) ||
                other.garrisonStrength == garrisonStrength) &&
            (identical(other.garrisonMaxStrength, garrisonMaxStrength) ||
                other.garrisonMaxStrength == garrisonMaxStrength) &&
            (identical(other.underSiege, underSiege) ||
                other.underSiege == underSiege) &&
            (identical(other.recruitsThisTurn, recruitsThisTurn) ||
                other.recruitsThisTurn == recruitsThisTurn));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    originalNationality,
    coordinates,
    owner,
    level,
    const DeepCollectionEquality().hash(_buildings),
    resources,
    treasury,
    population,
    happiness,
    garrisonStrength,
    garrisonMaxStrength,
    underSiege,
    recruitsThisTurn,
  );

  /// Create a copy of Village
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VillageImplCopyWith<_$VillageImpl> get copyWith =>
      __$$VillageImplCopyWithImpl<_$VillageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VillageImplToJson(this);
  }
}

abstract class _Village extends Village {
  const factory _Village({
    @VillageIdConverter() required final VillageId id,
    required final String name,
    @NationalityIdConverter() required final NationalityId originalNationality,
    required final GeoCoordinate coordinates,
    @PlayerIdConverter() required final PlayerId owner,
    final VillageLevel level,
    final List<Building> buildings,
    final ResourceBundle resources,
    final double treasury,
    final int population,
    final int happiness,
    final int garrisonStrength,
    final int garrisonMaxStrength,
    final bool underSiege,
    final int recruitsThisTurn,
  }) = _$VillageImpl;
  const _Village._() : super._();

  factory _Village.fromJson(Map<String, dynamic> json) = _$VillageImpl.fromJson;

  @override
  @VillageIdConverter()
  VillageId get id;
  @override
  String get name;
  @override
  @NationalityIdConverter()
  NationalityId get originalNationality;
  @override
  GeoCoordinate get coordinates;
  @override
  @PlayerIdConverter()
  PlayerId get owner;
  @override
  VillageLevel get level;
  @override
  List<Building> get buildings;
  @override
  ResourceBundle get resources;
  @override
  double get treasury;
  @override
  int get population;
  @override
  int get happiness;
  @override
  int get garrisonStrength;
  @override
  int get garrisonMaxStrength;
  @override
  bool get underSiege;
  @override
  int get recruitsThisTurn;

  /// Create a copy of Village
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VillageImplCopyWith<_$VillageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
