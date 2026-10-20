---
kind: configuration_system
name: Spring Boot + Flutter Configuration System
category: configuration_system
scope:
    - '**'
source_files:
    - backend/src/main/resources/application.yml
    - backend/src/main/java/com/penaareia/config/SecurityConfig.java
    - backend/pom.xml
    - frontend/pubspec.yaml
---

## Overview

The repository is a two-layer MVP (Spring Boot backend + Flutter frontend). The configuration system is split across the two layers:

- **Backend**: Spring Boot externalized configuration via `application.yml`, with environment-variable overrides for secrets and connection strings.
- **Frontend**: Minimal — no runtime config file; dependencies and SDK constraints live in `pubspec.yaml`.

There is no centralized feature-flag system, no `.env` files committed to source, and no secret manager integration yet.

---

## Backend: Spring Boot Externalized Configuration

### Primary configuration file

`backend/src/main/resources/application.yml` is the single source of truth for application settings. It defines:

| Section | Key(s) | Purpose |
|---|---|---|
| `server` | `port` | HTTP port (default `8080`) |
| `spring.application.name` | `pe-na-areia-backend` | Application name |
| `spring.data.mongodb.uri` | `${MONGODB_URI:...}` | MongoDB Atlas connection string |
| `spring.data.mongodb.database` | `${MONGODB_DATABASE:pe_na_areia}` | Database name |
| `spring.data.mongodb.auto-index-creation` | `true` | Auto-create indexes |
| `jwt.secret` | `${JWT_SECRET:troque-este-segredo-antes-de-ir-para-producao}` | JWT signing key |
| `jwt.expiration-ms` | `86400000` | Token TTL (24h) |
| `springdoc.swagger-ui.path` | `/docs` | Swagger UI path |
| `springdoc.api-docs.path` | `/api-docs` | OpenAPI JSON path |
| `app.delivery.confirmation-radius-meters` | `60` | Delivery confirmation radius in meters |

### Environment variable override convention

Every sensitive or deployment-specific value uses Spring's `${ENV_VAR:default}` placeholder syntax. The defaults are intentionally weak placeholders:

- `MONGODB_URI` defaults to a placeholder URI containing `<usuario>:<senha>@<cluster>.mongodb.net`.
- `MONGODB_DATABASE` defaults to `pe_na_areia`.
- `JWT_SECRET` defaults to the Portuguese warning `troque-este-segredo-antes-de-ir-para-producao`.

A comment in `application.yml` explicitly documents the intended override mechanism:

> "Crie a conta em https://www.mongodb.com/cloud/atlas/register e monte a connection string abaixo, ou use as variaveis de ambiente MONGODB_URI / MONGODB_DATABASE."

And a comment on the JWT secret says:

> "Nunca versione o secret real - defina via variavel de ambiente em producao" ("Never version the real secret — define it via environment variable in production").

### Security configuration

`backend/src/main/java/com/penaareia/config/SecurityConfig.java` declares security behavior as Spring beans:

- `PasswordEncoder` bean returns `BCryptPasswordEncoder`.
- `SecurityFilterChain` disables CSRF, sets `SessionCreationPolicy.STATELESS`, permits `/docs/**`, `/api-docs/**`, `/swagger-ui/**`, `/auth/**`, `/reference-points/**`, `/kiosks/**`, and currently leaves `anyRequest().permitAll()` as a TODO placeholder until JWT filtering is wired.

The class-level Javadoc states the intent: public catalog endpoints are open now, and the filter chain is ready for a JWT authentication filter once `/auth/login` and `/auth/register` are implemented.

### Dependency-driven configuration

`backend/pom.xml` pulls in the Spring Boot starters that bring their own auto-configured configuration properties:

- `spring-boot-starter-web` → server/web properties.
- `spring-boot-starter-data-mongodb` → `spring.data.mongodb.*`.
- `spring-boot-starter-security` → Spring Security defaults (overridden by `SecurityConfig`).
- `springdoc-openapi-starter-webmvc-ui` → `springdoc.*` properties.
- `io.jsonwebtoken` (jjwt-api/impl/jackson) → JWT library consumed by the app (the actual JWT filter is not yet present).

No custom `@ConfigurationProperties` class binds the `app.delivery.*` namespace — those values are read directly from the environment at runtime via Spring's standard property resolution.

---

## Frontend: Flutter Configuration

The Flutter side has no runtime configuration file. `frontend/pubspec.yaml` only declares:

- Package metadata (`name`, `description`, `version`).
- SDK constraint (`>=3.3.0 <4.0.0`).
- Runtime dependencies (`google_maps_flutter`, `geolocator`, `http`, `provider`, `image_picker`, `firebase_core`, `firebase_messaging`).
- Dev dependencies (`flutter_test`, `flutter_lints`).
- Asset declaration (`assets/` directory).

There is no `.env`, no `config.dart`, and no build-time constant generation visible in the tree. Platform-specific build configs exist under `frontend/macos/Runner/Configs/` (`AppInfo.xcconfig`, `Debug.xcconfig`, `Release.xcconfig`, `Warnings.xcconfig`) but they are Xcode project scaffolding, not application configuration.

---

## Architecture and Conventions Observed

1. **Single YAML entry point** — All backend configuration lives in one `application.yml`; there are no `application-{profile}.yml` profiles.
2. **Environment variables for secrets** — Sensitive values (`MONGODB_URI`, `MONGODB_DATABASE`, `JWT_SECRET`) are injected via `${VAR:default}`; defaults are non-functional placeholders meant to be replaced at deploy time.
3. **No `.env` files committed** — No `.env`, `.env.local`, or similar files appear in the tree; the repo relies on the host/container environment to supply values.
4. **Feature flags are absent** — There is no feature-flag framework or toggle system; behavior is controlled purely through static YAML keys (e.g., `app.delivery.confirmation-radius-meters`).
5. **Security config is code-only** — Spring Security rules are declared in Java (`SecurityConfig.java`) rather than in YAML.
6. **JWT is configured but not wired** — `jwt.secret` and `jwt.expiration-ms` are defined, and the jjwt dependency is present, but `SecurityConfig` still permits all requests (`anyRequest().permitAll()`) with a TODO to add `JwtAuthenticationFilter` before `UsernamePasswordAuthenticationFilter`.
7. **Frontend has no runtime config layer** — The Flutter app does not load environment variables or configuration files at runtime within the scope of this branch.

### Rules enforced by the codebase

- Secrets must be supplied via environment variables, not committed to source — enforced by the default placeholder values in `application.yml` and the explicit comment warning against versioning secrets.
- MongoDB credentials are expected in `MONGODB_URI` / `MONGODB_DATABASE` — documented in the `application.yml` comments and reflected in the `${...}` placeholders.
- Public API surfaces (`/docs/**`, `/api-docs/**`, `/swagger-ui/**`, `/auth/**`, `/reference-points/**`, `/kiosks/**`) are explicitly whitelisted in `SecurityConfig.filterChain`; everything else is currently permitted but marked with a TODO to become authenticated.