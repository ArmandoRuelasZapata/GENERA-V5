# Estrategia Corporativa de Pruebas (1.3)

Este documento estandariza los flujos de prueba requeridos para cualquier feature nueva o existente en `theoriginallab_v2`.

## 1. Pruebas Funcionales (Unit & Widget)
El objetivo es validar que cada componente individual funcione según lo especificado antes de integrarse.

### Alcance
- **Lógica de Negocio (Blocs/Providers)**: 100% cobertura de estados y eventos.
- **Repositorios**: Mockear siempre las fuentes de datos externas.
- **UI (Widgets)**: Validar renderizado inicial y estados de interacción básicos (onTap, inputs).

### Checkpoints Obligatorios
1.  **Happy Path**: El flujo ideal funciona sin errores.
2.  **Edge Cases**:
    - Entradas vacías o nulas.
    - Respuestas de error del backend (404, 500).
    - **Offline (Mundo Real)**: La app no debe crashear si se pierde la red en medio de una transacción. Debe mostrar pantalla de "Sin Conexión" y permitir reintentar.
3.  **Límites**: Valores máximos/mínimos en campos numéricos y de texto.

## 2. Pruebas de Integración (E2E)
El objetivo es validar flujos completos de usuario simulando un entorno real.

### Escenarios Críticos (Smoke Test)
Estos flujos deben pasar antes de cualquier release:

1.  **Inicio de Sesión**: Login exitoso -> Home Screen.
2.  **Navegación Principal**: Cambio entre tabs (Home, Store, Profile) sin crashes.
3.  **Flujo de Compra/Reserva**:
    - Ver producto -> Detalle -> "Comprar" (Simulado).
4.  **Logout**: Cerrar sesión -> Login Screen.

### Herramientas
- `integration_test` (Flutter SDK).
- Ejecución en CI: Mínimo 1 dispositivo Android (Pixel virtual) y 1 iOS (si aplica).

## 3. Pruebas de Seguridad (SAST & DAST)
El objetivo es identificar vulnerabilidades antes de producción.

### Análisis Estático (SAST)
- **Cuándo**: En cada commit (pre-commit hook & CI).
- **Herramientas**:
    - `flutter_lints` / `very_good_analysis`.
    - Detección de secretos (Trufflehog o similar en CI).

### Análisis Dinámico (DAST)
- **Cuándo**: Previo a Release Candidates (RC).
- **Herramienta**: MobSF (Mobile Security Framework).
- **Validaciones**:
    - No hay datos sensibles en logs (`debugPrint`).
    - Las comunicaciones son HTTPS.
    - No hay datos sensibles en SharedPreferences sin cifrar.

## 4. Matriz de Responsabilidades

| Tipo de Prueba | Ejecuta | Frecuencia | Responsable |
| :--- | :--- | :--- | :--- |
| **Unit/Widget** | Developer | Local + CI (Cada PR) | Desarrollador |
| **Integration** | CI / QA | CI (Nightly / Merge a Main) | QA Automation |
| **Seguridad** | CI / SecOps | Pre-release | Equipo de Seguridad / Dev Lead |
