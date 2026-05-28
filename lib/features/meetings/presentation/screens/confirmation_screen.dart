import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/booking_provider.dart';
import '../../../home/presentation/screens/main_screen.dart';
import '../../../../shared/providers/providers.dart';

import '../../../../shared/widgets/app_animated_background.dart';

class ConfirmationScreen extends ConsumerStatefulWidget {
  const ConfirmationScreen({super.key});

  @override
  ConsumerState<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends ConsumerState<ConfirmationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill with auth data
    final authState = ref.read(authProvider);
    authState.whenOrNull(
      authenticated: (user) {
        _nameController.text = user.name;
        _emailController.text = user.email;
        if (user.phone != null && user.phone!.isNotEmpty) {
          _phoneController.text = user.phone!;
        }
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  IconData _getIconForService(String? name) {
    if (name == null) return Icons.event;
    final lowerName = name.toLowerCase();
    if (lowerName.contains('incubación')) return Icons.lightbulb_outline;
    if (lowerName.contains('consultoría')) return Icons.support_agent;
    if (lowerName.contains('desarrollo')) return Icons.cloud_outlined;
    if (lowerName.contains('capacitación')) return Icons.school_outlined;
    if (lowerName.contains('outsourcing')) return Icons.people_outline;
    if (lowerName.contains('alianzas')) return Icons.handshake_outlined;
    if (lowerName.contains('personalizado') || lowerName.contains('otro')) {
      return Icons.edit_note_outlined;
    }
    return Icons.design_services_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingNotifierProvider);
    final service = bookingState.selectedService;
    final slot = bookingState.selectedTimeSlot;

    // Formatting date for display: "Martes, 10 de Febrero"
    final dateStr = slot != null
        ? DateFormat('EEEE, d \'de\' MMMM', 'es')
            .format(slot.startTime)
            .replaceFirstMapped(
                RegExp(r'^\w'), (match) => match.group(0)!.toUpperCase())
        : '';

    final timeStr = slot != null
        ? '${slot.startTime.hour.toString().padLeft(2, '0')}:${slot.startTime.minute.toString().padLeft(2, '0')}'
        : '';

    // Service name display
    final serviceName = service?.id == 'custom'
        ? bookingState.customInterest ?? 'Consulta personalizada'
        : service?.name ?? 'Servicio';

    return AppAnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Revisar y Confirmar'),
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.white,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Appointment Summary Card
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.borderDark),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header Section
                    Container(
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDarkElevated,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16.r),
                          topRight: Radius.circular(16.r),
                        ),
                        border: const Border(
                            bottom: BorderSide(
                                color: AppColors.borderDark, width: 0.5)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getIconForService(service?.name),
                            color: AppColors.accentCyan,
                            size: 32.w,
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  serviceName,
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  'Confirma tus datos y agenda',
                                  style: TextStyle(
                                    color: AppColors.supportMedium,
                                    fontSize: 13.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Body Section
                    Padding(
                      padding: EdgeInsets.all(20.w),
                      child: Column(
                        children: [
                          _buildRow('Fecha', dateStr),
                          SizedBox(height: 12.h),
                          _buildRow('Hora', timeStr),
                          SizedBox(height: 12.h),
                          _buildRow('Duración',
                              '${service?.durationMinutes ?? 60} min'),
                          SizedBox(height: 12.h),
                          const Divider(
                              color: AppColors.borderDark, height: 24),
                          _buildRow('Costo', 'Gratuito', isHighlighted: true),
                        ],
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fade(duration: 600.ms)
                  .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),

              SizedBox(height: 24.h),

              // 2. Contact Information Fields
              Text(
                'Tus Datos de Contacto',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              )
                  .animate()
                  .fade(duration: 600.ms, delay: 100.ms)
                  .slideX(begin: -0.1, end: 0),

              SizedBox(height: 12.h),

              // Name Field
              _buildTextField(
                controller: _nameController,
                label: 'Nombre completo *',
                icon: Icons.person_outline,
                delay: 150,
              ),
              SizedBox(height: 12.h),

              // Email Field
              _buildTextField(
                controller: _emailController,
                label: 'Correo electrónico *',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                delay: 200,
              ),
              SizedBox(height: 12.h),

              // Phone Field
              _buildTextField(
                controller: _phoneController,
                label: 'Teléfono (opcional)',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                delay: 250,
              ),
              SizedBox(height: 12.h),

              // Notes Field
              _buildTextField(
                controller: _notesController,
                label: 'Notas adicionales (opcional)',
                icon: Icons.notes_outlined,
                maxLines: 2,
                delay: 300,
              ),

              SizedBox(height: 24.h),

              // 3. Microcopy
              Center(
                child: Text(
                  'Recibirás un correo de confirmación\ncon los detalles de tu cita.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.supportMedium,
                    fontSize: 12.sp,
                  ),
                ),
              ).animate().fade(duration: 600.ms, delay: 350.ms),

              SizedBox(height: 16.h),

              // 4. Confirm Button
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentCyan,
                    foregroundColor: const Color(0xFF021024),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 4,
                  ),
                  onPressed: bookingState.isLoading
                      ? null
                      : () async {
                          final name = _nameController.text.trim();
                          final email = _emailController.text.trim();
                          final phone = _phoneController.text.trim();
                          final notes = _notesController.text.trim();

                          if (name.isEmpty || email.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Por favor completa tu nombre y correo.'),
                                backgroundColor: Colors.orangeAccent,
                              ),
                            );
                            return;
                          }

                          final success = await ref
                              .read(bookingNotifierProvider.notifier)
                              .confirmBooking(
                                name: name,
                                email: email,
                                phone: phone.isNotEmpty ? phone : null,
                                notes: notes.isNotEmpty ? notes : null,
                              );

                          if (context.mounted) {
                            if (success) {
                              _showSuccessDialog(context, ref);
                            } else {
                              final error =
                                  ref.read(bookingNotifierProvider).error;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      error ?? 'Error al agendar la cita.'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        },
                  child: bookingState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.baseDark))
                      : Text(
                          'Confirmar Cita',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              )
                  .animate()
                  .fade(duration: 600.ms, delay: 400.ms)
                  .scale(delay: 400.ms),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    int delay = 0,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: AppColors.white),
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.supportMedium),
        prefixIcon: Icon(icon, color: AppColors.accentCyan, size: 20),
        filled: true,
        fillColor: AppColors.surfaceDark,
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.accentCyan),
        ),
      ),
    ).animate().fade(duration: 500.ms, delay: delay.ms);
  }

  void _showSuccessDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surfaceDark,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: AppColors.accentCyan, size: 80.w),
              SizedBox(height: 16.h),
              Text(
                '¡Cita Agendada!',
                style: TextStyle(
                    color: AppColors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.h),
              Text(
                'Tu cita ha sido confirmada con éxito.\nRecibirás un correo de confirmación.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: AppColors.supportMedium, fontSize: 14.sp),
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentCyan,
                    foregroundColor: AppColors.baseDark,
                  ),
                  onPressed: () {
                    ref.read(bookingNotifierProvider.notifier).reset();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const MainScreen()),
                      (route) => false,
                    );
                  },
                  child: const Text('Volver al Inicio',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.supportMedium,
            fontSize: 14.sp,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isHighlighted ? AppColors.accentCyan : AppColors.white,
            fontSize: isHighlighted ? 16.sp : 14.sp,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
