import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:theoriginallab_v2/core/constants/api_constants.dart';
import 'package:theoriginallab_v2/core/error/exceptions.dart';
import 'package:theoriginallab_v2/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:theoriginallab_v2/features/auth/data/models/user_model.dart';

import 'auth_remote_datasource_test.mocks.dart';

@GenerateNiceMocks([MockSpec<Dio>()])
void main() {
  late AuthRemoteDataSourceImpl dataSource;
  late MockDio mockDio;
  late MockDio mockExchangeDio;

  setUp(() {
    mockDio = MockDio();
    mockExchangeDio = MockDio();
    dataSource = AuthRemoteDataSourceImpl(
      mockDio,
      exchangeDio: mockExchangeDio,
    );
  });

  group('login', () {
    const tEmail = 'test@example.com';
    const tPassword = 'password123';
    const tSecureToken = 'secure-token';

    test(
        'should return UserModel when the response code is 200 and success is true',
        () async {
      // Arrange
      final responseData = {
        'success': true,
        'message': 'Login successful',
        'data': {
          'token': 'legacy-token',
          'user': {
            'id': 1,
            'email': tEmail,
            'name': 'Test User',
            'phone': '1234567890',
            'profile_img': null
          }
        }
      };

      when(mockDio.post(
        ApiConstants.loginEndpoint,
        data: anyNamed('data'),
      )).thenAnswer((_) async => Response(
            data: responseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: ApiConstants.loginEndpoint),
          ));
      when(mockExchangeDio.post(
        '/api/auth/exchange',
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
            data: {
              'success': true,
              'data': {'token': tSecureToken, 'expires_in': 2592000}
            },
            statusCode: 200,
            requestOptions: RequestOptions(path: '/api/auth/exchange'),
          ));

      // Act
      final result = await dataSource.login(email: tEmail, password: tPassword);

      // Assert
      expect(result, isA<UserModel>());
      expect(result.email, tEmail);
      expect(result.token, tSecureToken);
    });

    test(
        'should throw ServerException when response code is 401 (Unauthorized)',
        () async {
      // Arrange
      when(mockDio.post(
        ApiConstants.loginEndpoint,
        data: anyNamed('data'),
      )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.loginEndpoint),
        response: Response(
          statusCode: 401,
          data: {'message': 'Credenciales incorrectas'},
          requestOptions: RequestOptions(path: ApiConstants.loginEndpoint),
        ),
      ));

      // Act
      final call = dataSource.login;

      // Assert
      expect(() => call(email: tEmail, password: tPassword),
          throwsA(isA<ServerException>()));
    });
  });

  group('register', () {
    const tEmail = 'new@example.com';
    const tPassword = 'password123';
    const tName = 'New User';
    const tSecureToken = 'secure-token';

    test('should return UserModel on successful registration', () async {
      // Arrange
      final responseData = {
        'success': true,
        'message': 'Registration successful',
        'data': {
          'token': 'legacy-token',
          'user': {
            'id': 2,
            'email': tEmail,
            'name': tName,
            'phone': null,
            'profile_img': null
          }
        }
      };

      when(mockDio.post(
        ApiConstants.registerEndpoint,
        data: anyNamed('data'),
      )).thenAnswer((_) async => Response(
            data: responseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: ApiConstants.registerEndpoint),
          ));
      when(mockExchangeDio.post(
        '/api/auth/exchange',
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
            data: {
              'success': true,
              'data': {'token': tSecureToken, 'expires_in': 2592000}
            },
            statusCode: 200,
            requestOptions: RequestOptions(path: '/api/auth/exchange'),
          ));

      // Act
      final result = await dataSource.register(
        email: tEmail,
        password: tPassword,
        name: tName,
      );

      // Assert
      expect(result, isA<UserModel>());
      expect(result.email, tEmail);
      expect(result.token, tSecureToken);
    });

    test(
        'should return UserModel when registration responds 201 and success is true',
        () async {
      // Arrange
      final responseData = {
        'success': true,
        'message': 'Usuario registrado con éxito',
        'data': {
          'token': 'legacy-token',
          'user': {
            'id': 3,
            'email': tEmail,
            'name': tName,
            'phone': null,
            'profile_img': null
          }
        }
      };

      when(mockDio.post(
        ApiConstants.registerEndpoint,
        data: anyNamed('data'),
      )).thenAnswer((_) async => Response(
            data: responseData,
            statusCode: 201,
            requestOptions: RequestOptions(path: ApiConstants.registerEndpoint),
          ));
      when(mockExchangeDio.post(
        '/api/auth/exchange',
        data: anyNamed('data'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
            data: {
              'success': true,
              'data': {'token': tSecureToken, 'expires_in': 2592000}
            },
            statusCode: 200,
            requestOptions: RequestOptions(path: '/api/auth/exchange'),
          ));

      // Act
      final result = await dataSource.register(
        email: tEmail,
        password: tPassword,
        name: tName,
      );

      // Assert
      expect(result, isA<UserModel>());
      expect(result.email, tEmail);
      expect(result.token, tSecureToken);
    });

    test('should throw ServerException when registration fails', () async {
      // Arrange
      when(mockDio.post(
        ApiConstants.registerEndpoint,
        data: anyNamed('data'),
      )).thenAnswer((_) async => Response(
            data: {'success': false, 'message': 'Email already exists'},
            statusCode: 400,
            requestOptions: RequestOptions(path: ApiConstants.registerEndpoint),
          ));

      // Act
      final call = dataSource.register;

      // Assert
      expect(
        () => call(email: tEmail, password: tPassword, name: tName),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
