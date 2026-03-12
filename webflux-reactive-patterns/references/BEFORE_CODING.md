# Before Coding - Analysis Workflow

This document outlines the mandatory analysis workflow that must be completed before writing or modifying any reactive code.

## Philosophy

Reactive programming requires careful planning because imperative thinking doesn't translate directly to reactive patterns. Rushing into implementation leads to anti-patterns, nested chains, and broken reactive semantics.

## Pre-Implementation Checklist

Before modifying any file, complete these steps in order:

### 1. Analyze Existing Code

**What to examine:**
- Classes that will be modified or extended
- Methods that will be called or overridden
- Dependencies and their reactive contracts (Mono/Flux return types)
- Error handling patterns already in use
- Data flow through the reactive chain

**Questions to answer:**
- What reactive types are involved? (Mono, Flux, or both?)
- Are there existing helper methods I can reuse?
- What error types are already defined?
- Are there parallel operations I need to coordinate with?

### 2. Define Implementation Plan

**Create a concrete plan including:**
- Which methods need to be added/modified
- The reactive operator chain structure (map → flatMap → filter → etc.)
- Where helper methods should be extracted
- How errors will be handled (which BusinessType enums to use)
- Whether operations can run in parallel

**Example plan structure:**
```
1. Add validateRequest() helper method
   - Use Optional.ofNullable() for null check
   - Return Mono<Request> or Mono.error()
   
2. Modify processRequest() main method
   - Chain: validate → fetch from repo → transform → save
   - Use Mono.zip() for parallel validation steps
   
3. Extract buildResponse() helper
   - Map domain object to DTO
   - Keep synchronous (use map, not flatMap)
```

### 3. Ask Clarifying Questions

**Before implementing, verify:**
- Return types: Should this return `Mono<T>`, `Flux<T>`, or `Mono<Void>`?
- Error handling: What specific error should be thrown for each failure case?
- Edge cases: What happens with null/empty inputs? Duplicate data? Missing references?
- Business logic: Are there implicit requirements not documented?
- Performance: Should these operations run in parallel or sequentially?

**Don't assume - ask explicitly:**
- "Should this method return Mono<Response> or Mono<Void>?"
- "What error type for missing entity - NOT_FOUND or INVALID_REQUEST?"
- "Can validation steps run in parallel or must they be sequential?"

### 4. Make Explicit Design Decisions

**Document your decisions:**
- **Pattern choice**: Why Optional vs filter? Why zip vs sequential flatMap?
- **Method structure**: Why extract this helper? What's its single responsibility?
- **Error strategy**: Why this BusinessType? What context to include?
- **Reusability**: Can this logic be generalized for other use cases?

**Example decision log:**
```
Decision: Use Optional.ofNullable() instead of filter()
Reason: Input validation at entry point, clearer intent than filter
Alternative considered: Direct filter() - rejected because less explicit

Decision: Extract validateBusinessRules() helper
Reason: Complex multi-field validation, reusable across endpoints
Single responsibility: Validate business constraints only

Decision: Use Mono.zip() for field validations
Reason: Validations are independent, can run in parallel
Performance gain: ~3x faster than sequential flatMap chain
```

## Only Then: Write Code

After completing all four steps above, you can begin implementation. The code should directly reflect your plan with no surprises.

## Red Flags That Indicate Insufficient Planning

- You're not sure whether to use `map()` or `flatMap()`
- You're nesting more than 2 levels of reactive operators
- You're using `if` statements inside reactive chains
- You're not sure what error type to return
- The method is growing beyond 15 lines
- You're repeating similar logic from elsewhere

**If you encounter any red flag: STOP. Return to analysis phase.**

## Example: Complete Analysis Before Implementation

**Task:** Add endpoint to update user profile with validation

**1. Analysis:**
- Existing: UserRepository returns Mono<User>, UserValidator has validateEmail()
- Dependencies: ProfileMapper (sync), AuditService.log() returns Mono<Void>
- Error types: USER_NOT_FOUND, INVALID_EMAIL, VALIDATION_FAILED

**2. Plan:**
```
Main flow: updateProfile(userId, request)
  → validateRequest(request) [helper]
  → repository.findById(userId)
  → switchIfEmpty(error USER_NOT_FOUND)
  → flatMap(user -> Mono.zip(
      validateEmail(request.email),
      validatePhone(request.phone)
    ).thenReturn(user))
  → map(user -> applyUpdates(user, request)) [helper]
  → flatMap(repository::save)
  → flatMap(user -> auditService.log(userId).thenReturn(user))
  → map(ProfileMapper::toDto)
```

**3. Questions:**
- Q: Should validation fail-fast or collect all errors?
- A: Fail-fast (use zip, first error stops chain)
- Q: Should audit logging failure fail the whole operation?
- A: No, use onErrorResume to log and continue

**4. Decisions:**
- Use Mono.zip for parallel validation (independent checks)
- Extract applyUpdates() helper (complex field mapping)
- Use thenReturn() after audit to preserve user object
- Map to DTO at the end (presentation layer concern)

**Now ready to implement.**

## Benefits of This Workflow

- **Fewer rewrites**: Plan catches issues before coding
- **Better patterns**: Conscious operator selection
- **Cleaner code**: Helper methods identified upfront
- **Faster reviews**: Decisions are documented
- **Knowledge sharing**: Analysis can be reviewed before implementation

## Anti-Pattern: Coding First, Thinking Later

```java
// Result of skipping analysis - imperative reactive code
public Mono<Response> badExample(String id) {
    return repository.findById(id)
        .flatMap(data -> {
            if (data.isValid()) {  // ❌ Imperative if
                if (data.getStatus().equals("ACTIVE")) {  // ❌ Nested if
                    try {
                        return process(data);  // ❌ Unclear error handling
                    } catch (Exception e) {  // ❌ Imperative exception
                        throw new RuntimeException(e);
                    }
                } else {
                    return Mono.error(new Exception("Not active"));  // ❌ Not lazy
                }
            } else {
                return Mono.empty();  // ❌ Silent failure
            }
        });
}
```

**This code has multiple issues that proper analysis would have prevented.**

## Summary

The analysis workflow is not overhead - it's the foundation of clean reactive code. Invest 5-10 minutes in planning to save hours of debugging and refactoring.

**Remember: In reactive programming, thinking is more important than typing.**
