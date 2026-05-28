import 'package:dio/dio.dart';

import 'network_error.dart';

class NetworkErrorMapper {
  static AppNetworkException fromDioException(DioException error) {
    final statusCode = error.response?.statusCode;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppNetworkException(
          type: NetworkErrorType.timeout,
          message: 'La solicitud excedió el tiempo de espera.',
          statusCode: statusCode,
        );
      case DioExceptionType.connectionError:
        return AppNetworkException(
          type: NetworkErrorType.network,
          message: 'No se pudo conectar al servidor. Verifica tu conexión.',
          statusCode: statusCode,
        );
      case DioExceptionType.badResponse:
        return _fromStatusCode(statusCode, error);
      case DioExceptionType.cancel:
        return AppNetworkException(
          type: NetworkErrorType.unknown,
          message: 'La solicitud fue cancelada.',
          statusCode: statusCode,
        );
      case DioExceptionType.badCertificate:
        return AppNetworkException(
          type: NetworkErrorType.network,
          message: 'Error de certificado de seguridad.',
          statusCode: statusCode,
        );
      case DioExceptionType.unknown:
        return AppNetworkException(
          type: NetworkErrorType.unknown,
          message: 'Ocurrió un error inesperado de red.',
          statusCode: statusCode,
        );
    }
  }

  static AppNetworkException unknown(Object error) {
    return AppNetworkException(
      type: NetworkErrorType.unknown,
      message: 'Error inesperado: $error',
    );
  }

  static AppNetworkException _fromStatusCode(
    int? statusCode,
    DioException error,
  ) {
    final serverMessage = _extractServerMessage(error.response?.data);

    if (statusCode == 400) {
      return AppNetworkException(
        type: NetworkErrorType.badRequest,
        message: serverMessage ?? 'Solicitud inválida.',
        statusCode: statusCode,
      );
    }
    if (statusCode == 401) {
      return AppNetworkException(
        type: NetworkErrorType.unauthorized,
        message: serverMessage ?? 'No autorizado.',
        statusCode: statusCode,
      );
    }
    if (statusCode == 403) {
      return AppNetworkException(
        type: NetworkErrorType.forbidden,
        message: serverMessage ?? 'Acceso denegado.',
        statusCode: statusCode,
      );
    }
    if (statusCode == 404) {
      return AppNetworkException(
        type: NetworkErrorType.notFound,
        message: serverMessage ?? 'Recurso no encontrado.',
        statusCode: statusCode,
      );
    }
    if (statusCode == 405) {
      return AppNetworkException(
        type: NetworkErrorType.methodNotAllowed,
        message:
            serverMessage ?? 'Método HTTP no permitido para este endpoint.',
        statusCode: statusCode,
      );
    }
    if (statusCode != null && statusCode >= 500) {
      return AppNetworkException(
        type: NetworkErrorType.server,
        message: serverMessage ?? 'Error interno del servidor.',
        statusCode: statusCode,
      );
    }

    return AppNetworkException(
      type: NetworkErrorType.unknown,
      message: serverMessage ?? 'Error de red no controlado. Intenta de nuevo.',
      statusCode: statusCode,
    );
  }

  static String? _extractServerMessage(dynamic data) {
    if (data == null) {
      return null;
    }
    if (data is String) {
      return data.isNotEmpty ? data : null;
    }
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
      final error = data['error'];
      if (error is String && error.isNotEmpty) {
        return error;
      }
      if (error is Map<String, dynamic>) {
        final nestedMessage = error['message'];
        if (nestedMessage is String && nestedMessage.isNotEmpty) {
          return nestedMessage;
        }
      }
    }
    return null;
  }
}
