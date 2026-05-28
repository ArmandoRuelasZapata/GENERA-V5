# Criterios de Aceptación Corporativos

Este documento define los "Quality Gates" mínimos que cualquier release debe cumplir para ser aprobado.

## 1. Usabilidad (UX/UI)
- **Consistencia Visual**: La implementación debe coincidir con el diseño en Figma (pixel-perfect dentro de lo razonable).
- **Accesibilidad**:
    - Elementos interactivos con tamaño mínimo de 48x48dp.
    - Contraste de texto cumple estándar WCAG AA.
    - Etiquetas semánticas para lectores de pantalla en elementos clave.
- **Feedback al Usuario**: Indicadores de carga visibles para operaciones > 500ms.

## 2. Rendimiento
La aplicación debe sentirse fluida y responder rápidamente.

- **Tiempo de Inicio (Cold Start)**: < 2 segundos hasta que la UI es interactiva.
- **Frame Rate**:
    - Animaciones y scroll a 60 FPS consistentes sin "jank" visible.
    - **Matriz de Dispositivos**: Validación obligatoria en dispositivo físico de gama media (ej. Android 10+, 4GB RAM).
- **Compatibilidad de Software (Min SDK)**:
    - iOS: Soporte garantizado desde iOS 15+.
    - Android: Pendiente de confirmación final por equipo de Backend (Target provisional: Android 10 / API 29+).
- **Memoria**: Sin fugas de memoria (memory leaks) detectables tras ciclos de uso prolongado.
- **Tamaño de App**: Optimización de assets para mantener el APK/IPA dentro de límites razonables (< 50MB idealmente para MVP).

## 3. Seguridad
Cumplimiento base de seguridad para proteger datos del usuario y corporativos.

- **OWASP MASVS L1**: Cumplimiento del nivel estándar de seguridad móvil.
- **Gestión de Secretos**:
    - API Keys no hardcodeadas en el repositorio (uso de variables de entorno / Flavors).
    - Claves críticas restringidas por aplicación (SHA-1 fingerprint).
- **Almacenamiento Local**:
    - Datos sensibles (tokens, PII) almacenados en `FlutterSecureStorage` o equivalente cifrado.
    - No almacenar logs sensibles en producción.
- **Comunicación**: Todo tráfico de red forzado bajo HTTPS (TLS 1.2+).
