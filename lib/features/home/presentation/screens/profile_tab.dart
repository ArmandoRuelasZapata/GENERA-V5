import 'dart:convert';
import 'dart:io';

import 'package:theoriginallab_v2/features/home/presentation/screens/puntos_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:theoriginallab_v2/features/home/presentation/screens/documentos_screen.dart';
import 'datos_personales_screen.dart';
import 'package:theoriginallab_v2/core/theme/app_colors.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';
import 'package:theoriginallab_v2/shared/providers/providers.dart';
import 'package:theoriginallab_v2/features/auth/presentation/screens/login_screen.dart';
import 'package:theoriginallab_v2/features/home/presentation/screens/account_action_success_screen.dart';
import 'package:theoriginallab_v2/features/home/presentation/widgets/profile_providers.dart';
import '../widgets/digital_credencial_card.dart';

class ProfileTab extends ConsumerStatefulWidget {
  const ProfileTab({super.key});

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab> {
  File? _fotoLocal;
  bool _subiendoFoto = false;

  // ── Seleccionar y subir foto ───────────────────────────────────────────────
  Future<void> _cambiarFoto(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Cambiar foto de perfil',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 6),
            Text('Selecciona el origen de la foto',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.supportMedium)),
            const SizedBox(height: 20),
            _OpcionFoto(
              icono: Icons.camera_alt_rounded,
              label: 'Tomar foto',
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 10),
            _OpcionFoto(
              icono: Icons.photo_library_outlined,
              label: 'Seleccionar de galería',
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_fotoLocal != null) ...[
              const SizedBox(height: 10),
              _OpcionFoto(
                icono: Icons.delete_outline,
                label: 'Eliminar foto',
                color: AppColors.error,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _fotoLocal = null);
                },
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final permission =
        source == ImageSource.camera ? Permission.camera : Permission.photos;

    final status = await permission.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      if (!mounted) return;
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

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (picked == null) return;

    // Mostrar foto local mientras sube
    setState(() {
      _fotoLocal = File(picked.path);
      _subiendoFoto = true;
    });

    try {
      final authState = ref.read(authProvider);
      final socioId = authState.maybeWhen(
        authenticated: (user) => user.id,
        orElse: () => null,
      );
      if (socioId == null) return;

      final dio = ref.read(authApiDioProvider);

      // Convertir imagen a base64
      final imageBytes = await _fotoLocal!.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      // 1. Subir imagen al servidor con base64
      final uploadResponse = await dio.post('/api/upload', data: {
        'file': picked.path,
        'socio_id': socioId,
        'image_base64': base64Image,
      });

      final uploadedUrl = uploadResponse.data['data']?['url']?.toString() ?? '';

      if (uploadedUrl.isEmpty) throw Exception('URL vacía');

      // 2. Persistir foto_url en el socio
      await dio.patch('/api/socios/$socioId', data: {
        'foto_url': uploadedUrl,
      });

      // 3. Actualizar authProvider en memoria
      ref.read(authProvider.notifier).updateProfileImage(uploadedUrl);

      // 4. Forzar recarga global — notifica a home_tab y digital_credencial_card
      ref.read(profileImageTimestampProvider.notifier).state =
          DateTime.now().millisecondsSinceEpoch;

      // 5. Limpiar foto local (ya tenemos la URL remota)
      setState(() => _fotoLocal = null);

      // 6. Refrescar detalle del socio
      ref.refresh(socioDetalleProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Foto actualizada correctamente'),
            ],
          ),
          backgroundColor: const Color(0xFF1ABC9C),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      debugPrint('Error al subir foto: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error al subir la foto. Intenta de nuevo.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      setState(() => _fotoLocal = null);
    } finally {
      if (mounted) setState(() => _subiendoFoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // 🔥 Timestamp global — se actualiza en _pickImage y reconstruye este widget
    final imageTimestamp = ref.watch(profileImageTimestampProvider);

    ref.listen(authProvider, (_, current) {
      current.whenOrNull(
        unauthenticated: () {
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }
        },
      );
    });

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      body: authState.maybeWhen(
        authenticated: (user) => CustomScrollView(
          slivers: [
            // ── AppBar ───────────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              floating: false,
              backgroundColor: AppColors.primaryNavy,
              elevation: 0,
              automaticallyImplyLeading: false,
              toolbarHeight: kToolbarHeight,
              title: Text('Mi perfil',
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  )),
              centerTitle: true,
            ),

            // ── Foto + nombre + número de socio ─────────────────────
            SliverToBoxAdapter(
              child: Container(
                color: const Color(0xFFEEF2F5),
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    // Avatar clickeable
                    GestureDetector(
                      onTap: () => _cambiarFoto(context),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundColor: AppColors.borderLight,
                            child: ClipOval(
                              child: _subiendoFoto
                                  ? const SizedBox(
                                      width: 88,
                                      height: 88,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: AppColors.primaryNavy,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : _fotoLocal != null
                                      // Vista previa local mientras sube
                                      ? Image.file(_fotoLocal!,
                                          width: 88,
                                          height: 88,
                                          fit: BoxFit.cover)
                                      // Foto del servidor con timestamp global
                                      : user.profileImage != null &&
                                              user.profileImage!.isNotEmpty
                                          ? Image.network(
                                              '${user.profileImage}?t=$imageTimestamp',
                                              width: 88,
                                              height: 88,
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
                                                return const Center(
                                                  child: SizedBox(
                                                    width: 30,
                                                    height: 30,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                                  ),
                                                );
                                              },
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Text(
                                                  user.name.isNotEmpty
                                                      ? user.name[0]
                                                          .toUpperCase()
                                                      : '?',
                                                  style: AppTypography
                                                      .headlineMedium
                                                      .copyWith(
                                                          color: AppColors
                                                              .primaryNavy),
                                                );
                                              },
                                            )
                                          // Sin foto — inicial del nombre
                                          : Text(
                                              user.name.isNotEmpty
                                                  ? user.name[0].toUpperCase()
                                                  : '?',
                                              style: AppTypography
                                                  .headlineMedium
                                                  .copyWith(
                                                      color: AppColors
                                                          .primaryNavy),
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
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt_rounded,
                                  color: Colors.white, size: 13),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(user.name,
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w700,
                        )),

                    const SizedBox(height: 6),

                    ref.watch(socioDetalleProvider).when(
                          loading: () => Container(
                            height: 20,
                            width: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          error: (_, __) => Text('Socio #------',
                              style: AppTypography.bodySmall
                                  .copyWith(color: AppColors.supportMedium)),
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
                                  socio['estado'] == 'activo'
                                      ? 'Activo'
                                      : 'Inactivo',
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

            // ── Contenido ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle('Información personal'),
                    const SizedBox(height: 10),
                    _OptionTile(
                      icono: Icons.person_outline_rounded,
                      titulo: 'Datos personales',
                      subtitulo: 'Consulta edita tus datos personales',
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DatosPersonalesScreen(),
                          ),
                        );

                        if (result == true) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                  'Datos actualizados correctamente'),
                              backgroundColor: const Color(0xFF1ABC9C),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                    _OptionTile(
                      icono: Icons.description_outlined,
                      titulo: 'Documentos',
                      subtitulo: 'Consulta, actualiza y sube tus documentos',
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DocumentosScreen(),
                          ),
                        );

                        if (result == true) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                  'Documentos actualizados correctamente'),
                              backgroundColor: const Color(0xFF1ABC9C),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                    _OptionTile(
                      icono: Icons.storefront_outlined,
                      titulo: 'Mis puntos Genera',
                      subtitulo:
                          'Consulta y visualiza tus puntos acumulados para obtener recompensas',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PuntosScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    _SectionTitle('Credencial digital'),
                    const SizedBox(height: 10),
                    const DigitalCredentialCard(),
                    const SizedBox(height: 24),
                    _SectionTitle('Beneficiarios'),
                    const SizedBox(height: 10),
                    const _BeneficiariosWidget(),
                    const SizedBox(height: 24),
                    _SectionTitle('Cuenta'),
                    const SizedBox(height: 10),
                    _OptionTile(
                      icono: Icons.pause_circle_outline,
                      titulo: 'Desactivar cuenta',
                      subtitulo: 'Pausar acceso temporalmente',
                      iconColor: AppColors.error,
                      textColor: AppColors.error,
                      onTap: () => _showDeactivateDialog(context),
                    ),
                    _OptionTile(
                      icono: Icons.delete_outline,
                      titulo: 'Eliminar cuenta',
                      subtitulo: 'Acción permanente',
                      iconColor: AppColors.error,
                      textColor: AppColors.error,
                      onTap: () => _showDeleteDialog(context),
                    ),
                    _OptionTile(
                      icono: Icons.logout_rounded,
                      titulo: 'Cerrar Sesión',
                      subtitulo: null,
                      iconColor: AppColors.error,
                      textColor: AppColors.error,
                      onTap: () => _showLogoutDialog(context),
                    ),
                    const SizedBox(height: 32),
                  ],
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.05, end: 0),
              ),
            ),
          ],
        ),
        orElse: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  // ── Diálogos ───────────────────────────────────────────────────────────────

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon:
            const Icon(Icons.logout_rounded, color: AppColors.error, size: 32),
        title: Text('¿Cerrar Sesión?',
            style:
                AppTypography.titleMedium.copyWith(color: AppColors.textDark)),
        content: Text('¿Estás seguro de que deseas cerrar sesión?',
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.supportMedium)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authProvider.notifier).logout();
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  void _showDeactivateDialog(BuildContext context) {
    _showAccountActionDialog(
      context: context,
      title: '¿Desactivar cuenta?',
      message:
          'Tu cuenta quedará inactiva y no podrás iniciar sesión hasta reactivarla.',
      confirmLabel: 'Desactivar',
      icon: Icons.pause_circle_outline,
      successMessage: 'Cuenta desactivada exitosamente',
      action: (password) =>
          ref.read(authProvider.notifier).deactivateAccount(password),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    _showAccountActionDialog(
      context: context,
      title: '¿Eliminar cuenta?',
      message:
          'Esta acción es permanente. Se eliminará tu cuenta y tus sesiones.',
      confirmLabel: 'Eliminar',
      icon: Icons.delete_outline,
      successMessage: 'Cuenta eliminada exitosamente',
      action: (password) =>
          ref.read(authProvider.notifier).deleteAccount(password),
    );
  }

  void _showAccountActionDialog({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmLabel,
    required IconData icon,
    required String successMessage,
    required Future<String?> Function(String password) action,
  }) {
    final controller = TextEditingController();
    var obscure = true;
    var isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          icon: Icon(icon, color: AppColors.error, size: 32),
          title: Text(title,
              style: AppTypography.titleMedium
                  .copyWith(color: AppColors.textDark)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message,
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.supportMedium)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                obscureText: obscure,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  suffixIcon: IconButton(
                    icon:
                        Icon(obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => obscure = !obscure),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: isLoading || controller.text.isEmpty
                  ? null
                  : () async {
                      setState(() => isLoading = true);
                      final error = await action(controller.text);
                      if (!dialogContext.mounted) return;
                      if (error != null) {
                        setState(() => isLoading = false);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(error),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }
                      Navigator.pop(dialogContext);
                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AccountActionSuccessScreen(
                            title: successMessage,
                            subtitle:
                                'Serás redirigido a la pantalla de inicio de sesión.',
                            icon: icon,
                            iconColor: AppColors.error,
                          ),
                        ),
                      );
                    },
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(confirmLabel),
            ),
          ],
        ),
      ),
    ).then((_) => controller.dispose());
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// OPCIÓN DE FOTO
// ═══════════════════════════════════════════════════════════════════════════════

class _OpcionFoto extends StatelessWidget {
  final IconData icono;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _OpcionFoto({
    required this.icono,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primaryNavy;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icono, color: c, size: 20),
            ),
            const SizedBox(width: 14),
            Text(label,
                style: AppTypography.bodyMedium.copyWith(
                  color: c,
                  fontWeight: FontWeight.w500,
                )),
            const Spacer(),
            Icon(Icons.chevron_right_rounded,
                color: c.withValues(alpha: 0.5), size: 20),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// BENEFICIARIOS
// ═══════════════════════════════════════════════════════════════════════════════

class _BeneficiariosWidget extends ConsumerWidget {
  const _BeneficiariosWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final benefAsync = ref.watch(beneficiariosProvider);

    return benefAsync.when(
      loading: () => Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: CircularProgressIndicator(
              color: AppColors.primaryNavy, strokeWidth: 2),
        ),
      ),
      error: (_, __) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text('No se pudieron cargar los beneficiarios',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.supportMedium)),
      ),
      data: (beneficiarios) {
        if (beneficiarios.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text('No tienes beneficiarios registrados',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.supportMedium)),
          );
        }

        return Container(
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
            children: beneficiarios.asMap().entries.map((entry) {
              final i = entry.key;
              final ben = entry.value;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 70,
                          child: Text(
                            ben['parentesco']?.toString() ?? '',
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.supportMedium),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            ben['nombre_completo']?.toString() ?? '',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (ben['porcentaje'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primaryNavy.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${ben['porcentaje']}%',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.primaryNavy,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (i < beneficiarios.length - 1)
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
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGETS PRIVADOS
// ═══════════════════════════════════════════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: AppTypography.titleSmall.copyWith(
          color: AppColors.textDark,
          fontWeight: FontWeight.w700,
        ));
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String? subtitulo;
  final Color? iconColor;
  final Color? textColor;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icono,
    required this.titulo,
    this.subtitulo,
    this.iconColor,
    this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDestructive = textColor == AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isDestructive
                ? AppColors.error.withValues(alpha: 0.08)
                : const Color(0xFFB6CDE4).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icono, color: iconColor ?? AppColors.textDark, size: 22),
        ),
        title: Text(titulo,
            style: AppTypography.bodyMedium.copyWith(
              color: textColor ?? AppColors.textDark,
              fontWeight: FontWeight.w600,
            )),
        subtitle: subtitulo != null
            ? Text(subtitulo!,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.supportMedium))
            : null,
        trailing: Icon(Icons.chevron_right_rounded,
            color: AppColors.supportMedium, size: 20),
        onTap: onTap,
      ),
    );
  }
}
