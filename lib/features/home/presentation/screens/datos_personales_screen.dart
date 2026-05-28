import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:theoriginallab_v2/core/theme/app_colors.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';
import 'package:theoriginallab_v2/shared/providers/providers.dart';
import 'package:theoriginallab_v2/features/home/presentation/widgets/profile_providers.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// PANTALLA INFORMACIÓN PERSONAL
// ═══════════════════════════════════════════════════════════════════════════════

class DatosPersonalesScreen extends ConsumerWidget {
  const DatosPersonalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final socioAsync = ref.watch(socioDetalleProvider);

    final fotoUrl = authState.maybeWhen(
      authenticated: (user) => user.profileImage,
      orElse: () => null,
    );

    final nombreCompleto = authState.maybeWhen(
      authenticated: (user) => user.name,
      orElse: () => '',
    );

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      body: CustomScrollView(
        slivers: [
          // ── AppBar ───────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.primaryNavy,
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chevron_left_rounded,
                    color: Colors.white, size: 22),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Información personal',
              style: AppTypography.titleMedium
                  .copyWith(color: Colors.white, fontWeight: FontWeight.w700),
            ),
            centerTitle: true,
          ),

          // ── Avatar + nombre + número de socio ────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: const Color(0xFFEEF2F5),
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  // Foto
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: AppColors.borderLight,
                        child: ClipOval(
                          child: fotoUrl != null && fotoUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: fotoUrl,
                                  width: 88,
                                  height: 88,
                                  fit: BoxFit.cover,
                                )
                              : Text(
                                  nombreCompleto.isNotEmpty
                                      ? nombreCompleto[0].toUpperCase()
                                      : '?',
                                  style: AppTypography.headlineMedium
                                      .copyWith(color: AppColors.primaryNavy),
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: AppColors.accentCyan,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt_rounded,
                              color: Colors.white, size: 13),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Nombre
                  Text(
                    nombreCompleto,
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Número de socio + badge
                  socioAsync.when(
                    loading: () => Container(
                      height: 20,
                      width: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (socio) => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Socio ${socio['numero_socio'] ?? '#------'}',
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.supportMedium),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1ABC9C),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            socio['estado'] == 'activo' ? 'Activo' : 'Inactivo',
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Datos personales ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: socioAsync.when(
              loading: () => _DatosSkeleton(),
              error: (_, __) => Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No se pudieron cargar los datos',
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.supportMedium),
                  ),
                ),
              ),
              data: (socio) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Datos personales',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Card de datos
                    Container(
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
                        children: [
                          _DatoRow(
                            label: 'Teléfono',
                            valor: socio['telefono'] ?? '—',
                            icono: Icons.phone_outlined,
                            primero: true,
                          ),
                          _DatoRow(
                            label: 'Correo',
                            valor: socio['email'] ?? '—',
                            icono: Icons.email_outlined,
                          ),
                          _DatoRow(
                            label: 'Nacimiento',
                            valor: _formatearFecha(
                                socio['fecha_nacimiento']?.toString() ?? ''),
                            icono: Icons.cake_outlined,
                          ),
                          _DatoRow(
                            label: 'Domicilio',
                            valor: socio['domicilio'] ?? '—',
                            icono: Icons.home_outlined,
                          ),
                          _DatoRow(
                            label: 'CURP',
                            valor: socio['curp'] ?? '—',
                            icono: Icons.badge_outlined,
                            ultimo: true,
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.04, end: 0),
                  ],
                ),
              ),
            ),
          ),

          // ── Botón Guardar cambios ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              child: SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: () async {
                    // 1. Mostrar loading (opcional pero muy pro)
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) =>
                          const Center(child: CircularProgressIndicator()),
                    );

                    // 2. Simular guardado o API
                    await Future.delayed(const Duration(seconds: 1));

                    // 3. Cerrar loading
                    Navigator.pop(context);

                    // 4. Regresar con resultado
                    Navigator.pop(context, true);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1ABC9C),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Guardar cambios',
                    style: AppTypography.labelLarge
                        .copyWith(color: Colors.white, letterSpacing: 0.3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatearFecha(String fecha) {
    if (fecha.isEmpty) return '—';
    try {
      final d = DateTime.parse(fecha);
      const meses = [
        'enero',
        'febrero',
        'marzo',
        'abril',
        'mayo',
        'junio',
        'julio',
        'agosto',
        'septiembre',
        'octubre',
        'noviembre',
        'diciembre'
      ];
      return '${d.day} de ${meses[d.month - 1]} de ${d.year}';
    } catch (_) {
      return fecha;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FILA DE DATO
// ─────────────────────────────────────────────────────────────────────────────

class _DatoRow extends StatelessWidget {
  final String label;
  final String valor;
  final IconData icono;
  final bool primero;
  final bool ultimo;

  const _DatoRow({
    required this.label,
    required this.valor,
    required this.icono,
    this.primero = false,
    this.ultimo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Label
              SizedBox(
                width: 90,
                child: Text(
                  label,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.supportMedium),
                ),
              ),
              // Valor
              Expanded(
                child: Text(
                  valor,
                  textAlign: TextAlign.right,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!ultimo)
          const Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: Color(0xFFEEF2F5),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SKELETON
// ─────────────────────────────────────────────────────────────────────────────

class _DatosSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 140,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
          ).animate(onPlay: (c) => c.repeat()).shimmer(
                duration: const Duration(milliseconds: 1200),
                color: const Color(0xFFF5F8FC),
              ),
        ],
      ),
    );
  }
}
