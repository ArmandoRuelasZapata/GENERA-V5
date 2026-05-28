import 'package:dio/dio.dart';

/// Calback invocado cuando el servidor devuelve 401 (token expirado o inválido).
/// Debe limpiar el estado de sesión local y redirigir al usuario al login.
typedef OnUnauthorized = Future<void> Function();

/// Interceptor que detecta respuestas HTTP 401 Unauthorized y dispara
/// el cierre de sesión automático para evitar estados inconsistentes
/// cuando el token JWT ha expirado o sido revocado.
///
/// Uso:
/// ```dart
/// dio.interceptors.add(UnauthorizedInterceptor(
///   onUnauthorized: () async {
///     await authRepository.logout();
///     router.go('/login');
///   },
/// ));
/// ```
class UnauthorizedInterceptor extends Interceptor {
  final OnUnauthorized onUnauthorized;

  /// Evita múltiples llamadas simultáneas a [onUnauthorized] mientras
  /// el primer cierre de sesión aún se está procesando.
  bool _isHandling = false;

  UnauthorizedInterceptor({required this.onUnauthorized});

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 && !_isHandling) {
      _isHandling = true;
      try {
        await onUnauthorized();
      } finally {
        _isHandling = false;
      }
    }
    handler.next(err);
  }
}
