import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:theoriginallab_v2/core/theme/app_colors.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';
import 'package:theoriginallab_v2/shared/providers/providers.dart';
import 'package:theoriginallab_v2/features/home/presentation/widgets/profile_providers.dart';

class DigitalCredentialCard extends ConsumerStatefulWidget {
  const DigitalCredentialCard({super.key});

  @override
  ConsumerState<DigitalCredentialCard> createState() =>
      _DigitalCredentialCardState();
}

class _DigitalCredentialCardState extends ConsumerState<DigitalCredentialCard> {
  final _credentialKey = GlobalKey();
  bool _downloading = false;

  // ── Captura la card y guarda como PNG en la galería ────────────────────────
  Future<void> _descargarCredencial(BuildContext context) async {
    final status = await Permission.photos.request();

    if (status.isDenied || status.isPermanentlyDenied) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Permiso denegado. Habilítalo en Ajustes.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          action: SnackBarAction(
            label: 'Ajustes',
            textColor: Colors.white,
            onPressed: openAppSettings,
          ),
        ),
      );
      return;
    }

    setState(() => _downloading = true);

    try {
      // 1. Capturar el widget como imagen a 3x de resolución
      final boundary = _credentialKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // 2. Guardar en galería con saver_gallery
      final fileName =
          'credencial_genera_${DateTime.now().millisecondsSinceEpoch}';
      final result = await SaverGallery.saveImage(
        pngBytes,
        quality: 100,
        fileName: fileName,
        androidRelativePath: 'Pictures/Genera',
        skipIfExists: false,
      );

      if (!context.mounted) return;

      final success = result.isSuccess;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle_outline : Icons.error_outline,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(success
                    ? 'Credencial guardada en tu galería'
                    : 'No se pudo guardar la credencial'),
              ),
            ],
          ),
          backgroundColor: success ? const Color(0xFF1ABC9C) : AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error al guardar. Intenta de nuevo.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    final imageTimestamp = ref.watch(profileImageTimestampProvider);

    final fotoUrl = authState.maybeWhen(
      authenticated: (user) => user.profileImage,
      orElse: () => null,
    );

    final socioAsync = ref.watch(socioDetalleProvider);
    final numeroSocio = socioAsync.maybeWhen(
      data: (s) => s['numero_socio']?.toString() ?? '------',
      orElse: () => '------',
    );

    final tieneFoto = fotoUrl != null && fotoUrl.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFD6E8F7),
            Color(0xFFB8D4EE),
            Color(0xFF9BBFE3),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Título "Caja Genera" en Cinzel (Trajan Pro) ─────────────
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Caja Genera',
              style: GoogleFonts.cinzel(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
                letterSpacing: 1.5,
              ),
            ),
          ),

          // ── Card credencial envuelta en RepaintBoundary ─────────────
          RepaintBoundary(
            key: _credentialKey,
            child: AspectRatio(
              aspectRatio: 1.586,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF3A6EA8),
                      Color(0xFF5A8EC4),
                      Color(0xFF7FAFD8),
                      Color(0xFF9BBFE3),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A5499).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  children: [
                    // Bloque azul marino superior izquierda
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        width: 200,
                        height: 110,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF0D2E5C),
                              Color(0xFF163F86),
                            ],
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomRight: Radius.circular(100),
                          ),
                        ),
                      ),
                    ),

                    // Franja verde/teal diagonal
                    Positioned(
                      top: -10,
                      left: 70,
                      right: -20,
                      child: Transform.rotate(
                        angle: -0.12,
                        child: Container(
                          height: 40,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF0DAFA0),
                                Color(0xFF10C7B2),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Card blanca interior
                    Positioned(
                      top: 18,
                      left: 18,
                      right: 18,
                      bottom: 18,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: Stack(
                          children: [
                            // Formas grises decorativas
                            Positioned(
                              bottom: -25,
                              left: -15,
                              child: Transform.rotate(
                                angle: -0.2,
                                child: Container(
                                  width: 180,
                                  height: 55,
                                  color: Colors.grey.shade200,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -18,
                              right: -25,
                              child: Transform.rotate(
                                angle: 0.25,
                                child: Container(
                                  width: 180,
                                  height: 55,
                                  color: Colors.grey.shade100,
                                ),
                              ),
                            ),

                            // Contenido
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // 🔥 Foto del socio con timestamp global
                                  CircleAvatar(
                                    radius: 36,
                                    backgroundColor: Colors.grey.shade100,
                                    child: tieneFoto
                                        ? ClipOval(
                                            child: Image.network(
                                              '$fotoUrl?t=$imageTimestamp',
                                              width: 72,
                                              height: 72,
                                              fit: BoxFit.cover,
                                              headers: const {
                                                'Cache-Control':
                                                    'no-cache, no-store, must-revalidate',
                                                'Pragma': 'no-cache',
                                              },
                                              loadingBuilder: (context, child,
                                                  loadingProgress) {
                                                if (loadingProgress == null)
                                                  return child;
                                                return Icon(
                                                  Icons.person_outline_rounded,
                                                  color: Colors.grey.shade400,
                                                  size: 28,
                                                );
                                              },
                                              errorBuilder: (_, __, ___) =>
                                                  Icon(
                                                Icons.person_outline_rounded,
                                                color: Colors.grey.shade400,
                                                size: 28,
                                              ),
                                            ),
                                          )
                                        : Icon(
                                            Icons.person_outline_rounded,
                                            color: Colors.grey.shade400,
                                            size: 28,
                                          ),
                                  ),

                                  const Spacer(),

                                  // Logo + QR
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/images/app_icon_color_credential.png',
                                        width: 80,
                                        fit: BoxFit.contain,
                                      ),
                                      const SizedBox(height: 6),
                                      QrImageView(
                                        data: 'GENERA:$numeroSocio',
                                        version: QrVersions.auto,
                                        size: 56,
                                        backgroundColor: Colors.white,
                                        eyeStyle: const QrEyeStyle(
                                          eyeShape: QrEyeShape.square,
                                          color: Color(0xFF2D3B83),
                                        ),
                                        dataModuleStyle:
                                            const QrDataModuleStyle(
                                          dataModuleShape:
                                              QrDataModuleShape.square,
                                          color: Color(0xFF2D3B83),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Botón descargar ─────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed:
                  _downloading ? null : () => _descargarCredencial(context),
              icon: _downloading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textDark,
                      ),
                    )
                  : const Icon(Icons.download_rounded),
              label: Text(_downloading
                  ? 'Guardando...'
                  : 'Descargar credencial digital'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textDark,
                backgroundColor: Colors.white,
                minimumSize: const Size.fromHeight(56),
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                textStyle: AppTypography.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
