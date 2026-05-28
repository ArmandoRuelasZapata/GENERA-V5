import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_colors.dart';

/// AuthBackground — GENERA
///
/// Fondo para todas las pantallas de autenticación.
/// Aplica el gradiente correcto según el tema activo (estándar o Black).
///
/// Para la versión Black se detecta vía [_isBlackTheme]; en producción
/// esto se leerá del themeProvider de Riverpod.
class AuthBackground extends StatelessWidget {
  final Widget child;
  final bool isBlackTheme;

  const AuthBackground({
    super.key,
    required this.child,
    this.isBlackTheme = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: isBlackTheme
              ? AppColors.blackAuthBackgroundGradient
              : AppColors.authBackgroundGradient,
        ),
        child: Stack(
          children: [
            // ── Glow superior derecha ──────────────────────────────
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: isBlackTheme
                        ? [
                            AppColors.goldAccent.withValues(alpha: 0.18),
                            Colors.transparent,
                          ]
                        : [
                            AppColors.accentCyan.withValues(alpha: 0.25),
                            Colors.transparent,
                          ],
                    stops: const [0.0, 0.75],
                  ),
                ),
              ),
            ),

            // ── Glow inferior izquierda ────────────────────────────
            Positioned(
              bottom: -60,
              left: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: isBlackTheme
                        ? [
                            AppColors.goldAccent.withValues(alpha: 0.10),
                            Colors.transparent,
                          ]
                        : [
                            AppColors.primaryNavy.withValues(alpha: 0.4),
                            Colors.transparent,
                          ],
                    stops: const [0.0, 0.75],
                  ),
                ),
              ),
            ),

            // ── Contenido principal ────────────────────────────────
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 32.0,
                  ),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}