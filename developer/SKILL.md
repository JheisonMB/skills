---
name: developer
description: >
  Production-grade coding — design principles, pattern selection, clean code.
  Use when writing, refactoring, reviewing, or designing code in any language.
license: MIT
metadata:
  author: jheison.martinez
  version: "1.0"
  category: agent-behavior
  last_updated: "2026-04-06"
---

# Developer: Production-Grade Coding

Write code as if it ships to production today. Every function, class, and module should be clean, intentional, and maintainable.

This skill complements [mindful-precision](../mindful-precision) — mindful handles agent behavior (verify, think, security, resourcefulness), developer handles code quality and design decisions.

---

## Before Writing Any Code

Resolve all uncertainty first. Don't start coding until you can answer:

1. **What exactly** does the user need? (not what you assume)
2. **What exists already?** Read the codebase — don't duplicate or contradict existing patterns
3. **What's the scope?** Only build what's needed now (YAGNI)
4. **What could go wrong?** Identify edge cases and failure modes upfront

If anything is unclear, ask. One question now saves a rewrite later.

### Respect Existing Patterns

Before writing new code, scan the codebase for established conventions:
- Naming conventions, project structure, error handling style
- Logging patterns, dependency injection approach, test structure
- Existing abstractions — if there's already a `BaseRepository` or a `HttpClient` wrapper, use it

New code should look like it was written by the same team. Consistency beats personal preference.

**When existing code violates principles:** don't silently follow the anti-pattern and don't silently break convention. Notify the user, leave a `TODO` comment explaining the issue, and ask: "Should we prioritize refactoring this or continue with the existing convention?"

**When existing code uses a clear anti-pattern** (God classes, no DI, everything static): ask the user how to proceed before writing code that follows or breaks the pattern.

---

## Design Principles

Ordered by priority. When principles conflict, higher priority wins.

| Priority | Principle | Core Rule |
|----------|-----------|-----------|
| 1 | **SoC** | Separate concerns into layers — presentation, business, data |
| 2 | **DRY** | One source of truth — but don't over-abstract things that look similar but change for different reasons |
| 3 | **YAGNI** | Build only what's needed now — no "future flexibility" abstractions |
| 4 | **KISS** | Simplest solution that works — over-engineering is a bug |
| 5 | **Fail Fast** | Validate at the boundary, reject invalid state immediately |
| 6 | **SOLID** | SRP, OCP, LSP, ISP, DIP — the structural backbone |
| 7 | **Law of Demeter** | Don't reach through objects — expose what's needed at each level |

### Composition over Inheritance
Prefer composing behaviors via interfaces/traits over deep inheritance hierarchies. Inheritance creates rigid coupling — composition stays flexible.

### SOLID Breakdown

- **SRP** — One reason to change per class/function. If a function validates, saves, and sends email — that's three functions.
- **OCP** — Extend, don't modify. Use interfaces and strategy patterns so existing code stays untouched.
- **LSP** — Subtypes must be substitutable. If a subclass throws exceptions the parent doesn't, the hierarchy is wrong.
- **ISP** — Small, focused interfaces. No class should implement methods it doesn't use.
- **DIP** — Depend on abstractions. Inject interfaces, not concrete classes.

---

## Naming

Use explicit, readable names. No acronyms, no abbreviations, no single letters (except loop counters).

- Names must reveal intent: `calculateShippingCost` > `calc`, `userRepository` > `repo`, `isPaymentExpired` > `check`
- Avoid meaningless names: no `data`, `temp`, `result`, `info`, `handle`, `process`, `manager` unless genuinely descriptive
- Follow the recommended style guide for the language being used (PEP 8 for Python, Effective Go conventions, Rust API guidelines, Google Java Style, etc.)
- When in doubt, longer and clear beats short and cryptic

---

## Fail Fast & Guard Clauses

Validate with negative conditions first. Instead of nesting "if valid, then do X", invert it: "if invalid, return error". This reduces conditional nesting and makes the happy path obvious.

```
// ❌ Nested conditionals
function process(order) {
  if (order != null) {
    if (order.items.length > 0) {
      if (order.payment != null) {
        // actual logic buried 3 levels deep
      }
    }
  }
}

// ✅ Guard clauses — fail fast
function process(order) {
  if (order == null) return error("order is null")
  if (order.items.length == 0) return error("no items")
  if (order.payment == null) return error("no payment")
  // happy path at top level
}
```

---

## Code Size Limits

- **Method > 30 lines** → candidate for refactoring. Extract helper methods.
- **> 3 levels of conditional nesting** → extract into helper methods or use guard clauses.
- **> 3 levels of reactive chain nesting** (flatMap inside flatMap inside flatMap) → extract into named methods.

These are heuristics, not hard rules — but when exceeded, the burden of proof is on keeping the code as-is.

---

## Formatting

If the project has a formatter available, use it always before presenting code:
- `cargo fmt`, `go fmt`, `terraform fmt`, `black`, `prettier`, `ktlint`, or whatever the project uses
- Don't manually format what a tool can handle — let the formatter own style consistency

---

## Error Handling

- Use guard clauses at boundaries (see Fail Fast section)
- Prefer explicit error types when the language supports them (`Result` in Rust, `Either` in functional Java/Kotlin, `error` in Go)
- Use exceptions when they're idiomatic for the language (Python, Java legacy, C#)
- Always handle errors explicitly — no empty catch blocks, no swallowed errors
- Log errors with enough context to debug without reproducing

---

## Testing

Don't write tests until the functionality is working. This avoids rework during iterative development.

Once the feature is stable:
1. Write unit tests covering the core logic
2. Cover edge cases and error paths
3. Tests should be independent, repeatable, and fast

---

## Commits

Use [Conventional Commits](https://www.conventionalcommits.org/). One commit per logical change — don't accumulate multiple features.

- Single phrase in English: `feat: add shipping cost calculation`
- Only add body/footer for breaking changes: `feat!: change payment API response format`
- Atomic commits — each commit should compile and pass tests independently

---

## Design Pattern Decision Tree

Before reaching for a pattern, ask: does the simplest approach work? Patterns solve specific structural problems — don't use them for decoration.

Read `references/design-patterns.md` for the full catalog with use cases and selection guides.

### Object Creation Problems

```
Need to create objects?
├─ One global instance needed? → Singleton (but prefer DI if available)
├─ Multiple implementations of same interface? → Factory Method
├─ Families of related objects? → Abstract Factory
├─ Complex object with many optional params? → Builder
└─ Cloning existing objects is cheaper? → Prototype
```

### Structure Problems

```
Need to organize/compose objects?
├─ Incompatible interfaces? → Adapter
├─ Abstraction and implementation vary independently? → Bridge
├─ Tree/hierarchy treated uniformly? → Composite
├─ Add behavior dynamically without subclassing? → Decorator
├─ Simplify a complex subsystem? → Facade
├─ Many similar objects eating memory? → Flyweight
└─ Control access (lazy load, cache, auth)? → Proxy
```

### Behavior Problems

```
Need to manage communication/algorithms?
├─ Notify multiple objects of state changes? → Observer
├─ Swap algorithms at runtime? → Strategy
├─ Encapsulate operations (undo, queue)? → Command
├─ Behavior changes with internal state? → State
├─ Algorithm skeleton with variable steps? → Template Method
├─ Pass request through handler chain? → Chain of Responsibility
├─ Reduce chaotic object-to-object communication? → Mediator
├─ Capture/restore state (undo/redo)? → Memento
├─ Traverse collection without exposing internals? → Iterator
├─ Add operations to hierarchy without modifying it? → Visitor
└─ Interpret expressions or DSL? → Interpreter
```

### When NOT to use a pattern
- The problem is simple and a function/conditional solves it
- There's only one implementation (don't abstract for one case)
- The pattern adds more code than the problem warrants
- You're using it because it "feels right" rather than solving a concrete problem

---

## Code Quality Checklist

Before presenting any code change, verify:

- [ ] Each function does one thing and is ≤ 30 lines
- [ ] No nesting deeper than 3 levels (conditionals or reactive chains)
- [ ] Names are explicit and readable — no acronyms or abbreviations
- [ ] Guard clauses used instead of nested conditionals
- [ ] No duplicated logic
- [ ] Error cases handled explicitly with appropriate error types
- [ ] No hardcoded values that should be configurable
- [ ] Dependencies injected, not instantiated internally
- [ ] Public API is minimal — expose only what's necessary
- [ ] Formatter applied (if available for the language)
- [ ] Follows existing codebase conventions

---

## How to Apply This

1. **Understand first** — read existing code, understand the domain, clarify requirements
2. **Design before typing** — think about structure, responsibilities, and boundaries
3. **Write clean from the start** — don't plan to "clean up later"
4. **Evaluate your own output** — before presenting code, run the checklist above
5. **Choose patterns by need** — use the decision tree when you hit a structural problem, not before
6. **Flag tech debt** — if you see violations, notify the user and leave a TODO
