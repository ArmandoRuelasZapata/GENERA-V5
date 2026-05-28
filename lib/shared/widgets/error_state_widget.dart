import 'package:flutter/material.dart';
import 'package:theoriginallab_v2/core/theme/app_colors.dart';
import 'package:theoriginallab_v2/core/theme/app_spacing.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';

/// Reusable Error State Widget
class ErrorStateWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool isFullPage;

  const ErrorStateWidget({
    super.key,
    required this.message,
    required this.onRetry,
    this.isFullPage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: isFullPage ? null : 200,
      decoration: isFullPage
          ? null
          : BoxDecoration(
              color: AppColors.errorLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(
                  color: AppColors.errorLight.withValues(alpha: 0.3)),
            ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: AppColors.errorLight,
                size: isFullPage ? 64 : 48,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: isFullPage
                    ? AppTypography.titleMedium
                    : AppTypography.bodyMedium.copyWith(
                        color: AppColors.errorLight,
                      ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
