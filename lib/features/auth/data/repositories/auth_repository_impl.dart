import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  }) async {
    try {
      final userModel = await remoteDataSource.login(
        email: email,
        password: password,
      );

      // Guardar usuario primero (registra login_at internamente)
      await localDataSource.saveUser(userModel);

      // Guardar el TTL recibido del backend para validación offline.
      // remoteDataSource expone el último expires_in recibido.
      final expiresIn = remoteDataSource.lastExpiresIn;
      if (expiresIn != null) {
        await localDataSource.saveSessionTtl(expiresIn);
      }

      final authToken = remoteDataSource.lastAuthToken;
      if (authToken != null && authToken.isNotEmpty) {
        await localDataSource.saveAuthToken(authToken);
      }

      return Right(userModel.toEntity());
    } on ServerException catch (e) {
      return Left(Failure.server(e.message));
    } on NetworkException catch (e) {
      return Left(Failure.network(e.message));
    } catch (e) {
      return Left(Failure.server('Error inesperado: $e'));
    }
  }

  @override
  Future<Either<Failure, User>> register({
    required String email,
    required String name,
    required String password,
    String? phone,
  }) async {
    try {
      final userModel = await remoteDataSource.register(
        email: email,
        name: name,
        password: password,
        phone: phone,
      );

      // No guardamos automáticamente después del registro
      // El usuario debe validar su email primero

      return Right(userModel.toEntity());
    } on ServerException catch (e) {
      return Left(Failure.server(e.message));
    } on NetworkException catch (e) {
      return Left(Failure.network(e.message));
    } catch (e) {
      return Left(Failure.server('Error inesperado: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await localDataSource.clearUser();
      return const Right(null);
    } on CacheException catch (e) {
      return Left(Failure.cache(e.message));
    } catch (e) {
      return Left(Failure.cache('Error inesperado: $e'));
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final userModel = await localDataSource.getUser();
      return Right(userModel?.toEntity());
    } on CacheException catch (e) {
      return Left(Failure.cache(e.message));
    } catch (e) {
      return Left(Failure.cache('Error inesperado: $e'));
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    return await localDataSource.isLoggedIn();
  }

  @override
  Future<Either<Failure, void>> activateAccount({
    required String email,
    required String password,
  }) async {
    try {
      await remoteDataSource.activateAccount(
        email: email,
        password: password,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(Failure.server(e.message));
    } on NetworkException catch (e) {
      return Left(Failure.network(e.message));
    } catch (e) {
      return Left(Failure.server('Error inesperado: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deactivateAccount({
    required String password,
  }) async {
    try {
      final user = await localDataSource.getUser();
      if (user == null) {
        return const Left(Failure.server('Sesion no valida'));
      }

      final authToken = await localDataSource.getAuthToken();
      if (authToken == null || authToken.isEmpty) {
        return const Left(
          Failure.server(
            'Sesion de auth no encontrada. Cierra sesion e inicia de nuevo.',
          ),
        );
      }

      await remoteDataSource.deactivateAccount(
        email: user.email,
        password: password,
        token: authToken,
      );

      return const Right(null);
    } on ServerException catch (e) {
      return Left(Failure.server(e.message));
    } on NetworkException catch (e) {
      return Left(Failure.network(e.message));
    } catch (e) {
      return Left(Failure.server('Error inesperado: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount({
    required String password,
  }) async {
    try {
      final user = await localDataSource.getUser();
      if (user == null) {
        return const Left(Failure.server('Sesion no valida'));
      }

      final authToken = await localDataSource.getAuthToken();
      if (authToken == null || authToken.isEmpty) {
        return const Left(
          Failure.server(
            'Sesion de auth no encontrada. Cierra sesion e inicia de nuevo.',
          ),
        );
      }

      await remoteDataSource.deleteAccount(
        email: user.email,
        password: password,
        token: authToken,
      );

      return const Right(null);
    } on ServerException catch (e) {
      return Left(Failure.server(e.message));
    } on NetworkException catch (e) {
      return Left(Failure.network(e.message));
    } catch (e) {
      return Left(Failure.server('Error inesperado: $e'));
    }
  }

  @override
  Future<void> saveLastActivity() async {
    await localDataSource.saveLastActivity();
  }

  @override
  Future<int?> getLastActivity() async {
    return await localDataSource.getLastActivity();
  }

  @override
  Future<void> clearAllSecureData() async {
    await localDataSource.clearAllSecureData();
  }
}
