import 'package:flutter/material.dart';
import 'package:theoriginallab_v2/core/theme/app_colors.dart';
import 'package:theoriginallab_v2/core/theme/app_spacing.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';

/// Standard Empty State Widget
/// Displays an icon/illustration, a message, and an optional CTA.
class AppEmptyWidget extends StatelessWidget {
  final String message;
  final String? subMessage;
  final IconData? icon;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final double iconSize;

  const AppEmptyWidget({
    super.key,
    required this.message,
    this.subMessage,
    this.icon,
    this.buttonText,
    this.onButtonPressed,
    this.iconSize = 80,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.largePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.accentCyan : AppColors.primaryNavy)
                    .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.inbox_rounded,
                size: iconSize,
                color: (isDark ? AppColors.accentCyan : AppColors.primaryNavy)
                    .withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: AppSpacing.mediumGap),
            Text(
              message,
              style: AppTypography.titleMedium.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (subMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                subMessage!,
                style: AppTypography.bodyMedium.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: AppSpacing.largeGap),
              FilledButton.icon(
                onPressed: onButtonPressed,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(buttonText!),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Standard Error State Widget
/// Refined version of the common error display.
class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final IconData icon;

  const AppErrorWidget({
    super.key,
    required this.message,
    required this.onRetry,
    this.icon = Icons.error_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.largePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.mediumGap),
            Text(
              'Algo salió mal',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.supportMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.largeGap),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Standard Loading State Widget
class AppLoadingState extends StatelessWidget {
  final String? message;

  const AppLoadingState({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentCyan),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.mediumGap),
            Text(
              message!,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.supportMedium,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
