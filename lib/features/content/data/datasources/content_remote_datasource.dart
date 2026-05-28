import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/network_error_mapper.dart';
import '../models/slider_model.dart';
import '../models/item_model.dart';

abstract class ContentRemoteDataSource {
  Future<List<SliderModel>> fetchHomeSliders();
  Future<List<ItemModel>> fetchHomeItems();
  Future<List<SliderModel>> fetchCursos();
  Future<List<ItemModel>> fetchTarjetas();
  Future<List<SliderModel>> fetchSliderTienda();
}

class ContentRemoteDataSourceImpl implements ContentRemoteDataSource {
  final Dio dio;

  ContentRemoteDataSourceImpl(this.dio);

  Future<Map<String, dynamic>> _fetchHomeData() async {
    final response = await dio.get(
      ApiConstants.homeContent,
      options: Options(headers: ApiConstants.contentHeaders),
    );

    if (response.data is! Map<String, dynamic>) {
      throw ServerException('Invalid response format');
    }
    final body = response.data as Map<String, dynamic>;
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw ServerException('Missing data in /home response');
    }
    return data;
  }

  List<Map<String, dynamic>> _section(
    Map<String, dynamic> data,
    String key,
  ) {
    final raw = data[key];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
        .toList();
  }

  SliderModel _toSlider(Map<String, dynamic> item) {
    return SliderModel(
      image: (item['image_url'] ?? item['image'] ?? '').toString(),
      url: (item['cta_url'] ?? item['url'] ?? '').toString(),
    );
  }

  ItemModel _toItem(Map<String, dynamic> item) {
    return ItemModel(
      title: (item['title'] ?? item['titulo'] ?? 'Sin titulo').toString(),
      image: (item['image_url'] ?? item['image'] ?? '').toString(),
      url: (item['cta_url'] ?? item['url'] ?? '').toString(),
    );
  }

  @override
  Future<List<SliderModel>> fetchHomeSliders() async {
    try {
      final data = await _fetchHomeData();
      return _section(data, 'carousel').map(_toSlider).toList();
    } on DioException catch (e) {
      throw ServerException(
        NetworkErrorMapper.fromDioException(e).message,
      );
    } catch (e) {
      throw ServerException('Unexpected error loading sliders');
    }
  }

  @override
  Future<List<ItemModel>> fetchHomeItems() async {
    try {
      final data = await _fetchHomeData();
      return _section(data, 'featured').map(_toItem).toList();
    } on DioException catch (e) {
      throw ServerException(
        NetworkErrorMapper.fromDioException(e).message,
      );
    } catch (e) {
      throw ServerException('Unexpected error loading items');
    }
  }

  @override
  Future<List<SliderModel>> fetchCursos() async {
    try {
      final data = await _fetchHomeData();
      // Compatibilidad legacy: cursos consume slider-style cards.
      return _section(data, 'carousel').map(_toSlider).toList();
    } on DioException catch (e) {
      throw ServerException(NetworkErrorMapper.fromDioException(e).message);
    }
  }

  @override
  Future<List<ItemModel>> fetchTarjetas() async {
    try {
      final data = await _fetchHomeData();
      return _section(data, 'ads').map(_toItem).toList();
    } on DioException catch (e) {
      throw ServerException(NetworkErrorMapper.fromDioException(e).message);
    }
  }

  @override
  Future<List<SliderModel>> fetchSliderTienda() async {
    try {
      final data = await _fetchHomeData();
      return _section(data, 'ads_horizontal').map(_toSlider).toList();
    } on DioException catch (e) {
      throw ServerException(NetworkErrorMapper.fromDioException(e).message);
    }
  }
}
