# Reactive Patterns - Pure Reactive Flow

This document provides comprehensive guidance on writing pure reactive code with Spring WebFlux, eliminating imperative patterns and anti-patterns.

## Core Principle: Pure Reactive Flow

Reactive programming is declarative, not imperative. Every operation must be expressed as a transformation of the reactive stream, not as procedural logic.

## Anti-Pattern #1: Imperative Conditionals

### ❌ Wrong: Using `if` statements

```java
return repository.findById(id)
    .flatMap(data -> {
        if (data.isValid()) {
            return process(data);
        } else {
            return Mono.error(new ValidationException());
        }
    });
```

### ✅ Correct: Using reactive operators

```java
return repository.findById(id)
    .filter(Data::isValid)
    .switchIfEmpty(Mono.defer(() -> 
        Mono.error(BusinessType.INVALID_DATA.build())))
    .flatMap(this::process);
```

**Why:** `filter()` + `switchIfEmpty()` maintains reactive semantics and allows proper operator chaining.

## Anti-Pattern #2: Eager Error Creation

### ❌ Wrong: Direct error instantiation

```java
return Optional.ofNullable(data)
    .map(Mono::just)
    .orElse(Mono.error(BusinessType.NULL_DATA.build()));  // Eager evaluation
```

### ✅ Correct: Lazy error with `Mono.defer()`

```java
return Optional.ofNullable(data)
    .map(Mono::just)
    .orElse(Mono.defer(() -> Mono.error(BusinessType.NULL_DATA.build())));
```

**Why:** `Mono.defer()` ensures the error is only created when subscribed, maintaining fail-fast behavior and proper backpressure.

**Mandatory pattern for all errors:**
```java
Mono.defer(() -> Mono.error(exception))
```

## Anti-Pattern #3: Using `throw` in Reactive Chains

### ❌ Wrong: Throwing exceptions

```java
return repository.findById(id)
    .map(data -> {
        if (!data.isValid()) {
            throw new ValidationException();  // Breaks reactive chain
        }
        return data;
    });
```

### ✅ Correct: Returning `Mono.error()`

```java
return repository.findById(id)
    .flatMap(data -> data.isValid() 
        ? Mono.just(data)
        : Mono.defer(() -> Mono.error(BusinessType.INVALID_DATA.build())));
```

**Even better with helper method:**
```java
return repository.findById(id)
    .flatMap(this::validateData);

private Mono<Data> validateData(Data data) {
    return data.isValid()
        ? Mono.just(data)
        : Mono.defer(() -> Mono.error(BusinessType.INVALID_DATA.build()));
}
```

## Anti-Pattern #4: Breaking Fail-Fast with `.then(Mono.just())`

### ❌ Wrong: Using `.then(Mono.just(x))` mid-flow

```java
return validateData(data)
    .then(Mono.just(data))  // ❌ Loses validation error
    .flatMap(repository::save);
```

**Problem:** If `validateData()` returns an error, `.then()` ignores it and proceeds with `Mono.just(data)`.

### ✅ Correct: Proper flow structure

```java
return validateData(data)
    .flatMap(validData -> repository.save(validData));
```

**Or if validation returns Mono<Void>:**
```java
return validateData(data)
    .thenReturn(data)  // Preserves upstream errors
    .flatMap(repository::save);
```

## Anti-Pattern #5: Nested Reactive Operations

### ❌ Wrong: Nested flatMap chains

```java
return repository.findById(id)
    .flatMap(data -> 
        validator.validate(data)
            .flatMap(valid -> 
                enricher.enrich(data)
                    .flatMap(enriched -> 
                        repository.save(enriched))));
```

### ✅ Correct: Linear chain with helper methods

```java
return repository.findById(id)
    .flatMap(this::validateAndEnrich)
    .flatMap(repository::save);

private Mono<Data> validateAndEnrich(Data data) {
    return validator.validate(data)
        .then(enricher.enrich(data));
}
```

**Rule:** Never nest more than 2 levels. Extract to helper methods.

## Anti-Pattern #6: Returning `Mono<Void>` Mid-Flow

### ❌ Wrong: Void in the middle

```java
private Mono<Void> processData(Data data) {  // ❌ Loses data
    return repository.save(data).then();
}

public Mono<Response> handle(Request req) {
    return buildData(req)
        .flatMap(this::processData)  // Returns Mono<Void>
        .map(this::buildResponse);   // ❌ Nothing to map
}
```

### ✅ Correct: Return data through the chain

```java
private Mono<Data> processData(Data data) {
    return repository.save(data);  // Returns Mono<Data>
}

public Mono<Response> handle(Request req) {
    return buildData(req)
        .flatMap(this::processData)
        .map(this::buildResponse);
}
```

**Rule:** Only use `Mono<Void>` as the final return type of the main method, never in intermediate steps.

## Pattern: Optional for Null Checks

### Use Optional for entry-point validation

```java
return Optional.ofNullable(input)
    .filter(i -> !i.isEmpty())
    .map(Mono::just)
    .orElse(Mono.defer(() -> Mono.error(BusinessType.EMPTY_INPUT.build())));
```

**When to use:**
- Validating method parameters
- Checking nullable fields before processing
- Entry-point guards

**Structure:**
1. `Optional.ofNullable()` - Handle null
2. `.filter()` - Additional validation
3. `.map(Mono::just)` - Wrap in Mono
4. `.orElse(Mono.defer(...))` - Lazy error

## Pattern: Repository with Fallback

### Standard pattern for entity lookup

```java
return repository.findById(id)
    .switchIfEmpty(Mono.defer(() -> 
        Mono.error(BusinessType.NOT_FOUND.build(id))));
```

**Variations:**

**With default value:**
```java
return repository.findById(id)
    .switchIfEmpty(Mono.just(defaultEntity));
```

**With alternative lookup:**
```java
return repository.findById(id)
    .switchIfEmpty(repository.findByAlternateKey(key));
```

## Pattern: Parallel Operations

### Use `Mono.zip()` for independent parallel operations

```java
return Mono.zip(
    validateField1(data),
    validateField2(data),
    validateField3(data)
).thenReturn(data);
```

**When to use:**
- Independent validations
- Multiple repository lookups
- Parallel external service calls

**Benefits:**
- Executes in parallel (not sequential)
- Fails fast on first error
- Combines results when all succeed

### Combining results from parallel operations

```java
return Mono.zip(
    fetchUser(userId),
    fetchAccount(accountId),
    fetchSettings(userId)
).map(tuple -> buildResponse(
    tuple.getT1(),  // User
    tuple.getT2(),  // Account
    tuple.getT3()   // Settings
));
```

### Use `Flux.merge()` for parallel Flux operations

```java
return Flux.merge(
    processTypeA(data),
    processTypeB(data),
    processTypeC(data)
).collectList();
```

**Difference from zip:**
- `merge()` emits items as they arrive (unordered)
- `zip()` waits for all and combines (ordered)

## Pattern: Ternary for Simple Cases

### When ternary improves readability

```java
return data.isActive()
    ? processActive(data)
    : processInactive(data);
```

**Only use ternary when:**
- Both branches return the same reactive type
- Logic is simple and obvious
- No null checks involved (use Optional instead)

### ❌ Don't use ternary for null checks

```java
// Wrong
return data != null ? Mono.just(data) : Mono.error(...);

// Correct
return Optional.ofNullable(data)
    .map(Mono::just)
    .orElse(Mono.defer(() -> Mono.error(...)));
```

## Operator Selection Guide

### `map()` - Synchronous 1:1 transformation

```java
.map(user -> user.getName())
.map(this::buildDto)
.map(String::toUpperCase)
```

**Use when:** Transforming data without async operations.

### `flatMap()` - Asynchronous 1:1 transformation

```java
.flatMap(repository::save)
.flatMap(this::callExternalService)
.flatMap(id -> fetchDetails(id))
```

**Use when:** Operation returns `Mono<T>` or `Flux<T>`.

### `filter()` - Conditional filtering

```java
.filter(User::isActive)
.filter(data -> data.getAmount() > 0)
.filter(this::meetsBusinessRules)
```

**Use when:** Keeping only elements that match a predicate.

### `switchIfEmpty()` - Fallback for empty streams

```java
.switchIfEmpty(Mono.just(defaultValue))
.switchIfEmpty(Mono.defer(() -> Mono.error(...)))
.switchIfEmpty(alternativeSource())
```

**Use when:** Providing fallback for empty Mono/Flux.

### `collect()` - Aggregate Flux to collection

```java
.collect(Collectors.toList())
.collect(Collectors.toMap(User::getId, Function.identity()))
.collectList()
```

**Use when:** Converting Flux to Mono of collection.

### `defer()` - Lazy evaluation

```java
Mono.defer(() -> Mono.error(exception))
Mono.defer(() -> Mono.just(expensiveComputation()))
```

**Use when:** Delaying evaluation until subscription (mandatory for errors).

## Common Transformations

### Sequential operations

```java
return fetchData(id)
    .flatMap(this::validate)
    .flatMap(this::enrich)
    .flatMap(this::transform)
    .flatMap(repository::save);
```

### Parallel validations, then process

```java
return Mono.zip(
    validateFormat(data),
    validateBusinessRules(data),
    validatePermissions(userId, data)
)
.thenReturn(data)
.flatMap(this::process);
```

### Fetch multiple, combine, process

```java
return Mono.zip(
    fetchUser(userId),
    fetchAccount(accountId)
)
.flatMap(tuple -> process(tuple.getT1(), tuple.getT2()));
```

### Process and ignore result

```java
return processData(data)
    .flatMap(result -> auditService.log(result).thenReturn(result));
```

## Error Handling Strategy

### Always use lazy errors

```java
// ✅ Correct
Mono.defer(() -> Mono.error(BusinessType.ERROR.build()))

// ❌ Wrong
Mono.error(BusinessType.ERROR.build())
```

### Use BusinessType enums for all errors

```java
// Assuming BusinessType enum exists
BusinessType.NOT_FOUND.build(id)
BusinessType.INVALID_DATA.build()
BusinessType.UNAUTHORIZED.build(userId)
```

### Error recovery

```java
return riskyOperation()
    .onErrorResume(e -> fallbackOperation())
    .onErrorReturn(defaultValue);
```

## Summary: Reactive Flow Checklist

- ✅ No `if` statements - use `filter()`, `switchIfEmpty()`
- ✅ No `throw` - use `Mono.defer(() -> Mono.error())`
- ✅ No `.then(Mono.just(x))` mid-flow
- ✅ No nested operations - extract helper methods
- ✅ No `Mono<Void>` except final return
- ✅ Use `Optional` for null checks at entry points
- ✅ Use `Mono.zip()` for parallel operations
- ✅ Use `map()` for sync, `flatMap()` for async
- ✅ All errors are lazy with `Mono.defer()`

**When in doubt: Extract to a helper method and make the decision explicit.**
