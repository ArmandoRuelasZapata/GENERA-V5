import 'package:flutter/material.dart';
import 'package:theoriginallab_v2/core/theme/app_colors.dart';
import 'package:theoriginallab_v2/core/theme/app_spacing.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';

class HomeQuickActions extends StatelessWidget {
  final VoidCallback onStoreTap;
  final VoidCallback onBookingTap;
  final VoidCallback onCoworkTap;
  final VoidCallback onSupportTap;

  const HomeQuickActions({
    super.key,
    required this.onStoreTap,
    required this.onBookingTap,
    required this.onCoworkTap,
    required this.onSupportTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildPillButton(
            context,
            icon: Icons.storefront_rounded,
            label: 'Tienda',
            onTap: onStoreTap,
            color: AppColors.primaryNavy,
          ),
          const SizedBox(width: 12),
          _buildPillButton(
            context,
            icon: Icons.work_outline_rounded,
            label: 'Cowork',
            onTap: onCoworkTap,
            color: AppColors.accentCyan,
          ),
          const SizedBox(width: 12),
          _buildPillButton(
            context,
            icon: Icons.calendar_month_rounded,
            label: 'Citas',
            onTap: onBookingTap,
            color: AppColors.primaryNavy,
          ),
          const SizedBox(width: 12),
          _buildPillButton(
            context,
            icon: Icons.support_agent_rounded,
            label: 'Soporte',
            onTap: onSupportTap,
            color: AppColors.tertiaryTeal,
          ),
        ],
      ),
    );
  }

  Widget _buildPillButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.accentCyan
                .withValues(alpha: 0.15), // Unified background style
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
                color: AppColors.accentCyan
                    .withValues(alpha: 0.5)), // Unified border (contour)
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
