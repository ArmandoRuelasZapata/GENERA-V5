import 'package:flutter/material.dart';

/// GENERA — Paleta de Colores
/// Versión Estándar: Azul Institucional
/// Versión Black:    Negro / Dorado Premium
class AppColors {
  // ============================================================
  // VERSIÓN ESTÁNDAR — Identidad GENERA
  // ============================================================

  /// Azul Marino — color de marca principal
  static const Color primaryNavy = Color(0xFF154284);

  /// Azul Celeste — acento / acciones interactivas
  static const Color accentCyan = Color(0xFF009FE3);

  /// Gris Carbón — textos y datos
  static const Color textDark = Color(0xFF3C3C3B);

  /// Blanco Hueso — fondo principal
  static const Color backgroundLight = Color(0xFFF7F7F7);

  /// Superficie de tarjeta (modo claro)
  static const Color surfaceLight = Color(0xFFFFFFFF);

  /// Borde sutil en modo claro
  static const Color borderLight = Color(0xFFE0E8F0);

  // ============================================================
  // VERSIÓN BLACK — Socio Premium
  // ============================================================

  static const Color blackBackground = Color(0xFF0A0A0A);
  static const Color blackSurface = Color(0xFF1C1C1C);
  static const Color blackBorder = Color(0x33C9A84C);
  static const Color goldAccent = Color(0xFFC9A84C);
  static const Color goldLight = Color(0xFFE8C97A);
  static const Color blackTextPrimary = Color(0xFFF5F5F5);
  static const Color blackTextSecondary = Color(0xFFAAAAAA);

  // ============================================================
  // SEMÁNTICOS — compartidos ambas versiones
  // ============================================================

  static const Color success = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFF9A825);
  static const Color error = Color(0xFFC62828);
  static const Color errorLight = Color(0xFFEF5350);
  static const Color info = Color(0xFF0277BD);

  // ============================================================
  // GRADIENTES — Versión Estándar
  // ============================================================

  static const LinearGradient authBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0D2E5C), Color(0xFF154284), Color(0xFF1A5499)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF154284), Color(0xFF009FE3)],
  );

  // ============================================================
  // GRADIENTES — Versión Black
  // ============================================================

  static const LinearGradient blackAuthBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF000000), Color(0xFF0A0A0A), Color(0xFF111111)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8C97A), Color(0xFFC9A84C), Color(0xFFA07830)],
  );

  // ============================================================
  // COMPATIBILIDAD — colores del tema TOL original
  // Mantener mientras existan referencias en código heredado.
  // Migrar pantalla por pantalla al nuevo sistema GENERA.
  // ============================================================

  static const Color baseDark = Color(0xFF021024);
  static const Color surfaceDark = Color(0xFF061A2A);
  static const Color surfaceDarkElevated = Color(0xFF0A2338);
  static const Color borderDark = Color(0xFF1E3246);
  static const Color borderDarkSubtle = Color(0xFF152433);
  static const Color supportLight = Color(0xFFC9D9E8);
  static const Color supportMedium = Color(0xFF4C6480);
  static const Color tertiaryTeal = Color(0xFF034960);

  // Helpers
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Colors.transparent;
}
