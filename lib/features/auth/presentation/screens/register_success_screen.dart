import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theoriginallab_v2/core/theme/app_colors.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';
import 'package:theoriginallab_v2/features/auth/presentation/screens/login_screen.dart';
import 'package:theoriginallab_v2/features/auth/presentation/widgets/auth_background.dart';
import 'package:theoriginallab_v2/features/auth/presentation/widgets/glass_auth_card.dart';
import 'package:theoriginallab_v2/shared/providers/providers.dart';

class RegisterSuccessScreen extends ConsumerWidget {
  final bool shouldLogout;

  const RegisterSuccessScreen({
    super.key,
    this.shouldLogout = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: AuthBackground(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GlassAuthCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 24),
                    // Success Icon
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.mark_email_read_outlined,
                        size: 64,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Title
                    Text(
                      '¡Registro Exitoso!',
                      textAlign: TextAlign.center,
                      style: AppTypography.headlineMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Body
                    Text(
                      'Se ha enviado un correo de confirmación.\n\nPor favor verifica tu bandeja de entrada (puede tardar 5-10 minutos en llegar).',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyLarge.copyWith(
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: () {
                          if (shouldLogout) {
                            ref.read(authProvider.notifier).logout();
                          }
                          // Navigate to Login and clear stack
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryNavy,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'IR AL INICIO',
                          style: AppTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
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
        ),
      ),
    );
  }
}
