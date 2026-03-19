# Entry Points Reference

Full catalog of `generateEntryPoint | gep` types.

## Types

| Type | Name | Parameters |
|------|------|-----------|
| `generic` | Empty Entry Point | `--name` (required) |
| `asynceventhandler` | Async Event Handler | `--eda` (true/false, default: false), `--tech` (rabbitmq/kafka/rabbitmq,kafka, default: rabbitmq) |
| `graphql` | API GraphQL | `--pathgql` (String, default: /graphql) |
| `kafka` | Kafka Consumer | - |
| `mcp` | MCP Server | `--name`, `--enable-tools` (true/false), `--enable-resources` (true/false), `--enable-prompts` (true/false), `--enable-security` (true/false), `--enable-audit` (true/false) — all default true |
| `mq` | JMS MQ Client (listen) | - |
| `restmvc` | API REST (Spring MVC) | `--server` (tomcat/jetty, default: tomcat), `--authorization` (true/false), `--versioning` (HEADER/PATH/NONE), `--from-swagger` (file path), `--swagger` (true/false) |
| `rsocket` | RSocket Controller | - |
| `sqs` | SQS Listener | - |
| `webflux` | API REST (WebFlux) | `--router` (true/false, default: true), `--authorization` (true/false), `--versioning` (HEADER/PATH/NONE), `--from-swagger` (file path), `--swagger` (true/false) |
| `kafkastrimzi` | Kafka Strimzi Consumer | `--name`, `--topic-consumer` (default: test-with-registries) |
| `agent` | Spring AI A2A Agent | `--name` (default: project name), `--agent-enable-kafka` (true/false, default: true), `--agent-enable-mcp-client` (true/false, default: true) |

## MCP Server Details

Generates a reactive MCP server with Tools, Resources, and Prompts based on Spring AI.

Generated structure:
```
infrastructure/entry-points/mcp-server/
├── src/main/java/[package]/mcp/
│   ├── tools/          (HealthTool.java, ExampleTool.java)
│   ├── resources/      (SystemInfoResource.java, UserInfoResource.java)
│   ├── prompts/        (ExamplePrompt.java)
│   └── audit/          (McpAuditAspect.java — if audit enabled)
└── build.gradle
```

Security: OAuth2/Entra ID with JWT validation (enabled by default).
Audit: AOP aspect logging who/what/when/result/performance for all MCP operations.

### Component Examples

Tool:
```java
@Component
public class CalculatorTool {
    @McpTool(name = "multiply", description = "Multiplies two numbers")
    public Mono<Integer> multiply(
            @McpToolParam(description = "First number", required = true) int a,
            @McpToolParam(description = "Second number", required = true) int b) {
        return Mono.just(a * b);
    }
}
```

Resource:
```java
@Component
public class ConfigResource {
    @McpResource(uri = "resource://config/app", name = "app-config", description = "App config")
    public Mono<ReadResourceResult> getConfig() {
        return Mono.fromCallable(() -> { /* impl */ });
    }
}
```

Prompt:
```java
@Component
public class SupportPrompt {
    @McpPrompt(name = "customer-support", description = "Customer support prompt")
    public Mono<GetPromptResult> customerSupport(
            @McpArg(name = "issue", required = true) String issue) {
        return Mono.fromCallable(() -> { /* impl */ });
    }
}
```

## A2A Agent Details

Generates a full reactive Agent-to-Agent skeleton with Spring AI and WebFlux.

Endpoints: `POST /message:send` and `GET /.well-known/agent-card.json`

With `--agent-enable-mcp-client=true`: adds `mcp-client` driven adapter.
With `--agent-enable-mcp-client=false`: adds `spring-ai-adapter` driven adapter.

Generated domain models: SendMessageRequest, SendMessageResponse, Message, Task, Error, AgentCard, ChatGateway, AgentResponseGateway.

Generated structure includes reactive-web entry point, optional Kafka consumer/producer, and the selected chat adapter.
