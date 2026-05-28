import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:theoriginallab_v2/core/theme/app_colors.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';

import 'red_negocios_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PANTALLA DETALLE — ALIANZA
// Sin tabs — una sola vista con: banner, info, acerca de, servicios, mapa
// ─────────────────────────────────────────────────────────────────────────────

class AlianzaDetalleScreen extends StatefulWidget {
  final Alianza alianza;
  const AlianzaDetalleScreen({super.key, required this.alianza});

  @override
  State<AlianzaDetalleScreen> createState() => _AlianzaDetalleScreenState();
}

class _AlianzaDetalleScreenState extends State<AlianzaDetalleScreen> {
  // Coordenadas mock — en producción vendrán del servidor
  static const _defaultLatLng = LatLng(24.0277, -104.6532);

  // Mock de servicios — en producción vendrá de /api/alianzas/:id
  static const _serviciosMock = [
    'Alberca',
    'Tirolesa',
    'Lago',
    'Área de asadores',
    'Área de camping',
    'Sport Bar',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      body: CustomScrollView(
        slivers: [
          // ── AppBar con foto banner ─────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.primaryNavy,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chevron_left_rounded,
                    color: Colors.white, size: 22),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Alianza',
              style: AppTypography.titleMedium.copyWith(color: Colors.white),
            ),
            centerTitle: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Foto de fondo (banner)
                  if (widget.alianza.logoUrl != null)
                    Image.network(
                      widget.alianza.logoUrl!
                          .replaceAll('/200/200', '/800/400'),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: AppColors.primaryNavy),
                    )
                  else
                    Container(color: AppColors.primaryNavy),

                  // Gradiente oscuro sobre la foto
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x33000000),
                          Color(0x99000000),
                        ],
                      ),
                    ),
                  ),

                  // Logo pequeño encima del banner
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: widget.alianza.logoUrl != null
                              ? Image.network(widget.alianza.logoUrl!,
                                  fit: BoxFit.cover)
                              : const Icon(Icons.handshake_outlined,
                                  color: AppColors.primaryNavy),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Contenido ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre y teléfono
                  _InfoCard(
                    child: Column(
                      children: [
                        Text(
                          widget.alianza.nombre,
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.phone_outlined,
                                size: 16, color: AppColors.primaryNavy),
                            const SizedBox(width: 6),
                            Text(
                              '+52 618 123 4567',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.primaryNavy,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Acerca de nosotros + dirección + foto
                  _InfoCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Acerca de nosotros',
                                style: AppTypography.titleSmall.copyWith(
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.alianza.descripcion,
                                style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.supportMedium),
                              ),
                              const SizedBox(height: 14),

                              // Servicios
                              Text(
                                'Servicios',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              ..._serviciosMock.map(
                                (s) => Padding(
                                  padding: const EdgeInsets.only(bottom: 3),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(
                                            top: 6, right: 8),
                                        width: 5,
                                        height: 5,
                                        decoration: const BoxDecoration(
                                          color: AppColors.textDark,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          s,
                                          style: AppTypography.bodySmall
                                              .copyWith(
                                                  color: AppColors.textDark),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Foto lateral
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: widget.alianza.logoUrl != null
                              ? Image.network(
                                  widget.alianza.logoUrl!
                                      .replaceAll('/200/200', '/120/140'),
                                  width: 110,
                                  height: 130,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 110,
                                    height: 130,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEEF2F5),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 110,
                                  height: 130,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF2F5),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Mapa Google Maps
                  _MapaCard(
                    latLng: _defaultLatLng,
                    titulo: 'Sucursal Centro',
                  ),

                  const SizedBox(height: 24),
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
// WIDGETS PRIVADOS
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
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: widget.latLng,
            zoom: 15,
          ),
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