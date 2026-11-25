# ShopLab Contracts (`shoplab-contracts`)

Única fuente de verdad para los contratos síncronos (OpenAPI) y asíncronos (Avro y AsyncAPI) entre los microservicios y clientes del ecosistema **ShopLab Helpdesk**.

Este repositorio de soporte (ADR-0015, LAB-128, LAB-108) gobierna la evolución de las interfaces, garantiza la compatibilidad hacia atrás mediante validaciones automáticas en CI (`oasdiff` y Schema Registry `BACKWARD`) y publica paquetes versionados inmutables para:
- **Backend Java (Maven)**: `com.shoplab:shoplab-contracts` en GitHub Packages.
- **Frontend Angular (npm)**: `@leandroamariles/shoplab-contracts` en GitHub Packages.
- **Servicios Python (`uv`)**: Instalable por Git tag inmutable `@vX.Y.Z`.

---

## Estructura del Repositorio

```text
shoplab-contracts/
├── .github/
│   ├── workflows/
│   │   ├── ci.yml                 # Validaciones sintácticas, oasdiff, avro test, dry-run
│   │   ├── pr-title.yml           # Verificación Conventional Commits
│   │   ├── release-please.yml     # Orquestación de Semantic Versioning
│   │   └── publish.yml            # Publicación Maven, npm y confirmación tag Python
│   └── dependabot.yml             # Mantenimiento de GitHub Actions y generadores
├── openapi/
│   ├── README.md                  # Índice de contratos y regla al nacer (catalog, orders, tickets)
│   ├── common/
│   │   └── v1/
│   │       └── common-api.yaml    # Contrato semilla base (Health, Ping, ErrorDto, ApiErrorResponse)
│   ├── chat/
│   │   └── v1/
│   │       └── chat-api.yaml      # API de chat SSE, feedback y GET /api/assistant/settings
│   ├── retrieval/
│   │   └── v1/
│   │       └── retrieval-api.yaml # API de documentos y búsqueda semántica
│   └── eval/
│       └── v1/
│           └── eval-api.yaml      # API de corridas de evaluación, settings e historial
├── avro/
│   └── .gitkeep                   # Vacío de esquemas reales hasta LAB-50
├── asyncapi/
│   └── .gitkeep                   # Vacío de especificaciones hasta LAB-50
├── generators/
│   ├── java/pom.xml               # Generador Java DTOs con openapi-generator-maven-plugin
│   ├── npm/package.json           # Generador cliente Angular con typescript-angular
│   └── python/pyproject.toml      # Configuración del paquete Python para uv
├── scripts/
│   ├── check-openapi-compatibility.sh # Validador oasdiff
│   ├── check-avro-compatibility.sh    # Validador Avro BACKWARD
│   └── verify-contracts-purity.sh     # Verificación de ausencia de código de negocio
├── release-please-config.json
├── .release-please-manifest.json
└── LICENSE
```

---

## Cómo Proponer un Cambio

1. Crear una rama `feature/LAB-<n>-descripcion`.
2. Modificar o añadir especificaciones bajo `openapi/` (o `avro/`/`asyncapi/` a partir de `LAB-50`).
3. Comprobar localmente que la generación compila y que no se introducen rupturas incompatibles:
   ```bash
   ./scripts/check-openapi-compatibility.sh
   cd generators/java && mvn clean compile && cd ../..
   cd generators/npm && npm run build && cd ../..
   cd generators/python && uv build && cd ../..
   ```
4. Abrir Pull Request con título Conventional Commits:
   - Para cambios compatibles (aditivos): `feat(tickets): [LAB-xxx] add priority field`.
   - Para cambios incompatibles (breaking): `feat(tickets)!: [LAB-xxx] remove legacy status`. Todo cambio incompatible **exige** incremento de versión mayor.

---

## Cliente HTTP Java de la búsqueda

El JAR incluye la interfaz `com.shoplab.contracts.retrieval.client.KnowledgeSearchApi` (`@HttpExchange`, reactiva),
generada del OpenAPI de `retrieval` (LAB-129), disponible desde la versión 1.3.0. No trae cliente HTTP ni Jackson propios: el consumidor pone
`spring-web` y la monta sobre su `WebClient`:

```java
var factory = HttpServiceProxyFactory.builderFor(WebClientAdapter.create(webClient)).build();
KnowledgeSearchApi search = factory.createClient(KnowledgeSearchApi.class);
```

---

## Documentación y Guía Operativa

Para consultar el flujo de publicación detallado y la política de orden de despliegue entre productor y consumidores (estrategia expand-and-contract), consulta la documentación oficial en:
- [Guía de Publicación y Orden de Despliegue de Contratos](https://github.com/leandroAmariles/shoplab-helpdesk/blob/main/docs/architecture/contracts-publishing-and-deployment-order.md)
