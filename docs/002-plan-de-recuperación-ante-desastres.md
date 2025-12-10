# Propuesta de Recuperación ante Desastres

## Autor: Michael Salazar

## Objetivo
Garantizar la continuidad operativa del core bancario y de todas las integraciones críticas ante fallos, para minimizar el impacto en clientes, operaciones internas y proveedores externos

---

## Estrategia General

### Modelo de continuidad

- **Multi-AZ en cloud** para servicios críticos o integraciones sensibles
- **Replicación continua** de datos transaccionales y eventos  
- **Failover automático** para bases de datos, clúster de mensajería, API Gateway o Adapters de integraciones
---

## Implementaciones clave

- Replicación multi-AZ para Kafka
- Backups automáticos con restauración verificada  
- Circuit Breakers y Timeouts en adaptadores externos para comunicación con APIs
- Métricas obligatorias de latencia, disponibilidad y offsets
- Logs estructurados con tracing distribuido utilizando OpenTelemetry con FluentD

---

## Pruebas y Validación
- Recomiendo realizar pruebas trimestrales simulando la pérdida total de la AZ  
- Validar los tiempos de restauración de backups y servicios
- Ensayar el reprocesamiento masivo de eventos
- Simular la caída de adaptadores externos
- Volver a realizar los procedimientos hasta refinar el DRP

---

## Uso Obligatorio de IaC
Para asegurar consistencia, auditabilidad y tiempos de recuperación predecibles:

- Toda la infraestructura debe gestionarse con IaC utilizando Terraform o Ansible
- Las configuraciones de redes, balanceadores, clústeres y despliegues deben ser **reproducibles** en cualquier región cloud
- La restauración automatizada debe tener **estados versionados** y **pipelines de despliegue determinísticos** que permitan estabilizar el sistema en el menor tiempo posible

---