# Design Patterns Reference

Full catalog of GoF design patterns with use cases and selection guides. Consult this when the decision tree in SKILL.md points you to a specific pattern.

---

## Creational Patterns

### Singleton
- **Problem:** Need exactly one instance (config, logger, connection pool)
- **Use when:** Resource must be shared globally and instantiation is controlled
- **Avoid when:** DI container is available (prefer DI), or in testing-heavy codebases

### Factory Method
- **Problem:** Create objects without specifying exact class until runtime
- **Use when:** Multiple implementations of same interface, chosen by parameter/context
- **Avoid when:** Few variations — a simple constructor is enough
- **Examples:** Payment processors, notification services, parsers

### Abstract Factory
- **Problem:** Create families of related objects that must be compatible
- **Use when:** UI themes, DB drivers, platform-specific components
- **Avoid when:** Products are independent and don't need to be compatible

### Builder
- **Problem:** Complex object with many optional parameters
- **Use when:** Emails, configs, immutable objects, SQL queries
- **Avoid when:** Object has few required fields — use constructor

### Prototype
- **Problem:** Creating objects from scratch is expensive, cloning is cheaper
- **Use when:** Game configs, document templates, complex object graphs
- **Avoid when:** Objects are simple to construct

---

## Structural Patterns

### Adapter
- **Problem:** Two incompatible interfaces need to work together
- **Use when:** Integrating legacy APIs, third-party libraries, external systems
- **Avoid when:** Interfaces are already compatible

### Bridge
- **Problem:** Abstraction and implementation should vary independently
- **Use when:** DB drivers, cross-platform systems, rendering engines
- **Avoid when:** Single implementation — abstraction adds no value

### Composite
- **Problem:** Treat individual objects and groups uniformly
- **Use when:** File trees, menus, org charts, UI component hierarchies
- **Avoid when:** Structure is flat, no nesting needed

### Decorator
- **Problem:** Add behavior dynamically without subclassing
- **Use when:** Middleware, validators, loggers, processing filters
- **Avoid when:** Behavior is static and known at compile time

### Facade
- **Problem:** Complex subsystem needs a simple entry point
- **Use when:** Unified APIs, high-level service wrappers
- **Avoid when:** System is already simple

### Flyweight
- **Problem:** Many similar objects consuming too much memory
- **Use when:** Text editors (characters), games (particles), rendering
- **Avoid when:** Few objects — optimization isn't needed

### Proxy
- **Problem:** Need to control access to an object
- **Use when:** Lazy loading, caching, security checks, logging
- **Avoid when:** Direct access is sufficient and safe

---

## Behavioral Patterns

### Observer
- **Problem:** Multiple objects need to react to state changes
- **Use when:** Domain events, notifications, reactive UI, pub/sub
- **Avoid when:** Direct communication between two objects is enough

### Strategy
- **Problem:** Need to swap algorithms dynamically based on context
- **Use when:** Pricing rules, shipping calculators, payment processing, sorting
- **Avoid when:** Only one algorithm exists

### Command
- **Problem:** Encapsulate operations as objects for queuing, undo, or logging
- **Use when:** Undo/redo, task queues, operation logging, macros
- **Avoid when:** Operations are simple and don't need to be stored

### State
- **Problem:** Object behavior changes based on internal state
- **Use when:** State machines, workflows, connection states, order lifecycle
- **Avoid when:** States are simple (a boolean or enum with if/switch suffices)

### Template Method
- **Problem:** Algorithm skeleton is fixed but some steps vary
- **Use when:** Frameworks, processing pipelines, ETL with variable steps
- **Avoid when:** Algorithms are completely different (use Strategy instead)

### Chain of Responsibility
- **Problem:** Request should be handled by one of several possible handlers
- **Use when:** Middleware, validation chains, authorization, filters
- **Avoid when:** Single handler — just call it directly

### Mediator
- **Problem:** Many objects communicate in chaotic ways
- **Use when:** UI components, chat systems, workflow coordination
- **Avoid when:** Communication is simple and between few objects

### Memento
- **Problem:** Need to capture and restore object state without breaking encapsulation
- **Use when:** Undo/redo, snapshots, checkpoints, state versioning
- **Avoid when:** State is trivial to reconstruct

### Iterator
- **Problem:** Traverse a collection without exposing its internal structure
- **Use when:** Custom collections, pagination, data navigation
- **Avoid when:** Language already provides iteration (for-each, streams)

### Visitor
- **Problem:** Add operations to a class hierarchy without modifying it
- **Use when:** AST processing, reporting, transformations, compilers
- **Avoid when:** Hierarchy is stable and operations rarely change

### Interpreter
- **Problem:** Need to evaluate expressions in a specific grammar
- **Use when:** Parsers, calculators, business rule engines, DSLs
- **Avoid when:** Logic is simple enough for conditionals

---

## Quick Selection Guide

| Need | Pattern |
|------|---------|
| One global instance | Singleton (prefer DI) |
| Create by type/param | Factory Method |
| Compatible object families | Abstract Factory |
| Many optional params | Builder |
| Expensive cloning | Prototype |
| Incompatible interfaces | Adapter |
| Abstraction ≠ implementation | Bridge |
| Tree structures | Composite |
| Dynamic behavior wrapping | Decorator |
| Simplify complex API | Facade |
| Memory optimization | Flyweight |
| Controlled access | Proxy |
| Event notifications | Observer |
| Swappable algorithms | Strategy |
| Undo/queue operations | Command |
| State-dependent behavior | State |
| Fixed algorithm, variable steps | Template Method |
| Handler chain | Chain of Responsibility |
| Centralized communication | Mediator |
| State snapshots | Memento |
| Collection traversal | Iterator |
| Operations on hierarchy | Visitor |
| Expression parsing | Interpreter |
