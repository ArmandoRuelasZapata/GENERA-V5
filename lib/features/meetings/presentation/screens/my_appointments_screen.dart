import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:theoriginallab_v2/core/theme/app_colors.dart';
import 'package:theoriginallab_v2/shared/widgets/app_animated_background.dart';
import '../providers/my_appointments_provider.dart';
import '../../domain/entities/appointment_entity.dart';

class MyAppointmentsScreen extends ConsumerWidget {
  const MyAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(myAppointmentsProvider);

    return AppAnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Mis Citas'),
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.white,
        ),
        body: appointmentsAsync.when(
          data: (appointments) {
            if (appointments.isEmpty) {
              return Center(
                child: Text(
                  'No tienes citas registradas.',
                  style: TextStyle(
                      color: AppColors.supportMedium, fontSize: 16.sp),
                ),
              );
            }

            // Split into Upcoming and History
            final upcoming = appointments
                .where((a) => a.status == 'upcoming')
                .toList()
              ..sort((a, b) => a.date.compareTo(b.date));

            final history = appointments
                .where((a) => a.status != 'upcoming')
                .toList()
              ..sort((a, b) => b.date.compareTo(a.date)); // Newest first

            return ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                if (upcoming.isNotEmpty) ...[
                  _buildSectionHeader('Próximas'),
                  SizedBox(height: 12.h),
                  ...upcoming.asMap().entries.map((entry) {
                    final index = entry.key;
                    final a = entry.value;
                    return _AppointmentCard(appointment: a)
                        .animate()
                        .fade(duration: 500.ms, delay: (100 * index).ms)
                        .slideX(begin: 0.1, end: 0, curve: Curves.easeOutQuad);
                  }),
                  SizedBox(height: 24.h),
                ],
                if (history.isNotEmpty) ...[
                  _buildSectionHeader('Historial'),
                  SizedBox(height: 12.h),
                  ...history.asMap().entries.map((entry) {
                    final index = entry.key;
                    final a = entry.value;
                    // Add a base delay if upcoming exists, or just stagger nicely
                    final delay = (upcoming.length * 100) + (100 * index);
                    return _AppointmentCard(appointment: a)
                        .animate()
                        .fade(duration: 500.ms, delay: delay.ms)
                        .slideX(begin: 0.1, end: 0, curve: Curves.easeOutQuad);
                  }),
                ],
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.accentCyan,
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentEntity appointment;

  const _AppointmentCard({required this.appointment});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'upcoming':
        return AppColors.accentCyan;
      case 'completed':
        return const Color(
            0xFF64B5F6); // Azul claro — coincide con MeetingStatus.completed
      case 'cancelled':
        return Colors.redAccent;
      default:
        return AppColors.supportMedium;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'upcoming':
        return 'Confirmada';
      case 'completed':
        return 'Realizada'; // ← Consistente con MeetingStatus.completed
      case 'cancelled':
        return 'Cancelada';
      default:
        return status;
    }
  }

  IconData _getServiceIcon(String name) {
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
    final isUpcoming = appointment.status == 'upcoming';
    final dateStr =
        DateFormat('EEE, d MMM yyyy', 'es').format(appointment.date);
    final timeStr = DateFormat('HH:mm').format(appointment.date);

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isUpcoming
              ? AppColors.accentCyan.withValues(alpha: 0.3)
              : AppColors.borderDark,
        ),
        boxShadow: isUpcoming
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      child: Column(
        children: [
          // Header (Date & Status)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: isUpcoming
                  ? AppColors.accentCyan.withValues(alpha: 0.1)
                  : AppColors.surfaceDarkElevated,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
              border: const Border(
                  bottom: BorderSide(color: AppColors.borderDark, width: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 14.sp, color: AppColors.supportMedium),
                    SizedBox(width: 6.w),
                    Text(
                      dateStr,
                      style: TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _getStatusColor(appointment.status)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4.r),
                    border: Border.all(
                        color: _getStatusColor(appointment.status)
                            .withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    _getStatusText(appointment.status),
                    style: TextStyle(
                      color: _getStatusColor(appointment.status),
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body (Service Info)
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: AppColors.baseDark,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: Icon(
                    _getServiceIcon(appointment.serviceName),
                    color: isUpcoming
                        ? AppColors.accentCyan
                        : AppColors.supportMedium,
                    size: 24.w,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.serviceName,
                        style: TextStyle(
                          color: isUpcoming
                              ? AppColors.white
                              : AppColors.supportMedium,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Hora: $timeStr',
                        style: TextStyle(
                          color: AppColors.supportMedium,
                          fontSize: 13.sp,
                        ),
                      ),
                      if (appointment.notes != null) ...[
                        SizedBox(height: 8.h),
                        Text(
                          'Nota: ${appointment.notes}',
                          style: TextStyle(
                            color:
                                AppColors.supportMedium.withValues(alpha: 0.7),
                            fontSize: 12.sp,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
