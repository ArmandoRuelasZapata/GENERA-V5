import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:theoriginallab_v2/core/theme/app_colors.dart';
import 'package:theoriginallab_v2/core/theme/app_spacing.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';

/// Animated Chip with Bounce and Haptic Feedback
class AnimatedChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const AnimatedChip({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<AnimatedChip> createState() => _AnimatedChipState();
}

class _AnimatedChipState extends State<AnimatedChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.1,
    )..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
    HapticFeedback.lightImpact(); // Haptic feedback
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final scale = 1.0 - _controller.value * 0.2; // Bounds 1.0 -> 0.98

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: Transform.scale(
        scale: scale,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.cardPadding,
            vertical: AppSpacing.smallGap,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceDarkElevated
                : AppColors.primaryNavy.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            border: Border.all(
              color: isDark
                  ? AppColors.borderDarkSubtle
                  : Colors.black.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 20, color: AppColors.accentCyan),
              const SizedBox(width: AppSpacing.tinyGap),
              Text(
                widget.label,
                style: AppTypography.labelMedium.copyWith(
                  color: isDark ? AppColors.white : AppColors.primaryNavy,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
