# Auditoría Prelanzamiento - The Original Lab v2

Fecha: 2026-02-25
Alcance: Usabilidad, flujos completos, velocidad de respuesta, registro/priorización de incidencias y ajustes finales de UX.

## 1) Evidencia técnica ejecutada
- `flutter analyze`: OK (sin issues).
- `flutter test`: OK (suite completa aprobada).
- Métrica observada en pruebas de rendimiento actuales: `Scroll Action Duration: 321ms` (umbral del test: < 5000ms).

Nota: la prueba de `startup_sanity_test` valida construcción de widget en entorno de test; no mide cold start real en dispositivo físico.

## 2) Incidencias priorizadas

### P1 - Alta (corregidas)
1. `Tickets` con separación superior rígida que podía desalinearse según dispositivo/notch.
   - Riesgo: superposición o corte visual en diferentes pantallas.
   - Solución aplicada: cálculo dinámico con `MediaQuery + kToolbarHeight`.

2. Pull-to-refresh de tickets no esperaba recarga real de providers.
   - Riesgo: sensación de “refrescar no funciona”.
   - Solución aplicada: refresh asíncrono con `Future.wait` sobre providers `active/history`.

3. Catálogo con grilla fija (2 columnas), menos usable en tablets/ancho grande.
   - Riesgo: densidad visual ineficiente y mala escalabilidad.
   - Solución aplicada: grilla responsive (2/3/4 columnas según ancho).

4. Carga de imágenes de productos sin fallback explícito al fallar asset.
   - Riesgo: error visual severo en pruebas si hay ruta inválida.
   - Solución aplicada: `errorBuilder` en tarjeta y detalle de producto.

5. Fuga de datos (aislamiento) en el Historial de Citas (Appointments).
   - Riesgo: Todos los usuarios podían ver la agenda completa del webhook, incluyendo citas de terceros (vulnerabilidad de privacidad).
   - Solución aplicada: Filtrado local post-fetch en `WebhookMeetingsRepository` comparando `email` y `name` del usuario activo.

### P2 - Media (corregidas)
1. Chips de categorías implementadas con `GestureDetector` (menor semántica/accesibilidad).
   - Solución aplicada: migración a `ChoiceChip`.

2. CTA “Notificarme del lanzamiento” en tienda sin feedback.
   - Riesgo: percepción de botón roto.
   - Solución aplicada: `SnackBar` de confirmación inmediata.

### P3 - Baja (Pendientes)
1. Sección de Perfil con opciones en estado “Próximamente” (`Editar Perfil`, `Seguridad`, `Notificaciones`, `Idioma`).
   - Riesgo: feedback negativo de testers por funcionalidades no terminadas.
   - Recomendación: etiquetarlas como beta en UI o esconderlas temporalmente para la ronda externa.

2. Logs de depuración abundantes en servicios (auth/FCM).
   - Riesgo: ruido operativo y exposición de trazas innecesarias.
   - Recomendación: encapsular `debugPrint` bajo `kDebugMode` donde aplique.

## 3) Cambios aplicados
- `lib/features/tickets/presentation/screens/tickets_screen.dart`
  - Padding superior adaptativo.
  - Refresh asíncrono real de tickets.
- `lib/features/home/presentation/screens/products_catalog_screen.dart`
  - Chips accesibles (`ChoiceChip`).
  - Grilla responsive por ancho de pantalla.
- `lib/features/home/presentation/widgets/product_catalog_card.dart`
  - Fallback visual con `errorBuilder` en imagen.
- `lib/features/home/presentation/screens/product_detail_screen.dart`
  - Fallback visual con `errorBuilder` en imagen.
- `lib/features/home/presentation/screens/store_tab.dart`
  - Feedback en botón “Notificarme del Lanzamiento”.
- `lib/features/auth/presentation/screens/register_screen.dart`
  - Limpieza de comentarios de deuda/ruido interno.

## 4) Recomendación para pruebas con usuarios externos
Checklist mínimo antes de compartir APK:
1. Login válido + inválido (mensajes claros, sin bloqueos).
2. Registro completo + navegación a pantalla de éxito.
3. Flujo de tickets: crear, listar, refrescar, abrir detalle.
4. Catálogo: filtrar por categoría, abrir detalle con y sin imagen.
5. Notificaciones: badge, marcar leídas, borrar individual/todas.
6. Navegación por tabs durante 3-5 minutos para detectar jank.

Registro sugerido para cada incidencia reportada por testers:
- Severidad (`P1/P2/P3`).
- Pantalla/flujo.
- Pasos para reproducir.
- Resultado esperado vs actual.
- Evidencia (video/captura).
- Dispositivo y versión de Android.
