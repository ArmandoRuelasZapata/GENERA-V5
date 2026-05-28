import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:theoriginallab_v2/core/network/network_error_mapper.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/products_repository.dart';

class ApiProductsRepository implements ProductsRepository {
  final Dio _dio;

  ApiProductsRepository({required Dio dio}) : _dio = dio;

  @override
  Future<Either<String, List<Product>>> getProducts() async {
    try {
      final response = await _dio.get('/api/products');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> rawProducts = response.data['data']['products'];

        final products = rawProducts.map((json) {
          final priceData = json['price'] ?? {};
          final categories = json['categories'] as List<dynamic>? ?? [];
          final categoryName =
              categories.isNotEmpty ? categories[0]['name'] : 'General';

          // Handle dynamic number types safely
          final priceAmount = priceData['amount'];
          final double price = (priceAmount is int)
              ? priceAmount.toDouble()
              : (priceAmount is double ? priceAmount : 0.0);

          return Product(
            id: json['id'] ?? '',
            title: json['title'] ?? 'Producto sin nombre',
            description: json['description'] ?? '',
            price: price,
            currency: priceData['currency'] ?? 'USD',
            category: categoryName.toString(),
            productUrl: json['url_product'] ?? '',
            imageUrl: (json['images'] as List<dynamic>?)?.isNotEmpty == true
                ? json['images'][0] as String
                : '',
          );
        }).toList();

        return Right(products);
      } else {
        return Left('Error del servidor: ${response.statusCode}');
      }
    } on DioException catch (e) {
      return Left(NetworkErrorMapper.fromDioException(e).message);
    } catch (e) {
      return Left(NetworkErrorMapper.unknown(e).message);
    }
  }
}
