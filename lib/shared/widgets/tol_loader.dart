import 'package:flutter/material.dart';
import 'package:theoriginallab_v2/core/theme/app_colors.dart';

/// TOL Branded Loader
/// Custom loading indicator with glow effect
/// Uses brand colors (Teal/Cyan) for identity
class TolLoader extends StatefulWidget {
  final double size;
  final bool showLabel;
  final String? label;

  const TolLoader({
    super.key,
    this.size = 48.0,
    this.showLabel = false,
    this.label,
  });

  @override
  State<TolLoader> createState() => _TolLoaderState();
}

class _TolLoaderState extends State<TolLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentCyan.withValues(
                      alpha: _glowAnimation.value,
                    ),
                    blurRadius: 20 * _glowAnimation.value,
                    spreadRadius: 5 * _glowAnimation.value,
                  ),
                  BoxShadow(
                    color: AppColors.tertiaryTeal.withValues(
                      alpha: _glowAnimation.value * 0.6,
                    ),
                    blurRadius: 30 * _glowAnimation.value,
                    spreadRadius: 10 * _glowAnimation.value,
                  ),
                ],
              ),
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [AppColors.accentCyan, AppColors.tertiaryTeal],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        if (widget.showLabel) ...[
          const SizedBox(height: 16),
          Text(
            widget.label ?? 'Cargando...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );
  }
}

/// Simple spinning variant with gradient
class TolSpinner extends StatefulWidget {
  final double size;

  const TolSpinner({super.key, this.size = 24.0});

  @override
  State<TolSpinner> createState() => _TolSpinnerState();
}

class _TolSpinnerState extends State<TolSpinner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: RotationTransition(
        turns: _controller,
        child: const CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentCyan),
        ),
      ),
    );
  }
}
