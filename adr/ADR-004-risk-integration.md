# ADR-004: Integración con el Sistema de Gestión de Riesgos

## Estado
Propuesto  

## Autor  
Michael Salazar

---

## Contexto

Un **sistema de gestión de riesgos** es un componente crítico dentro de un core bancario ya que es el responsable de evaluar y aplicar diferentes reglas de negocio internas, validar umbrales, límites y escenarios de riesgo que puedan afectar la capacidad del cliente para realizar solicitudes o transacciones financieras. Este sistema se ve involucrado en procesos indispensables como:

- Apertura de productos financieros
- Validación de límites y scoring en tiempo real
- Análisis de riesgo asociado a movimientos y transacciones
- Revisiones periódicas de comportamiento crediticio

---

## Requisitos

Para garantizar una integración segura y confiable con sistemas de riesgo, es necesario tener en cuenta los siguientes lineamientos:

- El sistema de gestión de riesgo debe responder rápidamente para no afectar la experiencia del cliente y garantizar una alta **disponibilidad**
- La plataforma debe tolerar fallos temporales sin bloquear operaciones internas o procesos bajo demanda, permitiendo que funcione con buena **resiliencia**
- Cada proceso debe guardar la trazabilidad completa para cumplir con la LOPD, ISO 27001, auditoría y políticas internas 
- Se debe evitar duplicidad, inconsistencias o divergencia entre cálculos de riesgo
- Los cambios en reglas de evaluación de riesgo no deben requerir modificaciones directas en el core

Además, la plataforma debe permitir incorporar:

- Nuevas metodologías internas para evaluar riesgo sin afectar el proceso interno del core
- Proveedores adicionales externos para scoring alternativo o burós de crédito 
- Cambios regulatorios sin romper los flujos existentes

---

## Consideraciones

En un entorno bancario, los sistemas de gestión de riesgo necesitam realizar:

1. Validaciones inmediatas que requieren verificar transacciones en tiempo real 
2. Análisis de movimientos o información histórica para comparar con el comportamiento financiero 

Adicionalmente:

- Se debe restringir la información enviada según el principio de **Data Minimization**
- Se debe registrar la trazabilidad completa de qué se evalúa, con qué parámetros, quién inició la operación y qué resultado entregó el sistema de gestión de riesgos

---

## Opciones consideradas

### Opción 1: Integración directa del core digital y el sistema de gestión de riesgo

Para llevar a cabo esta solución de integración, el core digital consume directamente la API expuesta por el sistema de gestión de riesgo cada vez que necesita una validación

#### Pros

- Simplicidad inicial ya que unicamente se agrega el consumo de la API en determinados procesos
- Las reglas centralizadas en el sistema de gestión de riesgo no requieren lógica adicional en el core digital

#### Contras  

- Alto acoplamiento entre el core y sistema de gestión de riesgos
- El sistema de gestión de riesgos se convierte en un **single point of failure**, afectando la experiencia del usuario
- No existe un mecanismo claro para gestionar fallos temporales o degradación del servicio 
- La auditoría y trazabilidad dependen únicamente del core, no de un modelo transversal

---

### Opción 2: Integración basada en eventos

En esta opción, el sistema de gestión de riesgos recibe los eventos desde los servicios internos del banco y genera evaluaciones internas, sin interacción en línea

#### Pros

- Desacoplamiento total con el core digital
- El sistema de gestión de riesgos recibe información detallada del contexto del cliente y sus operaciones

#### Contras

- No se pueden aplicar validaciones críticas en línea 
- El sistema podría ejecutar operaciones sin validar condiciones de riesgo específicas en el momento de una transacción

---

### Opción 3: Integración Híbrida mediante Mensajería con Gateway y Adaptador de riesgo

En esta opción se toma el mismo enfoque usado en ADR-001 y ADR-002 y se implementa:

- **Bus de Mensajes** como columna vertebral para mensajería
- **Adaptador** especializado para implementar:
  - **Messaging Gateway** para comunicación desacoplada
  - **Service Activator** para ejecutar llamadas HTTP/SOAP hacia el sistema de gestión de riesgos
  - **Message Translator** para estandarizar los datos que se envían y reciben de la evaluación del riesgo
- Soporte para **Request-Reply** en evaluaciones en línea donde el core digital envía un **Command Message** al Adaptador, el adaptador invoca al sistema de gestión de riesgo y retorna la respuesta por **Reply Message**
- Soporte para **Publish-Subscribe** para notificaciones de eventos como movimientos, pagos, cambios de estado, etc.

#### Pros
- **Desacoplamiento total** entre el core digital y el sistema de gestión de riesgos
- La lógica de integración compleja vive en el **Adaptador** y no en los servicios internos
- La solución está alineada completamente al modelo orientado a eventos del banco ya implementados en **ADR-001**, **ADR-002** y **ADR-003**
- El sistema de gestión de riesgos recibe información en tiempo real y también puede responder consultas síncronas
- Se reutilizan patrones e infraestructura definidas anteriormente

#### Contras
- Requiere un componente de integración adicional dedicado para comunicarse con el sistema de gestión de riesgos
- Agrega mayor complejidad inicial para diseñar contratos y eventos de evaluación de riesgo
- Implica invertir en gobernanza y monitoreo de eventos críticos para detectar anomalías tempranas

---

## Decisión

Se selecciona la **Opción 3**, ya que permite mantener un modelo consistente en toda la arquitectura, garantiza resiliencia, soporta comunicación en línea y asíncrona, y fortalece la trazabilidad y el cumplimiento normativo.

---

## Razonamiento

1. El Adaptador propuesto sigue exactamente los patrones introducidos en ADR-001 y ADR-002 donde se trata de evitar que el core digital se acople al sistema de gestión de riesgos

2. Las evaluaciones en línea se manejan con **Request-Reply** desacoplado por mensajería. En el caso que exista una caída del sistema de gestión de riesgos, los eventos quedan en cola, los comandos pueden reintentarse y los consumidores pueden escalar horizontalmente.

3. En otro posible escenario, el sistema de gestión de riesgo puede suscribirse a cualquier canal relevante donde se mantienen históricos completos de todas las solicitudes de evaluación

4. Agrega la posibilidad de cambiar de motor de evaluación de riesgos o añadir motores especializados

---

## Consecuencias

### Positivas
- Integración **robusta**, segura y alineada al resto de la arquitectura
- Menor impacto en los servicios del Core ante cambios en el sistema de evaluación de riesgos
- Auditoría completa end-to-end gracias a eventos, Message Store y Reply Messages
- Capacidad de agregar nuevos motores de riesgo sin afectar el Core
- Reduce riesgos operativos al habilitar resiliencia nativa por mensajería

### Negativas
- Requiere mayor inversión inicial
- Más infraestructura y monitoreo para mantener el funcionamiento correcto del Adaptador
- Se necesita gobernar y versionar contratos de eventos de riesgo.

---

## Decisiones relacionadas
- **ADR-001** – Integración entre Core Bancario Tradicional y Core Digital mediante mensajería
- **ADR-002** – Integración con la Plataforma de Servicios de Pago mediante Adaptador de Pagos
- **ADR-003** – Integración con Servicios de Terceros para Open Finance

---

## Referencias

- *Enterprise Integration Patterns* – Gregor Hohpe & Bobby Woolf  
- *Microservices Patterns* – Chris Richardson  
- Normativas de riesgo locales y estándares de gobernanza