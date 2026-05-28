import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:theoriginallab_v2/core/theme/app_colors.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';
import 'package:theoriginallab_v2/shared/providers/providers.dart';
import 'package:theoriginallab_v2/features/home/presentation/providers/navigation_provider.dart';
import 'package:theoriginallab_v2/features/home/presentation/widgets/profile_providers.dart';
import 'package:theoriginallab_v2/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:theoriginallab_v2/features/notifications/presentation/screens/notifications_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// PROVIDERS LOCALES
// ═══════════════════════════════════════════════════════════════════════════════

// Resumen financiero del socio para el home
final _resumenFinancieroProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final authState = ref.watch(authProvider);
  final socioId = authState.maybeWhen(
    authenticated: (user) => user.id,
    orElse: () => null,
  );
  if (socioId == null) return {};

  final dio = ref.watch(authApiDioProvider);

  // Llamadas en paralelo
  final results = await Future.wait([
    dio.get('/api/socios/$socioId/cuentas'),
    dio.get('/api/socios/$socioId/creditos'),
    dio.get('/api/socios/$socioId/inversiones'),
  ]);

  final cuentas = (results[0].data['data'] as List?) ?? [];
  final creditos = (results[1].data['data'] as List?) ?? [];
  final inversiones = (results[2].data['data'] as List?) ?? [];

  // Totales
  final totalAhorros = cuentas.fold<double>(
      0, (sum, c) => sum + (c['saldo_actual'] as num? ?? 0).toDouble());
  final totalCreditos = creditos.fold<double>(
      0, (sum, c) => sum + (c['total_liquidar'] as num? ?? 0).toDouble());
  final totalInversiones = inversiones.fold<double>(
      0, (sum, i) => sum + (i['monto_invertido'] as num? ?? 0).toDouble());

  // Primera cuenta, primer crédito, primera inversión para mostrar detalle
  final primeraCuenta = cuentas.isNotEmpty ? cuentas.first : null;
  final primerCredito = creditos.isNotEmpty ? creditos.first : null;
  final primeraInversion = inversiones.isNotEmpty ? inversiones.first : null;

  return {
    'total_ahorros': totalAhorros,
    'total_creditos': totalCreditos,
    'total_inversiones': totalInversiones,
    'primera_cuenta': primeraCuenta,
    'primer_credito': primerCredito,
    'primera_inversion': primeraInversion,
    'num_cuentas': cuentas.length,
    'num_creditos': creditos.length,
    'num_inversiones': inversiones.length,
  };
});

// Negocios destacados para la sección Red de negocios
final _negociosDestacadosProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(authApiDioProvider);
  final response = await dio.get('/api/negocios');
  final List data = response.data['data'] ?? [];
  return data.take(5).map((e) => Map<String, dynamic>.from(e)).toList();
});

// ═══════════════════════════════════════════════════════════════════════════════
// HOME TAB
// ═══════════════════════════════════════════════════════════════════════════════

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final topPad = MediaQuery.of(context).padding.top;

    // 🔥 Timestamp global — se actualiza cuando el usuario cambia su foto
    final imageTimestamp = ref.watch(profileImageTimestampProvider);

    final userName = authState.maybeWhen(
      authenticated: (user) => user.name.split(' ').first,
      orElse: () => '',
    );

    final fotoUrl = authState.maybeWhen(
      authenticated: (user) => user.profileImage,
      orElse: () => null,
    );

    final greeting = _greeting();

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      body: RefreshIndicator(
        color: AppColors.primaryNavy,
        onRefresh: () async {
          // ignore: unused_result
          ref.refresh(_resumenFinancieroProvider);
          // ignore: unused_result
          ref.refresh(_negociosDestacadosProvider);
          // ignore: unused_result
          ref.refresh(socioDetalleProvider);
        },
        child: CustomScrollView(
          slivers: [
            // ── HEADER ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.primaryNavy,
                padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Foto arriba del saludo ──────────────────────
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => ref
                              .read(navigationIndexProvider.notifier)
                              .state = 3,
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.2),
                            child: fotoUrl != null && fotoUrl.isNotEmpty
                                ? ClipOval(
                                    // 🔥 Image.network con timestamp para
                                    // evitar caché al cambiar de foto
                                    child: Image.network(
                                      '$fotoUrl?t=$imageTimestamp',
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.cover,
                                      headers: const {
                                        'Cache-Control':
                                            'no-cache, no-store, must-revalidate',
                                        'Pragma': 'no-cache',
                                      },
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Text(
                                          userName.isNotEmpty
                                              ? userName[0].toUpperCase()
                                              : 'G',
                                          style: AppTypography.titleSmall
                                              .copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700),
                                        );
                                      },
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Text(
                                          userName.isNotEmpty
                                              ? userName[0].toUpperCase()
                                              : 'G',
                                          style: AppTypography.titleSmall
                                              .copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700),
                                        );
                                      },
                                    ),
                                  )
                                : Text(
                                    userName.isNotEmpty
                                        ? userName[0].toUpperCase()
                                        : 'G',
                                    style: AppTypography.titleSmall.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          greeting,
                          style: AppTypography.bodySmall
                              .copyWith(color: Colors.white70),
                        ),
                        Text(
                          userName,
                          style: AppTypography.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '¿Qué quieres hacer hoy?',
                          style: AppTypography.bodySmall
                              .copyWith(color: Colors.white60),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // ── Campana con contador real ───────────────────
                    Consumer(
                      builder: (context, ref, _) {
                        final unread = ref.watch(unreadCountProvider);
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
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
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.notifications_outlined,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              if (unread > 0)
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: Container(
                                    constraints:
                                        const BoxConstraints(minWidth: 18),
                                    height: 18,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.error,
                                      borderRadius: BorderRadius.circular(9),
                                      border: Border.all(
                                          color: AppColors.primaryNavy,
                                          width: 1.5),
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
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // ── RESUMEN FINANCIERO ──────────────────────────────────────
            SliverToBoxAdapter(
              child: ref
                  .watch(_resumenFinancieroProvider)
                  .when(
                    loading: () => _ResumenSkeleton(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (resumen) => _ResumenFinanciero(
                      resumen: resumen,
                      onVerAhorros: () {
                        ref.read(navigationIndexProvider.notifier).state = 1;
                        ref.read(storeTabIndexProvider.notifier).state = 0;
                      },
                      onVerCreditos: () {
                        ref.read(navigationIndexProvider.notifier).state = 1;
                        Future.delayed(const Duration(milliseconds: 100), () {
                          ref.read(storeTabIndexProvider.notifier).state = 1;
                        });
                      },
                      onVerInversiones: () {
                        ref.read(navigationIndexProvider.notifier).state = 1;
                        Future.delayed(const Duration(milliseconds: 100), () {
                          ref.read(storeTabIndexProvider.notifier).state = 2;
                        });
                      },
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 400.ms),
            ),

            // ── RED DE NEGOCIOS ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: ref
                  .watch(_negociosDestacadosProvider)
                  .when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (negocios) => negocios.isEmpty
                        ? const SizedBox.shrink()
                        : _RedNegociosSection(
                            negocios: negocios,
                            onExplorar: () => ref
                                .read(navigationIndexProvider.notifier)
                                .state = 2,
                          ),
                  )
                  .animate()
                  .fadeIn(delay: 400.ms),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buen día!';
    if (h < 19) return 'Buenas tardes!';
    return 'Buenas noches!';
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// RESUMEN FINANCIERO
// ═══════════════════════════════════════════════════════════════════════════════

class _ResumenFinanciero extends StatelessWidget {
  final Map<String, dynamic> resumen;
  final VoidCallback onVerAhorros;
  final VoidCallback onVerCreditos;
  final VoidCallback onVerInversiones;

  const _ResumenFinanciero({
    required this.resumen,
    required this.onVerAhorros,
    required this.onVerCreditos,
    required this.onVerInversiones,
  });

  @override
  Widget build(BuildContext context) {
    final primeraCuenta = resumen['primera_cuenta'] as Map?;
    final primerCredito = resumen['primer_credito'] as Map?;
    final primeraInversion = resumen['primera_inversion'] as Map?;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          // Mis Ahorros
          if (primeraCuenta != null)
            _ResumenTile(
              icono: Icons.savings_outlined,
              iconColor: AppColors.accentCyan,
              etiqueta: 'Mis Ahorros',
              titulo: primeraCuenta['nombre_cuenta']?.toString() ??
                  'Ahorro a la Vista',
              monto: (primeraCuenta['saldo_actual'] as num?)?.toDouble() ?? 0,
              badge: 'Disponible',
              badgeColor: const Color(0xFF27AE60),
              onTap: onVerAhorros,
            ),

          // Créditos
          if (primerCredito != null)
            _ResumenTile(
              icono: Icons.credit_card_outlined,
              iconColor: AppColors.primaryNavy,
              etiqueta: 'Créditos',
              titulo: _formatFecha(
                  primerCredito['fecha_proximo_pago']?.toString() ?? ''),
              monto: (primerCredito['total_liquidar'] as num?)?.toDouble() ?? 0,
              badge: 'Disponible',
              badgeColor: const Color(0xFF27AE60),
              onTap: onVerCreditos,
              montoColor: AppColors.error,
            ),

          // Inversiones
          if (primeraInversion != null)
            _ResumenTile(
              icono: Icons.trending_up_rounded,
              iconColor: const Color(0xFF1ABC9C),
              etiqueta: 'Inversiones',
              titulo: _formatFecha(
                  primeraInversion['fecha_vencimiento']?.toString() ?? ''),
              monto:
                  (primeraInversion['monto_invertido'] as num?)?.toDouble() ??
                      0,
              badge:
                  '+${(primeraInversion['tasa_rendimiento'] as num?)?.toStringAsFixed(1) ?? '0'}%',
              badgeColor: const Color(0xFF1ABC9C),
              onTap: onVerInversiones,
            ),
        ],
      ),
    );
  }

  String _formatFecha(String fecha) {
    if (fecha.isEmpty) return '';
    try {
      final d = DateTime.parse(fecha);
      return 'Vence ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    } catch (_) {
      return fecha;
    }
  }
}

class _ResumenTile extends StatelessWidget {
  final IconData icono;
  final Color iconColor;
  final String etiqueta;
  final String titulo;
  final double monto;
  final String badge;
  final Color badgeColor;
  final VoidCallback onTap;
  final Color? montoColor;

  const _ResumenTile({
    required this.icono,
    required this.iconColor,
    required this.etiqueta,
    required this.titulo,
    required this.monto,
    required this.badge,
    required this.badgeColor,
    required this.onTap,
    this.montoColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Etiqueta + chevron
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icono, color: iconColor, size: 17),
                ),
                const SizedBox(width: 8),
                Text(etiqueta,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.supportMedium)),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.supportMedium, size: 18),
              ],
            ),

            const SizedBox(height: 6),

            // Monto
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${_fmt(monto)}',
                  style: AppTypography.titleMedium.copyWith(
                    color: montoColor ?? AppColors.textDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                // Badge estado
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(badge,
                      style: AppTypography.labelSmall.copyWith(
                          color: badgeColor, fontWeight: FontWeight.w600)),
                ),
              ],
            ),

            // Subtítulo
            if (titulo.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(titulo,
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.supportMedium)),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SECCIÓN RED DE NEGOCIOS
// ═══════════════════════════════════════════════════════════════════════════════

class _RedNegociosSection extends StatelessWidget {
  final List<Map<String, dynamic>> negocios;
  final VoidCallback onExplorar;

  const _RedNegociosSection({
    required this.negocios,
    required this.onExplorar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Red de negocios',
              style: AppTypography.titleSmall.copyWith(
                  color: AppColors.textDark, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Explora nuestra red de negocios y consigue nuevas oportunidades',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.supportMedium),
            ),

            const SizedBox(height: 14),

            // Logos de negocios
            Row(
              children: [
                ...negocios.take(4).map((n) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2F5),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFFDDE3EC), width: 1),
                        ),
                        child: ClipOval(
                          child: n['logo_url'] != null
                              ? CachedNetworkImage(
                                  imageUrl: n['logo_url'],
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => const Icon(
                                    Icons.storefront_outlined,
                                    color: AppColors.supportMedium,
                                    size: 20,
                                  ),
                                )
                              : const Icon(
                                  Icons.storefront_outlined,
                                  color: AppColors.supportMedium,
                                  size: 20,
                                ),
                        ),
                      ),
                    )),

                // Badge "+N más" si hay más de 4
                if (negocios.length > 4)
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryNavy,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '+${negocios.length - 4}',
                        style: AppTypography.labelSmall.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 14),

            // Botón Explorar
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onExplorar,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                child: Text('Explorar',
                    style:
                        AppTypography.labelLarge.copyWith(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SKELETON LOADING
// ═══════════════════════════════════════════════════════════════════════════════

class _ResumenSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: List.generate(
          3,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
          ).animate(onPlay: (c) => c.repeat()).shimmer(
              duration: const Duration(milliseconds: 1200),
              color: const Color(0xFFF5F8FC)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UTILIDADES
// ─────────────────────────────────────────────────────────────────────────────

String _fmt(double monto) {
  final parts = monto.toStringAsFixed(2).split('.');
  final intPart = parts[0];
  final buf = StringBuffer();
  int count = 0;
  for (int i = intPart.length - 1; i >= 0; i--) {
    if (count > 0 && count % 3 == 0) buf.write(',');
    buf.write(intPart[i]);
    count++;
  }
  return '${buf.toString().split('').reversed.join()}.${parts[1]}';
}
