import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';

import 'package:theoriginallab_v2/core/theme/app_colors.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';
import 'package:theoriginallab_v2/shared/providers/providers.dart';
import 'package:theoriginallab_v2/features/home/presentation/widgets/profile_providers.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// MODELO
// ═══════════════════════════════════════════════════════════════════════════════

class DocumentoSocio {
  final String id;
  final String tipoDocumento;
  final String? archivoUrl;
  final String estadoRevision;
  final String? comentarioRevisor;
  final String? fechaSubida;

  const DocumentoSocio({
    required this.id,
    required this.tipoDocumento,
    required this.estadoRevision,
    this.archivoUrl,
    this.comentarioRevisor,
    this.fechaSubida,
  });

  String get nombreLegible {
    switch (tipoDocumento) {
      case 'INE':
        return 'INE';
      case 'CURP':
        return 'CURP';
      case 'acta_nacimiento':
        return 'Acta de nacimiento';
      case 'comprobante_domicilio':
        return 'Comp. de domicilio';
      case 'comprobante_ingresos':
        return 'Comprobante de ingresos';
      case 'constancia_fiscal':
        return 'Const. de situación fiscal';
      case 'acta_matrimonio':
        return 'Acta de matrimonio';
      default:
        return tipoDocumento;
    }
  }

  IconData get icono {
    switch (tipoDocumento) {
      case 'INE':
        return Icons.badge_outlined;
      case 'CURP':
        return Icons.article_outlined;
      case 'acta_nacimiento':
        return Icons.description_outlined;
      case 'comprobante_domicilio':
        return Icons.home_outlined;
      case 'comprobante_ingresos':
        return Icons.request_page_outlined;
      case 'constancia_fiscal':
        return Icons.receipt_long_outlined;
      case 'acta_matrimonio':
        return Icons.favorite_border_rounded;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  bool get puedeSubir =>
      estadoRevision == 'pendiente' || estadoRevision == 'rechazado';

  String get fechaFormateada {
    if (fechaSubida == null) return '';
    try {
      final d = DateTime.parse(fechaSubida!);
      const meses = [
        'ene',
        'feb',
        'mar',
        'abr',
        'may',
        'jun',
        'jul',
        'ago',
        'sep',
        'oct',
        'nov',
        'dic'
      ];
      return 'Subido ${d.day} ${meses[d.month - 1]} ${d.year}';
    } catch (_) {
      return '';
    }
  }

  factory DocumentoSocio.fromJson(Map<String, dynamic> json) => DocumentoSocio(
        id: json['id']?.toString() ?? '',
        tipoDocumento: json['tipo_documento'] ?? '',
        archivoUrl: json['archivo_url'],
        estadoRevision: json['estado_revision'] ?? 'pendiente',
        comentarioRevisor: json['comentario_revisor'],
        fechaSubida: json['fecha_subida'],
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════════

final _documentosProvider = FutureProvider<List<DocumentoSocio>>((ref) async {
  final authState = ref.watch(authProvider);
  final socioId = authState.maybeWhen(
    authenticated: (user) => user.id,
    orElse: () => null,
  );
  if (socioId == null) return [];

  final dio = ref.watch(authApiDioProvider);
  final response = await dio.get('/api/socios/$socioId/documentos');
  final List data = response.data['data'] ?? [];
  return data
      .map((json) => DocumentoSocio.fromJson(json))
      .where((d) => d.estadoRevision != 'no_aplica')
      .toList();
});

// Estado de subida por documento (docId → isUploading)
final _uploadingProvider = StateProvider<Map<String, bool>>((ref) => {});

// ═══════════════════════════════════════════════════════════════════════════════
// PANTALLA
// ═══════════════════════════════════════════════════════════════════════════════

class DocumentosScreen extends ConsumerWidget {
  const DocumentosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final socioAsync = ref.watch(socioDetalleProvider);
    final docsAsync = ref.watch(_documentosProvider);

    final fotoUrl = authState.maybeWhen(
      authenticated: (user) => user.profileImage,
      orElse: () => null,
    );
    final nombreCompleto = authState.maybeWhen(
      authenticated: (user) => user.name,
      orElse: () => '',
    );
    final socioId = authState.maybeWhen(
      authenticated: (user) => user.id,
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
            title: Text('Información personal',
                style: AppTypography.titleMedium.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w700)),
            centerTitle: true,
          ),

          // ── Avatar + nombre + número de socio ────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: const Color(0xFFEEF2F5),
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
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
                                  fit: BoxFit.cover)
                              : Text(
                                  nombreCompleto.isNotEmpty
                                      ? nombreCompleto[0].toUpperCase()
                                      : '?',
                                  style: AppTypography.headlineMedium
                                      .copyWith(color: AppColors.primaryNavy)),
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
                  Text(nombreCompleto,
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w700,
                      )),
                  const SizedBox(height: 6),
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

          // ── Lista documentos ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Documentos personales',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w700,
                      )),
                  const SizedBox(height: 12),
                  docsAsync.when(
                    loading: () => _DocumentosSkeleton(),
                    error: (_, __) => Center(
                      child: Text('No se pudieron cargar los documentos',
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.supportMedium)),
                    ),
                    data: (documentos) => Container(
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
                        children: documentos.asMap().entries.map((entry) {
                          final i = entry.key;
                          final doc = entry.value;
                          return Column(
                            children: [
                              _DocumentoTile(
                                documento: doc,
                                socioId: socioId,
                                onSubir: () => _seleccionarYSubirPDF(
                                    context, ref, doc, socioId),
                              ).animate().fadeIn(
                                  delay: Duration(milliseconds: i * 60)),
                              if (i < documentos.length - 1)
                                const Divider(
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16,
                                  color: Color(0xFFEEF2F5),
                                ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
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

  // ── Seleccionar PDF y subir al servidor ────────────────────────────────────
  Future<void> _seleccionarYSubirPDF(
    BuildContext context,
    WidgetRef ref,
    DocumentoSocio doc,
    String socioId,
  ) async {
    // 1. Abrir selector de archivos — solo PDF
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );
    } catch (e) {
      if (!context.mounted) return;
      _showError(context, 'No se pudo abrir el selector de archivos');
      return;
    }

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;

    // Validar tamaño máximo 10 MB
    if (file.size > 10 * 1024 * 1024) {
      if (!context.mounted) return;
      _showError(context, 'El archivo no debe superar 10 MB');
      return;
    }

    // 2. Marcar como subiendo
    ref.read(_uploadingProvider.notifier).update(
          (state) => {...state, doc.id: true},
        );

    try {
      final dio = ref.read(authApiDioProvider);
      final filePath = file.path!;

      // 3. Subir al endpoint de upload
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: '${doc.tipoDocumento}_$socioId.pdf',
        ),
        'tipo_documento': doc.tipoDocumento,
        'socio_id': socioId,
      });

      final uploadResponse = await dio.post(
        '/api/upload',
        data: formData,
      );

      final uploadedUrl = uploadResponse.data['data']?['url']?.toString() ?? '';

      // 4. Actualizar el documento con la URL subida
      await dio.patch(
        '/api/documentos/${doc.id}',
        data: {
          'archivo_url': uploadedUrl,
          'estado_revision': 'pendiente',
          'fecha_subida': DateTime.now().toIso8601String(),
        },
      );

      // 5. Refrescar lista
      // ignore: unused_result
      ref.refresh(_documentosProvider);

      if (!context.mounted) return;
      _showSuccess(context, '${doc.nombreLegible} subido correctamente');
    } catch (e) {
      if (!context.mounted) return;
      _showError(context, 'Error al subir el documento. Intenta de nuevo.');
    } finally {
      // Quitar estado de carga
      ref.read(_uploadingProvider.notifier).update(
            (state) => {...state, doc.id: false},
          );
    }
  }

  void _showSuccess(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: const Color(0xFF1ABC9C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TILE DE DOCUMENTO
// ═══════════════════════════════════════════════════════════════════════════════

class _DocumentoTile extends ConsumerWidget {
  final DocumentoSocio documento;
  final String socioId;
  final VoidCallback onSubir;

  const _DocumentoTile({
    required this.documento,
    required this.socioId,
    required this.onSubir,
  });

  Widget _badge(bool isUploading) {
    if (isUploading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primaryNavy,
        ),
      );
    }

    switch (documento.estadoRevision) {
      case 'aprobado':
        return _BadgeEstado(
          label: 'Aprobado',
          color: const Color(0xFF1ABC9C),
          bgColor: const Color(0xFFE8FAF5),
        );
      case 'rechazado':
        return _BadgeEstado(
          label: 'Rechazado',
          color: AppColors.error,
          bgColor: AppColors.error.withValues(alpha: 0.1),
        );
      case 'en_revision':
        return _BadgeEstado(
          label: 'En revisión',
          color: const Color(0xFFE6920A),
          bgColor: const Color(0xFFFFF3E0),
        );
      case 'pendiente':
        return GestureDetector(
          onTap: onSubir,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryNavy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppColors.primaryNavy.withValues(alpha: 0.2)),
            ),
            child: const Icon(Icons.upload_rounded,
                color: AppColors.primaryNavy, size: 18),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadingMap = ref.watch(_uploadingProvider);
    final isUploading = uploadingMap[documento.id] == true;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Ícono
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryNavy.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                Icon(documento.icono, color: AppColors.primaryNavy, size: 20),
          ),

          const SizedBox(width: 12),

          // Nombre + fecha + comentario
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  documento.nombreLegible,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (documento.fechaFormateada.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(documento.fechaFormateada,
                      style: AppTypography.labelSmall
                          .copyWith(color: AppColors.supportMedium)),
                ],
                if (documento.estadoRevision == 'rechazado' &&
                    documento.comentarioRevisor != null) ...[
                  const SizedBox(height: 2),
                  Text(documento.comentarioRevisor!,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.error,
                        fontSize: 10,
                      )),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),
          _badge(isUploading),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS AUXILIARES
// ─────────────────────────────────────────────────────────────────────────────

class _BadgeEstado extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const _BadgeEstado({
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: AppTypography.labelSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          )),
    );
  }
}

class _DocumentosSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 340,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(
          duration: const Duration(milliseconds: 1200),
          color: const Color(0xFFF5F8FC),
        );
  }
}
