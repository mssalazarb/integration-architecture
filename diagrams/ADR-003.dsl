workspace "ADR-003 - Integración con Servicios de Terceros para Open Finance" {

    model {
        customer = person "Customer" {
            description "Cliente que otorga el consentimiento para compartir su información financiera con terceros autorizados"
            tags "Person"
        }

        thirdParty = person "Third Party Service" {
            description "Servicio de terceros/proveedor que consume APIs de Open Finance con el consentimiento del cliente"
            tags "Person"
        }

        bankingPlatform = softwareSystem "Digital Banking Platform" {
            description "Plataforma bancaria digital que expone APIs a canales y orquesta los procesos de negocio"
            tags "InternalSystem"

            apiGateway = container "API Gateway / API Manager" {
                description "Gateway/API Manager interno que expone APIs de Open Finance a terceros, aplica OAuth2/OIDC, rate limit, cuotas, logging y control de accesos"
                technology "Kong / KrakenD"
                tags "Gateway"
            }

            digitalCore = container "Digital Core" {
                description "Core bancario digital que orquesta consultas y operaciones de negocio internas"
                technology "Java / Spring Boot / EKS-AKS"
                tags "DigitalCore"
            }

            openFinanceApi = container "Open Finance API" {
                description "Capa dedicada de Open Finance que aplica Factory Method / Abstract Factory, Message Filter, Canonical Data Model y mensajería interna"
                technology "Java / Spring Boot / Integration Framework"
                tags "OpenFinance"

                openFinanceFactory = component "Open Finance Factory" {
                    description "Implementa Factory Method y Abstract Factory para exponer una única API de Open Finance e instanciar la lógica específica por proveedor/servicio de terceros"
                    technology "Spring Boot / Patterns"
                    tags "Domain"
                }

                openFinanceMessageFilter = component "Open Finance Message Filter" {
                    description "Aplica el patrón Message Filter para exponer únicamente los campos autorizados por consentimiento y regulaciones de datos personales (Data Minimization)"
                    technology "Spring Boot / Integration Filter"
                    tags "MessageFilter"
                }

                openFinanceCanonicalMapper = component "Open Finance Canonical Mapper" {
                    description "Implementa el Canonical Data Model para unificar contratos de Open Finance independientemente de si los datos provienen del core digital o del core tradicional"
                    technology "Spring Boot / Mapping"
                    tags "CanonicalModel"
                }

                openFinanceMessagingGateway = component "Open Finance Messaging Gateway" {
                    description "Implementa Messaging Gateway y Request-Reply hacia servicios internos, y usa Publish-Subscribe para publicar eventos de accesos, operaciones iniciadas por terceros y consentimientos creados o revocados"
                    technology "Spring Boot / Integration / Messaging"
                    tags "MessagingGateway"
                }
            }

            eventsBus = container "Events & Messaging Bus" {
                description "Bus de eventos y mensajería usado como backbone interno para eventos de cuentas, pagos, clientes y eventos de Open Finance"
                technology "Kafka / RabbitMQ"
                tags "MessageBus"
            }
        }

        iam = softwareSystem "IAM" {
            description "Proveedor IAM central (Keycloak / Okta) que gestiona OAuth2/OIDC, flujos de consentimiento y permisos por API y proveedor"
            tags "ExternalSystem"
        }

        auditSystem = softwareSystem "Audit System" {
            description "Sistema de auditoría que consume eventos de Open Finance para trazabilidad, cumplimiento regulatorio y reconstrucción de operaciones"
            tags "ExternalSystem"
        }

        riskSystem = softwareSystem "Risk System" {
            description "Sistema de riesgo que consume eventos de Open Finance para análisis de riesgo asociado a accesos y operaciones iniciadas por terceros"
            tags "ExternalSystem"
        }

        fraudSystem = softwareSystem "Fraud System" {
            description "Sistema de prevención de fraude que consume eventos de Open Finance para detectar patrones sospechosos en accesos y operaciones"
            tags "ExternalSystem"
        }

        customer -> thirdParty "Otorga consentimiento para compartir su información financiera con" "Términos y condiciones / Consentimiento" {
            tags "Relationship"
        }

        thirdParty -> apiGateway "Consume APIs de Open Finance a través de" "HTTPS / REST / OAuth2" {
            tags "RequestReply"
        }

        apiGateway -> iam "Valida tokens, permisos, consentimientos y scopes mediante" "OAuth2 / OIDC" {
            tags "RequestReply"
        }

        apiGateway -> openFinanceFactory "Envía solicitudes a la capa Open Finance mediante" "REST / OpenAPI / Request-Reply" {
            tags "RequestReply"
        }

        openFinanceFactory -> openFinanceMessageFilter "Invoca la lógica de filtrado de campos según consentimiento y regulaciones (Message Filter)" "Internal Call" {
            tags "Relationship"
        }

        openFinanceMessageFilter -> openFinanceCanonicalMapper "Transforma los datos al modelo canónico de Open Finance" "Internal Call" {
            tags "Relationship"
        }

        openFinanceCanonicalMapper -> openFinanceMessagingGateway "Envía comandos y consultas hacia servicios internos usando mensajería" "Internal Call" {
            tags "MessagingGateway"
        }

        openFinanceMessagingGateway -> digitalCore "Realiza consultas síncronas a servicios de dominio internos usando Request-Reply" "Request-Reply" {
            tags "RequestReply", "MessagingGateway"
        }

        openFinanceMessagingGateway -> eventsBus "Publica eventos de accesos de terceros, operaciones iniciadas por terceros y consentimientos creados o revocados (Publish-Subscribe)" "Event Message / Publish-Subscribe" {
            tags "EventDriven", "MessagingGateway"
        }

        eventsBus -> openFinanceMessagingGateway "Entrega eventos internos de cuentas, pagos y clientes para que la capa Open Finance pueda consumir datos históricos o real-time cuando lo requiera" "Event Message / Publish-Subscribe" {
            tags "EventDriven"
        }

        eventsBus -> auditSystem "Publica eventos de Open Finance para observabilidad, auditoría y trazabilidad (Message Store / Message History)" "Event Message / Publish-Subscribe" {
            tags "EventDriven"
        }

        eventsBus -> riskSystem "Publica eventos de Open Finance para análisis de riesgo asociado a accesos y operaciones de terceros" "Event Message / Publish-Subscribe" {
            tags "EventDriven"
        }

        eventsBus -> fraudSystem "Publica eventos de Open Finance para detección de fraude asociado a accesos y operaciones de terceros" "Event Message / Publish-Subscribe" {
            tags "EventDriven"
        }
    }

    views {
        systemContext bankingPlatform {
            include customer
            include thirdParty
            include bankingPlatform
            include iam
            include auditSystem
            include riskSystem
            include fraudSystem
            autoLayout lr
        }

        container bankingPlatform {
            include customer
            include thirdParty
            include apiGateway
            include digitalCore
            include openFinanceApi
            include eventsBus
            include iam
            include auditSystem
            include riskSystem
            include fraudSystem

            autoLayout lr
        }

        component openFinanceApi {
            description "Vista de la capa Open Finance, su integración con API Gateway, IAM, Bus de Mensajes y sistemas consumidores de eventos, mostrando Factory Method, Abstract Factory, Message Filter, Canonical Data Model, Messaging Gateway, Request-Reply y Publish-Subscribe"

            include customer
            include thirdParty
            include apiGateway
            include openFinanceApi
            include openFinanceFactory
            include openFinanceMessageFilter
            include openFinanceCanonicalMapper
            include openFinanceMessagingGateway
            include digitalCore
            include eventsBus
            include iam
            include auditSystem
            include riskSystem
            include fraudSystem

            autoLayout lr
        }

        styles {
            element "Person" {
                shape person
                background "#08427b"
                color "#ffffff"
            }

            element "InternalSystem" {
                shape RoundedBox
                background "#1168bd"
                color "#ffffff"
            }

            element "DigitalCore" {
                shape RoundedBox
                background "#1971c2"
                color "#ffffff"
            }

            element "Gateway" {
                shape RoundedBox
                background "#0b7285"
                color "#ffffff"
            }

            element "OpenFinance" {
                shape RoundedBox
                background "#e8590c"
                color "#ffffff"
            }

            element "Domain" {
                shape RoundedBox
                background "#364fc7"
                color "#ffffff"
            }

            element "MessageBus" {
                shape pipe
                background "#495057"
                color "#ffffff"
            }

            element "MessageFilter" {
                shape RoundedBox
                background "#f08c00"
                color "#ffffff"
            }

            element "CanonicalModel" {
                shape RoundedBox
                background "#5c940d"
                color "#ffffff"
            }

            element "MessagingGateway" {
                shape RoundedBox
                background "#862e9c"
                color "#ffffff"
            }

            element "ExternalSystem" {
                shape RoundedBox
                background "#90ee90"
                color "#000000"
            }

            relationship "Relationship" {
                thickness 2
                color "#707070"
                fontSize 22
            }

            relationship "RequestReply" {
                color "#2d9cdb"
                thickness 3
            }

            relationship "EventDriven" {
                color "#37b24d"
                thickness 3
            }

            relationship "MessagingGateway" {
                color "#862e9c"
                thickness 3
            }
        }
    }
}
