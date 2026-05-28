import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';
import 'package:mockito/annotations.dart';
import 'package:theoriginallab_v2/features/store/data/repositories/api_products_repository.dart';

// Generate a MockDio class
@GenerateMocks([Dio])
import 'product_api_error_test.mocks.dart';

void main() {
  group('API Misuse & Resilience', () {
    late ApiProductsRepository repository;
    late MockDio mockDio;

    setUp(() {
      mockDio = MockDio();
      repository = ApiProductsRepository(dio: mockDio);
    });

    test('Should handle 500 Server Error gracefully', () async {
      // Arrange
      when(mockDio.get(any)).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 500,
            statusMessage: 'Internal Server Error',
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      // Act
      final result = await repository.getProducts();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (error) => expect(error, contains('Error interno del servidor.')),
        (r) => fail('Should have returned Left for 500 error'),
      );
    });
  });
}
