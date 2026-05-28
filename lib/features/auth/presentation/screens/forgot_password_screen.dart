import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:theoriginallab_v2/core/theme/app_colors.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';
import 'package:theoriginallab_v2/shared/providers/providers.dart';

import 'verify_code_screen.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends ConsumerState<ForgotPasswordScreen> {
  final _formKey              = GlobalKey<FormState>();
  final _emailController      = TextEditingController();
  final _passwordController   = TextEditingController();
  final _confirmController    = TextEditingController();

  bool _isLoading             = false;
  bool _isPasswordVisible     = false;
  bool _isConfirmVisible      = false;

  // Barra de seguridad
  double get _passwordStrength {
    final p = _passwordController.text;
    if (p.isEmpty) return 0;
    double score = 0;
    if (p.length >= 8)  score += 0.25;
    if (p.length >= 12) score += 0.15;
    if (RegExp(r'[A-Z]').hasMatch(p))              score += 0.2;
    if (RegExp(r'[0-9]').hasMatch(p))              score += 0.2;
    if (RegExp(r'[!@#\$%^&*(),.?]').hasMatch(p))  score += 0.2;
    return score.clamp(0.0, 1.0);
  }

  Color get _strengthColor {
    final s = _passwordStrength;
    if (s < 0.35) return AppColors.error;
    if (s < 0.65) return AppColors.warning;
    return AppColors.successLight;
  }

  String get _strengthLabel {
    final s = _passwordStrength;
    if (s == 0)   return '';
    if (s < 0.35) return 'Débil';
    if (s < 0.65) return 'Regular';
    if (s < 0.85) return 'Buena';
    return 'Excelente';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final dataSource = ref.read(authRemoteDataSourceProvider);
      await dataSource.requestPasswordReset(_emailController.text.trim());

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                VerifyCodeScreen(email: _emailController.text.trim()),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Si el email existe, se envió un código de recuperación',
              style: AppTypography.bodySmall.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString(),
                style: AppTypography.bodySmall.copyWith(color: Colors.white)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // ── Botón atrás ────────────────────────────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: _CircleBackButton(),
                ),
              ),

              const SizedBox(height: 20),

              Column(
                children: [
                  Image.asset('assets/images/genera_logo_color.png',
                  width: 72,
                  fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 18),
                  Text('GENERA',
                  style: AppTypography.headlineLarge.copyWith(
                    color: AppColors.primaryNavy,
                    letterSpacing: 5,
                    fontWeight: FontWeight.w900,
                    ),
                  )
                ],
              ),

              const SizedBox(height: 24),

              // ── CARD BLANCA ────────────────────────────────────────
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título
                      Center(
                        child: Text(
                          'Restablecer contraseña',
                          style: AppTypography.headlineMedium.copyWith(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Email ──────────────────────────────────────
                      _FieldLabel('Email'),
                      const SizedBox(height: 6),
                      _LightTextField(
                        controller: _emailController,
                        hint: 'example@gmail.com',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Ingresa tu correo';
                          }
                          if (!v.contains('@')) {
                            return 'Ingresa un correo válido';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // ── Nueva Contraseña ───────────────────────────
                      _FieldLabel('Nueva Contraseña'),
                      const SizedBox(height: 6),
                      _LightTextField(
                        controller: _passwordController,
                        hint: '••••••••',
                        isPassword: true,
                        isPasswordVisible: _isPasswordVisible,
                        textInputAction: TextInputAction.next,
                        onVisibilityToggle: () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible),
                        onChanged: (_) => setState(() {}),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Ingresa tu nueva contraseña';
                          }
                          if (v.length < 8) {
                            return 'Mínimo 8 caracteres';
                          }
                          return null;
                        },
                      ),

                      // Barra de seguridad
                      if (_passwordController.text.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _PasswordStrengthBar(
                          strength: _passwordStrength,
                          color: _strengthColor,
                          label: _strengthLabel,
                        ),
                      ],

                      const SizedBox(height: 20),

                      // ── Confirmar contraseña ───────────────────────
                      _FieldLabel('Confirmar contraseña'),
                      const SizedBox(height: 6),
                      _LightTextField(
                        controller: _confirmController,
                        hint: '••••••••',
                        isPassword: true,
                        isPasswordVisible: _isConfirmVisible,
                        textInputAction: TextInputAction.done,
                        onVisibilityToggle: () => setState(
                            () => _isConfirmVisible = !_isConfirmVisible),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Confirma tu contraseña';
                          }
                          if (v != _passwordController.text) {
                            return 'Las contraseñas no coinciden';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 32),

                      // ── Botón Continuar ────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton(
                          onPressed: _isLoading ? null : _handleSubmit,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryNavy,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ).copyWith(
                            backgroundColor:
                                WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.disabled)) {
                                return AppColors.primaryNavy
                                    .withValues(alpha: 0.5);
                              }
                              return AppColors.primaryNavy;
                            }),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Continuar',
                                    style: AppTypography.labelLarge.copyWith(
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Volver al login ────────────────────────────
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '¿Recordaste tu contraseña? ',
                                  style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textDark),
                                ),
                                TextSpan(
                                  text: 'Inicia sesión',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.accentCyan,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Botón atrás circular
// ─────────────────────────────────────────────────────────────────────────────
class _CircleBackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (Navigator.canPop(context)) Navigator.pop(context);
      },
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.primaryNavy.withValues(alpha: 0.10),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.chevron_left_rounded,
          color: AppColors.primaryNavy,
          size: 26,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Etiqueta de campo
// ─────────────────────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.labelMedium.copyWith(color: AppColors.textDark),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Campo de texto claro
// ─────────────────────────────────────────────────────────────────────────────
class _LightTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? hint;
  final bool isPassword;
  final bool isPasswordVisible;
  final VoidCallback? onVisibilityToggle;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;

  const _LightTextField({
    required this.controller,
    this.hint,
    this.isPassword = false,
    this.isPasswordVisible = false,
    this.onVisibilityToggle,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !isPasswordVisible,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onChanged: onChanged,
      style: AppTypography.bodyMedium.copyWith(color: AppColors.textDark),
      cursorColor: AppColors.accentCyan,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.supportMedium.withValues(alpha: 0.6),
        ),
        filled: true,
        fillColor: const Color(0xFFF5F8FC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDDE3EC), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDDE3EC), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.accentCyan, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.errorLight, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.errorLight, width: 1.5),
        ),
        suffixIcon: isPassword
            ? IconButton(
                onPressed: onVisibilityToggle,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isPasswordVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    key: ValueKey(isPasswordVisible),
                    color: AppColors.supportMedium,
                    size: 20,
                  ),
                ),
              )
            : null,
        errorStyle:
            AppTypography.labelSmall.copyWith(color: AppColors.errorLight),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Barra de seguridad de contraseña
// ─────────────────────────────────────────────────────────────────────────────
class _PasswordStrengthBar extends StatelessWidget {
  final double strength;
  final Color color;
  final String label;

  const _PasswordStrengthBar({
    required this.strength,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: strength,
              backgroundColor: const Color(0xFFE0E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Seguridad ',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.supportMedium,
          ),
        ),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}