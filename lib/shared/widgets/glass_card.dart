import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:theoriginallab_v2/core/theme/app_colors.dart';
import 'package:theoriginallab_v2/core/theme/app_spacing.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final double opacity;
  final double blur;
  final BorderRadius? borderRadius;
  final Color? color;
  final BoxBorder? border;
  final bool enableBlur;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
    this.opacity = 0.7,
    this.blur = 10.0,
    this.borderRadius,
    this.color,
    this.border,
    this.enableBlur = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final effectiveBorderRadius =
        borderRadius ?? BorderRadius.circular(AppSpacing.cardRadius);

    final cardChild = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: effectiveBorderRadius,
        child: Container(
          padding: padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: (color ?? (isDark ? AppColors.surfaceDark : AppColors.white))
                .withValues(alpha: opacity),
            borderRadius: effectiveBorderRadius,
            border: border ??
                Border.all(
                  color: (isDark ? Colors.white : AppColors.primaryNavy)
                      .withValues(alpha: 0.1),
                  width: 1,
                ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    return Container(
      margin: margin ?? EdgeInsets.zero,
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: effectiveBorderRadius,
        child: enableBlur
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: cardChild,
              )
            : cardChild,
      ),
    );
  }
}
