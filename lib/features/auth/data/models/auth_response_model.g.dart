// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AuthResponseModelImpl _$$AuthResponseModelImplFromJson(
        Map<String, dynamic> json) =>
    _$AuthResponseModelImpl(
      token: json['token'] as String?,
      tokenVerificacion: json['token_verificacion'] as String?,
      message: json['message'] as String?,
      error: json['error'] as String?,
      user: json['user'] == null
          ? null
          : UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$AuthResponseModelImplToJson(
        _$AuthResponseModelImpl instance) =>
    <String, dynamic>{
      'token': instance.token,
      'token_verificacion': instance.tokenVerificacion,
      'message': instance.message,
      'error': instance.error,
      'user': instance.user,
    };
