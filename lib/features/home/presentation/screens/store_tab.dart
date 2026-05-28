import 'dart:ui';
import 'credito_detalle_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:theoriginallab_v2/features/home/presentation/providers/navigation_provider.dart';
import 'package:theoriginallab_v2/core/theme/app_colors.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';
import 'package:theoriginallab_v2/shared/providers/providers.dart';
import 'simulador_inversion_screen.dart';
import 'ahorro_detalle_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// PROVIDERS — conectados al mock server
// ═══════════════════════════════════════════════════════════════════════════════

final cuentasAhorroProvider = FutureProvider<List<CuentaAhorro>>((ref) async {
  final authState = ref.watch(authProvider);
  final socioId = authState.maybeWhen(
    authenticated: (user) => user.id,
    orElse: () => null,
  );
  if (socioId == null) return [];

  final dio = ref.watch(authApiDioProvider);
  final response = await dio.get('/api/socios/$socioId/cuentas');
  final List data = response.data['data'] ?? [];
  return data.map((json) => CuentaAhorro.fromJson(json)).toList();
});

final creditosProvider = FutureProvider<List<Credito>>((ref) async {
  final authState = ref.watch(authProvider);
  final socioId = authState.maybeWhen(
    authenticated: (user) => user.id,
    orElse: () => null,
  );
  if (socioId == null) return [];

  final dio = ref.watch(authApiDioProvider);
  final response = await dio.get('/api/socios/$socioId/creditos');
  final List data = response.data['data'] ?? [];
  return data.map((json) => Credito.fromJson(json)).toList();
});

final inversionesProvider = FutureProvider<List<Inversion>>((ref) async {
  final authState = ref.watch(authProvider);
  final socioId = authState.maybeWhen(
    authenticated: (user) => user.id,
    orElse: () => null,
  );
  if (socioId == null) return [];

  final dio = ref.watch(authApiDioProvider);
  final response = await dio.get('/api/socios/$socioId/inversiones');
  final List data = response.data['data'] ?? [];
  return data.map((json) => Inversion.fromJson(json)).toList();
});

// ═══════════════════════════════════════════════════════════════════════════════
// MODELO PAGO CRÉDITO
// ═══════════════════════════════════════════════════════════════════════════════

class PagoCredito {
  final String id;
  final String creditoId;
  final double monto;
  final DateTime fechaVencimiento;
  final String estado;
  final String? fechaPago;
  final String referencia;

  const PagoCredito({
    required this.id,
    required this.creditoId,
    required this.monto,
    required this.fechaVencimiento,
    required this.estado,
    this.fechaPago,
    required this.referencia,
  });

  bool get esProximoPago => estado == 'pendiente' && fechaVencimiento.isAfter(DateTime.now());

  String get fechaFormateada {
    return '${fechaVencimiento.day.toString().padLeft(2, '0')}/${fechaVencimiento.month.toString().padLeft(2, '0')}';
  }

  String get mesFormateado {
    const meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${fechaVencimiento.day} ${meses[fechaVencimiento.month - 1]}';
  }

  factory PagoCredito.fromJson(Map<String, dynamic> json) {
    return PagoCredito(
      id: json['id']?.toString() ?? '',
      creditoId: json['credito_id']?.toString() ?? '',
      monto: (json['monto'] as num?)?.toDouble() ?? 0.0,
      fechaVencimiento: DateTime.tryParse(json['fecha_vencimiento'] ?? '') ?? DateTime.now(),
      estado: json['estado'] ?? 'pendiente',
      fechaPago: json['fecha_pago'],
      referencia: json['referencia'] ?? '',
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PROVIDER PARA PAGOS
// ═══════════════════════════════════════════════════════════════════════════════

final pagosCreditoProvider = FutureProvider.family<List<PagoCredito>, String>((ref, creditoId) async {
  final dio = ref.watch(authApiDioProvider);
  
  try {
    final response = await dio.get('/api/creditos/$creditoId/pagos');
    final List data = response.data['data'] ?? [];
    return data.map((json) => PagoCredito.fromJson(json)).toList();
  } catch (_) {
    // Generar pagos simulados basados en el crédito
    final creditoResponse = await dio.get('/api/creditos/$creditoId');
    final creditoData = creditoResponse.data['data'];
    
    if (creditoData == null) return [];
    
    final fechaVencimiento = DateTime.tryParse(creditoData['fecha_vencimiento'] ?? '');
    final fechaOtorgamiento = DateTime.tryParse(creditoData['fecha_otorgamiento'] ?? '');
    final totalLiquidar = (creditoData['total_liquidar'] as num?)?.toDouble() ?? 0.0;
    
    if (fechaVencimiento == null || fechaOtorgamiento == null) return [];
    
    List<PagoCredito> pagosSimulados = [];
    DateTime fechaPago = DateTime(fechaOtorgamiento.year, fechaOtorgamiento.month + 1, 1);
    int mes = 1;
    
    while (fechaPago.isBefore(fechaVencimiento) || fechaPago.isAtSameMomentAs(fechaVencimiento)) {
      final estado = fechaPago.isBefore(DateTime.now()) ? 'pagado' : 'pendiente';
      pagosSimulados.add(PagoCredito(
        id: 'pago_$mes',
        creditoId: creditoId,
        monto: totalLiquidar / 12,
        fechaVencimiento: fechaPago,
        estado: estado,
        referencia: 'PAGO-${creditoData['numero_credito']}-$mes',
      ));
      
      fechaPago = DateTime(fechaPago.year, fechaPago.month + 1, 1);
      mes++;
    }
    
    return pagosSimulados;
  }
});

// ═══════════════════════════════════════════════════════════════════════════════
// MODELOS
// ═══════════════════════════════════════════════════════════════════════════════

class CuentaAhorro {
  final String id;
  final String numeroCuenta;
  final String tipoCuenta;
  final String nombreCuenta;
  final double saldoActual;
  final String estadoCuenta;
  final String fechaApertura;

  const CuentaAhorro({
    required this.id,
    required this.numeroCuenta,
    required this.tipoCuenta,
    required this.nombreCuenta,
    required this.saldoActual,
    required this.estadoCuenta,
    required this.fechaApertura,
  });

  String get estadoBadge {
    switch (tipoCuenta) {
      case 'vista':
      case 'kids':        return 'Disponible';
      case 'genera':
      case 'nuevo_ideal': return 'Primer día hábil';
      case 'plazo_fijo':  return 'Plazo fijo';
      case 'navideña':    return 'Navideña';
      default:            return 'Disponible';
    }
  }

  factory CuentaAhorro.fromJson(Map<String, dynamic> json) => CuentaAhorro(
    id:            json['id']?.toString()  ?? '',
    numeroCuenta:  json['numero_cuenta']   ?? '',
    tipoCuenta:    json['tipo_cuenta']     ?? 'vista',
    nombreCuenta:  json['nombre_cuenta']   ?? json['tipo_cuenta'] ?? 'Cuenta',
    saldoActual:   (json['saldo_actual'] as num?)?.toDouble() ?? 0.0,
    estadoCuenta:  json['estado_cuenta']   ?? 'activa',
    fechaApertura: json['fecha_apertura']  ?? '',
  );
}

class Credito {
  final String id;
  final String numeroCredito;
  final String tipoCredito;
  final double montoOriginal;
  final double saldoCapital;
  final double totalLiquidar;
  final double tasaInteres;
  final String fechaOtorgamiento;
  final String fechaVencimiento;
  final String fechaProximoPago;
  final String estadoCredito;

  const Credito({
    required this.id,
    required this.numeroCredito,
    required this.tipoCredito,
    required this.montoOriginal,
    required this.saldoCapital,
    required this.totalLiquidar,
    required this.tasaInteres,
    required this.fechaOtorgamiento,
    required this.fechaVencimiento,
    required this.fechaProximoPago,
    required this.estadoCredito,
  });

  double get porcentajePagado =>
      ((montoOriginal - saldoCapital) / montoOriginal * 100).clamp(0, 100);

  String get nombreLegible {
    switch (tipoCredito) {
      case 'personal':    return 'Crédito Personal';
      case 'hipotecario': return 'Crédito Hipotecario';
      case 'automotriz':  return 'Crédito Automotriz';
      case 'nomina':      return 'Crédito Nómina';
      default:            return tipoCredito;
    }
  }

  factory Credito.fromJson(Map<String, dynamic> json) => Credito(
    id:                json['id']?.toString()            ?? '',
    numeroCredito:     json['numero_credito']             ?? '',
    tipoCredito:       json['tipo_credito']               ?? '',
    montoOriginal:     (json['monto_original']   as num?)?.toDouble() ?? 0.0,
    saldoCapital:      (json['saldo_capital']    as num?)?.toDouble() ?? 0.0,
    totalLiquidar:     (json['total_liquidar']   as num?)?.toDouble() ?? 0.0,
    tasaInteres:       (json['tasa_interes']     as num?)?.toDouble() ?? 0.0,
    fechaOtorgamiento: json['fecha_otorgamiento']        ?? '',
    fechaVencimiento:  json['fecha_vencimiento']         ?? '',
    fechaProximoPago:  json['fecha_proximo_pago']        ?? '',
    estadoCredito:     json['estado_credito']            ?? 'activo',
  );
}

class Inversion {
  final String id;
  final String numeroInversion;
  final double montoInvertido;
  final int plazoDias;
  final double tasaRendimiento;
  final String fechaApertura;
  final String fechaVencimiento;
  final double rendimientoAcumulado;
  final String estadoInversion;

  const Inversion({
    required this.id,
    required this.numeroInversion,
    required this.montoInvertido,
    required this.plazoDias,
    required this.tasaRendimiento,
    required this.fechaApertura,
    required this.fechaVencimiento,
    required this.rendimientoAcumulado,
    required this.estadoInversion,
  });

  double get progreso {
    try {
      final inicio = DateTime.parse(fechaApertura);
      final fin    = DateTime.parse(fechaVencimiento);
      final hoy    = DateTime.now();
      if (hoy.isAfter(fin)) return 1.0;
      final totalDias = fin.difference(inicio).inDays;
      final diasTranscurridos = hoy.difference(inicio).inDays;
      return (diasTranscurridos / totalDias).clamp(0.0, 1.0);
    } catch (_) { return 0.5; }
  }

  int get diasRestantes {
    try {
      final fin = DateTime.parse(fechaVencimiento);
      final diff = fin.difference(DateTime.now()).inDays;
      return diff < 0 ? 0 : diff;
    } catch (_) { return 0; }
  }

  String get fechaAperturaFormatted {
    try {
      final d = DateTime.parse(fechaApertura);
      return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
    } catch (_) { return fechaApertura; }
  }

  String get fechaVencimientoFormatted {
    try {
      final d = DateTime.parse(fechaVencimiento);
      return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
    } catch (_) { return fechaVencimiento; }
  }

  factory Inversion.fromJson(Map<String, dynamic> json) => Inversion(
    id:                   json['id']?.toString()                        ?? '',
    numeroInversion:      json['numero_inversion']                       ?? '',
    montoInvertido:       (json['monto_invertido']    as num?)?.toDouble() ?? 0.0,
    plazoDias:            (json['plazo_dias']          as num?)?.toInt()    ?? 0,
    tasaRendimiento:      (json['tasa_rendimiento']    as num?)?.toDouble() ?? 0.0,
    fechaApertura:        json['fecha_apertura']                         ?? '',
    fechaVencimiento:     json['fecha_vencimiento']                      ?? '',
    rendimientoAcumulado: (json['rendimiento_acumulado'] as num?)?.toDouble() ?? 0.0,
    estadoInversion:      json['estado_inversion']                       ?? 'activa',
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// PANTALLA PRINCIPAL
// ═══════════════════════════════════════════════════════════════════════════════

class StoreTab extends ConsumerStatefulWidget {
  const StoreTab({super.key});

  @override
  ConsumerState<StoreTab> createState() => _StoreTabState();
}

class _StoreTabState extends ConsumerState<StoreTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(storeTabIndexProvider.notifier).state = _tabController.index;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(storeTabIndexProvider, (_, newIndex) {
      if (_tabController.index != newIndex) {
        _tabController.animateTo(newIndex);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      body: Column(
        children: [
          _ProductosHeader(tabController: _tabController),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _AhorrosTab(),
                _CreditosTab(),
                _InversionesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _ProductosHeader extends StatelessWidget {
  final TabController tabController;
  const _ProductosHeader({required this.tabController});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      color: AppColors.primaryNavy,
      padding: EdgeInsets.fromLTRB(0, topPad + 12, 0, 0),
      child: Column(
        children: [
          Text('Mis Productos',
              style: AppTypography.titleMedium
                  .copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          TabBar(
            controller: tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 2,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            labelStyle:
                AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
            unselectedLabelStyle: AppTypography.labelMedium,
            tabs: const [
              Tab(text: 'Mis Ahorros'),
              Tab(text: 'Mis Créditos'),
              Tab(text: 'Mis Inversiones'),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 1 — MIS AHORROS
// ═══════════════════════════════════════════════════════════════════════════════

class _AhorrosTab extends ConsumerStatefulWidget {
  const _AhorrosTab();

  @override
  ConsumerState<_AhorrosTab> createState() => _AhorrosTabState();
}

class _AhorrosTabState extends ConsumerState<_AhorrosTab> {
  CuentaAhorro? _cuentaSeleccionada;

  @override
  Widget build(BuildContext context) {
    if (_cuentaSeleccionada != null) {
      return AhorroDetalleTab(
        cuenta: _cuentaSeleccionada!,
        onBack: () => setState(() => _cuentaSeleccionada = null),
      );
    }

    final cuentasAsync = ref.watch(cuentasAhorroProvider);
    return cuentasAsync.when(
      loading: () => const _LoadingSkeleton(),
      error: (e, _) => _ErrorState(
        mensaje: 'No se pudieron cargar tus cuentas',
        onRetry: () => ref.refresh(cuentasAhorroProvider),
      ),
      data: (cuentas) {
        if (cuentas.isEmpty) {
          return const _EmptyState(
              mensaje: 'No tienes cuentas de ahorro activas');
        }
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Text('Ahorros activos',
                    style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _AhorroTile(
                  cuenta: cuentas[i],
                  onTap: () =>
                      setState(() => _cuentaSeleccionada = cuentas[i]),
                )
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: i * 60))
                    .slideY(begin: 0.04, end: 0),
                childCount: cuentas.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
      },
    );
  }
}

class _AhorroTile extends StatelessWidget {
  final CuentaAhorro cuenta;
  final VoidCallback onTap;
  const _AhorroTile({required this.cuenta, required this.onTap});

  Color get _badgeColor {
    switch (cuenta.tipoCuenta) {
      case 'vista':
      case 'kids':        return const Color(0xFF27AE60);
      case 'genera':
      case 'nuevo_ideal': return const Color(0xFF8E44AD);
      case 'plazo_fijo':  return const Color.fromARGB(255, 196, 84, 4);
      default:            return const Color(0xFF27AE60);
    }
  }

  Color get _iconBg {
    switch (cuenta.tipoCuenta) {
      case 'vista':       return AppColors.accentCyan;
      case 'kids':        return const Color(0xFF27AE60);
      case 'genera':      return AppColors.primaryNavy;
      case 'nuevo_ideal': return const Color(0xFF8E44AD);
      case 'plazo_fijo':  return const Color(0xFF8B4513);
      default:            return AppColors.primaryNavy;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration:
                  BoxDecoration(color: _iconBg, shape: BoxShape.circle),
              child: const Icon(Icons.savings_outlined,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cuenta.nombreCuenta,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.supportMedium)),
                  const SizedBox(height: 2),
                  Text('\$${_fmt(cuenta.saldoActual)}',
                      style: AppTypography.titleSmall.copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(cuenta.estadoBadge,
                  style: AppTypography.labelSmall.copyWith(
                      color: _badgeColor, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.supportMedium, size: 20),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 2 — MIS CRÉDITOS
// ═══════════════════════════════════════════════════════════════════════════════

class _CreditosTab extends ConsumerStatefulWidget {
  const _CreditosTab();

  @override
  ConsumerState<_CreditosTab> createState() => _CreditosTabState();
}

class _CreditosTabState extends ConsumerState<_CreditosTab> {
  Credito? _creditoSeleccionado;

  @override
  Widget build(BuildContext context) {
    // Si hay crédito seleccionado, mostrar detalle (igual que AhorrosTab)
    if (_creditoSeleccionado != null) {
      return CreditoDetalleTab(
        credito: _creditoSeleccionado!,
        onBack: () => setState(() => _creditoSeleccionado = null),
      );
    }

    final creditosAsync = ref.watch(creditosProvider);

    return creditosAsync.when(
      loading: () => const _LoadingSkeleton(),
      error: (e, _) => _ErrorState(
        mensaje: 'No se pudieron cargar tus créditos',
        onRetry: () => ref.refresh(creditosProvider),
      ),
      data: (creditos) {
        if (creditos.isEmpty) {
          return const _EmptyState(mensaje: 'No tienes créditos activos');
        }

        final totalLiquidar = creditos.fold<double>(0, (sum, c) => sum + c.totalLiquidar);

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Text('Créditos activos',
                    style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total a liquidar',
                        style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w600)),
                    Text('-\$${_fmt(totalLiquidar)}',
                        style: AppTypography.titleSmall.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => GestureDetector(
                  onTap: () => setState(() => _creditoSeleccionado = creditos[i]),
                  child: _CreditoTile(credito: creditos[i])
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: i * 60))
                      .slideY(begin: 0.04, end: 0),
                ),
                childCount: creditos.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
      },
    );
  }
}
class _CreditoTile extends StatelessWidget {
  final Credito credito;
  const _CreditoTile({required this.credito});

  @override
  Widget build(BuildContext context) {
    final pct = credito.porcentajePagado.round();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: CircularProgressIndicator(
                    value: credito.porcentajePagado / 100,
                    strokeWidth: 5,
                    backgroundColor: const Color(0xFFEEF2F5),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.accentCyan),
                  ),
                ),
                Text('$pct%',
                    style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(credito.nombreLegible,
                style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textDark, fontWeight: FontWeight.w600)),
          ),
          Text('-\$${_fmt(credito.totalLiquidar)}',
              style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.error, fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.supportMedium, size: 20),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 3 — MIS INVERSIONES
// ═══════════════════════════════════════════════════════════════════════════════

class _InversionesTab extends ConsumerWidget {
  const _InversionesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inversionesAsync = ref.watch(inversionesProvider);

    return inversionesAsync.when(
      loading: () => const _LoadingSkeleton(),
      error: (e, _) => _ErrorState(
        mensaje: 'No se pudieron cargar tus inversiones',
        onRetry: () => ref.refresh(inversionesProvider),
      ),
      data: (inversiones) {
        final saldoTotal = inversiones.fold<double>(
            0, (sum, i) => sum + i.montoInvertido);
        final tasaPromedio = inversiones.isEmpty
            ? 0.0
            : inversiones.fold<double>(
                    0, (sum, i) => sum + i.tasaRendimiento) /
                inversiones.length;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0671A6),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.primaryNavy.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Saldo total',
                                style: AppTypography.labelMedium
                                    .copyWith(color: Colors.white70)),
                            const SizedBox(height: 4),
                            Text('\$${_fmt(saldoTotal)} MXN',
                                style: AppTypography.headlineSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.trending_up_rounded,
                              color: Colors.white, size: 22),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _ResumenChip(
                            label: 'Tasa promedio',
                            valor: '${tasaPromedio.toStringAsFixed(2)} %',
                            icono: Icons.trending_up_rounded,
                            fondoColor: const Color(0xFF057189),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ResumenChip(
                            label: 'Inversiones activas',
                            valor: '${inversiones.length} activas',
                            icono: Icons.account_balance_outlined,
                            fondoColor: const Color(0xFF145882),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: const Duration(milliseconds: 400)),
            ),

            if (inversiones.isEmpty)
              const SliverFillRemaining(
                child: _EmptyState(mensaje: 'No tienes inversiones activas'),
              )
            else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Text('Inversiones activas',
                      style: AppTypography.titleMedium.copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w700)),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _InversionCard(inversion: inversiones[i])
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: 200 + i * 80))
                      .slideY(begin: 0.04, end: 0),
                  childCount: inversiones.length,
                ),
              ),
            ],

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SimuladorInversionScreen(),
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1ABC9C),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.show_chart_rounded,
                        color: Colors.white, size: 20),
                    label: Text('Simulador de inversión',
                        style: AppTypography.labelLarge.copyWith(
                            color: Colors.white, letterSpacing: 0.3)),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

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
  ConsumerState<CreditoDetalleTab> createState() => _CreditoDetalleTabState();
}

class _CreditoDetalleTabState extends ConsumerState<CreditoDetalleTab> {
  @override
  Widget build(BuildContext context) {
    final pagosAsync = ref.watch(pagosCreditoProvider(widget.credito.id));

    return CustomScrollView(
      slivers: [
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
                Expanded(
                  child: Text(
                    widget.credito.nombreLegible,
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total a liquidar',
                              style: AppTypography.labelMedium
                                  .copyWith(color: Colors.white70),
                            ),
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
                          valor: '${widget.credito.tasaInteres.toStringAsFixed(1)}%',
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
        SliverToBoxAdapter(
          child: pagosAsync.when(
            loading: () => const _PagosSkeleton(),
            error: (_, __) => const SizedBox.shrink(),
            data: (pagos) {
              final proximosPagos = pagos.where((p) => p.esProximoPago).toList();
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
                            color: const Color(0xFF1ABC9C).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.calendar_today_rounded,
                              color: Color(0xFF1ABC9C), size: 18),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Próximos pagos',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...proximosPagos.take(2).map((pago) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ProximoPagoCard(pago: pago),
                    )),
                    if (proximosPagos.length > 2)
                      TextButton(
                        onPressed: () => _showAllPagosDialog(context, pagos),
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
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5A623).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF5A623).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: Color(0xFFF5A623), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Si los pagos no se han realizado conforme al monto y fecha, los saldos pueden variar. Te sugerimos contactar a un asesor.',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.supportMedium,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Text(
              'Medios de pago',
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryNavy.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time_rounded,
                    color: AppColors.primaryNavy, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Los pagos se reflejan el mismo día hasta antes de las 16:00 hrs. Posterior a esa hora se reflejan el siguiente día hábil.',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.supportMedium,
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

  void _showAllPagosDialog(BuildContext context, List<PagoCredito> pagos) {
    final pagosOrdenados = List<PagoCredito>.from(pagos)
      ..sort((a, b) => a.fechaVencimiento.compareTo(b.fechaVencimiento));

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
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                child: Text(
                  'Historial de pagos',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
                              ? const Color(0xFF1ABC9C).withValues(alpha: 0.1)
                              : AppColors.error.withValues(alpha: 0.1),
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
                      title: Text(
                        pago.mesFormateado,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
      const meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
      return '${date.day} ${meses[date.month - 1]} ${date.year}';
    } catch (_) {
      return fecha;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS DE APOYO PARA CRÉDITO DETALLE
// ─────────────────────────────────────────────────────────────────────────────

class _InfoMiniChip extends StatelessWidget {
  final String label;
  final String valor;

  const _InfoMiniChip({
    required this.label,
    required this.valor,
  });

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
              style: AppTypography.labelSmall.copyWith(
                  color: Colors.white70, fontSize: 10)),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1ABC9C).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      pago.fechaFormateada.split('/')[0],
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
              Text(
                'Pago',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
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
    const meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return meses[mes - 1];
  }
}

class _MedioPagoItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MedioPagoItem({
    required this.icon,
    required this.label,
  });

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
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
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
          ...List.generate(2, (_) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS COMPARTIDOS
// ─────────────────────────────────────────────────────────────────────────────

class _ResumenChip extends StatelessWidget {
  final Color? fondoColor;
  final String label;
  final String valor;
  final IconData icono;

  const _ResumenChip({
    required this.label,
    required this.valor,
    required this.icono,
    this.fondoColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: fondoColor ?? Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(icono, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTypography.labelSmall
                        .copyWith(color: Colors.white60, fontSize: 10)),
                Text(valor,
                    style: AppTypography.labelSmall.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InversionCard extends StatelessWidget {
  final Inversion inversion;
  const _InversionCard({required this.inversion});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E4973),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: AppColors.primaryNavy.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.business_outlined,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(inversion.numeroInversion,
                        style: AppTypography.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700)),
                    Text('Apertura ${inversion.fechaAperturaFormatted}',
                        style: AppTypography.labelSmall
                            .copyWith(color: Colors.white60)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1ABC9C).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up_rounded,
                        color: Color(0xFF1ABC9C), size: 14),
                    const SizedBox(width: 3),
                    Text('${inversion.tasaRendimiento}%',
                        style: AppTypography.labelSmall.copyWith(
                            color: const Color(0xFF1ABC9C),
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _InversionDato(
                  label: '\$ Monto',
                  valor: '\$ ${_fmt(inversion.montoInvertido)}'),
              _InversionDato(
                  label: '\$ Vencimiento',
                  valor: inversion.fechaVencimientoFormatted),
              _InversionDato(
                  label: 'Días restantes',
                  valor: '${inversion.diasRestantes}'),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Progreso del plazo',
                  style: AppTypography.labelSmall
                      .copyWith(color: Colors.white60, fontSize: 10)),
              const SizedBox(height: 6),
              Stack(
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: inversion.progreso,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1ABC9C),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text('${(inversion.progreso * 100).round()}%',
                    style: AppTypography.labelSmall
                        .copyWith(color: Colors.white60, fontSize: 10)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InversionDato extends StatelessWidget {
  final String label;
  final String valor;
  const _InversionDato({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTypography.labelSmall
                  .copyWith(color: Colors.white60, fontSize: 10)),
          const SizedBox(height: 2),
          Text(valor,
              style: AppTypography.labelSmall.copyWith(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      itemCount: 4,
      itemBuilder: (_, i) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
      )
          .animate(onPlay: (c) => c.repeat())
          .shimmer(
              duration: const Duration(milliseconds: 1200),
              color: const Color(0xFFF5F8FC)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String mensaje;
  const _EmptyState({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.account_balance_wallet_outlined,
              size: 56,
              color: AppColors.supportMedium.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(mensaje,
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.supportMedium)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String mensaje;
  final VoidCallback onRetry;
  const _ErrorState({required this.mensaje, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded,
              size: 48,
              color: AppColors.supportMedium.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(mensaje,
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.supportMedium),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Reintentar'),
            style:
                TextButton.styleFrom(foregroundColor: AppColors.primaryNavy),
          ),
        ],
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
  final decPart = parts[1];
  final buf = StringBuffer();
  int count = 0;
  for (int i = intPart.length - 1; i >= 0; i--) {
    if (count > 0 && count % 3 == 0) buf.write(',');
    buf.write(intPart[i]);
    count++;
  }
  return '${buf.toString().split('').reversed.join()}.$decPart';
}

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