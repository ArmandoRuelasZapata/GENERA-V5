import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  /// Login con email y password
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  });

  /// Registro de nuevo usuario
  Future<Either<Failure, User>> register({
    required String email,
    required String name,
    required String password,
    String? phone,
  });

  /// Logout
  Future<Either<Failure, void>> logout();

  /// Obtener usuario actual guardado localmente
  Future<Either<Failure, User?>> getCurrentUser();

  /// Verificar si hay sesión activa
  Future<bool> isLoggedIn();

  /// Reactivar cuenta (sin token)
  Future<Either<Failure, void>> activateAccount({
    required String email,
    required String password,
  });

  /// Desactivar cuenta (requiere token del auth externo)
  Future<Either<Failure, void>> deactivateAccount({
    required String password,
  });

  /// Eliminar cuenta (requiere token del auth externo)
  Future<Either<Failure, void>> deleteAccount({
    required String password,
  });

  /// Persistencia de inactividad
  Future<void> saveLastActivity();
  Future<int?> getLastActivity();

  /// Limpieza total (Fresh install fix)
  Future<void> clearAllSecureData();
}
