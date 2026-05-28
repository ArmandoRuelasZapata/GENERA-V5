// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ServiceEntityImpl _$$ServiceEntityImplFromJson(Map<String, dynamic> json) =>
    _$ServiceEntityImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      durationMinutes: (json['durationMinutes'] as num).toInt(),
    );

Map<String, dynamic> _$$ServiceEntityImplToJson(_$ServiceEntityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'price': instance.price,
      'durationMinutes': instance.durationMinutes,
    };
