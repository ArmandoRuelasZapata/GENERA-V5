import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// GENERA — Sistema Tipográfico
///
/// Títulos:  Cinzel (sustituto de Trajan Pro, mismo espíritu serif clásico)
/// Cuerpos:  Inter  (sustituto de Helvetica Neue, diseñada para pantallas)
///
/// Cuando el cliente entregue los .ttf oficiales, cambiar solo el fontFamily
/// en _titleFamily y _bodyFamily sin tocar el resto del código.
class AppTypography {
  // ── Familias ─────────────────────────────────────────────────────────────

  /// Serif para títulos — reemplazar por 'TrajanPro' cuando esté disponible
  static String get fontFamily =>
      GoogleFonts.inter().fontFamily ?? 'sans-serif';

  static String get _titleFamily =>
      GoogleFonts.cinzel().fontFamily ?? 'serif';

  static String get _bodyFamily =>
      GoogleFonts.inter().fontFamily ?? 'sans-serif';

  // ============================================================
  // DISPLAY — secciones hero, números de saldo
  // ============================================================

  static TextStyle displayLarge = TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 57,
    fontWeight: FontWeight.w700,
    height: 1.12,
    letterSpacing: -0.25,
  );

  static TextStyle displayMedium = TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 45,
    fontWeight: FontWeight.w700,
    height: 1.16,
  );

  static TextStyle displaySmall = TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 36,
    fontWeight: FontWeight.w600,
    height: 1.22,
  );

  // ============================================================
  // HEADLINE — títulos de pantalla y sección
  // ============================================================

  static TextStyle headlineLarge = TextStyle(
    fontFamily: _titleFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: 0.3,
  );

  static TextStyle headlineMedium = TextStyle(
    fontFamily: _titleFamily,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.29,
    letterSpacing: 0.2,
  );

  static TextStyle headlineSmall = TextStyle(
    fontFamily: _titleFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.33,
  );

  // ============================================================
  // TITLE — encabezados de card y sub-sección
  // ============================================================

  static TextStyle titleLarge = TextStyle(
    fontFamily: _titleFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.27,
    letterSpacing: 0.2,
  );

  static TextStyle titleMedium = TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.33,
    letterSpacing: 0.15,
  );

  static TextStyle titleSmall = TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.43,
    letterSpacing: 0.1,
  );

  // ============================================================
  // BODY — contenido principal
  // ============================================================

  static TextStyle bodyLarge = TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.15,
  );

  static TextStyle bodyMedium = TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.43,
    letterSpacing: 0.1,
  );

  static TextStyle bodySmall = TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0.2,
  );

  // ============================================================
  // LABEL — botones, chips, etiquetas
  // ============================================================

  static TextStyle labelLarge = TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.43,
    letterSpacing: 1.2,
  );

  static TextStyle labelMedium = TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.33,
    letterSpacing: 0.5,
  );

  static TextStyle labelSmall = TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.45,
    letterSpacing: 0.5,
  );

  // ============================================================
  // ESTILOS COMPUESTOS — atajos de uso frecuente
  // ============================================================

  /// Encabezado de AppBar
  static TextStyle screenTitle = TextStyle(
    fontFamily: _titleFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );

  /// Texto de botón
  static TextStyle button = TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  /// Texto de pie / helper / nota legal
  static TextStyle caption = TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.33,
    letterSpacing: 0.2,
  );

  /// Número de saldo — grande y destacado
  static TextStyle balanceAmount = TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
  );

  /// Texto de link / acción secundaria
  static TextStyle link = TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.43,
    letterSpacing: 0.1,
    decoration: TextDecoration.underline,
  );

  /// Encabezado de sección
  static TextStyle sectionHeader = TextStyle(
    fontFamily: _titleFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.33,
  );

  /// Título de card
  static TextStyle cardTitle = TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  /// Subtítulo / descripción de card
  static TextStyle cardSubtitle = TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.43,
  );
}