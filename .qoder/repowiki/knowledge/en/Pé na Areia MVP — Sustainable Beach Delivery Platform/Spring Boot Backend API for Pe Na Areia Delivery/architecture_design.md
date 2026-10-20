Standard Spring Boot layered application under `com.penaareia`:
- `PeNaAreiaApplication` is the single `@SpringBootApplication` entry point.
- `config/` holds cross-cutting concerns: `SecurityConfig` (stateless filter chain, BCrypt password encoder, permissive routes pending JWT) and `GlobalExceptionHandler`.
- `controller/` (`KioskController`, `OrderController`, `ReferencePointController`) are thin REST endpoints annotated with Lombok's `@RequiredArgsConstructor` and SpringDoc `@Tag`/`@Operation`.
- `service/` contains business logic; `ResourceNotFoundException` is a domain exception used across services.
- `repository/` extends Spring Data MongoDB interfaces against `model/` entities.
- `model/` defines MongoDB documents (`@Document`) using Lombok (`@Data`, `@NoArgsConstructor`, `@AllArgsConstructor`) and Spring Data annotations (`@Id`, `@GeoSpatialIndexed` on `Order.pinCliente`).
- `dto/` carries request/response payloads decoupled from persistence models.
- `seed/ReferencePointSeeder` bootstraps initial data.
Dependency direction is strictly controller → service → repository → model; configuration and DTOs are consumed only at layer boundaries. External state lives in MongoDB Atlas via `spring.data.mongodb.uri` / `MONGODB_DATABASE` env vars, and JWT secret via `JWT_SECRET`.