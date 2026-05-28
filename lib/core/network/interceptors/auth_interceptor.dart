import 'package:dio/dio.dart';

typedef AuthTokenReader = Future<String?> Function();

class AuthInterceptor extends Interceptor {
  final AuthTokenReader readToken;

  AuthInterceptor({required this.readToken});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final skipAuth = options.extra['skipAuth'] == true;
    final alreadyHasAuthHeader = options.headers.containsKey('Authorization');

    if (!skipAuth && !alreadyHasAuthHeader) {
      final token = await readToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }
}
