class StorageKeys {
  // Auth
  static const String accessToken = 'access_token';
  static const String authToken = 'auth_token';
  static const String userId = 'user_id';
  static const String userEmail = 'user_email';
  static const String userName = 'user_name';
  static const String userPhone = 'user_phone';
  static const String userProfileImg = 'user_profile_img';
  static const String isLoggedIn = 'is_logged_in';

  // Validación de sesión por TTL (ya que el token no es JWT estándar con exp)
  static const String loginAt =
      'login_at'; // Epoch en segundos (al momento del login)
  static const String expiresIn =
      'expires_in'; // Duración en segundos (del backend)

  // Inactividad (OWASP M3)
  static const String lastActivityAt =
      'last_activity_at'; // Epoch en milisegundos

  // Fresh Install (iOS Keychain persistencia fix)
  // Cambiar esta versión si se desea forzar limpieza en una actualización futura.
  static const String isFirstRunV2 = 'is_first_run_v2_0_1';
}
