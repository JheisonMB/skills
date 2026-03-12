# Best Practices - Code Style and Organization

This document covers code organization, style conventions, and quality practices for WebFlux reactive applications.

## Rule 1: Clean Imports

### Always use short imported names

```java
// ✅ Correct
import java.util.List;
import java.util.Optional;
import reactor.core.publisher.Mono;
import com.example.domain.User;

public class UserService {
    public Mono<List<User>> findAll() { ... }
}
```

```java
// ❌ Wrong - fully qualified names
public class UserService {
    public reactor.core.publisher.Mono<java.util.List<com.example.domain.User>> findAll() { ... }
}
```

### Import organization

Organize imports in three groups with blank lines between:

1. **Java standard library** (`java.*`, `javax.*`)
2. **External libraries** (`org.*`, `com.*` from dependencies)
3. **Project classes** (your package structure)

```java
import java.util.List;
import java.util.Optional;

import reactor.core.publisher.Mono;
import org.springframework.stereotype.Service;

import com.example.domain.User;
import com.example.repository.UserRepository;
```

**Most IDEs can auto-organize imports - configure them to follow this pattern.**

## Rule 2: No Literals

### Never use string or number literals in code

```java
// ❌ Wrong - literals scattered in code
public Mono<Response> process(Request req) {
    if (req.getType().equals("PREMIUM")) {  // String literal
        return processWithLimit(req, 1000);  // Number literal
    }
    return Mono.error(new Exception("Invalid type"));  // String literal
}
```

```java
// ✅ Correct - constants and enums
public class Constants {
    public static final String TYPE_PREMIUM = "PREMIUM";
    public static final int PREMIUM_LIMIT = 1000;
}

public enum BusinessType {
    INVALID_TYPE("Invalid type");
    
    private final String message;
    BusinessType(String message) { this.message = message; }
    public BusinessException build() { return new BusinessException(message); }
}

public Mono<Response> process(Request req) {
    return req.getType().equals(Constants.TYPE_PREMIUM)
        ? processWithLimit(req, Constants.PREMIUM_LIMIT)
        : Mono.defer(() -> Mono.error(BusinessType.INVALID_TYPE.build()));
}
```

### Use enums for error messages

```java
public enum BusinessType {
    NOT_FOUND("Entity not found: %s"),
    INVALID_DATA("Data validation failed"),
    UNAUTHORIZED("User %s not authorized"),
    EMPTY_INPUT("Input cannot be empty");
    
    private final String messageTemplate;
    
    BusinessType(String messageTemplate) {
        this.messageTemplate = messageTemplate;
    }
    
    public BusinessException build(Object... args) {
        String message = args.length > 0 
            ? String.format(messageTemplate, args)
            : messageTemplate;
        return new BusinessException(message);
    }
}
```

**Usage:**
```java
Mono.defer(() -> Mono.error(BusinessType.NOT_FOUND.build(userId)))
Mono.defer(() -> Mono.error(BusinessType.UNAUTHORIZED.build(username)))
```

### Constants for configuration values

```java
public class ServiceConfig {
    public static final int MAX_RETRY_ATTEMPTS = 3;
    public static final Duration TIMEOUT = Duration.ofSeconds(30);
    public static final int BATCH_SIZE = 100;
}
```

### Use constants in switch expressions

```java
// ✅ Correct
public static final String STATUS_ACTIVE = "ACTIVE";
public static final String STATUS_PENDING = "PENDING";
public static final String STATUS_INACTIVE = "INACTIVE";

return switch (status) {
    case STATUS_ACTIVE -> processActive(data);
    case STATUS_PENDING -> processPending(data);
    case STATUS_INACTIVE -> processInactive(data);
    default -> Mono.defer(() -> Mono.error(BusinessType.INVALID_STATUS.build()));
};
```

## Rule 3: Helper Methods

### Extract complex operations to helper methods

Every helper method should have a single, clear responsibility.

### When to extract a helper method

**Extract when:**
- Building objects with multiple fields
- Validating multiple parameters
- Searching or filtering collections
- Any operation that obscures the main flow

```java
// ❌ Wrong - complex logic inline
public Mono<Response> handle(Request req) {
    return repository.findById(req.getId())
        .flatMap(data -> {
            Response response = new Response();
            response.setId(data.getId());
            response.setName(data.getName());
            response.setStatus(data.getStatus());
            response.setCreatedAt(data.getCreatedAt());
            response.setUpdatedAt(data.getUpdatedAt());
            response.setMetadata(buildMetadata(data));
            return Mono.just(response);
        });
}
```

```java
// ✅ Correct - extracted to helper
public Mono<Response> handle(Request req) {
    return repository.findById(req.getId())
        .map(this::buildResponse);
}

private Response buildResponse(Data data) {
    Response response = new Response();
    response.setId(data.getId());
    response.setName(data.getName());
    response.setStatus(data.getStatus());
    response.setCreatedAt(data.getCreatedAt());
    response.setUpdatedAt(data.getUpdatedAt());
    response.setMetadata(buildMetadata(data));
    return response;
}
```

### Main methods should read as high-level flows

```java
// ✅ Good - reads like a story
public Mono<Response> processOrder(OrderRequest request) {
    return validateRequest(request)
        .flatMap(this::checkInventory)
        .flatMap(this::calculatePricing)
        .flatMap(this::applyDiscounts)
        .flatMap(orderRepository::save)
        .flatMap(this::sendConfirmation)
        .map(this::buildResponse);
}
```

Each step is self-documenting through the method name.

### Helper method naming

- Use descriptive verb-noun combinations
- Make the responsibility obvious
- Avoid generic names like `process()`, `handle()`, `doWork()`

```java
// ✅ Good names
validateUserPermissions()
buildOrderSummary()
enrichWithAccountDetails()
calculateTotalAmount()
filterActiveUsers()

// ❌ Poor names
validate()
build()
enrich()
calculate()
filter()
```

### Single responsibility principle

Each helper should do one thing:

```java
// ❌ Wrong - multiple responsibilities
private Mono<Data> validateAndEnrichAndSave(Data data) {
    return validate(data)
        .flatMap(this::enrich)
        .flatMap(repository::save);
}

// ✅ Correct - separate concerns
private Mono<Data> validateData(Data data) { ... }
private Mono<Data> enrichData(Data data) { ... }
private Mono<Data> saveData(Data data) { ... }

// Main flow composes them
return validateData(data)
    .flatMap(this::enrichData)
    .flatMap(this::saveData);
```

## Rule 4: Type Inference

### Let the compiler infer obvious types

```java
// ❌ Wrong - unnecessary casting
return repository.findById(id)
    .map(data -> (Data) data)  // Redundant cast
    .flatMap(this::process);
```

```java
// ✅ Correct - compiler knows the type
return repository.findById(id)
    .flatMap(this::process);
```

### Don't fight the type system

If you need a cast, the design might be wrong:

```java
// ❌ Code smell - why is casting needed?
return repository.findAll()
    .map(obj -> (User) obj)
    .collectList();

// ✅ Better - fix the repository return type
// Repository should return Flux<User>, not Flux<Object>
```

## Rule 5: Operator Selection

### Use the right operator for the job

**Synchronous transformation → `map()`**
```java
.map(User::getName)
.map(this::buildDto)
```

**Asynchronous operation → `flatMap()`**
```java
.flatMap(repository::save)
.flatMap(this::callExternalService)
```

**Aggregation → `collect()`**
```java
.collect(Collectors.toList())
.collectList()
```

**Don't use `flatMap()` when `map()` suffices:**
```java
// ❌ Wrong - flatMap for sync operation
.flatMap(user -> Mono.just(user.getName()))

// ✅ Correct - map for sync operation
.map(User::getName)
```

## Rule 6: Method Length

### Keep methods focused and short

**Guidelines:**
- Main reactive flow: 10-15 lines max
- Helper methods: 5-10 lines max
- If longer, extract more helpers

```java
// ✅ Good length - clear and focused
public Mono<Response> processPayment(PaymentRequest request) {
    return validatePaymentRequest(request)
        .flatMap(this::checkFraudRules)
        .flatMap(this::processWithGateway)
        .flatMap(this::recordTransaction)
        .map(this::buildPaymentResponse);
}
```

## Rule 7: Avoid Premature Optimization

### Write clear code first, optimize if needed

```java
// ✅ Clear and correct
return repository.findById(id)
    .flatMap(this::validate)
    .flatMap(this::enrich)
    .flatMap(this::process);
```

Only optimize (e.g., add parallelization) when:
- Profiling shows it's a bottleneck
- Operations are truly independent
- The complexity trade-off is worth it

## Code Organization Checklist

- ✅ Imports organized: Java → libraries → project
- ✅ No string/number literals - use constants/enums
- ✅ Complex operations extracted to helpers
- ✅ Helper methods have single responsibility
- ✅ Main methods read as high-level flows
- ✅ Method names are descriptive
- ✅ No unnecessary type casts
- ✅ Correct operator selection (map vs flatMap)
- ✅ Methods are short and focused

## Example: Well-Organized Service

```java
import java.util.Optional;

import reactor.core.publisher.Mono;
import org.springframework.stereotype.Service;

import com.example.domain.Order;
import com.example.repository.OrderRepository;

@Service
public class OrderService {
    
    private static final int MAX_QUANTITY = 100;
    private final OrderRepository repository;
    
    public OrderService(OrderRepository repository) {
        this.repository = repository;
    }
    
    public Mono<OrderResponse> createOrder(OrderRequest request) {
        return validateRequest(request)
            .flatMap(this::checkInventory)
            .flatMap(this::createOrderEntity)
            .flatMap(repository::save)
            .map(this::buildResponse);
    }
    
    private Mono<OrderRequest> validateRequest(OrderRequest request) {
        return Optional.ofNullable(request)
            .filter(r -> r.getQuantity() > 0)
            .filter(r -> r.getQuantity() <= MAX_QUANTITY)
            .map(Mono::just)
            .orElse(Mono.defer(() -> 
                Mono.error(BusinessType.INVALID_REQUEST.build())));
    }
    
    private Mono<OrderRequest> checkInventory(OrderRequest request) {
        // Implementation
    }
    
    private Mono<Order> createOrderEntity(OrderRequest request) {
        Order order = new Order();
        order.setProductId(request.getProductId());
        order.setQuantity(request.getQuantity());
        order.setStatus(OrderStatus.PENDING);
        return Mono.just(order);
    }
    
    private OrderResponse buildResponse(Order order) {
        OrderResponse response = new OrderResponse();
        response.setOrderId(order.getId());
        response.setStatus(order.getStatus());
        return response;
    }
}
```

**Notice:**
- Clean imports organization
- Constant for MAX_QUANTITY
- Each method has single responsibility
- Main method reads as clear flow
- Helper methods are focused and short
- No literals in code
- Proper operator selection

## Summary

Good code organization makes reactive flows readable and maintainable. Follow these practices consistently to produce professional-quality WebFlux applications.
