enum NetworkErrorType {
  network,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  methodNotAllowed,
  server,
  badRequest,
  unknown,
}

class AppNetworkException implements Exception {
  final NetworkErrorType type;
  final String message;
  final int? statusCode;

  const AppNetworkException({
    required this.type,
    required this.message,
    this.statusCode,
  });

  @override
  String toString() =>
      'AppNetworkException(type: $type, statusCode: $statusCode, message: $message)';
}
