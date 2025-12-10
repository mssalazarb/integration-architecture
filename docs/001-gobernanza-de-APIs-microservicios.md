# Modelo de Gobierno de APIs y Microservicios

## Autor: Michael Salazar

## Gobierno de APIs

### Catálogo de APIs
- Se debe implementar un registro centralizado de todas las APIs internas, externas y de terceros basados en el estándar Open API
- Se debe clasificar las APIs por dominio, criticidad, sensibilidad del dato y permisos  
- Se debe implementar metadatos obligatorios para conocer la versión, propietario, SLA y políticas asociadas a cada API

### Versionado y Ciclo de Vida
- El versionado de APIs es fundamental para poder tener servicios escalables y desacoplar funcionalidades sin impactar en el funcionamiento del sistema

### Seguridad Aplicada a APIs
- OAuth2/OIDC mediante IAM central tipo AWS Cognito u Okta
- Implementar API Gateway para gestionar:
  - Rate Limit & Throttling  
  - Quotas  
  - Mutual TLS donde aplique  
  - Validación de contratos
  - Auditoría por operación y proveedor

### Exposición Controlada
- Las APIs internas **no se exponen directamente** hacia terceros, siempre se realiza por los API Gateways

---

## Gobierno de Microservicios

### Lineamientos Generales
- Cada microservicio es autónomo, con su propio dominio y ciclo de despliegue
- Cada microservicio debe estar desarrollado bajo la arquitectura hexagonal para garantizar la implementación del patrón SOLID
- Los microservicios deberán comunicarse por Eventos o por APIs internas controladas
- Debe ser prohibido compartir bases de datos entre servicios

### Contratos y Dominios
- Toda integración se hace mediante adaptadores, no directamente a motores externos
- Los servicios deben respetar la idempotencia, trazabilidad y versionado interno y externo  

### Observabilidad
- Los microservicios deben tener logs estructurados con correlación obligatoria
- Cada microservicio debe tener soporte para OpenTelémetry para obtener métricas estándar de latencia, throughput, errores y saturación
- Los microservicios deben tener trazas distribuidas en todas las operaciones sin excepción

### Resiliencia
- Todos los microservicios deben implementar:
  - Retries 
  - Circuit Breaker  
  - Timeouts  
  - Graceful degradation  
- Integraciones externas siempre a través de adaptadores con Request-Reply y manejo de errores.

---
