// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'booking_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$BookingState {
  ServiceEntity? get selectedService => throw _privateConstructorUsedError;
  DateTime? get selectedDate => throw _privateConstructorUsedError;
  TimeSlot? get selectedTimeSlot => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  String? get successMessage => throw _privateConstructorUsedError;

  /// For "Personalizado" service — the user types their own interest
  String? get customInterest => throw _privateConstructorUsedError;

  /// Create a copy of BookingState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BookingStateCopyWith<BookingState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BookingStateCopyWith<$Res> {
  factory $BookingStateCopyWith(
          BookingState value, $Res Function(BookingState) then) =
      _$BookingStateCopyWithImpl<$Res, BookingState>;
  @useResult
  $Res call(
      {ServiceEntity? selectedService,
      DateTime? selectedDate,
      TimeSlot? selectedTimeSlot,
      bool isLoading,
      String? error,
      String? successMessage,
      String? customInterest});

  $ServiceEntityCopyWith<$Res>? get selectedService;
}

/// @nodoc
class _$BookingStateCopyWithImpl<$Res, $Val extends BookingState>
    implements $BookingStateCopyWith<$Res> {
  _$BookingStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BookingState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? selectedService = freezed,
    Object? selectedDate = freezed,
    Object? selectedTimeSlot = freezed,
    Object? isLoading = null,
    Object? error = freezed,
    Object? successMessage = freezed,
    Object? customInterest = freezed,
  }) {
    return _then(_value.copyWith(
      selectedService: freezed == selectedService
          ? _value.selectedService
          : selectedService // ignore: cast_nullable_to_non_nullable
              as ServiceEntity?,
      selectedDate: freezed == selectedDate
          ? _value.selectedDate
          : selectedDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      selectedTimeSlot: freezed == selectedTimeSlot
          ? _value.selectedTimeSlot
          : selectedTimeSlot // ignore: cast_nullable_to_non_nullable
              as TimeSlot?,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      successMessage: freezed == successMessage
          ? _value.successMessage
          : successMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      customInterest: freezed == customInterest
          ? _value.customInterest
          : customInterest // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of BookingState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ServiceEntityCopyWith<$Res>? get selectedService {
    if (_value.selectedService == null) {
      return null;
    }

    return $ServiceEntityCopyWith<$Res>(_value.selectedService!, (value) {
      return _then(_value.copyWith(selectedService: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$BookingStateImplCopyWith<$Res>
    implements $BookingStateCopyWith<$Res> {
  factory _$$BookingStateImplCopyWith(
          _$BookingStateImpl value, $Res Function(_$BookingStateImpl) then) =
      __$$BookingStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {ServiceEntity? selectedService,
      DateTime? selectedDate,
      TimeSlot? selectedTimeSlot,
      bool isLoading,
      String? error,
      String? successMessage,
      String? customInterest});

  @override
  $ServiceEntityCopyWith<$Res>? get selectedService;
}

/// @nodoc
class __$$BookingStateImplCopyWithImpl<$Res>
    extends _$BookingStateCopyWithImpl<$Res, _$BookingStateImpl>
    implements _$$BookingStateImplCopyWith<$Res> {
  __$$BookingStateImplCopyWithImpl(
      _$BookingStateImpl _value, $Res Function(_$BookingStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of BookingState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? selectedService = freezed,
    Object? selectedDate = freezed,
    Object? selectedTimeSlot = freezed,
    Object? isLoading = null,
    Object? error = freezed,
    Object? successMessage = freezed,
    Object? customInterest = freezed,
  }) {
    return _then(_$BookingStateImpl(
      selectedService: freezed == selectedService
          ? _value.selectedService
          : selectedService // ignore: cast_nullable_to_non_nullable
              as ServiceEntity?,
      selectedDate: freezed == selectedDate
          ? _value.selectedDate
          : selectedDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      selectedTimeSlot: freezed == selectedTimeSlot
          ? _value.selectedTimeSlot
          : selectedTimeSlot // ignore: cast_nullable_to_non_nullable
              as TimeSlot?,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      successMessage: freezed == successMessage
          ? _value.successMessage
          : successMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      customInterest: freezed == customInterest
          ? _value.customInterest
          : customInterest // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$BookingStateImpl implements _BookingState {
  const _$BookingStateImpl(
      {this.selectedService,
      this.selectedDate,
      this.selectedTimeSlot,
      this.isLoading = false,
      this.error,
      this.successMessage,
      this.customInterest});

  @override
  final ServiceEntity? selectedService;
  @override
  final DateTime? selectedDate;
  @override
  final TimeSlot? selectedTimeSlot;
  @override
  @JsonKey()
  final bool isLoading;
  @override
  final String? error;
  @override
  final String? successMessage;

  /// For "Personalizado" service — the user types their own interest
  @override
  final String? customInterest;

  @override
  String toString() {
    return 'BookingState(selectedService: $selectedService, selectedDate: $selectedDate, selectedTimeSlot: $selectedTimeSlot, isLoading: $isLoading, error: $error, successMessage: $successMessage, customInterest: $customInterest)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BookingStateImpl &&
            (identical(other.selectedService, selectedService) ||
                other.selectedService == selectedService) &&
            (identical(other.selectedDate, selectedDate) ||
                other.selectedDate == selectedDate) &&
            (identical(other.selectedTimeSlot, selectedTimeSlot) ||
                other.selectedTimeSlot == selectedTimeSlot) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.successMessage, successMessage) ||
                other.successMessage == successMessage) &&
            (identical(other.customInterest, customInterest) ||
                other.customInterest == customInterest));
  }

  @override
  int get hashCode => Object.hash(runtimeType, selectedService, selectedDate,
      selectedTimeSlot, isLoading, error, successMessage, customInterest);

  /// Create a copy of BookingState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BookingStateImplCopyWith<_$BookingStateImpl> get copyWith =>
      __$$BookingStateImplCopyWithImpl<_$BookingStateImpl>(this, _$identity);
}

abstract class _BookingState implements BookingState {
  const factory _BookingState(
      {final ServiceEntity? selectedService,
      final DateTime? selectedDate,
      final TimeSlot? selectedTimeSlot,
      final bool isLoading,
      final String? error,
      final String? successMessage,
      final String? customInterest}) = _$BookingStateImpl;

  @override
  ServiceEntity? get selectedService;
  @override
  DateTime? get selectedDate;
  @override
  TimeSlot? get selectedTimeSlot;
  @override
  bool get isLoading;
  @override
  String? get error;
  @override
  String? get successMessage;

  /// For "Personalizado" service — the user types their own interest
  @override
  String? get customInterest;

  /// Create a copy of BookingState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BookingStateImplCopyWith<_$BookingStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
