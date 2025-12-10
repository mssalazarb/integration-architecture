workspace "ADR-005 - Integración con Sistema de Prevención de Fraudes" {

    model {

        customer = person "Customer" {
            description "Cliente que realiza transacciones que deben ser evaluadas por el sistema de prevención de fraude"
            tags "Person"
        }

        bankingPlatform = softwareSystem "Digital Banking Platform" {
            description "Plataforma bancaria digital que orquesta procesos internos del core digital y publica eventos transaccionales"
            tags "InternalSystem"

            digitalCore = container "Digital Core" {
                description "Core digital que procesa solicitudes y transacciones financieras y envía información relevante para evaluación de fraude"
                technology "Java / Spring Boot / EKS-AKS"
                tags "DigitalCore"

                fraudClient = component "Fraud Evaluation Client" {
                    description "Componente interno que envía eventos transaccionales y marca aquellas operaciones que requieren evaluación de fraude en tiempo inmediato"
                    technology "Java / Spring Boot"
                    tags "Domain"
                }
            }

            eventStream = container "Event Stream Platform" {
                description "Plataforma de streaming de eventos que distribuye eventos de transacciones, movimientos y operaciones para procesamiento de fraude"
                technology "Kafka / Event Stream"
                tags "EventStream"
            }

            fraudStreamProcessor = container "Fraud Stream Processor" {
                description "Procesador de streams para detección basada en streaming usando Apache Flink. Aplica ventanas de tiempo, correlación y patrones complejos de fraude"
                technology "Apache Flink"
                tags "StreamProcessor"

                fraudEnrichment = component "Fraud Enrichment" {
                    description "Implementa Enrichment para agregar datos adicionales antes de evaluar fraude (dispositivo, geolocalización, historial, límites)"
                    technology "Flink / Enrichment Logic"
                    tags "Enrichment"
                }

                fraudClaimCheck = component "Fraud Claim Check" {
                    description "Implementa Claim Check para almacenar datos sensibles en un repositorio seguro y enviar solo metadatos al pipeline de fraude"
                    technology "Flink / Secure Reference"
                    tags "ClaimCheck"
                }

                fraudCorrelation = component "Fraud Correlation Identifier" {
                    description "Implementa Correlation Identifier para correlacionar transacciones de un mismo cliente, dispositivo, IP o canal en ventanas de tiempo"
                    technology "Flink / Correlation"
                    tags "CorrelationIdentifier"
                }

                fraudRoutingSlip = component "Fraud Routing Slip" {
                    description "Implementa Routing Slip para configurar dinámicamente qué validaciones debe pasar una transacción en el pipeline de fraude"
                    technology "Flink / Routing"
                    tags "RoutingSlip"
                }

                fraudScatterGather = component "Fraud Scatter-Gather Orchestrator" {
                    description "Implementa Scatter-Gather para ejecutar múltiples motores de fraude en paralelo cuando es necesario escalar a más proveedores"
                    technology "Flink / Orchestration"
                    tags "ScatterGather"
                }

                fraudNormalizer = component "Fraud Normalizer" {
                    description "Implementa Normalizer para unificar las respuestas de distintos motores de fraude en un formato común para tomar una decisión final"
                    technology "Flink / Normalization"
                    tags "Normalizer"
                }
            }

            claimCheckStore = container "Claim Check Store" {
                description "Repositorio seguro donde se almacenan datos sensibles y al que se hace referencia mediante Claim Check desde el pipeline de fraude"
                technology "Encrypted DB / Secure Storage"
                tags "ClaimCheckStore"
            }

            fraudDecisionApi = container "Fraud Decision API" {
                description "API interna que expone el veredicto final de evaluación de fraude para que el core digital pueda tomar una decisión de aprobación, rechazo o challenge"
                technology "REST / gRPC"
                tags "FraudDecisionAPI"
            }
        }

        rulesEngine = softwareSystem "Rules Engine" {
            description "Motor de reglas internas que evalúa condiciones determinísticas de fraude"
            tags "FraudEngine"
        }

        mlEngine = softwareSystem "ML Fraud Scoring Engine" {
            description "Motor de machine learning que calcula un score de fraude basado en modelos entrenados"
            tags "FraudEngine"
        }

        externalFraudProvider = softwareSystem "External Fraud Provider" {
            description "Proveedor externo de servicios de fraude / AML que evalúa listas negras, patrones globales y otros indicadores"
            tags "FraudEngine"
        }

        auditSystem = softwareSystem "Fraud Audit & Compliance System" {
            description "Sistema de auditoría y cumplimiento que registra trazabilidad completa de eventos, ventanas de análisis, reglas aplicadas y decisiones tomadas"
            tags "ExternalSystem"
        }

        customer -> digitalCore "Realiza transacciones y operaciones financieras" "Canales internos" {
            tags "Relationship"
        }

        fraudClient -> eventStream "Publica eventos de transacciones, movimientos y operaciones que pueden requerir evaluación de fraude" "Event Message / Event Stream" {
            tags "EventDriven"
        }

        eventStream -> fraudStreamProcessor "Entrega eventos transaccionales al procesador de streams para detección basada en streaming" "Event Stream Subscription" {
            tags "EventDriven"
        }

        fraudEnrichment -> claimCheckStore "Almacena datos sensibles en el Claim Check Store cuando aplica minimización de datos" "Claim Check Store Access" {
            tags "ClaimCheck"
        }

        fraudEnrichment -> fraudClaimCheck "Genera referencias Claim Check para los eventos que contienen datos sensibles" "Claim Check Reference" {
            tags "ClaimCheck"
        }

        fraudEnrichment -> fraudCorrelation "Envía eventos enriquecidos para aplicar Correlation Identifier por cliente, dispositivo, IP o canal" "Internal Stream Processing" {
            tags "CorrelationIdentifier"
        }

        fraudCorrelation -> fraudRoutingSlip "Envía eventos correlacionados hacia el Routing Slip para determinar el pipeline de validaciones" "Internal Stream Routing" {
            tags "RoutingSlip"
        }

        fraudRoutingSlip -> fraudScatterGather "Configura dinámicamente qué validaciones (motores de fraude) deben ejecutarse para cada transacción" "Routing Slip" {
            tags "RoutingSlip", "ScatterGather"
        }

        fraudScatterGather -> rulesEngine "Envía solicitudes de evaluación al motor de reglas internas usando patrón Scatter-Gather" "Scatter-Gather Request" {
            tags "ScatterGather"
        }

        fraudScatterGather -> mlEngine "Envía solicitudes de evaluación al motor de ML para scoring de fraude" "Scatter-Gather Request" {
            tags "ScatterGather"
        }

        fraudScatterGather -> externalFraudProvider "Envía solicitudes a proveedor externo de fraude / AML si aplica" "Scatter-Gather Request" {
            tags "ScatterGather"
        }

        rulesEngine -> fraudScatterGather "Retorna resultado de evaluación de reglas internas" "Scatter-Gather Response" {
            tags "ScatterGather"
        }

        mlEngine -> fraudScatterGather "Retorna score de fraude calculado por el modelo ML" "Scatter-Gather Response" {
            tags "ScatterGather"
        }

        externalFraudProvider -> fraudScatterGather "Retorna el resultado de evaluación de fraude externo / AML" "Scatter-Gather Response" {
            tags "ScatterGather"
        }

        fraudScatterGather -> fraudNormalizer "Envía todas las respuestas de motores de fraude para unificarlas" "Internal Aggregation" {
            tags "Normalizer"
        }

        fraudNormalizer -> fraudDecisionApi "Envía el veredicto final de fraude en un formato normalizado para consumo interno" "Normalized Fraud Verdict" {
            tags "Relationship"
        }

        fraudDecisionApi -> fraudClient "Entrega el veredicto final de fraude para aprobar, rechazar o desafiar la transacción" "Fraud Decision" {
            tags "Relationship"
        }

        fraudStreamProcessor -> auditSystem "Envía trazabilidad de eventos, ventanas de análisis, reglas aplicadas y decisiones tomadas" "Audit Events / Compliance Logs" {
            tags "EventDriven"
        }

        fraudDecisionApi -> auditSystem "Registra decisiones finales de fraude para auditoría y cumplimiento" "Decision Logs" {
            tags "Relationship"
        }
    }

    views {
        systemContext bankingPlatform {
            include customer
            include bankingPlatform
            include rulesEngine
            include mlEngine
            include externalFraudProvider
            include auditSystem
            autoLayout lr
        }

        container bankingPlatform {
            include customer
            include digitalCore
            include eventStream
            include fraudStreamProcessor
            include claimCheckStore
            include fraudDecisionApi
            include rulesEngine
            include mlEngine
            include externalFraudProvider
            include auditSystem

            autoLayout lr
        }

        component fraudStreamProcessor {
            description "Vista del pipeline de fraude basado en Event Stream, Apache Flink, Enrichment, Claim Check, Correlation Identifier, Routing Slip, Scatter-Gather y Normalizer"

            include fraudStreamProcessor
            include fraudEnrichment
            include fraudClaimCheck
            include fraudCorrelation
            include fraudRoutingSlip
            include fraudScatterGather
            include fraudNormalizer
            include claimCheckStore
            include rulesEngine
            include mlEngine
            include externalFraudProvider
            include fraudDecisionApi
            include eventStream
            include digitalCore
            include fraudClient
            include auditSystem
            include customer

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

            element "EventStream" {
                shape pipe
                background "#495057"
                color "#ffffff"
            }

            element "StreamProcessor" {
                shape RoundedBox
                background "#0b7285"
                color "#ffffff"
            }

            element "Enrichment" {
                shape RoundedBox
                background "#5c940d"
                color "#ffffff"
            }

            element "ClaimCheck" {
                shape RoundedBox
                background "#e8590c"
                color "#ffffff"
            }

            element "ClaimCheckStore" {
                shape Cylinder
                background "#e67700"
                color "#ffffff"
            }

            element "CorrelationIdentifier" {
                shape RoundedBox
                background "#228be6"
                color "#ffffff"
            }

            element "RoutingSlip" {
                shape Hexagon
                background "#f08c00"
                color "#ffffff"
            }

            element "ScatterGather" {
                shape RoundedBox
                background "#862e9c"
                color "#ffffff"
            }

            element "Normalizer" {
                shape RoundedBox
                background "#343a40"
                color "#ffffff"
            }

            element "FraudEngine" {
                shape RoundedBox
                background "#c92a2a"
                color "#ffffff"
            }

            element "FraudDecisionAPI" {
                shape RoundedBox
                background "#12b886"
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

            relationship "EventDriven" {
                color "#37b24d"
                thickness 3
            }

            relationship "Enrichment" {
                color "#5c940d"
                thickness 3
            }

            relationship "ClaimCheck" {
                color "#e8590c"
                thickness 3
            }

            relationship "CorrelationIdentifier" {
                color "#228be6"
                thickness 3
            }

            relationship "RoutingSlip" {
                color "#f08c00"
                thickness 3
            }

            relationship "ScatterGather" {
                color "#862e9c"
                thickness 3
            }

            relationship "Normalizer" {
                color "#343a40"
                thickness 3
            }
        }
    }
}
