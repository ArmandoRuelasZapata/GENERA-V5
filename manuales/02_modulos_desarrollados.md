# 02 - Modulos desarrollados

## 1. Objetivo de este documento

Inventariar los modulos funcionales implementados en la aplicacion y describir:

- Que resuelven
- Componentes tecnicos principales
- Integraciones
- Estado funcional actual

## 2. Resumen por modulo

| Modulo | Objetivo | Estado |
|---|---|---|
| Auth | Acceso, registro, recuperacion de cuenta | Activo |
| Home + Content | Inicio dinamico y secciones comerciales | Activo |
| Store | Catalogo de productos y puente a tienda | Activo (con partes "proximamente") |
| Tickets | Soporte tecnico (usuario y panel soporte) | Activo |
| Meetings | Agendamiento de citas y consulta de agenda | Activo |
| Chatbot | Asistente comercial con IA y agendamiento | Activo |
| Notifications | Push FCM + bandeja local | Activo |
| WebView | Acceso a servicios web externos | Activo |
| Maps | Ubicacion de sucursal en Google Maps | Activo |
| Core/Shared | Infraestructura transversal | Activo |

## 3. Módulo Auth

### 3.1 Propósito (Contexto de Negocio)
Garantizar el acceso seguro y la identidad de los usuarios a través del ciclo de vida completo de autenticación. Permite a The Original Lab recolectar leads verificados (email y teléfono) para el equipo comercial y asegurar el soporte técnico a los clientes existentes.

### 3.2 Componentes Clave

- **Providers:** `authProvider` (`AuthNotifier`, `AuthState`)
- **Data Layer:** `AuthRemoteDataSourceImpl`, `AuthLocalDataSourceImpl`, `AuthRepositoryImpl`
- **Screens:** `login_screen`, `register_screen`, `forgot_password_screen`, `verify_code_screen`, `change_password_screen`

### 3.3 Integraciones y Endpoints

| Método | Endpoint | Funcionalidad |
|---|---|---|
| `POST` | `/api/login` | Validación de credenciales y obtención de token |
| `POST` | `/api/register` | Creación de nuevo usuario |
| `POST` | `/api/email_reset_password` | Solicitud de código de recuperación |
| `POST` | `/api/verify_code` | Validación de token numérico temporal |
| `POST` | `/api/change_password` | Establecimiento de nueva contraseña |

### 3.4 Reglas funcionales relevantes

- Password enviada en Base64 al backend.
- Login exitoso guarda token y datos de usuario en secure storage.
- Sesion validada por TTL (`expires_in`) y `login_at`.
- Timeout de inactividad de 15 min para cierre de sesion.

## 4. Modulo Home + Content

## 4.1 Proposito

Mostrar landing principal de la app con informacion dinamica:

- Carrusel de servicios
- Productos destacados
- Casos de exito
- Secciones institucionales

## 4.2 Componentes clave

- `home_data_provider.dart` (fuente remota con fallback local)
- `content_providers.dart` (sliders/items/cursos/tarjetas)
- `home_tab.dart` y widgets asociados (`home_hero_carousel`, `home_quick_actions`, etc)

## 4.3 Fuentes de datos

- Endpoint home con candidatos:
  - `/home`
  - `/api/home`
  - `/api/v1/home`
- Datasource local de respaldo (`LocalDataSource`) para continuidad operativa si falla remoto.

## 4.4 Estado actual

- Funcional y con fallback implementado.
- Permite degradacion controlada ante errores de red.

## 5. Módulo Store

### 5.1 Propósito (Contexto de Negocio)
Exhibir el catálogo completo de productos tecnológicos y servicios de software de The Original Lab para fomentar la conversión. Sirve como escaparate digital para clientes actuales y prospectos.

### 5.2 Componentes Clave

- **Provider:** `productsProvider`
- **Repositorio:** `ApiProductsRepository`
- **Pantallas:** `store_tab.dart`, `product_list_screen.dart`

### 5.3 Integración

| Método | Endpoint | Funcionalidad |
|---|---|---|
| `GET` | `/api/products` | Obtiene el catálogo paginado de productos y servicios |

### 5.4 Estado Actual

> [!WARNING]
> La navegación y visualización del catálogo está 100% operativa, pero las funciones de _checkout_ y pasarelas de pago (`StoreTab`) se encuentran maquetadas bajo el estado comunicacional de "Próximamente".

- Catalogo actual funcional.
- `StoreTab` comunica funcionalidades de pagos como "proximamente".

## 6. Módulo Tickets (Soporte)

### 6.1 Propósito (Contexto de Negocio)
Proveer un canal directo, trazable y seguro para la resolución de incidentes técnicos. Diferencia la aplicación de un simple "sitio web" al ofrecer un servicio B2B profesional donde los clientes gestionan la vida útil de sus desarrollos.

### 6.2 Componentes Clave

- **Providers:** `activeTicketsProvider`, `historyTicketsProvider`, `ticketThreadProvider`, `createTicketProvider`, `adminAllTicketsProvider`
- **Repo:** `ApiTicketsRepository`
- **Screens:** `tickets_screen`, `ticket_create_screen`, `ticket_detail_screen`, `service_tickets_screen`

### 6.3 Integraciones

| Método | Endpoint | Funcionalidad |
|---|---|---|
| `GET/POST`| `/tickets` | Listado y creación de incidencias |
| `GET` | `/tickets/{id}` | Metadatos de un ticket específico |
| `GET/POST`| `/tickets/{id}/messages` | Hilo de comunicación del ticket |
| `POST` | `/upload` | Carga de adjuntos visuales |

## 6.4 Detalles tecnicos relevantes

- Hilo con polling cada 5 segundos.
- Mensajeria soporta texto e imagenes (max 5 MB por archivo en UI).
- Validacion de sesion activa para crear ticket.
- Clasificacion de listas por estado (activos vs resueltos/cerrados).

## 7. Módulo Meetings (Agenda)

### 7.1 Propósito (Contexto de Negocio)
Convertir leads cálidos en clientes al permitir agendas sincronizadas (Sales Call, Soporte, Consultorías). Elimina el choque humano operando consultas automatizadas contra el calendario corporativo.

### 7.2 Componentes Clave

- **Providers:** `servicesProvider`, `bookingNotifierProvider`, `timeSlotsProvider`, `meetingsListProvider`, `myAppointmentsProvider`
- **Servicios/Repos:** `BookingWebhookService`, `WebhookMeetingsRepository`
- **Screens:** `service_selection_screen`, `availability_screen`, `confirmation_screen`, `my_appointments_screen`

### 7.3 Integraciones

| Método | Destino (Microservicio/Webhook) | Funcionalidad |
|---|---|---|
| `GET` | Webhook `AGENDA_WEBHOOK_URL` | Recupera restricciones de agenda en tiempo real. |
| `POST`| Webhook `SCHEDULE_WEBHOOK_URL`| Confirma un slot asíncronamente y lo reserva. |

### 7.4 Detalles Operativos
- **Time Boxing:** Genera bloques predefinidos locales de disponibilidad de 08:00 a 18:00.
- **Prevención de Clash:** Cruza dinámicamente el JSON del webhook externo contra los huecos teóricos para mostrar solo slots 100% libres.

---

## 8. Módulo Chatbot (Integración IA)

### 8.1 Propósito (Contexto de Negocio)
Servir como agente de atención de primer nivel disponible 24/7. Su base de conocimiento lo orienta a venta cruzada, resolución de dudas corporativas e instigación de reservas.

### 8.2 Componentes Clave

- **Provider:** `chatbotProvider` (`ChatbotNotifier`)
- **Repo / Servicio:** `OpenAiChatbotRepository`, `OpenAiChatbotService`, `AppointmentService`
- **UI:** `chatbot_screen`, `chatbot_view`, Floating Action Button Global (FAB).

### 8.3 Integraciones

| Integración | Uso Categórico |
|---|---|
| **OpenAI (Chat Completions)** | Modelado de personalidad y NLP. |
| **Bypass Webhook (Agenda)** | Consulta de slots libres delegada por detección de intenciones de IA. |

### 8.4 Lógica Distintiva
> [!NOTE]
> El prompt del sistema está afinado para ventas, obligándolo a incluir una firma estructurada oculta `[AGENDAR_CITA]...[/AGENDAR_CITA]`. Cuando el Regex identifica esta bandera, la UI pausa la conversación del chat y activa el bloque de confirmación gráfica de reservas, logrando un flujo híbrido Chat-UI.

---

## 9. Módulo Notifications (FCM)

### 9.1 Propósito (Contexto de Negocio)
Retención masiva y engagement directo con el dispositivo a través de campañas o alertas transaccionales (como "Tu ticket fue respondido").

### 9.2 Componentes Clave

- **Servicios:** `FcmService`, `LocalNotifications`
- **Provider:** `notificationsProvider`, `unreadCountProvider`
- **UI:** `notifications_screen`, Componente `notification_card` y Badge rojo en AppBar.

### 9.3 Capacidades y Restricciones
- Orquesta escenarios _Foreground_ (Banner Local UI) y _Background / Terminated_ (Inyección de bandeja en despertar).
- Límite circular duro: **50 notificaciones** retenidas físicamente en memoria para evitar colapso de base local (App Bloat).

---

## 10. Módulo WebView Entornos Corporativos

### 10.1 Propósito (Contexto de Negocio)
Proveer acceso modular a subsistemas B2B que, por su volatilidad e inmensidad, resultan insostenibles nativamente (como plataformas e-learning o motores de render).

### 10.2 Componentes Clave
- Enrutamiento: `webview_urls.dart` actúa como un registro DNS de accesos híbridos.

### 10.3 Destinos Principales Embebidos
- Flujos de Cotización Complejos.
- *The Original Lab Academia* (E-learning).
- Generador de logotipos asistido y Reservas Cowork Space.

---

## 11. Módulo Navigation Maps

### 11.1 Propósito
Geolocalizar las oficinas matrices y fomentar visitas B2B trasladando las coordenadas de la app hacia el centro de Google Maps nativo.

### 11.2 Interacción
> El `MapScreen` incluye un componente temático nocturno pre-renderizado. El botón flotante de _Indicaciones_ levanta un Intent del sistema abriendo `url_launcher` con URI geo-precisa.

---

## 12. Módulos Transversales (Core & Shared)

| Capa | Responsabilidades |
|---|---|
| **Core** | Control de variables `.env`, _Network Interceptors_ y manejo absoluto de fallas (`ErrorMapper`). Tematización (Colores/Tipografía). |
| **Shared** | _Dependency Injection Container_ (`providers.dart`). Widgets atómicos reutilizables (Botones de gradiente, Spinners adaptativos y Tarjetas vacías). |

---

## 13. Estado Global del Producto a Fecha

### 13.1 Funciones Listas (100% Producción)
1. **Autenticación End-to-End** (Login/Register/PWD Reset + Limpieza temporal).
2. **Tablero Dinámico** (API-Driven Home).
3. **Mesa de Ayuda Interactiva** (Tickets Multi-Adjuntos + Admin Views).
4. **Agente IA Vendedor** (Chatbot Híbrido con reservas inyectadas).
5. **Notificaciones Push Activas.**

### 13.2 Bloques en Evolución (Deuda Planificada)
> [!WARNING]
> - Partes del ecosistema de usuario (Perfil / Métricas B2B / Preferencias Granulares) muestran vistas preliminares ("Próximamente").
> - La vitrina de Store está funcional como expositor, pero sin puente de Check-Out nativo.

---

## 14. Documentación Recomendada QA & Soporte

Para salvaguardar el nivel de código frente a rotaciones, las siguientes auditorías quedan delegadas:
1. **Matriz de Permisología:** Levantar listado de accesos Usuario / Empresa / Admin frente a los menús.
2. **KPIs Frontend:** Telemetría de renders, LCP (Largest Contentful Paint) para _Home Tab_.
3. **Pruebas E2E.**
