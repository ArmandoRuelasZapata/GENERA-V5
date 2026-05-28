# Escalabilidad y Multicanalidad del Sistema de Tickets

## ¿Es posible reutilizar el sistema de tickets en otras apps o sitios webs?

**Sí, absolutamente.**

El sistema de tickets actual está construido como una **API REST independiente** utilizando **Dart Frog** (`api_crudrodval_dart`), respaldada por una base de datos PostgreSQL. Esto significa que la lógica de negocio, las reglas y los datos no están amarrados exclusivamente a la aplicación de Flutter ("The Original Lab"). 

Cualquier plataforma o lenguaje (React, Angular, Vue, iOS nativo, Android nativo, etc.) que tenga la capacidad de realizar peticiones HTTP estándar puede conectarse y consumir este mismo sistema en tiempo real.

---

## Documentación Técnica de Integración

Para que los desarrolladores web o móviles puedan conectarse, aquí están las especificaciones exactas que necesitan:

### 1. URL Base y Entornos
Todas las peticiones mostradas a continuación deben ir precedidas de la URL del servidor correspondiente. Se requiere obligatoriamente enviar la cabecera `apikey: tu_clave_de_acceso` en todas las peticiones.

*   **Desarrollo (Local):** `http://localhost:8080/tickets`
*   **Producción:** `https://theoriginallab-api-apptolv2-dev.m0oqwu.easypanel.host/tickets`

*(Puedes encontrar el contrato completo interactivo en los archivos adjuntos **openapi_tickets.yaml** y **postman_tickets_collection.json**).*

### 2. Modelos de Datos (Esquema del Ticket)
Al crear o solicitar tickets, el formato estándar JSON devuelto por la API luce exactamente así:

```json
{
  "id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "user_id": "8b9e4a3b-21cc-4372-a567-0e02b2c3d90x",
  "title": "Problema con mi último pago",
  "description": "El cargo aparece doble en mi tarjeta de crédito.",
  "status": "SUBMITTED",
  "category": "PAYMENT",
  "priority": "HIGH",
  "created_at": "2026-02-26T10:00:00.000Z",
  "updated_at": "2026-02-26T10:05:00.000Z"
}
```
*   **IDs:** Tanto `id` como `user_id` son identificadores `UUID` en formato string.
*   **Valores exactos (Enum):**
    *   `status`: "SUBMITTED", "IN_REVIEW", "RESOLVED"
    *   `category`: "APP", "PAYMENT", "ORDER"
    *   `priority`: "LOW", "MEDIUM", "HIGH"

### 3. Flujo y Ciclo de Vida del Ticket
El ciclo de soporte sigue un orden lineal lógico que el equipo de frontend debe respetar al momento de diseñar interfaces o paneles:

`SUBMITTED` *(Recien creado)* -> `IN_REVIEW` *(Agente atendiendolo)* -> `RESOLVED` *(Cerrado)*

Actualmente, para reabrir un ticket, el administrador requeriría cambiar manualmente el status de `RESOLVED` de vuelta a `IN_REVIEW` mediante una solicitud `PUT` a la app.

### 4. Códigos de Estado y Manejo de Errores
La API utiliza códigos HTTP estándar para facilitar el debug.

*   **`200 OK`**: Petición exitosa. Devuelve el JSON del ticket o el listado.
*   **`400 Bad Request`**: Datos mal formados (Ej. falta el `user_id` al crear).
*   **`403 Forbidden`**: La `apikey` es incorrecta o no fue enviada.
*   **`404 Not Found`**: El ID del ticket solicitado o a eliminar no existe en base de datos.
*   **`500 Internal Server Error`**: Problema con la conexión de base de datos.
    
**Ejemplo de formato de error (400 Bad Request):**
```json
// En caso de que se intente crear un ticket sin "title" o "user_id"
"Missing title or user_id"
```
*(Nota: Actualmente los errores devuelven un String simple, se recomienda a futuro estandarizarlos a formato JSON).*

### 5. Primeros Pasos (Quickstart): Crea tu primer ticket

Copia y pega este código en tu terminal para probar la API al instante (Asegúrate de cambiar `TU_USER_ID_AQUI` y tu `apikey` real):

**Ejemplo usando cURL:**
```bash
curl -X POST http://localhost:8080/tickets \
  -H "apikey: tu_clave_de_acceso" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "TU_USER_ID_AQUI",
    "title": "Prueba de integración",
    "description": "Verificando conexión desde nuevo sitio web.",
    "category": "APP",
    "priority": "MEDIUM"
  }'
```

### 6. Paginación y Endpoints Principales

*   **Listar (`GET /tickets`):** 
    *   Actualmente esta ruta devuelve **todos** los tickets del sistema o todos los tickets filtrados por usuario (`?user_id=123`). 
    *   *Nota para desarrollo futuro:* **Aún no soporta paginación** (parámetros `limit` ni `offset`). Si el volumen de datos crece significativamente, será necesario implementar paginación del lado del servidor.
*   **Obtener Especial (`GET /tickets/[id]`)**
*   **Cambiar Estatus (`PUT /tickets/[id]`)**
*   **Eliminar (`DELETE /tickets/[id]`)**
*   **Cargar Chat (`GET /tickets/[id]/messages`)**
*   **Responder Chat (`POST /tickets/[id]/messages`)**

---

## Ventajas de la Arquitectura Centralizada

1. **Centralización (Single Source of Truth):** Todos los tickets, provengan del sitio, tienda o móvil, van a la misma base de datos.
2. **Panel de Soporte Único:** Tu equipo de atención no necesita revisar diferentes sistemas. Pueden tener un único dashboard web para contestar simultáneamente.
3. **Desacoplamiento Front/Back:** El equipo de desarrollo actualizará los diseños en la web sin afectar la app móvil.

## Recomendaciones de Seguridad Generales

1. **Nuevas API Keys:** Genera en base de datos una clave individual por plataforma (ej: `WEB_REACT_TICKETS_KEY`, `APP_FLUTTER_KEY`).
2. **CORS en Producción:** Cuando pasen a dominio real, actualicen el archivo `_middleware.dart` para cambiar `Access-Control-Allow-Origin: *` por los dominios web exactos de su empresa. 
