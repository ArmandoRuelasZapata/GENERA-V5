import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:theoriginallab_v2/features/store/data/repositories/api_products_repository.dart';
import 'package:dio/dio.dart';
import 'product_api_error_test.mocks.dart'; // Reuse the Dio mock

void main() {
  group('API Misuse - Rate Limiting', () {
    late ApiProductsRepository repository;
    late MockDio mockDio;

    setUp(() {
      mockDio = MockDio();
      repository = ApiProductsRepository(dio: mockDio);
    });

    test('Should handle rapid repeated calls (Manual Debounce Check)',
        () async {
      // Note: Actual debounce logic usually lives in the Bloc/Provider, not Repository.
      // However, we can test Repository resilience to ensure it doesn't crash on race conditions.

      when(mockDio.get(any)).thenAnswer((_) async {
        await Future.delayed(
            const Duration(milliseconds: 50)); // Simulate net latency
        return Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
            data: {
              'success': true,
              'data': {'products': []}
            });
      });

      // Act: Spam the API 10 times instantly
      final futures = List.generate(10, (_) => repository.getProducts());

      // Wait for all
      final results = await Future.wait(futures);

      // Assert: None should fail/throw exception
      for (final result in results) {
        expect(result.isRight(), true);
      }

      // Verify all 10 calls went through (Repository is stateless, so it forwards all).
      // This confirms the *Repository* doesn't break.
      // A UI-layer test would verify only 1 call is made (Debouncing).
      verify(mockDio.get(any)).called(10);
    });
  });
}
