# Checklist de Vulnerabilidades y Seguridad (1.4 & 1.6)

Este documento define las verificaciones de seguridad obligatorias para el desarrollo y auditoría de la aplicación, alineadas con **OWASP Mobile Application Security Verification Standard (MASVS)**.

## 1. Manejo de Sesiones (Authentication & Session Management)
**Objetivo**: Asegurar que la identidad del usuario esté protegida y las sesiones se gestionen correctamente.

- [ ] **Expiración de Sesión**: El token de acceso (JWT) debe expirar en un tiempo razonable (ej. 15-60 min).
- [ ] **Refresh Token Seguro**: El refresh token debe almacenarse de forma segura y rotarse tras su uso.
- [ ] **Logout Real**: Al cerrar sesión, el token debe ser invalidado en el cliente y (si es posible) en el backend (blacklist).
- [ ] **Límite de Intentos**: Implementar bloqueo temporal tras 'N' intentos fallidos de login (prevenir fuerza bruta).

## 2. Almacenamiento de Datos Sensibles (Data Storage)
**Objetivo**: Proteger datos críticos almacenados en el dispositivo (Data-at-Rest).

- [ ] **No Hardcoding**: Nunca incluir credenciales, API Keys maestras o secretos en el código fuente.
- [ ] **Secure Storage**: Utilizar `flutter_secure_storage` (Keystore/Keychain) para:
    - Tokens de autenticación.
    - Información personal identificable (PII) cacheada.
- [ ] **Limpieza de Caché**: Eliminar datos sensibles al hacer logout o desinstalar la app.
- [ ] **Logs en Producción**: Deshabilitar `print`, `debugPrint` o logs de red que expongan datos sensibles en builds de Release.

## 3. Validación de Entradas (Input Validation)
**Objetivo**: Prevenir inyección de código y comportamiento inesperado.

- [ ] **Tipado Fuerte**: Usar el sistema de tipos de Dart para prevenir inyecciones básicas.
- [ ] **Sanitización**: Limpiar inputs de texto antes de enviarlos a APIs o bases de datos locales.
- [ ] **Límites de Longitud**: Validar longitud máxima de campos de texto (ej. Username < 50 chars).
- [ ] **URLs**: Validar que las URLs ingresadas o procesadas sigan un formato válido (`Uri.parse`).

## 4. Comunicaciones Seguras (Network Communication)
- [ ] **HTTPS Forzado**: Todo tráfico debe ir sobre TLS 1.2+.
- [ ] **Certificate Pinning** (Opcional/Avanzado): Implementar pinning para endpoints críticos si el nivel de riesgo lo amerita.
- [ ] **Gestión de Errores**: Las respuestas de error de la API no deben exponer stack traces ni detalles de infraestructura al usuario final.

## 5. Alineación OWASP Mobile Top 10 (Referencia)
| ID | Vulnerabilidad | Contramedida Principal |
| :--- | :--- | :--- |
| M1 | Improper Platform Usage | Usar APIs de Android/iOS correctamente (intentos, permisos). |
| M2 | Insecure Data Storage | Usar Keystore/Keychain. No SharedPreferences para secretos. |
| M3 | Insecure Communication | HTTPS + Pinning. |
| M4 | Insecure Authentication | No guardar passwords en local. MFA. |
| M5 | Insufficient Cryptography | No crear algoritmos propios. Usar estándares (AES, RSA). |
| M6 | Insecure Authorization | Validar permisos en Backend (IDOR). |
| M7 | Client Code Quality | Linter estricto, manejo de excepciones. |
| M8 | Code Tampering | Obfuscación (ProGuard/R8). |
| M9 | Reverse Engineering | Detección de Root/Jailbreak (opcional). |
| M10 | Extraneous Functionality | Remover backdoors o funcionalidades de debug en Prod. |
