import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:theoriginallab_v2/core/theme/app_colors.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';
import 'package:theoriginallab_v2/shared/providers/providers.dart';
import 'package:theoriginallab_v2/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:theoriginallab_v2/features/notifications/presentation/screens/notifications_screen.dart';

// ──────────────────────────────────────────────────────────────────────────────
// PROVIDERS
// ──────────────────────────────────────────────────────────────────────────────

final puntosProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final socioId = ref.watch(authProvider).maybeWhen(authenticated: (u) => u.id, orElse: () => null);
  if (socioId == null) return {};
  final r = await ref.watch(authApiDioProvider).get('/api/socios/$socioId/puntos');
  final data = Map<String, dynamic>.from(r.data['data'] ?? {});
  
  try {
    final statsR = await ref.watch(authApiDioProvider).get('/api/socios/$socioId/puntos/stats');
    data['stats'] = statsR.data['data'];
  } catch (e) {
    data['stats'] = {};
  }
  
  return data;
});

final nivelesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final r = await ref.watch(authApiDioProvider).get('/api/niveles');
  return (r.data['data'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
});

final recompensasProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final r = await ref.watch(authApiDioProvider).get('/api/recompensas');
  return (r.data['data'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
});

final canjesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final socioId = ref.watch(authProvider).maybeWhen(authenticated: (u) => u.id, orElse: () => null);
  if (socioId == null) return [];
  final r = await ref.watch(authApiDioProvider).get('/api/socios/$socioId/canjes');
  return (r.data['data'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
});

// Información de puntos desde el servidor (cómo ganar puntos)
final puntosInfoProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final r = await ref.watch(authApiDioProvider).get('/api/puntos/info');
  return Map<String, dynamic>.from(r.data['data'] ?? {});
});

// Provider específico para niveles (como respaldo)
final nivelesCompletoProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final r = await ref.watch(authApiDioProvider).get('/api/puntos/info');
  final data = Map<String, dynamic>.from(r.data['data'] ?? {});
  return (data['niveles'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
});
// Tipos de recompensa desde el servidor
final tiposRecompensaProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final r = await ref.watch(authApiDioProvider).get('/api/recompensas/tipos');
  return (r.data['data'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
});

// ──────────────────────────────────────────────────────────────────────────────
// PANTALLA PRINCIPAL
// ──────────────────────────────────────────────────────────────────────────────

class PuntosScreen extends ConsumerStatefulWidget {
  const PuntosScreen({super.key});
  
  @override
  ConsumerState<PuntosScreen> createState() => _PuntosScreenState();
}

class _PuntosScreenState extends ConsumerState<PuntosScreen> {
  bool _catalogoExpandido = false;
  bool _historialExpandido = false;

  Future<void> _refreshData() async {
    ref.invalidate(puntosProvider);
    ref.invalidate(nivelesProvider);
    ref.invalidate(recompensasProvider);
    ref.invalidate(canjesProvider);
    ref.invalidate(puntosInfoProvider);
    ref.invalidate(tiposRecompensaProvider);
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final puntosAsync = ref.watch(puntosProvider);
    final recompensasAsync = ref.watch(recompensasProvider);
    final puntosInfoAsync = ref.watch(puntosInfoProvider);
    final tiposRecompensaAsync = ref.watch(tiposRecompensaProvider);
    final socioId = ref.watch(authProvider)
        .maybeWhen(authenticated: (u) => u.id, orElse: () => '');

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      body: RefreshIndicator(
        color: AppColors.primaryNavy,
        onRefresh: _refreshData,
        child: CustomScrollView(
          slivers: [
            // HEADER
            SliverToBoxAdapter(
              child: puntosAsync.when(
                loading: () => _HeaderSkeleton(topPad: topPad),
                error: (_, __) => _HeaderSkeleton(topPad: topPad),
                data: (p) => _HeroHeader(
                  topPad: topPad,
                  puntosTotales: (p['puntos_totales'] as num?)?.toInt() ?? 0,
                  nivelActual: p['nivel_actual']?.toString() ?? 'Bronce',
                  nivelInfo: p['nivel_info'] as Map? ?? {},
                  puntosPorExpirar: (p['puntos_por_expirar'] as num?)?.toInt() ?? 0,
                  onVolver: () => Navigator.pop(context),
                ),
              ),
            ),

            // ESTADÍSTICAS
            SliverToBoxAdapter(
              child: puntosAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (p) {
                  final txs = (p['transacciones'] as List?)?.cast<Map>() ?? [];
                  final canjeados = txs
                      .where((t) => t['codigo_evento'] == 'CANJE_RECOMPENSA')
                      .fold<int>(0, (s, t) => s + ((t['puntos_otorgados'] as num?)?.toInt().abs() ?? 0));
                  final now = DateTime.now();
                  final esteMes = txs.where((t) {
                    final f = DateTime.tryParse(t['creado_en']?.toString() ?? '');
                    return f != null && f.year == now.year && f.month == now.month && (t['puntos_otorgados'] as num? ?? 0) > 0;
                  }).fold<int>(0, (s, t) => s + ((t['puntos_otorgados'] as num?)?.toInt() ?? 0));
                  
                  final stats = p['stats'] as Map? ?? {};
                  
                  return _EstadisticasRow(
                    disponibles: (p['puntos_totales'] as num?)?.toInt() ?? 0,
                    canjeados: canjeados,
                    esteMes: esteMes,
                    totalGanados: (stats['total_ganados'] as num?)?.toInt() ?? 0,
                  );
                },
              ).animate().fadeIn(duration: 300.ms),
            ),

            // CÓMO GANAR PUNTOS (desde el servidor)
            SliverToBoxAdapter(
              child: puntosInfoAsync.when(
                loading: () => const _ComoGanarSkeleton(),
                error: (_, __) => const _ComoGanarSkeleton(),
                data: (info) => _ComoGanarSection(info: info),
              ).animate().fadeIn(delay: 120.ms, duration: 300.ms),
            ),

            // CATÁLOGO DE BENEFICIOS (con tipos desde el servidor)
            SliverToBoxAdapter(
              child: tiposRecompensaAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (tipos) {
                  final Map<String, dynamic> tiposMap = {
                      for (var t in tipos) (t['codigo']?.toString() ?? ''): t,};
                  return recompensasAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (recompensas) {
                      final puntosTotales = puntosAsync.value?['puntos_totales'] as num? ?? 0;
                      return _CatalogoBeneficios(
                        recompensas: recompensas,
                        tiposMap: tiposMap,
                        puntosDisponibles: puntosTotales.toInt(),
                        socioId: socioId,
                        expandido: _catalogoExpandido,
                        onToggle: () => setState(() => _catalogoExpandido = !_catalogoExpandido),
                        onCanjeExitoso: _refreshData,
                      );
                    },
                  );
                },
              ),
            ),

            // NIVELES
            SliverToBoxAdapter(
              child: _NivelesSection(
                nivelActual: puntosAsync.value?['nivel_actual']?.toString() ?? 'Bronce',
                puntosActuales: puntosAsync.value?['puntos_totales'] as num? ?? 0,
              ),
            ),

            // ÚLTIMOS MOVIMIENTOS
            SliverToBoxAdapter(
              child: puntosAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (p) => _UltimosMovimientos(
                  transacciones: (p['transacciones'] as List?)?.cast<Map>() ?? [],
                  expandido: _historialExpandido,
                  onToggle: () => setState(() => _historialExpandido = !_historialExpandido),
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 300.ms),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// CÓMO GANAR PUNTOS - VERSIÓN DINÁMICA DESDE EL SERVIDOR
// ──────────────────────────────────────────────────────────────────────────────

class _ComoGanarSection extends StatefulWidget {
  final Map<String, dynamic> info;
  const _ComoGanarSection({required this.info});
  
  @override
  State<_ComoGanarSection> createState() => _ComoGanarSectionState();
}

class _ComoGanarSectionState extends State<_ComoGanarSection> {
  bool _expandido = false;

  @override
  Widget build(BuildContext context) {
    final formasDeGanar = (widget.info['formas_de_ganar'] as List? ?? [])
        .map((e) => _GanarItemDto.fromJson(e))
        .toList();
    
    final infoGeneral = widget.info['info_general'] as Map? ?? {};
    final nivelesInfo = (widget.info['niveles'] as List? ?? []);
    
    final visibles = _expandido ? formasDeGanar : formasDeGanar.take(3).toList();

    if (formasDeGanar.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Cómo ganar puntos',
                  style: AppTypography.titleSmall.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w700),
                ),
              ),
              GestureDetector(
                onTap: () => _mostrarInfo(context, infoGeneral, nivelesInfo),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primaryNavy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.help_outline_rounded, color: AppColors.primaryNavy, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        '¿Cómo funciona?',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.primaryNavy, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: [
                ...visibles.asMap().entries.map((e) => Column(
                  children: [
                    _ComoGanarTile(item: e.value),
                    if (e.key < visibles.length - 1) const Divider(height: 1, indent: 56, endIndent: 16),
                  ],
                )),
                if (formasDeGanar.length > 3) ...[
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  GestureDetector(
                    onTap: () => setState(() => _expandido = !_expandido),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _expandido ? 'Ver menos' : 'Ver ${formasDeGanar.length - 3} más',
                            style: AppTypography.labelSmall.copyWith(color: AppColors.primaryNavy, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _expandido ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            color: AppColors.primaryNavy,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarInfo(BuildContext context, Map infoGeneral, List nivelesInfo) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              infoGeneral['titulo'] ?? '¿Cómo funcionan los puntos?',
              style: AppTypography.titleSmall.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              infoGeneral['descripcion'] ?? 'Los puntos GENERA se acumulan con cada acción financiera.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.supportMedium),
            ),
            const SizedBox(height: 16),
            ...nivelesInfo.map((n) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Icon(
                    _getNivelIcon(n['nivel']),
                    color: _getColorFromHex(n['color']),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Nivel ${n['nivel']}',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _getColorFromHex(n['color']),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_formatPuntos(n['puntos_minimos'])}-${n['puntos_maximos'] >= 999999 ? '∞' : _formatPuntos(n['puntos_maximos'])} pts',
                    style: AppTypography.labelSmall.copyWith(color: AppColors.supportMedium),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _GanarItemDto {
  final String codigo;
  final String titulo;
  final String subtitulo;
  final int puntosBase;
  final int puntosBlack;
  final String detalle;
  final String icono;
  final String color;
  final int maxDiario;
  final bool tieneUnidad;
  final String? unidadTexto;

  _GanarItemDto({
    required this.codigo,
    required this.titulo,
    required this.subtitulo,
    required this.puntosBase,
    required this.puntosBlack,
    required this.detalle,
    required this.icono,
    required this.color,
    required this.maxDiario,
    required this.tieneUnidad,
    this.unidadTexto,
  });

  factory _GanarItemDto.fromJson(Map<String, dynamic> json) {
    return _GanarItemDto(
      codigo: json['codigo'] ?? '',
      titulo: json['titulo'] ?? '',
      subtitulo: json['subtitulo'] ?? '',
      puntosBase: (json['puntos_base'] as num?)?.toInt() ?? 0,
      puntosBlack: (json['puntos_black'] as num?)?.toInt() ?? 0,
      detalle: json['detalle'] ?? '',
      icono: json['icono'] ?? 'star',
      color: json['color'] ?? '#3498DB',
      maxDiario: (json['max_diario'] as num?)?.toInt() ?? 1,
      tieneUnidad: json['tiene_unidad'] ?? false,
      unidadTexto: json['unidad_texto'],
    );
  }

  String get puntosTexto {
    if (tieneUnidad && puntosBase == 0) return unidadTexto ?? 'Variable';
    if (puntosBase == puntosBlack) return '+$puntosBase pts';
    return '+$puntosBase pts / +$puntosBlack pts (Black)';
  }
}

class _ComoGanarTile extends StatefulWidget {
  final _GanarItemDto item;
  const _ComoGanarTile({required this.item});
  @override
  State<_ComoGanarTile> createState() => _ComoGanarTileState();
}

class _ComoGanarTileState extends State<_ComoGanarTile> {
  bool _expandido = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final color = _getColorFromHex(item.color);
    
    return GestureDetector(
      onTap: () => setState(() => _expandido = !_expandido),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: _expandido ? color.withValues(alpha: 0.04) : Colors.transparent,
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_getIconData(item.icono), color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.titulo,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        item.subtitulo,
                        style: AppTypography.labelSmall.copyWith(color: AppColors.supportMedium),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.puntosTexto,
                    style: AppTypography.labelSmall.copyWith(color: color, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  _expandido ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.supportMedium,
                  size: 18,
                ),
              ],
            ),
            if (_expandido) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.detalle,
                  style: AppTypography.labelSmall.copyWith(color: AppColors.textDark, height: 1.4),
                ),
              ),
              if (item.maxDiario > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Máximo ${item.maxDiario} veces por día',
                    style: AppTypography.labelSmall.copyWith(color: AppColors.supportMedium, fontSize: 10),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ComoGanarSkeleton extends StatelessWidget {
  const _ComoGanarSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 140, height: 20, color: Colors.grey.shade200),
          const SizedBox(height: 10),
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// HERO HEADER
// ──────────────────────────────────────────────────────────────────────────────

class _HeroHeader extends ConsumerWidget {
  final double topPad;
  final int puntosTotales;
  final String nivelActual;
  final Map nivelInfo;
  final int puntosPorExpirar;
  final VoidCallback onVolver;

  const _HeroHeader({
    required this.topPad,
    required this.puntosTotales,
    required this.nivelActual,
    required this.nivelInfo,
    required this.puntosPorExpirar,
    required this.onVolver,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);
    final ptsMax = (nivelInfo['puntos_maximos'] as num?)?.toInt() ?? 999;
    final ptsMin = (nivelInfo['puntos_minimos'] as num?)?.toInt() ?? 0;
    final progreso = ptsMax > ptsMin
        ? ((puntosTotales - ptsMin) / (ptsMax - ptsMin)).clamp(0.0, 1.0) : 1.0;
    const sig = {'Bronce': 'Plata', 'Plata': 'Oro', 'Oro': 'Black', 'Black': 'Black'};
    final nextNivel = sig[nivelActual] ?? 'Black';
    final ptsFaltantes = (ptsMax + 1 - puntosTotales).clamp(0, 999999);

    return Container(
      color: AppColors.primaryNavy,
      padding: EdgeInsets.fromLTRB(20, topPad + 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onVolver,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Mis puntos Genera',
                  style: AppTypography.bodySmall.copyWith(color: Colors.white70),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
                    ),
                    if (unread > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 18),
                          height: 18,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: AppColors.primaryNavy, width: 1.5),
                          ),
                          child: Center(
                            child: Text(
                              unread > 99 ? '99+' : '$unread',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatPuntos(puntosTotales),
                style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w800, height: 1.1),
              ),
              const SizedBox(width: 8),
              if (puntosPorExpirar > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_formatPuntos(puntosPorExpirar)} expiran pronto',
                    style: const TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.w500),
                  ),
                ),
            ],
          ),
          Text(
            'puntos acumulados',
            style: AppTypography.bodySmall.copyWith(color: Colors.white60),
          ),
          const SizedBox(height: 16),
          _NivelChip(nivel: nivelActual),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progreso,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(
                nivelActual == 'Black' ? const Color(0xFFFFD700) : AppColors.accentCyan,
              ),
              minHeight: 6,
            ),
          ),
          if (nivelActual != 'Black') ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$ptsFaltantes pts para $nextNivel',
                style: AppTypography.labelSmall.copyWith(color: Colors.white60, fontSize: 11),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NivelChip extends StatelessWidget {
  final String nivel;
  const _NivelChip({required this.nivel});

  @override
  Widget build(BuildContext context) {
    const c = {
      'Bronce': Color(0xFFCD7F32),
      'Plata': Color(0xFFB0BEC5),
      'Oro': Color(0xFFFFD700),
      'Black': Color(0xFF212121),
    };
    final color = c[nivel] ?? AppColors.accentCyan;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: color, size: 13),
          const SizedBox(width: 4),
          Text(
            'Nivel $nivel',
            style: AppTypography.labelSmall.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// ESTADÍSTICAS
// ──────────────────────────────────────────────────────────────────────────────

class _EstadisticasRow extends StatelessWidget {
  final int disponibles, canjeados, esteMes, totalGanados;
  const _EstadisticasRow({
    required this.disponibles,
    required this.canjeados,
    required this.esteMes,
    required this.totalGanados,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          _StatItem(valor: _formatPuntos(disponibles), etiqueta: 'Disponibles'),
          Container(width: 1, height: 32, color: const Color(0xFFEEF2F5)),
          _StatItem(valor: _formatPuntos(canjeados), etiqueta: 'Canjeados'),
          Container(width: 1, height: 32, color: const Color(0xFFEEF2F5)),
          _StatItem(
            valor: esteMes >= 0 ? '+${_formatPuntos(esteMes)}' : _formatPuntos(esteMes),
            etiqueta: 'Este mes',
            colorValor: esteMes >= 0 ? const Color(0xFF27AE60) : AppColors.error,
          ),
          if (totalGanados > 0) ...[
            Container(width: 1, height: 32, color: const Color(0xFFEEF2F5)),
            _StatItem(valor: _formatPuntos(totalGanados), etiqueta: 'Histórico'),
          ],
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String valor, etiqueta;
  final Color? colorValor;
  const _StatItem({required this.valor, required this.etiqueta, this.colorValor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            valor,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: colorValor ?? AppColors.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            etiqueta,
            style: AppTypography.labelSmall.copyWith(color: AppColors.supportMedium),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// CATÁLOGO DE BENEFICIOS - AHORA CON DATOS DEL SERVIDOR
// ──────────────────────────────────────────────────────────────────────────────

class _CatalogoBeneficios extends StatelessWidget {
  final List<Map<String, dynamic>> recompensas;
  final Map<String, dynamic> tiposMap;
  final int puntosDisponibles;
  final String socioId;
  final bool expandido;
  final VoidCallback onToggle;
  final VoidCallback? onCanjeExitoso;

  const _CatalogoBeneficios({
    required this.recompensas,
    required this.tiposMap,
    required this.puntosDisponibles,
    required this.socioId,
    required this.expandido,
    required this.onToggle,
    this.onCanjeExitoso,
  });

  @override
  Widget build(BuildContext context) {
    if (recompensas.isEmpty) return const SizedBox.shrink();
    final visibles = expandido ? recompensas : recompensas.take(4).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Catálogo de beneficios',
                style: AppTypography.titleSmall.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w700),
              ),
              GestureDetector(
                onTap: onToggle,
                child: Row(
                  children: [
                    Text(
                      expandido ? 'Ver menos' : 'Ver todo',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.primaryNavy, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      expandido ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primaryNavy,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: visibles.map((r) {
              final costo = (r['costo_puntos'] as num?)?.toInt() ?? 0;
              final tipoCodigo = r['tipo_recompensa']?.toString() ?? '';
              final tipoConfig = tiposMap[tipoCodigo] as Map?;
              
              return SizedBox(
                width: (MediaQuery.of(context).size.width - 42) / 2,
                child: _RecompensaCard(
                  recompensa: r,
                  tipoConfig: tipoConfig,
                  tienePoints: puntosDisponibles >= costo,
                  onCanjear: () => showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (_) => _CanjeBottomSheet(
                      recompensa: r,
                      socioId: socioId,
                      onCanjeExitoso: onCanjeExitoso,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _RecompensaCard extends StatelessWidget {
  final Map recompensa;
  final Map? tipoConfig;
  final bool tienePoints;
  final VoidCallback onCanjear;

  const _RecompensaCard({
    required this.recompensa,
    required this.tipoConfig,
    required this.tienePoints,
    required this.onCanjear,
  });

  @override
  Widget build(BuildContext context) {
    final costo = (recompensa['costo_puntos'] as num?)?.toInt() ?? 0;
    final nombre = recompensa['nombre']?.toString() ?? '';
    
    // Valores desde el servidor o defaults
    final icono = _getIconDataFromTipo(tipoConfig?['icono'] ?? 'star_outline_rounded');
    final color = _getColorFromHex(tipoConfig?['color'] ?? '#E67E22');
    final label = tipoConfig?['label'] ?? 'Beneficio';

    return GestureDetector(
      onTap: tienePoints ? onCanjear : null,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: tienePoints ? color.withValues(alpha: 0.3) : const Color(0xFFEEF2F5),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: Icon(icono, color: color, size: 26)),
            ),
            const SizedBox(height: 8),
            Text(
              nombre,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                Text(
                  '$costo pts',
                  style: AppTypography.labelSmall.copyWith(color: AppColors.primaryNavy, fontWeight: FontWeight.w700),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            if (!tienePoints) ...[
              const SizedBox(height: 4),
              Text(
                'Puntos insuficientes',
                style: AppTypography.labelSmall.copyWith(color: AppColors.supportMedium, fontSize: 9),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// CANJE BOTTOM SHEET
// ──────────────────────────────────────────────────────────────────────────────

class _CanjeBottomSheet extends ConsumerStatefulWidget {
  final Map recompensa;
  final String socioId;
  final VoidCallback? onCanjeExitoso;

  const _CanjeBottomSheet({
    required this.recompensa,
    required this.socioId,
    this.onCanjeExitoso,
  });

  @override
  ConsumerState<_CanjeBottomSheet> createState() => _CanjeBottomSheetState();
}

class _CanjeBottomSheetState extends ConsumerState<_CanjeBottomSheet> {
  bool _loading = false;
  bool _exito = false;

  Future<void> _canjear() async {
    setState(() => _loading = true);
    try {
      await ref.read(authApiDioProvider).post(
        '/api/recompensas/${widget.recompensa['id']}/canjear',
        data: {'socio_id': widget.socioId},
      );
      setState(() {
        _loading = false;
        _exito = true;
      });
      
      ref.invalidate(puntosProvider);
      ref.invalidate(recompensasProvider);
      ref.invalidate(canjesProvider);
      ref.invalidate(puntosInfoProvider);
      ref.invalidate(tiposRecompensaProvider);
      widget.onCanjeExitoso?.call();
      
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al realizar el canje: ${e.toString()}')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final costo = (widget.recompensa['costo_puntos'] as num?)?.toInt() ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFDDE3EC),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (_exito)
            Column(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF27AE60), size: 48),
                const SizedBox(height: 12),
                Text(
                  '¡Canje exitoso!',
                  style: AppTypography.titleMedium.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w700),
                ),
              ],
            )
          else ...[
            Text(
              widget.recompensa['nombre']?.toString() ?? '',
              style: AppTypography.titleMedium.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.recompensa['descripcion']?.toString() ?? '',
              style: AppTypography.bodySmall.copyWith(color: AppColors.supportMedium),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.stars_rounded, color: Color(0xFFFFD700), size: 20),
                const SizedBox(width: 6),
                Text(
                  '$costo puntos',
                  style: AppTypography.titleSmall.copyWith(color: AppColors.primaryNavy, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _canjear,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Confirmar canje', style: AppTypography.labelLarge.copyWith(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar', style: AppTypography.labelLarge.copyWith(color: AppColors.supportMedium)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// NIVELES
// ──────────────────────────────────────────────────────────────────────────────

class _NivelesSection extends ConsumerWidget {
  final String nivelActual;
  final num puntosActuales;

  const _NivelesSection({
    required this.nivelActual,
    required this.puntosActuales,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nivelesAsync = ref.watch(nivelesCompletoProvider);
    
    return nivelesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (niveles) {
        if (niveles.isEmpty) return const SizedBox.shrink();
        
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Niveles',
                style: AppTypography.titleSmall.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: niveles.map((n) => SizedBox(
                  width: (MediaQuery.of(context).size.width - 42) / 2,
                  child: _NivelCard(
                    nivel: n,
                    esActual: n['nivel']?.toString() == nivelActual,
                    puntosActuales: puntosActuales,
                    niveles: niveles,
                  ),
                )).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NivelCard extends StatelessWidget {
  final Map<String, dynamic> nivel;
  final bool esActual;
  final num puntosActuales;
  final List<Map<String, dynamic>> niveles;

  const _NivelCard({
    required this.nivel,
    required this.esActual,
    required this.puntosActuales,
    required this.niveles,
  });

  @override
  Widget build(BuildContext context) {
    final nombre = nivel['nivel']?.toString() ?? '';
    final ptsMin = (nivel['puntos_minimos'] as num?)?.toInt() ?? 0;
    final ptsMax = (nivel['puntos_maximos'] as num?)?.toInt() ?? 999;
    
    // Colores desde el servidor
    final colorPrincipal = _getColorFromHex(nivel['color'] ?? '#154284');
    final colorSecundario = _getColorFromHex(nivel['color_secundario'] ?? '#EEF2F5');
    
    // Beneficio UI desde el servidor
    final beneficioUI = nivel['beneficio_ui']?.toString() ?? 
        (nombre == 'Black' ? 'Beneficios VIP + 3x puntos' :
         nombre == 'Oro' ? '2x puntos + tasas preferenciales' :
         nombre == 'Plata' ? '1.5x puntos + descuentos' :
         'Acceso básico a la red');
    
    // Calcular progreso hacia este nivel
    double progreso = 0;
    if (!esActual && ptsMin > puntosActuales) {
      final nivelAnteriorPts = _getPuntosNivelAnterior(nombre);
      if (ptsMin > nivelAnteriorPts) {
        progreso = ((puntosActuales - nivelAnteriorPts) / (ptsMin - nivelAnteriorPts))
            .clamp(0.0, 1.0)
            .toDouble();
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: esActual ? colorSecundario : colorSecundario.withValues(alpha: 0.3),
          width: esActual ? 2 : 1,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getNivelIcon(nombre), color: colorPrincipal, size: 28),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  nombre,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w700),
                ),
              ),
              if (esActual)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorPrincipal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Actual',
                    style: TextStyle(color: colorPrincipal, fontSize: 9, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            ptsMax >= 999999 ? '${_formatPuntos(ptsMin)}+ pts' : '${_formatPuntos(ptsMin)}-${_formatPuntos(ptsMax)} pts',
            style: AppTypography.labelSmall.copyWith(color: AppColors.supportMedium, fontSize: 10),
          ),
          const SizedBox(height: 2),
          Text(
            beneficioUI,
            style: AppTypography.labelSmall.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 11),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (!esActual && progreso > 0 && progreso < 1) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progreso,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(colorPrincipal),
                minHeight: 3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${((progreso * 100)).toInt()}% para alcanzar',
              style: AppTypography.labelSmall.copyWith(color: AppColors.supportMedium, fontSize: 8),
            ),
          ],
        ],
      ),
    );
  }

  int _getPuntosNivelAnterior(String nombreActual) {
    // Encontrar el índice del nivel actual en la lista
    final orden = ['Bronce', 'Plata', 'Oro', 'Black'];
    final idx = orden.indexOf(nombreActual);
    if (idx <= 0) return 0;
    
    // Buscar el nivel anterior en la lista de niveles del servidor
    final nivelAnterior = niveles.firstWhere(
      (n) => n['nivel'] == orden[idx - 1],
      orElse: () => {},
    );
    
    return (nivelAnterior['puntos_minimos'] as num?)?.toInt() ?? 0;
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// ÚLTIMOS MOVIMIENTOS
// ──────────────────────────────────────────────────────────────────────────────

class _UltimosMovimientos extends StatelessWidget {
  final List<Map> transacciones;
  final bool expandido;
  final VoidCallback onToggle;

  const _UltimosMovimientos({
    required this.transacciones,
    required this.expandido,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (transacciones.isEmpty) return const SizedBox.shrink();
    final todas = transacciones.reversed.toList();
    final visibles = expandido ? todas : todas.take(4).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Últimos movimientos',
                style: AppTypography.titleSmall.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w700),
              ),
              GestureDetector(
                onTap: onToggle,
                child: Row(
                  children: [
                    Text(
                      expandido ? 'Ocultar' : 'Ver historial',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.primaryNavy, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      expandido ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primaryNavy,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: visibles.asMap().entries.map((e) => Column(
                children: [
                  _MovimientoTile(transaccion: e.value).animate().fadeIn(delay: Duration(milliseconds: e.key * 40)),
                  if (e.key < visibles.length - 1) const Divider(height: 1, indent: 56, endIndent: 16),
                ],
              )).toList(),
            ),
          ),
          if (!expandido && todas.length > 4) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                '+ ${todas.length - 4} movimientos más',
                style: AppTypography.labelSmall.copyWith(color: AppColors.supportMedium),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MovimientoTile extends StatelessWidget {
  final Map transaccion;
  const _MovimientoTile({required this.transaccion});

  @override
  Widget build(BuildContext context) {
    final evento = transaccion['codigo_evento']?.toString() ?? '';
    final puntos = (transaccion['puntos_otorgados'] as num?)?.toInt() ?? 0;
    final fecha = DateTime.tryParse(transaccion['creado_en']?.toString() ?? '') ?? DateTime.now();

    const cfgs = {
      'PAGO_CREDITO_PUNTUAL': _EC(t: 'Pago de crédito', i: Icons.credit_card_outlined, c: Color(0xFF2E86C1)),
      'LOGIN_DIARIO': _EC(t: 'Inicio de sesión', i: Icons.login_rounded, c: Color(0xFF27AE60)),
      'APERTURA_INVERSION': _EC(t: 'Apertura de inversión', i: Icons.trending_up_rounded, c: Color(0xFF1ABC9C)),
      'REFERIDO_NUEVO_SOCIO': _EC(t: 'Referido registrado', i: Icons.person_add_outlined, c: Color(0xFF8E44AD)),
      'CANJE_RECOMPENSA': _EC(t: 'Canje de recompensa', i: Icons.redeem_outlined, c: AppColors.error),
      'COMPLETAR_PERFIL': _EC(t: 'Perfil completado', i: Icons.assignment_outlined, c: Color(0xFF9B59B6)),
      'DEPOSITO_AHORRO': _EC(t: 'Depósito de ahorro', i: Icons.savings_outlined, c: Color(0xFF1ABC9C)),
      'PUNTOS_EXPIRADOS': _EC(t: 'Puntos expirados', i: Icons.timer_outlined, c: Colors.orange),
    };
    final cfg = cfgs[evento] ?? const _EC(t: 'Movimiento', i: Icons.stars_outlined, c: AppColors.primaryNavy);
    final esPos = puntos >= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(color: cfg.c, shape: BoxShape.circle),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cfg.c.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(cfg.i, color: cfg.c, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cfg.t,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w600),
                ),
                Text(
                  _fmtFecha(fecha),
                  style: AppTypography.labelSmall.copyWith(color: AppColors.supportMedium),
                ),
              ],
            ),
          ),
          Text(
            '${esPos ? '+' : ''}$puntos',
            style: AppTypography.bodySmall.copyWith(
              color: esPos ? const Color(0xFF27AE60) : AppColors.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _fmtFecha(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays == 0) return 'Hoy, ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    if (diff.inDays == 1) return 'Ayer, ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    const m = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }
}

class _EC {
  final String t;
  final IconData i;
  final Color c;
  const _EC({required this.t, required this.i, required this.c});
}

// ──────────────────────────────────────────────────────────────────────────────
// SKELETON
// ──────────────────────────────────────────────────────────────────────────────

class _HeaderSkeleton extends StatelessWidget {
  final double topPad;
  const _HeaderSkeleton({required this.topPad});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryNavy,
      padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 140, height: 14, color: Colors.white24),
          const SizedBox(height: 8),
          Container(width: 200, height: 48, color: Colors.white24)
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 1200.ms, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 8),
          Container(width: 100, height: 12, color: Colors.white24),
          const SizedBox(height: 16),
          Container(
            width: 120,
            height: 26,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            height: 6,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// UTILIDADES
// ──────────────────────────────────────────────────────────────────────────────

String _formatPuntos(int puntos) {
  final abs = puntos.abs();
  final s = abs.toString();
  final buf = StringBuffer();
  int cnt = 0;
  for (int i = s.length - 1; i >= 0; i--) {
    if (cnt > 0 && cnt % 3 == 0) buf.write(',');
    buf.write(s[i]);
    cnt++;
  }
  final fmt = buf.toString().split('').reversed.join();
  return puntos < 0 ? '-$fmt' : fmt;
}

IconData _getIconData(String icono) {
  switch (icono) {
    case 'login': return Icons.login_rounded;
    case 'credit_card': return Icons.credit_card_outlined;
    case 'trending_up': return Icons.trending_up_rounded;
    case 'person_add': return Icons.person_add_outlined;
    case 'assignment': return Icons.assignment_outlined;
    case 'savings': return Icons.savings_outlined;
    default: return Icons.star_outlined;
  }
}

IconData _getIconDataFromTipo(String icono) {
  switch (icono) {
    case 'local_offer_outlined': return Icons.local_offer_outlined;
    case 'redeem_outlined': return Icons.redeem_outlined;
    case 'account_balance_outlined': return Icons.account_balance_outlined;
    case 'star_outline_rounded': return Icons.star_outline_rounded;
    default: return Icons.star_outline_rounded;
  }
}

Color _getColorFromHex(String hexColor) {
  hexColor = hexColor.toUpperCase().replaceAll('#', '');
  if (hexColor.length == 6) {
    hexColor = 'FF$hexColor';
  }
  return Color(int.parse(hexColor, radix: 16));
}

IconData _getNivelIcon(String nivel) {
  switch (nivel) {
    case 'Bronce': return Icons.emoji_events_outlined;
    case 'Plata': return Icons.workspace_premium_outlined;
    case 'Oro': return Icons.emoji_events_rounded;
    case 'Black': return Icons.stars_rounded;
    default: return Icons.star_outline;
  }
}