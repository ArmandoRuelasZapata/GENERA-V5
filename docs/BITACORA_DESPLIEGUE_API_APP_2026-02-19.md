# Bitácora de Cambios - Despliegue API + App

**Fecha de corte:** 19 de febrero de 2026  
**Proyecto:** The Original Lab v2 (App Flutter + API Dart Frog)  
**Entornos involucrados:** Local, servidor productivo (EasyPanel)

## 1. Objetivo

Consolidar el backend y la app móvil/web para operar contra infraestructura real:

- Migrar datos de tablas legacy desde entorno local hacia base de datos de servidor.
- Ajustar API para usar la base de datos productiva.
- Desplegar API en EasyPanel.
- Configurar la app Flutter para consumir la API publicada.
- Validar endpoints críticos (`/health`, `/home`, tickets).

## 2. Cambios Ejecutados (Resumen Ejecutivo)

1. Se preparó estrategia de aislamiento legacy por fases (compatibilidad con vistas).
2. Se ejecutaron respaldos antes de cambios estructurales.
3. Se migraron tablas completas de DB local a DB real en servidor.
4. Se actualizó configuración de la API para apuntar a DB productiva.
5. Se desplegó la API en EasyPanel con variables de entorno.
6. Se reconfiguró la app Flutter para consumir host real de EasyPanel.
7. Se diagnosticó error `502` y se confirmó causa operativa: servicio apagado en EasyPanel.
8. Se reactivó el servicio y se dejó flujo listo para validación final en app.

## 3. Detalle Técnico por Componente

### 3.1 Base de Datos

- Se trabajó con enfoque **safe rollout** (aislamiento legacy por fases).
- Se realizaron respaldos previos a cada cambio crítico.
- Se aplicó migración de tablas desde entorno local al servidor real.
- Se mantuvo compatibilidad para consumo legacy durante transición.

Estado:
- Datos ya consolidados en DB real del servidor.
- API configurada para consumir DB remota.

### 3.2 API (Dart Frog / EasyPanel)

Variables de entorno configuradas en EasyPanel:

- `PORT=8080`
- `DB_HOST=89.116.187.217`
- `DB_PORT=5437`
- `DB_NAME=apptol`
- `DB_USER=adminApptol`
- `DB_PASSWORD=***`
- `DB_SSL_MODE=disable`
- `LEGACY_CONTENT_ENABLED=false`

Rutas verificadas en código de API:

- `GET /health` (ruta de vida del servicio)
- `GET /home` (contenido home dinámico)
- `GET/POST /tickets` y subrutas de mensajes

Incidencia detectada:
- Se presentó `502 Bad Gateway` en `/health` y `/home`.
- Diagnóstico: el servicio en EasyPanel estaba apagado/no disponible.
- Acción: encendido del servicio para restablecer disponibilidad.

### 3.3 App Flutter

Archivo actualizado:
- `.env.dev.json`

Cambios de conexión:

- `CONTENT_API_BASE_URL` -> `https://theoriginallab-api-apptolv2-dev.m0oqwu.easypanel.host`
- `TICKETS_API_BASE_URL` -> `https://theoriginallab-api-apptolv2-dev.m0oqwu.easypanel.host`
- `AUTH_API_BASE_URL` se mantuvo en host de auth separado.

Robustez adicional implementada en app:

- Fallback de endpoint Home en cliente:
  - `/home`
  - `/api/home`
  - `/api/v1/home`

Archivos de app ajustados:

- `lib/core/constants/api_constants.dart`
- `lib/features/home/presentation/providers/home_data_provider.dart`
- `.env.dev.json`

## 4. Evidencia Operativa / Diagnóstico

Síntoma observado:
- `DioException` con `502 Bad Gateway` al consultar host de EasyPanel.

Hallazgo clave:
- `502` también en `GET /health`, lo que descarta error de ruta de negocio y apunta a indisponibilidad del contenedor/proxy backend.

Conclusión:
- El incidente no era de código de app ni del endpoint `home`; era de estado del servicio en EasyPanel.

## 5. Estado Final

- DB real: **Configurada y operativa**.
- API con variables productivas: **Configurada**.
- Despliegue en EasyPanel: **Levantado** (tras reactivar servicio).
- App apuntando a API real: **Configurada**.
- Integración Home/Tickets/Auth: **Lista para validación funcional final**.

## 6. Checklist de Cierre

- [x] Respaldos realizados antes de migración.
- [x] Migración local -> servidor completada.
- [x] API conectada a DB real.
- [x] API desplegada en EasyPanel.
- [x] App configurada con host real.
- [x] Diagnóstico y resolución de `502` por servicio apagado.
- [ ] Validación E2E final en app (login, home, tickets, envío de mensaje).
- [ ] Monitoreo post-despliegue 24-48h (logs API, errores 5xx, tiempos de respuesta).

## 7. Recomendaciones para el Reporte

1. Incluir esta bitácora como anexo técnico.
2. Adjuntar captura de EasyPanel en estado `Running`.
3. Adjuntar evidencia de:
   - `GET /health` = 200
   - `GET /home` = 200 con `apikey`
4. Registrar ventana de monitoreo de 24-48h antes de declarar cierre total.
