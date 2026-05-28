/// Validadores centralizados para formularios de la app.
/// Ubicados aquí para reutilizarlos en todos los formularios y
/// garantizar consistencia de reglas de seguridad (OWASP M4).
class AppValidators {
  AppValidators._();

  // ─── Expresiones Regulares ────────────────────────────────────────────────

  /// RFC 5322 simplificado — acepta la mayoría de emails válidos.
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
  );

  /// Solo letras (con acentos y ñ), espacios y guiones. Mínimo 2 caracteres.
  static final _nameRegex = RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ'\- ]{2,100}$");

  /// Teléfono: solo dígitos, espacios, +, ( y ). Entre 7 y 20 caracteres.
  static final _phoneRegex = RegExp(r'^\+?[\d\s\-().]{7,20}$');

  /// Contraseña: mínimo 8 caracteres, al menos 1 letra y 1 número.
  static final _passwordRegex = RegExp(
    r'^(?=.*[A-Za-z])(?=.*\d).{8,128}$',
  );

  // ─── Límites de longitud ──────────────────────────────────────────────────

  static const int maxEmailLength = 254;
  static const int maxNameLength = 100;
  static const int maxPasswordLength = 128;
  static const int maxPhoneLength = 20;
  static const int maxTicketTitleLength = 120;
  static const int maxTicketDescLength = 2000;

  // ─── Validadores ─────────────────────────────────────────────────────────

  /// Valida un email.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingresa tu email';
    }
    if (value.length > maxEmailLength) {
      return 'Email demasiado largo';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Ingresa un email válido (ej. usuario@dominio.com)';
    }
    return null;
  }

  /// Valida un nombre completo.
  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingresa tu nombre';
    }
    if (value.trim().length < 2) return 'El nombre es demasiado corto';
    if (value.length > maxNameLength) return 'El nombre es demasiado largo';
    if (!_nameRegex.hasMatch(value.trim())) {
      return 'Solo se permiten letras, espacios y guiones';
    }
    return null;
  }

  /// Valida la contraseña en login (solo verifica que no esté vacía).
  static String? loginPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu contraseña';
    }
    return null;
  }

  /// Valida la contraseña en registro (verifica fortaleza).
  static String? registerPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa una contraseña';
    }
    if (value.length < 8) return 'Mínimo 8 caracteres';
    if (value.length > maxPasswordLength) return 'Contraseña demasiado larga';
    if (!_passwordRegex.hasMatch(value)) {
      return 'Debe contener al menos una letra y un número';
    }
    return null;
  }

  /// Valida un teléfono (opcional).
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null; // opcional
    if (value.length > maxPhoneLength) return 'Teléfono demasiado largo';
    if (!_phoneRegex.hasMatch(value.trim())) {
      return 'Formato de teléfono inválido';
    }
    return null;
  }

  /// Valida el asunto de un ticket.
  static String? ticketTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingresa un asunto';
    }
    if (value.trim().length < 5) return 'El asunto es demasiado corto';
    if (value.length > maxTicketTitleLength) {
      return 'El asunto es demasiado largo';
    }
    return null;
  }

  /// Valida la descripción de un ticket.
  static String? ticketDescription(String? value) {
    if (value == null || value.trim().length < 10) {
      return 'La descripción debe tener al menos 10 caracteres';
    }
    if (value.length > maxTicketDescLength) {
      return 'La descripción no puede superar los $maxTicketDescLength caracteres';
    }
    return null;
  }
}
