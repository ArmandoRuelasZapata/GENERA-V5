# CMS APPTOL

Panel web (Next.js) para administrar el contenido del Home de la app y gestionar tickets de soporte.
Se conecta a la misma API del sistema de tickets usando cifrado de payload y una API key.

## Funcionalidad principal
- Login de administradores.
- Edición de secciones del Home.
- CRUD de items del Home (título, descripción, imagen, orden, activo).
- Reordenamiento de items.
- Gestión de tickets y respuestas de soporte.

## Requisitos
- Node.js 20+
- API activa y accesible por red.
- Variables de entorno configuradas.

## Variables de entorno
Configura estas variables en tu entorno (local) o en EasyPanel:

- `API_BASE_URL` (ejemplo: `https://mi-api.easypanel.host`)
- `API_KEY`
- `PAYLOAD_ENCRYPTION_KEY`

Opcionalmente puedes usar `NEXT_PUBLIC_API_BASE_URL` y `NEXT_PUBLIC_API_KEY`
para pruebas locales, pero en producción se recomienda usar solo las privadas.

## Desarrollo local
```bash
npm install
npm run dev
```
Abre: `http://localhost:3000/login`

## Build y producción
```bash
npm run build
npm run start
```

## Docker (producción)
El proyecto incluye un `Dockerfile` optimizado con `output: 'standalone'`.

```bash
docker build -t cms-apptol .
docker run -p 3000:3000 \
  -e API_BASE_URL="https://mi-api.easypanel.host" \
  -e API_KEY="mi_api_key" \
  -e PAYLOAD_ENCRYPTION_KEY="mi_payload_key" \
  cms-apptol
```

## EasyPanel (resumen)
- Rama: `main`
- Ruta de compilación: `.`
- Dockerfile: `Dockerfile`
- Puerto: `3000`

## Seguridad
- El acceso al CMS está protegido por login de admin.
- Las cookies de sesión son HttpOnly.
- Los endpoints de la API requieren API key y cifrado.

## Notas
- El CMS está diseñado para administrar solo el contenido que actualmente consume el Home de la app.
- La UI es intencionalmente simple para facilitar mantenimiento y despliegue.
