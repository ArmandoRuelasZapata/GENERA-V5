import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:theoriginallab_v2/core/config/env.dart';
import 'package:theoriginallab_v2/core/theme/app_colors.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';
import 'package:theoriginallab_v2/shared/providers/providers.dart';

import 'red_negocios_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELO EXTENDIDO — datos extra del servidor
// ─────────────────────────────────────────────────────────────────────────────

class NegocioDetalle {
  final String telefono;
  final double latitud;
  final double longitud;
  final String sitioWeb;
  final Map<String, String> horarios;
  final Map<String, String> redesSociales;

  const NegocioDetalle({
    required this.telefono,
    required this.latitud,
    required this.longitud,
    required this.sitioWeb,
    required this.horarios,
    required this.redesSociales,
  });

  factory NegocioDetalle.fromJson(Map<String, dynamic> json) {
    final horariosRaw = json['horarios'];
    final redesRaw    = json['redes_sociales'];
    return NegocioDetalle(
      telefono:      json['telefono']?.toString()  ?? '',
      latitud:       (json['latitud']  as num?)?.toDouble() ?? 24.0277,
      longitud:      (json['longitud'] as num?)?.toDouble() ?? -104.6532,
      sitioWeb:      json['sitio_web']?.toString() ?? '',
      horarios:      horariosRaw is Map
          ? Map<String, String>.from(horariosRaw)
          : {},
      redesSociales: redesRaw is Map
          ? Map<String, String>.from(redesRaw)
          : {},
    );
  }
}

// Provider que carga el detalle del negocio del servidor
final _negocioDetalleProvider =
    FutureProvider.family<NegocioDetalle, String>((ref, negocioId) async {
  final dio = ref.watch(authApiDioProvider);
  final response = await dio.get('/api/negocios/$negocioId');
  return NegocioDetalle.fromJson(response.data['data'] ?? {});
});

// ─────────────────────────────────────────────────────────────────────────────
// PANTALLA DETALLE
// ─────────────────────────────────────────────────────────────────────────────

class NegocioDetalleScreen extends ConsumerStatefulWidget {
  final Negocio negocio;
  const NegocioDetalleScreen({super.key, required this.negocio});

  @override
  ConsumerState<NegocioDetalleScreen> createState() =>
      _NegocioDetalleScreenState();
}

class _NegocioDetalleScreenState extends ConsumerState<NegocioDetalleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  GoogleMapController? _mapController;

  static const _defaultLatLng = LatLng(24.0277, -104.6532);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detalleAsync =
        ref.watch(_negocioDetalleProvider(widget.negocio.id));

    final latLng = detalleAsync.maybeWhen(
      data: (d) => LatLng(d.latitud, d.longitud),
      orElse: () => _defaultLatLng,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerScrolled) => [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.primaryNavy,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chevron_left_rounded,
                    color: Colors.white, size: 22),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('Red de negocios',
                style: AppTypography.titleMedium
                    .copyWith(color: Colors.white)),
            centerTitle: true,

            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.negocio.logoUrl != null)
                    Image.network(
                      widget.negocio.logoUrl!
                          .replaceAll('/200/200', '/800/400'),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: AppColors.primaryNavy),
                    )
                  else
                    Container(color: AppColors.primaryNavy),

                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x44000000), Color(0x88000000)],
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: 60, left: 0, right: 0,
                    child: Center(
                      child: Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8)],
                        ),
                        child: ClipOval(
                          child: widget.negocio.logoUrl != null
                              ? Image.network(widget.negocio.logoUrl!,
                                  fit: BoxFit.cover)
                              : const Icon(Icons.storefront_outlined,
                                  color: AppColors.primaryNavy),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 2,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: AppTypography.labelMedium
                  .copyWith(fontWeight: FontWeight.w700),
              unselectedLabelStyle: AppTypography.labelMedium,
              tabs: const [
                Tab(text: 'Información'),
                Tab(text: 'Beneficios'),
                Tab(text: 'Invertir'),
              ],
            ),
          ),
        ],

        body: TabBarView(
          controller: _tabController,
          children: [
            _InformacionTab(
              negocio: widget.negocio,
              detalleAsync: detalleAsync,
              latLng: latLng,
            ),
            _BeneficiosTab(negocio: widget.negocio),
            _InvertirTab(negocio: widget.negocio),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1 — INFORMACIÓN
// ─────────────────────────────────────────────────────────────────────────────

class _InformacionTab extends StatelessWidget {
  final Negocio negocio;
  final AsyncValue<NegocioDetalle> detalleAsync;
  final LatLng latLng;

  const _InformacionTab({
    required this.negocio,
    required this.detalleAsync,
    required this.latLng,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre + categoría + teléfono
          _InfoCard(
            child: Column(
              children: [
                Text(negocio.nombre,
                    style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(negocio.categoria,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.supportMedium),
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                // Teléfono del servidor
                detalleAsync.when(
                  loading: () => const SizedBox(height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (d) => d.telefono.isNotEmpty
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.phone_outlined,
                                size: 16, color: AppColors.primaryNavy),
                            const SizedBox(width: 6),
                            Text('+52 ${d.telefono}',
                                style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.primaryNavy,
                                    fontWeight: FontWeight.w600)),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Descripción + dirección + sitio web + redes
          _InfoCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Acerca de nosotros',
                          style: AppTypography.titleSmall.copyWith(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(negocio.descripcion,
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.supportMedium)),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 16, color: AppColors.primaryNavy),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(negocio.direccion,
                                style: AppTypography.bodySmall
                                    .copyWith(color: AppColors.textDark)),
                          ),
                        ],
                      ),
                      // Sitio web si existe
                      detalleAsync.maybeWhen(
                        data: (d) => d.sitioWeb.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Row(
                                  children: [
                                    const Icon(Icons.language_outlined,
                                        size: 16,
                                        color: AppColors.primaryNavy),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(d.sitioWeb,
                                          style: AppTypography.bodySmall
                                              .copyWith(
                                                  color: AppColors.primaryNavy),
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                        orElse: () => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: negocio.logoUrl != null
                      ? Image.network(
                          negocio.logoUrl!
                              .replaceAll('/200/200', '/120/100'),
                          width: 100, height: 80, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                              width: 100, height: 80,
                              color: const Color(0xFFEEF2F5)))
                      : Container(
                          width: 100, height: 80,
                          color: const Color(0xFFEEF2F5)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Horarios
          detalleAsync.maybeWhen(
            data: (d) => d.horarios.isNotEmpty
                ? _InfoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Horarios',
                            style: AppTypography.titleSmall.copyWith(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10),
                        ...d.horarios.entries.map((e) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 90,
                                    child: Text(_nombreDia(e.key),
                                        style: AppTypography.bodySmall
                                            .copyWith(
                                                color:
                                                    AppColors.supportMedium)),
                                  ),
                                  Text(e.value,
                                      style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.textDark,
                                          fontWeight: FontWeight.w500)),
                                ],
                              ),
                            )),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),

          const SizedBox(height: 12),

          // Mapa
          _MapaCard(latLng: latLng, titulo: negocio.nombre),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _nombreDia(String key) {
    const map = {
      'lunes': 'Lunes', 'martes': 'Martes', 'miercoles': 'Miércoles',
      'jueves': 'Jueves', 'viernes': 'Viernes', 'sabado': 'Sábado',
      'domingo': 'Domingo',
    };
    return map[key] ?? key;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2 — BENEFICIOS
// ─────────────────────────────────────────────────────────────────────────────

class _BeneficiosTab extends StatelessWidget {
  final Negocio negocio;
  const _BeneficiosTab({required this.negocio});

  static const _beneficios = [
    _Beneficio(
      titulo: '15% de descuento',
      descripcion: 'Presenta tu credencial GENERA y obtén 15% de descuento en tu consumo total.',
      icono: Icons.local_offer_outlined,
      puntos: null,
    ),
    _Beneficio(
      titulo: 'Acceso preferencial',
      descripcion: 'Socios GENERA tienen acceso preferencial sin filas en días de alta demanda.',
      icono: Icons.star_outline_rounded,
      puntos: null,
    ),
    _Beneficio(
      titulo: 'Canje de 500 puntos',
      descripcion: 'Canjea 500 puntos GENERA por una experiencia exclusiva en este establecimiento.',
      icono: Icons.redeem_outlined,
      puntos: 500,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _beneficios.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _BeneficioCard(beneficio: _beneficios[i]),
    );
  }
}

class _Beneficio {
  final String titulo;
  final String descripcion;
  final IconData icono;
  final int? puntos;
  const _Beneficio({
    required this.titulo,
    required this.descripcion,
    required this.icono,
    this.puntos,
  });
}

class _BeneficioCard extends StatelessWidget {
  final _Beneficio beneficio;
  const _BeneficioCard({required this.beneficio});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryNavy.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(beneficio.icono,
                color: AppColors.primaryNavy, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(beneficio.titulo,
                          style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w700)),
                    ),
                    if (beneficio.puntos != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accentCyan
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('${beneficio.puntos} pts',
                            style: AppTypography.labelSmall.copyWith(
                                color: AppColors.accentCyan,
                                fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(beneficio.descripcion,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.supportMedium)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 3 — INVERTIR
// ─────────────────────────────────────────────────────────────────────────────

class _InvertirTab extends StatefulWidget {
  final Negocio negocio;
  const _InvertirTab({required this.negocio});

  @override
  State<_InvertirTab> createState() => _InvertirTabState();
}

class _InvertirTabState extends State<_InvertirTab> {
  bool   _descargando = false;
  double _progreso    = 0.0;

  Future<void> _descargarPDF() async {
    setState(() { _descargando = true; _progreso = 0.0; });
    try {
      final baseUrl = Env.authApiBaseUrl;
      final url     = '$baseUrl/api/negocios/${widget.negocio.id}/pdf';

      // Guardar en Downloads en Android, Documents en iOS
      final dir = Platform.isAndroid
          ? Directory('/storage/emulated/0/Download')
          : await getApplicationDocumentsDirectory();
      if (!await dir.exists()) await dir.create(recursive: true);

      final safe = widget.negocio.nombre
          .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')
          .toLowerCase();
      final filePath = '${dir.path}/genera_$safe.pdf';

      final dio = Dio();
      await dio.download(
        url,
        filePath,
        onReceiveProgress: (recv, total) {
          if (total > 0 && mounted) {
            setState(() => _progreso = recv / total);
          }
        },
      );

      if (!mounted) return;

      final result = await OpenFile.open(filePath);
      if (result.type != ResultType.done) {
        _snack('PDF guardado en Descargas: genera_$safe.pdf',
            AppColors.primaryNavy);
      }
    } catch (e) {
      if (!mounted) return;
      _snack('Error al descargar: $e', AppColors.error);
    } finally {
      if (mounted) setState(() { _descargando = false; _progreso = 0.0; });
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Oportunidad de inversión',
                    style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  'Este negocio forma parte de la red de inversión GENERA. Como socio puedes acceder a rendimientos exclusivos al invertir en este establecimiento.',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.supportMedium),
                ),
                const SizedBox(height: 16),
                _InvRow(label: 'Inversión mínima',  valor: '\$10,000 MXN'),
                _InvRow(label: 'Rendimiento anual', valor: '9.5%'),
                _InvRow(label: 'Plazo mínimo',      valor: '90 días'),
                _InvRow(label: 'Modalidad',         valor: 'Plazo fijo'),
                const SizedBox(height: 20),

                // Progreso
                if (_descargando) ...[
                  LinearProgressIndicator(
                    value: _progreso > 0 ? _progreso : null,
                    backgroundColor: const Color(0xFFEEF2F5),
                    color: AppColors.primaryNavy,
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 6,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _progreso > 0
                        ? 'Descargando ${(_progreso * 100).round()}%...'
                        : 'Generando PDF...',
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.supportMedium),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                ],

                // Botón descargar PDF
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _descargando ? null : _descargarPDF,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryNavy,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    icon: _descargando
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.download_rounded,
                            color: Colors.white, size: 20),
                    label: Text(
                      _descargando ? 'Descargando...' : 'Descargar ficha PDF',
                      style: AppTypography.labelLarge
                          .copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryNavy.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.primaryNavy.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.primaryNavy, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'La ficha incluye horarios, beneficios, promociones y condiciones de inversión del negocio.',
                    style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primaryNavy, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _InvRow extends StatelessWidget {
  final String label;
  final String valor;
  const _InvRow({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.supportMedium)),
          ),
          Text(valor,
              style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textDark, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS COMPARTIDOS
// ─────────────────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final Widget child;
  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}

class _MapaCard extends StatefulWidget {
  final LatLng latLng;
  final String titulo;
  const _MapaCard({required this.latLng, required this.titulo});

  @override
  State<_MapaCard> createState() => _MapaCardState();
}

class _MapaCardState extends State<_MapaCard> {
  GoogleMapController? _ctrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: GoogleMap(
          initialCameraPosition:
              CameraPosition(target: widget.latLng, zoom: 15),
          onMapCreated: (c) => _ctrl = c,
          markers: {
            Marker(
              markerId: const MarkerId('sucursal'),
              position: widget.latLng,
              infoWindow: InfoWindow(title: widget.titulo),
            ),
          },
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          mapToolbarEnabled: false,
          scrollGesturesEnabled: false,
          zoomGesturesEnabled: false,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }
}