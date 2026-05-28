# Auth/Login Issue – Contexto y Hallazgos (2026-03-24)

## Bitácora (problema y corrección)
**Problema**
- Login funciona en debug pero falla en release con `DioExceptionType.unknown` al llamar `POST /api/auth/exchange`.
- En logs no hay `response` (null), lo que indica fallo de conexión/handshake TLS.
- Causa raíz: **certificate pinning** con cert rotado en el host de la API propia.

**Corrección**
- Se actualizó el certificado embebido en pinning con el PEM actual del host.
- Resultado: login en release volvió a funcionar.

**Acciones técnicas aplicadas**
- Cert actualizado en `lib/core/network/interceptors/certificate_pinning_interceptor.dart`.
- Se añadió soporte para múltiples certs (rotación sin downtime).
- Se agregó script `scripts/update_pinning_cert.sh` para actualizar certs.

## Resumen rápido
- En **debug** el login funciona, en **release/producción** falla con Dio.
- Se revisó configuración de URLs y cifrado; **no hay mismatch** de llaves.
- La hipótesis más fuerte es **certificate pinning** en release.

## Hallazgos en la app (Flutter)
- `Env` usa **.env.dev** en debug y **.env.prod** en release.
- Verificado que **.env.dev** y **.env.prod** tienen los **mismos valores**.
- Verificado que `env.g.dart` coincide con esos valores.
- `authApiDioProvider` (auth externo) **NO usa pinning** ni cifrado.
- `contentApiDioProvider` (API propia) **SÍ usa pinning** y **SÍ usa cifrado**.
- Flujo de login:
  1) `POST /api/login` (auth API externa, sin cifrado/pinning)
  2) `POST /api/auth/exchange` (API propia, con cifrado + pinning)

## Registro (register) – comportamiento observado
- No se envía “dos veces”. Son 2 requests esperadas:
  1) `POST /api/register` (auth externo)
  2) `POST /api/auth/exchange` (API propia)
- En logs, `/api/register` devuelve `success: true` **pero sin `user_id`** (data: {}).
- El exchange falla con `400` porque `user_id` llega vacío.
- Se aplicó fix en app para **no intentar exchange si falta user_id**:
  - Archivo: `lib/features/auth/data/datasources/auth_remote_datasource.dart`
  - Si no hay `user_id`, se retorna `UserModel` básico sin token.

## Cert Pinning (hipótesis principal)
- En debug se desactiva automáticamente (por `kDebugMode`).
- En release se activa y valida el cert embebido.
- Si el cert del servidor rotó recientemente, el release fallará.
- Cert embebido en app:
  - Archivo: `lib/core/network/interceptors/certificate_pinning_interceptor.dart`
  - Dominio: `*.m0oqwu.easypanel.host`
  - Expira: `2026-04-22`

## Cifrado (AES-256-CTR + HMAC)
- App usa `PAYLOAD_ENCRYPTION_KEY` desde env.
- Backend (Dart Frog) también lee `PAYLOAD_ENCRYPTION_KEY`.
- Se confirmó que la key en Easypanel es:
  `987446b50cbeb38f8f95d50654ae8e7bf0ca5a27eb463716bfecb44d63379591`
- La key coincide con la app, por lo tanto **no hay mismatch**.
- El cifrado no “vence”. Solo falla si la key cambia o se desactiva.

## Logs en release
- Se modificó la app para permitir logs en release si `ENABLE_NETWORK_LOGS=true`.
  - Archivo: `lib/core/network/network_client.dart`
  - Cambio: `loggingEnabled = ApiConstants.enableNetworkLogs;`
- Comando sugerido:
  - `flutter run --release --dart-define-from-file=.env.prod.json`
  - Asegurar `ENABLE_NETWORK_LOGS=true` en `.env.prod.json`.

## Backend (Dart Frog API)
- Middleware de cifrado y replay:
  - `routes/_middleware.dart`
- Crypto:
  - `lib/services/payload_crypto.dart`
- Exchange:
  - `routes/api/auth/exchange.dart`

## Próximos pasos
1) Correr release con logs habilitados y revisar error real (handshake/pinning vs payload/replay).
2) Si es pinning:
   - Actualizar cert embebido en app.
3) Si aparece error de replay:
   - Verificar reloj del servidor y headers `X-Request-Nonce` / `X-Request-Timestamp`.

## Hardening (config pro)
- Se habilitó soporte para **múltiples certs** en pinning:
  - Archivo: `lib/core/network/interceptors/certificate_pinning_interceptor.dart`
  - Lista: `_pinnedCertsPem` (mantener 2 certs durante rotación).
- Script para actualizar el cert automáticamente:
  - `scripts/update_pinning_cert.sh <host> [output_pem_path]`
  - Ejemplo:
    `scripts/update_pinning_cert.sh theoriginallab-api-apptolv2-dev.m0oqwu.easypanel.host`

PRUEBAS
PRUEBAS EN RELEASE CON: flutter run --release --dart-define-from-file=.env.prod.json
LOGS DE INICIO DE SESION 

I/flutter (19748): [IMPORTANT:flutter/shell/platform/android/android_context_vk_impeller.cc(62)] Using the Impeller rendering backend (Vulkan).
I/flutter (19748): [IMPORTANT:flutter/shell/platform/android/android_context_vk_impeller.cc(62)] Using the Impeller rendering backend (Vulkan).
I/flutter (19748): 
I/flutter (19748): ╔╣ Request ║ POST 
I/flutter (19748): ║  https://theoriginallab-api-originalauth-desa.m0oqwu.easypanel.host/api/login
I/flutter (19748): ╚══════════════════════════════════════════════════════════════════════════════════════════╝
I/flutter (19748): ╔ Body 
I/flutter (19748): ╟ email: alanjesus2422@gmail.com
I/flutter (19748): ╟ password: T3JpZ2luYWwyQA==
I/flutter (19748): ╚══════════════════════════════════════════════════════════════════════════════════════════╝
I/flutter (19748): ║ {email: alanjesus2422@gmail.com, password: T3JpZ2luYWwyQA==}
I/flutter (19748): 
I/flutter (19748): ╔╣ Response ║ POST ║ Status: 200 OK  ║ Time: 606 ms
I/flutter (19748): ║  https://theoriginallab-api-originalauth-desa.m0oqwu.easypanel.host/api/login
I/flutter (19748): ╚══════════════════════════════════════════════════════════════════════════════════════════╝
I/flutter (19748): ╔ Body
I/flutter (19748): ║
I/flutter (19748): ║    {
I/flutter (19748): ║         "data": {
I/flutter (19748): ║             "callback": null,
I/flutter (19748): ║             "expires_in": 3600,
I/flutter (19748): ║             "return_url": null,
I/flutter (19748): ║             "role": "USR03",
I/flutter (19748): ║             "session": "dBu7f0cOeEAFhlMh",
I/flutter (19748): ║             "token": ".eJyrViotTi2Kz0xRsjKyMNNRSs1NzMxRslJKzEnMy0otLi02MjEyckgHieol5-cq6SgV5eekAhWE
I/flutter (19748): ║              BgcZGAO5iQUFYN2GxpY6SsWpxcWZ-XlA6RSnUvM0g2T_VFdHt4wc3wyoxvjk_BSE7loA2XYnLQ.acK
I/flutter (19748): ║              8ww.M823DM5D_hDVgWqTij2ZxEdWFos"
I/flutter (19748): ║             "user": {email: alanjesus2422@gmail.com, id: 286, name: Alan Gonzalez}
I/flutter (19748): ║        }
I/flutter (19748): ║         "message": "Login exitoso",
I/flutter (19748): ║         "success": true
I/flutter (19748): ║    }
I/flutter (19748): ║
I/flutter (19748): ╚══════════════════════════════════════════════════════════════════════════════════════════╝
I/flutter (19748): 
I/flutter (19748): ╔╣ Request ║ POST 
I/flutter (19748): ║  https://theoriginallab-api-apptolv2-dev.m0oqwu.easypanel.host/api/auth/exchange
I/flutter (19748): ╚══════════════════════════════════════════════════════════════════════════════════════════╝
I/flutter (19748): ╔ Body 
I/flutter (19748): ╟ enc: 
I/flutter (19748): ║ rqNo6/xa5NkQNq8Ibhhmu1BrJDCvbDljtEzFW9vWDH19yYkWtAnr/IJhAnmnO3ozeZNMecoAWVpZHe+BNpkA1vnrrg
I/flutter (19748): ║ W9eC4w7Zje0PqmX41nmXT1LAvQqwxQN5kMLvhOukaJEH132BrrvosXwAOofsEUoP+JixFFFyHWGvHcjHG+V8dREbw=
I/flutter (19748): ╚══════════════════════════════════════════════════════════════════════════════════════════╝
I/flutter (19748): ║ {enc: rqNo6/xa5NkQNq8Ibhhmu1BrJDCvbDljtEzFW9vWDH19yYkWtAnr/IJhAnmnO3ozeZNMecoAWVpZHe+BNpkA
I/flutter (19748): ║ 1vnrrgW9eC4w7Zje0PqmX41nmXT1LAvQqwxQN5kMLvhOukaJEH132BrrvosXwAOofsEUoP+JixFFFyHWGvHcjHG+V8
I/flutter (19748): ║ dREbw=}
I/flutter (19748): 
I/flutter (19748): ╔╣ DioError ║ DioExceptionType.unknown
I/flutter (19748): ║  null
I/flutter (19748): ╚══════════════════════════════════════════════════════════════════════════════════════════╝


LOGS DE REGISTRO QUE YA FUNCIONA 
/flutter (19748): [IMPORTANT:flutter/shell/platform/android/android_context_vk_impeller.cc(62)] Using the Impeller rendering backend (Vulkan).
I/flutter (19748): 
I/flutter (19748): ╔╣ Request ║ POST 
I/flutter (19748): ║  https://theoriginallab-api-originalauth-desa.m0oqwu.easypanel.host/api/login
I/flutter (19748): ╚══════════════════════════════════════════════════════════════════════════════════════════╝
I/flutter (19748): ╔ Body 
I/flutter (19748): ╟ email: alanjesus2422@gmail.com
I/flutter (19748): ╟ password: T3JpZ2luYWwyQA==
I/flutter (19748): ╚══════════════════════════════════════════════════════════════════════════════════════════╝
I/flutter (19748): ║ {email: alanjesus2422@gmail.com, password: T3JpZ2luYWwyQA==}
I/flutter (19748): 
I/flutter (19748): ╔╣ Response ║ POST ║ Status: 200 OK  ║ Time: 606 ms
I/flutter (19748): ║  https://theoriginallab-api-originalauth-desa.m0oqwu.easypanel.host/api/login
I/flutter (19748): ╚══════════════════════════════════════════════════════════════════════════════════════════╝
I/flutter (19748): ╔ Body
I/flutter (19748): ║
I/flutter (19748): ║    {
I/flutter (19748): ║         "data": {
I/flutter (19748): ║             "callback": null,
I/flutter (19748): ║             "expires_in": 3600,
I/flutter (19748): ║             "return_url": null,
I/flutter (19748): ║             "role": "USR03",
I/flutter (19748): ║             "session": "dBu7f0cOeEAFhlMh",
I/flutter (19748): ║             "token": ".eJyrViotTi2Kz0xRsjKyMNNRSs1NzMxRslJKzEnMy0otLi02MjEyckgHieol5-cq6SgV5eekAhWE
I/flutter (19748): ║              BgcZGAO5iQUFYN2GxpY6SsWpxcWZ-XlA6RSnUvM0g2T_VFdHt4wc3wyoxvjk_BSE7loA2XYnLQ.acK
I/flutter (19748): ║              8ww.M823DM5D_hDVgWqTij2ZxEdWFos"
I/flutter (19748): ║             "user": {email: alanjesus2422@gmail.com, id: 286, name: Alan Gonzalez}
I/flutter (19748): ║        }
I/flutter (19748): ║         "message": "Login exitoso",
I/flutter (19748): ║         "success": true
I/flutter (19748): ║    }
I/flutter (19748): ║
I/flutter (19748): ╚══════════════════════════════════════════════════════════════════════════════════════════╝
I/flutter (19748): 
I/flutter (19748): ╔╣ Request ║ POST 
I/flutter (19748): ║  https://theoriginallab-api-apptolv2-dev.m0oqwu.easypanel.host/api/auth/exchange
I/flutter (19748): ╚══════════════════════════════════════════════════════════════════════════════════════════╝
I/flutter (19748): ╔ Body 
I/flutter (19748): ╟ enc: 
I/flutter (19748): ║ rqNo6/xa5NkQNq8Ibhhmu1BrJDCvbDljtEzFW9vWDH19yYkWtAnr/IJhAnmnO3ozeZNMecoAWVpZHe+BNpkA1vnrrg
I/flutter (19748): ║ W9eC4w7Zje0PqmX41nmXT1LAvQqwxQN5kMLvhOukaJEH132BrrvosXwAOofsEUoP+JixFFFyHWGvHcjHG+V8dREbw=
I/flutter (19748): ╚══════════════════════════════════════════════════════════════════════════════════════════╝
I/flutter (19748): ║ {enc: rqNo6/xa5NkQNq8Ibhhmu1BrJDCvbDljtEzFW9vWDH19yYkWtAnr/IJhAnmnO3ozeZNMecoAWVpZHe+BNpkA
I/flutter (19748): ║ 1vnrrgW9eC4w7Zje0PqmX41nmXT1LAvQqwxQN5kMLvhOukaJEH132BrrvosXwAOofsEUoP+JixFFFyHWGvHcjHG+V8
I/flutter (19748): ║ dREbw=}
I/flutter (19748): 
I/flutter (19748): ╔╣ DioError ║ DioExceptionType.unknown
I/flutter (19748): ║  null
I/flutter (19748): ╚══════════════════════════════════════════════════════════════════════════════════════════╝
I/flutter (19748): 
I/flutter (19748): ╔╣ Request ║ POST 
I/flutter (19748): ║  https://theoriginallab-api-originalauth-desa.m0oqwu.easypanel.host/api/register
I/flutter (19748): ╚══════════════════════════════════════════════════════════════════════════════════════════╝
I/flutter (19748): ╔ Body 
I/flutter (19748): ╟ email: correorpieua@gmail.col
I/flutter (19748): ╟ name: alan
I/flutter (19748): ╟ password: YTEyMzQ1Njc=
I/flutter (19748): ╟ phone: 
I/flutter (19748): ╟ profile_img: null
I/flutter (19748): ╚══════════════════════════════════════════════════════════════════════════════════════════╝
I/flutter (19748): ║ {email: correorpieua@gmail.col, name: alan, password: YTEyMzQ1Njc=, phone: , profile_img: 
I/flutter (19748): ║ null}
I/flutter (19748): 
I/flutter (19748): ╔╣ Response ║ POST ║ Status: 201 Created  ║ Time: 2147 ms
I/flutter (19748): ║  https://theoriginallab-api-originalauth-desa.m0oqwu.easypanel.host/api/register
I/flutter (19748): ╚══════════════════════════════════════════════════════════════════════════════════════════╝
I/flutter (19748): ╔ Body
I/flutter (19748): ║
I/flutter (19748): ║    {
I/flutter (19748): ║         "data": {},
I/flutter (19748): ║         "message": "Usuario registrado con éxito",
I/flutter (19748): ║         "success": true
I/flutter (19748): ║    }
I/flutter (19748): ║
I/flutter (19748): ╚══════════════════════════════════════════════════════════════════════════════════════════╝
