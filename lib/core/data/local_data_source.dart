import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class LocalDataSource {
  Future<Map<String, dynamic>>? _cachedDataFuture;

  Future<Map<String, dynamic>> loadData() async {
    final cached = _cachedDataFuture;
    if (cached != null) return cached;

    final future = _loadAndParseData();
    _cachedDataFuture = future;
    return future;
  }

  Future<Map<String, dynamic>> _loadAndParseData() async {
    try {
      final String response = await rootBundle.loadString('assets/datos.json');
      final data = await json.decode(response);
      return data;
    } catch (e) {
      _cachedDataFuture = null;
      // Just rethrow or log, but ensure it's propagated so UI handles it.
      if (kDebugMode) {
        debugPrint('Error loading datos.json: $e');
      }
      throw Exception('Error loading local data: $e');
    }
  }

  // Helpers to get specific sections
  Future<List<dynamic>> getServices() async {
    final data = await loadData();
    return data['servicios'] ?? [];
  }

  Future<List<dynamic>> getSuccessStories() async {
    final data = await loadData();
    return data['casos_de_exito'] ?? [];
  }

  Future<List<dynamic>> getFeaturedProducts() async {
    final data = await loadData();
    // Assuming 'catalogo' inside 'productos'
    return data['productos']['catalogo'] ?? [];
  }

  Future<Map<String, dynamic>> getAboutUs() async {
    final data = await loadData();
    return data['quienes_somos'] ?? {};
  }

  Future<Map<String, dynamic>> getProducts() async {
    final data = await loadData();
    return data['productos'] ?? {};
  }

  Future<List<dynamic>> getIncubatedProjects() async {
    final data = await loadData();
    return data['proyectos_incubados'] ?? [];
  }

  Future<Map<String, dynamic>> getStatsAndContact() async {
    final data = await loadData();
    return data['estadisticas_y_contacto'] ?? {};
  }
}
