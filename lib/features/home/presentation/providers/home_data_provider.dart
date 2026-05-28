import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theoriginallab_v2/core/data/local_data_source.dart';
import 'package:theoriginallab_v2/core/constants/api_constants.dart';
import 'package:theoriginallab_v2/shared/providers/providers.dart';

part 'home_data_provider.g.dart';

@riverpod
LocalDataSource localDataSource(Ref ref) {
  return LocalDataSource();
}

final homeRemoteContentProvider = FutureProvider<Map<String, List<dynamic>>>((
  ref,
) async {
  final dio = ref.watch(contentApiDioProvider);
  Response<dynamic>? response;
  DioException? lastDioError;

  for (final endpoint in ApiConstants.homeContentCandidates) {
    try {
      response = await dio.get(endpoint);
      break;
    } on DioException catch (e) {
      lastDioError = e;
      final statusCode = e.response?.statusCode;
      final shouldTryNext =
          statusCode == 404 || statusCode == 405 || statusCode == 502;
      if (!shouldTryNext) {
        rethrow;
      }
    }
  }

  if (response == null) {
    if (lastDioError != null) {
      throw lastDioError;
    }
    throw const FormatException('Unable to fetch home content.');
  }

  if (response.data is! Map<String, dynamic>) {
    throw const FormatException('Invalid /home response');
  }

  final body = response.data as Map<String, dynamic>;
  final data = body['data'];
  if (data is! Map<String, dynamic>) {
    throw const FormatException('Missing data in /home response');
  }

  List<dynamic> section(String key) {
    final value = data[key];
    if (value is List) return value;
    return const [];
  }

  Map<String, dynamic> toAppCarousel(dynamic raw) {
    final item = raw is Map<String, dynamic>
        ? raw
        : Map<String, dynamic>.from(raw as Map);
    return {
      'titulo': item['title'] ?? '',
      'descripcion': item['description'] ?? '',
      'url': item['cta_url'] ?? '',
      'image_url': item['image_url'] ?? '',
      'badge': item['badge'] ?? '',
    };
  }

  Map<String, dynamic> toAppFeatured(dynamic raw) {
    final item = raw is Map<String, dynamic>
        ? raw
        : Map<String, dynamic>.from(raw as Map);
    return {
      'nombre': item['title'] ?? '',
      'descripcion': item['description'] ?? '',
      'url': item['cta_url'] ?? '',
      'image_url': item['image_url'] ?? '',
      'badge': item['badge'] ?? '',
    };
  }

  Map<String, dynamic> toAppSuccessStory(dynamic raw) {
    final item = raw is Map<String, dynamic>
        ? raw
        : Map<String, dynamic>.from(raw as Map);
    final extra = item['extra'] is Map<String, dynamic>
        ? item['extra'] as Map<String, dynamic>
        : item['extra'] is Map
            ? Map<String, dynamic>.from(item['extra'] as Map)
            : <String, dynamic>{};
    final rawData = extra['raw'] is Map<String, dynamic>
        ? extra['raw'] as Map<String, dynamic>
        : extra['raw'] is Map
            ? Map<String, dynamic>.from(extra['raw'] as Map)
            : <String, dynamic>{};

    final subtitle = (item['subtitle'] ?? '').toString().trim().isNotEmpty
        ? item['subtitle']
        : rawData['subtitulo'] ?? rawData['lema'] ?? rawData['entidad'] ?? '';

    return {
      'titulo': item['title'] ?? '',
      'subtitulo': subtitle,
      'descripcion': item['description'] ?? '',
      'url': item['cta_url'] ?? '',
      'image_url': item['image_url'] ?? '',
      'badge': item['badge'] ?? '',
    };
  }

  Map<String, dynamic> toAppAd(dynamic raw) {
    final item = raw is Map<String, dynamic>
        ? raw
        : Map<String, dynamic>.from(raw as Map);
    final extra = item['extra'] is Map<String, dynamic>
        ? item['extra'] as Map<String, dynamic>
        : item['extra'] is Map
            ? Map<String, dynamic>.from(item['extra'] as Map)
            : <String, dynamic>{};

    final displayType = _resolveAdDisplayType(
      rawDisplayType: item['display_type'],
      extra: extra,
    );

    return {
      'titulo': item['title'] ?? 'Publicidad',
      'descripcion': item['description'] ?? '',
      'url': item['cta_url'] ?? '',
      'image_url': item['image_url'] ?? '',
      'badge': item['badge'] ?? '',
      'ad_type': displayType,
      'extra': extra,
    };
  }

  Map<String, dynamic> toHorizontalAd(dynamic raw) {
    final item = raw is Map<String, dynamic>
        ? raw
        : Map<String, dynamic>.from(raw as Map);
    return {
      'image_url': item['image_url'] ?? '',
      'url': item['url'] ?? item['cta_url'] ?? '',
    };
  }

  return {
    'carousel': section('carousel').map(toAppCarousel).toList(),
    'featured': section('featured').map(toAppFeatured).toList(),
    'success_stories':
        section('success_stories').map(toAppSuccessStory).toList(),
    'ads': section('ads').map(toAppAd).toList(),
    'ads_horizontal': section('ads_horizontal').map(toHorizontalAd).toList(),
  };
});

@riverpod
Future<List<dynamic>> homeServices(Ref ref) async {
  try {
    final remote = await ref.watch(homeRemoteContentProvider.future);
    final items = remote['carousel'] ?? const [];
    if (items.isNotEmpty) return items;
  } on DioException {
    // Fallback to local content
  } catch (_) {}

  final local = ref.watch(localDataSourceProvider);
  return local.getServices();
}

@riverpod
Future<List<dynamic>> homeFeaturedProducts(Ref ref) async {
  try {
    final remote = await ref.watch(homeRemoteContentProvider.future);
    final items = remote['featured'] ?? const [];
    if (items.isNotEmpty) return items.take(4).toList();
  } on DioException {
    // Fallback to local content
  } catch (_) {}

  final local = ref.watch(localDataSourceProvider);
  return local.getFeaturedProducts();
}

@riverpod
Future<List<dynamic>> homeSuccessStories(Ref ref) async {
  try {
    final remote = await ref.watch(homeRemoteContentProvider.future);
    final items = remote['success_stories'] ?? const [];
    if (items.isNotEmpty) return items;
  } on DioException {
    // Fallback to local content
  } catch (_) {}

  final local = ref.watch(localDataSourceProvider);
  return local.getSuccessStories();
}

@riverpod
Future<Map<String, dynamic>> homeAboutUs(Ref ref) async {
  final dataSource = ref.watch(localDataSourceProvider);
  return dataSource.getAboutUs();
}

@riverpod
Future<Map<String, dynamic>> homeProducts(Ref ref) async {
  final dataSource = ref.watch(localDataSourceProvider);
  return dataSource.getProducts();
}

@riverpod
Future<List<dynamic>> homeIncubatedProjects(Ref ref) async {
  final dataSource = ref.watch(localDataSourceProvider);
  return dataSource.getIncubatedProjects();
}

@riverpod
Future<Map<String, dynamic>> homeStatsAndContact(Ref ref) async {
  final dataSource = ref.watch(localDataSourceProvider);
  return dataSource.getStatsAndContact();
}

final homeAdsProvider = FutureProvider<List<dynamic>>((ref) async {
  try {
    final remote = await ref.watch(homeRemoteContentProvider.future);
    return remote['ads'] ?? const [];
  } on DioException {
    return const [];
  } catch (_) {
    return const [];
  }
});

final homeHorizontalAdsProvider = FutureProvider<List<dynamic>>((ref) async {
  try {
    final remote = await ref.watch(homeRemoteContentProvider.future);
    final items = remote['ads_horizontal'] ?? const [];
    if (items.isNotEmpty) return items;

    final ads = remote['ads'] ?? const [];
    return ads
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((ad) => (ad['ad_type'] ?? 'banner') == 'banner')
        .map((ad) => {
              'image_url': ad['image_url'] ?? '',
              'url': ad['url'] ?? '',
            })
        .toList();
  } on DioException {
    return const [];
  } catch (_) {
    return const [];
  }
});

String _resolveAdDisplayType({
  required dynamic rawDisplayType,
  required Map<String, dynamic> extra,
}) {
  final normalizedDisplayType =
      (rawDisplayType ?? '').toString().toLowerCase().trim();
  if (normalizedDisplayType == 'banner' ||
      normalizedDisplayType == 'horizontal' ||
      normalizedDisplayType == 'carousel') {
    return 'banner';
  }
  if (normalizedDisplayType == 'item' ||
      normalizedDisplayType == 'square' ||
      normalizedDisplayType == 'card') {
    return 'item';
  }

  final rawType = (extra['display_type'] ?? '').toString().toLowerCase().trim();
  if (rawType == 'banner' || rawType == 'horizontal' || rawType == 'carousel') {
    return 'banner';
  }
  if (rawType == 'item' || rawType == 'square' || rawType == 'card') {
    return 'item';
  }

  final source = (extra['source'] ?? '').toString().toLowerCase().trim();
  if (source == 'slidertienda' || source == 'slider') {
    return 'banner';
  }
  if (source == 'tarjeta' || source == 'item') {
    return 'item';
  }

  return 'banner';
}
