import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animations/animations.dart';

import 'package:theoriginallab_v2/core/theme/app_colors.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';
import 'package:theoriginallab_v2/core/validators/app_validators.dart';
import 'package:theoriginallab_v2/shared/providers/providers.dart';
import 'package:theoriginallab_v2/features/home/presentation/screens/main_screen.dart';

import '../widgets/auth_text_field.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final bool isBlackTheme;
  const LoginScreen({super.key, this.isBlackTheme = false});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _credentialController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

  // TODO: Modificar al tener la base de datos reemplazar por el nombre real del socio
  static const String _socioName = 'Daniel';

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días';
    if (h < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  void dispose() {
    _credentialController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref
        .read(authProvider.notifier)
        .login(_credentialController.text.trim(), _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (_, current) {
      current.whenOrNull(
        authenticated: (_) => Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        ),
        error: (msg) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg,
                style: AppTypography.bodySmall.copyWith(color: Colors.white)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        ),
      );
    });

    final isLoading = ref
        .watch(authProvider)
        .maybeWhen(loading: () => true, orElse: () => false);

    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      body: Stack(
        children: [
          // ── 1. FOTO DE FONDO con gradiente ──────────────────────────────
          Stack(
            children: [
              SizedBox(
                height: screenHeight * 0.65,
                width: double.infinity,
                child: Image.asset(
                  'assets/images/login_background.jpg',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
              Container(
                height: screenHeight * 0.65,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x55154284), Color(0xEE154284)],
                  ),
                ),
              ),
            ],
          ),

          // ── 2. CONTENIDO ────────────────────────────────────────────────
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Botón atrás
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    child: _CircleBackButton(),
                  ),
                ),

                const SizedBox(height: 20),

                // ── LOGO ─────────────────────────────────────────────────
                Hero(
                  tag: 'genera_logo',
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/genera_logo_white.png',
                        width: 64,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'GENERA',
                        style: AppTypography.headlineLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 5,
                          
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── CARD BLANCA ──────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
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
                            // Saludo
                            Text(
                              '$_greeting,',
                              style: AppTypography.headlineMedium.copyWith(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              _socioName,
                              style: AppTypography.headlineMedium.copyWith(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),

                            const SizedBox(height: 28),

                            // Campo: Usuario
                            Text(
                              'Usuario',
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _LightTextField(
                              controller: _credentialController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Ingresa tu número de socio o correo';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 20),

                            // Campo: Contraseña
                            Text(
                              'Contraseña',
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _LightTextField(
                              controller: _passwordController,
                              isPassword: true,
                              isPasswordVisible: _isPasswordVisible,
                              textInputAction: TextInputAction.done,
                              onVisibilityToggle: () => setState(() =>
                                  _isPasswordVisible = !_isPasswordVisible),
                              validator: AppValidators.loginPassword,
                            ),

                            // ¿Olvidaste tu contraseña?
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ForgotPasswordScreen(),
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 0, vertical: 8),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '¿Olvidaste tu ',
                                        style: AppTypography.bodySmall
                                            .copyWith(
                                                color: AppColors.textDark),
                                      ),
                                      TextSpan(
                                        text: 'contraseña?',
                                        style: AppTypography.bodySmall
                                            .copyWith(
                                          color: AppColors.accentCyan,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Botón Ingresar
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: FilledButton(
                                onPressed: isLoading ? null : _handleLogin,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primaryNavy,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ).copyWith(
                                  backgroundColor:
                                      WidgetStateProperty.resolveWith(
                                    (states) {
                                      if (states
                                          .contains(WidgetState.disabled)) {
                                        return AppColors.primaryNavy
                                            .withValues(alpha: 0.5);
                                      }
                                      return AppColors.primaryNavy;
                                    },
                                  ),
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          'Ingresar',
                                          style: AppTypography.labelLarge
                                              .copyWith(
                                            color: Colors.white,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // ¿No tienes cuenta?
                            Center(
                              child: GestureDetector(
                                onTap: () => Navigator.of(context).push(
                                  PageRouteBuilder(
                                    pageBuilder: (_, a, sa) =>
                                        const RegisterScreen(),
                                    transitionsBuilder: (_, a, sa, child) =>
                                        FadeThroughTransition(
                                      animation: a,
                                      secondaryAnimation: sa,
                                      child: child,
                                    ),
                                  ),
                                ),
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '¿No tienes cuenta? ',
                                        style: AppTypography.bodyMedium
                                            .copyWith(
                                                color: AppColors.textDark),
                                      ),
                                      TextSpan(
                                        text: 'Regístrate',
                                        style: AppTypography.bodyMedium
                                            .copyWith(
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
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
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
          color: Colors.white.withValues(alpha: 0.25),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.chevron_left_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Campo de texto claro — sobre la card blanca
// ─────────────────────────────────────────────────────────────────────────────
class _LightTextField extends StatelessWidget {
  final TextEditingController controller;
  final bool isPassword;
  final bool isPasswordVisible;
  final VoidCallback? onVisibilityToggle;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  const _LightTextField({
    required this.controller,
    this.isPassword = false,
    this.isPasswordVisible = false,
    this.onVisibilityToggle,
    this.validator,
    this.keyboardType,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !isPasswordVisible,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      style: AppTypography.bodyMedium.copyWith(color: AppColors.textDark),
      cursorColor: AppColors.accentCyan,
      decoration: InputDecoration(
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
          borderSide: const BorderSide(color: AppColors.errorLight, width: 1),
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