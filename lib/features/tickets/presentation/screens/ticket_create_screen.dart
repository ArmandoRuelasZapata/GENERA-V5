import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theoriginallab_v2/core/theme/app_colors.dart';
import 'package:theoriginallab_v2/core/theme/app_spacing.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';
import 'package:theoriginallab_v2/core/validators/app_validators.dart';
import '../../../../shared/widgets/tol_loader.dart';
import '../../domain/entities/ticket.dart';
import '../providers/tickets_provider.dart';

class TicketCreateScreen extends ConsumerStatefulWidget {
  const TicketCreateScreen({super.key});

  @override
  ConsumerState<TicketCreateScreen> createState() => _TicketCreateScreenState();
}

class _TicketCreateScreenState extends ConsumerState<TicketCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  TicketCategory _selectedCategory = TicketCategory.app;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ref.read(createTicketProvider.notifier).createTicket(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            category: _selectedCategory,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createTicketProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Listen for success or error
    ref.listen(createTicketProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: Colors.red,
          ),
        );
      } else if (!next.isLoading &&
          !next.hasError &&
          previous?.isLoading == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ticket creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Ticket'),
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
                    'Detalles del Requerimiento',
                    style: AppTypography.headlineMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Completa la información para que nuestro equipo pueda ayudarte rápidamente.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.largePadding),

                  // Category Dropdown
                  _buildLabel('Categoría'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<TicketCategory>(
                    initialValue: _selectedCategory,
                    decoration:
                        _inputDecoration(context, 'Selecciona una categoría'),
                    items: TicketCategory.values.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat.label),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: AppSpacing.mediumGap),

                  // Title Input
                  _buildLabel('Asunto'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleController,
                    maxLength: AppValidators.maxTicketTitleLength,
                    decoration: _inputDecoration(
                        context, 'Ej. Error en inicio de sesión'),
                    validator: AppValidators.ticketTitle,
                  ),
                  const SizedBox(height: AppSpacing.mediumGap),

                  // Description Input
                  _buildLabel('Descripción Detallada'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 5,
                    maxLength: AppValidators.maxTicketDescLength,
                    decoration: _inputDecoration(
                        context, 'Describe tu problema o solicitud...'),
                    validator: AppValidators.ticketDescription,
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
                        : const Text('Enviar Ticket'),
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
      hintText: hint,
      filled: true,
      fillColor: isDark ? AppColors.surfaceDarkElevated : Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accentCyan, width: 2),
      ),
    );
  }
}
