workspace "ADR-004 - Integración con Sistema de Gestión de Riesgos" {

    model {
        customer = person "Customer" {
            description "Cliente que realiza solicitudes o transacciones financieras que requieren evaluación de riesgo"
            tags "Person"
        }

        bankingPlatform = softwareSystem "Digital Banking Platform" {
            description "Plataforma bancaria digital donde se ejecutan los procesos internos del core digital"
            tags "InternalSystem"

            digitalCore = container "Digital Core" {
                description "Core digital que orquesta procesos internos como apertura de productos, validación de límites, scoring y movimientos"
                technology "Java / Spring Boot / EKS-AKS"
                tags "DigitalCore"

                coreRiskClient = component "Core Risk Client" {
                    description "Componente interno del core digital que envía solicitudes de evaluación de riesgo y procesa las respuestas para los procesos de negocio"
                    technology "Java / Spring Boot"
                    tags "Domain"
                }
            }

            eventsBus = container "Events & Messaging Bus" {
                description "Bus de mensajería que actúa como columna vertebral para Command Message, Request-Reply y Publish-Subscribe entre el core digital, el Adaptador de Riesgo y el sistema de gestión de riesgos"
                technology "Kafka / RabbitMQ"
                tags "MessageBus"
            }

            riskAdapter = container "Risk Adapter" {
                description "Adaptador especializado para integrar el core digital con el sistema de gestión de riesgos usando Messaging Gateway, Service Activator y Message Translator"
                technology "Java / Spring Boot / Integration Framework"
                tags "IntegrationAdapter"

                riskMessagingGateway = component "Risk Messaging Gateway" {
                    description "Implementa el patrón Messaging Gateway para la comunicación desacoplada con el sistema de gestión de riesgos usando Command Message, Request-Reply y Publish-Subscribe"
                    technology "Spring Boot / Integration"
                    tags "MessagingGateway"
                }

                riskMessageTranslator = component "Risk Message Translator" {
                    description "Implementa Message Translator para estandarizar los datos enviados y recibidos con el sistema de gestión de riesgos"
                    technology "Spring Boot / Mapping"
                    tags "MessagingConnector"
                }

                riskServiceActivator = component "Risk Service Activator" {
                    description "Implementa Service Activator para ejecutar llamadas HTTP/SOAP hacia el sistema de gestión de riesgos"
                    technology "Spring Boot / Integration"
                    tags "ServiceActivator"
                }
            }
        }

        riskSystem = softwareSystem "Risk Management System" {
            description "Sistema de gestión de riesgos que evalúa reglas internas, umbrales, límites y escenarios de riesgo para solicitudes y transacciones financieras"
            tags "ExternalSystem"
        }

        customer -> digitalCore "Inicia solicitudes o transacciones financieras que requieren evaluación de riesgo" "Canales internos" {
            tags "Relationship"
        }

        coreRiskClient -> eventsBus "Envía Command Message para evaluaciones de riesgo y espera respuesta usando Request-Reply" "Command Message / Request-Reply" {
            tags "RequestReply", "EventDriven"
        }

        eventsBus -> riskMessagingGateway "Entrega Command Message de evaluación de riesgo al Adaptador" "Command Message" {
            tags "EventDriven", "MessagingGateway"
        }

        riskMessagingGateway -> riskMessageTranslator "Envía solicitudes de evaluación de riesgo para estandarizar datos (Message Translator)" "Internal Call" {
            tags "Relationship"
        }

        riskMessageTranslator -> riskServiceActivator "Envía solicitud estandarizada al Service Activator para invocar al sistema de gestión de riesgos" "Internal Call" {
            tags "Relationship"
        }

        // Adaptadr ↔ Sistema de gestión de riesgos (Service Activator / Request-Reply)
        riskServiceActivator -> riskSystem "Ejecuta llamadas HTTP/SOAP para solicitar evaluación de riesgo" "Service Activator / Request-Reply" {
            tags "ServiceActivator", "RequestReply"
        }

        riskSystem -> riskServiceActivator "Retorna la respuesta de evaluación de riesgo para la solicitud enviada" "Response / Request-Reply" {
            tags "ServiceActivator", "RequestReply"
        }

        riskServiceActivator -> riskMessagingGateway "Retorna la respuesta de evaluación de riesgo al Messaging Gateway" "Internal Call" {
            tags "Relationship"
        }

        riskMessagingGateway -> eventsBus "Publica Reply Message con el resultado de evaluación de riesgo y notificaciones relacionadas" "Reply Message / Event Message" {
            tags "MessagingGateway", "EventDriven"
        }

        eventsBus -> coreRiskClient "Entrega Reply Message con el resultado de la evaluación de riesgo para el proceso interno" "Reply Message / Request-Reply" {
            tags "RequestReply", "EventDriven"
        }

        digitalCore -> eventsBus "Publica eventos de movimientos, pagos y cambios de estado para análisis de riesgo" "Event Message / Publish-Subscribe" {
            tags "EventDriven"
        }

        eventsBus -> riskSystem "Publica eventos de movimientos, pagos y cambios de estado para que el sistema de gestión de riesgos los procese" "Event Message / Publish-Subscribe" {
            tags "EventDriven"
        }
    }

    views {
        systemContext bankingPlatform {
            include customer
            include bankingPlatform
            include riskSystem
            autoLayout lr
        }

        container bankingPlatform {
            include customer
            include digitalCore
            include eventsBus
            include riskAdapter
            include riskSystem

            autoLayout lr
        }

        component digitalCore {
            description "Vista de los componentes que participan en la integración híbrida entre el core digital, el Adaptador de Riesgo y el sistema de gestión de riesgos usando Bus de Mensajes, Messaging Gateway, Service Activator, Message Translator, Request-Reply y Publish-Subscribe"

            include customer
            include digitalCore
            include coreRiskClient
            include eventsBus
            include riskAdapter
            include riskMessagingGateway
            include riskMessageTranslator
            include riskServiceActivator
            include riskSystem

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

            element "MessagingGateway" {
                shape RoundedBox
                background "#862e9c"
                color "#ffffff"
            }

            element "MessagingConnector" {
                shape RoundedBox
                background "#f08c00"
                color "#ffffff"
            }

            element "ServiceActivator" {
                shape RoundedBox
                background "#ae3ec9"
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
        }
    }
}
