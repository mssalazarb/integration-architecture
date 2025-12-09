# ADR-003: Integración con Servicios de Terceros para Open Finance

## Estado
Propuesto

## Autor
Michael Salazar

## Contexto

Open Finance se basa en la evolución del Open Banking que nos permitirá compartir la información de los usuarios y sus datos financieros de manera segura con terceros autorizados. Este intercambio de información se realiza siempre que el usuario nos otorga el consentimiento para compartir su información. Normalmente estos datos son expuestos o enviados por APIs seguras entre sistemas para:

- Consultar productos del cliente
- Gestionar pagos en nombre del cliente
- Exponer información transaccional para casos de uso tipo scoring o análisis financiero

Al mismo tiempo, esta integración no debe afectar el funcionamiento de:

- El **core digital** como fachada principal de negocio para las aplicaciones de frontend o canales expuestos
- El **core tradicional** integrado según el **ADR-001**
- La integración de pagos según el **ADR-002**

Requisitos que se deben tener en cuenta para Open Finance:

- Se debe tener en cuenta la seguridad y cumplimiento normativo LOPD vigente, estándares tipo PSD2/Open Banking y PCI DSS / ISO 27001 para la tratar y transportar la información sensible del cliente
- El cliente debe autorizar explícitamente los datos que se puedan exponer o compartir con terceros
- No se debe acoplar las integraciones y servicios expuestos a terceros directamente a los cores
- Se debe garantizar la observabilidad, auditoría y trazabilidad de quién accedió, a qué, cuándo, desde dónde y bajo qué consentimiento
- Debemos considerar la gobernanza versionando las APIs, revocando accesos, incorporando nuevas integraciones de terceros o nuevos casos de uso sin romper el modelo actual

## Supuestos

- La exposición de APIs de Open Finance se realizará a través de una **capa dedicada**
- El banco ya cuenta con un **IAM central** como Keycloak u Okta que nos permitirá soportar:
  - OAuth2 / OIDC
  - Flujos de consentimiento
  - Permisos por API y proveedor
- El **Bus de Mensajes** definido en ADR-001 y ADR-002 es el backbone interno para gestionar los eventos de cuentas, pagos y clientes
- Los sistemas de **riesgo, fraude y auditoría** consumirán eventos de Open Finance para cumplir con las regulaciones

## Consideraciones

Adicional a definir una solución de integración, en el análisis de una solución escalable se plantea las siguientes observaciones de seguridad y cumplimiento para tenerlo presente en el proceso de integración que serían:

- Los servicios de terceros no deben integrarse directamente con el core digital o tradicional
- La **capa de Open Finance** debe aplicar principios de:
  - *Least Privilege*
  - *Data Minimization*
  - *Zero Trust Architecture*
- También deben existir mecanismos claros para controlar:
  - **Rate limit**, **quotas**, **throttling**
  - **Revocación** de consentimientos y tokens
  - **Versionado** y **deprecación** de APIs

---

## Opciones consideradas

### Opción 1: Integración Directa de Terceros Contra APIs de Dominio Internas

En esta opción, los servicios de terceros se integrarían directamente con APIs internas del dominio a través del API Gateway genérico, compartiendo rutas con canales internos. Se podría incrementar la seguridad y cumplimiento, integrando una conexión VPN peer to peer pero es opcional

#### Pros

- No se debe gestionar muchos cambios a nivel de arquitectura porque los componentes adicionales serían pequeños
- La simplicidad inicial nos permitiría reutilizar directamente las APIs internas para otros proveedores

#### Contras

- Existe un alto acoplamiento entre los servicios de terceros y APIs internas. Entonces, cualquier cambio interno de contratos impacta directamente a los terceros o directamente al core
- Dejamos una brecha abierta que permitiría tener una **superficie de ataque** hacia las APIs internas ya que están expuestas hacia el exterior para que los proveedores accedan
- No tendríamos claro un modelo de consentimientos para la gobernanza específica de Términos y condiciones o control de accesos por proveedor
- Nos va dificultar cumplir plenamente con los requisitos regulatorios ya que el API Gateway se convertiría en el único punto de entrada a los servicios internos

---

### Opción 2: Capa dedicada de Open Finance usando API Manager con mensajería interna

En esta opción, se desarrollaría una **capa de integración especializada** únicamente para **Open Finance**, que estaría alineada con ADR-001 y ADR-002 que incluiría:

- Un componente **Open Finance API** que nos va a permitir:

  - Utilizar el patrón **Factoy Method** y **Abstract Factory** para exponer una única **API** e internamente gestionar la lógica de forma independiente por proveedor
  - Se integra con el **API Gateway interno** que nos permitirá gestionar la autenticación y autorización via OAuth2/OIDC, configurar un rate limit y registrar los accesos de los servicios de terceros con gestión de claves, certificados y seguridades punto a punto.
  - Internamente, el API Manager se debe integrar con el core digital mediante los patrones **Messaging Gateway** para flujos asíncronos y **Request-Reply** hacia servicios de dominio para consultas síncronas

- Una vez implementado el patrón Factory, podríamos escalar nuestra integración por servicio de tercero ya que se implementarían los patrones:

  - **Message Filter** para exponer únicamente los campos autorizados por consentimiento y regulaciones de datos personales
  - **Canonical Data Model** para unificar los contratos en el adaptador de Open Finance independientemente de si los datos vienen del core digital o del core tradicional
  - **Publish-Subscribe** para publicar eventos de accesos de terceros, operaciones iniciadas por terceros, consentimientos creados o revocados y eventos que analizarán el riesgo, fraude y auditoría
  - **Messaging Gateway** para desacoplar la capa que se expone para Open Finance de los detalles del Bus de Mensajes y los servicios internos

#### Pros

- Los servicios de terceros nunca hablan directamente con servicios internos ni con los cores
- Los contratos, políticas de seguridad, cumplimiento de LOPD, requisitos de OAuth2/OIDC y auditoría son gestionados por accesos y operaciones independientes
- Reutiliza la infraestructura y patrones definidos en ADR-001 y ADR-002
- Permite evolucionar la oferta de Open Finance disponibilizando nuevos endpoints, nuevas combinaciones de datos, sin cambiar el core

#### Contras

- Se introduce una capa dedicada con lógica específica para integrar Open Finance
- Requiere asociar un servicio de IAM, API Manager y bus de mensajes para diseñar bien los alcances, claims, tokens y mapeo a permisos internos
- Implica establecer un proceso fuerte de **gobernanza de APIs** para versionado, ciclo de vida y certificación de terceros

---

## Decisión

En base a los requisitos de seguridad, desacoplamiento, cumplimiento normativo, capacidad evolutiva y alineación con la arquitectura basada en mensajería ya definida, se escoge la **Opción 2**

---

## Razonamiento

1. Los terceros nunca consumen APIs internas ni acceden directamente al core tradicional o al core digital

2. La capa Open Finance abstrae y protege el dominio interno

3. Se agrupa un solo lugar para mantener catálogo de APIs para terceros, registro de proveedores, consentimientos y SLAs, así como políticas de seguridad y cumplimiento

4. La capa Open Finance consume eventos de cuentas, pagos, clientes cuando necesita datos históricos o real-time. Publica eventos de accesos, consentimientos y operaciones iniciadas por terceros. Y se mantiene la coherencia del modelo orientado a eventos y del Bus de Mensajes

5. Si existen cambios regulatorios, nuevas APIs requeridas por Open Finance o nuevos partners, se desarrollan principalmente en la capa Open Finance y en los contratos canónicos, sin romper ni acoplar directamente al core

6. A través de **Message Store**, **Message History** y trazas de API Manager, se puede reconstruir el flujo completo de una operación iniciada por terceros, desde el cliente final hasta el core y los sistemas de riesgo ó fraude

---

## Consecuencias

### Positivas

- Arquitectura de Open Finance **robusta, segura y gobernable**
- Menor impacto en cores y dominios internos ante cambios regulatorios o nuevas integraciones
- Alineación con el modelo **event-driven** y de mensajería ya adoptado en **ADR-001** y **ADR-002**
- Mayor capacidad para **auditar y demostrar cumplimiento** ante reguladores
- Facilidad para incorporar **nuevos terceros** o **nuevas APIs** sin reescribir servicios internos

### Negativas

- Mayor complejidad inicial para el diseño de la capa Open Finance, sus contratos, sus flujos de consentimiento y seguridad
- Requiere un **equipo de gobierno de APIs y seguridad** para mantener catálogo, versionado, políticas y certificación de terceros, así como un oficial de cumplimiento y el oficial de seguridad para otorgar y revocar accesos
- Implica integrar varias soluciones como IAM, API Manager, Bus de Mensajes, dominio interno, monitoreo y logging

---

## Decisiones relacionadas

- **ADR-001** – Integración entre Core Bancario Tradicional y Core Bancario Digital mediante mensajería y adaptadores.  
- **ADR-002** – Integración con la Plataforma de Servicios de Pago mediante Bus de Mensajes y Adaptador de Pagos.  

---

## Referencias

- *Enterprise Integration Patterns* – Gregor Hohpe & Bobby Woolf  
- *Microservices Patterns* – Chris Richardson  
- Especificaciones de Open Banking / Open Finance
- Documentación de OAuth2 / OIDC para flujos de consentimiento de terceros
