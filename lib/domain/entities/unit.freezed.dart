// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'unit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Unit _$UnitFromJson(Map<String, dynamic> json) {
  return _Unit.fromJson(json);
}

/// @nodoc
mixin _$Unit {
  @UnitIdConverter()
  UnitId get id => throw _privateConstructorUsedError;
  UnitType get unitType => throw _privateConstructorUsedError;
  @PlayerIdConverter()
  PlayerId get owner => throw _privateConstructorUsedError;
  int get attack => throw _privateConstructorUsedError;
  int get defense => throw _privateConstructorUsedError;
  int get maxHP => throw _privateConstructorUsedError;
  int get currentHP => throw _privateConstructorUsedError;
  int get movement => throw _privateConstructorUsedError;
  int get level => throw _privateConstructorUsedError;
  int get experience => throw _privateConstructorUsedError;
  int get morale =>
      throw _privateConstructorUsedError; // Building-based bonuses (applied at creation time)
  int get producedFromBuildingLevel => throw _privateConstructorUsedError;
  int get bonusAttack => throw _privateConstructorUsedError;
  int get bonusDefense => throw _privateConstructorUsedError;
  double get bonusAccuracy => throw _privateConstructorUsedError;
  double get bonusKillPotential => throw _privateConstructorUsedError;

  /// Serializes this Unit to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Unit
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UnitCopyWith<Unit> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UnitCopyWith<$Res> {
  factory $UnitCopyWith(Unit value, $Res Function(Unit) then) =
      _$UnitCopyWithImpl<$Res, Unit>;
  @useResult
  $Res call({
    @UnitIdConverter() UnitId id,
    UnitType unitType,
    @PlayerIdConverter() PlayerId owner,
    int attack,
    int defense,
    int maxHP,
    int currentHP,
    int movement,
    int level,
    int experience,
    int morale,
    int producedFromBuildingLevel,
    int bonusAttack,
    int bonusDefense,
    double bonusAccuracy,
    double bonusKillPotential,
  });
}

/// @nodoc
class _$UnitCopyWithImpl<$Res, $Val extends Unit>
    implements $UnitCopyWith<$Res> {
  _$UnitCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Unit
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? unitType = null,
    Object? owner = null,
    Object? attack = null,
    Object? defense = null,
    Object? maxHP = null,
    Object? currentHP = null,
    Object? movement = null,
    Object? level = null,
    Object? experience = null,
    Object? morale = null,
    Object? producedFromBuildingLevel = null,
    Object? bonusAttack = null,
    Object? bonusDefense = null,
    Object? bonusAccuracy = null,
    Object? bonusKillPotential = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as UnitId,
            unitType: null == unitType
                ? _value.unitType
                : unitType // ignore: cast_nullable_to_non_nullable
                      as UnitType,
            owner: null == owner
                ? _value.owner
                : owner // ignore: cast_nullable_to_non_nullable
                      as PlayerId,
            attack: null == attack
                ? _value.attack
                : attack // ignore: cast_nullable_to_non_nullable
                      as int,
            defense: null == defense
                ? _value.defense
                : defense // ignore: cast_nullable_to_non_nullable
                      as int,
            maxHP: null == maxHP
                ? _value.maxHP
                : maxHP // ignore: cast_nullable_to_non_nullable
                      as int,
            currentHP: null == currentHP
                ? _value.currentHP
                : currentHP // ignore: cast_nullable_to_non_nullable
                      as int,
            movement: null == movement
                ? _value.movement
                : movement // ignore: cast_nullable_to_non_nullable
                      as int,
            level: null == level
                ? _value.level
                : level // ignore: cast_nullable_to_non_nullable
                      as int,
            experience: null == experience
                ? _value.experience
                : experience // ignore: cast_nullable_to_non_nullable
                      as int,
            morale: null == morale
                ? _value.morale
                : morale // ignore: cast_nullable_to_non_nullable
                      as int,
            producedFromBuildingLevel: null == producedFromBuildingLevel
                ? _value.producedFromBuildingLevel
                : producedFromBuildingLevel // ignore: cast_nullable_to_non_nullable
                      as int,
            bonusAttack: null == bonusAttack
                ? _value.bonusAttack
                : bonusAttack // ignore: cast_nullable_to_non_nullable
                      as int,
            bonusDefense: null == bonusDefense
                ? _value.bonusDefense
                : bonusDefense // ignore: cast_nullable_to_non_nullable
                      as int,
            bonusAccuracy: null == bonusAccuracy
                ? _value.bonusAccuracy
                : bonusAccuracy // ignore: cast_nullable_to_non_nullable
                      as double,
            bonusKillPotential: null == bonusKillPotential
                ? _value.bonusKillPotential
                : bonusKillPotential // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UnitImplCopyWith<$Res> implements $UnitCopyWith<$Res> {
  factory _$$UnitImplCopyWith(
    _$UnitImpl value,
    $Res Function(_$UnitImpl) then,
  ) = __$$UnitImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @UnitIdConverter() UnitId id,
    UnitType unitType,
    @PlayerIdConverter() PlayerId owner,
    int attack,
    int defense,
    int maxHP,
    int currentHP,
    int movement,
    int level,
    int experience,
    int morale,
    int producedFromBuildingLevel,
    int bonusAttack,
    int bonusDefense,
    double bonusAccuracy,
    double bonusKillPotential,
  });
}

/// @nodoc
class __$$UnitImplCopyWithImpl<$Res>
    extends _$UnitCopyWithImpl<$Res, _$UnitImpl>
    implements _$$UnitImplCopyWith<$Res> {
  __$$UnitImplCopyWithImpl(_$UnitImpl _value, $Res Function(_$UnitImpl) _then)
    : super(_value, _then);

  /// Create a copy of Unit
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? unitType = null,
    Object? owner = null,
    Object? attack = null,
    Object? defense = null,
    Object? maxHP = null,
    Object? currentHP = null,
    Object? movement = null,
    Object? level = null,
    Object? experience = null,
    Object? morale = null,
    Object? producedFromBuildingLevel = null,
    Object? bonusAttack = null,
    Object? bonusDefense = null,
    Object? bonusAccuracy = null,
    Object? bonusKillPotential = null,
  }) {
    return _then(
      _$UnitImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as UnitId,
        unitType: null == unitType
            ? _value.unitType
            : unitType // ignore: cast_nullable_to_non_nullable
                  as UnitType,
        owner: null == owner
            ? _value.owner
            : owner // ignore: cast_nullable_to_non_nullable
                  as PlayerId,
        attack: null == attack
            ? _value.attack
            : attack // ignore: cast_nullable_to_non_nullable
                  as int,
        defense: null == defense
            ? _value.defense
            : defense // ignore: cast_nullable_to_non_nullable
                  as int,
        maxHP: null == maxHP
            ? _value.maxHP
            : maxHP // ignore: cast_nullable_to_non_nullable
                  as int,
        currentHP: null == currentHP
            ? _value.currentHP
            : currentHP // ignore: cast_nullable_to_non_nullable
                  as int,
        movement: null == movement
            ? _value.movement
            : movement // ignore: cast_nullable_to_non_nullable
                  as int,
        level: null == level
            ? _value.level
            : level // ignore: cast_nullable_to_non_nullable
                  as int,
        experience: null == experience
            ? _value.experience
            : experience // ignore: cast_nullable_to_non_nullable
                  as int,
        morale: null == morale
            ? _value.morale
            : morale // ignore: cast_nullable_to_non_nullable
                  as int,
        producedFromBuildingLevel: null == producedFromBuildingLevel
            ? _value.producedFromBuildingLevel
            : producedFromBuildingLevel // ignore: cast_nullable_to_non_nullable
                  as int,
        bonusAttack: null == bonusAttack
            ? _value.bonusAttack
            : bonusAttack // ignore: cast_nullable_to_non_nullable
                  as int,
        bonusDefense: null == bonusDefense
            ? _value.bonusDefense
            : bonusDefense // ignore: cast_nullable_to_non_nullable
                  as int,
        bonusAccuracy: null == bonusAccuracy
            ? _value.bonusAccuracy
            : bonusAccuracy // ignore: cast_nullable_to_non_nullable
                  as double,
        bonusKillPotential: null == bonusKillPotential
            ? _value.bonusKillPotential
            : bonusKillPotential // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UnitImpl extends _Unit {
  const _$UnitImpl({
    @UnitIdConverter() required this.id,
    required this.unitType,
    @PlayerIdConverter() required this.owner,
    required this.attack,
    required this.defense,
    required this.maxHP,
    required this.currentHP,
    required this.movement,
    this.level = 1,
    this.experience = 0,
    this.morale = 100,
    this.producedFromBuildingLevel = 0,
    this.bonusAttack = 0,
    this.bonusDefense = 0,
    this.bonusAccuracy = 0.0,
    this.bonusKillPotential = 0.0,
  }) : super._();

  factory _$UnitImpl.fromJson(Map<String, dynamic> json) =>
      _$$UnitImplFromJson(json);

  @override
  @UnitIdConverter()
  final UnitId id;
  @override
  final UnitType unitType;
  @override
  @PlayerIdConverter()
  final PlayerId owner;
  @override
  final int attack;
  @override
  final int defense;
  @override
  final int maxHP;
  @override
  final int currentHP;
  @override
  final int movement;
  @override
  @JsonKey()
  final int level;
  @override
  @JsonKey()
  final int experience;
  @override
  @JsonKey()
  final int morale;
  // Building-based bonuses (applied at creation time)
  @override
  @JsonKey()
  final int producedFromBuildingLevel;
  @override
  @JsonKey()
  final int bonusAttack;
  @override
  @JsonKey()
  final int bonusDefense;
  @override
  @JsonKey()
  final double bonusAccuracy;
  @override
  @JsonKey()
  final double bonusKillPotential;

  @override
  String toString() {
    return 'Unit(id: $id, unitType: $unitType, owner: $owner, attack: $attack, defense: $defense, maxHP: $maxHP, currentHP: $currentHP, movement: $movement, level: $level, experience: $experience, morale: $morale, producedFromBuildingLevel: $producedFromBuildingLevel, bonusAttack: $bonusAttack, bonusDefense: $bonusDefense, bonusAccuracy: $bonusAccuracy, bonusKillPotential: $bonusKillPotential)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UnitImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.unitType, unitType) ||
                other.unitType == unitType) &&
            (identical(other.owner, owner) || other.owner == owner) &&
            (identical(other.attack, attack) || other.attack == attack) &&
            (identical(other.defense, defense) || other.defense == defense) &&
            (identical(other.maxHP, maxHP) || other.maxHP == maxHP) &&
            (identical(other.currentHP, currentHP) ||
                other.currentHP == currentHP) &&
            (identical(other.movement, movement) ||
                other.movement == movement) &&
            (identical(other.level, level) || other.level == level) &&
            (identical(other.experience, experience) ||
                other.experience == experience) &&
            (identical(other.morale, morale) || other.morale == morale) &&
            (identical(
                  other.producedFromBuildingLevel,
                  producedFromBuildingLevel,
                ) ||
                other.producedFromBuildingLevel == producedFromBuildingLevel) &&
            (identical(other.bonusAttack, bonusAttack) ||
                other.bonusAttack == bonusAttack) &&
            (identical(other.bonusDefense, bonusDefense) ||
                other.bonusDefense == bonusDefense) &&
            (identical(other.bonusAccuracy, bonusAccuracy) ||
                other.bonusAccuracy == bonusAccuracy) &&
            (identical(other.bonusKillPotential, bonusKillPotential) ||
                other.bonusKillPotential == bonusKillPotential));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    unitType,
    owner,
    attack,
    defense,
    maxHP,
    currentHP,
    movement,
    level,
    experience,
    morale,
    producedFromBuildingLevel,
    bonusAttack,
    bonusDefense,
    bonusAccuracy,
    bonusKillPotential,
  );

  /// Create a copy of Unit
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UnitImplCopyWith<_$UnitImpl> get copyWith =>
      __$$UnitImplCopyWithImpl<_$UnitImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UnitImplToJson(this);
  }
}

abstract class _Unit extends Unit {
  const factory _Unit({
    @UnitIdConverter() required final UnitId id,
    required final UnitType unitType,
    @PlayerIdConverter() required final PlayerId owner,
    required final int attack,
    required final int defense,
    required final int maxHP,
    required final int currentHP,
    required final int movement,
    final int level,
    final int experience,
    final int morale,
    final int producedFromBuildingLevel,
    final int bonusAttack,
    final int bonusDefense,
    final double bonusAccuracy,
    final double bonusKillPotential,
  }) = _$UnitImpl;
  const _Unit._() : super._();

  factory _Unit.fromJson(Map<String, dynamic> json) = _$UnitImpl.fromJson;

  @override
  @UnitIdConverter()
  UnitId get id;
  @override
  UnitType get unitType;
  @override
  @PlayerIdConverter()
  PlayerId get owner;
  @override
  int get attack;
  @override
  int get defense;
  @override
  int get maxHP;
  @override
  int get currentHP;
  @override
  int get movement;
  @override
  int get level;
  @override
  int get experience;
  @override
  int get morale; // Building-based bonuses (applied at creation time)
  @override
  int get producedFromBuildingLevel;
  @override
  int get bonusAttack;
  @override
  int get bonusDefense;
  @override
  double get bonusAccuracy;
  @override
  double get bonusKillPotential;

  /// Create a copy of Unit
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UnitImplCopyWith<_$UnitImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
