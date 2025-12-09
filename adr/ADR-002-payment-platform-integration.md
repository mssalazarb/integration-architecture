# ADR-002: Integración con la Plataforma de Servicios de Pago

## Estado
Propuesto

## Autor
Michael Salazar

## Contexto

La integración con una **Plataforma de Servicios de Pago** tiene muchas formas de integración dependiendo de la plataforma. Unas pueden ser locales, redes internacionales, ACH, wallets u otros. Según el tipo de implementación, las plataformas pueden implementar también varios patrones dentro de sus soluciones. 

A nivel local existen plataformas de Pago que tiene servicios para realizar pagos y confirmar pagos, otras plataformas en cambio, tienen servicios para realizar pagos y utilizan los **callback urls** para responder el estado de la transacción una vez que se ha procesado. Por este motivo, la integración con estas plataformas es un componente crítico y se debe considerar lo siguiente:

1. Es indispensable implementar un proceso de autorización de pagos en tiempo real sin afectar el performance del sistema

2. El procesamiento de transferencias y débitos directos debe ser independendiente del pago de servicios para no afectar la operación interna de los cores

3. Se debe tener un regristro tipo espejo de los pagos realizados siguiendo el patrón **Service Layer** para así mitigar la complejidad de la gestión de liquidaciones, conciliaciones y reversos

4. La solución debe ser escalable para los cores pueda integrarse con múltiples proveedores locales o internacionales a futuro

Por otro lado, el **Core Bancario Digital** debe orquestar estos pagos y, en muchos casos, coexistir con:

- Procesar pagos que aún se ejecutan en el **core tradicional**
- Mantener o adaptarse a distintos proveedores de pagos que pueden cambiar en el tiempo

Requisitos clave:

- La integración debe garantizar una **baja latencia** en autorizaciones en línea
- El servicio de pagos debe tener una **Alta disponibilidad** y tolerancia a fallos
- Soporte para **múltiples proveedores de pago** y estrategias de enrutamiento
- Trazabilidad completa para cumplimiento y regulaciones locales
- Posibilidad de **migrar gradualmente** flujos de pago del core tradicional al core digital de ser necesario

## Supuestos

Asumiendo que la **Plataforma de Servicios de Pago** es externa o un proveedor asociado, se han considerado los siguientes aspectos:

- Las autorizaciones de pago en línea deben tener una **baja latencia**
- La integración debe tener **alta disponibilidad** y **tolerancia a fallos**
- Si en un futuro es necesario seguir escalando, debemos agregar soporte para **múltiples proveedores de pago** y estrategias de enrutamiento
- Registrar toda la trazabilidad para cumplimiento normativo
- Soportar los flujos de pago del core tradicional y del core digital manteniendo la integración de ADR-0001

## Consideraciones

Antes de poder analizar las diferentes posibilidades de integración, también es necesario considerar:

- La plataforma de pagos puede exponer interfaces **heterogéneas** para integrarnos de forma síncrona o asíncrona
- Algunos procesos requieren **respuesta síncrona** con autorización en tiempo real y otros son **asíncronos**
- Se debe tener la capacidad de adaptar o integrar nuevos proveedores **sin impactar a los canales o servicios** ni al resto del sistema

## Opciones consideradas

### Opción 1: Integración directa con la Plataforma de Pagos

En esta opción, el **core digital** y posiblemente el **core tradicional** se deben integrar directamente con la plataforma de pagos:

- El servicio de pagos del core implementa directamente:
  - ISO 8583 para comunicación con el proveedor de pagos
  - Cliente HTTP con SSL para APIs del procesador
  - Manejo de conectividad, enmascaramiento y reintentos

#### Pros

- Menor número de componentes a desarrollar o adaptar
- Es mas simple inicialmente la integración

#### Contras

- La integración genera una **fuerte dependencia** entre el dominio de pagos del core y el proveedor
- Si en algún momento es necesario cambiar de proveedor de pagos implica **modificar el core** directamente y adaptarlo constantemente
- Es difícil soportar **múltiples proveedores** ya que imponemos una integración y es dificil escalar a futuro
- La lógica de enrutamiento, reintentos, normalización de mensajes y manejo de errores queda mezclada con la lógica de negocio de pagos
- No se adapta al objetivo de la arquitectura y patrones de mensajería que se van a implementar para integrar el core digital y tradicional.

---

### Opción 2: Orquestación síncrona únicamente desde el Core digital

Para esta opción, es indispensable que el **core digital** exponga APIs internas para que el **core tradicional** también pueda realizar pagos de ser necesario y orqueste directamente llamadas síncronas a la plataforma de pagos

#### Pros

- Los canales siguen integrados a un único core pero los pagos pueden ser emitidos por el core digital
- La lógica de orquestación de pagos queda centralizada en el core digital y es responsable de gestionar los procesos y comunicarse con el core tradicional. 

#### Contras

- La arquitectura es **poco resiliente** ya que al tener una integración síncrona agrega latencia o posible caída de la plataforma de pagos que impacta directamente al core. Esto imprime una degradación del servicio porque se agrega complejidad y procesamiento extra al **core digital**
- No se dispone de un modelo nativo que nos permita gestionar de forma independiente y distribuir la carga de liquidaciones, conciliaciones, reversos, fraudes y auditorias
- Agregamos un alto riesgo de adaptación ya que al cambiar el proveedor de pagos o enrutar pagos a diferentes plataformas implicaría modificar la orquestación interna del core a cada momento.

---

### Opción 3: Integración mediante Mensajería con Adaptador de Pagos

Para esta integración se ha tomado en cuenta la creación de una capa especializada de integración con la plataforma de pagos para que sea mantenible y escalable a futuro, implementando:

- **Bus de Mensajería** con un Kafka autogestionado KMS / AWS para emitir comandos y recibir respuestas de autorización aplicando el patrón **Request-Reply**
- Gestionar eventos de pagos, liquidaciones y conciliaciones utilizando el patrón **Event Message**
- **Adaptador** que actúa como:
  - **Messaging Gateway** para un Punto de entrada y salida entre el Bus de Mensajes y la plataforma de pagos
  - **Service Activator**  para traducir los mensajes en invocaciones ISO 8583, o REST hacia la plataforma de pagos y viceversa
  - **Message Translator** para traducir los mensajes de pagos entrantes al modelo interno del core
  - **Content-Based Router** para agregar la posibilidad de integrar mas de un proveedor de pagos
  - **Request-Reply** para recibir las respuestas en línea de autorización o rechazo de pagos

#### Pros

- Generamos un bajo **acoplamiento** entre core y proveedores de pagos
- Agregamos soporte para **múltiples plataformas de pago**
- Mejoramos la **resiliencia** entre el core y los proveedores de pagos
- Permitimos que se pueda mantener el modelo **orientado a eventos** que se intenta implementar o estandarizar internamente
- Facilita el **cumplimiento y la auditoría** ya que podemos reutilizar el **Message Store** y **Message History** implementado en **ADR-0001** para mantener la trazabilidad completa de los pagos procesados
- Agregamos una capa de abstracción que nos permitirá aplicar patrones de diseño tipo Factory, Visitor o Composite para futuras integraciones con plataformas de pago

#### Contras

- Mayor **complejidad arquitectónica** ya que se se introduce un adapter adicional, un bus adicional y más contratos con proveedores
- Implica un esfuerzo inicial para diseñar el **Modelo de Pagos** para las respectivas integraciones

---

## Decisión

En base a los requisitos de resiliencia, escalabilidad, desacoplamiento, cumplimiento y capacidad de evolucionar a múltiples proveedores de pago, se escoge la **Opción 3**

---

## Razonamiento

1. El dominio de pagos del core no depende directamente de ISO 8583

2. Cambiar de proveedor o agregar uno nuevo se resuelve principalmente en la capa de adapter y en reglas de enrutamiento sin afectar cambios en el core

2. Implementar estos patrones de integración la arquitectura permite tolerar fallos temporales de la plataforma de pagos, balancear carga y evitar perder transacciones

4. Las autorizaciones exitosas, declinaciones, reversos, liquidaciones y conciliaciones se publican como **Event Messages** y estos eventos alimentan los servicios de riesgo, fraude, conciliación, contabilidad y monitoreo en tiempo casi real, sin nuevas integraciones punto a punto

5. Mediante **Message Store** y **Message History** se mantiene un registro completo de mensajes de autorización, cambios de estado y respuestas de la plataforma de pagos

6. La lógica de integración técnica se concentra en el Adaptador y no en mantener o evolucionar los servicios internos del core digital o tradicional

---

## Consecuencias

### Positivas

- Arquitectura de pagos **más robusta**, preparada para múltiples plataformas
- Menor impacto en el core ante cambios de plataformas
- Mayor control de **resiliencia y disponibilidad** mediante patrones de mensajería
- Habilita un ecosistema de **eventos de pagos** reutilizable por riesgo, fraude y auditoría
- Mejora la capacidad de cumplimiento regulatorio y trazabilidad

### Negativas

- Mayor complejidad inicial para integrarse con las plataformas
- Requiere inversión en **observabilidad y arquitectura** con monitoreo de flujos de integración para no perder trasacciones o información

---

## Decisiones relacionadas

- ADR-001 – Integración entre core bancario tradicional y core bancario digital 

---

## Referencias

- *Enterprise Integration Patterns* – Gregor Hohpe & Bobby Woolf
- *Microservices Patterns* – Chris Richardson
