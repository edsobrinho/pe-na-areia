# PRD — Pé na Areia · v1.1 (Parcerias e regras por quiosque)

**Versão:** 1.1 (rascunho para validação)
**Base:** PRD v1.0, 17 de outubro de 2026
**Status:** Proposta

## 1. Mudança proposta

Na v1.0, o catálogo é global: o quiosque tem itens e preços, e todo pedido sai pelo mesmo canal. Esta versão permite que cada quiosque:

- escolha as **parcerias** (canais de venda) pelas quais quer receber pedidos;
- defina, para cada parceria, **quais produtos** vende;
- configure **filtros**, **política de taxas** e **restrições de pedido** próprias daquela parceria.

## 2. Conceitos

- **Parceria:** vínculo entre um quiosque e um canal de venda (ex.: app Pé na Areia, clube de praia, evento sazonal). Pode estar ativa ou pausada.
- **Oferta por parceria:** subconjunto dos produtos do cardápio habilitados naquela parceria.
- **Filtros:** critérios que restringem a oferta (categorias e somente embalagem retornável).
- **Política de taxas:** comissão da plataforma (%), taxa de entrega (R$) e quem a paga (cliente ou quiosque).
- **Restrições de pedido:** pedido mínimo, máximo de itens, janela de horário e tempo de preparo.

## 3. Premissas (a validar)

- "Parceiro" é tratado como **canal de venda**. A entrega continua com a operação Pé na Areia. Se o parceiro for um operador logístico, ver a seção 10.
- Surge o papel **`KIOSK_OPERATOR`**, vinculado a um quiosque. A v1.0 deixava a administração fora do app; esta versão exige ao menos uma tela de configuração. Isso amplia o escopo do MVP.
- Taxas e comissões são **calculadas e registradas** no servidor. Nenhuma cobrança é feita nesta versão: o pagamento continua fora do escopo.

## 4. Requisitos funcionais

- **RF-01** O quiosque vê as parcerias disponíveis e ativa ou pausa cada uma.
- **RF-02** Por parceria, o quiosque habilita ou desabilita produtos do próprio cardápio.
- **RF-03** Filtros por parceria: categorias (vazio significa todas) e "somente embalagem retornável".
- **RF-04** Política de taxas por parceria: comissão entre 0% e 30% (limite a confirmar), taxa de entrega maior ou igual a zero e pagador da taxa (`CLIENT` ou `KIOSK`).
- **RF-05** Restrições por parceria: pedido mínimo, máximo de itens, horário de início e fim para aceitar pedidos e tempo de preparo.
- **RF-06** O cliente escolhe a parceria ao pedir e só pode comprar produtos elegíveis nela. O pedido registra a parceria.
- **RF-07** Prévia com um pedido de exemplo, mostrando subtotal, comissão, valor pago pelo cliente e valor líquido do quiosque.
- **RF-08** Cada pedido grava um *snapshot* da parceria: percentuais, taxa, restrições e preços vigentes na criação.

## 5. Regras de negócio

- **RN-01** Um item só é vendável se o quiosque estiver ativo, o produto disponível, o produto habilitado na parceria, a parceria ativa e o item passar nos filtros.
- **RN-02** Parceria pausada não aceita novos pedidos. Pedidos em andamento continuam.
- **RN-03** Alterações de taxa, filtro ou restrição valem apenas para pedidos criados depois da alteração.
- **RN-04** O total é calculado no servidor: soma de preço do servidor × quantidade, mais a taxa de entrega quando o cliente a paga. Comissão e valor líquido do quiosque são calculados e gravados no pedido.
- **RN-05** O pedido é recusado, com mensagem clara, se: ficar abaixo do mínimo, ultrapassar o máximo de itens, estiver fora da janela de horário, a parceria estiver pausada ou houver item fora da oferta.
- **RN-06** Comissão fora do intervalo permitido e taxa negativa são rejeitadas na configuração.
- **RN-07** Quando o quiosque paga a taxa, ela é deduzida do valor líquido dele e não é cobrada do cliente.
- **RN-08** A janela de horário usa o fuso `America/Sao_Paulo`.

## 6. Modelo de dados (proposta MongoDB)

```
kiosks:              { _id, name, active, ownerUserId }
partnerships:        { _id, name, channel, active }          // catálogo global
kiosk_partnerships:  {
  _id, kioskId, partnershipId, active,
  commissionPercent, deliveryFee, deliveryFeePayer: "CLIENT" | "KIOSK",
  minimumOrder, maxItemsPerOrder, acceptFrom, acceptUntil, prepMinutes,
  filters: { categories: [], onlyReturnable: false },
  productIds: [ ... ]
}                                                           // índice único (kioskId, partnershipId)
orders: + partnershipId, pricingSnapshot {
  commissionPercent, deliveryFee, deliveryFeePayer,
  subtotal, commissionAmount, customerTotal, kioskNet
}
```

## 7. Endpoints (propostos)

| Método | Rota | Acesso | Descrição |
|---|---|---|---|
| GET | `/partnerships` | Público | Lista parcerias ativas |
| GET | `/kiosks/{id}/partnerships` | Público | Oferta por parceria: produtos elegíveis, taxa e restrições |
| GET | `/kiosk/me/partnerships` | KIOSK_OPERATOR | Configurações do quiosque do operador |
| PUT | `/kiosk/me/partnerships/{partnershipId}` | KIOSK_OPERATOR | Atualiza parceria, filtros, taxas e restrições |
| POST | `/orders` | CLIENT | Passa a exigir `partnershipId` |

`GET /kiosks` passa a aceitar `?partnershipId=`, para que o cardápio exibido já respeite a parceria escolhida.

## 8. Critérios de aceite

- Dada uma parceria pausada, quando o cliente tenta pedir por ela, então a API responde com erro de conflito e mensagem explicando o motivo.
- Ao desabilitar um produto em uma parceria, ele deixa de aparecer nela e continua disponível nas demais.
- Pedido abaixo do mínimo é rejeitado. O total ignora qualquer valor enviado pelo app.
- Alterar a taxa depois da criação não altera o pedido já existente (snapshot).
- A prévia do painel usa a mesma regra de cálculo do servidor e os dois resultados batem em testes automatizados.

## 9. Métricas adicionais

- Percentual de quiosques com ao menos duas parcerias ativas.
- Ticket médio por parceria.
- Taxa de pedidos recusados por restrição, como indicador de configuração mal feita.

## 10. Questões em aberto

1. O que exatamente é um "parceiro": canal de venda, operador logístico ou ambos?
2. Quem define o limite de comissão: a plataforma ou negociação caso a caso?
3. A taxa de entrega é fixa ou varia por distância, dentro do raio de 500 m do posto?
4. As restrições são livres para o quiosque ou dependem de aprovação da plataforma?
5. Alterações de configuração precisam de aprovação ou entram em vigor imediatamente?
6. Como a comissão será repassada (split no provedor de pagamento)? Depende da definição de pagamento, fora do MVP.

## 11. Impacto no roadmap

Esta versão não substitui a seção 10 do PRD v1.0. Ela acrescenta o papel `KIOSK_OPERATOR`, o painel de configuração por parceria e o cálculo de comissão no pedido. A cobrança real de comissão continua condicionada à definição do provedor de pagamento.
