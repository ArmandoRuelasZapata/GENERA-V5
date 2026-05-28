import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/providers.dart';
import 'change_password_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/auth_background.dart';
import '../widgets/glass_auth_card.dart';
import '../widgets/auth_text_field.dart';

class VerifyCodeScreen extends ConsumerStatefulWidget {
  final String email;

  const VerifyCodeScreen({super.key, required this.email});

  @override
  ConsumerState<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends ConsumerState<VerifyCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleVerifyCode() async {
    if (!_formKey.currentState!.validate()) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isLoading = true);

    try {
      final dataSource = ref.read(authRemoteDataSourceProvider);
      final changeToken = await dataSource.verifyResetCode(
        widget.email,
        _codeController.text.trim(),
      );

      if (!mounted) return;

      // Navegar a pantalla de cambio de contraseña
      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (context) => ChangePasswordScreen(
            email: widget.email,
            changeToken: changeToken,
          ),
        ),
      );

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Código válido'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back Button
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                padding: const EdgeInsets.all(12),
              ),
            ),
          ),

          // Icon
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.accentCyan.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accentCyan.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.verified_user_outlined,
                size: 48,
                color: AppColors.accentCyan,
              ),
            ),
          ),
          const SizedBox(height: 24),

          GlassAuthCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  Text(
                    'Verificar Código',
                    style: AppTypography.headlineMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Description
                  Text(
                    'Ingresa el código de 6 dígitos que enviamos a:',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  Text(
                    widget.email,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.accentCyan,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  // Code Input
                  AuthTextField(
                    controller: _codeController,
                    label: 'Código de Verificación',
                    icon: Icons.pin_outlined,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa el código';
                      }
                      if (value.length != 6) {
                        return 'El código debe tener 6 dígitos';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),

                  // Verify Button
                  SizedBox(
                    height: 56,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _handleVerifyCode,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryNavy,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ).copyWith(
                        backgroundColor: WidgetStateProperty.resolveWith((
                          states,
                        ) {
                          if (states.contains(WidgetState.disabled)) {
                            return AppColors.primaryNavy.withValues(alpha: 0.6);
                          }
                          return AppColors.primaryNavy;
                        }),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'VERIFICAR CÓDIGO',
                                style: AppTypography.labelLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Resend Code
                  TextButton(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        final dataSource = ref.read(
                          authRemoteDataSourceProvider,
                        );
                        await dataSource.requestPasswordReset(widget.email);

                        if (!mounted) return;
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Código reenviado'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accentCyan,
                    ),
                    child: Text(
                      'Reenviar código',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.accentCyan,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
