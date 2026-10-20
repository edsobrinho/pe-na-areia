---
kind: external_dependency
name: MongoDB Atlas (free tier M0) as persistent store
slug: mongodb-atlas
category: external_dependency
category_hints:
    - vendor_identity
    - client_constraint
scope:
    - '**'
---

### MongoDB Atlas
- Role: cloud-hosted MongoDB database for the Spring Boot backend (`pe-na-areia-backend`).
- Integration point: `application.yml` via `spring.data.mongodb.uri` and `database`, both overridable by environment variables `MONGODB_URI` and `MONGODB_DATABASE`.
- Client constraint: free-tier M0 cluster; connection string must be supplied at runtime, not committed.
- Geo usage: backend models use GeoJSON coordinates `[longitude, latitude]`; geospatial queries are driven by Spring Data MongoDB `findByLocalizacaoNear`.
- Verify exact connection/geo query shapes against the official Spring Data MongoDB docs.