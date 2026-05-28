# 04 - Prevención de Riesgos y Seguridad Operativa

## 1. Visión General de Seguridad

The Original Lab App (v2) está diseñada desde su concepción bajo principios *Security-by-Design*. Incorpora múltiples capas de defensa activa para proteger los datos del cliente, garantizar la integridad de las sesiones y prevenir la intercepción de tráfico de red.

Estas políticas aseguran que la plataforma cumpla con los estándares esperados de aplicaciones B2B empresariales.

---

## 2. Matriz de Defensas Activas (OWASP Mobile)

| Amenaza | Contramedida Implementada | Cumplimiento |
|---|---|---|
| **M1: Uso inadecuado de Plataforma** | Restricción de permisos mínimos en Android/iOS y manejo seguro de Intents. | OK |
| **M2: Almacenamiento Inseguro** | Almacenamiento de tokens Bearer en Keystore (Android) / Keychain (iOS) a través de `flutter_secure_storage`. Borrado completo tras desinstalación. | OK |
| **M3: Comunicación Insegura** | Uso obligatorio de HTTPS. **Certificate Pinning** implementado exclusivamente para los dominios propios de la empresa en producción. | OK |
| **M4: Autenticación Insegura** | Implementación de `TTL` local e invalidación automática tras 15 minutos exactos de inactividad táctil. | OK |
| **M8: Manipulación de Código** | Evaluación anti-root y anti-jailbreak en fase de arranque (Release mode). | OK |

---

## 3. Comportamientos Operativos Clave

### 3.1 Device Security (Anti-Root / Jailbreak)
> [!IMPORTANT]
> Si la aplicación se ejecuta en un binario compilado para producción (`--release`), el módulo `DeviceSecurity` evalúa de inmediato el entorno. Si el dispositivo está "rooteado" en Android o tiene "jailbreak" en iOS, la aplicación se cerrará automáticamente (Fail-fast).

### 3.2 TLS Pinning (M3)
> [!NOTE]
> Para evitar ataques _Man-in-the-Middle_ (espionaje), las conexiones hacia los dominios propios detectados en la plataforma (ej. `theoriginallab.com`, `easypanel.host`) requerirán que el certificado del servidor coincida exactamente con la huella esperada por la app. **Nota:** No se aplica a OpenAI ni a Webhooks de terceros para evitar que un cambio ajeno rompa la app.

### 3.3 Logger de Red Seguro (Data Leak Prevention)
> [!TIP]
> Incluso en entornos de pruebas, el `PrettyDioLogger` está configurado (`requestHeader: false`) para **reducir significativamente la exposición visual** de credenciales. Al bloquear la impresión de las cabeceras, se evita mostrar las claves de API y los tokens Bearer (`Authorization: Bearer xyz...`) en la consola, aunque el cuerpo de las peticiones (`requestBody`) sigue activo en debug para facilitar el desarrollo. Esto previene que un volcado de logs simple (Logcat Dump) comprometa los secretos principales.

### 3.4 Inactivity Culling (Deslogueo por Inactividad)
Para sesiones olvidadas, el `AuthNotifier` corre un temporizador subyacente de 15 minutos (900 segundos). Cualquier _tap_ o gesto de desplazamiento en cualquier pantalla reinicia el reloj. Si llega a cero, el usuario es deslogueado y sus llaves borradas del Keystore.

---

## 4. Guía de Resolución de Errores Críticos Comunes

### Error: `FIS_AUTH_ERROR` (Firebase Installations Service Error)

Este no es un error de código, sino una medida de restricción de Google Cloud sobre el proyecto.

* **Por qué ocurre:** Las peticiones desde la aplicación móvil hacia los servidores de Notificaciones Push (FCM) son rechazadas por falta de permisos o por una huella SHA-1 ausente.
* **Solución Rápida:**
  1. Extraer la huella SHA-1 del entorno afectado o llaves de PlayStore (`gradlew signingReport`).
  2. Registrar la nueva huella en la Consola Firebase del proyecto bajo la app `com.theoriginallab.app`.
  3. Comprobar que en Google Cloud Console > Restricciones de API de Android, se encuentre permitida explícitamente la API **Firebase Installations API**.
  4. Ejecutar `flutter clean` y reconstruir.
