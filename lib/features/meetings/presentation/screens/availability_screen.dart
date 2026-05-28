import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/booking_provider.dart';
import '../providers/meetings_provider.dart';
import '../../domain/entities/time_slot.dart';
import 'confirmation_screen.dart';

import '../../../../shared/widgets/app_animated_background.dart';

class AvailabilityScreen extends ConsumerStatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  ConsumerState<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends ConsumerState<AvailabilityScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingNotifierProvider);
    final selectedService = bookingState.selectedService;

    // Fetch real time slots from the webhook
    final timeSlotsAsync = ref.watch(timeSlotsProvider(_selectedDay!));

    return AppAnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Seleccionar Fecha y Hora'),
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.white,
        ),
        body: Column(
          children: [
            // Quick Summary Header
            if (selectedService != null)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark.withValues(alpha: 0.5),
                  border: const Border(
                      bottom: BorderSide(color: AppColors.borderDark)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bookmark_border,
                        color: AppColors.accentCyan, size: 20),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'Agendando: ',
                          style: TextStyle(
                              color: AppColors.supportMedium, fontSize: 13.sp),
                          children: [
                            TextSpan(
                              text:
                                  '${selectedService.name} - ${selectedService.durationMinutes} min',
                              style: const TextStyle(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Calendar and Slots
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCalendar()
                        .animate()
                        .fade(duration: 600.ms)
                        .slideY(begin: -0.1, end: 0, curve: Curves.easeOutQuad),

                    SizedBox(height: 24.h),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Text(
                        'Horarios Disponibles',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                        .animate()
                        .fade(duration: 600.ms, delay: 200.ms)
                        .slideX(begin: -0.1, end: 0),

                    SizedBox(height: 16.h),

                    timeSlotsAsync.when(
                      data: (timeSlots) => _buildTimeSlots(timeSlots),
                      loading: () => Padding(
                        padding: EdgeInsets.all(32.w),
                        child: const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.accentCyan)),
                      ),
                      error: (err, stack) => Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Text(
                          'Error al cargar horarios: $err',
                          style: TextStyle(
                              color: Colors.redAccent, fontSize: 14.sp),
                        ),
                      ),
                    ),

                    SizedBox(height: 100.h), // Spacing for scrollable area
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          padding: EdgeInsets.all(16.w),
          decoration: const BoxDecoration(
            color: AppColors.baseDark,
            border: Border(top: BorderSide(color: AppColors.borderDark)),
          ),
          child: SizedBox(
            height: 50.h,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                // Active: Cyan, Inactive: Surface/Grey
                backgroundColor: bookingState.selectedTimeSlot != null
                    ? AppColors.accentCyan
                    : AppColors.surfaceDark,
                // Active: Dark Text (high contrast), Inactive: Support/Grey Text
                foregroundColor: bookingState.selectedTimeSlot != null
                    ? const Color(0xFF021024) // Dark text on Cyan
                    : AppColors.supportMedium,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: bookingState.selectedTimeSlot != null ? 2 : 0,
              ),
              onPressed: bookingState.selectedTimeSlot != null
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const ConfirmationScreen()),
                      );
                    }
                  : null,
              child: Text(
                'Continuar',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return TableCalendar(
      locale: 'es_ES',
      firstDay: DateTime.now(),
      lastDay: DateTime.now().add(const Duration(days: 60)),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
        ref.read(bookingNotifierProvider.notifier).selectDate(selectedDay);
      },
      calendarFormat: CalendarFormat.twoWeeks,
      headerStyle: HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false,
        titleTextStyle: TextStyle(
          color: AppColors.white,
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
        ),
        leftChevronIcon:
            const Icon(Icons.chevron_left, color: AppColors.white, size: 28),
        rightChevronIcon:
            const Icon(Icons.chevron_right, color: AppColors.white, size: 28),
        leftChevronPadding: EdgeInsets.all(12.w),
        rightChevronPadding: EdgeInsets.all(12.w),
      ),
      daysOfWeekStyle: const DaysOfWeekStyle(
        weekdayStyle: TextStyle(
            color: AppColors.supportMedium, fontWeight: FontWeight.bold),
        weekendStyle: TextStyle(
            color: AppColors.supportMedium, fontWeight: FontWeight.bold),
      ),
      calendarStyle: CalendarStyle(
        defaultTextStyle: const TextStyle(color: AppColors.white),
        weekendTextStyle: const TextStyle(color: AppColors.white),
        outsideTextStyle:
            TextStyle(color: AppColors.white.withValues(alpha: 0.3)),
        selectedDecoration: const BoxDecoration(
          color: AppColors.accentCyan,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: AppColors.accentCyan.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        selectedTextStyle: const TextStyle(
          color: AppColors.baseDark,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTimeSlots(List<TimeSlot> slots) {
    if (slots.isEmpty) {
      return Center(
        child: Text(
          'No hay horarios disponibles para este día.',
          style: TextStyle(color: AppColors.supportMedium, fontSize: 14.sp),
        ),
      );
    }

    final bookingState = ref.watch(bookingNotifierProvider);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Wrap(
        spacing: 12.w,
        runSpacing: 12.h,
        children: slots.asMap().entries.map((entry) {
          final index = entry.key;
          final slot = entry.value;
          final isSelected = bookingState.selectedTimeSlot == slot;
          final isAvailable = slot.isAvailable;
          final timeStr =
              "${slot.startTime.hour.toString().padLeft(2, '0')}:${slot.startTime.minute.toString().padLeft(2, '0')}";

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isAvailable
                  ? () {
                      ref
                          .read(bookingNotifierProvider.notifier)
                          .selectTimeSlot(slot);
                    }
                  : null,
              borderRadius: BorderRadius.circular(8.r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                decoration: BoxDecoration(
                  // Background Color Logic
                  color: isSelected
                      ? AppColors.accentCyan // Solid Cyan when selected
                      : isAvailable
                          ? Colors.transparent // Transparent when available
                          : const Color(
                              0xFF1E293B), // Dark Gray when unavailable
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.accentCyan
                        : isAvailable
                            ? AppColors.accentCyan // Cyan Border for available
                            : Colors.transparent,
                    width:
                        isAvailable ? 1.5 : 1.0, // Thicker border for available
                  ),
                ),
                child: Text(
                  timeStr,
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFF021024) // Dark text on Cyan
                        : isAvailable
                            ? AppColors.white
                            : AppColors.supportMedium,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    decoration:
                        !isAvailable ? TextDecoration.lineThrough : null,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
          )
              .animate()
              .fade(duration: 400.ms, delay: (300 + (50 * index)).ms)
              .scale(delay: (300 + (50 * index)).ms);
        }).toList(),
      ),
    );
  }
}
