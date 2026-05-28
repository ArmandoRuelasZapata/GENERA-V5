# Requerimientos de Backend para Tickets (Chat Abierto)

Este documento define la estructura para un sistema de tickets con **chat siempre abierto**. El usuario puede enviar mensajes en cualquier momento mientras el ticket no esté cerrado.

## 1. Concepto UX y Estados

El ticket funciona como un chat de soporte. El usuario puede **enviar mensajes libremente** en cualquier estado excepto `CLOSED`.

### Estados (Enum Oficial)
*   **SUBMITTED**: Ticket recién creado por el usuario. (**Chat abierto**).
*   **IN_REVIEW**: Soporte está revisando el caso. (**Chat abierto**).
*   **NEEDS_INFO**: Soporte solicita información adicional. (**Chat abierto**).
*   **RESOLVED**: Soporte propone una solución. (**Chat abierto**, usuario puede reabrir o cerrar).
*   **CLOSED**: Ticket finalizado. **Solo lectura, chat desactivado.**

### Regla de Chat
```
canUserSendMessage = (status != CLOSED)
```

### Transiciones Válidas
1.  `SUBMITTED` -> `IN_REVIEW` (Soporte toma el ticket).
2.  `IN_REVIEW` -> `NEEDS_INFO` (Soporte pide datos).
3.  `NEEDS_INFO` -> `IN_REVIEW` (Soporte retoma sin esperar respuesta del usuario).
4.  `IN_REVIEW` -> `RESOLVED` (Soporte resuelve).
5.  `RESOLVED` -> `CLOSED` (Usuario acepta o timeout).
6.  `RESOLVED` -> `IN_REVIEW` (Usuario no acepta la solución / reabre).

> **Nota**: El usuario puede enviar mensajes en CUALQUIER estado excepto CLOSED, sin que esto cambie el estado del ticket automáticamente. Los cambios de estado los maneja Soporte.

---

## 2. Endpoints Requeridos

### Tickets

*   `GET /api/v1/tickets`
    *   **Params**: `limit`, `cursor`, `status`, `sort` (default `-updatedAt`).
    *   **Respuesta**: `PaginatedResponse<Ticket>`.

*   `POST /api/v1/tickets`
    *   **Body**: `CreateTicketRequest`.
    *   **Efecto**: Crea ticket en estado `SUBMITTED`.

*   `GET /api/v1/tickets/{id}`
    *   **Respuesta**: `Ticket`. Valida ownership.

*   `PATCH /api/v1/tickets/{id}`
    *   **Propósito**: Cambiar estado por parte del usuario.
    *   **Transiciones Permitidas (Usuario)**:
        *   `RESOLVED` -> `CLOSED` (Confirmar solución).
        *   `RESOLVED` -> `IN_REVIEW` (Rechazar solución / Reabrir).
    *   **Validación**: Cualquier otra transición intentada por el usuario debe retornar `403 FORBIDDEN`.
    *   **Respuesta**: `Ticket` actualizado.

### Thread (Línea de tiempo / Chat)

*   `GET /api/v1/tickets/{id}/thread`
    *   **Params**: `limit`, `cursor`, `afterCursor` (para polling).
    *   **Respuesta**: `PaginatedResponse<TicketThreadItem>`.

*   `POST /api/v1/tickets/{id}/messages`
    *   **Body**: `CreateMessageRequest`.
    *   **Validación**:
        *   Usuario puede postear **siempre que** `ticket.status != CLOSED`.
        *   Si el ticket está `CLOSED`, retornar `409 INVALID_STATE`.
    *   **Efecto**: Guarda mensaje. No cambia el estado del ticket.

*   `POST /api/v1/tickets/{id}/read` (Opcional)
    *   **Propósito**: Marcar hilo como leído (resetear `unreadCount`).
    *   **Respuesta**: `{ "ok": true, "unreadCount": 0 }`

---

## 3. Modelo de Datos (JSON)

### Modelo: Ticket
```json
{
  "id": "uuid",
  "title": "string",
  "description": "string",
  "status": "SUBMITTED | IN_REVIEW | NEEDS_INFO | RESOLVED | CLOSED",
  "category": "ORDER | PAYMENT | APP | OTHER",
  "priority": "LOW | MEDIUM | HIGH",
  "unreadCount": 0,
  "lastMessageAt": "ISO 8601 UTC",
  "createdAt": "ISO 8601 UTC",
  "updatedAt": "ISO 8601 UTC",
  "closedAt": "ISO 8601 UTC | null"
}
```

> **Nota**: Ya no se incluye `canUserSendMessage` como campo del backend. El frontend lo calcula localmente: `status != CLOSED`.

### Modelo: TicketThreadItem (Unified)
Representa tanto mensajes como eventos del sistema (ej: "Ticket cambiado a En Revisión").

```json
{
  "id": "uuid",
  "ticketId": "uuid",
  "kind": "MESSAGE | EVENT",
  "senderType": "USER | SUPPORT | SYSTEM",
  "senderId": "uuid | null",
  "content": "string",
  "type": "TEXT | IMAGE | FILE",
  "attachments": [
    { "url": "string", "name": "string", "mimeType": "string", "size": 0 }
  ],
  "clientMessageId": "uuid | null",
  "createdAt": "ISO 8601 UTC"
}
```

---

## 4. Contrato de Errores

```json
{
  "error": "VALIDATION_ERROR | NOT_FOUND | UNAUTHORIZED | FORBIDDEN | INVALID_STATE | RATE_LIMITED",
  "message": "Descripción legible",
  "details": [{ "field": "string", "issue": "string" }],
  "traceId": "string"
}
```
*   `FORBIDDEN`: El ticket no pertenece al usuario autenticado.
*   `INVALID_STATE`: Cuando usuario intenta enviar mensaje en un ticket `CLOSED`.
*   `RATE_LIMITED`: Si intenta spam de tickets/mensajes.

---

## 5. Seguridad y Reglas

*   **Auth**: Header `Authorization: Bearer <token>` obligatorio. `userId` extraído del token.
*   **Idempotencia**: `clientMessageId` es mandatorio para mensajes de usuario. Si se repite, retornar éxito sin duplicar.
*   **Sanitización**: Límites de caracteres estrictos.

## 6. Recomendaciones de Implementación (Backend)

### Idempotencia (Detalle)
Si el backend recibe un `clientMessageId` duplicado en `POST /api/v1/tickets/{id}/messages`:
*   **NO** debe crear un nuevo mensaje.
*   **Debe** responder `200 OK` o `201 Created` devolviendo el objeto del mensaje original.

### Lógica de `unreadCount`
*   **Incrementar (+1)**: Cuando se crea un nuevo `TicketThreadItem` con `senderType` diferente a `USER` (es decir, `SUPPORT` o `SYSTEM`).
*   **Resetear a 0**: Cuando se llama con éxito al endpoint `POST /tickets/{id}/read`.

### Códigos HTTP Estándar
*   `GET`: **200 OK**
*   `POST (Creación)`: **201 Created**
*   `PATCH`: **200 OK**
*   `Error de Validación`: **400 Bad Request**
*   `Estado Inválido (Ej: Escribir en ticket cerrado)`: **409 Conflict**
*   `Rate Limit Exceeded`: **429 Too Many Requests**

### Base de Datos (Sugerencia)
1.  **Índices**: 
    *   Tickets: `(userId, updatedAt DESC)` para listados rápidos.
    *   Thread: `(ticketId, createdAt ASC)` para carga del historial.
