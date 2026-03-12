# Troubleshooting Reactive Code

This guide helps diagnose and fix common issues in WebFlux reactive applications.

## Issue 1: Stream Not Executing

### Symptoms
- Code looks correct but nothing happens
- No data returned, no errors thrown
- Logs show method called but no processing

### Root Cause
Reactive streams are lazy - they don't execute until subscribed.

### Examples

```java
// ❌ Wrong - creates Mono but never subscribes
public void processUser(String id) {
    Mono<User> user = repository.findById(id);
    // Nothing happens! No subscription = no execution
}

// ❌ Wrong - manual subscription in service layer
public void processUser(String id) {
    repository.findById(id)
        .subscribe(user -> log.info("Found: {}", user));
    // Subscription happens but caller can't get result
}

// ✅ Correct - return Mono, let framework subscribe
public Mono<User> getUser(String id) {
    return repository.findById(id);  // Framework subscribes
}

// ✅ Correct - chain operations, return final Mono
public Mono<UserDto> processUser(String id) {
    return repository.findById(id)
        .map(this::enrichUser)
        .map(this::toDto);
}
```

### Solution
Always return the Mono/Flux. Let the framework (Spring WebFlux) handle subscription.

---

## Issue 2: Blocking Calls in Reactive Code

### Symptoms
- Poor performance under load
- Thread pool exhaustion
- High latency despite async code

### Root Cause
Using blocking operations inside reactive chains blocks the reactive thread pool.

### Detection

Look for these blocking patterns:

```java
// ❌ Thread.sleep()
.map(data -> {
    Thread.sleep(1000);  // Blocks thread!
    return data;
})

// ❌ JDBC database calls
.map(data -> {
    jdbcTemplate.query(...);  // Blocking!
    return data;
})

// ❌ Blocking HTTP clients
.map(data -> {
    RestTemplate restTemplate = new RestTemplate();
    String result = restTemplate.getForObject(url, String.class);  // Blocking!
    return result;
})

// ❌ CompletableFuture.get()
.map(data -> {
    CompletableFuture<String> future = asyncCall();
    return future.get();  // Blocks!
})

// ❌ .block() or .blockFirst()
.map(data -> {
    String result = someReactiveMono.block();  // Never do this!
    return result;
})
```

### Solutions

```java
// ✅ Use Mono.delay() instead of Thread.sleep()
return Mono.delay(Duration.ofSeconds(1))
    .thenReturn(data);

// ✅ Use R2DBC instead of JDBC
return r2dbcRepository.findById(id);

// ✅ Use WebClient instead of RestTemplate
return webClient.get()
    .uri(url)
    .retrieve()
    .bodyToMono(String.class);

// ✅ Use Mono.fromFuture() for CompletableFuture
return Mono.fromFuture(asyncCall());

// ✅ Chain reactive operations instead of blocking
return someReactiveMono
    .flatMap(this::processResult);
```

### When Blocking is Unavoidable

If you must use a blocking library, isolate it on a separate thread pool:

```java
private final Scheduler blockingScheduler = Schedulers.boundedElastic();

return Mono.fromCallable(() -> {
    // Blocking operation here
    return jdbcTemplate.query(...);
})
.subscribeOn(blockingScheduler);
```

---

## Issue 3: Memory Leaks from Subscriptions

### Symptoms
- Memory usage grows over time
- Application eventually crashes with OutOfMemoryError
- Heap dumps show many Subscription objects

### Root Cause
Manual subscriptions without proper disposal.

### Examples

```java
// ❌ Wrong - manual subscription leaks
@PostConstruct
public void init() {
    repository.findAll()
        .subscribe(data -> cache.put(data.getId(), data));
    // Subscription never disposed!
}

// ❌ Wrong - subscribing in loop
public void processAll(List<String> ids) {
    ids.forEach(id -> 
        repository.findById(id)
            .subscribe(this::process)  // Leak per iteration!
    );
}
```

### Solutions

```java
// ✅ Correct - return Flux, let framework manage
public Flux<Data> getAllData() {
    return repository.findAll();
}

// ✅ Correct - use operators instead of manual subscription
public Mono<Void> processAll(List<String> ids) {
    return Flux.fromIterable(ids)
        .flatMap(repository::findById)
        .flatMap(this::process)
        .then();
}

// ✅ If manual subscription needed, dispose properly
private Disposable subscription;

@PostConstruct
public void init() {
    subscription = repository.findAll()
        .subscribe(data -> cache.put(data.getId(), data));
}

@PreDestroy
public void cleanup() {
    if (subscription != null && !subscription.isDisposed()) {
        subscription.dispose();
    }
}
```

---

## Issue 4: Lost Context in Parallel Operations

### Symptoms
- ThreadLocal data disappears
- Security context lost
- Request-scoped data unavailable

### Root Cause
Reactive streams can switch threads, losing ThreadLocal context.

### Solution: Use Reactor Context

```java
// ❌ Wrong - ThreadLocal doesn't work
private static final ThreadLocal<String> userId = new ThreadLocal<>();

public Mono<Data> process() {
    return Mono.just("data")
        .map(d -> {
            String user = userId.get();  // Likely null!
            return processWithUser(d, user);
        });
}

// ✅ Correct - use Reactor Context
public Mono<Data> process() {
    return Mono.deferContextual(ctx -> {
        String userId = ctx.get("userId");
        return processWithUser(userId);
    });
}

// Set context when creating the chain
return process()
    .contextWrite(Context.of("userId", currentUserId));
```

---

## Issue 5: Infinite Loops or Excessive Retries

### Symptoms
- Application hangs
- Logs show endless retry attempts
- External services report abuse

### Root Cause
Retry without limits or backoff strategy.

### Examples

```java
// ❌ Wrong - infinite retries
return externalService.call()
    .retry();  // Retries forever!

// ❌ Wrong - too many retries, no backoff
return externalService.call()
    .retry(1000);  // Hammers service!
```

### Solutions

```java
// ✅ Correct - limited retries with exponential backoff
return externalService.call()
    .retryWhen(Retry.backoff(3, Duration.ofSeconds(1))
        .maxBackoff(Duration.ofSeconds(10))
        .filter(throwable -> throwable instanceof TimeoutException));

// ✅ Correct - retry with custom logic
return externalService.call()
    .retryWhen(Retry.fixedDelay(3, Duration.ofSeconds(2))
        .filter(this::isRetryable)
        .doBeforeRetry(signal -> 
            log.warn("Retry attempt {} after error: {}", 
                signal.totalRetries(), signal.failure().getMessage())));

private boolean isRetryable(Throwable throwable) {
    return throwable instanceof TimeoutException 
        || throwable instanceof ConnectException;
}
```

---

## Issue 6: Errors Swallowed Silently

### Symptoms
- Operations fail but no error logged
- Unexpected empty results
- Silent failures

### Root Cause
Missing error handlers in reactive chain.

### Examples

```java
// ❌ Wrong - errors disappear
return repository.findById(id)
    .map(this::process);
// If process() throws, error propagates but might not be logged

// ✅ Correct - explicit error handling
return repository.findById(id)
    .map(this::process)
    .doOnError(error -> log.error("Processing failed for id: {}", id, error))
    .onErrorResume(error -> Mono.empty());  // Or provide fallback

// ✅ Correct - log all stages
return repository.findById(id)
    .doOnNext(data -> log.debug("Found: {}", data))
    .map(this::process)
    .doOnNext(result -> log.debug("Processed: {}", result))
    .doOnError(error -> log.error("Error: ", error));
```

---

## Issue 7: Incorrect Operator Selection

### Symptoms
- Compilation errors about return types
- Nested Mono<Mono<T>> or Flux<Flux<T>>
- Operations not executing as expected

### Root Cause
Using `map()` when `flatMap()` is needed, or vice versa.

### Decision Guide

```java
// Use map() for synchronous transformations
.map(user -> user.getName())           // ✅ Returns String
.map(this::buildDto)                   // ✅ Returns DTO
.map(String::toUpperCase)              // ✅ Returns String

// Use flatMap() for async operations (returns Mono/Flux)
.flatMap(repository::save)             // ✅ Returns Mono<Entity>
.flatMap(this::callExternalService)    // ✅ Returns Mono<Response>
.flatMap(id -> fetchDetails(id))       // ✅ Returns Mono<Details>

// ❌ Wrong - map with async operation
.map(id -> repository.findById(id))    // Returns Mono<Mono<Entity>>!

// ✅ Correct - flatMap with async operation
.flatMap(id -> repository.findById(id)) // Returns Mono<Entity>

// ❌ Wrong - flatMap with sync operation
.flatMap(user -> Mono.just(user.getName())) // Unnecessary wrapping

// ✅ Correct - map with sync operation
.map(User::getName)                    // Clean and efficient
```

---

## Issue 8: Timeout Not Configured

### Symptoms
- Requests hang indefinitely
- No response from slow services
- Resource exhaustion

### Root Cause
Missing timeout configuration.

### Solutions

```java
// ✅ Add timeout to operations
return webClient.get()
    .uri(url)
    .retrieve()
    .bodyToMono(String.class)
    .timeout(Duration.ofSeconds(5))
    .onErrorResume(TimeoutException.class, e -> 
        Mono.error(new ServiceUnavailableException("Service timeout")));

// ✅ Global timeout for entire chain
return processData(id)
    .timeout(Duration.ofSeconds(10))
    .onErrorMap(TimeoutException.class, e -> 
        new BusinessException("Processing timeout"));
```

---

## Debugging Techniques

### 1. Add Logging Operators

```java
return repository.findById(id)
    .doOnSubscribe(s -> log.debug("Subscribing to findById: {}", id))
    .doOnNext(data -> log.debug("Found data: {}", data))
    .doOnError(error -> log.error("Error finding data: ", error))
    .doOnSuccess(data -> log.debug("Success: {}", data))
    .doFinally(signal -> log.debug("Finally: {}", signal));
```

### 2. Use checkpoint() for Stack Traces

```java
return repository.findById(id)
    .checkpoint("After repository lookup")
    .flatMap(this::process)
    .checkpoint("After processing");
```

### 3. Enable Reactor Debug Mode (Development Only)

```java
// In main() or @PostConstruct
Hooks.onOperatorDebug();
```

**Warning:** Significant performance impact. Only use in development.

### 4. Use BlockHound to Detect Blocking Calls

Add dependency:
```xml
<dependency>
    <groupId>io.projectreactor.tools</groupId>
    <artifactId>blockhound</artifactId>
    <scope>test</scope>
</dependency>
```

Enable in tests:
```java
@BeforeAll
static void setup() {
    BlockHound.install();
}
```

---

## Performance Issues

### Cold vs Hot Publishers

```java
// Cold publisher - creates new stream per subscriber
Mono<Data> cold = Mono.fromCallable(() -> expensiveOperation());

// Each subscription calls expensiveOperation()
cold.subscribe(data -> process1(data));
cold.subscribe(data -> process2(data));  // Calls again!

// ✅ Hot publisher - share single execution
Mono<Data> hot = Mono.fromCallable(() -> expensiveOperation())
    .cache();  // Cache result

hot.subscribe(data -> process1(data));
hot.subscribe(data -> process2(data));  // Uses cached result
```

### Backpressure Issues

```java
// ❌ Wrong - no backpressure handling
return Flux.range(1, 1_000_000)
    .flatMap(this::processItem);  // Overwhelms downstream!

// ✅ Correct - limit concurrency
return Flux.range(1, 1_000_000)
    .flatMap(this::processItem, 10);  // Max 10 concurrent

// ✅ Correct - use buffer
return Flux.range(1, 1_000_000)
    .buffer(100)
    .flatMap(this::processBatch);
```

---

## Summary Checklist

When debugging reactive code, check:

- ✅ Are you returning Mono/Flux (not subscribing manually)?
- ✅ Are there any blocking calls? (Thread.sleep, JDBC, RestTemplate, .block())
- ✅ Are errors handled explicitly? (doOnError, onErrorResume)
- ✅ Are timeouts configured?
- ✅ Is retry logic bounded?
- ✅ Are you using the right operator? (map vs flatMap)
- ✅ Is context propagated correctly? (not using ThreadLocal)
- ✅ Are subscriptions disposed properly?
- ✅ Is backpressure handled for large streams?

**When stuck, add logging operators to trace execution flow.**
