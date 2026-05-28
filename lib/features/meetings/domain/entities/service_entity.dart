import 'package:freezed_annotation/freezed_annotation.dart';

part 'service_entity.freezed.dart';
part 'service_entity.g.dart';

@freezed
class ServiceEntity with _$ServiceEntity {
  const factory ServiceEntity({
    required String id,
    required String name,
    required String description,
    @Default(0) double price,
    required int durationMinutes,
  }) = _ServiceEntity;

  factory ServiceEntity.fromJson(Map<String, dynamic> json) =>
      _$ServiceEntityFromJson(json);
}
