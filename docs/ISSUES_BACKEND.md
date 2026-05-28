# Issues Detectados — Backend / Make.com / Webhooks

**Fecha:** 11 de febrero de 2026  
**Reportado por:** Equipo de desarrollo App Flutter  
**Estado:** Pendiente de revisión por equipo de backend

---

## 1. Hora incorrecta en correo de confirmación

**Severidad:** Alta  
**Componente:** Make.com → Módulo de correo electrónico

**Descripción:**  
Cuando un usuario agenda una cita (ej. 13:00 hrs), la hora se envía correctamente desde la app en formato `YYYY/MM/DD HH:MM:SS` (hora local CST/UTC-6). Sin embargo, el correo de confirmación que recibe el usuario muestra una hora diferente.

**Payload que se envía desde la app:**
```json
{
  "name": "Nombre Usuario",
  "email": "usuario@correo.com",
  "startdate": "2026/02/11 13:00:00",
  "interest": "Consultoría TI",
  "value": "0",
  "number": "1234567890"
}
```

**Resultado esperado:** El correo debe mostrar 13:00 hrs (1:00 PM).  
**Resultado actual:** El correo muestra una hora diferente (posiblemente UTC).

**Posibles causas:**
- El escenario de Make.com no tiene configurada la zona horaria correcta (debe ser `America/Mexico_City` / UTC-6)
- El módulo de Google Calendar interpreta la hora como UTC y la convierte
- La plantilla del correo no aplica la zona horaria al formatear la hora

**Acción requerida:** Revisar la configuración de timezone en el escenario de Make.com, tanto en el módulo de Google Calendar como en el módulo de envío de correo.

---

## 2. Historial de citas muestra todas las citas (de todos los usuarios)

**Severidad:** Alta  
**Componente:** Webhook de agenda (lectura)

**Descripción:**  
El webhook de lectura de agenda (`GET https://hook.us2.make.com/xe1te3vk0qpnqcb98eftobvpyib0e8aw`) devuelve **todas** las citas del calendario, sin filtrar por usuario. Esto causa que en la sección "Mis Citas" de la app, un usuario vea las citas de **todos** los clientes.

**Resultado esperado:** Cada usuario solo debería ver sus propias citas.  
**Resultado actual:** Se muestran todas las citas de la agenda completa.

**Solución propuesta:** Dos opciones:

1. **Filtro por email en el webhook:** Que el webhook acepte un parámetro `email` (ej. `?email=usuario@correo.com`) y devuelva solo las citas donde el email coincida.
2. **Campo identificador:** Agregar un campo `userId` o `email` en cada evento del calendario para poder filtrar del lado del cliente.

**Nota:** Actualmente la app envía el email del usuario al agendar. Si el webhook de lectura pudiera filtrar por ese email, el problema se resolvería sin cambios en la app.

---

## 3. Chatbot GPT muestra disponibilidad diferente al flujo manual

**Severidad:** Media  
**Componente:** Lógica del chatbot / entrenamiento GPT

**Descripción:**  
El chatbot (GPT) a veces indica horarios disponibles diferentes a los que muestra el flujo manual de la app. Por ejemplo, el bot puede decir que solo las 15:00 están libres cuando en realidad hay más horarios disponibles (o viceversa).

**Causa:** GPT interpreta la agenda como texto y "razona" sobre la disponibilidad, lo cual puede ser impreciso. El flujo manual hace una comparación programática directa y es más confiable.

**Nota:** Se agregó un disclaimer en la app ("El asistente puede cometer errores. Verifica la información importante.") para mitigar la confusión del usuario.

**Acción sugerida:** Mejorar el prompt del chatbot o ajustar el entrenamiento para que sea más preciso con los horarios. Alternativamente, considerar que el chatbot redirija al flujo manual para selección de horarios en lugar de sugerir horas él mismo.

---

## Resumen de Acciones Requeridas

| # | Issue | Severidad | Responsable |
|---|-------|-----------|-------------|
| 1 | Hora incorrecta en correo | Alta | Backend / Make.com |
| 2 | Historial muestra todas las citas | Alta | Backend / Webhook |
| 3 | Chatbot da horarios imprecisos | Media | IA / Prompt engineering |

---

*Documento generado durante la integración de la app Flutter con los webhooks de Make.com.*
