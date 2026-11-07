---
name: penaareia-delivery-flow
description: >-
  Procedimento passo a passo para execução e validação do fluxo completo de pedido e entrega na praia do Pé na Areia,
  incluindo código numérico de 4 dígitos (PIN OTP), geofencing de 60m e avaliação de 1 a 5 estrelas.
---

# Skill: Fluxo de Entrega na Praia (PIN de 4 Dígitos & Geofencing)

Runbook detalhado para validação e execução do ciclo de vida de pedidos no Pé na Areia.

## Fluxo de Estados do Pedido
1. `PENDENTE_PAGAMENTO`: Pedido submetido pelo cliente com coordenadas na areia e ponto de referência.
2. `PAGO`: Pagamento Pix validado; o backend gera automaticamente o `codigoEntrega` de 4 dígitos numéricos exclusivo.
3. `EM_PREPARO`: O quiosque aceita e inicia a preparação das bebidas e porções.
4. `AGUARDANDO_ENTREGADOR`: O pedido fica pronto e é disponibilizado no mural de entregas da orla.
5. `A_CAMINHO`: Um entregador a pé aceita a entrega e inicia o deslocamento guiado pelo radar.
6. `ENTREGUE`: Ao se encontrar com o cliente, o entregador solicita o PIN, digita no app e confirma. O backend valida:
   - Coincidência do `codigoEntrega`.
   - Distância calculada $\le 60.0$ metros (fórmula Haversine via `distanceMeters`).
7. `AVALIADO`: O cliente submete a avaliação de 1 a 5 estrelas para a entrega e o pedido.

## Execução Automatizada do Teste E2E

Para validar todas as etapas do ciclo sem intervenção manual:
```powershell
node e2e/e2e_delivery_flow.mjs
```

### Contratos de API do Fluxo

#### Confirmação da Entrega pelo Entregador:
- **Endpoint:** `POST /orders/{id}/confirm-delivery`
- **Payload:**
  ```json
  {
    "courierId": "entregador-joao-123",
    "latitude": -23.972350,
    "longitude": -46.327120,
    "codigoEntrega": "4821"
  }
  ```

#### Avaliação pelo Cliente:
- **Endpoint:** `POST /orders/{id}/review`
- **Payload:**
  ```json
  {
    "rating": 5,
    "courierRating": 5,
    "comment": "Entrega rápida na barraca do Canal 3, caipirinha trincando de gelada!"
  }
  ```
