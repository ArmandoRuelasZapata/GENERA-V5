import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:theoriginallab_v2/core/network/interceptors/unauthorized_interceptor.dart';

void main() {
  group('UnauthorizedInterceptor', () {
    // ─────────────────────────────────────────────────────────────────────
    // Helper: simula la invocación onError del interceptor directamente
    // ─────────────────────────────────────────────────────────────────────
    Future<void> triggerError(
      UnauthorizedInterceptor interceptor,
      DioException err,
    ) async {
      final handler = _NoOpErrorHandler();
      await interceptor.onError(err, handler);
    }

    DioException make401({String path = '/protected'}) => DioException(
          requestOptions: RequestOptions(path: path),
          response: Response(
            statusCode: 401,
            data: {'message': 'Unauthorized'},
            requestOptions: RequestOptions(path: path),
          ),
          type: DioExceptionType.badResponse,
        );

    // ─────────────────────────────────────────────────────────────────────
    // Tests
    // ─────────────────────────────────────────────────────────────────────

    test('callback is invoked when DioException has status 401', () async {
      bool callbackCalled = false;
      final interceptor = UnauthorizedInterceptor(
        onUnauthorized: () async {
          callbackCalled = true;
        },
      );

      await triggerError(interceptor, make401());

      expect(callbackCalled, isTrue,
          reason: 'El callback debe ejecutarse al recibir 401');
    });

    test('callback is NOT invoked for non-401 (404) errors', () async {
      bool callbackCalled = false;
      final interceptor = UnauthorizedInterceptor(
        onUnauthorized: () async {
          callbackCalled = true;
        },
      );

      final err = DioException(
        requestOptions: RequestOptions(path: '/not-found'),
        response: Response(
          statusCode: 404,
          data: {'message': 'Not Found'},
          requestOptions: RequestOptions(path: '/not-found'),
        ),
        type: DioExceptionType.badResponse,
      );

      await triggerError(interceptor, err);

      expect(callbackCalled, isFalse,
          reason:
              'El callback NO debe ejecutarse para errores distintos de 401');
    });

    test('callback is NOT invoked for network errors (no response)', () async {
      bool callbackCalled = false;
      final interceptor = UnauthorizedInterceptor(
        onUnauthorized: () async {
          callbackCalled = true;
        },
      );

      final err = DioException(
        requestOptions: RequestOptions(path: '/no-conn'),
        type: DioExceptionType.connectionError,
        // Sin `response` — error de conectividad
      );

      await triggerError(interceptor, err);

      expect(callbackCalled, isFalse,
          reason: 'El callback NO debe ejecutarse para errores de conexión');
    });

    test('concurrent 401s only trigger callback once (_isHandling guard)',
        () async {
      int invokedCount = 0;
      final interceptor = UnauthorizedInterceptor(
        onUnauthorized: () async {
          invokedCount++;
          await Future.delayed(const Duration(milliseconds: 50));
        },
      );

      // Lanzar dos 401 simultáneos
      await Future.wait([
        triggerError(interceptor, make401(path: '/a')),
        triggerError(interceptor, make401(path: '/b')),
      ]);

      expect(invokedCount, 1,
          reason:
              'El callback solo debe ejecutarse UNA VEZ aunque lleguen 401s concurrentes');
    });
  });
}

/// Handler vacío — solo necesario para satisfacer la firma de onError
class _NoOpErrorHandler extends ErrorInterceptorHandler {
  @override
  void next(DioException err) {}

  @override
  void reject(DioException err) {}
}
