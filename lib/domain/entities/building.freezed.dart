// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'building.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Building _$BuildingFromJson(Map<String, dynamic> json) {
  return _Building.fromJson(json);
}

/// @nodoc
mixin _$Building {
  @BuildingIdConverter()
  BuildingId get id => throw _privateConstructorUsedError;
  BuildingType get type => throw _privateConstructorUsedError;
  int get level => throw _privateConstructorUsedError;

  /// Serializes this Building to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Building
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BuildingCopyWith<Building> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BuildingCopyWith<$Res> {
  factory $BuildingCopyWith(Building value, $Res Function(Building) then) =
      _$BuildingCopyWithImpl<$Res, Building>;
  @useResult
  $Res call({
    @BuildingIdConverter() BuildingId id,
    BuildingType type,
    int level,
  });
}

/// @nodoc
class _$BuildingCopyWithImpl<$Res, $Val extends Building>
    implements $BuildingCopyWith<$Res> {
  _$BuildingCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Building
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? type = null, Object? level = null}) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as BuildingId,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as BuildingType,
            level: null == level
                ? _value.level
                : level // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BuildingImplCopyWith<$Res>
    implements $BuildingCopyWith<$Res> {
  factory _$$BuildingImplCopyWith(
    _$BuildingImpl value,
    $Res Function(_$BuildingImpl) then,
  ) = __$$BuildingImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @BuildingIdConverter() BuildingId id,
    BuildingType type,
    int level,
  });
}

/// @nodoc
class __$$BuildingImplCopyWithImpl<$Res>
    extends _$BuildingCopyWithImpl<$Res, _$BuildingImpl>
    implements _$$BuildingImplCopyWith<$Res> {
  __$$BuildingImplCopyWithImpl(
    _$BuildingImpl _value,
    $Res Function(_$BuildingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Building
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? type = null, Object? level = null}) {
    return _then(
      _$BuildingImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as BuildingId,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as BuildingType,
        level: null == level
            ? _value.level
            : level // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$BuildingImpl extends _Building {
  const _$BuildingImpl({
    @BuildingIdConverter() required this.id,
    required this.type,
    this.level = 1,
  }) : super._();

  factory _$BuildingImpl.fromJson(Map<String, dynamic> json) =>
      _$$BuildingImplFromJson(json);

  @override
  @BuildingIdConverter()
  final BuildingId id;
  @override
  final BuildingType type;
  @override
  @JsonKey()
  final int level;

  @override
  String toString() {
    return 'Building(id: $id, type: $type, level: $level)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BuildingImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.level, level) || other.level == level));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, type, level);

  /// Create a copy of Building
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BuildingImplCopyWith<_$BuildingImpl> get copyWith =>
      __$$BuildingImplCopyWithImpl<_$BuildingImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BuildingImplToJson(this);
  }
}

abstract class _Building extends Building {
  const factory _Building({
    @BuildingIdConverter() required final BuildingId id,
    required final BuildingType type,
    final int level,
  }) = _$BuildingImpl;
  const _Building._() : super._();

  factory _Building.fromJson(Map<String, dynamic> json) =
      _$BuildingImpl.fromJson;

  @override
  @BuildingIdConverter()
  BuildingId get id;
  @override
  BuildingType get type;
  @override
  int get level;

  /// Create a copy of Building
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BuildingImplCopyWith<_$BuildingImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
