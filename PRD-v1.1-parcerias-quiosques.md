# PRD — Pé na Areia · v1.1 (Parcerias, Gestão de Cardápio com Fotos e Regras por Quiosque)

**Versão:** 1.1 (Consolidado na v2.0)  
**Base:** [PRD Principal v2.0](PRD.md)  
**Data de Atualização:** 28 de outubro de 2026  
**Status:** Implementado e Validado End-to-End

## 1. Resumo da Evolução

Na versão inicial (v1.0), o catálogo era estático no banco de dados e todo pedido saía por um único fluxo sem gestão pelo restaurante. A **v1.1** (consolidada na v2.0) permite que cada quiosque, por meio do perfil **`KIOSK_OPERATOR`** no Portal Web React:

1. **Gerencie seu próprio cardápio com fotos reais (`MenuManager`):**
   - Cadastre, edite e exclua itens do cardápio (`POST`, `PUT`, `DELETE /kiosk/me/menu`).
   - Faça upload de fotos dos produtos (`POST /uploads/menu-item-photo`) integradas ao Cloudinary (`pe-na-areia/cardapio`), exibidas tanto no Portal Web quanto no App Mobile Flutter (`fotoUrl`).
2. **Configure Canais de Parceria (`partnerships`):**
   - Escolha as **parcerias** (canais de venda) pelas quais quer receber pedidos.
   - Defina, para cada parceria, **quais produtos** vende (`productIds`).
   - Configure **filtros**, **política de taxas** e **restrições de pedido** próprias daquela parceria.
   - Simule em tempo real o repasse líquido com a calculadora integrada (`POST /kiosk/me/partnerships/{partnershipId}/preview`).

---

## 2. Conceitos do Domínio

- **Cardápio do Quiosque (`cardapio`):** Lista de produtos (`MenuItem`) pertencentes ao quiosque, contendo `id`, `nome`, `descricao`, `fotoUrl`, `preco`, `categoria`, `disponivel` e `embalagemRetornavel`.
- **Parceria (`Partnership`):** Vínculo entre um quiosque e um canal de venda (ex.: app Pé na Areia, clube de praia, evento sazonal). Pode estar ativa ou pausada globalmente pelo `ADMIN` e individualmente pelo `KIOSK_OPERATOR`.
- **Oferta por Parceria (`KioskPartnership`):** Subconjunto dos produtos do cardápio habilitados naquela parceria, combinado com taxas e restrições.
- **Filtros (`PartnershipFilters`):** Critérios que restringem a oferta (`categories` e `onlyReturnable`).
- **Política de Taxas:** Comissão da plataforma (`commissionPercent` de `0%` a `30%`), taxa de entrega (`deliveryFee >= 0`) e pagador da taxa (`CLIENT` ou `KIOSK`).
- **Restrições de Pedido:** Pedido mínimo (`minimumOrder`), máximo de unidades (`maxItemsPerOrder`), janela de horário (`acceptFrom` / `acceptUntil` em `America/Sao_Paulo`) e tempo estimado de preparo (`prepMinutes`).

---

## 3. Requisitos Funcionais Implementados

- **RF-01 (Gestão de Cardápio CRUD):** O operador do quiosque lista (`GET /kiosk/me/menu`), cria (`POST /kiosk/me/menu`), edita (`PUT /kiosk/me/menu/{itemId}`) e remove (`DELETE /kiosk/me/menu/{itemId}`) produtos do seu quiosque.
- **RF-02 (Upload de Fotos de Produtos):** O operador envia fotos JPEG/PNG/WebP de até 5 MB (`POST /uploads/menu-item-photo`), recebendo `secureUrl` do Cloudinary (ou container `cloudinary-mock` em Docker) para associar ao campo `fotoUrl` do item.
- **RF-03 (Ativação de Parcerias):** O quiosque vê as parcerias disponíveis e ativa ou pausa cada uma.
- **RF-04 (Seleção de Produtos por Canal):** Por parceria, o quiosque habilita ou desabilita produtos do próprio cardápio.
- **RF-05 (Filtros por Parceria):** Categorias (vazio significa todas) e flag "somente embalagem retornável".
- **RF-06 (Política de Taxas por Parceria):** Comissão entre `0%` e `30%`, taxa de entrega `>= 0` e pagador da taxa (`CLIENT` ou `KIOSK`).
- **RF-07 (Restrições Operacionais):** Pedido mínimo, máximo de itens, horário de início/fim para aceitar pedidos e tempo de preparo em minutos.
- **RF-08 (Compra Elegível pelo Cliente):** O cliente escolhe a parceria ao pedir (`GET /kiosks?partnershipId=`) e só pode comprar produtos elegíveis nela. O pedido registra `partnershipId`.
- **RF-09 (Simulador de Prévia):** Prévia com um pedido de exemplo (`POST /kiosk/me/partnerships/{partnershipId}/preview`), mostrando subtotal, comissão, valor pago pelo cliente e valor líquido do quiosque.
- **RF-10 (Snapshot Imutável):** Cada pedido grava um `pricingSnapshot` imutável da parceria contendo percentuais, taxa, pagador, subtotal, comissão, total do cliente e líquido do quiosque vigentes na criação.

---

## 4. Regras de Negócio Validadas no Servidor

- **RN-01:** Um item só é vendável se o quiosque estiver ativo, o produto disponível, o produto habilitado na parceria, a parceria ativa (globalmente e no quiosque) e o item passar nos filtros.
- **RN-02:** Parceria pausada não aceita novos pedidos (`422 Unprocessable Entity`). Pedidos em andamento continuam normalmente.
- **RN-03:** Alterações de preço no cardápio, taxa, filtro ou restrição valem apenas para pedidos criados depois da alteração.
- **RN-04:** O total é calculado exclusivamente no servidor: soma de `preço do servidor × quantidade`, mais a taxa de entrega quando `deliveryFeePayer == CLIENT`. Comissão e valor líquido do quiosque são calculados e gravados no pedido.
- **RN-05:** O pedido é recusado com mensagem clara se ficar abaixo do mínimo, ultrapassar o máximo de itens, estiver fora da janela de horário, a parceria estiver pausada ou houver item fora da oferta.
- **RN-06:** Comissão fora do intervalo `0%..30%` e taxa negativa são rejeitadas na configuração.
- **RN-07:** Quando o quiosque paga a taxa (`deliveryFeePayer == KIOSK`), ela é deduzida do valor líquido dele (`kioskNet`) e não é cobrada do cliente.
- **RN-08:** A janela de horário utiliza sempre o fuso `America/Sao_Paulo`.

---

## 5. Modelo de Dados no MongoDB

```javascript
// Coleção: kiosks
{
  _id: "kiosk-santos-1",
  nome: "Quiosque Sol & Mar",
  postoReferenciaId: "posto-4",
  ativo: true,
  aceitaEmbalagemSustentavel: true,
  cardapio: [
    {
      _id: "porcao-camarao",
      nome: "Porção de Camarão Empanado",
      descricao: "400g com molho tártaro",
      fotoUrl: "http://localhost:8099/pe-na-areia-local/image/upload/v1/pe-na-areia/cardapio/...",
      preco: NumberDecimal("64.90"),
      categoria: "Porções",
      disponivel: true,
      embalagemRetornavel: true
    }
  ]
}

// Coleção: partnerships (catálogo global)
{ _id: "pe-na-areia-app", name: "App Pé na Areia", channel: "APP", active: true }

// Coleção: kiosk_partnerships — índice único (kioskId, partnershipId)
{
  _id: "...",
  kioskId: "kiosk-santos-1",
  partnershipId: "pe-na-areia-app",
  active: true,
  commissionPercent: NumberDecimal("10.00"),
  deliveryFee: NumberDecimal("6.00"),
  deliveryFeePayer: "CLIENT", // "CLIENT" | "KIOSK"
  minimumOrder: NumberDecimal("20.00"),
  maxItemsPerOrder: 15,
  acceptFrom: "08:00",
  acceptUntil: "20:00",
  prepMinutes: 20,
  filters: { categories: [], onlyReturnable: false },
  productIds: ["agua-coco", "porcao-camarao"]
}
```

---

## 6. Endpoints de Cardápio, Parcerias e Administração

| Método | Rota | Acesso | Descrição |
| :--- | :--- | :--- | :--- |
| `GET` | `/partnerships` | Público | Lista parcerias globais ativas |
| `GET` | `/kiosks?partnershipId=` | Público | Lista quiosques ativos e cardápio filtrado pela parceria |
| `GET` | `/kiosks/{id}/partnerships` | Público | Lista ofertas por parceria: produtos elegíveis, taxa e restrições |
| `GET` | `/kiosk/me/menu` | `KIOSK_OPERATOR` | Lista todos os itens do cardápio do quiosque do operador |
| `POST` | `/kiosk/me/menu` | `KIOSK_OPERATOR` | Cadastra novo item no cardápio (com `fotoUrl` opcional) |
| `PUT` | `/kiosk/me/menu/{itemId}` | `KIOSK_OPERATOR` | Atualiza item existente do cardápio |
| `DELETE` | `/kiosk/me/menu/{itemId}` | `KIOSK_OPERATOR` | Remove item do cardápio do quiosque |
| `POST` | `/uploads/menu-item-photo` | `KIOSK_OPERATOR` | Faz upload da foto do produto para `pe-na-areia/cardapio` no Cloudinary |
| `GET` | `/kiosk/me/partnerships` | `KIOSK_OPERATOR` | Lista configurações de parcerias do quiosque do operador |
| `PUT` | `/kiosk/me/partnerships/{partnershipId}` | `KIOSK_OPERATOR` | Atualiza parceria, produtos, filtros, taxas e restrições |
| `POST` | `/kiosk/me/partnerships/{partnershipId}/preview` | `KIOSK_OPERATOR` | Simula subtotal, comissão, total do cliente e líquido do quiosque |
| `POST` | `/admin/partnerships` | `ADMIN` | Cria novo canal de parceria global |
| `PUT` | `/admin/partnerships/{partnershipId}` | `ADMIN` | Ativa ou pausa canal global |
| `PATCH` | `/admin/kiosk-operators` | `ADMIN` | Associa conta de usuário existente a um quiosque (`KIOSK_OPERATOR`) |
