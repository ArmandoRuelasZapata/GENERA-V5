import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:theoriginallab_v2/core/theme/app_colors.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';
import 'package:theoriginallab_v2/shared/providers/providers.dart';

// ── Importa el modelo CuentaAhorro desde store_tab
import 'package:theoriginallab_v2/features/home/presentation/screens/store_tab.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// MODELO MOVIMIENTO
// ═══════════════════════════════════════════════════════════════════════════════

class Movimiento {
  final String id;
  final String tipoMovimiento; // deposito | retiro | cargo | abono
  final double monto;
  final double saldoPosterior;
  final String descripcion;
  final String referencia;
  final DateTime fechaOperacion;

  const Movimiento({
    required this.id,
    required this.tipoMovimiento,
    required this.monto,
    required this.saldoPosterior,
    required this.descripcion,
    required this.referencia,
    required this.fechaOperacion,
  });

  bool get esPositivo =>
      tipoMovimiento == 'deposito' || tipoMovimiento == 'abono';

  factory Movimiento.fromJson(Map<String, dynamic> json) {
    return Movimiento(
      id:              json['id']?.toString() ?? '',
      tipoMovimiento:  json['tipo_movimiento'] ?? '',
      monto:           (json['monto'] as num?)?.toDouble() ?? 0.0,
      saldoPosterior:  (json['saldo_posterior'] as num?)?.toDouble() ?? 0.0,
      descripcion:     json['descripcion'] ?? '',
      referencia:      json['referencia'] ?? '',
      fechaOperacion:  DateTime.tryParse(
              json['fecha_operacion']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PROVIDER
// ═══════════════════════════════════════════════════════════════════════════════

final _movimientosProvider =
    FutureProvider.family<List<Movimiento>, String>((ref, cuentaId) async {
  final dio = ref.watch(authApiDioProvider);
  final response = await dio.get('/api/cuentas/$cuentaId/movimientos');
  final List data = response.data['data'] ?? [];
  return data.map((json) => Movimiento.fromJson(json)).toList();
});

// ═══════════════════════════════════════════════════════════════════════════════
// PANTALLA
// ═══════════════════════════════════════════════════════════════════════════════

class AhorroDetalleScreen extends ConsumerWidget {
  final CuentaAhorro cuenta;

  const AhorroDetalleScreen({super.key, required this.cuenta});

  // ── Color de la card según tipo de cuenta ────────────────────────────────
  Color get _cardColor {
    switch (cuenta.tipoCuenta) {
      case 'vista':       return AppColors.primaryNavy;const Color(0xFF0671A6);
      case 'genera':      return const Color(0xFF0671A6);
      case 'nuevo_ideal': return const Color(0xFF6A1B9A);
      case 'kids':        return const Color(0xFF1B8A4A);
      case 'plazo_fijo':  return const Color(0xFF7B3F00);
      case 'navideña':    return const Color(0xFFB84A00);
      default:            return AppColors.primaryNavy;
    }
  }

  // ── Color del banner de aviso ─────────────────────────────────────────────
  bool get _mostrarBannerPrimerDia =>
      cuenta.tipoCuenta == 'genera' || cuenta.tipoCuenta == 'nuevo_ideal';

  // ── Ícono según tipo ──────────────────────────────────────────────────────
  IconData get _iconoCuenta {
    return Icons.savings_outlined;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movimientosAsync = ref.watch(_movimientosProvider(cuenta.id));

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      body: CustomScrollView(
        slivers: [
          // ── AppBar con tabs ────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: _cardColor,
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
              'Mis Productos',
              style: AppTypography.titleMedium
                  .copyWith(color: Colors.white, fontWeight: FontWeight.w700),
            ),
            centerTitle: true,
            // Tabs decorativos — mismos que en StoreTab
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(44),
              child: Container(
                color: _cardColor,
              ),
            ),
          ),

          // ── Card de saldo ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Saldo total + ícono
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Saldo total',
                                style: AppTypography.labelMedium
                                    .copyWith(color: Colors.white70),
                              ),
                              const SizedBox(height: 4),
                              // Monto con centavos más pequeños
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '\$${_fmtEntero(cuenta.saldoActual)}',
                                      style: AppTypography.headlineMedium
                                          .copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '.${_fmtCentavos(cuenta.saldoActual)}',
                                      style: AppTypography.titleSmall
                                          .copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '  MXN',
                                      style: AppTypography.labelSmall
                                          .copyWith(color: Colors.white60),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_iconoCuenta,
                              color: Colors.white, size: 24),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Divider(color: Colors.white.withValues(alpha: 0.2)),
                    const SizedBox(height: 12),

                    // Tipo de cuenta chip — verde teal
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1ABC9C),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tipo de cuenta',
                            style: AppTypography.labelSmall
                                .copyWith(color: Colors.white70, fontSize: 10),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            cuenta.nombreCuenta,
                            style: AppTypography.labelMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 400.ms),
          ),

          // ── Banner aviso primer día hábil ─────────────────────────────
          if (_mostrarBannerPrimerDia)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5A623),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Retiro primer día hábil del mes',
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms),
            ),

          // ── Título movimientos ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Text(
                'Últimos movimientos',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          // ── Lista de movimientos ──────────────────────────────────────
          SliverToBoxAdapter(
            child: movimientosAsync.when(
              loading: () => _MovimientosSkeleton(),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.wifi_off_rounded,
                          size: 40,
                          color: AppColors.supportMedium
                              .withValues(alpha: 0.5)),
                      const SizedBox(height: 8),
                      Text('No se pudieron cargar los movimientos',
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.supportMedium),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () =>
                            ref.refresh(_movimientosProvider(cuenta.id)),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Reintentar'),
                        style: TextButton.styleFrom(
                            foregroundColor: AppColors.primaryNavy),
                      ),
                    ],
                  ),
                ),
              ),
              data: (movimientos) {
                if (movimientos.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 48,
                              color: AppColors.supportMedium
                                  .withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          Text('Sin movimientos registrados',
                              style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.supportMedium)),
                        ],
                      ),
                    ),
                  );
                }

                // Agrupar movimientos por fecha
                final grupos = _agruparPorFecha(movimientos);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: grupos.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Encabezado de fecha
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(16, 8, 16, 6),
                          child: Text(
                            entry.key,
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.supportMedium,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        // Tiles del grupo
                        Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    Colors.black.withValues(alpha: 0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: entry.value
                                .asMap()
                                .entries
                                .map((e) => Column(
                                      children: [
                                        _MovimientoTile(
                                                movimiento: e.value)
                                            .animate()
                                            .fadeIn(
                                              delay: Duration(
                                                  milliseconds:
                                                      e.key * 50),
                                            ),
                                        if (e.key <
                                            entry.value.length - 1)
                                          const Divider(
                                            height: 1,
                                            indent: 60,
                                            endIndent: 16,
                                            color: Color(0xFFEEF2F5),
                                          ),
                                      ],
                                    ))
                                .toList(),
                          ),
                        ),

                        const SizedBox(height: 10),
                      ],
                    );
                  }).toList(),
                );
              },
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  // Agrupa movimientos por etiqueta de fecha
  Map<String, List<Movimiento>> _agruparPorFecha(
      List<Movimiento> movimientos) {
    final Map<String, List<Movimiento>> grupos = {};
    final hoy = DateTime.now();
    final ayer = hoy.subtract(const Duration(days: 1));

    for (final mov in movimientos) {
      final fecha = mov.fechaOperacion;
      String etiqueta;

      if (_mismaFecha(fecha, hoy)) {
        etiqueta = 'Hoy';
      } else if (_mismaFecha(fecha, ayer)) {
        etiqueta = 'Ayer';
      } else {
        final dias = [
          'Lunes', 'Martes', 'Miércoles', 'Jueves',
          'Viernes', 'Sábado', 'Domingo'
        ];
        final meses = [
          'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
          'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
        ];
        etiqueta =
            '${dias[fecha.weekday - 1]} ${fecha.day} ${meses[fecha.month - 1]}';
      }

      grupos.putIfAbsent(etiqueta, () => []).add(mov);
    }

    return grupos;
  }

  bool _mismaFecha(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ═══════════════════════════════════════════════════════════════════════════════
// TILE DE MOVIMIENTO
// ═══════════════════════════════════════════════════════════════════════════════

class _MovimientoTile extends StatelessWidget {
  final Movimiento movimiento;
  const _MovimientoTile({required this.movimiento});

  IconData get _icono {
    switch (movimiento.tipoMovimiento) {
      case 'deposito': return Icons.arrow_downward_rounded;
      case 'abono':    return Icons.arrow_downward_rounded;
      case 'retiro':   return Icons.arrow_upward_rounded;
      case 'cargo':    return Icons.arrow_upward_rounded;
      default:         return Icons.swap_horiz_rounded;
    }
  }

  Color get _iconColor {
    return movimiento.esPositivo
        ? const Color(0xFF1ABC9C)
        : AppColors.error;
  }

  String get _hora {
    final h = movimiento.fechaOperacion.hour.toString().padLeft(2, '0');
    final m = movimiento.fechaOperacion.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get _etiquetaTipo {
    switch (movimiento.tipoMovimiento) {
      case 'deposito': return 'Depósito';
      case 'abono':    return 'Abono';
      case 'retiro':   return 'Retiro';
      case 'cargo':    return 'Cargo';
      default:         return 'Transacción';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Ícono
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _iconColor.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(_icono, color: _iconColor, size: 18),
          ),

          const SizedBox(width: 12),

          // Descripción y hora
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movimiento.descripcion.isNotEmpty
                      ? movimiento.descripcion
                      : _etiquetaTipo,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$_hora · Por procesar',
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.supportMedium),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Monto
          Text(
            '${movimiento.esPositivo ? '+' : '-'} \$ ${_fmtMonto(movimiento.monto)}',
            style: AppTypography.bodySmall.copyWith(
              color: _iconColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SKELETON LOADING
// ═══════════════════════════════════════════════════════════════════════════════

class _MovimientosSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(
          5,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(
                duration: const Duration(milliseconds: 1200),
                color: const Color(0xFFF5F8FC),
              ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// AHORRO DETALLE TAB — vive dentro del StoreTab sin Scaffold propio
// ═══════════════════════════════════════════════════════════════════════════════

class AhorroDetalleTab extends ConsumerWidget {
  final CuentaAhorro cuenta;
  final VoidCallback onBack;

  const AhorroDetalleTab({
    super.key,
    required this.cuenta,
    required this.onBack,
  });

  bool get _mostrarBannerPrimerDia =>
      cuenta.tipoCuenta == 'genera' || cuenta.tipoCuenta == 'nuevo_ideal';

  Color get _cardColor {
    switch (cuenta.tipoCuenta) {
      case 'vista':       return const Color(0xFF0671A6);
      case 'genera':      return AppColors.primaryNavy;
      case 'nuevo_ideal': return const Color(0xFF6A1B9A);
      case 'kids':        return const Color(0xFF1B8A4A);
      case 'plazo_fijo':  return const Color(0xFF7B3F00);
      default:            return AppColors.primaryNavy;
    }
  }

  IconData get _iconoCuenta {
      return Icons.savings_outlined;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movimientosAsync = ref.watch(_movimientosProvider(cuenta.id));

    return CustomScrollView(
      slivers: [
        // ── Botón volver + nombre cuenta ──────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onBack,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.primaryNavy.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chevron_left_rounded,
                        color: AppColors.primaryNavy, size: 22),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  cuenta.nombreCuenta,
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Card de saldo ──────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _cardColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Saldo total',
                                style: AppTypography.labelMedium
                                    .copyWith(color: Colors.white70)),
                            const SizedBox(height: 4),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '\$${_fmtEntero(cuenta.saldoActual)}',
                                    style: AppTypography.headlineMedium
                                        .copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '.${_fmtCentavos(cuenta.saldoActual)}',
                                    style: AppTypography.titleSmall.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '  MXN',
                                    style: AppTypography.labelSmall
                                        .copyWith(color: Colors.white60),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_iconoCuenta,
                            color: Colors.white, size: 24),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Colors.white.withValues(alpha: 0.2)),
                  const SizedBox(height: 12),
                  // Chip tipo cuenta en verde
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF057189),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tipo de cuenta',
                            style: AppTypography.labelSmall.copyWith(
                                color: Colors.white70, fontSize: 10)),
                        const SizedBox(height: 2),
                        Text(cuenta.nombreCuenta,
                            style: AppTypography.labelMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 400.ms),
        ),

        // ── Banner primer día hábil ────────────────────────────────────
        if (_mostrarBannerPrimerDia)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5A623),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Retiro primer día hábil del mes',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms),
          ),

        // ── Título movimientos ─────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Text(
              'Últimos movimientos',
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),

        // ── Movimientos ────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: movimientosAsync.when(
            loading: () => _MovimientosSkeleton(),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.wifi_off_rounded,
                        size: 40,
                        color: AppColors.supportMedium
                            .withValues(alpha: 0.5)),
                    const SizedBox(height: 8),
                    Text('No se pudieron cargar los movimientos',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.supportMedium),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () =>
                          ref.refresh(_movimientosProvider(cuenta.id)),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Reintentar'),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryNavy),
                    ),
                  ],
                ),
              ),
            ),
            data: (movimientos) {
              if (movimientos.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 48,
                            color: AppColors.supportMedium
                                .withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text('Sin movimientos registrados',
                            style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.supportMedium)),
                      ],
                    ),
                  ),
                );
              }

              final grupos = _agruparPorFecha(movimientos);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: grupos.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                        child: Text(entry.key,
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.supportMedium,
                              fontWeight: FontWeight.w600,
                            )),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
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
                          children: entry.value.asMap().entries.map((e) =>
                            Column(children: [
                              _MovimientoTile(movimiento: e.value)
                                  .animate()
                                  .fadeIn(delay: Duration(
                                      milliseconds: e.key * 50)),
                              if (e.key < entry.value.length - 1)
                                const Divider(
                                  height: 1, indent: 60, endIndent: 16,
                                  color: Color(0xFFEEF2F5),
                                ),
                            ])
                          ).toList(),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  );
                }).toList(),
              );
            },
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  Map<String, List<Movimiento>> _agruparPorFecha(
      List<Movimiento> movimientos) {
    final Map<String, List<Movimiento>> grupos = {};
    final hoy = DateTime.now();
    final ayer = hoy.subtract(const Duration(days: 1));
    for (final mov in movimientos) {
      final fecha = mov.fechaOperacion;
      String etiqueta;
      if (_mismaFecha(fecha, hoy)) {
        etiqueta = 'Hoy';
      } else if (_mismaFecha(fecha, ayer)) {
        etiqueta = 'Ayer';
      } else {
        final dias = ['Lunes','Martes','Miércoles','Jueves','Viernes','Sábado','Domingo'];
        final meses = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
        etiqueta = '${dias[fecha.weekday - 1]} ${fecha.day} ${meses[fecha.month - 1]}';
      }
      grupos.putIfAbsent(etiqueta, () => []).add(mov);
    }
    return grupos;
  }

  bool _mismaFecha(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ═══════════════════════════════════════════════════════════════════════════════
// UTILIDADES
// ═══════════════════════════════════════════════════════════════════════════════

String _fmtEntero(double monto) {
  final intPart = monto.toInt().toString();
  final buf = StringBuffer();
  int count = 0;
  for (int i = intPart.length - 1; i >= 0; i--) {
    if (count > 0 && count % 3 == 0) buf.write(',');
    buf.write(intPart[i]);
    count++;
  }
  return buf.toString().split('').reversed.join();
}

String _fmtCentavos(double monto) {
  return (monto - monto.toInt()).toStringAsFixed(2).substring(2);
}

String _fmtMonto(double monto) {
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