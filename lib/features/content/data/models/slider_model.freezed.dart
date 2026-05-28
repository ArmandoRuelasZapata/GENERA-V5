// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'slider_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SliderModel _$SliderModelFromJson(Map<String, dynamic> json) {
  return _SliderModel.fromJson(json);
}

/// @nodoc
mixin _$SliderModel {
  String get image => throw _privateConstructorUsedError;
  String get url => throw _privateConstructorUsedError;

  /// Serializes this SliderModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SliderModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SliderModelCopyWith<SliderModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SliderModelCopyWith<$Res> {
  factory $SliderModelCopyWith(
          SliderModel value, $Res Function(SliderModel) then) =
      _$SliderModelCopyWithImpl<$Res, SliderModel>;
  @useResult
  $Res call({String image, String url});
}

/// @nodoc
class _$SliderModelCopyWithImpl<$Res, $Val extends SliderModel>
    implements $SliderModelCopyWith<$Res> {
  _$SliderModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SliderModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? image = null,
    Object? url = null,
  }) {
    return _then(_value.copyWith(
      image: null == image
          ? _value.image
          : image // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SliderModelImplCopyWith<$Res>
    implements $SliderModelCopyWith<$Res> {
  factory _$$SliderModelImplCopyWith(
          _$SliderModelImpl value, $Res Function(_$SliderModelImpl) then) =
      __$$SliderModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String image, String url});
}

/// @nodoc
class __$$SliderModelImplCopyWithImpl<$Res>
    extends _$SliderModelCopyWithImpl<$Res, _$SliderModelImpl>
    implements _$$SliderModelImplCopyWith<$Res> {
  __$$SliderModelImplCopyWithImpl(
      _$SliderModelImpl _value, $Res Function(_$SliderModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of SliderModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? image = null,
    Object? url = null,
  }) {
    return _then(_$SliderModelImpl(
      image: null == image
          ? _value.image
          : image // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SliderModelImpl implements _SliderModel {
  const _$SliderModelImpl({required this.image, required this.url});

  factory _$SliderModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$SliderModelImplFromJson(json);

  @override
  final String image;
  @override
  final String url;

  @override
  String toString() {
    return 'SliderModel(image: $image, url: $url)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SliderModelImpl &&
            (identical(other.image, image) || other.image == image) &&
            (identical(other.url, url) || other.url == url));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, image, url);

  /// Create a copy of SliderModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SliderModelImplCopyWith<_$SliderModelImpl> get copyWith =>
      __$$SliderModelImplCopyWithImpl<_$SliderModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SliderModelImplToJson(
      this,
    );
  }
}

abstract class _SliderModel implements SliderModel {
  const factory _SliderModel(
      {required final String image,
      required final String url}) = _$SliderModelImpl;

  factory _SliderModel.fromJson(Map<String, dynamic> json) =
      _$SliderModelImpl.fromJson;

  @override
  String get image;
  @override
  String get url;

  /// Create a copy of SliderModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SliderModelImplCopyWith<_$SliderModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
