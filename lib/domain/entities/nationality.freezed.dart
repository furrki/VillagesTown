// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'nationality.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Nationality _$NationalityFromJson(Map<String, dynamic> json) {
  return _Nationality.fromJson(json);
}

/// @nodoc
mixin _$Nationality {
  @NationalityIdConverter()
  NationalityId get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get assetPath => throw _privateConstructorUsedError;
  int get colorValue => throw _privateConstructorUsedError;
  bool get isMajor => throw _privateConstructorUsedError;
  double get aggression => throw _privateConstructorUsedError;

  /// Serializes this Nationality to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Nationality
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NationalityCopyWith<Nationality> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NationalityCopyWith<$Res> {
  factory $NationalityCopyWith(
    Nationality value,
    $Res Function(Nationality) then,
  ) = _$NationalityCopyWithImpl<$Res, Nationality>;
  @useResult
  $Res call({
    @NationalityIdConverter() NationalityId id,
    String name,
    String assetPath,
    int colorValue,
    bool isMajor,
    double aggression,
  });
}

/// @nodoc
class _$NationalityCopyWithImpl<$Res, $Val extends Nationality>
    implements $NationalityCopyWith<$Res> {
  _$NationalityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Nationality
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? assetPath = null,
    Object? colorValue = null,
    Object? isMajor = null,
    Object? aggression = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as NationalityId,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            assetPath: null == assetPath
                ? _value.assetPath
                : assetPath // ignore: cast_nullable_to_non_nullable
                      as String,
            colorValue: null == colorValue
                ? _value.colorValue
                : colorValue // ignore: cast_nullable_to_non_nullable
                      as int,
            isMajor: null == isMajor
                ? _value.isMajor
                : isMajor // ignore: cast_nullable_to_non_nullable
                      as bool,
            aggression: null == aggression
                ? _value.aggression
                : aggression // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$NationalityImplCopyWith<$Res>
    implements $NationalityCopyWith<$Res> {
  factory _$$NationalityImplCopyWith(
    _$NationalityImpl value,
    $Res Function(_$NationalityImpl) then,
  ) = __$$NationalityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @NationalityIdConverter() NationalityId id,
    String name,
    String assetPath,
    int colorValue,
    bool isMajor,
    double aggression,
  });
}

/// @nodoc
class __$$NationalityImplCopyWithImpl<$Res>
    extends _$NationalityCopyWithImpl<$Res, _$NationalityImpl>
    implements _$$NationalityImplCopyWith<$Res> {
  __$$NationalityImplCopyWithImpl(
    _$NationalityImpl _value,
    $Res Function(_$NationalityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Nationality
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? assetPath = null,
    Object? colorValue = null,
    Object? isMajor = null,
    Object? aggression = null,
  }) {
    return _then(
      _$NationalityImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as NationalityId,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        assetPath: null == assetPath
            ? _value.assetPath
            : assetPath // ignore: cast_nullable_to_non_nullable
                  as String,
        colorValue: null == colorValue
            ? _value.colorValue
            : colorValue // ignore: cast_nullable_to_non_nullable
                  as int,
        isMajor: null == isMajor
            ? _value.isMajor
            : isMajor // ignore: cast_nullable_to_non_nullable
                  as bool,
        aggression: null == aggression
            ? _value.aggression
            : aggression // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$NationalityImpl extends _Nationality {
  const _$NationalityImpl({
    @NationalityIdConverter() required this.id,
    required this.name,
    required this.assetPath,
    required this.colorValue,
    this.isMajor = true,
    this.aggression = 0.7,
  }) : super._();

  factory _$NationalityImpl.fromJson(Map<String, dynamic> json) =>
      _$$NationalityImplFromJson(json);

  @override
  @NationalityIdConverter()
  final NationalityId id;
  @override
  final String name;
  @override
  final String assetPath;
  @override
  final int colorValue;
  @override
  @JsonKey()
  final bool isMajor;
  @override
  @JsonKey()
  final double aggression;

  @override
  String toString() {
    return 'Nationality(id: $id, name: $name, assetPath: $assetPath, colorValue: $colorValue, isMajor: $isMajor, aggression: $aggression)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NationalityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.assetPath, assetPath) ||
                other.assetPath == assetPath) &&
            (identical(other.colorValue, colorValue) ||
                other.colorValue == colorValue) &&
            (identical(other.isMajor, isMajor) || other.isMajor == isMajor) &&
            (identical(other.aggression, aggression) ||
                other.aggression == aggression));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    assetPath,
    colorValue,
    isMajor,
    aggression,
  );

  /// Create a copy of Nationality
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NationalityImplCopyWith<_$NationalityImpl> get copyWith =>
      __$$NationalityImplCopyWithImpl<_$NationalityImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NationalityImplToJson(this);
  }
}

abstract class _Nationality extends Nationality {
  const factory _Nationality({
    @NationalityIdConverter() required final NationalityId id,
    required final String name,
    required final String assetPath,
    required final int colorValue,
    final bool isMajor,
    final double aggression,
  }) = _$NationalityImpl;
  const _Nationality._() : super._();

  factory _Nationality.fromJson(Map<String, dynamic> json) =
      _$NationalityImpl.fromJson;

  @override
  @NationalityIdConverter()
  NationalityId get id;
  @override
  String get name;
  @override
  String get assetPath;
  @override
  int get colorValue;
  @override
  bool get isMajor;
  @override
  double get aggression;

  /// Create a copy of Nationality
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NationalityImplCopyWith<_$NationalityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
