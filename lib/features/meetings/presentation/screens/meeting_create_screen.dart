import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:theoriginallab_v2/core/theme/app_colors.dart';
import 'package:theoriginallab_v2/core/theme/app_spacing.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';
import '../../../../shared/widgets/tol_loader.dart';
import '../../domain/entities/meeting_request.dart';
import '../providers/meetings_provider.dart';

class MeetingCreateScreen extends ConsumerStatefulWidget {
  const MeetingCreateScreen({super.key});

  @override
  ConsumerState<MeetingCreateScreen> createState() =>
      _MeetingCreateScreenState();
}

class _MeetingCreateScreenState extends ConsumerState<MeetingCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  MeetingTopic _selectedTopic = MeetingTopic.projectReview;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: isDark
              ? ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: AppColors.accentCyan,
                    onPrimary: AppColors.primaryNavy,
                    surface: AppColors.surfaceDarkElevated,
                  ),
                )
              : ThemeData.light(),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: isDark
              ? ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: AppColors.accentCyan,
                    onPrimary: AppColors.primaryNavy,
                    surface: AppColors.surfaceDarkElevated,
                  ),
                )
              : ThemeData.light(),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null || _selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor selecciona fecha y hora')),
        );
        return;
      }

      ref.read(createMeetingProvider.notifier).createMeeting(
            topic: _selectedTopic,
            date: _selectedDate!,
            time: _selectedTime!,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createMeetingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Listen for success
    ref.listen(createMeetingProvider, (previous, next) {
      if (!next.isLoading && !next.hasError && previous?.isLoading == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitud de reunión enviada'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendar Reunión'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Programa una sesión',
                    style: AppTypography.headlineMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selecciona un tema y horario para reunirte con un experto.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.largePadding),

                  // Topic Dropdown
                  _buildLabel('Tema de la Reunión'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<MeetingTopic>(
                    initialValue: _selectedTopic,
                    decoration: _inputDecoration(context, 'Selecciona un tema'),
                    items: MeetingTopic.values.map((topic) {
                      return DropdownMenuItem(
                        value: topic,
                        child: Text(topic.label),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedTopic = val);
                    },
                  ),
                  const SizedBox(height: AppSpacing.mediumGap),

                  // Date Picker Card
                  _buildLabel('Fecha'),
                  const SizedBox(height: 8),
                  _buildSelectionCard(
                    context: context,
                    icon: Icons.calendar_today,
                    text: _selectedDate == null
                        ? 'Seleccionar Fecha'
                        : DateFormat('EEEE d, MMMM y', 'es')
                            .format(_selectedDate!),
                    onTap: state.isLoading ? null : _pickDate,
                    isDark: isDark,
                  ),
                  const SizedBox(height: AppSpacing.mediumGap),

                  // Time Picker Card
                  _buildLabel('Hora'),
                  const SizedBox(height: 8),
                  _buildSelectionCard(
                    context: context,
                    icon: Icons.access_time,
                    text: _selectedTime == null
                        ? 'Seleccionar Hora'
                        : _selectedTime!.format(context),
                    onTap: state.isLoading ? null : _pickTime,
                    isDark: isDark,
                  ),
                  const SizedBox(height: AppSpacing.xlPadding),

                  // Submit Button
                  FilledButton(
                    onPressed: state.isLoading ? null : _submit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.accentCyan,
                      foregroundColor: AppColors.primaryNavy,
                    ),
                    child: state.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Solicitar Reunión'),
                  ),
                ],
              ),
            ),
          ),
          if (state.isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black12,
                child: const Center(child: TolLoader()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectionCard({
    required BuildContext context,
    required IconData icon,
    required String text,
    required VoidCallback? onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDarkElevated : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.accentCyan),
            const SizedBox(width: 12),
            Text(
              text,
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTypography.labelLarge.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String hint) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      filled: true,
      fillColor: isDark ? AppColors.surfaceDarkElevated : Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
