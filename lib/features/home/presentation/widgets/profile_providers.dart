import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theoriginallab_v2/shared/providers/providers.dart';

// ── Datos extendidos del socio (numero_socio, nivel, estado, etc.) ────────────
// Endpoint: GET /api/socios/:id
final socioDetalleProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final authState = ref.watch(authProvider);
  final socioId = authState.maybeWhen(
    authenticated: (user) => user.id,
    orElse: () => null,
  );
  if (socioId == null) return {};

  final dio = ref.watch(authApiDioProvider);
  final response = await dio.get('/api/socios/$socioId');
  return Map<String, dynamic>.from(response.data['data'] ?? {});
});

// ── Beneficiarios del socio ───────────────────────────────────────────────────
// Endpoint: GET /api/socios/:id/beneficiarios
final beneficiariosProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final authState = ref.watch(authProvider);
  final socioId = authState.maybeWhen(
    authenticated: (user) => user.id,
    orElse: () => null,
  );
  if (socioId == null) return [];

  final dio = ref.watch(authApiDioProvider);
  final response = await dio.get('/api/socios/$socioId/beneficiarios');
  final List data = response.data['data'] ?? [];
  return data.map((e) => Map<String, dynamic>.from(e)).toList();
});

// ── Timestamp global para forzar recarga de foto de perfil ───────────────────
// Al escribir un nuevo valor aquí, todos los widgets que lo escuchen
// se reconstruyen y usan la URL con el timestamp actualizado,
// evitando el caché del sistema en todas las pantallas.
final profileImageTimestampProvider = StateProvider<int>((ref) => 0);
