workspace "ADR-0001 - Integración core tradicional y core digital" "Aplicación de patrones de integración empresarial para integración multicore" {

    model {
        customer = person "Customer" "Cliente que usa banca web/móvil" {
            tags "Person"
        }

        fintech = person "Fintech" "Terceros que consumen APIs de Open Finance" {
            tags "Person"
        }

        digitalBankingPlatform = softwareSystem "Digital Banking Platform" "Plataforma digital que expone un core unificado a canales y terceros" {
            tags "DigitalCoreSystem"

            apiGateway = container "API Gateway" {
                description "Fachada de APIs para web, móvil y terceros. Encapsula canal y se integra con el core digital"
                technology "Kong / KrakenD / Ocelot"
                tags "Gateway"
            }

            digitalCore = container "Digital Core Banking" {
                description "Core bancario digital que orquesta operaciones y decide entre core digital y core tradicional"
                technology "Java / Spring Boot / EKS-AKS"
                tags "DigitalCore"
                
                accountsService = component "Accounts and Ledger Service" {
                    description "Gestión de cuentas, saldos y transacciones internas que publica eventos"
                    technology "Java / Spring Boot"
                    tags "Domain"
                }
                
                paymentsService = component "Payments Orchestration Service" {
                    description "Orquestación de pagos y transferencias, decide a qué core o plataforma de pagos enviar la operación"
                    technology "Spring Boot"
                    tags "Domain"
                }
    
                multicoreRouter = component "Multicore Routing Component" {
                    description "Implementa Content-Based Router para decidir entre core digital y tradicional según el producto, segmento o fase de migración"
                    technology "Spring Boot / Integration Framework"
                    tags "ContentBasedRouter"
                }
            }

            eventsBus = container "Events & Integration Bus" {
                description "Bus de eventos y mensajería que soporta Event Messages"
                technology "Kafka / RabbitMQ"
                tags "MessageBus"
            }

            auditService = container "Audit & Logging Service" {
                description "Servicio central de auditoría que recibe copias de los mensajes críticos y eventos de negocio"
                technology "Golang"
                tags "Observability"
            }

            tradicionalCoreAdapter = container "Tradicional Core Adapter" {
                description "Capa de integración hacia el core tradicional"
                technology "Java / Spring Boot / Messaging Gateway / Service Activator / Message Translator"
                tags "IntegrationAdapter"
            }
        }

        tradicionalCore = softwareSystem "tradicional Core Banking" {
            description "Core bancario tradicional que mantiene productos y procesos existentes"
            tags "tradicionalCoreSystem"
        }

        customer -> apiGateway "Opera sus productos a través de" "HTTPS / REST" {
            tags "RequestReply"
        }

        fintech -> apiGateway "Consume APIs y productos del banco a través de" "HTTPS / REST" {
            tags "RequestReply"
        }

        apiGateway -> digitalCore "Envía comandos y consultas mediante integración interna (REST/gRPC/Gateway)" "REST / Request-Reply" {
            tags "RequestReply"
        }

        apiGateway -> accountsService "Envía comandos y consultas (Request-Reply) mediante integración interna (REST/gRPC/Gateway)" "REST / Request-Reply" {
            tags "RequestReply"
        }

        apiGateway -> paymentsService "Envía comandos y consultas (Request-Reply) mediante integración interna (REST/gRPC/Gateway)" "REST / Request-Reply" {
            tags "RequestReply"
        }

        digitalCore -> eventsBus "Publica comandos y eventos de dominio (Command Message + Event Message)" "Command Message / Event Message" {
            tags "EventDriven"
        }

        eventsBus -> digitalCore "Retorna respuestas síncronas (Reply) o eventos para procesos internos" "Reply / Event Message" {
            tags "EventDriven"
        }

        accountsService -> eventsBus "Publica eventos de cuentas, saldos y movimientos" "Event Message / Publish-Subscribe" {
            tags "EventDriven"
        }

        paymentsService -> multicoreRouter "Envía solicitudes de operación para decidir el core de destino" "Internal Call / Route Decision" {
            tags "ContentBasedRouter"
        }

        multicoreRouter -> eventsBus "Envía comandos de pago/transacción al core correspondiente (Digital o tradicional) usando Content-Based Routing" "Command Message / Content-Based Router" {
            tags "ContentBasedRouter", "EventDriven"
        }

        eventsBus -> tradicionalCoreAdapter "Entrega comandos dirigidos al Core Tradicional" "Command Message / Request-Reply" {
            tags "MessagingGateway", "RequestReply"
        }

        tradicionalCoreAdapter -> eventsBus "Publica respuestas y eventos provenientes del Core Tradicional" "Reply / Event Message" {
            tags "MessagingGateway", "EventDriven"
        }

        tradicionalCoreAdapter -> tradicionalCore "Invoca operaciones tradicional (Service Activator sobre MQ/SOAP/APIs)" "SOAP / APIs" {
            tags "MessagingGateway", "ServiceActivator", "RequestReply"
        }

        eventsBus -> auditService "Envía copias de mensajes y eventos críticos vía Wire Tap para auditoría y trazabilidad" "Message Store / Message History" {
            tags "WireTap", "EventDriven"
        }
    }

    views {

        systemContext digitalBankingPlatform {
            include customer
            include fintech
            include digitalBankingPlatform
            include tradicionalCore
            autoLayout lr
        }

        container digitalBankingPlatform {
            include customer
            include fintech
            include apiGateway
            include digitalCore
            include eventsBus
            include auditService
            include tradicionalCoreAdapter
            include tradicionalCore
            autoLayout lr
        }

        component digitalCore {
            description "Vista de los componentes del Core Digital, el Adapter tradicional y el Bus de Mensajes, mostrando Content-Based Router, Messaging Gateway, Service Activator y Event-Driven."

            include customer
            include fintech

            include apiGateway
            include digitalCore
            include accountsService
            include paymentsService
            include multicoreRouter
            include eventsBus
            include auditService
            include tradicionalCoreAdapter
            include tradicionalCore

            autoLayout lr
        }

        styles {
            element "Person" {
                shape person
                background "#08427b"
                color "#ffffff"
            }

            element "DigitalCoreSystem" {
                shape RoundedBox
                background "#1168bd"
                color "#ffffff"
            }

            element "tradicionalCoreSystem" {
                shape RoundedBox
                background "#fb6944"
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

            element "ContentBasedRouter" {
                shape Hexagon
                background "#f08c00"
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

            element "Observability" {
                shape RoundedBox
                background "#343a40"
                color "#ffffff"
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
