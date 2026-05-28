# The Original Lab — v2

![Flutter](https://img.shields.io/badge/Flutter-estable-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3-0175C2?logo=dart&logoColor=white)
![Next.js](https://img.shields.io/badge/Next.js-14-000000?logo=nextdotjs&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-activo-FFCA28?logo=firebase&logoColor=black)
![Estado](https://img.shields.io/badge/estado-en%20desarrollo-yellow)

Aplicación Flutter para **The Original Lab**. El repositorio incluye también un CMS web (Next.js) para administrar el contenido del Home y gestionar tickets de soporte.

---

## Contenido

- [Estructura del repositorio](#estructura-del-repositorio)
- [Stack tecnológico](#stack-tecnológico)
- [Requisitos previos](#requisitos-previos)
- [Configuración del entorno](#configuración-del-entorno)
- [Setup rápido](#setup-rápido)
- [Generación de código](#generación-de-código)
- [Pruebas](#pruebas)
- [Compilación para producción](#compilación-para-producción)
- [CMS (Next.js)](#cms-nextjs)
- [Scripts útiles](#scripts-útiles)
- [Documentación](#documentación)
- [Troubleshooting](#troubleshooting)

---

## Estructura del repositorio

```
/
├── lib/              # Aplicación móvil — Flutter (Clean Architecture)
├── assets/           # Recursos gráficos de la app
├── CMS app/          # CMS web — Next.js (Home + soporte)
├── docs/             # Documentación funcional, QA y seguridad
└── scripts/          # Scripts de build y seguridad
```

---

## Stack tecnológico

| Capa | Tecnología |
|---|---|
| **App móvil** | Flutter + Dart 3 |
| **Estado / navegación** | Riverpod, GoRouter |
| **Red** | Dio |
| **Firebase** | Analytics, Messaging, In-App Messaging |
| **Secrets** | Envied (build-time) |
| **CMS** | Next.js 14 |

---

## Requisitos previos

| Herramienta | Versión | Necesario para |
|---|---|---|
| Flutter | Canal estable | App móvil |
| Dart | Incluido con Flutter | App móvil |
| Android Studio / Xcode | Última estable | Emuladores y builds |
| Node.js | 20+ | CMS únicamente |

---

## Configuración del entorno

> ⚠️ **Nunca hardcodees credenciales en el código.** La app usa archivos `.env.*.json` que están excluidos del repositorio vía `.gitignore`.

### 1. Crear el archivo de configuración

```bash
cp .env.template.json .env.dev.json
```

### 2. Completar con credenciales reales

Edita `.env.dev.json` (debe ser JSON válido, sin comentarios):

```json
{
  "AUTH_API_BASE_URL":     "https://api.tu-dominio.com",
  "CONTENT_API_BASE_URL":  "https://api.tu-dominio.com",
  "TICKETS_API_BASE_URL":  "https://api.tu-dominio.com",
  "CONTENT_API_KEY":       "tu_api_key_real",
  "AI_PROXY_URL":          "https://api.tu-dominio.com",
  "OPENAI_API_KEY":        "",
  "AGENDA_WEBHOOK_URL":    "https://hook.us2.make.com/...",
  "SCHEDULE_WEBHOOK_URL":  "https://hook.us2.make.com/...",
  "ENABLE_NETWORK_LOGS":   true
}
```

### Configuración del chatbot IA

| Opción | Variable | Cuándo usar |
|---|---|---|
| **A — Recomendada (prod)** | `AI_PROXY_URL` | La API key nunca viaja en el cliente |
| **B — Fallback (dev/local)** | `OPENAI_API_KEY` | Solo para desarrollo local |

> Si `AI_PROXY_URL` está configurado, `OPENAI_API_KEY` es ignorada automáticamente.

### Reglas importantes

- Las `BASE_URL` van **sin** sufijo `/api` → ✅ `https://api.tu-dominio.com`
- Los endpoints ya incluyen el prefijo `/api/...` donde corresponde.

### Ambientes disponibles

| Ambiente | Archivo |
|---|---|
| Desarrollo | `.env.dev.json` |
| Producción | `.env.prod.json` |

---

## Setup rápido

```bash
flutter pub get
flutter run --dart-define-from-file=.env.dev.json
```

---

## Generación de código

```bash
dart run build_runner build -d
```

---

## Pruebas

```bash
# Pruebas unitarias e integración
flutter test

# Pruebas en modo release
flutter run --release --dart-define-from-file=.env.prod.json
```

---

## Compilación para producción

> ⚠️ Es **obligatorio** usar ofuscación en todos los builds de producción.

### APK

```bash
flutter build apk --release \
  --obfuscate \
  --split-debug-info=build/debug-info \
  --dart-define-from-file=.env.prod.json
```

### App Bundle (Play Store)

```bash
flutter build appbundle --release \
  --obfuscate \
  --split-debug-info=build/debug-info \
  --dart-define-from-file=.env.prod.json
```

> Antes de subir a Play Store, actualiza `version: x.y.z+build` en `pubspec.yaml` (ej. `2.0.0+2`).

### Script automatizado

```bash
./scripts/build_release.sh
```

Incluye checklist de verificación pre-build.

---

## Validación de configuración al inicio

La app valida al arrancar que todas las configuraciones críticas estén presentes:

| Modo | Comportamiento |
|---|---|
| **Debug** | Advertencias en consola si falta algo |
| **Release** | La app falla inmediatamente (*fail fast*) si falta algo crítico |

---

## CMS (Next.js)

El CMS vive en `CMS app/` y permite administrar el contenido del Home y los tickets de soporte. Para más detalle, lee `CMS app/README.md`.

### Inicio rápido

```bash
cd "CMS app"
npm install
npm run dev
```

Abre: `http://localhost:3000/login`

### Variables de entorno requeridas

| Variable | Descripción |
|---|---|
| `API_BASE_URL` | URL base del backend |
| `API_KEY` | Clave de acceso a la API |
| `PAYLOAD_ENCRYPTION_KEY` | Clave de cifrado del payload |

Aplica tanto para entorno local como para despliegue en EasyPanel.

---

## Scripts útiles

| Script | Descripción |
|---|---|
| `scripts/build_release.sh` | Build release con ofuscación y checklist de verificación |
| `scripts/update_pinning_cert.sh <host> [output_pem_path]` | Actualiza el certificado de certificate pinning |

---

## Documentación

| Documento | Descripción |
|---|---|
| `docs/POLITICA_DE_PRIVACIDAD.md` | Política de privacidad |
| `docs/testing_strategy.md` | Estrategia de pruebas |
| `docs/security_checklist.md` | Checklist de seguridad |
| `docs/REPORTE_SEGURIDAD_OWASP_MOBILE_2026.md` | Reporte OWASP Mobile 2026 |

---

## Troubleshooting

| Síntoma | Solución |
|---|---|
| Falta una variable crítica al inicio | Revisa el archivo `.env.*.json` y el flag `--dart-define-from-file` |
| El backend responde `404` | Confirma que las base URLs **no** incluyan `/api` al final |
