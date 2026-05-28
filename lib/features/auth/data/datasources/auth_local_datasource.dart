import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> saveUser(UserModel user);
  Future<void> saveAuthToken(String token);
  Future<String?> getAuthToken();
  Future<void> saveSessionTtl(int expiresInSeconds);
  Future<UserModel?> getUser();
  Future<void> clearUser();
  Future<bool> isLoggedIn();
  Future<void> saveLastActivity();
  Future<int?> getLastActivity();
  Future<void> clearAllSecureData();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage secureStorage;

  AuthLocalDataSourceImpl({
    required this.secureStorage,
  });

  @override
  Future<void> saveUser(UserModel user) async {
    try {
      if (user.token != null) {
        await secureStorage.write(
          key: StorageKeys.accessToken,
          value: user.token,
        );
      }

      await secureStorage.write(key: StorageKeys.userId, value: user.id);
      await secureStorage.write(key: StorageKeys.userEmail, value: user.email);
      await secureStorage.write(key: StorageKeys.userName, value: user.name);

      if (user.phone != null) {
        await secureStorage.write(
            key: StorageKeys.userPhone, value: user.phone!);
      }

      if (user.profileImage != null) {
        await secureStorage.write(
          key: StorageKeys.userProfileImg,
          value: user.profileImage!,
        );
      }

      // Guardar timestamp de login para validación de TTL local.
      // Si el backend ya guardó expires_in con saveSessionTtl(),
      // este timestamp marca cuándo empieza a contar.
      final nowEpochSeconds =
          DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
      await secureStorage.write(
        key: StorageKeys.loginAt,
        value: nowEpochSeconds.toString(),
      );

      await secureStorage.write(key: StorageKeys.isLoggedIn, value: 'true');
    } catch (e) {
      throw CacheException('Failed to save user: $e');
    }
  }

  @override
  Future<void> saveAuthToken(String token) async {
    try {
      await secureStorage.write(
        key: StorageKeys.authToken,
        value: token,
      );
    } catch (e) {
      throw CacheException('Failed to save auth token: $e');
    }
  }

  @override
  Future<String?> getAuthToken() async {
    try {
      return await secureStorage.read(key: StorageKeys.authToken);
    } catch (e) {
      throw CacheException('Failed to get auth token: $e');
    }
  }

  @override
  Future<void> saveSessionTtl(int expiresInSeconds) async {
    try {
      await secureStorage.write(
        key: StorageKeys.expiresIn,
        value: expiresInSeconds.toString(),
      );
    } catch (e) {
      throw CacheException('Failed to save session TTL: $e');
    }
  }

  @override
  Future<UserModel?> getUser() async {
    try {
      final isLoggedStr = await secureStorage.read(key: StorageKeys.isLoggedIn);
      final isLogged = isLoggedStr == 'true';

      if (!isLogged) return null;

      final userId = await secureStorage.read(key: StorageKeys.userId);
      final email = await secureStorage.read(key: StorageKeys.userEmail);
      final name = await secureStorage.read(key: StorageKeys.userName);
      final phone = await secureStorage.read(key: StorageKeys.userPhone);
      final profileImg =
          await secureStorage.read(key: StorageKeys.userProfileImg);
      final token = await secureStorage.read(key: StorageKeys.accessToken);

      if (userId == null || email == null || name == null) {
        return null;
      }

      return UserModel(
        id: userId,
        email: email,
        name: name,
        phone: phone,
        profileImage: profileImg,
        token: token,
      );
    } catch (e) {
      throw CacheException('Failed to get user: $e');
    }
  }

  @override
  Future<void> clearUser() async {
    try {
      await secureStorage.delete(key: StorageKeys.accessToken);
      await secureStorage.delete(key: StorageKeys.authToken);
      await secureStorage.delete(key: StorageKeys.userId);
      await secureStorage.delete(key: StorageKeys.userEmail);
      await secureStorage.delete(key: StorageKeys.userName);
      await secureStorage.delete(key: StorageKeys.userPhone);
      await secureStorage.delete(key: StorageKeys.userProfileImg);
      await secureStorage.delete(key: StorageKeys.loginAt);
      await secureStorage.delete(key: StorageKeys.expiresIn);
      await secureStorage.delete(key: StorageKeys.lastActivityAt);
      await secureStorage.write(key: StorageKeys.isLoggedIn, value: 'false');
    } catch (e) {
      throw CacheException('Failed to clear user: $e');
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    final value = await secureStorage.read(key: StorageKeys.isLoggedIn);
    if (value != 'true') return false;

    final token = await secureStorage.read(key: StorageKeys.accessToken);
    if (token == null || token.isEmpty) {
      await clearUser();
      return false;
    }

    // ── Validación 1: TTL local (expires_in del backend) ────────────────────
    // Prioridad alta: si el backend mandó expires_in, calculamos la expiración
    // localmente sin hacer ninguna llamada de red.
    final loginAtStr = await secureStorage.read(key: StorageKeys.loginAt);
    final expiresInStr = await secureStorage.read(key: StorageKeys.expiresIn);

    if (loginAtStr != null && expiresInStr != null) {
      final loginAt = int.tryParse(loginAtStr);
      final expiresIn = int.tryParse(expiresInStr);

      if (loginAt != null && expiresIn != null) {
        final expiryEpoch = loginAt + expiresIn;
        final nowEpoch = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;

        if (nowEpoch >= expiryEpoch) {
          await clearUser();
          return false;
        }

        // TTL válido — sesión activa
        return true;
      }
    }

    // ── Validación 2: exp en JWT (fallback para futura migración) ────────────
    // Solo aplica si el backend alguna vez manda un JWT estándar.
    final isExpired = _isJwtExpired(token);
    if (isExpired == true) {
      await clearUser();
      return false;
    }

    return true;
  }

  bool? _isJwtExpired(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;

    try {
      final normalizedPayload = base64Url.normalize(parts[1]);
      final payloadJson = utf8.decode(base64Url.decode(normalizedPayload));
      final payloadMap = jsonDecode(payloadJson) as Map<String, dynamic>;
      final expRaw = payloadMap['exp'];
      final expSeconds = _asInt(expRaw);
      if (expSeconds == null) return null;

      final expiry = DateTime.fromMillisecondsSinceEpoch(
        expSeconds * 1000,
        isUtc: true,
      );
      return DateTime.now().toUtc().isAfter(expiry);
    } catch (_) {
      return null;
    }
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  @override
  Future<void> saveLastActivity() async {
    try {
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      await secureStorage.write(
        key: StorageKeys.lastActivityAt,
        value: now.toString(),
      );
    } catch (_) {}
  }

  @override
  Future<int?> getLastActivity() async {
    try {
      final value = await secureStorage.read(key: StorageKeys.lastActivityAt);
      return value != null ? int.tryParse(value) : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearAllSecureData() async {
    try {
      await secureStorage.deleteAll();
    } catch (e) {
      throw CacheException('Failed to clear all secure data: $e');
    }
  }
}
