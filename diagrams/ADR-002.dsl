workspace "ADR-002 - Integración con Plataforma de Pagos" {

    model {
        customer = person "Customer" {
            description "Cliente que inicia pagos y transferencias desde banca web/móvil"
            tags "Person"
        }

        bankingPlatform = softwareSystem "Digital Banking Platform" {
            description "Plataforma bancaria digital que expone APIs a canales y orquesta los pagos"
            tags "InternalSystem"

            apiGateway = container "API Gateway" {
                description "Fachada de APIs para web, móvil y terceros que se integra con el core digital"
                technology "Kong / KrakenD"
                tags "Gateway"
            }

            digitalCore = container "Digital Core" {
                description "Core bancario digital que orquesta pagos, consultas y procesos de negocio"
                technology "Java / Spring Boot / EKS-AKS"
                tags "DigitalCore"

                paymentsService = component "Payments Orchestration" {
                    description "Servicio de orquestación de pagos y transferencias que construye los comandos de pago, aplica reglas de negocio y usa Request-Reply vía Bus de Mensajes"
                    technology "Java / Spring Boot"
                    tags "Domain"
                }
            }

            eventsBus = container "Events & Messaging Bus" {
                description "Bus de eventos y mensajería que soporta Command Message, Event Message, Request-Reply"
                technology "Kafka / RabbitMQ"
                tags "MessageBus"
            }

            paymentsAudit = container "Payments Audit & Tracing Service" {
                description "Servicio de auditoría de pagos que persiste Message Store / Message History"
                technology "Java / Spring Boot"
                tags "Observability"
            }

            paymentAdapter = container "Payment Platform Adapter" {
                description "Adaptador especializado hacia la Plataforma de Pagos Implementa Messaging Gateway, Service Activator, Message Translator y Content-Based Router para múltiples proveedores"
                technology "Java / Spring Boot / Integration Framework"
                tags "IntegrationAdapter"

                paymentRoutingEngine = component "Payment Routing Engine" {
                    description "Componente interno que implementa Content-Based Router para enrutar transacciones entre múltiples procesadores de pago"
                    technology "Spring Boot / Integration Framework"
                    tags "ContentBasedRouter"
                }

                protocolConnector = component "Payment Protocol Connector" {
                    description "Implementa Service Activator y Message Translator para convertir mensajes canónicos en ISO 8583, REST específicos de cada proveedor y viceversa"
                    technology "Java / Spring Boot"
                    tags "MessagingConnector"
                }
            }
        }

        paymentPlatform = softwareSystem "Payment Platform" {
            description "Plataforma de servicios de pago que autoriza y liquida pagos"
            tags "ExternalSystem"
        }

        riskSystem = softwareSystem "Risk System" {
            description "Sistema de riesgo que evalúa y monitorea exposiciones asociadas a pagos y transacciones"
            tags "ExternalSystem"
        }

        fraudSystem = softwareSystem "Fraud System" {
            description "Sistema de prevención de fraude que consume eventos de pagos para detectar patrones sospechosos en línea y batch"
            tags "ExternalSystem"
        }

        customer -> apiGateway "Inicia pagos y transferencias a través de" "HTTPS / REST" {
            tags "RequestReply"
        }

        apiGateway -> paymentsService "Envía solicitudes de pago/transferencia mediante" "REST / Request-Reply" {
            tags "RequestReply"
        }

        paymentsService -> eventsBus "Envía comandos de autorización de pago y espera respuesta usando Request-Reply" "Command Message / Request-Reply" {
            tags "RequestReply", "EventDriven"
        }

        eventsBus -> paymentsService "Entrega respuesta de autorización de pago como Reply Message" "Reply Message / Request-Reply" {
            tags "RequestReply", "EventDriven"
        }

        eventsBus -> paymentRoutingEngine "Entrega comandos de pago dirigidos a la capa de integración de pagos" "Command Message" {
            tags "EventDriven", "ContentBasedRouter"
        }

        paymentRoutingEngine -> protocolConnector "Selecciona proveedor y delega la invocación según reglas (Content-Based Router)" "Internal Call / Route Decision" {
            tags "ContentBasedRouter"
        }

        protocolConnector -> paymentPlatform "Invoca autorizaciones y operaciones de pago usando Service Activator (ISO 8583 / REST)" "Service Activator / Request-Reply" {
            tags "ServiceActivator", "MessagingGateway", "RequestReply"
        }

        paymentPlatform -> protocolConnector "Retorna respuesta de autorización, reverso o error" "Response / Request-Reply" {
            tags "ServiceActivator", "MessagingGateway", "RequestReply"
        }

        protocolConnector -> eventsBus "Publica respuestas de autorización y eventos de pagos, liquidaciones y conciliaciones" "Reply Message / Event Message" {
            tags "MessagingGateway", "EventDriven"
        }

        eventsBus -> paymentsAudit "Envía copias de mensajes críticos para trazabilidad y cumplimiento (Wire Tap)" "Wire Tap / Message Store / Message History" {
            tags "WireTap", "EventDriven"
        }

        eventsBus -> riskSystem "Publica eventos de pagos para evaluación de riesgo" "Event Message / Publish-Subscribe" {
            tags "EventDriven"
        }

        eventsBus -> fraudSystem "Publica eventos de pagos para detección de fraude" "Event Message / Publish-Subscribe" {
            tags "EventDriven"
        }
    }

    views {
        systemContext bankingPlatform {
            include customer
            include bankingPlatform
            include paymentPlatform
            include riskSystem
            include fraudSystem
            autoLayout lr
        }

        container bankingPlatform {
            include customer
            include apiGateway
            include digitalCore
            include eventsBus
            include paymentsAudit
            include paymentAdapter
            include paymentPlatform
            include riskSystem
            include fraudSystem

            autoLayout lr
        }

        component digitalCore {
            description "Vista de los componentes de orquestación de pagos, bus de mensajería y adaptador de pagos, mostrando Request-Reply, Event Message, Messaging Gateway, Service Activator y Content-Based Router"

            include customer
            include apiGateway
            include paymentsService
            include eventsBus
            include paymentsAudit
            include paymentAdapter
            include paymentRoutingEngine
            include protocolConnector
            include paymentPlatform
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

            element "IntegrationAdapter" {
                shape RoundedBox
                background "#5c940d"
                color "#ffffff"
            }

            element "ContentBasedRouter" {
                shape Hexagon
                background "#f08c00"
                color "#ffffff"
            }

            element "MessagingConnector" {
                shape RoundedBox
                background "#862e9c"
                color "#ffffff"
            }

            element "Observability" {
                shape RoundedBox
                background "#343a40"
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

            relationship "ServiceActivator" {
                color "#ae3ec9"
                thickness 3
            }

            relationship "ContentBasedRouter" {
                color "#f08c00"
                thickness 3
            }

            relationship "WireTap" {
                color "#212529"
                thickness 3
            }
        }
    }
}
