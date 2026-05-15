---
name: java-springboot
description: Use when adding or modifying Spring Boot REST API code — controllers, request/response DTOs, services, validation, and centralised error handling — in a Java / Spring Boot 3+ project. TRIGGER when files import `org.springframework.web.*` or `org.springframework.stereotype.Service`; when the user asks to add a REST endpoint / API resource / "expose X over HTTP"; or when adding `@RestController`, `@Service`, `@RequestBody`, `@PathVariable`, or a record DTO in a Spring Boot project. SKIP for non-Spring Java (plain servlet, Quarkus, Micronaut, Jakarta EE without Spring), and for JPA-only changes that do not touch the web layer.
---

# Java Spring Boot — REST controllers, DTOs, services

Idiomatic Spring Boot 3.x conventions for the web layer in a layered architecture (controller → service → repository). Assumes Java 21 LTS, Jakarta namespace (`jakarta.*`, not `javax.*`), and the `spring-boot-starter-web` + `spring-boot-starter-validation` starters.

## Layer responsibilities

| Layer | Owns | Must not |
|---|---|---|
| `@RestController` | HTTP mapping, request validation, status codes, response shape | Contain business rules, call repositories directly |
| `@Service` | Business logic, transaction boundaries, orchestration | Reference HTTP types (`ResponseEntity`, `HttpStatus`) or web annotations |
| `@Repository` | Data access | Hold business rules or shape responses |

Controllers do not know about JPA entities. Services do not know about `ResponseEntity`. DTOs enforce the boundary.

## DTO conventions

Prefer Java `record` types. Keep **request** and **response** DTOs distinct — never return an entity. Co-locate with the controller or in a `dto/` subpackage:

```java
public record CreateOrderRequest(
        @NotBlank String customerId,
        @NotEmpty @Valid List<OrderLineRequest> lines
) {}

public record OrderResponse(
        UUID id,
        String customerId,
        List<OrderLineResponse> lines,
        Instant createdAt
) {}
```

Mapping: prefer a small hand-written `OrderMapper` over MapStruct unless the project already depends on it — explicit mapping keeps the controller boundary visible and avoids generated-code surprises.

## Controller template

```java
@RestController
@RequestMapping("/api/v1/orders")
@RequiredArgsConstructor
public class OrderController {

    private final OrderService orderService;
    private final OrderMapper mapper;

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public OrderResponse create(@Valid @RequestBody CreateOrderRequest req) {
        var order = orderService.create(mapper.toCommand(req));
        return mapper.toResponse(order);
    }

    @GetMapping("/{id}")
    public OrderResponse get(@PathVariable UUID id) {
        return mapper.toResponse(orderService.findById(id));
    }
}
```

Return the response body directly — Spring sets 200 by default. Use `@ResponseStatus` for non-200 success codes. Reach for `ResponseEntity<T>` **only** when the status varies at runtime or you need to set custom headers.

## Service template

```java
@Service
@Transactional
@RequiredArgsConstructor
public class OrderService {

    private final OrderRepository orders;

    public Order create(CreateOrderCommand cmd) {
        var order = Order.from(cmd);
        return orders.save(order);
    }

    @Transactional(readOnly = true)
    public Order findById(UUID id) {
        return orders.findById(id)
                .orElseThrow(() -> new OrderNotFoundException(id));
    }
}
```

Class-level `@Transactional` defaults to read-write; mark read paths `readOnly = true`. Throw a domain-specific exception (`OrderNotFoundException`), not a generic `RuntimeException` or `IllegalArgumentException`.

## Validation

Annotate request DTO fields with `jakarta.validation.constraints.*`. Add `@Valid` on the controller parameter to trigger validation. For nested collections both annotations are required — `@NotEmpty` on the outer list and `@Valid` to cascade into the inner records.

Cross-field rules → an `@AssertTrue` method on the record or a custom constraint annotation. Do **not** push validation into the service layer when it can be expressed declaratively on the DTO.

## Error handling — RFC 7807 Problem Details

Spring Boot 3 ships built-in `ProblemDetail` support. Centralise mapping in a `@RestControllerAdvice`:

```java
@RestControllerAdvice
public class ApiExceptionHandler {

    @ExceptionHandler(OrderNotFoundException.class)
    ProblemDetail handleNotFound(OrderNotFoundException e) {
        var pd = ProblemDetail.forStatusAndDetail(HttpStatus.NOT_FOUND, e.getMessage());
        pd.setType(URI.create("https://example.com/errors/order-not-found"));
        pd.setProperty("orderId", e.getOrderId());
        return pd;
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    ProblemDetail handleValidation(MethodArgumentNotValidException e) {
        var pd = ProblemDetail.forStatusAndDetail(HttpStatus.BAD_REQUEST, "Request validation failed");
        pd.setProperty("errors", e.getBindingResult().getFieldErrors().stream()
                .map(fe -> Map.of("field", fe.getField(), "message", fe.getDefaultMessage()))
                .toList());
        return pd;
    }
}
```

Do not catch exceptions in the controller just to re-throw them with a different message — let them propagate to the advice.

## What to avoid

- Returning JPA entities from controllers — couples API to schema, breaks on lazy collections during serialisation.
- `@Autowired` on fields — use constructor injection. Lombok's `@RequiredArgsConstructor` or a hand-written constructor are both fine; field injection is not.
- Catching bare `Exception` in the controller. Throw a typed exception, handle it in `@RestControllerAdvice`.
- Wrapping every method in `ResponseEntity<T>` "just in case." Return `T` directly when the status is fixed.
- Business logic in controllers (validation chains, repository calls). If you see `repository.` in a controller, push it down.
- Calling `@Transactional` methods from within the same class — Spring's proxy-based AOP does not intercept self-calls.

## Pre-flight checklist

Before declaring a vertical slice done, verify:

- [ ] Request DTO has `@Valid` on the controller parameter and constraint annotations on each field
- [ ] Response DTO is distinct from the entity
- [ ] Service is `@Transactional` (writes) or `@Transactional(readOnly = true)` (reads)
- [ ] Domain exception is mapped in `@RestControllerAdvice`, not handled in the controller
- [ ] HTTP status is verb-appropriate: POST → 201, GET → 200, PUT/PATCH → 200, DELETE → 204, missing → 404
- [ ] Constructor injection only — no `@Autowired` fields
- [ ] No `ResponseEntity<T>` unless the status varies at runtime or custom headers are set
