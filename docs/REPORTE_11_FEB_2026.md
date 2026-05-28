# Reporte de Avance — Residencia Profesional
## The Original Lab — Aplicación Móvil Flutter

**Fecha:** 11 de febrero de 2026  
**Elaborado por:** Alan  
**Proyecto:** Integración de sistema de citas y chatbot con IA en la aplicación móvil de The Original Lab

---

## 1. Objetivo de la Sesión

Integrar el sistema de citas reales y el chatbot con inteligencia artificial dentro de la aplicación móvil, reemplazando los datos simulados (mock data) por conexiones reales a servicios externos de automatización (Make.com) y de inteligencia artificial (OpenAI GPT-4o-mini). Todo esto con el fin de que la aplicación permita a los usuarios agendar citas de forma autónoma, tanto desde el flujo manual (pantalla de citas) como desde el chatbot conversacional.

---

## 2. Actividades Realizadas

### 2.1. Integración del Chatbot con OpenAI

Se integró el chatbot de la aplicación con el modelo GPT-4o-mini de OpenAI para que pueda mantener conversaciones inteligentes con los usuarios. La integración incluyó:

- **Conexión con la API de OpenAI:** Se configuró la comunicación con el endpoint de OpenAI utilizando la librería Dio para peticiones HTTP. El chatbot mantiene un historial de conversación para dar continuidad al diálogo.

- **Prompt de sistema (seller prompt):** Se implementó el prompt de vendedor proporcionado por el equipo, el cual guía al chatbot para actuar como un asesor comercial de The Original Lab. Este prompt se integró de forma literal para mantener la personalidad y las instrucciones del negocio.

- **Arquitectura multi-flujo:** Se implementó una arquitectura con tres flujos de conversación, replicando el comportamiento de un bot de referencia en WhatsApp:
  - **Flujo Vendedor:** Flujo por defecto para atender consultas generales y de ventas.
  - **Flujo de Agenda:** Se activa cuando el usuario muestra intención de agendar una cita. Consulta el webhook de la agenda en tiempo real e inyecta los datos de disponibilidad al contexto de GPT.
  - **Flujo de Confirmación:** GPT recopila los datos paso a paso (nombre, correo, hora, interés) y cuando tiene todo, genera una etiqueta especial que dispara automáticamente el agendamiento a través del webhook.

- **Indicador de escritura (typing indicator):** Se implementó una animación de tres puntos que aparece mientras el chatbot procesa la respuesta, dando retroalimentación visual al usuario de que el sistema está trabajando.

- **Tarjetas de confirmación de cita:** Cuando el chatbot agenda una cita exitosamente, en lugar de mostrar solo texto plano, se muestra una tarjeta visual con los datos de la cita (servicio, fecha, hora) dentro del chat, mejorando la experiencia de usuario.

### 2.2. Integración de Webhooks de Make.com

Se integraron dos webhooks de Make.com que conectan la aplicación con Google Calendar:

- **Webhook de lectura de agenda:** Permite consultar las citas existentes en el calendario. La aplicación realiza una petición GET y recibe un arreglo JSON con las citas programadas, incluyendo fecha, hora y nombre del cliente.

- **Webhook de agendamiento:** Permite crear nuevas citas. La aplicación envía una petición POST con los datos del usuario (nombre, correo, teléfono, fecha/hora, interés del servicio) y el escenario de Make.com se encarga de crear el evento en Google Calendar y enviar un correo de confirmación.

### 2.3. Corrección de UX del Chatbot

Durante las pruebas del chatbot se detectaron y corrigieron dos problemas de experiencia de usuario:

- **Problema de teclado:** Cuando el usuario abría el teclado para escribir en el chatbot, el campo de texto quedaba oculto detrás del teclado. Se resolvió haciendo que la hoja inferior (bottom sheet) sea consciente del teclado, ajustando dinámicamente su altura según el espacio ocupado por el teclado.

- **Pérdida de conversación:** Al cerrar y reabrir el chatbot, la conversación se perdía. Esto ocurría porque el proveedor de estado estaba configurado con auto-dispose, lo que eliminaba el estado al cerrarse la interfaz. Se corrigió removiendo la auto-disposición para que la conversación persista durante toda la sesión de la aplicación.

### 2.4. Repositorio Real para el Módulo de Reuniones

El módulo de reuniones de la aplicación originalmente funcionaba con un repositorio simulado (MockMeetingsRepository) que almacenaba datos en memoria. Se creó un repositorio real (WebhookMeetingsRepository) que se conecta directamente con los webhooks de Make.com para crear y consultar reuniones. Los proveedores de estado se actualizaron para utilizar el repositorio real en lugar del simulado, integrando además los datos del usuario autenticado (nombre, correo) automáticamente al crear reuniones.

### 2.5. Sistema de Citas con Datos Reales

Se reemplazó todo el sistema de datos simulados del módulo de citas por conexiones reales:

- **Servicio de disponibilidad (BookingWebhookService):** Se creó un servicio que genera slots horarios de 08:00 a 18:00 y consulta la agenda real del webhook para determinar cuáles están ocupados. Cada slot es de 60 minutos y se marca como no disponible si existe un conflicto con una cita existente.

- **Pantalla de selección de servicio:** Se actualizó para reflejar los servicios reales de The Original Lab (Incubación de Proyectos, Consultoría TI, Desarrollo de Plataformas, Capacitación, Outsourcing, Alianzas Estratégicas). Se eliminaron los precios ya que todas las consultas son gratuitas, mostrando en su lugar una etiqueta de "Gratuito". Adicionalmente se agregó una opción de "Otro / Personalizado" con un campo de texto libre para cuando ningún servicio predefinido aplica.

- **Pantalla de disponibilidad:** Se actualizó para que los horarios se obtengan en tiempo real desde el webhook. La pantalla muestra un indicador de carga mientras consulta la agenda y un mensaje de error si la consulta falla, en lugar de mostrar todos los horarios como disponibles (lo cual podría causar doble agendamiento).

- **Pantalla de confirmación:** Se rediseñó para incluir campos de datos del cliente que el webhook necesita: nombre completo, correo electrónico, teléfono (opcional) y notas adicionales (opcional). Los campos de nombre y correo se prellenan automáticamente con los datos del usuario logueado. Se eliminaron las secciones de pago y total ya que las citas son gratuitas.

- **Historial de citas (Mis Citas):** Se conectó con el webhook de lectura de agenda para mostrar las citas reales. Las citas se clasifican automáticamente como "Próximas" o "Historial" según la fecha actual y se ordenan cronológicamente.

### 2.6. Corrección de Errores de Timeout

Durante las pruebas, la pantalla de "Mis Citas" mostró un error de timeout al consultar el webhook. El webhook de Make.com tiene tiempos de respuesta mayores a los 30 segundos configurados por defecto. Se incrementó el timeout a 60 segundos tanto en el servicio de reservas como en el proveedor de citas, resolviendo el problema.

### 2.7. Corrección de Persistencia de Estado en el Flujo de Reservas

Se detectó que al navegar entre las pantallas de selección → calendario → confirmación, los datos seleccionados por el usuario (servicio, fecha, hora) se perdían. Esto ocurría porque el proveedor de estado del flujo de reservas estaba configurado con auto-dispose. Se cambió a un proveedor persistente (keepAlive) para mantener el estado durante todo el flujo de agendamiento.

### 2.8. Mejoras en la Detección de Conflictos de Horarios

Se identificó una discrepancia entre la disponibilidad que reportaba el chatbot y la que mostraba el flujo manual. Se mejoró el servicio de disponibilidad con:

- **Manejo robusto de errores:** En lugar de fallar silenciosamente y mostrar todos los horarios como disponibles (riesgo de doble agendamiento), ahora los errores se propagan a la interfaz de usuario.

- **Parseo flexible de fechas:** Se amplió el soporte de formatos de fecha de 5 a 12+, incluyendo formatos estadounidense, europeo, ISO 8601 y variantes con y sin hora, más un respaldo con el parser nativo de Dart.

- **Registro de depuración:** Se agregaron logs de desarrollo que muestran en consola qué datos devuelve el webhook, cuántos se parsearon correctamente y cuáles fallaron, facilitando la depuración futura.

### 2.9. Disclaimer del Chatbot

Se agregó un mensaje discreto al pie del encabezado del chatbot que dice: "El asistente puede cometer errores. Verifica la información importante." Esto establece expectativas realistas para el usuario sobre las limitaciones inherentes de los asistentes de inteligencia artificial, similar a como lo hacen servicios como ChatGPT.

### 2.10. Documentación de Issues para el Equipo de Backend

Se creó un documento técnico (`docs/ISSUES_BACKEND.md`) dirigido al equipo de backend que detalla tres problemas identificados que requieren atención del lado del servidor:

1. **Hora incorrecta en correo de confirmación** — La zona horaria no está correcta en el escenario de Make.com.
2. **Historial muestra citas de todos los usuarios** — El webhook no tiene filtro por usuario; se necesita un parámetro de email o ID.
3. **Chatbot da horarios imprecisos** — GPT interpreta la agenda en vez de calcularla programáticamente.

---

## 3. Problemas Encontrados y Soluciones

| Problema | Causa Raíz | Solución Aplicada |
|----------|-----------|-------------------|
| Teclado tapaba el chat | El bottom sheet no consideraba el espacio del teclado | Se hizo la hoja consciente del teclado usando `MediaQuery.viewInsets` |
| Conversación del chat se perdía | Proveedor de estado con auto-dispose | Se removió el auto-dispose del proveedor |
| Datos de reuniones simulados | Repositorio mock en memoria | Se creó repositorio real conectado a webhooks |
| Slots de horario falsos (mock) | Datos hardcodeados | Conexión real al webhook de agenda |
| Timeout en "Mis Citas" | Webhook lento (>30s) | Timeout aumentado a 60 segundos |
| Servicio seleccionado se perdía | Proveedor de booking con auto-dispose | Se cambió a `keepAlive: true` |
| Horarios incorrectos en flujo manual | Parseo de fechas fallido silenciosamente | Parseo robusto con 12+ formatos y propagación de errores |
| Precios en servicios | Todos los servicios son gratuitos | Se eliminaron precios y se puso badge "Gratuito" |
| Sin opción personalizada | No había servicio genérico | Se agregó "Otro / Personalizado" con campo de texto |
| Sin datos de contacto | No se pedían datos del cliente | Se agregaron campos de nombre, email, teléfono y notas |
| Hora mal en correo | Timezone de Make.com | Documentado para equipo de backend |
| Historial muestra todas las citas | Webhook sin filtro por usuario | Documentado para equipo de backend |

---

## 4. Tecnologías y Herramientas Utilizadas

- **Flutter / Dart** — Framework de desarrollo de la aplicación móvil
- **Riverpod** — Gestión de estado reactivo
- **Dio** — Cliente HTTP para comunicación con APIs
- **OpenAI API (GPT-4o-mini)** — Motor de inteligencia artificial del chatbot
- **Make.com** — Plataforma de automatización que conecta la app con Google Calendar
- **Google Calendar** — Calendario donde se almacenan las citas
- **Freezed + build_runner** — Generación de código para modelos inmutables

---

## 5. Archivos Creados y Modificados

### Archivos nuevos:
- `openai_chatbot_service.dart` — Servicio de comunicación con OpenAI (historial, prompt, detección de intención)
- `appointment_service.dart` — Servicio de comunicación con webhooks de Make.com para el chatbot
- `openai_chatbot_repository.dart` — Repositorio que orquesta la lógica multi-flujo del chatbot
- `webhook_meetings_repository.dart` — Repositorio real de reuniones conectado a webhooks
- `booking_webhook_service.dart` — Servicio para consulta de disponibilidad y agendamiento vía webhooks
- `docs/ISSUES_BACKEND.md` — Documento de issues para el equipo de backend

### Archivos modificados:
- `api_constants.dart` — Constantes para URLs de OpenAI y webhooks de Make.com
- `chat_message.dart` — Entidad de mensaje con tipos (texto, typing, tarjeta de cita) y metadata
- `chatbot_provider.dart` — Proveedor del chatbot (repositorio real, indicador de typing, persistencia)
- `chatbot_view.dart` — Vista del chatbot (renderizado de indicador de typing y tarjetas de cita)
- `chatbot_floating_button.dart` — Burbuja del chatbot (teclado, disclaimer)
- `meetings_provider.dart` — Proveedor de reuniones (repositorio real, datos de auth)
- `booking_provider.dart` — Proveedor de estado del flujo de reservas (conexión real, campos de contacto, keepAlive)
- `service_selection_screen.dart` — Pantalla de selección de servicio (sin precios, opción personalizada)
- `availability_screen.dart` — Pantalla de disponibilidad (slots reales desde webhook)
- `confirmation_screen.dart` — Pantalla de confirmación (campos de contacto, sin sección de pago)
- `my_appointments_provider.dart` — Proveedor de historial de citas (datos reales, timeout aumentado)
- `service_entity.dart` — Entidad de servicio (precio opcional)
- `meeting_request.dart` — Entidad de solicitud de reunión (campo clientName)

---

## 6. Estado Actual y Siguiente Paso

### Funcionalidades completadas del lado de la app:
- Chatbot con IA funcional y conectado a OpenAI
- Agendamiento de citas desde el chatbot
- Agendamiento de citas desde el flujo manual
- Consulta de disponibilidad en tiempo real
- Historial de citas ("Mis Citas")
- Deteccion de conflictos de horarios
- Disclaimer de limitaciones de IA

### Pendientes del lado del backend:
- ⬜ Corregir zona horaria en correo de confirmación
- ⬜ Implementar filtro por usuario en webhook de agenda
- ⬜ Mejorar precisión del chatbot en horarios

---

*Reporte generado como parte de la documentación de Residencia Profesional.*
