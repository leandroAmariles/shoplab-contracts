# Especificaciones OpenAPI (`openapi/`)

Este directorio contiene las especificaciones OpenAPI 3.1.0 autoritativas de las APIs HTTP de **ShopLab Helpdesk** (LAB-106, ADR-0015, ADR-0031).

## Contratos publicados

| Servicio | Archivo | Estado |
|---|---|---|
| `common` | `openapi/common/v1/common-api.yaml` | Activo (semilla + `ApiErrorResponse`) |
| `chat` | `openapi/chat/v1/chat-api.yaml` | Activo |
| `retrieval` | `openapi/retrieval/v1/retrieval-api.yaml` | Activo |
| `eval` | `openapi/eval/v1/eval-api.yaml` | Activo |

## Regla de nacimiento para servicios futuros (`catalog`, `orders`, `tickets`)

Los servicios transaccionales `catalog`, `orders` y `tickets` nacen directamente como microservicios independientes en F3 y F4 (`ADR-0031`, LAB-128). Antes de exponer su primer endpoint HTTP, cada servicio **DEBE** registrar su contrato siguiendo exactamente esta convención:

- `openapi/catalog/v1/catalog-api.yaml`
- `openapi/orders/v1/orders-api.yaml`
- `openapi/tickets/v1/tickets-api.yaml`

Todos los servicios comparten el esquema estándar de error `ApiErrorResponse` (`code`, `message`, `detail` opcional) y se validan en cada PR mediante `oasdiff` (`scripts/check-openapi-compatibility.sh`).
