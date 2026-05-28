import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:theoriginallab_v2/core/theme/app_colors.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';
import 'package:theoriginallab_v2/shared/providers/providers.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// MODELO DE RESULTADO
// ═══════════════════════════════════════════════════════════════════════════════

class ResultadoSimulacion {
  final double monto;
  final int plazoDias;
  final double tasaAnual;
  final double rendimientoBruto;
  final double isrEstimado;
  final double rendimientoNeto;
  final double totalAlVencimiento;
  final List<double> proyeccion;      // puntos mensuales de la curva
  final List<double> escenarioBase;   // curva conservadora

  const ResultadoSimulacion({
    required this.monto,
    required this.plazoDias,
    required this.tasaAnual,
    required this.rendimientoBruto,
    required this.isrEstimado,
    required this.rendimientoNeto,
    required this.totalAlVencimiento,
    required this.proyeccion,
    required this.escenarioBase,
  });

  double get rentabilidadPct =>
      monto > 0 ? (rendimientoNeto / monto * 100).clamp(0, 100) : 0;

  double get volatilidad => (tasaAnual * 0.042).clamp(0, 100);

  factory ResultadoSimulacion.fromJson(Map<String, dynamic> json) {
    final monto      = (json['monto']              as num).toDouble();
    final plazo      = (json['plazo_dias']          as num).toInt();
    final tasa       = (json['tasa_anual']          as num).toDouble();
    final rendNeto   = (json['rendimiento_neto']    as num).toDouble();
    final rendBruto  = (json['rendimiento_bruto']   as num).toDouble();
    final isr        = (json['isr_estimado']        as num).toDouble();
    final total      = (json['total_al_vencimiento']as num).toDouble();

    // Generar curvas de proyección mensual
    final meses = max(1, (plazo / 30).round());
    final proyeccion = List<double>.generate(meses + 1, (i) {
      final t = i / meses;
      return monto + rendNeto * t * (1 + 0.05 * sin(t * pi));
    });
    final escenarioBase = List<double>.generate(meses + 1, (i) {
      final t = i / meses;
      return monto + rendNeto * 0.7 * t;
    });

    return ResultadoSimulacion(
      monto: monto, plazoDias: plazo, tasaAnual: tasa,
      rendimientoBruto: rendBruto, isrEstimado: isr,
      rendimientoNeto: rendNeto, totalAlVencimiento: total,
      proyeccion: proyeccion, escenarioBase: escenarioBase,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PROVIDER
// ═══════════════════════════════════════════════════════════════════════════════

final _simuladorProvider = FutureProvider.family<ResultadoSimulacion,
    Map<String, dynamic>>((ref, params) async {
  final dio = ref.watch(authApiDioProvider);
  final response = await dio.post('/api/simulador/inversion', data: params);
  return ResultadoSimulacion.fromJson(response.data['data']);
});

// ═══════════════════════════════════════════════════════════════════════════════
// PANTALLA
// ═══════════════════════════════════════════════════════════════════════════════

class SimuladorInversionScreen extends ConsumerStatefulWidget {
  const SimuladorInversionScreen({super.key});

  @override
  ConsumerState<SimuladorInversionScreen> createState() =>
      _SimuladorInversionScreenState();
}

class _SimuladorInversionScreenState
    extends ConsumerState<SimuladorInversionScreen> {
  // ── Estado del formulario ─────────────────────────────────────────────────
  bool _modoRedNegocios = false;
  double _monto = 1500;
  int _horizonte = 6;       // meses
  String _perfilRiesgo = 'Medio';
  final _buscarCtrl = TextEditingController();
  bool _ejecutado = false;
  Map<String, dynamic>? _params;

  static const _horizontes = [3, 6, 12, 24];
  static const _perfiles   = ['Bajo', 'Medio', 'Alto'];

  /// Tasa según perfil de riesgo
  double get _tasaPorPerfil {
    switch (_perfilRiesgo) {
      case 'Bajo':  return 7.5;
      case 'Alto':  return 11.5;
      default:      return 9.5;
    }
  }

  void _ejecutarSimulacion() {
    FocusScope.of(context).unfocus();
    setState(() {
      _ejecutado = true;
      _params = {
        'monto':      _monto,
        'plazo_dias': _horizonte * 30,
        'tasa':       _tasaPorPerfil,
      };
    });
  }

  @override
  void dispose() {
    _buscarCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      body: Column(
        children: [
          // ── Header azul ──────────────────────────────────────────
          _SimuladorHeader(onBack: () => Navigator.pop(context)),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Sección 1: Configurar ─────────────────────
                  _ConfigCard(
                    modoRedNegocios:  _modoRedNegocios,
                    buscarCtrl:       _buscarCtrl,
                    monto:            _monto,
                    horizonte:        _horizonte,
                    perfilRiesgo:     _perfilRiesgo,
                    onModoChanged: (v) =>
                        setState(() => _modoRedNegocios = v),
                    onMontoChanged: (v) =>
                        setState(() => _monto = v),
                    onHorizonteChanged: (v) =>
                        setState(() => _horizonte = v),
                    onPerfilChanged: (v) =>
                        setState(() => _perfilRiesgo = v),
                    onEjecutar: _ejecutarSimulacion,
                  ),

                  // ── Sección 2 y 3: Resultado ──────────────────
                  if (_ejecutado && _params != null) ...[
                    const SizedBox(height: 20),
                    _ResultadoSection(params: _params!),
                  ],
                ],
              ),
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

class _SimuladorHeader extends StatelessWidget {
  final VoidCallback onBack;
  const _SimuladorHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      color: AppColors.primaryNavy,
      padding: EdgeInsets.fromLTRB(0, topPad + 12, 0, 0),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: Text('Simulador de Inversión',
                    style: AppTypography.titleMedium
                        .copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: IconButton(
                    icon: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chevron_left_rounded,
                          color: Colors.white, size: 22),
                    ),
                    onPressed: onBack,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARD DE CONFIGURACIÓN
// ─────────────────────────────────────────────────────────────────────────────

class _ConfigCard extends StatelessWidget {
  final bool modoRedNegocios;
  final TextEditingController buscarCtrl;
  final double monto;
  final int horizonte;
  final String perfilRiesgo;
  final ValueChanged<bool> onModoChanged;
  final ValueChanged<double> onMontoChanged;
  final ValueChanged<int> onHorizonteChanged;
  final ValueChanged<String> onPerfilChanged;
  final VoidCallback onEjecutar;

  const _ConfigCard({
    required this.modoRedNegocios,
    required this.buscarCtrl,
    required this.monto,
    required this.horizonte,
    required this.perfilRiesgo,
    required this.onModoChanged,
    required this.onMontoChanged,
    required this.onHorizonteChanged,
    required this.onPerfilChanged,
    required this.onEjecutar,
  });

  static const _horizontes = [3, 6, 12, 24];
  static const _perfiles   = ['Bajo', 'Medio', 'Alto'];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título con chevron
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                const Icon(Icons.trending_up_rounded,
                    color: AppColors.primaryNavy, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Configurar Simulación',
                          style: AppTypography.titleSmall.copyWith(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w700)),
                      Text('Define monto, plazo y dónde invertir',
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.supportMedium)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Toggle Red de negocios / Manual
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: ['Red de negocios', 'Manual'].map((label) {
                  final activo = (label == 'Red de negocios') == modoRedNegocios;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          onModoChanged(label == 'Red de negocios'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: activo
                              ? AppColors.primaryNavy
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(label,
                            style: AppTypography.labelSmall.copyWith(
                              color: activo ? Colors.white : AppColors.supportMedium,
                              fontWeight: activo
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            )),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Buscador (solo en modo Red de negocios)
          if (modoRedNegocios) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: buscarCtrl,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textDark),
                  decoration: InputDecoration(
                    hintText: 'Buscar empresa',
                    hintStyle: AppTypography.bodySmall
                        .copyWith(color: AppColors.supportMedium),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.supportMedium, size: 18),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFEEF2F5)),
          const SizedBox(height: 16),

          // Monto a invertir
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Monto a invertir',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.supportMedium)),
                Text('\$${_fmt(monto)}',
                    style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.primaryNavy,
                    inactiveTrackColor: const Color(0xFFDDE3EC),
                    thumbColor: AppColors.primaryNavy,
                    overlayColor:
                        AppColors.primaryNavy.withValues(alpha: 0.1),
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 8),
                  ),
                  child: Slider(
                    value: monto,
                    min: 500,
                    max: 500000,
                    divisions: 999,
                    onChanged: onMontoChanged,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('\$500',
                          style: AppTypography.labelSmall
                              .copyWith(color: AppColors.supportMedium)),
                      Text('\$500,000',
                          style: AppTypography.labelSmall
                              .copyWith(color: AppColors.supportMedium)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Horizonte
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Horizonte',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.supportMedium)),
                const SizedBox(height: 8),
                Row(
                  children: _horizontes.map((h) {
                    final activo = h == horizonte;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => onHorizonteChanged(h),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          height: 36,
                          decoration: BoxDecoration(
                            color: activo
                                ? AppColors.primaryNavy
                                : const Color(0xFFEEF2F5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text('${h}M',
                              style: AppTypography.labelSmall.copyWith(
                                color: activo
                                    ? Colors.white
                                    : AppColors.textDark,
                                fontWeight: activo
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              )),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Perfil de riesgo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Perfil de riesgo',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.supportMedium)),
                const SizedBox(height: 8),
                Row(
                  children: _perfiles.map((p) {
                    final activo = p == perfilRiesgo;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => onPerfilChanged(p),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          height: 36,
                          decoration: BoxDecoration(
                            color: activo
                                ? AppColors.primaryNavy
                                : const Color(0xFFEEF2F5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(p,
                              style: AppTypography.labelSmall.copyWith(
                                color: activo
                                    ? Colors.white
                                    : AppColors.textDark,
                                fontWeight: activo
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              )),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Botón Ejecutar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: onEjecutar,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1ABC9C),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text('Ejecutar simulación',
                    style: AppTypography.labelLarge
                        .copyWith(color: Colors.white, letterSpacing: 0.3)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECCIÓN DE RESULTADO (gráfica + resumen)
// ─────────────────────────────────────────────────────────────────────────────

class _ResultadoSection extends ConsumerWidget {
  final Map<String, dynamic> params;
  const _ResultadoSection({required this.params});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(_simuladorProvider(params));

    return resultAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: AppColors.primaryNavy),
        ),
      ),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text('Error al calcular: $e',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.error)),
      ),
      data: (resultado) => Column(
        children: [
          // Gráfica
          _GraficaCard(resultado: resultado, horizonte: params['plazo_dias'] ~/ 30)
              .animate().fadeIn(duration: const Duration(milliseconds: 400)),

          const SizedBox(height: 16),

          // Resumen
          _ResumenCard(resultado: resultado)
              .animate().fadeIn(delay: const Duration(milliseconds: 200)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GRÁFICA
// ─────────────────────────────────────────────────────────────────────────────

class _GraficaCard extends StatelessWidget {
  final ResultadoSimulacion resultado;
  final int horizonte;
  const _GraficaCard({required this.resultado, required this.horizonte});

  List<String> get _etiquetas {
    const meses = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    final now = DateTime.now();
    return List.generate(horizonte + 1, (i) => meses[(now.month - 1 + i) % 12]);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10, offset: const Offset(0, 3))],
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
                  Text('Previsión de comportamiento',
                      style: AppTypography.titleSmall.copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w700)),
                  Text('Simulación de inversión a $horizonte meses',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.supportMedium)),
                ],
              ),
              const Icon(Icons.add_rounded,
                  color: AppColors.supportMedium, size: 20),
            ],
          ),

          const SizedBox(height: 12),

          // Gráfica con CustomPainter
          SizedBox(
            height: 160,
            child: CustomPaint(
              painter: _LineChartPainter(
                proyeccion:    resultado.proyeccion,
                escenarioBase: resultado.escenarioBase,
                etiquetas:     _etiquetas,
              ),
              child: Container(),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeyendaItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;
  const _LeyendaItem(
      {required this.color, required this.label, this.dashed = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16, height: 3,
          color: dashed ? Colors.transparent : color,
          child: dashed
              ? CustomPaint(painter: _DashLinePainter(color: color))
              : null,
        ),
        const SizedBox(width: 6),
        Text(label,
            style: AppTypography.labelSmall
                .copyWith(color: AppColors.supportMedium)),
      ],
    );
  }
}

class _DashLinePainter extends CustomPainter {
  final Color color;
  const _DashLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 2;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, size.height / 2),
          Offset(x + 4, size.height / 2), paint);
      x += 7;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _LineChartPainter extends CustomPainter {
  final List<double> proyeccion;
  final List<double> escenarioBase;
  final List<String> etiquetas;

  const _LineChartPainter({
    required this.proyeccion,
    required this.escenarioBase,
    required this.etiquetas,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (proyeccion.isEmpty) return;

    final allValues = [...proyeccion, ...escenarioBase];
    final minVal = allValues.reduce(min);
    final maxVal = allValues.reduce(max);
    final range  = maxVal - minVal == 0 ? 1 : maxVal - minVal;

    final chartH = size.height - 24; // espacio para etiquetas X
    final chartW = size.width;

    double xOf(int i, int total) =>
        total <= 1 ? 0 : (i / (total - 1)) * chartW;
    double yOf(double v) =>
        chartH - ((v - minVal) / range) * chartH * 0.85 - chartH * 0.05;

    // ── Área bajo curva proyección ───────────────────────────────
    final areaPath = Path();
    areaPath.moveTo(0, chartH);
    for (int i = 0; i < proyeccion.length; i++) {
      final x = xOf(i, proyeccion.length);
      final y = yOf(proyeccion[i]);
      i == 0 ? areaPath.lineTo(x, y) : areaPath.lineTo(x, y);
    }
    areaPath.lineTo(chartW, chartH);
    areaPath.close();

    canvas.drawPath(
      areaPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.accentCyan.withValues(alpha: 0.15),
            AppColors.accentCyan.withValues(alpha: 0.02),
          ],
        ).createShader(Rect.fromLTWH(0, 0, chartW, chartH)),
    );

    // ── Línea escenario base (punteada) ──────────────────────────
    final dashPaint = Paint()
      ..color = AppColors.supportMedium.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < escenarioBase.length - 1; i++) {
      final x1 = xOf(i, escenarioBase.length);
      final y1 = yOf(escenarioBase[i]);
      final x2 = xOf(i + 1, escenarioBase.length);
      final y2 = yOf(escenarioBase[i + 1]);
      final dx = x2 - x1;
      final dy = y2 - y1;
      final dist = sqrt(dx * dx + dy * dy);
      double drawn = 0;
      bool drawing = true;
      while (drawn < dist) {
        final t1 = drawn / dist;
        final t2 = min((drawn + 4) / dist, 1.0);
        if (drawing) {
          canvas.drawLine(
            Offset(x1 + dx * t1, y1 + dy * t1),
            Offset(x1 + dx * t2, y1 + dy * t2),
            dashPaint,
          );
        }
        drawn += drawing ? 4 : 5;
        drawing = !drawing;
      }
    }

    // ── Línea proyección principal ───────────────────────────────
    final linePaint = Paint()
      ..color = AppColors.accentCyan
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    for (int i = 0; i < proyeccion.length; i++) {
      final x = xOf(i, proyeccion.length);
      final y = yOf(proyeccion[i]);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(path, linePaint);

    // ── Puntos en la curva ────────────────────────────────────────
    for (int i = 0; i < proyeccion.length; i++) {
      canvas.drawCircle(
        Offset(xOf(i, proyeccion.length), yOf(proyeccion[i])),
        3,
        Paint()..color = AppColors.accentCyan,
      );
    }

    // ── Etiquetas eje X ───────────────────────────────────────────
    final style = const TextStyle(
        fontSize: 10, color: AppColors.supportMedium);
    final step = max(1, (etiquetas.length / 6).ceil());
    for (int i = 0; i < etiquetas.length; i += step) {
      final tp = TextPainter(
        text: TextSpan(text: etiquetas[i], style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas,
          Offset(xOf(i, etiquetas.length) - tp.width / 2, chartH + 6));
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter old) =>
      old.proyeccion != proyeccion || old.escenarioBase != escenarioBase;
}

// ─────────────────────────────────────────────────────────────────────────────
// RESUMEN DE SIMULACIÓN
// ─────────────────────────────────────────────────────────────────────────────

class _ResumenCard extends StatelessWidget {
  final ResultadoSimulacion resultado;
  const _ResumenCard({required this.resultado});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Resumen de la simulación',
              style: AppTypography.titleSmall.copyWith(
                  color: AppColors.textDark, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            '+\$${_fmt(resultado.rendimientoNeto)} sobre el aporte inicial',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.supportMedium),
          ),

          const SizedBox(height: 16),

          // Rentabilidad proyectada
          _ResumenRow(
            icono: Icons.trending_up_rounded,
            iconoColor: const Color(0xFF1ABC9C),
            titulo: 'Rentabilidad proyectada',
            subtitulo:
                '+\$${_fmt(resultado.rendimientoNeto)} sobre el aporte inicial',
            porcentaje: resultado.rentabilidadPct,
            colorDonut: const Color(0xFF1ABC9C),
          ),

          const Divider(height: 24, color: Color(0xFFEEF2F5)),

          // Volatilidad estimada
          _ResumenRow(
            icono: Icons.info_outline_rounded,
            iconoColor: AppColors.accentCyan,
            titulo: 'Volatilidad estimada',
            subtitulo:
                'Riesgo medio • ~${resultado.volatilidad.toStringAsFixed(1)}% mensual',
            porcentaje: resultado.volatilidad,
            colorDonut: AppColors.accentCyan,
          ),

          const SizedBox(height: 20),

          // Desglose
          _DesgloseFila('Monto invertido',
              '\$${_fmt(resultado.monto)}'),
          _DesgloseFila('Rendimiento bruto',
              '+\$${_fmt(resultado.rendimientoBruto)}'),
          _DesgloseFila('ISR estimado (0.5%)',
              '-\$${_fmt(resultado.isrEstimado)}'),
          _DesgloseFila('Rendimiento neto',
              '+\$${_fmt(resultado.rendimientoNeto)}',
              bold: true, color: const Color(0xFF1ABC9C)),
          const Divider(height: 16, color: Color(0xFFEEF2F5)),
          _DesgloseFila('Total al vencimiento',
              '\$${_fmt(resultado.totalAlVencimiento)}',
              bold: true),

          const SizedBox(height: 20),

          // Botón finalizar
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1ABC9C),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text('Finalizar simulación',
                  style: AppTypography.labelLarge
                      .copyWith(color: Colors.white, letterSpacing: 0.3)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumenRow extends StatelessWidget {
  final IconData icono;
  final Color iconoColor;
  final String titulo;
  final String subtitulo;
  final double porcentaje;
  final Color colorDonut;

  const _ResumenRow({
    required this.icono,
    required this.iconoColor,
    required this.titulo,
    required this.subtitulo,
    required this.porcentaje,
    required this.colorDonut,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: iconoColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icono, color: iconoColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo,
                  style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w600)),
              Text(subtitulo,
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.supportMedium)),
            ],
          ),
        ),
        SizedBox(
          width: 48, height: 48,
          child: CustomPaint(
            painter: _DonutPainter(
                porcentaje: porcentaje, color: colorDonut),
            child: Center(
              child: Text('${porcentaje.round()}%',
                  style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 10)),
            ),
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double porcentaje;
  final Color color;
  const _DonutPainter({required this.porcentaje, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final bg = Paint()
      ..color = const Color(0xFFEEF2F5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bg);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * (porcentaje / 100),
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.porcentaje != porcentaje;
}

class _DesgloseFila extends StatelessWidget {
  final String label;
  final String valor;
  final bool bold;
  final Color? color;
  const _DesgloseFila(this.label, this.valor,
      {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.supportMedium)),
          Text(valor,
              style: AppTypography.bodySmall.copyWith(
                color: color ?? AppColors.textDark,
                fontWeight:
                    bold ? FontWeight.w700 : FontWeight.w400,
              )),
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
  final buf = StringBuffer();
  int count = 0;
  for (int i = intPart.length - 1; i >= 0; i--) {
    if (count > 0 && count % 3 == 0) buf.write(',');
    buf.write(intPart[i]);
    count++;
  }
  return '${buf.toString().split('').reversed.join()}.${parts[1]}';
}