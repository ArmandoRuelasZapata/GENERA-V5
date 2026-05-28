import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/booking_provider.dart';
import '../../domain/entities/service_entity.dart';
import 'availability_screen.dart';
import 'my_appointments_screen.dart';

import '../../../../shared/widgets/app_animated_background.dart';

class ServiceSelectionScreen extends ConsumerStatefulWidget {
  const ServiceSelectionScreen({super.key});

  @override
  ConsumerState<ServiceSelectionScreen> createState() =>
      _ServiceSelectionScreenState();
}

class _ServiceSelectionScreenState
    extends ConsumerState<ServiceSelectionScreen> {
  final TextEditingController _customController = TextEditingController();

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(servicesProvider);

    return AppAnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Agendar Cita'),
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.history, color: AppColors.white),
              tooltip: 'Mis Citas',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const MyAppointmentsScreen()),
                );
              },
            ),
          ],
        ),
        body: servicesAsync.when(
          data: (services) => ListView.separated(
            padding: EdgeInsets.all(16.w),
            itemCount: services.length,
            separatorBuilder: (_, __) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              final service = services[index];

              // "Personalizado" service gets special treatment
              if (service.id == 'custom') {
                return _CustomServiceCard(
                  service: service,
                  controller: _customController,
                  onTap: () {
                    final customText = _customController.text.trim();
                    if (customText.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Escribe en qué estás interesado para continuar.'),
                          backgroundColor: Colors.orangeAccent,
                        ),
                      );
                      return;
                    }
                    ref
                        .read(bookingNotifierProvider.notifier)
                        .selectService(service);
                    ref
                        .read(bookingNotifierProvider.notifier)
                        .setCustomInterest(customText);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const AvailabilityScreen()),
                    );
                  },
                )
                    .animate()
                    .fade(duration: 500.ms, delay: (100 * index).ms)
                    .slideX(begin: 0.1, end: 0, curve: Curves.easeOutQuad);
              }

              return _ServiceCard(
                service: service,
                onTap: () {
                  ref
                      .read(bookingNotifierProvider.notifier)
                      .selectService(service);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const AvailabilityScreen()),
                  );
                },
              )
                  .animate()
                  .fade(duration: 500.ms, delay: (100 * index).ms)
                  .slideX(begin: 0.1, end: 0, curve: Curves.easeOutQuad);
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final ServiceEntity service;
  final VoidCallback onTap;

  const _ServiceCard({required this.service, required this.onTap});

  IconData _getIconForService(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('incubación')) return Icons.lightbulb_outline;
    if (lowerName.contains('consultoría')) return Icons.support_agent;
    if (lowerName.contains('desarrollo')) return Icons.cloud_outlined;
    if (lowerName.contains('capacitación')) return Icons.school_outlined;
    if (lowerName.contains('outsourcing')) return Icons.people_outline;
    if (lowerName.contains('alianzas')) return Icons.handshake_outlined;
    return Icons.design_services_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        splashColor: AppColors.accentCyan.withValues(alpha: 0.1),
        highlightColor: AppColors.accentCyan.withValues(alpha: 0.05),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: AppColors.baseDark,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Icon(
                  _getIconForService(service.name),
                  color: AppColors.accentCyan,
                  size: 24.w,
                ),
              ),
              SizedBox(width: 16.w),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      service.description,
                      style: TextStyle(
                        color: AppColors.supportMedium,
                        fontSize: 13.sp,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.h),
                    // Duration & Free badge
                    Row(
                      children: [
                        Icon(Icons.schedule,
                            size: 14.w, color: AppColors.supportMedium),
                        SizedBox(width: 4.w),
                        Text(
                          '${service.durationMinutes} min',
                          style: TextStyle(
                            color: AppColors.supportMedium,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow
              const Icon(Icons.chevron_right, color: AppColors.accentCyan),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card for the "Otro / Personalizado" option with a text input field
class _CustomServiceCard extends StatelessWidget {
  final ServiceEntity service;
  final TextEditingController controller;
  final VoidCallback onTap;

  const _CustomServiceCard({
    required this.service,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: AppColors.baseDark,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Icon(
                  Icons.edit_note_outlined,
                  color: AppColors.accentCyan,
                  size: 24.w,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      service.description,
                      style: TextStyle(
                        color: AppColors.supportMedium,
                        fontSize: 13.sp,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: controller,
            style: const TextStyle(color: AppColors.white),
            decoration: InputDecoration(
              hintText: '¿En qué estás interesado?',
              hintStyle: const TextStyle(color: AppColors.supportMedium),
              filled: true,
              fillColor: AppColors.baseDark,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: const BorderSide(color: AppColors.borderDark),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: const BorderSide(color: AppColors.borderDark),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: const BorderSide(color: AppColors.accentCyan),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentCyan,
                foregroundColor: AppColors.baseDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              onPressed: onTap,
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('Continuar',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
