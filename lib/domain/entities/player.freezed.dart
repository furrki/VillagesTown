// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'player.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Player _$PlayerFromJson(Map<String, dynamic> json) {
  return _Player.fromJson(json);
}

/// @nodoc
mixin _$Player {
  @PlayerIdConverter()
  PlayerId get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @NationalityIdConverter()
  NationalityId get nationalityId => throw _privateConstructorUsedError;
  bool get isHuman => throw _privateConstructorUsedError;
  @VillageIdListConverter()
  List<VillageId> get villageIds => throw _privateConstructorUsedError;
  bool get isEliminated => throw _privateConstructorUsedError;
  AIPersonality? get aiPersonality => throw _privateConstructorUsedError;

  /// Serializes this Player to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Player
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlayerCopyWith<Player> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlayerCopyWith<$Res> {
  factory $PlayerCopyWith(Player value, $Res Function(Player) then) =
      _$PlayerCopyWithImpl<$Res, Player>;
  @useResult
  $Res call({
    @PlayerIdConverter() PlayerId id,
    String name,
    @NationalityIdConverter() NationalityId nationalityId,
    bool isHuman,
    @VillageIdListConverter() List<VillageId> villageIds,
    bool isEliminated,
    AIPersonality? aiPersonality,
  });
}

/// @nodoc
class _$PlayerCopyWithImpl<$Res, $Val extends Player>
    implements $PlayerCopyWith<$Res> {
  _$PlayerCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Player
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? nationalityId = null,
    Object? isHuman = null,
    Object? villageIds = null,
    Object? isEliminated = null,
    Object? aiPersonality = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as PlayerId,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            nationalityId: null == nationalityId
                ? _value.nationalityId
                : nationalityId // ignore: cast_nullable_to_non_nullable
                      as NationalityId,
            isHuman: null == isHuman
                ? _value.isHuman
                : isHuman // ignore: cast_nullable_to_non_nullable
                      as bool,
            villageIds: null == villageIds
                ? _value.villageIds
                : villageIds // ignore: cast_nullable_to_non_nullable
                      as List<VillageId>,
            isEliminated: null == isEliminated
                ? _value.isEliminated
                : isEliminated // ignore: cast_nullable_to_non_nullable
                      as bool,
            aiPersonality: freezed == aiPersonality
                ? _value.aiPersonality
                : aiPersonality // ignore: cast_nullable_to_non_nullable
                      as AIPersonality?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PlayerImplCopyWith<$Res> implements $PlayerCopyWith<$Res> {
  factory _$$PlayerImplCopyWith(
    _$PlayerImpl value,
    $Res Function(_$PlayerImpl) then,
  ) = __$$PlayerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @PlayerIdConverter() PlayerId id,
    String name,
    @NationalityIdConverter() NationalityId nationalityId,
    bool isHuman,
    @VillageIdListConverter() List<VillageId> villageIds,
    bool isEliminated,
    AIPersonality? aiPersonality,
  });
}

/// @nodoc
class __$$PlayerImplCopyWithImpl<$Res>
    extends _$PlayerCopyWithImpl<$Res, _$PlayerImpl>
    implements _$$PlayerImplCopyWith<$Res> {
  __$$PlayerImplCopyWithImpl(
    _$PlayerImpl _value,
    $Res Function(_$PlayerImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Player
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? nationalityId = null,
    Object? isHuman = null,
    Object? villageIds = null,
    Object? isEliminated = null,
    Object? aiPersonality = freezed,
  }) {
    return _then(
      _$PlayerImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as PlayerId,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        nationalityId: null == nationalityId
            ? _value.nationalityId
            : nationalityId // ignore: cast_nullable_to_non_nullable
                  as NationalityId,
        isHuman: null == isHuman
            ? _value.isHuman
            : isHuman // ignore: cast_nullable_to_non_nullable
                  as bool,
        villageIds: null == villageIds
            ? _value._villageIds
            : villageIds // ignore: cast_nullable_to_non_nullable
                  as List<VillageId>,
        isEliminated: null == isEliminated
            ? _value.isEliminated
            : isEliminated // ignore: cast_nullable_to_non_nullable
                  as bool,
        aiPersonality: freezed == aiPersonality
            ? _value.aiPersonality
            : aiPersonality // ignore: cast_nullable_to_non_nullable
                  as AIPersonality?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PlayerImpl extends _Player {
  const _$PlayerImpl({
    @PlayerIdConverter() required this.id,
    required this.name,
    @NationalityIdConverter() required this.nationalityId,
    required this.isHuman,
    @VillageIdListConverter() final List<VillageId> villageIds = const [],
    this.isEliminated = false,
    this.aiPersonality,
  }) : _villageIds = villageIds,
       super._();

  factory _$PlayerImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlayerImplFromJson(json);

  @override
  @PlayerIdConverter()
  final PlayerId id;
  @override
  final String name;
  @override
  @NationalityIdConverter()
  final NationalityId nationalityId;
  @override
  final bool isHuman;
  final List<VillageId> _villageIds;
  @override
  @JsonKey()
  @VillageIdListConverter()
  List<VillageId> get villageIds {
    if (_villageIds is EqualUnmodifiableListView) return _villageIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_villageIds);
  }

  @override
  @JsonKey()
  final bool isEliminated;
  @override
  final AIPersonality? aiPersonality;

  @override
  String toString() {
    return 'Player(id: $id, name: $name, nationalityId: $nationalityId, isHuman: $isHuman, villageIds: $villageIds, isEliminated: $isEliminated, aiPersonality: $aiPersonality)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlayerImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.nationalityId, nationalityId) ||
                other.nationalityId == nationalityId) &&
            (identical(other.isHuman, isHuman) || other.isHuman == isHuman) &&
            const DeepCollectionEquality().equals(
              other._villageIds,
              _villageIds,
            ) &&
            (identical(other.isEliminated, isEliminated) ||
                other.isEliminated == isEliminated) &&
            (identical(other.aiPersonality, aiPersonality) ||
                other.aiPersonality == aiPersonality));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    nationalityId,
    isHuman,
    const DeepCollectionEquality().hash(_villageIds),
    isEliminated,
    aiPersonality,
  );

  /// Create a copy of Player
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlayerImplCopyWith<_$PlayerImpl> get copyWith =>
      __$$PlayerImplCopyWithImpl<_$PlayerImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PlayerImplToJson(this);
  }
}

abstract class _Player extends Player {
  const factory _Player({
    @PlayerIdConverter() required final PlayerId id,
    required final String name,
    @NationalityIdConverter() required final NationalityId nationalityId,
    required final bool isHuman,
    @VillageIdListConverter() final List<VillageId> villageIds,
    final bool isEliminated,
    final AIPersonality? aiPersonality,
  }) = _$PlayerImpl;
  const _Player._() : super._();

  factory _Player.fromJson(Map<String, dynamic> json) = _$PlayerImpl.fromJson;

  @override
  @PlayerIdConverter()
  PlayerId get id;
  @override
  String get name;
  @override
  @NationalityIdConverter()
  NationalityId get nationalityId;
  @override
  bool get isHuman;
  @override
  @VillageIdListConverter()
  List<VillageId> get villageIds;
  @override
  bool get isEliminated;
  @override
  AIPersonality? get aiPersonality;

  /// Create a copy of Player
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlayerImplCopyWith<_$PlayerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
