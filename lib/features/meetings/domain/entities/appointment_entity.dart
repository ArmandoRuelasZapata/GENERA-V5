import 'package:freezed_annotation/freezed_annotation.dart';

part 'appointment_entity.freezed.dart';

@freezed
class AppointmentEntity with _$AppointmentEntity {
  const factory AppointmentEntity({
    required String id,
    required String serviceName,
    required DateTime date,
    required double price,
    required String status, // 'upcoming', 'completed', 'cancelled'
    String? notes,
  }) = _AppointmentEntity;
}
