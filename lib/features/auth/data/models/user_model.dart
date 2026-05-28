import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/user.dart';
part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const UserModel._();

  const factory UserModel({
    required String id,
    required String email,
    required String name,
    String? phone,
    @JsonKey(name: 'profile_img') String? profileImage,
    String? token,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  /// Convertir a entidad de dominio
  User toEntity() => User(
        id: id,
        email: email,
        name: name,
        phone: phone,
        profileImage: profileImage,
        token: token,
      );

  /// Crear desde entidad de dominio
  factory UserModel.fromEntity(User user) => UserModel(
        id: user.id,
        email: user.email,
        name: user.name,
        phone: user.phone,
        profileImage: user.profileImage,
        token: user.token,
      );
}
