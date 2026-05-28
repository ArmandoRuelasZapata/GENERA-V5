import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/network_error.dart';
import '../../../../core/network/network_error_mapper.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  /// Expira en (segundos) del último login exitoso. Nulo si no se ha hecho login.
  int? get lastExpiresIn;

  /// Token original del auth externo del último login exitoso.
  String? get lastAuthToken;

  Future<UserModel> login({required String email, required String password});

  Future<UserModel> register({
    required String email,
    required String name,
    required String password,
    String? phone,
  });

  // Password Reset
  Future<void> requestPasswordReset(String email);
  Future<String> verifyResetCode(String email, String code);
  Future<void> changePassword({
    required String email,
    required String changeToken,
    required String newPassword,
  });

  // Account Management
  Future<void> activateAccount({
    required String email,
    required String password,
  });
  Future<void> deactivateAccount({
    required String email,
    required String password,
    required String token,
  });

  Future<void> deleteAccount({
    required String email,
    required String password,
    required String token,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;
  final Dio exchangeDio;

  AuthRemoteDataSourceImpl(
    this.dio, {
    Dio? exchangeDio,
  }) : exchangeDio = exchangeDio ?? dio;

  /// Almacena el expires_in del último login para que el repositorio
  /// lo persista localmente sin necesidad de pasar por el UserModel.
  @override
  int? lastExpiresIn;
  @override
  String? lastAuthToken;

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      // Encode password to Base64
      final encodedPassword = base64.encode(utf8.encode(password));

      if (kDebugMode) debugPrint('Intentando login...');

      final response = await dio.post(
        ApiConstants.loginEndpoint,
        data: {'email': email, 'password': encodedPassword},
      );

      final isHttpSuccess = response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;

      if (isHttpSuccess && response.data['success'] == true) {
        // La API devuelve: { success, message, data: { token, user, ... } }
        final data = response.data['data'] as Map<String, dynamic>?;
        if (data == null) {
          throw ServerException(
              'La respuesta inicial del servidor no contiene datos válidos.');
        }

        // Guardar token original del auth externo
        final rawAuthToken = data['token'];
        if (rawAuthToken is String && rawAuthToken.isNotEmpty) {
          lastAuthToken = rawAuthToken;
        } else {
          lastAuthToken = null;
        }

        // --- INICIO TOKEN EXCHANGE PATTERN ---
        // Ignoramos el token original y las claims de expiración originales.
        final userData = data['user'] as Map<String, dynamic>?;
        if (userData == null) {
          throw ServerException(
              'Datos de usuario no encontrados en la respuesta.');
        }

        if (kDebugMode) debugPrint('Login externo exitoso, canjeando JWT...');

        final exchangeResponse = await exchangeDio.post(
          '/api/auth/exchange',
          data: {
            'user_id': userData['id'],
            'email': userData['email'],
            'name': userData['name'],
            'role': userData['role'] ?? 'USER',
          },
          options: Options(
            extra: {'skipAuth': true}, // No necesitamos token para el canje
          ),
        );

        final exchangeData =
            exchangeResponse.data['data'] as Map<String, dynamic>?;
        if (exchangeData == null) {
          throw ServerException(
              'La respuesta de intercambio no contiene datos válidos. Revisa el cifrado o backend.');
        }
        final secureToken = exchangeData['token'] as String;
        final ttl = exchangeData['expires_in'];

        if (kDebugMode) {
          debugPrint(
              'Canje exitoso: JWT propio asegurado (Expira en $ttl sec)');
        }
        // --- FIN TOKEN EXCHANGE PATTERN ---

        // Exponer el TTL del token intercambiado
        final parsedExpiry = ttl is int
            ? ttl
            : ttl is String
                ? int.tryParse(ttl.toString())
                : null;
        lastExpiresIn = parsedExpiry;

        // Crear usuario con los datos recibidos y el NUEVO TOKEN SEGURO
        return UserModel(
          id: userData['id'].toString(),
          email: userData['email'],
          name: userData['name'],
          phone: userData['phone'],
          profileImage: userData['profile_img'],
          token: secureToken,
        );
      } else {
        throw ServerException(response.data['message'] ?? 'Login failed');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('Error en login: ${e.response?.statusCode ?? e.type}');
      }
      _throwMappedAuthException(
        e,
        fallbackServerMessage:
            'Error de autenticación (Cód: ${e.response?.statusCode ?? e.type})',
      );
    } catch (e) {
      if (e is ServerException || e is NetworkException) {
        rethrow;
      }
      if (kDebugMode) debugPrint('Error inesperado: $e');
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<UserModel> register({
    required String email,
    required String name,
    required String password,
    String? phone,
  }) async {
    try {
      // Encode password to Base64
      final encodedPassword = base64.encode(utf8.encode(password));

      if (kDebugMode) debugPrint('Intentando registro...');

      final response = await dio.post(
        ApiConstants.registerEndpoint,
        data: {
          'email': email,
          'name': name,
          'password': encodedPassword,
          'phone': phone ?? '',
          'profile_img': null,
        },
      );

      final isHttpSuccess = response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;

      if (isHttpSuccess && response.data['success'] == true) {
        // La API devuelve: { success, message, data: { token, user, ... } }
        final data = response.data['data'] as Map<String, dynamic>?;
        if (data == null) {
          throw ServerException(
              'La respuesta de registro no contiene datos válidos.');
        }

        final userData = data['user'] as Map<String, dynamic>?;
        final userId = userData?['id'] ?? data['user_id'];
        if (userId == null) {
          if (kDebugMode) {
            debugPrint(
              'Registro exitoso, pero sin user_id. '
              'Se omite el canje de JWT.',
            );
          }
          // Registro OK pero la API no devolvió user_id: no forzar error.
          return UserModel(
            id: '',
            email: email,
            name: name,
            phone: phone,
            profileImage: null,
            token: null,
          );
        }

        // --- INICIO TOKEN EXCHANGE PATTERN ---
        if (kDebugMode) {
          debugPrint('Registro externo exitoso, canjeando JWT...');
        }

        final exchangeResponse = await exchangeDio.post(
          '/api/auth/exchange',
          data: {
            'user_id': userId,
            'email': email,
            'name': name,
            'role': 'USER',
          },
          options: Options(
            extra: {'skipAuth': true}, // No necesitamos token para el canje
          ),
        );

        final exchangeData =
            exchangeResponse.data['data'] as Map<String, dynamic>?;
        if (exchangeData == null) {
          throw ServerException(
              'La respuesta de intercambio no contiene datos válidos. Revisa el cifrado o backend.');
        }
        final secureToken = exchangeData['token'] as String;
        final ttl = exchangeData['expires_in'];

        if (kDebugMode) {
          debugPrint(
              'Canje exitoso: JWT propio asegurado (Expira en $ttl sec)');
        }

        // Exponer el TTL del token intercambiado
        final parsedExpiry = ttl is int
            ? ttl
            : ttl is String
                ? int.tryParse(ttl.toString())
                : null;
        lastExpiresIn = parsedExpiry;
        // --- FIN TOKEN EXCHANGE PATTERN ---

        // Devolver usuario con el token seguro
        if (userData != null) {
          return UserModel(
            id: userData['id'].toString(),
            email: userData['email'],
            name: userData['name'],
            phone: userData['phone'],
            profileImage: userData['profile_img'],
            token: secureToken,
          );
        }

        // Si no, crear usuario con los datos que enviamos
        return UserModel(
          id: userId?.toString() ?? '',
          email: email,
          name: name,
          phone: phone,
          profileImage: null,
          token: secureToken,
        );
      } else {
        throw ServerException(
          response.data['message'] ?? 'Registration failed',
        );
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('Error en registro: ${e.response?.statusCode ?? e.type}');
      }
      _throwMappedAuthException(
        e,
        fallbackServerMessage: 'Error en el registro',
      );
    } catch (e) {
      if (e is ServerException || e is NetworkException) {
        rethrow;
      }
      if (kDebugMode) debugPrint('Error inesperado: $e');
      throw ServerException('Error inesperado, intenta de nuevo');
    }
  }

  // ============================================================================
  // ACCOUNT MANAGEMENT
  // ============================================================================

  @override
  Future<void> activateAccount({
    required String email,
    required String password,
  }) async {
    try {
      if (kDebugMode) debugPrint('Reactivando cuenta...');

      final encodedPassword = base64.encode(utf8.encode(password));

      final response = await dio.patch(
        ApiConstants.activateEndpoint,
        data: {
          'email': email,
          'password': encodedPassword,
        },
      );

      if (response.data['success'] == true) {
        if (kDebugMode) debugPrint('Cuenta reactivada');
        return;
      }

      throw ServerException(
        response.data['message'] ?? 'No se pudo reactivar la cuenta',
      );
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('Error en activateAccount: ${e.response?.data}');
      }
      _throwMappedAuthException(
        e,
        fallbackServerMessage: 'Error al reactivar cuenta',
      );
    }
  }

  @override
  Future<void> deactivateAccount({
    required String email,
    required String password,
    required String token,
  }) async {
    try {
      if (kDebugMode) debugPrint('Desactivando cuenta...');

      final encodedPassword = base64.encode(utf8.encode(password));

      final response = await dio.patch(
        ApiConstants.deactivateEndpoint,
        data: {
          'email': email,
          'password': encodedPassword,
          'token': token,
        },
      );

      if (response.data['success'] == true) {
        if (kDebugMode) debugPrint('Cuenta desactivada');
        return;
      }

      throw ServerException(
        response.data['message'] ?? 'No se pudo desactivar la cuenta',
      );
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('Error en deactivateAccount: ${e.response?.data}');
      }
      _throwMappedAuthException(
        e,
        fallbackServerMessage: 'Error al desactivar cuenta',
      );
    }
  }

  @override
  Future<void> deleteAccount({
    required String email,
    required String password,
    required String token,
  }) async {
    try {
      if (kDebugMode) debugPrint('Eliminando cuenta...');

      final encodedPassword = base64.encode(utf8.encode(password));

      final response = await dio.delete(
        ApiConstants.eliminateAccountEndpoint,
        data: {
          'email': email,
          'password': encodedPassword,
          'token': token,
        },
      );

      if (response.data['success'] == true) {
        if (kDebugMode) debugPrint('Cuenta eliminada');
        return;
      }

      throw ServerException(
        response.data['message'] ?? 'No se pudo eliminar la cuenta',
      );
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('Error en deleteAccount: ${e.response?.data}');
      }
      _throwMappedAuthException(
        e,
        fallbackServerMessage: 'Error al eliminar cuenta',
      );
    }
  }

  // ============================================================================
  // PASSWORD RESET METHODS
  // ============================================================================

  @override
  Future<void> requestPasswordReset(String email) async {
    try {
      if (kDebugMode) {
        debugPrint('Solicitando restablecimiento de contraseña...');
      }

      final response = await dio.post(
        ApiConstants.emailResetPassword,
        data: {'email': email},
      );

      if (kDebugMode) debugPrint('Solicitud de reset enviada');

      if (response.data['success'] == true) {
        return;
      } else {
        throw ServerException(
          response.data['message'] ?? 'Error al solicitar restablecimiento',
        );
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('Error en requestPasswordReset: ${e.response?.data}');
      }
      _throwMappedAuthException(
        e,
        fallbackServerMessage: 'Error al solicitar restablecimiento',
      );
    }
  }

  @override
  Future<String> verifyResetCode(String email, String code) async {
    try {
      if (kDebugMode) debugPrint('Verificando codigo de reset...');

      final response = await dio.post(
        ApiConstants.verifyCode,
        data: {'email': email, 'code': code},
      );

      if (kDebugMode) debugPrint('Codigo verificado correctamente');

      if (response.data['success'] == true) {
        final changeToken = response.data['data']['change_token'] as String;
        return changeToken;
      } else {
        throw ServerException(response.data['message'] ?? 'Código inválido');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('Error en verifyResetCode: ${e.response?.data}');
      }
      _throwMappedAuthException(
        e,
        fallbackServerMessage: 'Código inválido',
      );
    }
  }

  @override
  Future<void> changePassword({
    required String email,
    required String changeToken,
    required String newPassword,
  }) async {
    try {
      if (kDebugMode) debugPrint('Cambiando contrasena...');

      // Codificar password en Base64
      final encodedPassword = base64.encode(utf8.encode(newPassword));

      final response = await dio.post(
        ApiConstants.changePassword,
        data: {
          'email': email,
          'change_token': changeToken,
          'new_password': encodedPassword,
        },
      );

      if (kDebugMode) debugPrint('Contrasena cambiada correctamente');

      if (response.data['success'] == true) {
        return;
      } else {
        throw ServerException(
          response.data['message'] ?? 'Error al cambiar contraseña',
        );
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('Error en changePassword: ${e.response?.data}');
      }
      _throwMappedAuthException(
        e,
        fallbackServerMessage: 'Error al cambiar contraseña',
      );
    }
  }

  Never _throwMappedAuthException(
    DioException error, {
    required String fallbackServerMessage,
  }) {
    if (error.response?.statusCode == 429) {
      throw ServerException(
        'Demasiados intentos. Espera un momento y vuelve a intentar.',
      );
    }

    final mapped = NetworkErrorMapper.fromDioException(error);
    final serverMessage =
        _extractServerMessage(error.response?.data) ?? fallbackServerMessage;

    if (mapped.type == NetworkErrorType.network ||
        mapped.type == NetworkErrorType.timeout) {
      throw NetworkException(mapped.message);
    }

    throw ServerException(serverMessage);
  }

  String? _extractServerMessage(dynamic data) {
    if (data == null) return null;

    if (data is String) {
      if (data.contains('<html')) {
        return 'Error del servidor. Intenta más tarde.';
      }
      return data.isNotEmpty ? data : null;
    }

    if (data is Map) {
      final message = data['message'];
      if (message is String && message.isNotEmpty) return message;

      final error = data['error'];
      if (error is String && error.isNotEmpty) return error;
      if (error is Map && error['message'] is String) {
        final nested = error['message'] as String;
        if (nested.isNotEmpty) return nested;
      }
    }

    return null;
  }
}
