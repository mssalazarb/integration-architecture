# Integración entre core bancario tradicional y core bancario digital

## Estado
Propuesto

## Autor
Michael Salazar

## Contexto
En el proceso de migración o adaptación de un core bancario tradicional a un core bancario digital, existen automatizaciones, código legado estable o procedimientos con alta criticidad que demandan implementar e iterar en escenarios controlados el proceso de migración a seguir. 

Debido a esto, el proceso de migración no es tan trivial y tampoco sucede en el corto o mediano plazo. Por esta razón, es necesario integrar el core bancario tradicional con el core bancario digital para no afectar la operación y garantizar que los usuarios tengan una experiencia transparente sin afectar la disponibilidad y acceso a los recursos.

## Consideraciones

Las principales consideraciones que se deben tener en cuenta son:

- El **Core tradicional no puede desmantelarse abruptamente** ya que esto daría paso a un riesgo operativo muy alto
- Se requiere un período de **coexistencia multicore** para que ambos core funcionen al mismo tiempo mientras dura la migración
- Los frontends y servicios de terceros deben tener acceso a un **núcleo bancario unificado**, sin conocer la existencia de dos cores
- Los flujos transaccionales deben mantener consistencia, resiliencia, trazabilidad, idempotencia, auditoría y seguridad normativa
- La arquitectura debe permitir una **migración gradual**, por producto, portafolio, segmento o dependencias existentes

## Opciones consideradas

Para la integración entre los dos core bancarios, se ha tenido en cuenta las siguientes opciones que generalmente se implementan en este tipo de requerimientos.

### **Opción 1:  API Gateway**
La implementación de un API Gateway nos permitiría disponibilizar el acceso a los cores desde los frontends Web, Móvil y APIs de terceros. Estos canales de comunicación se integrarían directamente con el API Gateway y después podríanc omunicarse mediante API con el core digital o con el core tradicional. Esto nos permitiría enrutar el tráfico bajo demanda según sea necesario.

#### Pros
- Simplicidad inicial.
- No requiere una capa intermedia adicional de integración.

#### Contras
- Tenemos un **fuerte acoplamiento** entre canales y cores.
- La lógica de **(qué core usar)** se dispersa desde los canales, esto agrega complejidad y no permite tener una integración escalable con alta disponibilidad ya que los canales deberán realizar cambios constantemente.
- Riesgo de **inconsistencias funcionales** entre frontends o con APIs de terceros.
- Dificulta la **migración gradual** porque se agrega un servicio adicional que debe tenerse en cuenta en la migración.
- Mayores implementaciones en seguridad, auditoría y mantenimiento para mitigar vulnerabilidades o fuga de información.

---

### **Opción 2: Orquestador Síncrono**
En este tipo de integración se deberá adaptar el core digital con un patrón de diseño tipo Fachada para que los canales conozcan unicamente el core digital e internamente se consuma servicios y procesos del core tradicional

#### Pros
- Los canales se integran a un único core y se mitiga la posibilidad de afectar a la disponibilidad o escalabilidad del sistema.
- El enrutamiento y lógica de negocio está centralizada y se accede directamente a la fuente de la verdad. De esta forma el core digital es el encargado de escalar internamente integrandose constantemente con el core tradicional o absorbiendo gradualmente la lógica de negocio.

#### Contras
- Las dependencias del core tradicional son mas complejas de desacoplar
- Crearíamos una arquitectura **poco resiliente** ya que la integración síncrona es más sensible a fallos
- Limitamos la escalabilidad horizontal y la capacidad de recuperación ante desastres, ya que los dos core están integrados sincronamente

---

### **Opción 3: Integración mediante Mensajería, Adaptadores y Enrutamiento Basado en Contenido**

Basados en los diferentes Patrones de integración empresarial, esta integración se implementaría con los siguientes componentes:

- Un **Bus de Mensajería** utilizando Kafka autogestionado tipo KMS / AWS como columna vertebral para poder comunicar asíncronamente los dos core
- Un **Adaptador** para el core tradicional que implementa:
  - **Messaging Gateway** para la entrada y salida de mensajes
  - ***Service Activator** para las llamadas a servicios como SOAP o API
  - **Message Translator** para traducción de mensajes entre el core tradicional y core digital para que puedan entenderse
- En el core digital se implementaría:
  - **Event Message y Publish-Subscribe** para que todos los eventos sean informados y direccionados a sus respectivos consumidores
  - **Content-Based Router** que nos permitirá gestionar las solicitudes y procesos de forma abstracta para operar con el core tradicional o con el core digital según corresponda
  - En el caso de que un proceso necesite utilizar ambos core, utilizaríamos el patrón **Process Manager** para que el proceso pueda ser adaptativo y escalable

#### Pros
- Los canales ven un **solo core bancario** que sería el digital
- Tendríamos la capacidad de llevar a cabo una **migración progresiva** por productos y segmentos sin afectar la operación o disponibilidad
- Logramos un **desacoplamiento** fuerte entre cores
- Agregamos el soporte nativo para ir orientando las nuevas soluciones a una arquitectura **orientada a eventos**
- Mejor resiliencia y escalabilidad para el core digital
- Permite **reprocesar, auditar y trazar** mensajes mediante otros patrones de integración como **Message Store** y **Message History** que nos ayudarán a tener una alta visibilidad y trazabilidad de las transacciones y movimientos entre cores

#### Contras
- Agregamos mayor complejidad operativa y arquitectónica
- Requerimos adaptar e implementar el soporte de eventos en el core digital y core tradicional si estos aún no lo soportan
- Es necesario integrar un equipo alineado en prácticas de integración y eventos para dar mantenibilidad a las integraciones o futuras adaptaciones

---

## Decisión
En base a lo expuesto anteriormente, se decidió escoger la **Opción 3** gracias a todos los beneficios que aporta en el proceso de migración de un core tradicional a un core digital y teniendo en cuenta que mitigamos las posibles afectaciones conocidas y desconocidas en este proceso

---


## Razonamiento

1. El core tradicional queda aislado detrás de un adaptador. Sus formatos, tiempos y protocolos no afectan al resto ya que únicamente se agrega un adaptador que será el punto de entrada

2. Con **Content-Based Router** podemos desviar el tráfico al core digital de forma gradual, producto por producto, con rollback inmediato si es necesario o si existe alguna afectación. Con esto podemos realizar una migración sin afectar la operación.

3. La mensajería soporta reintentos, colas de error, suscriptores permanentes y distribución de carga para incrementar la resiliencia y escalabilidad de la plataforma

4. Los servicios internos publican eventos que alimentan riesgo, fraude, Open Finance, auditoría y regulaciones. Esta información puede ser emitada desde el core tradicional o core digital

5. Los frontends o proveedores externos no conocen la existencia de dos cores y tampoco tienen acceso directo a ambos. Esto agrega seguridad y cumplimiento para integraciones futuras

6. Con la implementación de **Message Store** y **Message History**, se fortalece el cumplimiento de ISO 27001 para la seguridad de la información y regulaciones locales.

---

## Consecuencias

### Positivas
- Integración robusta y escalable entre core tradicional y digital
- Menor acoplamiento
- Facilita la auditoría, mejora la trazabilidad de procesos o transacciones e incrementa la capacidad de cumplimiento con las normas
- Permite realizar rollback en migraciones y pruebas controladas por segmentos o ambientes
- Nos abre la posibilidad de implementar un **Message Broker** para unificar información y alimentar procesos de ETL o Data Warehouse

### Negativas
- Mucha complejidad inicial.
- Requiere experiencia en patrones de integración empresarial y mensajería.
- Incrementa la necesidad de monitoreo y observabilidad.

---

## Referencias
- *Enterprise Integration Patterns* – Gregor Hohpe & Bobby Woolf
- *Microservices Patterns* – Chris Richardson