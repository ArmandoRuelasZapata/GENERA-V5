# Reporte de Hallazgo de Seguridad

**ID**: [SEC-XXX]
**Tipo de Vulnerabilidad**: [Ej. Data Leakage, Insecure Auth, Injection]
**Nivel de Riesgo (CVSS)**: [Crítico | Alto | Medio | Bajo]

## Descripción de la Vulnerabilidad
Explicación técnica de la vulnerabilidad encontrada y por qué representa un riesgo.

## Impacto
¿Qué podría lograr un atacante si explota esta vulnerabilidad? (Ej. Robo de identidad, acceso a datos de otros usuarios, crash de la app).

## Pasos de Reproducción (PoC)
Pasos detallados o scripts para replicar la vulnerabilidad.

1. Interceptar tráfico con Burp Suite.
2. Modificar el parámetro `user_id` en el request `POST /api/...`.
3. ...

## Referencia OWASP MASVS
Indicar qué control de MASVS se está violando (Ej. V2.1 - Data Storage).

## Recomendación de Remediación
Pasos técnicos sugeridos para arreglar el problema.

- [ ] Implementar validación en el servidor...
- [ ] Cifrar los datos antes de guardar...

## Estado
- [ ] Abierto
- [ ] En Corrección
- [ ] Verificado / Cerrado
