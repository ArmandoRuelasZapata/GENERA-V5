import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:theoriginallab_v2/core/constants/storage_keys.dart';
import 'package:theoriginallab_v2/features/auth/data/datasources/auth_local_datasource.dart';

class InMemorySecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _store = <String, String>{};

  @override
  Future<String?> read({
    required String key,
    AndroidOptions? aOptions,
    AppleOptions? iOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions, // ignore: avoid_renaming_method_parameters
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _store[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AndroidOptions? aOptions,
    AppleOptions? iOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions, // ignore: avoid_renaming_method_parameters
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _store.remove(key);
      return;
    }
    _store[key] = value;
  }

  @override
  Future<void> delete({
    required String key,
    AndroidOptions? aOptions,
    AppleOptions? iOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions, // ignore: avoid_renaming_method_parameters
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _store.remove(key);
  }

  void seed(String key, String value) {
    _store[key] = value;
  }

  String? get(String key) => _store[key];
}

void main() {
  late InMemorySecureStorage secureStorage;
  late AuthLocalDataSourceImpl dataSource;

  setUp(() {
    secureStorage = InMemorySecureStorage();
    dataSource = AuthLocalDataSourceImpl(secureStorage: secureStorage);
  });

  group('isLoggedIn', () {
    test('returns true when login flag is true and token exp is in the future',
        () async {
      secureStorage.seed(StorageKeys.isLoggedIn, 'true');
      secureStorage.seed(
        StorageKeys.accessToken,
        _jwtWithExp(DateTime.now().toUtc().add(const Duration(hours: 1))),
      );

      final result = await dataSource.isLoggedIn();

      expect(result, isTrue);
      expect(secureStorage.get(StorageKeys.isLoggedIn), 'true');
      expect(secureStorage.get(StorageKeys.accessToken), isNotNull);
    });

    test('returns false and clears session when token is expired', () async {
      secureStorage.seed(StorageKeys.isLoggedIn, 'true');
      secureStorage.seed(
        StorageKeys.accessToken,
        _jwtWithExp(DateTime.now().toUtc().subtract(const Duration(hours: 1))),
      );
      secureStorage.seed(StorageKeys.userId, '1');
      secureStorage.seed(StorageKeys.userEmail, 'test@example.com');
      secureStorage.seed(StorageKeys.userName, 'Test User');

      final result = await dataSource.isLoggedIn();

      expect(result, isFalse);
      expect(secureStorage.get(StorageKeys.isLoggedIn), 'false');
      expect(secureStorage.get(StorageKeys.accessToken), isNull);
      expect(secureStorage.get(StorageKeys.userId), isNull);
    });

    test('returns false and clears session when token is missing', () async {
      secureStorage.seed(StorageKeys.isLoggedIn, 'true');
      secureStorage.seed(StorageKeys.userId, '1');
      secureStorage.seed(StorageKeys.userEmail, 'test@example.com');
      secureStorage.seed(StorageKeys.userName, 'Test User');

      final result = await dataSource.isLoggedIn();

      expect(result, isFalse);
      expect(secureStorage.get(StorageKeys.isLoggedIn), 'false');
      expect(secureStorage.get(StorageKeys.accessToken), isNull);
      expect(secureStorage.get(StorageKeys.userId), isNull);
    });
  });
}

String _jwtWithExp(DateTime expiryUtc) {
  final expSeconds = expiryUtc.millisecondsSinceEpoch ~/ 1000;
  final header = _base64UrlNoPadding(
    jsonEncode(<String, dynamic>{'alg': 'HS256', 'typ': 'JWT'}),
  );
  final payload = _base64UrlNoPadding(
    jsonEncode(<String, dynamic>{'sub': 'user-1', 'exp': expSeconds}),
  );
  final signature = _base64UrlNoPadding('signature');
  return '$header.$payload.$signature';
}

String _base64UrlNoPadding(String value) {
  return base64Url.encode(utf8.encode(value)).replaceAll('=', '');
}
