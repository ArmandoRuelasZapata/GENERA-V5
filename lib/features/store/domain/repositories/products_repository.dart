import 'package:dartz/dartz.dart';
import '../entities/product.dart';

abstract class ProductsRepository {
  Future<Either<String, List<Product>>> getProducts();
}
