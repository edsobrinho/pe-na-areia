---
name: penaareia-backend
description: >-
  Procedimentos para desenvolvimento, compilação, testes e execução do backend do Pé na Areia
  em Java 21, Spring Boot 3.3.4 e MongoDB (Replica Set rs0). Utilize quando criar ou alterar endpoints REST,
  serviços de domínio, repositórios MongoDB, fluxos de geofencing e métricas de quiosques.
---

# Skill: Backend Pé na Areia (Java 21 + Spring Boot 3.3 + MongoDB)

Instruções para desenvolvimento e manutenção da API REST do Pé na Areia.

## Pré-requisitos
- JDK 21 configurado (`java -version`).
- Docker em execução para os contêineres de suporte (MongoDB réplica `rs0` e Cloudinary Mock).

## Procedimento de Inicialização

1. Subir infraestrutura local:
   ```powershell
   docker compose up -d mongodb cloudinary-mock
   ```
2. Compilar e executar a aplicação:
   ```powershell
   cd backend
   ./gradlew bootRun
   ```
3. Acessar endpoints de documentação e saúde:
   - OpenAPI Swagger: `http://localhost:8080/swagger-ui.html`
   - Actuator Health: `http://localhost:8080/actuator/health`

## Padrões de Implementação

1. **DTOs com Records:** Toda entrada e saída da API deve ser definida como `record` imutável.
2. **Tratamento Centralizado de Exceções:** Utilize `@RestControllerAdvice` retornando `ProblemDetail` (RFC 9457).
3. **Injeção de Dependências:** Estritamente via construtor (sem `@Autowired` em campos).
4. **Geofencing:** A confirmação de entrega valida `distanceMeters <= 60.0` entre entregador e cliente.
5. **Máscara do Código:** O `codigoEntrega` de 4 dígitos deve ser mascarado como `"****"` para entregadores até que o pedido seja `ENTREGUE`.

## Testes e Cobertura (Mínimo 80%)

```powershell
cd backend
./gradlew test jacocoTestReport jacocoTestCoverageVerification
```
- Cobertura obrigatória de linhas $\ge$ 80% configurada no JaCoCo.
- Relatório em: `backend/build/reports/jacoco/test/html/index.html`.
