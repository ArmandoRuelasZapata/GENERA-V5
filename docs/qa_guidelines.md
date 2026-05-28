# Lineamientos Corporativos de QA

## 1. Análisis Estático
Como primera barrera de calidad, todo código debe pasar el análisis estático antes de cualquier revisión humana o prueba automatizada.

- **Herramienta**: `flutter_lints` (configuración por defecto) o `very_good_analysis` (recomendado para mayor rigurosidad).
- **Configuración**: El archivo `analysis_options.yaml` debe estar presente en la raíz del proyecto.
- **Política**: Cero warnings permitidos en el pipeline de CI (`flutter analyze --no-fatal-infos --fatal-warnings`).

## 2. Pirámide de Pruebas
Se seguirá una estrategia de pirámide de pruebas para asegurar un balance entre velocidad de ejecución y confiabilidad.

### Unit Tests (70%)
- **Objetivo**: Validar lógica de negocio aislada (UseCases, Repositories, ViewModels).
- **Herramienta**: `test` / `flutter_test`.
- **Cobertura**: Mocking de dependencias externas (API, DB).

### Widget Tests (20%)
- **Objetivo**: Validar comportamiento de componentes UI aislados.
- **Herramienta**: `flutter_test`.
- **Alcance**: Verificar renderizado, interacciones básicas (taps) y estados visuales.

### Integration Tests (10%)
- **Objetivo**: Validar flujos de usuario completos (E2E) en un entorno controlado.
- **Herramienta**: `integration_test` (paquete oficial).
- **Entorno**: Ejecución en dispositivos emulados o granjas de dispositivos.

## 3. Flujo de Trabajo

1.  **Local (Pre-commit)**:
    - Ejecutar `flutter analyze`.
    - Ejecutar unit tests afectados.
2.  **CI (Pull Request)**:
    - Ejecución automática de linter.
    - Ejecución de toda la suite de Unit y Widget tests.
    - Bloqueo de merge si hay fallos.
3.  **Nightly / Release**:
    - Ejecución de Integration tests.
    - Análisis de vulnerabilidades (MobSF).

4.  **Auditoría Mensual (Cadena de Suministro)**:
    - Ejecutar `flutter pub outdated` para detectar dependencias obsoletas.
    - Revisar alertas de seguridad en dependencias (Snyk / GitHub Dependabot).

## 4. Herramientas Estándar
- **Framework de Pruebas**: Flutter Test SDK.
- **Mocks**: `mockito` o `mocktail`.
- **Seguridad**: Mobile Security Framework (MobSF).
- **CI/CD**: GitHub Actions / GitLab CI.

## 5. Reporte de Bugs
Todo reporte de incidencia debe contener:
- **Pasos para reproducir**: Lista numerada clara.
- **Comportamiento esperado vs. actual**.
- **Entorno**: Dispositivo, SO, versión de la App.
- **Evidencia**: Screenshots, logs o videos.
