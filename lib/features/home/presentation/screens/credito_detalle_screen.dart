import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:theoriginallab_v2/core/theme/app_colors.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';
import 'package:theoriginallab_v2/shared/providers/providers.dart';
import 'store_tab.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// MODELO PAGO CRÉDITO
// ═══════════════════════════════════════════════════════════════════════════════

class PagoCredito {
  final String id;
  final String creditoId;
  final double monto;
  final DateTime fechaVencimiento;
  final String estado;
  final String referencia;

  const PagoCredito({
    required this.id,
    required this.creditoId,
    required this.monto,
    required this.fechaVencimiento,
    required this.estado,
    required this.referencia,
  });

  bool get esProximoPago =>
      estado == 'pendiente' &&
      fechaVencimiento.isAfter(DateTime.now().subtract(const Duration(days: 1)));

  String get fechaFormateada {
    return '${fechaVencimiento.day.toString().padLeft(2, '0')}/'
        '${fechaVencimiento.month.toString().padLeft(2, '0')}/'
        '${fechaVencimiento.year}';
  }

  String get mesFormateado {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${meses[fechaVencimiento.month - 1]} ${fechaVencimiento.year}';
  }

  factory PagoCredito.fromJson(Map<String, dynamic> json) => PagoCredito(
    id:               json['id']?.toString() ?? '',
    creditoId:        json['credito_id']?.toString() ?? '',
    monto:            (json['monto'] as num?)?.toDouble() ?? 0.0,
    fechaVencimiento: DateTime.tryParse(json['fecha_vencimiento'] ?? '') ?? DateTime.now(),
    estado:           json['estado'] ?? 'pendiente',
    referencia:       json['referencia'] ?? '',
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// PROVIDER
// ═══════════════════════════════════════════════════════════════════════════════

final pagosCreditoDetailProvider =
    FutureProvider.family<List<PagoCredito>, String>((ref, creditoId) async {
  final dio = ref.watch(authApiDioProvider);

  try {
    final response = await dio.get('/api/creditos/$creditoId/pagos');
    final List data = response.data['data'] ?? [];
    return data.map((json) => PagoCredito.fromJson(json)).toList();
  } catch (_) {
    // Generar pagos simulados si el endpoint no existe aún
    final creditoResponse = await dio.get('/api/creditos/$creditoId');
    final creditoData = creditoResponse.data['data'];
    if (creditoData == null) return [];

    final fechaVencimiento =
        DateTime.tryParse(creditoData['fecha_vencimiento'] ?? '');
    final fechaOtorgamiento =
        DateTime.tryParse(creditoData['fecha_otorgamiento'] ?? '');
    final totalLiquidar =
        (creditoData['total_liquidar'] as num?)?.toDouble() ?? 0.0;

    if (fechaVencimiento == null || fechaOtorgamiento == null) return [];

    final List<PagoCredito> pagosSimulados = [];
    DateTime fechaPago = DateTime(
        fechaOtorgamiento.year, fechaOtorgamiento.month + 1, 1);
    int mes = 1;

    while (fechaPago.isBefore(fechaVencimiento) ||
        fechaPago.isAtSameMomentAs(fechaVencimiento)) {
      final estado =
          fechaPago.isBefore(DateTime.now()) ? 'pagado' : 'pendiente';
      pagosSimulados.add(PagoCredito(
        id: 'pago_$mes',
        creditoId: creditoId,
        monto: totalLiquidar / 12,
        fechaVencimiento: fechaPago,
        estado: estado,
        referencia:
            'PAGO-${creditoData['numero_credito']}-$mes',
      ));
      fechaPago =
          DateTime(fechaPago.year, fechaPago.month + 1, 1);
      mes++;
    }

    return pagosSimulados;
  }
});

// ═══════════════════════════════════════════════════════════════════════════════
// CRÉDITO DETALLE TAB
// ═══════════════════════════════════════════════════════════════════════════════

class CreditoDetalleTab extends ConsumerStatefulWidget {
  final Credito credito;
  final VoidCallback onBack;

  const CreditoDetalleTab({
    super.key,
    required this.credito,
    required this.onBack,
  });

  @override
  ConsumerState<CreditoDetalleTab> createState() =>
      _CreditoDetalleTabState();
}

class _CreditoDetalleTabState extends ConsumerState<CreditoDetalleTab> {
  @override
  Widget build(BuildContext context) {
    final pagosAsync =
        ref.watch(pagosCreditoDetailProvider(widget.credito.id));

    return CustomScrollView(
      slivers: [

        // ── Botón volver + nombre crédito ─────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: widget.onBack,
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
                  widget.credito.nombreLegible,
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Card principal ─────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E4973), AppColors.primaryNavy],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryNavy.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Total a liquidar
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total a liquidar',
                                style: AppTypography.labelMedium
                                    .copyWith(color: Colors.white70)),
                            const SizedBox(height: 4),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '\$${_fmtEntero(widget.credito.totalLiquidar)}',
                                    style: AppTypography.headlineMedium
                                        .copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '.${_fmtCentavos(widget.credito.totalLiquidar)}',
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
                        child: const Icon(Icons.credit_card_outlined,
                            color: Colors.white, size: 24),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Divider(color: Colors.white.withValues(alpha: 0.2)),
                  const SizedBox(height: 12),

                  // Grid de datos del crédito
                  Row(
                    children: [
                      Expanded(
                        child: _InfoMiniChip(
                          label: 'Saldo capital',
                          valor: '\$${_fmtMonto(widget.credito.saldoCapital)}',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _InfoMiniChip(
                          label: 'Monto original',
                          valor: '\$${_fmtMonto(widget.credito.montoOriginal)}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoMiniChip(
                          label: 'Tasa de interés',
                          valor: '${widget.credito.tasaInteres}%',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _InfoMiniChip(
                          label: 'Vencimiento',
                          valor: _formatearFecha(widget.credito.fechaVencimiento),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoMiniChip(
                          label: 'Otorgamiento',
                          valor: _formatearFecha(widget.credito.fechaOtorgamiento),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _InfoMiniChip(
                          label: 'Número crédito',
                          valor: widget.credito.numeroCredito,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 400.ms),
        ),

        // ── Próximos pagos ─────────────────────────────────────────────
        SliverToBoxAdapter(
          child: pagosAsync.when(
            loading: () => const _PagosSkeleton(),
            error: (_, __) => const SizedBox.shrink(),
            data: (pagos) {
              final proximosPagos =
                  pagos.where((p) => p.esProximoPago).toList();
              if (proximosPagos.isEmpty) return const SizedBox.shrink();

              return Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1ABC9C)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.calendar_today_rounded,
                              color: Color(0xFF1ABC9C), size: 18),
                        ),
                        const SizedBox(width: 12),
                        Text('Próximos pagos',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w700,
                            )),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...proximosPagos.take(2).map((pago) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ProximoPagoCard(pago: pago),
                        )),
                    if (proximosPagos.length > 2)
                      TextButton(
                        onPressed: () =>
                            _showAllPagosDialog(context, pagos),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF1ABC9C),
                        ),
                        child: const Text('Ver todos los pagos'),
                      ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms);
            },
          ),
        ),

        // ── Banner amarillo — sólido con contraste completo ────────────
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
                    'Si los pagos no se han realizado conforme al monto y fecha, los saldos pueden variar. Te sugerimos contactar a un asesor.',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms),
        ),

        // ── Título medios de pago ──────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Text('Medios de pago',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w700,
                )),
          ),
        ),

        // ── Medios de pago ─────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
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
            child: Row(
              children: [
                _MedioPagoItem(
                  icon: Icons.account_balance_outlined,
                  label: 'Transferencia',
                ),
                const SizedBox(width: 24),
                _MedioPagoItem(
                  icon: Icons.storefront_outlined,
                  label: 'Caja física',
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms),
        ),

        // ── Banner azul marino — sólido con contraste completo ─────────
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primaryNavy, // azul marino sólido
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Los pagos se reflejan el mismo día hasta antes de las 16:00 hrs. Posterior a esa hora se reflejan el siguiente día hábil.',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 500.ms),
        ),
      ],
    );
  }

  void _showAllPagosDialog(
      BuildContext context, List<PagoCredito> pagos) {
    final pagosOrdenados = List<PagoCredito>.from(pagos)
      ..sort((a, b) =>
          a.fechaVencimiento.compareTo(b.fechaVencimiento));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.supportMedium,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Historial de pagos',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w700,
                    )),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: pagosOrdenados.length,
                  itemBuilder: (context, index) {
                    final pago = pagosOrdenados[index];
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: pago.estado == 'pagado'
                              ? const Color(0xFF1ABC9C)
                                  .withValues(alpha: 0.1)
                              : AppColors.error
                                  .withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          pago.estado == 'pagado'
                              ? Icons.check_circle_outline
                              : Icons.pending_outlined,
                          color: pago.estado == 'pagado'
                              ? const Color(0xFF1ABC9C)
                              : AppColors.error,
                          size: 20,
                        ),
                      ),
                      title: Text(pago.mesFormateado,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w600,
                          )),
                      subtitle: Text(
                        pago.estado == 'pagado'
                            ? 'Pagado'
                            : 'Pendiente',
                        style: AppTypography.labelSmall.copyWith(
                          color: pago.estado == 'pagado'
                              ? const Color(0xFF1ABC9C)
                              : AppColors.supportMedium,
                        ),
                      ),
                      trailing: Text(
                        '\$${_fmtMonto(pago.monto)}',
                        style: AppTypography.bodyMedium.copyWith(
                          color: pago.estado == 'pagado'
                              ? const Color(0xFF1ABC9C)
                              : AppColors.textDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatearFecha(String fecha) {
    try {
      final date = DateTime.parse(fecha);
      const meses = [
        'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
        'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
      ];
      return '${date.day} ${meses[date.month - 1]} ${date.year}';
    } catch (_) {
      return fecha;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGETS DE APOYO
// ═══════════════════════════════════════════════════════════════════════════════

class _InfoMiniChip extends StatelessWidget {
  final String label;
  final String valor;

  const _InfoMiniChip({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTypography.labelSmall
                  .copyWith(color: Colors.white70, fontSize: 10)),
          const SizedBox(height: 2),
          Text(valor,
              style: AppTypography.labelSmall.copyWith(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ProximoPagoCard extends StatelessWidget {
  final PagoCredito pago;
  const _ProximoPagoCard({required this.pago});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEF2F5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1ABC9C).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      pago.fechaVencimiento.day
                          .toString()
                          .padLeft(2, '0'),
                      style: AppTypography.titleSmall.copyWith(
                        color: const Color(0xFF1ABC9C),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _obtenerMes(pago.fechaVencimiento.month),
                      style: AppTypography.labelSmall.copyWith(
                        color: const Color(0xFF1ABC9C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text('Pago',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w500,
                  )),
            ],
          ),
          Text(
            '\$${_fmtMonto(pago.monto)}',
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _obtenerMes(int mes) {
    const meses = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return meses[mes - 1];
  }
}

class _MedioPagoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MedioPagoItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primaryNavy.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryNavy, size: 18),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
            )),
      ],
    );
  }
}

class _PagosSkeleton extends StatelessWidget {
  const _PagosSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 120,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(
            2,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
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