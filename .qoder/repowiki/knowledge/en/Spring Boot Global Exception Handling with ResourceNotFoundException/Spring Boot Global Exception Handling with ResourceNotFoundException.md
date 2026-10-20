---
kind: error_handling
name: Spring Boot Global Exception Handling with ResourceNotFoundException
category: error_handling
scope:
    - '**'
source_files:
    - backend/src/main/java/com/penaareia/config/GlobalExceptionHandler.java
    - backend/src/main/java/com/penaareia/service/ResourceNotFoundException.java
    - backend/src/main/java/com/penaareia/service/OrderService.java
---

## Backend (Spring Boot)

The backend centralizes error handling through a single `@RestControllerAdvice` class and one domain-specific unchecked exception.

**Core types**
- `com.penaareia.service.ResourceNotFoundException extends RuntimeException` — the only custom exception in the codebase. It carries a Portuguese message string and is thrown from service methods when a kiosk, reference point, menu item, or order cannot be found.
- `com.penaareia.config.GlobalExceptionHandler` — the sole global error handler, annotated with `@RestControllerAdvice`, mapping exceptions to HTTP responses.

**Exception-to-HTTP mappings**
| Exception | HTTP status | Response body shape |
|---|---:|---|
| `ResourceNotFoundException` | `404 NOT_FOUND` | `{ timestamp, mensagem }` where `mensagem` is `ex.getMessage()` |
| `MethodArgumentNotValidException` (JSR-303 validation failures) | `400 BAD_REQUEST` | `{ timestamp, mensagem: "Dados invalidos", campos: { field: message, ... } }` |

The helper method `body(String mensagem)` builds the shared envelope containing an ISO-8601 `timestamp` (via `Instant.now().toString()`) and a Portuguese `mensagem` field. Validation errors additionally attach a `campos` map of field name → default message.

**Propagation pattern**
Service classes (e.g. `OrderService.criarPedido`, `OrderService.buscarPorId`) use `Optional.orElseThrow(() -> new ResourceNotFoundException(...))` and explicit `throw new ResourceNotFoundException(...)` for business-rule violations such as unavailable menu items. Controllers do not catch these; they bubble up to `GlobalExceptionHandler`. No other checked exceptions are caught at controller/service boundaries in the scanned files.

**No generic fallback**
`GlobalExceptionHandler` does not declare a catch-all `@ExceptionHandler(Exception.class)` handler, so unhandled exceptions will fall through to Spring's default `DefaultHandlerExceptionResolver` (typically producing a 500-style response). The repo has no custom error DTO class — responses are plain `Map<String, Object>` instances.

## Frontend (Flutter)

Error handling on the Flutter side is minimal and ad-hoc. A search for `catch (` in Dart sources finds two occurrences in `lib/screens/location_selection_screen.dart` (lines 59 and 79), which wrap location/geolocation calls in try/catch blocks that swallow the exception without surfacing it to the user. There is no centralized error service, no error model, and no HTTP error interceptor visible in the scanned tree.

## Conventions observed

- Custom application errors are represented by the single unchecked exception `ResourceNotFoundException`; checked exceptions are not used for domain errors.
- Service-layer code throws `ResourceNotFoundException` via `orElseThrow` lambdas rather than returning `Optional` to callers.
- All user-facing error messages are written in Portuguese (e.g. `"Quiosque nao encontrado"`, `"Posto de referencia nao encontrado"`, `"Item indisponivel no cardapio"`, `"Dados invalidos"`).
- API error envelopes always include a `timestamp` and a `mensagem` field; validation responses additionally include a `campos` map.
- Controllers never handle exceptions locally; all cross-cutting error translation is delegated to `GlobalExceptionHandler`.
- No panic/recover equivalent exists in Java; no `try/finally` resource cleanup patterns were observed around repository calls.