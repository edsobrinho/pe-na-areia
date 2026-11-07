# PÉ NA AREIA — PLANO DE NEGÓCIO E MODELOS DE SUCESSO

**Delivery Sustentável na Orla de Santos: MVP, Cases Internacionais e Estratégia de Expansão**

---

**Documento Consolidado**
Santos, SP • Outubro de 2026
Versão 3.0

---

## 1. RESUMO EXECUTIVO

### O Problema
A maioria dos apps de delivery exige endereço — e quem está na areia, no calçadão ou na ciclovia de Santos não tem um. Um endereço "não descreve a orla", e um cliente na areia se move, então um ponto fixo se torna obsoleto em minutos.

### A Solução
O **Pé na Areia** é um serviço de entrega sustentável (bike) cuja localização do cliente é fixada por geolocalização e ancorada em pontos de referência da orla (postos numerados, quiosques parceiros, bicicletários, rampas de acesso), sem necessidade de endereço tradicional.

### Os Diferenciais
- **Base proprietária de pontos validados em campo** (âncoras)
- **Baixo custo de última milha** em rotas curtas (bike)
- **Narrativa de sustentabilidade** (CO₂ evitado por pedido)
- **Identificação visual** (tela piscando) para encontro na areia

### O Modelo de Negócio
Múltiplas fontes de receita: comissão (15-20%), taxa de entrega (R$ 2-5), hubs de retirada, zonas de evento temporárias e licenciamento de API de pontos de referência.

---

## 2. O PROJETO: PÉ NA AREIA

### 2.1 Problema e Oportunidade

**Contexto do mercado:**
- A última milha representa ~60-70% do custo total de entrega em cidades densas
- A entrega em domicílio na Europa caiu de 66% para 54% em um ano, em favor de lockers e pontos de retirada
- O endereço fixo está perdendo centralidade

**Problema específico da orla:**
- Endereço não descreve a orla (areia, calçadão, ciclovia não têm numeração)
- Cliente na areia se move — ponto fixo se torna obsoleto em minutos
- Grandes apps têm alto custo de entrega para rotas curtas e não entregam "na areia"

### 2.2 Proposta de Valor

O **Pé na Areia** resolve o problema da entrega sem endereço através de:

1. **Geolocalização ancorada**: Pin no mapa + snap para ponto de referência mais próximo (até 120m)
2. **Identificação visual**: Tela do celular pisca com sinal visual para o entregador
3. **Pagamento antecipado**: 100% via Pix ou cartão (reduz risco operacional)
4. **Entrega sustentável**: Bikes elétricas + embalagem retornável

### 2.3 Público-Alvo

- **Banhistas e frequentadores da orla** (picos: verão, fins de semana, fim de tarde)
- **Ciclistas e corredores** na ciclovia — entrega em pontos da ciclovia
- **Moradores de Gonzaga, Boqueirão e Aparecida** que pedem "na porta" da orla
- **Eventos**: campeonatos de surf/vôlei, shows, Réveillon

### 2.4 Fluxo do MVP (6 Telas)

**Tela 1 — Abertura e Permissão**
- Consentimento LGPD em 2 toques
- Localização apenas em foreground
- Dados efêmeros com TTL de 24h

**Tela 2 — Escolha do Parceiro**
- Lista de quiosques/restaurantes ordenados por distância de bike na ciclovia
- Cada parceiro tem raio de atendimento de até 2km calculado por rota de bike (não linha reta)

**Tela 3 — Fixar Ponto de Entrega**
- Mapa com pin arrastável + chips de pontos de referência (Posto 5, quiosque parceiro, bicicletário, rampa)
- **Regra de snap**: se distância ≤ 120m, pedido herda a âncora; senão, fica "solto" com tag "sem referência"

**Tela 4 — Combina o Encontro**
- Âncora + descrição livre ("guarda-sol listrado azul, camisa verde") + foto opcional + check-in de proximidade
- **Tripla de localização**: âncora + descrição + foto (expira em 24h)
- **Geofence de 50m**: ao cruzar, cliente recebe push "olhe ao redor"
- Sinal visual (tela piscando) inspirado na Domino's Pinpoint

**Tela 5 — Rastreamento de Bike**
- Rota do entregador na ciclovia + timeline
- Atribuição ao entregador ativo mais próximo do parceiro na mesma zona
- Rastreamento WebSocket a cada 5s, suavizado e travado na rota de bike

**Tela 6 — Entrega e Ciclo**
- Confirmação, "pedir aqui de novo" (favorito por 7 dias), avaliação do encontro, CO₂ evitado

### 2.5 Diferenciais Competitivos

1. **Base de âncoras proprietária**: Postos, quiosques, bicicletários validados em campo
2. **Custo de última milha baixo**: Rotas curtas na orla, entrega por bike
3. **Sustentabilidade**: CO₂ evitado por pedido, embalagem retornável
4. **Identificação visual**: Tela piscando para encontro em praias lotadas

---

## 3. ANÁLISE DE CASES INTERNACIONAIS

### 3.1 Domino's Pinpoint Delivery (EUA, 2023) — O Case Mais Relevante

**O que é:** Sistema que permite pedir pizza de qualquer lugar sem endereço — praias, parques, eventos, canteiros de obras.

**Como funciona:**
- Cliente dropa um pin no mapa no app
- Tracking GPS em tempo real
- **"Visual signal"** — tela do celular pisca com logo da Domino's para ajudar o entregador a localizar o cliente
- Pagamento 100% antecipado (cartão)

**Resultados:**
- Primeira marca de "quick-service" nos EUA a oferecer delivery sem endereço
- "Seal of approval from customers" — aprovação dos clientes
- **Drive de downloads do app** — a experiência frictionless aumenta aquisição de usuários
- Funciona em mais de **150.000 hotspots** (pontos pré-cadastrados) — parques, praias, campos esportivos

**Lição para Pé na Areia:** O visual signal (tela piscando) é crucial para identificação em locais movimentados como praias. O modelo de hotspots pré-cadastrados aumenta a confiança do cliente.

**Referência:** [USA Today](https://www.usatoday.com/story/money/food/2023/06/20/dominos-pizzas-pinpoint-delivery-program/70339086007/), [Google Cloud](https://cloud.google.com/customers/dominos-maps)

---

### 3.2 what3words (Reino Unido) — Precisão sem Endereço

**O que é:** Divide o mundo em quadrados de 3x3 metros, cada um com um endereço único de 3 palavras (ex: "mesa.caderno.lapis").

**Como funciona:**
- Cliente compartilha as 3 palavras ao invés de endereço
- Precisão de 3x3m — suficiente para encontro
- Integrado com DHL, DPD, Aramex, etc.

**Resultados:**
- Reduz tempo de entrega e combustível gasto
- Elimina erros de endereço
- Usado em locais sem endereço formal (favelas, áreas rurais, eventos)

**Lição para Pé na Areia:** Considerar criar um sistema simples de "endereço" para o cliente comunicar ao entregador (ex: "Posto 5 + azul + guarda-sol listrado").

**Referência:** [what3words](https://what3words.com/business/what3words-enabled-logistics-carriers-and-software)

---

### 3.3 Curri (EUA) — Delivery em Obras e Eventos

**O que é:** Plataforma de delivery para canteiros de obras, eventos, áreas rurais — locais sem endereço no mapa.

**Como funciona:**
- Cliente dropa pin no mapa exato
- Driver navega direto para as coordenadas
- Foto de confirmação de entrega

**Resultados:**
- Resolve o problema de "endereço não existe ainda" (obras novas)
- Funciona em locais rurais com estradas sem nome

**Lição para Pé na Areia:** Focar em nichos específicos (eventos, Réveillon, campeonatos) como "zonas temporárias" é viável e lucrativo.

**Referência:** [Curri](https://www.curri.com/blog/delivery-without-an-address)

---

### 3.4 Picnic (Holanda) — Supermercado Online com Precisão

**O que é:** Supermercado online holandês que entrega de graça usando veículos elétricos compactos.

**Como funciona:**
- Modelo "**Milkman 2.0**" — entrega em janelas de tempo precisas (20 minutos)
- **Waitlist** — clientes entram em lista de espera mostrando demanda antes do lançamento na área
- Rastreamento do veículo em tempo real
- Frotas de veículos elétricos pequenos que entram em ruas estreitas

**Resultados:**
- Faturamento de €1,25 bilhão em 2023
- Expansão para Alemanha
- Sucesso com entrega gratuita + precisão

**Lição para Pé na Areia:** Implementar waitlist para construir demanda antes do lançamento em novas áreas. Foco em precisão de horário (ex: "entrega em 15 minutos").

**Referência:** [LinkedIn](https://www.linkedin.com/pulse/success-story-grocery-startup-picnic-wins-big-noakes-schulze-cxs)

---

### 3.5 Seattle E-Bike Pilot — Dados de Eficiência de Bikes

**O que é:** Piloto de 3 meses em Seattle usando e-cargo bikes para entregas de microhub.

**Resultados:**
- **30% redução em CO2** por pacote
- **50% menos milhas** percorridas vs. caminhões
- Bikes entregavam 8 pacotes/hora vs. 19 dos caminhões, mas milhas totais eram menores

**Lição para Pé na Areia:** Bikes são eficientes para última milha em áreas densas (como orla). Dados de CO2 evitado são ótimos para marketing/ESG.

**Referência:** [Fast Company](https://www.fastcompany.com/90686872/this-e-bike-delivery-experiment-reduced-co2-emissions-30-per-package)

---

### 3.6 Deliveroo (Reino Unido) — Delivery em Praia

**O que é:** Entrega de comida em praias do Reino Unido via **jet ski**.

**Resultados:**
- Iniciativa de marketing bem-sucedida
- Entregas em praias movimentadas

**Lição para Pé na Areia:** Entrega em praia é possível e tem demanda. O diferencial pode ser o meio (bike vs. jet ski).

**Referência:** [The Inertia](https://www.theinertia.com/business-media/a-uk-food-delivery-service-plans-to-bring-food-to-beachgoers-via-jet-ski/)

---

## 4. CASES BRASILEIROS RELEVANTES

### 4.1 Carbono Zero Courier (São Paulo)

**O que é:** Maior transportadora de entregas sustentáveis do Brasil.

**Dados:**
- 245 bikers + 10 pilotos de scooter + 3 de furgão elétrico
- Entregas em SP e região metropolitana
- Rastreamento em tempo real
- Integração com e-commerces

**Lição para Pé na Areia:** Modelo de frota mista (bike + scooter elétrica) é viável. Rastreamento em tempo real é esperado.

**Referência:** [Carbono Zero](https://carbonozero.com.br/)

---

### 4.2 James Delivery (Curitiba)

**O que é:** Startup de entrega com 600+ ciclistas.

**Dados:**
- Entregas sustentáveis com bicicletas
- Frota própria de ciclistas

**Lição para Pé na Areia:** Modelo de frota dedicada de ciclistas funciona no Brasil.

**Referência:** [James Delivery](https://jamesdelivery.com.br/)

---

### 4.3 iFood — Delivery em Quiosques

**O que é:** O iFood já fez parceria para entrega em quiosques na orla carioca.

**Dados:**
- Patrocínio de quiosques
- Delivery na praia

**Lição para Pé na Areia:** Existe demanda comprovada para delivery na praia no Brasil.

**Referência:** [iFood](https://institucional.ifood.com.br/releases/patrocinando-quiosques-e-com-delivery-na-praia-ifood-deixa-orla-carioca-mais-saborosa/)

---

## 5. MODELO DE NEGÓCIO ORLA.ENTREGA

### 5.1 Fontes de Receita

| Fonte | Como funciona |
|-------|---------------|
| **Comissão sobre pedido** | 15-20% do valor do pedido, cobrado do parceiro |
| **Taxa de entrega** | R$ 2-5 por corrida cobrada do cliente (rotas curtas, baixo custo de bike) |
| **Destaque mensal** | Opcional no início; depois R$ 50-100/mês por parceiro em destaque |
| **Hub de retirada** | Taxa fixa por pedido entregue em quiosque parceiro |
| **Licenciamento de âncoras (novo)** | API de pontos de referência para apps/eventos locais (Modelo 2) |
| **Zona de evento (novo)** | Taxa dinâmica + patrocínio no Réveillon, campeonatos, shows (Modelo 7) |

### 5.2 Estrutura de Custos

- **Desenvolvimento MVP/plugin** (maior custo inicial)
- **Operações:** seguro, manutenção de bikes, embalagem sustentável
- **Marketing local:** quiosques, eventos, ciclistas influentes
- **Infraestrutura:** servidores, SDK de mapas, push notifications (baixo volume no piloto)

### 5.3 Métricas de Sucesso (North Star)

- Taxa de encontro sem contato > 90%
- Tempo médio de entrega < 25 min no piloto
- Pedidos/dia por entregador > 8 para viabilidade
- Retenção mensal de clientes
- CO₂ evitado acumulado (ativo de marketing/ESG)

### 5.4 Go-to-Market

**Piloto (60-90 dias):** Trecho Gonzaga-Postos 3-6, 5-10 parceiros, 3-5 entregadores

**Métricas do piloto:** taxa de encontro sem contato > 90%; tempo médio de entrega < 25 min; retenção mensal; NPS do encontro

**Escala:** Boqueirão/Aparecida + eventos de inverno; depois replica em São Vicente, Guarujá, Rio

---

## 6. SUGESTÕES DE MELHORIAS BASEADAS NOS CASES

### 6.1 Expansão de Hotspots (inspirado na Domino's)

**Problema atual:** Postos de salva-vidas são bons, mas podem ser poucos.

**Sugestão:**
- Criar **150-200 "hotspots"** validados na orla (como Domino's fez nos EUA)
- Incluir: quiosques parceiros, escadas de acesso numeradas, pontos de ônibus, árvores marcantes, entradas de condomínios
- Mostrar no app: "Entregamos aqui ✅" — aumenta confiança

**Impacto:** Aumenta a área de cobertura percebida e real.

---

### 6.2 Sistema de "Endereço" Simples (inspirado no what3words)

**Problema atual:** Descrição textual pode ser confusa.

**Sugestão:**
- Criar sistema de **código curto** para cada ponto de referência
- Ex: "Posto 5 + Azul + Guarda-sol listrado"
- Ou: "P5-A3-GL" (Posto 5, Área 3, Guarda-sol Listra)

**Impacto:** Facilita comunicação entre cliente, entregador e suporte.

---

### 6.3 Waitlist por Bairro (inspirado no Picnic)

**Problema atual:** Lançamento pode ser arriscado sem demanda comprovada.

**Sugestão:**
- Antes de lançar em novo trecho (ex: Boqueirão), abrir **waitlist**
- Clientes se cadastram com email + localização aproximada
- Quando atingir 100 cadastros na área, lançar o serviço

**Impacto:** Valida demanda antes de investir. Construiu lista de leads.

---

### 6.4 Zonas de Evento Temporárias (inspirado no Curri + Modelo 7)

**Problema atual:** Sazonalidade de verão/inverno.

**Sugestão:**
- Criar **zonas de entrega temporárias** para eventos:
  - Réveillon: zona especial com preço dinâmico
  - Campeonatos de surf/vôlei: entrega nas arquibancadas
  - Shows na orla: entrega em pontos específicos
- Cobrar taxa de evento + patrocínio

**Impacto:** Receita extra em dias de pico. Modelo 7 do seu documento.

---

### 6.5 Microhubs nos Quiosques (Modelo 6)

**Problema atual:** Entregador percorre orla inteira.

**Sugestão:**
- Quiosques parceiros como **microhubs**
- Entregador fica baseado no quiosque, não percorre longas distâncias
- Cliente pode optar por "entrega no quiosque" (pickup) com desconto

**Impacto:** Reduz tempo de entrega. Cria receita extra para quiosque (taxa de hub).

---

### 6.6 Programa de Fidelidade com CO2 (inspirado no Seattle Pilot)

**Problema atual:** Sustentabilidade é diferencial, mas pode ser mais tangível.

**Sugestão:**
- Mostrar **"X gramas de CO2 evitados"** a cada entrega
- Programa de pontos: a cada 10 entregas, desconto de R$ 5
- Ranking de "guardiões da orla"

**Impacto:** Gamificação. Dados para marketing/ESG.

---

### 6.7 Visual Signal Aprimorado (inspirado na Domino's)

**Problema atual:** Tela piscando é boa, mas pode ser melhor.

**Sugestão:**
- Além da tela piscando, permitir:
  - Escolher **cor do sinal** (azul, verde, vermelho, amarelo)
  - Ícone customizado (ex: 🏖️, 🌴, 🌊)
  - Flash do flash do celular em padrão de morse (P-A = Pé na Areia)
- Som opcional (campainha personalizada)

**Impacto:** Facilita identificação em praias lotadas.

---

### 6.8 Integração com Apps Existentes (inspirado no what3words)

**Problema atual:** App próprio requer aquisição de usuários.

**Sugestão:**
- Criar **plugin/checkout** para quiosques/usar em apps existentes (iFood, Rappi)
- Ou: API de "pontos de referência da orla" para outros apps usarem

**Impacto:** Receita de licenciamento (Modelo 2 do seu documento). Menos fricção para adoção.

---

## 7. MODELOS DE NEGÓCIO MAIS PROMISSORES

### 7.1 Modelo 7 — Eventos Temporários (Réveillon, Campeonatos)

**O que é:** Criar zonas de entrega temporárias para eventos na orla.

**Como funciona:**
- Réveillon: zona especial com preço dinâmico + patrocínio
- Campeonatos de surf/vôlei: entrega nas arquibancadas
- Shows na orla: entrega em pontos específicos

**Receita:** Taxa de evento + patrocínio de marcas.

**Referência:** Curri (EUA) + eventos na orla.

---

### 7.2 Modelo 6 — Microhubs em Quiosques

**O que é:** Quiosques parceiros como pontos de retirada e base de entregadores.

**Como funciona:**
- Entregador fica baseado no quiosque
- Cliente pode optar por "entrega no quiosque" (pickup) com desconto
- Taxa fixa por pedido entregue no quiosque

**Receita:** Taxa de hub + eficiência operacional.

**Referência:** Modelo europeu de microhubs + lockers.

---

### 7.3 Modelo 2 — Licenciamento de API de Pontos de Referência

**O que é:** Licenciar a base de pontos de referência validados para outros apps.

**Como funciona:**
- API de "pontos de referência da orla" para outros apps usarem
- Cobrança por chamada ou por volume

**Receita:** Licenciamento B2B.

**Referência:** what3words (Reino Unido).

---

## 8. PLANO DE AÇÃO E PRÓXIMOS PASSOS

### Fase 1: Pilot (60-90 dias)

**Objetivo:** Validar modelo no trecho Gonzaga-Postos 3-6

**Ações:**
- Contratar 3-5 entregadores (bike)
- Fechar 5-10 parceiros (quiosques/restaurantes)
- Desenvolver MVP (app simples)
- Implementar waitlist para demonstrar demanda

**Métricas:**
- Taxa de encontro sem contato > 90%
- Tempo médio de entrega < 25 min
- Pedidos/dia por entregador > 8

---

### Fase 2: Expansão

**Objetivo:** Expandir para Boqueirão/Aparecida + eventos de inverno

**Ações:**
- Expandir para novos trechos da orla
- Implementar zonas de evento (Réveillon)
- Criar microhubs em quiosques

**Métricas:**
- Receita por entregador
- Retenção mensal de clientes
- NPS do encontro

---

### Fase 3: Escalada

**Objetivo:** Replicar em outras cidades (São Vicente, Guarujá, Rio)

**Ações:**
- Replicar modelo em outras orlas
- Implementar licenciamento de API (Modelo 2)
- Expandir zonas de evento (Modelo 7)

**Métricas:**
- Receita total
- Market share
- CO₂ evitado acumulado

---

## 9. CONCLUSÃO

O **Pé na Areia** está muito bem estruturado. As principais forças são:

✅ **Problema real:** Endereço não descreve a orla

✅ **Solução técnica:** Pin no mapa + pontos de referência validados

✅ **Diferencial sustentável:** Bike + embalagem retornável

✅ **Modelo de negócio:** Múltiplas fontes de receita (comissão, taxa, hubs, eventos, licenciamento)

### Recomendações Prioritárias:

1. **Implementar waitlist** antes do lançamento em novas áreas (Picnic)
2. **Criar visual signal robusto** (Domino's)
3. **Expandir hotspots** para 150-200 pontos (Domino's)
4. **Focar em eventos temporários** para sazonalidade (Curri)
5. **Programa de fidelidade com CO2** (Seattle Pilot)

### Modelos de Negócio Mais Promissores:

- **Modelo 7 (Eventos):** Réveillon, campeonatos — alta demanda, preço dinâmico
- **Modelo 6 (Microhubs):** Quiosques como pontos de retirada — receita extra, reduz last mile
- **Modelo 2 (Licenciamento):** API de pontos de referência para outros apps — receita recorrente

---

## REFERÊNCIAS

1. **Domino's Pinpoint Delivery** — USA Today: https://www.usatoday.com/story/money/food/2023/06/20/dominos-pizzas-pinpoint-delivery-program/70339086007/
2. **Domino's Hotspots** — Marketing Dive: https://www.marketingdive.com/news/technology-of-the-year-dominos-hotspots/541904/
3. **what3words Logistics** — https://what3words.com/business/what3words-enabled-logistics-carriers-and-software
4. **Curri Delivery without Address** — https://www.curri.com/blog/delivery-without-an-address
5. **Picnic Success Story** — LinkedIn: https://www.linkedin.com/pulse/success-story-grocery-startup-picnic-wins-big-noakes-schulze-cxs
6. **Seattle E-Bike Pilot** — Fast Company: https://www.fastcompany.com/90686872/this-e-bike-delivery-experiment-reduced-co2-emissions-30-per-package
7. **Deliveroo Beach Delivery** — The Inertia: https://www.theinertia.com/business-media/a-uk-food-delivery-service-plans-to-bring-food-to-beachgoers-via-jet-ski/
8. **Carbono Zero Courier** — https://carbonozero.com.br/
9. **James Delivery** — https://jamesdelivery.com.br/
10. **iFood Beach Delivery** — https://institucional.ifood.com.br/releases/patrocinando-quiosques-e-com-delivery-na-praia-ifood-deixa-orla-carioca-mais-saborosa/

---

**Documento elaborado em Outubro de 2026**
**Versão 3.0**
