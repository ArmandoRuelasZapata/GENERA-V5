// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'appointment_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$AppointmentEntity {
  String get id => throw _privateConstructorUsedError;
  String get serviceName => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  double get price => throw _privateConstructorUsedError;
  String get status =>
      throw _privateConstructorUsedError; // 'upcoming', 'completed', 'cancelled'
  String? get notes => throw _privateConstructorUsedError;

  /// Create a copy of AppointmentEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AppointmentEntityCopyWith<AppointmentEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppointmentEntityCopyWith<$Res> {
  factory $AppointmentEntityCopyWith(
          AppointmentEntity value, $Res Function(AppointmentEntity) then) =
      _$AppointmentEntityCopyWithImpl<$Res, AppointmentEntity>;
  @useResult
  $Res call(
      {String id,
      String serviceName,
      DateTime date,
      double price,
      String status,
      String? notes});
}

/// @nodoc
class _$AppointmentEntityCopyWithImpl<$Res, $Val extends AppointmentEntity>
    implements $AppointmentEntityCopyWith<$Res> {
  _$AppointmentEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppointmentEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? serviceName = null,
    Object? date = null,
    Object? price = null,
    Object? status = null,
    Object? notes = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      serviceName: null == serviceName
          ? _value.serviceName
          : serviceName // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      price: null == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as double,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AppointmentEntityImplCopyWith<$Res>
    implements $AppointmentEntityCopyWith<$Res> {
  factory _$$AppointmentEntityImplCopyWith(_$AppointmentEntityImpl value,
          $Res Function(_$AppointmentEntityImpl) then) =
      __$$AppointmentEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String serviceName,
      DateTime date,
      double price,
      String status,
      String? notes});
}

/// @nodoc
class __$$AppointmentEntityImplCopyWithImpl<$Res>
    extends _$AppointmentEntityCopyWithImpl<$Res, _$AppointmentEntityImpl>
    implements _$$AppointmentEntityImplCopyWith<$Res> {
  __$$AppointmentEntityImplCopyWithImpl(_$AppointmentEntityImpl _value,
      $Res Function(_$AppointmentEntityImpl) _then)
      : super(_value, _then);

  /// Create a copy of AppointmentEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? serviceName = null,
    Object? date = null,
    Object? price = null,
    Object? status = null,
    Object? notes = freezed,
  }) {
    return _then(_$AppointmentEntityImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      serviceName: null == serviceName
          ? _value.serviceName
          : serviceName // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      price: null == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as double,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$AppointmentEntityImpl implements _AppointmentEntity {
  const _$AppointmentEntityImpl(
      {required this.id,
      required this.serviceName,
      required this.date,
      required this.price,
      required this.status,
      this.notes});

  @override
  final String id;
  @override
  final String serviceName;
  @override
  final DateTime date;
  @override
  final double price;
  @override
  final String status;
// 'upcoming', 'completed', 'cancelled'
  @override
  final String? notes;

  @override
  String toString() {
    return 'AppointmentEntity(id: $id, serviceName: $serviceName, date: $date, price: $price, status: $status, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppointmentEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.serviceName, serviceName) ||
                other.serviceName == serviceName) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, serviceName, date, price, status, notes);

  /// Create a copy of AppointmentEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppointmentEntityImplCopyWith<_$AppointmentEntityImpl> get copyWith =>
      __$$AppointmentEntityImplCopyWithImpl<_$AppointmentEntityImpl>(
          this, _$identity);
}

abstract class _AppointmentEntity implements AppointmentEntity {
  const factory _AppointmentEntity(
      {required final String id,
      required final String serviceName,
      required final DateTime date,
      required final double price,
      required final String status,
      final String? notes}) = _$AppointmentEntityImpl;

  @override
  String get id;
  @override
  String get serviceName;
  @override
  DateTime get date;
  @override
  double get price;
  @override
  String get status; // 'upcoming', 'completed', 'cancelled'
  @override
  String? get notes;

  /// Create a copy of AppointmentEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppointmentEntityImplCopyWith<_$AppointmentEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
