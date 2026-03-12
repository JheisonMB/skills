package com.example.service;

import java.util.Optional;

import reactor.core.publisher.Mono;
import org.springframework.stereotype.Service;

import com.example.domain.User;
import com.example.domain.Account;
import com.example.repository.UserRepository;
import com.example.repository.AccountRepository;
import com.example.exception.BusinessType;

/**
 * Example service demonstrating WebFlux reactive patterns.
 * 
 * This class showcases:
 * - Lazy error handling with Mono.defer()
 * - Optional for null checks
 * - Helper method extraction
 * - Parallel operations with Mono.zip()
 * - Pure reactive flow (no imperative constructs)
 * - Timeout handling
 * - Retry logic with backoff
 * - Error recovery strategies
 */
@Service
public class UserAccountService {
    
    private static final int MIN_BALANCE = 0;
    private static final String STATUS_ACTIVE = "ACTIVE";
    private static final Duration OPERATION_TIMEOUT = Duration.ofSeconds(5);
    private static final int MAX_RETRY_ATTEMPTS = 3;
    
    private final UserRepository userRepository;
    private final AccountRepository accountRepository;
    private final AuditService auditService;
    
    public UserAccountService(
            UserRepository userRepository, 
            AccountRepository accountRepository,
            AuditService auditService) {
        this.userRepository = userRepository;
        this.accountRepository = accountRepository;
        this.auditService = auditService;
    }
    
    /**
     * Main flow: validates input, fetches data in parallel, processes, and saves.
     * Demonstrates: high-level readable flow, parallel operations, helper methods,
     * timeout handling, and audit logging with error recovery.
     */
    public Mono<UserAccountResponse> processUserAccount(String userId, AccountRequest request) {
        return validateRequest(request)
            .flatMap(req -> fetchUserAndAccount(userId))
            .timeout(OPERATION_TIMEOUT)
            .flatMap(tuple -> processAccount(tuple.getT1(), tuple.getT2(), request))
            .flatMap(this::saveAccountWithRetry)
            .flatMap(account -> auditLog(account).thenReturn(account))
            .map(this::buildResponse)
            .onErrorResume(TimeoutException.class, e -> 
                Mono.error(BusinessType.OPERATION_TIMEOUT.build(userId)));
    }
    
    /**
     * Validates request using Optional pattern.
     * Demonstrates: Optional.ofNullable, filter chain, lazy error with Mono.defer().
     */
    private Mono<AccountRequest> validateRequest(AccountRequest request) {
        return Optional.ofNullable(request)
            .filter(r -> r.getAmount() != null)
            .filter(r -> r.getAmount() >= MIN_BALANCE)
            .map(Mono::just)
            .orElse(Mono.defer(() -> 
                Mono.error(BusinessType.INVALID_REQUEST.build())));
    }
    
    /**
     * Fetches user and account in parallel using Mono.zip().
     * Demonstrates: parallel independent operations, switchIfEmpty with lazy error.
     */
    private Mono<Tuple2<User, Account>> fetchUserAndAccount(String userId) {
        Mono<User> userMono = userRepository.findById(userId)
            .switchIfEmpty(Mono.defer(() -> 
                Mono.error(BusinessType.USER_NOT_FOUND.build(userId))));
        
        Mono<Account> accountMono = accountRepository.findByUserId(userId)
            .switchIfEmpty(Mono.defer(() -> 
                Mono.error(BusinessType.ACCOUNT_NOT_FOUND.build(userId))));
        
        return Mono.zip(userMono, accountMono);
    }
    
    /**
     * Processes account with business logic.
     * Demonstrates: filter + switchIfEmpty instead of if statements, helper method extraction.
     */
    private Mono<Account> processAccount(User user, Account account, AccountRequest request) {
        return validateUserStatus(user)
            .then(Mono.just(account))
            .map(acc -> applyTransaction(acc, request));
    }
    
    /**
     * Validates user status reactively.
     * Demonstrates: filter + switchIfEmpty pattern, no imperative if.
     */
    private Mono<Void> validateUserStatus(User user) {
        return Mono.just(user)
            .filter(u -> STATUS_ACTIVE.equals(u.getStatus()))
            .switchIfEmpty(Mono.defer(() -> 
                Mono.error(BusinessType.USER_INACTIVE.build(user.getId()))))
            .then();
    }
    
    /**
     * Applies transaction to account (synchronous operation).
     * Demonstrates: helper method for complex logic, single responsibility.
     */
    private Account applyTransaction(Account account, AccountRequest request) {
        account.setBalance(account.getBalance() + request.getAmount());
        account.setLastModified(System.currentTimeMillis());
        return account;
    }
    
    /**
     * Saves account to repository with retry logic.
     * Demonstrates: retry with exponential backoff, error filtering.
     */
    private Mono<Account> saveAccountWithRetry(Account account) {
        return accountRepository.save(account)
            .retryWhen(Retry.backoff(MAX_RETRY_ATTEMPTS, Duration.ofMillis(100))
                .maxBackoff(Duration.ofSeconds(2))
                .filter(this::isRetryableError)
                .doBeforeRetry(signal -> 
                    log.warn("Retry attempt {} for account {}", 
                        signal.totalRetries(), account.getId())));
    }
    
    /**
     * Determines if error is retryable.
     * Demonstrates: helper method for business logic.
     */
    private boolean isRetryableError(Throwable throwable) {
        return throwable instanceof TimeoutException
            || throwable instanceof ConnectException;
    }
    
    /**
     * Audit log with error recovery.
     * Demonstrates: onErrorResume for non-critical operations.
     */
    private Mono<Void> auditLog(Account account) {
        return auditService.log(account)
            .onErrorResume(error -> {
                log.error("Audit logging failed for account {}", account.getId(), error);
                return Mono.empty();  // Continue despite audit failure
            });
    }
    
    /**
     * Saves account to repository.
     * Demonstrates: simple delegation to repository.
     */
    private Mono<Account> saveAccount(Account account) {
        return accountRepository.save(account);
    }
    
    /**
     * Builds response DTO (synchronous operation).
     * Demonstrates: helper method for object construction, used with map().
     */
    private UserAccountResponse buildResponse(Account account) {
        UserAccountResponse response = new UserAccountResponse();
        response.setAccountId(account.getId());
        response.setBalance(account.getBalance());
        response.setStatus(account.getStatus());
        return response;
    }
}

/**
 * Key patterns demonstrated:
 * 
 * 1. Lazy errors: Always use Mono.defer(() -> Mono.error(...))
 * 2. Optional pattern: For null checks at entry points
 * 3. No imperative if: Use filter() + switchIfEmpty()
 * 4. Helper methods: Extract complex logic, single responsibility
 * 5. Parallel operations: Mono.zip() for independent operations
 * 6. Operator selection: map() for sync, flatMap() for async
 * 7. No literals: Use constants (MIN_BALANCE, STATUS_ACTIVE)
 * 8. Clean flow: Main method reads as high-level steps
 * 9. Timeout handling: Add timeouts to prevent hanging operations
 * 10. Retry logic: Use exponential backoff for transient failures
 * 11. Error recovery: Use onErrorResume for non-critical operations
 * 12. Audit pattern: Log operations without failing main flow
 */
