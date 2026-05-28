import 'dart:async';

import 'package:dio/dio.dart';

class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration initialDelay;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 2,
    this.initialDelay = const Duration(milliseconds: 300),
  });

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final attempt = (request.extra['retry_attempt'] as int?) ?? 0;

    if (attempt >= maxRetries || !_shouldRetry(err)) {
      handler.next(err);
      return;
    }

    request.extra['retry_attempt'] = attempt + 1;

    final backoff = Duration(
      milliseconds: initialDelay.inMilliseconds * (attempt + 1),
    );

    await Future<void>.delayed(backoff);

    try {
      final response = await dio.fetch<dynamic>(request);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  bool _shouldRetry(DioException err) {
    final method = err.requestOptions.method.toUpperCase();
    final explicitlyRetryable = err.requestOptions.extra['retryable'] == true;
    final isIdempotent =
        method == 'GET' || method == 'HEAD' || method == 'OPTIONS';

    if (!isIdempotent && !explicitlyRetryable) {
      return false;
    }

    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      return true;
    }

    final statusCode = err.response?.statusCode;
    if (statusCode == 408) {
      return true;
    }
    if (statusCode != null && statusCode >= 500 && statusCode < 600) {
      return true;
    }
    return statusCode == 429 ||
        statusCode == 502 ||
        statusCode == 503 ||
        statusCode == 504;
  }
}
