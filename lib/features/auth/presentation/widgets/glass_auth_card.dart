import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_colors.dart';

/// GlassAuthCard — GENERA
///
/// Card con efecto glassmorphism para formularios de auth.
/// Versión estándar: azul semitransparente con borde celeste sutil.
/// Versión Black:    negro semitransparente con borde dorado sutil.
class GlassAuthCard extends StatelessWidget {
  final Widget child;
  final double padding;
  final bool isBlackTheme;

  const GlassAuthCard({
    super.key,
    required this.child,
    this.padding = 28.0,
    this.isBlackTheme = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: isBlackTheme
                ? const Color(0xFF1C1C1C).withValues(alpha: 0.85)
                : const Color(0xFF0D2E5C).withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isBlackTheme
                  ? AppColors.goldAccent.withValues(alpha: 0.30)
                  : AppColors.accentCyan.withValues(alpha: 0.25),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isBlackTheme
                    ? Colors.black.withValues(alpha: 0.50)
                    : Colors.black.withValues(alpha: 0.30),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}