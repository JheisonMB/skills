---
name: scaffold-clean-architecture
description: >
  Scaffold and manage Java Spring Boot projects using the Bancolombia Clean Architecture Gradle plugin
  (co.com.bancolombia.cleanArchitecture). Generates projects, models, use cases, driven adapters, and entry points
  following clean architecture patterns. Use this skill whenever the user mentions scaffold, clean architecture,
  Bancolombia plugin, "gradle ca", "gradle gep", "gradle gda", "gradle guc", "gradle gm", generating a reactive
  or imperative Java project structure, adding driven adapters (JPA, MongoDB, R2DBC, Redis, S3, DynamoDB, REST consumer,
  SQS, Kafka, secrets), adding entry points (WebFlux, REST MVC, GraphQL, Kafka, SQS, RSocket, MCP server, A2A agent),
  or generating models and use cases in a clean architecture project. Also activate when the user wants to create
  a new microservice, add infrastructure modules, or asks about project structure with domain/infrastructure layers.
---

# Scaffold Clean Architecture

Guide for scaffolding and managing Java Spring Boot projects with the Bancolombia Clean Architecture Gradle plugin.

## Plugin Setup

Requires Java 17+ and Gradle 9.2.1+. Add to `build.gradle`:

```groovy
plugins {
    id 'co.com.bancolombia.cleanArchitecture' version '4.2.0'
}
```

## Quick Start

```bash
mkdir my-project && cd my-project
echo "plugins { id 'co.com.bancolombia.cleanArchitecture' version '4.2.0' }" > build.gradle
gradle wrapper
./gradlew ca --name=MyProject
./gradlew gep --type webflux
./gradlew bootRun
```

## Core Tasks

All tasks are Gradle tasks. Short aliases are available for each.

### Generate Project (`ca`)

Creates the full clean architecture structure.

```bash
./gradlew ca --name=MyProject --package=co.com.bancolombia --type=reactive --lombok=true
```

| Parameter | Values | Default |
|-----------|--------|---------|
| `--name` | String | `cleanArchitecture` |
| `--package` | String | `co.com.bancolombia` |
| `--type` | `reactive`, `imperative` | `reactive` |
| `--lombok` | `true`, `false` | `true` |
| `--metrics` | `true`, `false` | `true` |
| `--mutation` | `true`, `false` | `true` |
| `--java-version` | `17`, `21`, `25` | `25` |

Generated structure:
```
📦Project
┣ 📂applications/app-service/   (MainApplication, configs, resources)
┣ 📂domain/model/               (domain models)
┣ 📂domain/usecase/             (business logic)
┣ 📂infrastructure/driven-adapters/
┣ 📂infrastructure/entry-points/
┣ 📂infrastructure/helpers/
┗ 📂deployment/
```

### Generate Model (`gm`)

Creates a domain model class + gateway interface.

```bash
./gradlew gm --name=Product
```

Generates: `domain/model/.../model/Product.java` + `domain/model/.../model/gateways/ProductRepository.java`

### Generate Use Case (`guc`)

Creates a use case class in the domain layer.

```bash
./gradlew guc --name=CreateOrder
```

Generates: `domain/usecase/.../usecase/createorder/CreateOrderUseCase.java`

### Generate Driven Adapter (`gda`)

Creates infrastructure adapters. Read `references/driven-adapters.md` for the full catalog of types and parameters.

```bash
./gradlew gda --type=jpa
./gradlew gda --type=mongodb
./gradlew gda --type=r2dbc
./gradlew gda --type=restconsumer --url=https://api.example.com
./gradlew gda --type=redis --mode=template
./gradlew gda --type=s3
./gradlew gda --type=dynamodb
./gradlew gda --type=sqs
./gradlew gda --type=secrets --secrets-backend=aws_secrets_manager
./gradlew gda --type=asynceventbus --tech=kafka
./gradlew gda --type=generic --name=MyAdapter
```

### Generate Entry Point (`gep`)

Creates infrastructure entry points. Read `references/entry-points.md` for the full catalog of types and parameters.

```bash
./gradlew gep --type=webflux
./gradlew gep --type=restmvc --server=tomcat
./gradlew gep --type=graphql
./gradlew gep --type=kafka
./gradlew gep --type=sqs
./gradlew gep --type=rsocket
./gradlew gep --type=mcp
./gradlew gep --type=agent --name=my-agent
./gradlew gep --type=generic --name=MyEntryPoint
```

## Workflow

When the user wants to create a new project or add modules, follow this sequence:

1. Ask what they need (project name, reactive/imperative, which adapters and entry points)
2. If no project exists yet, generate it with `ca`
3. Generate models with `gm` for each domain entity
4. Generate use cases with `guc` for each business operation
5. Generate driven adapters with `gda` for external integrations
6. Generate entry points with `gep` for how the app is exposed
7. Run with `./gradlew bootRun`

Always run commands from the project root where `build.gradle` lives. Use `./gradlew` (not `gradle`) after the wrapper is generated.

## Important Notes

- Running `ca` on an existing project overrides `main.gradle`, `build.gradle`, and `gradle.properties`
- The `--type=reactive` project uses WebFlux (non-blocking), `--type=imperative` uses Spring MVC
- For driven adapters with secrets (JPA, MongoDB, Redis), add `--secret=true` to enable secrets manager integration
- Entry points like `webflux` and `restmvc` support `--authorization`, `--versioning`, `--swagger`, and `--from-swagger` options
