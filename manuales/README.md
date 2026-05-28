<div align="center">
  <img src="../assets/tolnewclaro.png" width="200" alt="The Original Lab Logo"/>
  <h1>Manuales Técnicos Oficiales</h1>
  <p><b>The Original Lab App (v2) - Flutter Clean Architecture</b></p>

  [![Plataforma](https://img.shields.io/badge/Plataforma-Flutter%203.x-02569B?logo=flutter)](https://flutter.dev)
  [![Estado](https://img.shields.io/badge/Estado-Producci%C3%B3n-success?style=flat-square)]()
  [![Seguridad](https://img.shields.io/badge/OWASP-Cumplimiento%20M5-blue?style=flat-square)]()
  [![Versión](https://img.shields.io/badge/v-2.0.0-orange?style=flat-square)]()
</div>

---

## Introducción

Este directorio contiene la documentación oficial técnica, operativa y de arquitectura de la aplicación **The Original Lab App**. Estos manuales están diseñados para guiar tanto a nuevos desarrolladores como a evaluadores técnicos, auditores de seguridad y líderes de proyecto en la comprensión profunda del sistema.

La aplicación está construida sobre principios de **Clean Architecture**, con un manejo robusto de inyección de dependencias a través de **Riverpod**, y está conectada a múltiples servicios empresariales integrados (autenticación segura, comercio electrónico, atención al cliente mediante IA y agendamiento).

---

## Índice de Documentación

Aquí encontrarás el acceso rápido a los volúmenes de documentación:

### [01 - Arquitectura Técnica](./01_arquitectura.md)
> **Recomendado para: Desarrolladores y Arquitectos**
* Visión general del _stack_ tecnológico.
* Separación de responsabilidades (`core`, `shared`, `features`).
* Estrategia de Inyección de Dependencias y Cliente HTTP.
* Mecanismos de persistencia local y seguridad transversal.

### [02 - Módulos Desarrollados](./02_modulos_desarrollados.md)
> **Recomendado para: Product Managers y Analistas de Negocio**
* Inventario profundo de capacidades funcionales.
* Integraciones clave (OpenAI, Webhooks, Firebase, Pasarelas).
* Estado y alcance de los módulos principales (Tienda, Soporte, Citas, Chatbot).

### [03 - Flujos Principales](./03_flujos_principales.md)
> **Recomendado para: Equipos de Calidad (QA) y Soporte Técnico**
* Recorridos lógicos paso a paso (_Happy paths_) y ramas alternativas.
* Documentación de procesos críticos: Recuperación de PWD, Creación de Tickets, Motor IA de Ventas.
* Precondiciones, errores frecuentes y dependencias.

### [04 - Prevención de Riesgos y Seguridad](./04_seguridad_y_operaciones.md)
> **Recomendado para: Oficiales de Seguridad (CISO) y DevSecOps**
* Matriz de defensas activas del cliente móvil.
* Cumplimiento de normativas OWASP en almacenamiento y transmisión.
* Configuración de sesión, protecciones contra inactividad y anti-root.

---

> [!TIP]
> **Actualización Continua:** Estos manuales operan como un documento vivo. Cualquier adición de un nuevo módulo (`feature/...`) debe verse reflejada inmediatamente en el documento `02_modulos_desarrollados.md`.

## Ejecucion local
```bash
flutter run --dart-define-from-file=.env.dev.json
```
