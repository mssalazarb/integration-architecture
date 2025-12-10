# ADR-005: Integración con el Sistema de Prevención de Fraudes

## Estado
Propuesto  

## Autor  
Michael Salazar

---

## Contexto

El **sistema de prevención de fraude** es un componente crítico para detectar patrones sospechosos, comportamientos fuera de lo normal y transacciones potencialmente fraudulentas en tiempo real. A diferencia del sistema de gestión de riesgos, el motor de fraude requiere:

- Correlación temporal entre eventos
- Enriquecimiento con múltiples fuentes internas y externas
- Detección de patrones complejos
- Capacidad de ejecutar múltiples validaciones en paralelo
- Respuestas dinámicas basadas en reglas o modelos de machine learning

---

## Requisitos

Para habilitar una integración eficaz con el sistema de fraude, se deben cumplir los siguientes requisitos:

- Evaluar transacciones de forma **inmediata** sin afectar la latencia de respuesta o experiencia del usuario
- Detectar patrones **en ventanas de tiempo**, correlacionando múltiples eventos por cliente, dispositivo, IP o canal
- Resiliencia ante fallos del motor de fraude, permitiendo respuestas degradadas cuando sea necesario
- Registrar trazabilidad completa de eventos, ventanas de análisis, reglas aplicadas y decisiones tomadas
- Mantener desacoplamiento total para permitir evolucionar motores de fraude o incorporar proveedores externos
- Considerar mecanismos de Feature Enrichment y Data Minimization

---

## Consideraciones

Un sistema de fraude moderno requiere capacidades que no pueden resolverse únicamente con patrones de mensajería. Por este motivo es necesario tener en cuenta:

1. Detección basada en streaming
2. Pipeline dinámico de validaciones
3. Capacidad para ejecutar múltiples motores en paralelo como reglas, Machine Learning o heurísticas
4. Manejo seguro de datos sensibles
5. Mecanismos de correlación

---

## Opciones consideradas

### Opción 1: Integración síncrona basada en API

Para llevar a cabo esta solución de integración, el core digital consume directamente la API expuesta por el sistema de detección de fraude cada vez que necesita evaluar una transacción o eventos

#### Pros
- Simplicidad inicial ya que la integración se realiza directamente en el servicio que necesita la evaluación de fraude

#### Contras
- No soporta correlación temporal ni análisis complejo
- Se convierte en un punto único de fallo
- Puede aumentar la latencia y afectar la experiencia del cliente
- No permite ejecutar múltiples motores de fraude al mismo tiempo

---

### Opción 2: Envío de eventos para análisis offline

#### Pros
- Desacoplamiento total.
- Permite análisis histórico.

#### Contras
- No resuelve validación inmediata.
- No detecta fraudes en tiempo real.

---

### Opción 3: Arquitectura híbrida para integración a Machine Learning

Esta arquitectura propone un pipeline especializado para fraude que opera de forma paralela e independiente, utilizando los siguientes patrones:

1. **Enrichment** para agregar datos adicionales antes de evaluar fraude

2. **Claim Check** para que los datos sensibles se almacenen en un repositorio seguro y solo se envían metadatos al motor de fraude

3. **Correlation Identifier** que nos permite correlacionar las transacciones de un mismo cliente en un intervalo de tiempo

4. **Routing Slip** que nos permite configurar dinámicamente qué validaciones debe pasar una transacción

5. **Scatter-Gather** para ejecutar  múltiples motores de fraude en paralelo si es necesario escalar a mas proveedores

6. **Normalizer** unifica las respuestas de los distintos motores en un formato para tomar una desición final en base a toda la información evaluada

7. **Event Stream y Stream Processor Apache Flink** para agregar, cargar y procesar datos en tiempo real que son necesarios para que los sistemas de detección de fraude puedan evaluar frente a mas información


#### Pros

- **Desacoplamiento total** entre core digital y el sistema de prevención de fraude
- Permite validaciones en tiempo real y análisis asíncrono simultáneamente
- Se integra de forma natural al modelo orientado a eventos del banco
- Mejora la resiliencia ante caídas o degradación del sistema de fraude
- Permite incorporar nuevos motores de fraude sin impactar el core digital

#### Contras

- Requiere diseñar una capa de integración específica con sistemas de detección de fraude para evaluar y cargar mucha mas información constantemente
- Aumenta la complejidad inicial y el esfuerzo para gobernar contratos y eventos entre plataformas
- Requiere observabilidad robusta para evitar pérdida de eventos o afectación del servicio de evaluación de fraude

---

## Decisión

Se selecciona la **Opción 3**, ya que permite cumplir con los requerimientos de validación inmediata, análisis continuo y resiliencia operativa, manteniendo un desacoplamiento total del core digital y alineándose a la arquitectura basada en mensajería definida en los ADR anteriores

---

## Razonamiento

1. La solución híbrida asegura validaciones en línea y análisis continuo mediante eventos
2. El Adaptador de Fraude permite reemplazar o adicionar motores sin modificar el core digital
3. Se evita que el sistema de fraude se convierta en un punto único de fallo
4. La trazabilidad end-to-end se fortalece mediante mensajes, eventos y auditoría transversal

---

## Consecuencias

### Positivas

- Menor acoplamiento y mayor capacidad de evolución
- Trazabilidad completa ante auditorías o incidentes
- Mejor seguridad operacional ante escenarios de fraude
- Capacidad de incorporar más motores de fraude sin impactar el core

### Negativas

- Mayor complejidad en diseño y monitoreo
- Dependencia de la correcta operación del Adaptador de Fraude

---

## Decisiones relacionadas

- **ADR-001** – Integración entre Core Bancario Tradicional y Core Digital  
- **ADR-002** – Integración con Plataforma de Pagos  
- **ADR-003** – Integración con Open Finance  
- **ADR-004** – Integración con Sistema de Gestión de Riesgos  

---

## Referencias

- *Enterprise Integration Patterns* – Gregor Hohpe & Bobby Woolf  
- *Microservices Patterns* – Chris Richardson  
- Normativas de fraude y seguridad aplicables