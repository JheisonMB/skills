# WebFlux Reactive Patterns - Agent Skill

An Agent Skill for Spring WebFlux reactive programming best practices and patterns.

## Overview

This skill provides expert guidance for writing idiomatic, production-ready reactive code with Spring WebFlux in Java. It enforces pure reactive programming patterns and eliminates common anti-patterns that break reactive streams.

## Installation

### For skills.sh compatible agents (Kiro CLI, Cline, Cursor, etc.)

```bash
npx skills add <your-github-username>/webflux-reactive-patterns
```

### Manual installation

1. Clone or download this repository
2. Copy the `webflux-reactive-patterns` directory to your agent's skills directory
3. The skill will be automatically discovered by compatible agents

## What's Included

- **SKILL.md** - Main skill file with overview and quick reference
- **references/BEFORE_CODING.md** - Pre-implementation analysis workflow
- **references/REACTIVE_PATTERNS.md** - Comprehensive reactive patterns and anti-patterns
- **references/BEST_PRACTICES.md** - Code style and organizational best practices
- **references/TROUBLESHOOTING.md** - Common issues, debugging techniques, and solutions
- **assets/reactive-service-example.java** - Working example demonstrating key patterns

## Key Features

- ✅ Pure reactive flow patterns (no imperative constructs)
- ✅ Lazy error handling with `Mono.defer()`
- ✅ Proper use of `Optional`, `filter()`, `switchIfEmpty()`
- ✅ Parallel operations with `Mono.zip()`
- ✅ Helper method extraction guidelines
- ✅ Code organization and style conventions
- ✅ Pre-implementation analysis workflow
- ✅ Troubleshooting guide for common reactive issues
- ✅ Timeout and retry patterns
- ✅ Error recovery strategies

## When to Use

This skill activates when:
- Developing or refactoring Spring WebFlux applications
- Working with Mono and Flux reactive types
- Implementing reactive REST APIs or microservices
- Converting imperative code to reactive patterns
- Reviewing reactive code for anti-patterns
- Debugging reactive issues (streams not executing, blocking calls, memory leaks)
- Implementing timeout and retry logic
- Optimizing reactive performance

## Skill Structure

Following the [Agent Skills specification](https://agentskills.io/specification):

```
webflux-reactive-patterns/
├── SKILL.md                              # Main skill file
├── references/
│   ├── BEFORE_CODING.md                  # Analysis workflow
│   ├── REACTIVE_PATTERNS.md              # Reactive patterns guide
│   ├── BEST_PRACTICES.md                 # Code style guide
│   └── TROUBLESHOOTING.md                # Debugging and common issues
├── assets/
│   └── reactive-service-example.java     # Working example
└── README.md                             # This file
```

## Core Principles

1. **Analysis Before Implementation** - Plan before coding
2. **Pure Reactive Flow** - No imperative constructs
3. **No Literals** - Use constants and enums
4. **Helper Methods** - Single responsibility extraction
5. **Parallel Operations** - Use `Mono.zip()` when possible
6. **Clean Imports** - Organized and short names

## Quick Example

```java
// ✅ Correct reactive pattern
return Optional.ofNullable(data)
    .filter(d -> !d.isEmpty())
    .map(Mono::just)
    .orElse(Mono.defer(() -> Mono.error(BusinessType.EMPTY_DATA.build())));

// ✅ Parallel operations
return Mono.zip(
    validateField1(data),
    validateField2(data),
    validateField3(data)
).thenReturn(data);
```


## Using This Skill

This skill is automatically activated when you mention reactive programming concepts in English or Spanish. For best results:

- Use clear descriptions of your reactive programming problem
- Include code snippets showing Mono/Flux usage
- Mention specific operators or issues (flatMap, block(), error handling)

For common issues and solutions, refer to the [Troubleshooting Guide](references/TROUBLESHOOTING.md).

### Contributing Improvements

To extend this skill with additional patterns:
1. Maintain the workflow-based organization
2. Keep examples minimal and focused
3. Follow the Agent Skills specification
4. Test with multiple compatible agents
## License

MIT License - See LICENSE file for details

## Metadata

- **Version:** 1.1
- **Framework:** Spring WebFlux
- **Language:** Java
- **Category:** Reactive Programming
- **Author:** jheison.martinez
- **Last Updated:** 2026-03-12

## Validation

Validate this skill using the skills-ref library:

```bash
npx skills-ref validate ./webflux-reactive-patterns
```

## Resources

- [Agent Skills Specification](https://agentskills.io/specification)
- [Skills.sh Ecosystem](https://skills.sh/)
- [Spring WebFlux Documentation](https://docs.spring.io/spring-framework/reference/web/webflux.html)
- [Project Reactor Documentation](https://projectreactor.io/docs)

## Support

For issues or questions about this skill, please open an issue in the repository.

---

**Note:** This skill fills a gap in the skills.sh ecosystem where WebFlux-specific skills are currently limited. It's designed to work with any Agent Skills-compatible AI coding assistant.
