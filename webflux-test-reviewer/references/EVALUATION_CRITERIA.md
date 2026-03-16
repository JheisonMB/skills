# Evaluation Criteria

Detailed guide for evaluating each criterion. For every item: what to look for, what's good, what's bad, and a real example.

---

## 1. Readme

**What to look for:**
- Exists and explains how to run the project (minimum requirement)
- Describes technologies used and basic architecture
- Additional content (Postman collections, diagrams, screenshots) adds value

**What's good:**
- Concise, explains how to build and run, mentions prerequisites
- Includes relevant technical decisions if brief

**What's bad:**
- Missing entirely
- Excessively long, clearly AI-generated (verbose explanations of obvious things, "if you want I can help you with..." type comments)
- Copy of a scaffold readme without customization
- Unmaintainable wall of text

**Examples:**
- ✅ `Si hizo buen readme e incluyo pdf`
- ✅ `Si tiene readme, muy completo y detallando todo lo desarrollado incluso respuestas a decisiones tecnicas`
- ⚠️ `Si hizo el readme con base en el de scaffold`
- ❌ `No, solo hizo un parrafo de readme`

---

## 2. GIT

**What to look for:**
- Multiple commits (not a single commit with everything)
- Commit messages follow a standard (conventional commits, descriptive messages)
- Atomic commits (each commit is a logical unit of work)
- Use of branches and PRs

**What's good:**
- Descriptive commit messages following a naming standard
- Feature branches, PRs, logical progression of work

**What's bad:**
- Single commit with all code
- Generic messages like "update", "fix", "changes"
- No branch strategy

**Examples:**
- ✅ `Si aplico buenas practicas bajo estandar de nombramiento`
- ⚠️ `Si presenta varios commits pero sin un manejo de estandar`
- ❌ `No un unico commit`

---

## 3. Webflux

**What to look for:**
- Actually uses Spring WebFlux (Mono/Flux), not Spring MVC
- Correct use of reactive operators:
  - `flatMap()` for async operations (returns Mono/Flux)
  - `map()` for sync transformations
  - `filter()` + `switchIfEmpty()` instead of imperative `if/else`
  - `Mono.zip()` for parallel independent operations
- No blocking calls: `block()`, `Thread.sleep()`, blocking I/O
- Reactive error handling: `onErrorResume`, `onErrorMap`, `Mono.error()`
- Advanced operators usage: `doOnError`, `doFinally`, `onErrorResume`

**What's good:**
- Pure reactive chains without imperative constructs
- Proper operator selection for each use case
- No blocking calls anywhere in the reactive chain

**What's bad:**
- Using `block()` anywhere
- Mixing imperative and reactive styles
- Using `map()` where `flatMap()` is needed
- Not using WebFlux at all (Spring MVC instead)

**Examples:**
- ✅ `Si uso webflux y se uso de metodos avanzados como doOnError, doFinally, onErrorResume. Hay manejo correcto`
- ✅ `Si uso programación reactiva`
- ❌ `No uso webflux`
- ❌ `No uso webflux por decisión tecnica de ser una solucion de baja concurrencia`

---

## 4. Test Unitarios

**What to look for:**
- Tests exist
- Approximate coverage (check test count, which layers are tested)
- Use of appropriate testing tools (JUnit, Mockito, StepVerifier for reactive)

**What's good:**
- Tests exist with reasonable coverage
- Multiple test scenarios covering happy path and edge cases

**What's bad:**
- No tests at all
- Only trivial tests (testing getters/setters)

**Examples:**
- ✅ `Si con cobertura del 80%`
- ✅ `Si hizo 19 test unitarios`
- ✅ `Si hizo test unitarios con muy buena cobertura y complejidad de escenarios`
- ❌ `No hizo test unitarios`

---

## 5. Arquitectura

**What to look for:**
- Identify the architecture pattern used
- Proper separation of responsibilities
- Use of interfaces to decouple layers (especially controller → use cases)
- Package/module organization

**Architecture hierarchy (best to worst):**

1. **Bancolombia Scaffold (best)** — Uses the `co.com.bancolombia.cleanArchitecture` Gradle plugin. Identifiable by:
   - Plugin `co.com.bancolombia.cleanArchitecture` in `build.gradle`
   - Multi-module Gradle structure with: `domain/model`, `domain/usecase`, `infrastructure/entry-points`, `infrastructure/driven-adapters`, `infrastructure/helpers`, `applications/app-service`
   - Clear separation: domain layer (model + usecase), infrastructure layer (entry-points + driven-adapters + helpers), application layer (assembly + dependency injection)
   - Ports defined as interfaces in the model module, implemented in driven-adapters
   - Reference: https://bancolombia.github.io/scaffold-clean-architecture/

2. **Clean Architecture / Hexagonal** — Proper layer separation with dependency inversion. Domain doesn't depend on infrastructure. Ports and adapters pattern. Interfaces between layers.

3. **Layered Architecture (MVC)** — Traditional controller → service → repository. Fulfills basic separation but layers depend downward without inversion. Acceptable but not ideal.

4. **No clear architecture** — Mixed responsibilities, no pattern, controllers calling repositories directly.

**What's good:**
- Clear architecture with proper layer separation
- Interfaces between layers
- Consistent package structure

**What's bad:**
- No clear architecture pattern
- Controllers calling repositories directly
- Mixed responsibilities in single classes
- Over-atomization of use cases (one use case per trivial operation)

**Examples:**
- ✅ `SI Uso scaffold, al usar scaffold tiene muy buena separación de responsabilidades`
- ✅ `Uso arquitectura hexagonal con buena separación de puertos y adaptadores`
- ⚠️ `Si manejo arquitectura limpia aunque atomizo demasiado los useCase`
- ⚠️ `Usa arquitectura de capas tradicional (MVC), cumple pero sin inversión de dependencias`
- ❌ `No uso clean architecture`

---

## 6. Clean Code

**What to look for:**
- Naming conventions: classes PascalCase, methods/variables camelCase, constants UPPER_SNAKE
- Short methods with single responsibility
- No dead code or commented-out code
- No unused imports
- Self-explanatory code (no excessive comments explaining obvious things)
- Consistent code style throughout

**What's good:**
- Readable, self-documenting code
- Consistent naming and formatting
- Small, focused methods

**What's bad:**
- Classes named in lowercase
- Methods doing too many things
- Excessive comments on obvious code (sign of AI or lack of understanding)
- Dead code, unused imports, commented blocks

**Examples:**
- ✅ `Se ven buenas practicas de codigo limpio`
- ⚠️ `Si pero tiene metodos muy largos`
- ⚠️ `Tiene problemas en el nombramiento de las clases con minusculas`

---

## 7. Manejo de Excepciones

**What to look for:**
- Custom exception classes (not just generic Exception/RuntimeException)
- Global error handler (WebExceptionHandler, @ControllerAdvice, or reactive handler)
- Reactive error operators: `onErrorResume`, `onErrorMap`, `Mono.defer(() -> Mono.error(...))`
- Specific business error scenarios (not found, bad request, conflict, etc.)

**What's good:**
- Custom exceptions + global handler + reactive error operators
- Specific HTTP status codes for different error scenarios
- Error responses with meaningful messages

**What's bad:**
- No error handling (everything returns 500)
- Only try/catch (imperative) in reactive code
- Generic handler without specific scenarios

**Examples:**
- ✅ `Si tiene manejo de errores en el handler con metodos propios de webflux. Se ve muy buen manejo`
- ⚠️ `No hay un buen manejo de errores solo escenarios notfound con un handler general`
- ⚠️ `Si bien controlo escenarios con excepciones personalizadas hay varios puntos con retorno 500`
- ❌ `Manejo de excepciones tradicional`

---

## 8. IaC (Infrastructure as Code)

**What to look for:**
- Exists (Terraform, CloudFormation, Pulumi, etc.)
- Resource pertinence: are the resources created appropriate for the solution?
- Basic structure and organization
- Security considerations (no hardcoded secrets, proper security groups)

**What's good:**
- Well-structured IaC with resources that match the solution needs
- Proper variable usage, no hardcoded values

**What's bad:**
- Missing entirely
- Resources that don't match the solution (over-engineering or under-engineering)
- Security vulnerabilities in resource definitions

**Examples:**
- ✅ `Si uso IaC de muy buen estructura`
- ⚠️ Resources with security vulnerabilities (open security groups, no WAF)
- ❌ `No la hizo`

---

## 9. DockerFile

**What to look for:**
- Multi-stage build: first stage compiles, second stage runs
- Does NOT just copy a pre-built JAR
- Proper base images (slim/alpine variants)
- Non-root user

**What's good:**
- Multi-stage build that compiles the application
- Slim base image, non-root user
- Proper layer caching (.dockerignore, dependency layers first)

**What's bad:**
- Only copies a JAR file without compiling
- JAR committed to the repository
- Running as root
- No .dockerignore

**Examples:**
- ✅ `Si dockerfile muy completo sin usar el usuario root`
- ⚠️ `Si pero basico solo copia y expone no compila`
- ❌ `No tiene un buen docker ya que solo copia el jar y no lo compila. Incluso lo subio al repo`

---

## 10. Docker-compose

**What to look for:**
- Exists and defines services for app + database
- Services can start together

**What's good:**
- Defines app + DB services
- Works as a complete local development environment

**What's bad:**
- Missing entirely
- Only defines DB without the app (or vice versa)

**Examples:**
- ✅ `Si creo para la db en postgres y la app`
- ✅ `Si docker-compose para redis, app y postgres`
- ❌ `No lo presento`

---

## 11. AI Detection (Cross-cutting — report only if found)

Three levels of detection:

### Level 1: Obvious AI Comments
- Comments like "si quieres te puedo dar ideas sobre X tema"
- "Here's an example of how you could..."
- Explanatory comments that read like a tutorial
- TODO comments generated by AI assistants

### Level 2: Style Inconsistencies
- Mixed coding styles within the same project
- Massive unused imports
- Inconsistent naming conventions (some files perfect, others messy)
- Code that doesn't match the readme's described approach

### Level 3: Suspicious Patterns
- Code that is technically perfect but shows no understanding of the business context
- Over-engineered solutions for simple problems
- Perfect error messages that don't match the rest of the code quality
- Documentation that describes features not implemented

**Note:** AI usage is not inherently bad. What matters is whether the candidate understands what was generated. The interview questions should probe this understanding.

---

## 12. Exposed Secrets (Cross-cutting — report only if found)

Not a formal criterion, but report if found:
- Hardcoded passwords, API keys, or tokens in source code
- Credentials in configuration files committed to git
- Database passwords in application.yml/properties without environment variable substitution
- AWS/cloud credentials in IaC files
