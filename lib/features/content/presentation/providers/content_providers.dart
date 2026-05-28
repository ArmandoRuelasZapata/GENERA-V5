import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/slider_model.dart';
import '../../data/models/item_model.dart';
import '../../../../shared/providers/providers.dart';

// FutureProvider for Home Sliders
final homeSlidersProvider = FutureProvider<List<SliderModel>>((ref) async {
  final dataSource = ref.read(contentRemoteDataSourceProvider);
  return dataSource.fetchHomeSliders();
});

// FutureProvider for Home Items
final homeItemsProvider = FutureProvider<List<ItemModel>>((ref) async {
  final dataSource = ref.read(contentRemoteDataSourceProvider);
  return dataSource.fetchHomeItems();
});

// FutureProvider for Cursos
final cursosProvider = FutureProvider<List<SliderModel>>((ref) async {
  final dataSource = ref.read(contentRemoteDataSourceProvider);
  return dataSource.fetchCursos();
});

// FutureProvider for Tarjetas (Store)
final tarjetasProvider = FutureProvider<List<ItemModel>>((ref) async {
  final dataSource = ref.read(contentRemoteDataSourceProvider);
  return dataSource.fetchTarjetas();
});

// FutureProvider for Slider Tienda
final sliderTiendaProvider = FutureProvider<List<SliderModel>>((ref) async {
  final dataSource = ref.read(contentRemoteDataSourceProvider);
  return dataSource.fetchSliderTienda();
});
