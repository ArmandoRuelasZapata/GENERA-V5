import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theoriginallab_v2/shared/providers/providers.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/products_repository.dart';

final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  return ref.watch(productsRepositoryDiProvider);
});

final productsProvider = FutureProvider<List<Product>>((ref) async {
  final repository = ref.watch(productsRepositoryProvider);
  final result = await repository.getProducts();

  return result.fold(
    (error) => throw Exception(error),
    (products) => products,
  );
});

final storeSearchQueryProvider = StateProvider<String>((ref) => '');
