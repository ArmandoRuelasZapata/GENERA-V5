import 'package:flutter/material.dart';
import 'package:theoriginallab_v2/core/theme/app_colors.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';

/// AuthTextField — GENERA
///
/// Campo de texto para formularios de autenticación.
/// Paleta institucional GENERA (azul/blanco) con soporte para Black (negro/dorado).
class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool isPassword;
  final bool isPasswordVisible;
  final VoidCallback? onVisibilityToggle;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final bool isBlackTheme;
  // Restaurado para compatibilidad con verify_code_screen y otros
  final TextAlign textAlign;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.isPassword = false,
    this.isPasswordVisible = false,
    this.onVisibilityToggle,
    this.validator,
    this.textInputAction,
    this.isBlackTheme = false,
    this.textAlign = TextAlign.start,
  });

  Color get _fillColor => isBlackTheme
      ? const Color(0xFF111111)
      : const Color(0xFF0A2550);

  Color get _focusColor => isBlackTheme
      ? AppColors.goldAccent
      : AppColors.accentCyan;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !isPasswordVisible,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textAlign: textAlign,
      validator: validator,
      style: AppTypography.bodyMedium.copyWith(color: Colors.white),
      cursorColor: _focusColor,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTypography.labelMedium.copyWith(
          color: Colors.white54,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: _fillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _focusColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.errorLight.withValues(alpha: 0.8),
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.errorLight, width: 2),
        ),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        suffixIcon: isPassword
            ? IconButton(
                onPressed: onVisibilityToggle,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    isPasswordVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    key: ValueKey<bool>(isPasswordVisible),
                    color: Colors.white38,
                    size: 20,
                  ),
                ),
              )
            : null,
        errorStyle: AppTypography.labelSmall.copyWith(
          color: AppColors.errorLight,
        ),
      ),
    );
  }
}