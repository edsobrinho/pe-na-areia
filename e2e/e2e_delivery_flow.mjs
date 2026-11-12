// =============================================================================
// Pé na Areia — Suíte de Testes Ponta a Ponta (E2E) — Ciclo Completo de Entrega
// =============================================================================
// Requisitos Cobertos:
//   R1. Confirmação de Entrega por PIN e Código Sequencial Diário (#0001-#9999)
//   R2. Chat em Tempo Real com Expiração por Status (PRONTO_ENTREGA -> ENTREGUE)
//   R3. Live Tracking e Rota em Tempo Real com Alerta de Proximidade (60m)
//   R4. Coleta Múltipla de até 5 Pedidos Próximos e Rejeição de Distância (>1km)
//   R5. Evidências Visuais e Integridade Operacional da Orla de Santos - SP
// =============================================================================

import { execFileSync } from 'node:child_process';

const BASE = process.env.API_BASE_URL || 'http://localhost:8080';
const MONGODB_CONTAINER = process.env.MONGODB_CONTAINER || 'pe-na-areia-e2e-mongodb';
const POSTO5_ID = '6acfd917f737c71df923a343';
const PONTA_PRAIA_ID = '6acfd917f737c71df923a344';
const KIOSK_ID = 'kiosk-santos-1';
const KIOSK_VIZINHO_ID = 'kiosk-santos-vizinho';
const KIOSK_DISTANT_ID = 'kiosk-santos-distant';
const PARTNERSHIP_ID = 'pe-na-areia-app';

// Coordenadas geográficas reais da Orla de Santos - SP
// Posto 5 (Gonzaga): lat -23.9689, lng -46.3336
// Ponto do Cliente na Areia: ~30m do Posto 5
const PIN = { latitude: -23.9691, longitude: -46.3334 };

function runMongoScript(script) {
  try {
    execFileSync('docker', [
      'exec', '-i', MONGODB_CONTAINER, 'mongosh', 'pe_na_areia', '--quiet',
    ], {
      input: script,
      stdio: ['pipe', 'pipe', 'inherit'],
    });
  } catch (err) {
    console.warn(`[WARN] runMongoScript via docker falhou: ${err.message}. Continuando testes HTTP...`);
  }
}

// -----------------------------------------------------------------------------
// Semeação dos Dados Base no MongoDB (Quiosques, Postos, Parcerias e Cardápios)
// -----------------------------------------------------------------------------
const seedScript = `
  db.reference_points.deleteMany({ _id: { $in: ["${POSTO5_ID}", "${PONTA_PRAIA_ID}"] } });
  db.reference_points.updateOne(
    { _id: ObjectId("${POSTO5_ID}") },
    {
      $set: {
        numero: 5,
        nome: "Posto 5",
        trecho: "Gonzaga",
        localizacao: { type: "Point", coordinates: [-46.3336, -23.9689] },
        ativo: true
      }
    },
    { upsert: true }
  );
  db.reference_points.updateOne(
    { _id: ObjectId("${PONTA_PRAIA_ID}") },
    {
      $set: {
        numero: 7,
        nome: "Posto 7",
        trecho: "Ponta da Praia",
        localizacao: { type: "Point", coordinates: [-46.3050, -23.9850] },
        ativo: true
      }
    },
    { upsert: true }
  );

  db.partnerships.updateOne(
    { _id: "${PARTNERSHIP_ID}" },
    {
      $set: {
        name: "Pé na Areia App",
        channel: "APP",
        active: true
      }
    },
    { upsert: true }
  );

  db.kiosks.deleteMany({ _id: { $in: ["${KIOSK_ID}", "${KIOSK_VIZINHO_ID}", "${KIOSK_DISTANT_ID}"] } });
  db.kiosk_partnerships.deleteMany({ kioskId: { $in: ["${KIOSK_ID}", "${KIOSK_VIZINHO_ID}", "${KIOSK_DISTANT_ID}"] } });

  db.kiosks.updateOne(
    { _id: "${KIOSK_ID}" },
    {
      $set: {
        nome: "Quiosque Pé na Areia",
        pontoReferenciaId: "${POSTO5_ID}",
        localizacao: { type: "Point", coordinates: [-46.3338, -23.9690] },
        aceitaEmbalagemSustentavel: true,
        ativo: true,
        destaquePopular: true,
        avaliacaoMedia: 4.9,
        cardapio: [
          { _id: "agua-coco", nome: "Água de Coco", descricao: "Coco gelado 500ml", preco: "12.00", disponivel: true, category: "Bebidas", returnablePackaging: true, fotoUrl: null, destaque: true },
          { _id: "pastel-camarao", nome: "Pastel de Camarão", descricao: "6 unidades", preco: "38.50", disponivel: true, category: "Porções", returnablePackaging: false, fotoUrl: null, destaque: true },
          { _id: "sundae", nome: "Sundae", descricao: "Chocolate", preco: "15.00", disponivel: true, category: "Sobremesas", returnablePackaging: false, fotoUrl: null, destaque: false },
          { _id: "item-agotado", nome: "Rabo de Tatu", descricao: "Fora do menu temporada", preco: "60.00", disponivel: false, category: "Outros", returnablePackaging: false, fotoUrl: null, destaque: false }
        ]
      }
    },
    { upsert: true }
  );

  db.kiosks.updateOne(
    { _id: "${KIOSK_VIZINHO_ID}" },
    {
      $set: {
        nome: "Quiosque Vizinho do Posto 5",
        pontoReferenciaId: "${POSTO5_ID}",
        localizacao: { type: "Point", coordinates: [-46.3325, -23.9705] },
        aceitaEmbalagemSustentavel: true,
        ativo: true,
        destaquePopular: false,
        avaliacaoMedia: 4.7,
        cardapio: [
          { _id: "acai-copo", nome: "Açaí no Copo 400ml", descricao: "Com granola", preco: "18.00", disponivel: true, category: "Açaí", returnablePackaging: false, fotoUrl: null, destaque: true }
        ]
      }
    },
    { upsert: true }
  );

  db.kiosks.updateOne(
    { _id: "${KIOSK_DISTANT_ID}" },
    {
      $set: {
        nome: "Quiosque Distante Ponta da Praia",
        pontoReferenciaId: "${PONTA_PRAIA_ID}",
        localizacao: { type: "Point", coordinates: [-46.3050, -23.9850] },
        aceitaEmbalagemSustentavel: false,
        ativo: true,
        destaquePopular: false,
        avaliacaoMedia: 4.5,
        cardapio: [
          { _id: "cerveja-lata", nome: "Cerveja Lata 350ml", descricao: "Gelada", preco: "8.00", disponivel: true, category: "Bebidas", returnablePackaging: false, fotoUrl: null, destaque: true }
        ]
      }
    },
    { upsert: true }
  );

  db.kiosk_partnerships.updateOne(
    { kioskId: "${KIOSK_ID}", partnershipId: "${PARTNERSHIP_ID}" },
    {
      $set: {
        active: true,
        commissionPercent: NumberDecimal("10.0"),
        deliveryFee: NumberDecimal("0.0"),
        deliveryFeePayer: "KIOSK",
        minimumOrder: NumberDecimal("20.0"),
        maxItemsPerOrder: 50,
        acceptFrom: "00:00:00",
        acceptUntil: "23:59:59",
        prepMinutes: 15,
        filters: { categories: [], onlyReturnable: false },
        productIds: ["agua-coco", "pastel-camarao", "sundae", "item-agotado"]
      }
    },
    { upsert: true }
  );

  db.kiosk_partnerships.updateOne(
    { kioskId: "${KIOSK_VIZINHO_ID}", partnershipId: "${PARTNERSHIP_ID}" },
    {
      $set: {
        active: true,
        commissionPercent: NumberDecimal("10.0"),
        deliveryFee: NumberDecimal("0.0"),
        deliveryFeePayer: "KIOSK",
        minimumOrder: NumberDecimal("20.0"),
        maxItemsPerOrder: 50,
        acceptFrom: "00:00:00",
        acceptUntil: "23:59:59",
        prepMinutes: 15,
        filters: { categories: [], onlyReturnable: false },
        productIds: ["acai-copo"]
      }
    },
    { upsert: true }
  );

  db.kiosk_partnerships.updateOne(
    { kioskId: "${KIOSK_DISTANT_ID}", partnershipId: "${PARTNERSHIP_ID}" },
    {
      $set: {
        active: true,
        commissionPercent: NumberDecimal("10.0"),
        deliveryFee: NumberDecimal("0.0"),
        deliveryFeePayer: "KIOSK",
        minimumOrder: NumberDecimal("20.0"),
        maxItemsPerOrder: 50,
        acceptFrom: "00:00:00",
        acceptUntil: "23:59:59",
        prepMinutes: 15,
        filters: { categories: [], onlyReturnable: false },
        productIds: ["cerveja-lata"]
      }
    },
    { upsert: true }
  );
`;
runMongoScript(seedScript);

async function waitForApi() {
  let lastError;
  for (let attempt = 0; attempt < 30; attempt++) {
    try {
      const response = await fetch(`${BASE}/auth/login`, { method: 'OPTIONS' });
      if (response.status < 500) return;
      lastError = new Error(`HTTP ${response.status}`);
    } catch (error) {
      lastError = error;
    }
    await new Promise(resolve => setTimeout(resolve, 1000));
  }
  throw new Error(`API não ficou pronta em 30 segundos: ${lastError}`);
}

await waitForApi();

// Contadores e métricas de execução categorizados
let pass = 0, fail = 0;
const failures = [];
const metrics = {
  r1_pin: { pass: 0, fail: 0 },
  r2_chat: { pass: 0, fail: 0 },
  r3_track: { pass: 0, fail: 0 },
  r4_batch: { pass: 0, fail: 0 },
  outros: { pass: 0, fail: 0 },
};

function check(name, cond, detail = '', category = 'outros') {
  if (cond) {
    pass++;
    metrics[category].pass++;
    console.log(`  \x1b[32m✔ PASS\x1b[0m ${name}`);
  } else {
    fail++;
    metrics[category].fail++;
    const errMsg = `${name}${detail ? ' -> ' + detail : ''}`;
    failures.push(errMsg);
    console.log(`  \x1b[31m✖ FAIL\x1b[0m ${errMsg}`);
  }
}

function device(label) {
  let token = null;
  return {
    get token() { return token; },
    set token(t) { token = t; },
    async call(method, path, body) {
      const res = await fetch(BASE + path, {
        method,
        headers: {
          'Content-Type': 'application/json',
          ...(token ? { Authorization: `Bearer ${token}` } : {}),
          'X-Device': label,
        },
        body: body ? JSON.stringify(body) : undefined,
      });
      let data = null;
      const text = await res.text();
      try { data = text ? JSON.parse(text) : null; } catch { data = text; }
      return { status: res.status, data };
    },
    async uploadFile(path, filename, buffer, mimeType = 'image/png') {
      const form = new FormData();
      form.append('file', new Blob([buffer], { type: mimeType }), filename);
      const res = await fetch(BASE + path, {
        method: 'POST',
        headers: {
          ...(token ? { Authorization: `Bearer ${token}` } : {}),
          'X-Device': label,
        },
        body: form,
      });
      let data = null;
      const text = await res.text();
      try { data = text ? JSON.parse(text) : null; } catch { data = text; }
      return { status: res.status, data };
    },
    async register(payload) {
      const r = await this.call('POST', '/auth/register', payload);
      if (r.status === 201 && r.data?.token) token = r.data.token;
      return r;
    },
    async login(payload) {
      const r = await this.call('POST', '/auth/login', payload);
      if (r.status === 200 && r.data?.token) token = r.data.token;
      return r;
    },
  };
}

const stamp = Date.now();
const aparecimentoA = device('aparelho-A-cliente');
const aparecimentoB = device('aparelho-B-entregador');
const aparelhoC = device('aparelho-C-entregador-2');
const aparelhoOp = device('painel-web-operador');

console.log('\n\x1b[1m\x1b[36m========================================================================\x1b[0m');
console.log('\x1b[1m\x1b[36m== it_01 Cadastro e sessão de cada aparelho (Cliente, Entregadores, Operador) ==\x1b[0m');
console.log('\x1b[1m\x1b[36m========================================================================\x1b[0m');

const preflightRes = await fetch(BASE + '/auth/login', {
  method: 'OPTIONS',
  headers: {
    Origin: 'http://localhost:58301',
    'Access-Control-Request-Method': 'POST',
    'Access-Control-Request-Headers': 'content-type,authorization',
  },
});
check('CORS Preflight OPTIONS /auth/login aceita portas locais do Flutter Web',
  preflightRes.status === 200 && preflightRes.headers.get('access-control-allow-origin') === 'http://localhost:58301',
  `status=${preflightRes.status} allow-origin=${preflightRes.headers.get('access-control-allow-origin')}`);

const regCliente = await aparecimentoA.register({
  name: 'Cliente E2E Santos', email: `cliente.e2e.${stamp}@exemplo.com`, phone: '13990000001',
  password: 'senha123', role: 'CLIENT',
});
check('Cliente registrado com HTTP 201', regCliente.status === 201, JSON.stringify(regCliente.data));
check('Cliente recebe userId + role CLIENT + token JWT', !!regCliente.data?.userId && regCliente.data?.role === 'CLIENT' && !!regCliente.data?.token);

const regCourier = await aparecimentoB.register({
  name: 'Entregador E2E Orla', email: `entregador.e2e.${stamp}@exemplo.com`, phone: '13990000002',
  password: 'senha123', role: 'COURIER', vehicle: 'BIKE',
});
check('Entregador 1 registrado com HTTP 201', regCourier.status === 201, JSON.stringify(regCourier.data));
check('Entregador recebe userId + role COURIER + token JWT', !!regCourier.data?.userId && regCourier.data?.role === 'COURIER' && !!regCourier.data?.token);

const regCourierC = await aparelhoC.register({
  name: 'Entregador C Alternativo', email: `entregador.c.e2e.${stamp}@exemplo.com`, phone: '13990000003',
  password: 'senha123', role: 'COURIER', vehicle: 'PE',
});
check('Segundo entregador (aparelho C) registrado com HTTP 201', regCourierC.status === 201);

const dupEmail = await aparecimentoA.register({
  name: 'Cliente E2E Clone', email: `cliente.e2e.${stamp}@exemplo.com`, phone: '13990000001',
  password: 'senha123', role: 'CLIENT',
});
check('E-mail duplicado rejeitado com HTTP 422', dupEmail.status === 422, JSON.stringify(dupEmail.data));

const loginCourier = await aparecimentoB.login({ email: `entregador.e2e.${stamp}@exemplo.com`, password: 'senha123' });
check('Login do entregador retorna mesmo userId', loginCourier.status === 200 && loginCourier.data?.userId === regCourier.data?.userId);

// Configuração do Operador do Quiosque
await aparelhoOp.register({
  name: 'Operador Quiosque Posto 5', email: `op.e2e.${stamp}@exemplo.com`, phone: '13990000099',
  password: 'senha123', role: 'CLIENT',
});
runMongoScript(`db.users.updateOne({ email: "op.e2e.${stamp}@exemplo.com" }, { $set: { role: "KIOSK_OPERATOR", kioskId: "kiosk-santos-1" } });`);
await aparelhoOp.login({ email: `op.e2e.${stamp}@exemplo.com`, password: 'senha123' });

console.log('\n\x1b[1m\x1b[36m== it_02 Configuração de Parceria, Vitrine e Auto-onboarding Web ==\x1b[0m');
const configPartnership = await aparelhoOp.call('PUT', `/kiosk/me/partnerships/${PARTNERSHIP_ID}`, {
  active: true, commissionPercent: 10, deliveryFee: 0, deliveryFeePayer: 'KIOSK',
  minimumOrder: 20, maxItemsPerOrder: 50, acceptFrom: '00:00:00', acceptUntil: '00:00:00',
  prepMinutes: 15, filters: { categories: [], onlyReturnable: false },
  productIds: ['agua-coco', 'pastel-camarao', 'sundae', 'item-agotado'],
});
check('Operador ativa parceria pe-na-areia-app via API REST (200)', configPartnership.status === 200 && configPartnership.data?.active === true);

const previewPartnership = await aparelhoOp.call('POST', `/kiosk/me/partnerships/${PARTNERSHIP_ID}/preview`, {
  items: [{ menuItemId: 'agua-coco', quantity: 2 }, { menuItemId: 'pastel-camarao', quantity: 1 }],
});
check('Simulador de Repasse do Quiosque em POST /kiosk/me/partnerships/{id}/preview (200)',
  previewPartnership.status === 200 && Number(previewPartnership.data?.subtotal) === 62.5 && Number(previewPartnership.data?.kioskNet) === 56.25);

const updateStorefront = await aparelhoOp.call('PUT', '/kiosk/me/storefront', {
  descricaoCurta: 'Porções de Frutos do Mar e Água de Coco no Posto 5',
  fotoCapaUrl: 'http://localhost:8099/pe-na-areia-local/image/upload/v1/capa-quiosque.png',
  logoUrl: 'http://localhost:8099/pe-na-areia-local/image/upload/v1/logo-quiosque.png',
  aceitaEmbalagemSustentavel: true, destaquePopular: true,
  cep: '11045-500', logradouro: 'Av. Vicente de Carvalho', numero: 'Quiosque 42',
  complemento: 'Calçadão em frente ao Canal 4', bairro: 'Boqueirão', cidade: 'Santos', uf: 'SP',
  pontoReferenciaId: POSTO5_ID,
});
check('Operador configura Vitrine e Endereço Tradicional do Quiosque via PUT /kiosk/me/storefront (200)',
  updateStorefront.status === 200 && updateStorefront.data?.destaquePopular === true && updateStorefront.data?.logradouro === 'Av. Vicente de Carvalho');

const novoParceiro = device('painel-web-novo-parceiro');
await novoParceiro.register({
  name: 'Parceiro Gonzaga', email: `parceiro.gonzaga.${stamp}@exemplo.com`, phone: '13990000088',
  password: 'senha123', role: 'CLIENT',
});
const onboardRes = await novoParceiro.call('POST', '/kiosk/me/onboarding', {
  nome: 'Restaurante Orla do Gonzaga', descricaoCurta: 'Peixes grelhados na areia',
  logoUrl: 'http://localhost:8099/pe-na-areia-local/image/upload/v1/logo-gonzaga.png',
  cep: '11060-001', logradouro: 'Av. Presidente Wilson', numero: '150', bairro: 'Gonzaga', cidade: 'Santos', uf: 'SP',
  pontoReferenciaId: POSTO5_ID,
});
check('Auto-cadastro de Restaurante via POST /kiosk/me/onboarding promove para KIOSK_OPERATOR (201)',
  onboardRes.status === 201 && onboardRes.data?.role === 'KIOSK_OPERATOR' && onboardRes.data?.kiosk?.nome === 'Restaurante Orla do Gonzaga');

console.log('\n\x1b[1m\x1b[36m== it_03 Catálogo e Vitrine no Aparelho do Cliente ==\x1b[0m');
const kiosks = await aparecimentoA.call('GET', '/kiosks');
check('Cliente consulta quiosques ativos em GET /kiosks (200)', kiosks.status === 200 && Array.isArray(kiosks.data) && kiosks.data.length > 0);
const kiosk = kiosks.data.find(k => k.id === KIOSK_ID);
check('Quiosque Pé na Areia visível com cardápio, fotos e destaquePopular',
  kiosk?.destaquePopular === true && kiosk?.cardapio?.length >= 4);

console.log('\n\x1b[1m\x1b[36m== it_04 Validações de Regras de Negócio na Criação do Pedido ==\x1b[0m');
const baseOrder = {
  userId: regCliente.data.userId,
  kioskId: KIOSK_ID,
  partnershipId: PARTNERSHIP_ID,
  formaPagamento: 'PIX',
  embalagemSustentavel: true,
  pinCliente: PIN,
  pontoReferenciaId: POSTO5_ID,
  descricaoLocal: 'Guarda-sol listrado azul, 20 m da faixa de água',
  referenciaBarraca: 'Guarda-sol listrado azul com 2 cadeiras brancas',
  complementoLocal: 'Em frente à rede de futevôlei',
  contatoNome: 'Cliente E2E Praia',
  contatoTelefone: '+55 (13) 99000-0001',
  etiquetaLocal: 'MEU_GUARDA_SOL',
};

const denyOtherUser = await aparecimentoA.call('POST', '/orders', { ...baseOrder, userId: 'outro-user-id', itens: [{ menuItemId: 'agua-coco', quantidade: 1 }] });
check('Pedido criado para outro usuário é negado (422)', denyOtherUser.status === 422);

const unavailable = await aparecimentoA.call('POST', '/orders', { ...baseOrder, itens: [{ menuItemId: 'item-agotado', quantidade: 1 }] });
check('Item esgotado no cardápio é negado (422)', unavailable.status === 422);

const belowMinimum = await aparecimentoA.call('POST', '/orders', { ...baseOrder, itens: [{ menuItemId: 'agua-coco', quantidade: 1 }] });
check('Pedido abaixo do valor mínimo da parceria (R$ 12 < R$ 20) é negado (422)', belowMinimum.status === 422);

console.log('\n\x1b[1m\x1b[36m== it_05 Upload de Fotos de Localização na Areia (Cloudinary Mock) ==\x1b[0m');
const validPngBuffer = Buffer.from(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
  'base64',
);
const uploadLocalRes = await aparecimentoA.uploadFile('/uploads/location-photo', 'guarda-sol.png', validPngBuffer, 'image/png');
const uploadVisaoPostoRes = await aparecimentoA.uploadFile('/uploads/location-photo', 'visao-posto.png', validPngBuffer, 'image/png');
check('Upload de fotos do Ponto na Praia (Guarda-sol e Visão do Posto) retorna secureUrl (200)',
  uploadLocalRes.status === 200 && !!uploadLocalRes.data?.secureUrl && uploadVisaoPostoRes.status === 200 && !!uploadVisaoPostoRes.data?.secureUrl);

console.log('\n\x1b[1m\x1b[36m== it_06 [R1] Criação de Pedido: Sequencial Diário (#0001) e PIN Desacoplado ==\x1b[0m');
const createOrder = await aparecimentoA.call('POST', '/orders', {
  ...baseOrder,
  fotoLocalUrl: uploadLocalRes.data.secureUrl,
  fotoVisaoPostoUrl: uploadVisaoPostoRes.data.secureUrl,
  itens: [
    { menuItemId: 'agua-coco', quantidade: 2 },
    { menuItemId: 'pastel-camarao', quantidade: 1 },
  ],
});
check('Pedido principal criado com HTTP 201', createOrder.status === 201, JSON.stringify(createOrder.data), 'r1_pin');
const order = createOrder.data || {};
const orderId = order.id;

// Verificação do Código Sequencial Diário formatado (#0001 a #9999) e número diário
check('Pedido recebe identificador sequencial diário formatado (#0001 a #9999) [R1]',
  typeof order.codigoPedido === 'string' && /^#\d{4}$/.test(order.codigoPedido),
  `codigoPedido=${order.codigoPedido}`, 'r1_pin');
check('Pedido possui número sequencial diário inteiro positivo (>= 1) [R1]',
  typeof order.numeroPedidoDiario === 'number' && order.numeroPedidoDiario >= 1,
  `numeroPedidoDiario=${order.numeroPedidoDiario}`, 'r1_pin');

// Verificação do PIN de confirmação de 4 dígitos (exclusivo para validação na areia)
const clientPin = order.codigoEntrega;
check('Cliente recebe código PIN de 4 dígitos exclusivo para confirmação na areia [R1]',
  typeof clientPin === 'string' && /^\d{4}$/.test(clientPin),
  `clientPin=${clientPin}`, 'r1_pin');

// Desacoplamento estrito entre o Identificador Sequencial e o PIN
check('Identificador Sequencial do pedido é COMPLETAMENTE DESVINCULADO do PIN verbal [R1]',
  order.codigoPedido !== clientPin && !order.codigoPedido?.includes(clientPin),
  `codigoPedido=${order.codigoPedido} vs clientPin=${clientPin}`, 'r1_pin');

// Confirmação do pagamento Pix via Webhook autenticado
const webhookPix = await fetch(BASE + '/webhooks/pix', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-Pix-Webhook-Token': process.env.PIX_WEBHOOK_TOKEN || 'dev-pix-webhook-token-secret-12345',
  },
  body: JSON.stringify({ txId: order.pixTxId, orderId: order.id, status: 'CONCLUIDA' }),
});
const webhookData = await webhookPix.json();
check('Webhook Pix confirma pagamento e transiciona para EM_PREPARO (200)',
  webhookPix.status === 200 && webhookData?.status === 'EM_PREPARO' && webhookData?.pago === true);

console.log('\n\x1b[1m\x1b[36m== it_07 [R1 & R2] Mascaramento Rigoroso do PIN e Chat em PRONTO_ENTREGA ==\x1b[0m');
// 1. Operador libera para PRONTO_ENTREGA
const markReady = await aparelhoOp.call('PATCH', `/orders/${orderId}/status`, { status: 'PRONTO_ENTREGA' });
check('Operador marca pedido como PRONTO_ENTREGA (200)', markReady.status === 200 && markReady.data?.status === 'PRONTO_ENTREGA');

// [R2] Chat ativo em PRONTO_ENTREGA: Cliente envia mensagem no chat antes do aceite pelo entregador
const msgReadyClient = await aparecimentoA.call('POST', `/orders/${orderId}/messages`, {
  texto: 'Pedido pronto no quiosque! Estou no aguardo na areia em frente à rede de futevôlei.',
});
check('Cliente envia mensagem no chat enquanto pedido está em PRONTO_ENTREGA (200) [R2]',
  msgReadyClient.status === 200 && Array.isArray(msgReadyClient.data?.mensagens) && msgReadyClient.data.mensagens.length >= 1 && msgReadyClient.data?.chatAtivo === true,
  `status=${msgReadyClient.status} mensagens=${msgReadyClient.data?.mensagens?.length}`, 'r2_chat');

// 2. Entregador lista pedidos disponíveis — PIN NÃO pode constar na resposta
const availableOrders = await aparecimentoB.call('GET', '/orders/available');
check('Entregador lista pedidos disponíveis em GET /orders/available (200)',
  availableOrders.status === 200 && Array.isArray(availableOrders.data));
const orderInAvailable = availableOrders.data?.find(o => o.id === orderId);
check('Pedido disponível localizado na listagem do entregador',
  !!orderInAvailable,
  `orderId=${orderId}`, 'r1_pin');
check('PIN de entrega é estritamente MASCARADO (null/omitido) em /orders/available [R1]',
  !!orderInAvailable && orderInAvailable.codigoEntrega == null,
  `codigoEntrega=${orderInAvailable?.codigoEntrega}`, 'r1_pin');
check('Pedido em /orders/available exibe código sequencial diário (#0001 a #9999) [R1]',
  !!orderInAvailable && typeof orderInAvailable.codigoPedido === 'string' && /^#\d{4}$/.test(orderInAvailable.codigoPedido),
  `codigoPedido=${orderInAvailable?.codigoPedido}`, 'r1_pin');

// 3. Entregador aceita pedido — PIN NÃO pode constar no payload de retorno
const acceptRes = await aparecimentoB.call('PATCH', `/orders/${orderId}/status`, { status: 'A_CAMINHO' });
check('Entregador aceita pedido e transiciona para A_CAMINHO (200)',
  acceptRes.status === 200 && acceptRes.data?.status === 'A_CAMINHO' && acceptRes.data?.courierId === regCourier.data.userId);
check('PIN de confirmação é estritamente MASCARADO no retorno de aceite do entregador [R1]',
  acceptRes.status === 200 && acceptRes.data?.codigoEntrega == null,
  `codigoEntrega=${acceptRes.data?.codigoEntrega}`, 'r1_pin');
check('Retorno de aceite exibe identificador sequencial no padrão #0001 [R1]',
  acceptRes.status === 200 && typeof acceptRes.data?.codigoPedido === 'string' && /^#\d{4}$/.test(acceptRes.data?.codigoPedido),
  `codigoPedido=${acceptRes.data?.codigoPedido}`, 'r1_pin');

// 4. Entregador consulta entregas em rota ativa — PIN continua mascarado
const activeOrders = await aparecimentoB.call('GET', '/orders/courier/active');
const courierActiveView = activeOrders.data?.find(o => o.id === orderId);
check('Pedido ativo localizado na listagem em rota do entregador',
  !!courierActiveView,
  `orderId=${orderId}`, 'r1_pin');
check('PIN de confirmação é estritamente MASCARADO na rota ativa /orders/courier/active [R1]',
  !!courierActiveView && courierActiveView.codigoEntrega == null,
  `codigoEntrega=${courierActiveView?.codigoEntrega}`, 'r1_pin');
check('Pedido em rota ativa exibe identificador sequencial no padrão #0001 [R1]',
  !!courierActiveView && typeof courierActiveView.codigoPedido === 'string' && /^#\d{4}$/.test(courierActiveView.codigoPedido),
  `codigoPedido=${courierActiveView?.codigoPedido}`, 'r1_pin');

// 5. Entregador consulta pedido individual via GET /orders/{id} — PIN continua mascarado
const courierSingleView = await aparecimentoB.call('GET', `/orders/${orderId}`);
check('PIN é estritamente MASCARADO quando entregador consulta GET /orders/{id} em rota [R1]',
  courierSingleView.status === 200 && courierSingleView.data?.codigoEntrega == null,
  `codigoEntrega=${courierSingleView.data?.codigoEntrega}`, 'r1_pin');
check('Consulta individual pelo entregador exibe identificador sequencial (#0001) [R1]',
  courierSingleView.status === 200 && typeof courierSingleView.data?.codigoPedido === 'string' && /^#\d{4}$/.test(courierSingleView.data?.codigoPedido),
  `codigoPedido=${courierSingleView.data?.codigoPedido}`, 'r1_pin');

// 6. Cliente consulta pedido individual — Cliente TEM acesso ao PIN verbal dele
const clientSingleView = await aparecimentoA.call('GET', `/orders/${orderId}`);
check('Cliente tem acesso legítimo ao PIN verbal de 4 dígitos em GET /orders/{id} [R1]',
  clientSingleView.status === 200 && clientSingleView.data?.codigoEntrega === clientPin,
  `codigoEntrega=${clientSingleView.data?.codigoEntrega}`, 'r1_pin');

console.log('\n\x1b[1m\x1b[36m== it_08 [R2] Ciclo de Vida do Chat em Tempo Real e Expiração por Status ==\x1b[0m');
// 1. Mensagem em A_CAMINHO (Permitido)
const msgCourier1 = await aparecimentoB.call('POST', `/orders/${orderId}/messages`, {
  texto: 'Estou retirando o pedido no quiosque e descendo para a praia!',
});
check('Entregador envia mensagem com pedido em A_CAMINHO (200) [R2]',
  msgCourier1.status === 200 && msgCourier1.data?.mensagens?.length >= 2,
  `status=${msgCourier1.status}`, 'r2_chat');

const msgCliente1 = await aparecimentoA.call('POST', `/orders/${orderId}/messages`, {
  texto: 'Perfeito! Estou no guarda-sol listrado azul com duas cadeiras brancas.',
});
check('Cliente responde no chat com pedido em A_CAMINHO (200) [R2]',
  msgCliente1.status === 200 && msgCliente1.data?.mensagens?.length >= 3,
  `status=${msgCliente1.status}`, 'r2_chat');

// 2. Chat com pedido em CANCELADO (Bloqueado)
const orderCancelRes = await aparecimentoA.call('POST', '/orders', {
  ...baseOrder,
  itens: [{ menuItemId: 'sundae', quantidade: 2 }],
  descricaoLocal: 'Cancelamento para teste de chat',
});
const cancelOrderId = orderCancelRes.data?.id;
await aparecimentoA.call('PATCH', `/orders/${cancelOrderId}/status`, { status: 'CANCELADO' });

const msgCancelledRes = await aparecimentoA.call('POST', `/orders/${cancelOrderId}/messages`, {
  texto: 'Tentando enviar mensagem em pedido cancelado',
});
check('Envio de mensagem em pedido CANCELADO é imediatamente BLOQUEADO com HTTP 422 (Chat expirado) [R2]',
  msgCancelledRes.status === 422 && (msgCancelledRes.data?.mensagem || msgCancelledRes.data?.detail || '').includes('Chat expirado'),
  `status=${msgCancelledRes.status} body=${JSON.stringify(msgCancelledRes.data)}`, 'r2_chat');

console.log('\n\x1b[1m\x1b[36m== it_09 [R3] Telemetria de Rota em Tempo Real e Alerta de Proximidade (60m) ==\x1b[0m');
// 1. Atualização GPS longe (>60m)
const gpsFar = await aparecimentoB.call('PATCH', `/orders/${orderId}/courier-location`, {
  latitude: PIN.latitude + 0.0020, // ~220m de distância
  longitude: PIN.longitude,
});
check('Entregador atualiza telemetria GPS a >60m da praia (200) [R3]',
  gpsFar.status === 200 && gpsFar.data?.alertaProximidadeEnviado === false,
  `alerta=${gpsFar.data?.alertaProximidadeEnviado}`, 'r3_track');
check('Telemetria atualizada oculta o PIN para o entregador [R1]',
  gpsFar.status === 200 && gpsFar.data?.codigoEntrega == null,
  `codigoEntrega=${gpsFar.data?.codigoEntrega}`, 'r1_pin');

// 2. Atualização GPS dentro do raio de 60m (Dispara alerta de proximidade e farol)
const gpsClose = await aparecimentoB.call('PATCH', `/orders/${orderId}/courier-location`, {
  latitude: PIN.latitude + 0.0002, // ~22m de distância da barraca do cliente
  longitude: PIN.longitude,
});
check('Entregador atinge raio <=60m e sistema dispara alerta de proximidade na areia (200) [R3]',
  gpsClose.status === 200 && gpsClose.data?.alertaProximidadeEnviado === true,
  `alerta=${gpsClose.data?.alertaProximidadeEnviado}`, 'r3_track');

// 3. Cliente consulta telemetria do entregador para desenhar Polyline de rota
const trackView = await aparecimentoA.call('GET', `/orders/${orderId}`);
check('Cliente obtém coordenadas GPS atualizadas do entregador para traçado de rota em tempo real [R3]',
  trackView.status === 200 && !!trackView.data?.localizacaoEntregador?.coordinates,
  `coords=${JSON.stringify(trackView.data?.localizacaoEntregador)}`, 'r3_track');

console.log('\n\x1b[1m\x1b[36m== it_10 [R1 & R2] Chegada na Praia, Validação de PIN verbal e Expiração de Chat ==\x1b[0m');
// Entregador marca chegada no ponto de encontro
const arrive = await aparecimentoB.call('PATCH', `/orders/${orderId}/status`, { status: 'CHEGOU_NO_LOCAL' });
check('Entregador transiciona pedido para CHEGOU_NO_LOCAL (200)',
  arrive.status === 200 && arrive.data?.status === 'CHEGOU_NO_LOCAL');

// Chat ainda é permitido enquanto entregador aguarda cliente
const msgArrived = await aparecimentoB.call('POST', `/orders/${orderId}/messages`, {
  texto: 'Cheguei ao lado da rede de futevôlei! Sinalizador laranja avistado.',
});
check('Chat permanece ATIVO durante CHEGOU_NO_LOCAL (200) [R2]',
  msgArrived.status === 200 && msgArrived.data?.mensagens?.length >= 4,
  `status=${msgArrived.status}`, 'r2_chat');

// Tentativa de confirmação com PIN INCORRETO (verbalizado errado)
const wrongPin = clientPin === '0000' ? '9999' : '0000';
const wrongPinRes = await aparecimentoB.call('POST', `/orders/${orderId}/confirm-delivery`, {
  courierId: regCourier.data.userId,
  codigoEntrega: wrongPin, // PIN dinamicamente inválido
  courierLocation: { lat: PIN.latitude + 0.00005, lng: PIN.longitude },
});
check('Confirmação com PIN INCORRETO é REJEITADA com HTTP 422 (Código inválido) [R1]',
  wrongPinRes.status === 422 && (wrongPinRes.data?.mensagem || wrongPinRes.data?.detail || '').includes('Código de confirmação de entrega inválido'),
  `status=${wrongPinRes.status} body=${JSON.stringify(wrongPinRes.data)}`, 'r1_pin');

// Tentativa de confirmação com PIN CORRETO, mas com GPS FORA DO RAIO (>60m)
const tooFarRes = await aparecimentoB.call('POST', `/orders/${orderId}/confirm-delivery`, {
  courierId: regCourier.data.userId,
  codigoEntrega: clientPin,
  courierLocation: { lat: PIN.latitude + 0.0015, lng: PIN.longitude }, // ~165m do cliente
});
check('Confirmação com PIN correto porém GPS > 60m é REJEITADA com HTTP 422 (Aproxime-se do pin) [R1]',
  tooFarRes.status === 422 && (tooFarRes.data?.mensagem || tooFarRes.data?.detail || '').includes('Aproxime-se do pin do cliente'),
  `status=${tooFarRes.status} body=${JSON.stringify(tooFarRes.data)}`, 'r1_pin');

// Confirmação VÁLIDA: PIN falado pelo cliente correto + GPS dentro de 60m (5m)
const confirmRes = await aparecimentoB.call('POST', `/orders/${orderId}/confirm-delivery`, {
  courierId: regCourier.data.userId,
  codigoEntrega: clientPin,
  courierLocation: { lat: PIN.latitude + 0.00005, lng: PIN.longitude }, // ~5m do cliente
});
check('Confirmação com PIN CORRETO e GPS <= 60m é APROVADA e transiciona para ENTREGUE (200) [R1]',
  confirmRes.status === 200 && confirmRes.data?.status === 'ENTREGUE',
  `status=${confirmRes.status}`, 'r1_pin');
check('PIN de entrega é DESMASCARADO para o entregador após transição confirmada para ENTREGUE [R1]',
  confirmRes.status === 200 && confirmRes.data?.codigoEntrega === clientPin,
  `codigoEntrega=${confirmRes.data?.codigoEntrega} vs clientPin=${clientPin}`, 'r1_pin');

// Verificação de Expiração Imediata do Chat após status ENTREGUE
const msgAfterDelivered = await aparecimentoA.call('POST', `/orders/${orderId}/messages`, {
  texto: 'Obrigado pela entrega gelada na areia!',
});
check('Envio de mensagem após status ENTREGUE é BLOQUEADO com HTTP 422 (Chat expirado) [R2]',
  msgAfterDelivered.status === 422 && (msgAfterDelivered.data?.mensagem || msgAfterDelivered.data?.detail || '').includes('Chat expirado'),
  `status=${msgAfterDelivered.status} body=${JSON.stringify(msgAfterDelivered.data)}`, 'r2_chat');

console.log('\n\x1b[1m\x1b[36m== it_11 [R3 & R4] Coleta Múltipla (até 5 pedidos), Quiosques Vizinhos e Telemetria Agregada ==\x1b[0m');

// 1. Criação e aceite do 1º pedido ativo no Quiosque Principal (Posto 5)
const orderBatch1Res = await aparecimentoA.call('POST', '/orders', {
  ...baseOrder,
  kioskId: KIOSK_ID,
  descricaoLocal: 'Pedido lote 1 - Quiosque Posto 5',
  itens: [{ menuItemId: 'agua-coco', quantidade: 2 }],
});
const orderBatch1Id = orderBatch1Res.data?.id;
await fetch(BASE + '/webhooks/pix', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json', 'X-Pix-Webhook-Token': 'dev-pix-webhook-token-secret-12345' },
  body: JSON.stringify({ txId: orderBatch1Res.data?.pixTxId, orderId: orderBatch1Id, status: 'CONCLUIDA' }),
});
await aparelhoOp.call('PATCH', `/orders/${orderBatch1Id}/status`, { status: 'PRONTO_ENTREGA' });

// Entregador B aceita o Pedido 1 (agora possui exatamente 1 pedido ativo)
const acceptBatch1 = await aparecimentoB.call('PATCH', `/orders/${orderBatch1Id}/status`, { status: 'A_CAMINHO' });
check('Entregador aceita 1º pedido ativo do lote no Quiosque Posto 5 (200) [R4]',
  acceptBatch1.status === 200 && acceptBatch1.data?.status === 'A_CAMINHO',
  `status=${acceptBatch1.status}`, 'r4_batch');

// 2. Teste de Rejeição de Quiosque Distante (>1km) enquanto entregador possui pedido ativo (< 5 pedidos)
// Cria pedido no Quiosque Distante (Ponta da Praia, >3km)
const distantOrderRes = await aparecimentoA.call('POST', '/orders', {
  ...baseOrder,
  kioskId: KIOSK_DISTANT_ID,
  pontoReferenciaId: PONTA_PRAIA_ID,
  descricaoLocal: 'Pedido na Ponta da Praia (>3km do Posto 5)',
  itens: [{ menuItemId: 'cerveja-lata', quantidade: 3 }],
});
const distantOrderId = distantOrderRes.data?.id;
if (distantOrderId) {
  await fetch(BASE + '/webhooks/pix', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'X-Pix-Webhook-Token': 'dev-pix-webhook-token-secret-12345' },
    body: JSON.stringify({ txId: distantOrderRes.data?.pixTxId, orderId: distantOrderId, status: 'CONCLUIDA' }),
  });
  await aparecimentoA.call('PATCH', `/orders/${distantOrderId}/status`, { status: 'PRONTO_ENTREGA' });

  // Entregador B (que possui 1 pedido ativo no Posto 5) tenta aceitar pedido da Ponta da Praia (>1km)
  const rejectDistantRes = await aparecimentoB.call('PATCH', `/orders/${distantOrderId}/status`, { status: 'A_CAMINHO' });
  check('Aceite de pedido em quiosque distante (>1km) é REJEITADO com HTTP 422 pela regra de proximidade [R4]',
    rejectDistantRes.status === 422 && (rejectDistantRes.data?.mensagem || rejectDistantRes.data?.detail || '').includes('Coleta múltipla permitida apenas para pedidos do mesmo quiosque ou quiosques vizinhos na praia (máximo 1 km).'),
    `status=${rejectDistantRes.status} body=${JSON.stringify(rejectDistantRes.data)}`, 'r4_batch');

  // Cancela o pedido distante criado
  await aparecimentoA.call('PATCH', `/orders/${distantOrderId}/status`, { status: 'CANCELADO' });
}

// 3. Teste Positivo de Quiosque Vizinho (<= 1000m, ~210m do Posto 5)
// Cria pedido no Quiosque Vizinho
const vizinhoOrderRes = await aparecimentoA.call('POST', '/orders', {
  ...baseOrder,
  kioskId: KIOSK_VIZINHO_ID,
  pontoReferenciaId: POSTO5_ID,
  descricaoLocal: 'Pedido no Quiosque Vizinho (~210m do Posto 5)',
  itens: [{ menuItemId: 'acai-copo', quantidade: 2 }],
});
const vizinhoOrderId = vizinhoOrderRes.data?.id;
await fetch(BASE + '/webhooks/pix', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json', 'X-Pix-Webhook-Token': 'dev-pix-webhook-token-secret-12345' },
  body: JSON.stringify({ txId: vizinhoOrderRes.data?.pixTxId, orderId: vizinhoOrderId, status: 'CONCLUIDA' }),
});
await aparecimentoA.call('PATCH', `/orders/${vizinhoOrderId}/status`, { status: 'PRONTO_ENTREGA' });

// Entregador B aceita o pedido do quiosque vizinho (distância ~210m <= 1km)
const acceptVizinhoRes = await aparecimentoB.call('PATCH', `/orders/${vizinhoOrderId}/status`, { status: 'A_CAMINHO' });
check('Entregador aceita pedido simultâneo de QUIOSQUE VIZINHO (<= 1km) com HTTP 200 [R4]',
  acceptVizinhoRes.status === 200 && acceptVizinhoRes.data?.status === 'A_CAMINHO' && acceptVizinhoRes.data?.kioskId === KIOSK_VIZINHO_ID,
  `status=${acceptVizinhoRes.status} kioskId=${acceptVizinhoRes.data?.kioskId}`, 'r4_batch');

// 4. Criação e aceite de mais 3 pedidos para completar a cota máxima de 5 pedidos ativos
const batchOrders = [orderBatch1Res.data, vizinhoOrderRes.data];
for (let i = 3; i <= 5; i++) {
  const oRes = await aparecimentoA.call('POST', '/orders', {
    ...baseOrder,
    kioskId: KIOSK_ID,
    descricaoLocal: `Pedido lote ${i} - Guarda-sol ${i}`,
    itens: [{ menuItemId: 'agua-coco', quantidade: 2 }],
  });
  const oId = oRes.data?.id;
  await fetch(BASE + '/webhooks/pix', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'X-Pix-Webhook-Token': 'dev-pix-webhook-token-secret-12345' },
    body: JSON.stringify({ txId: oRes.data?.pixTxId, orderId: oId, status: 'CONCLUIDA' }),
  });
  await aparelhoOp.call('PATCH', `/orders/${oId}/status`, { status: 'PRONTO_ENTREGA' });
  const aRes = await aparecimentoB.call('PATCH', `/orders/${oId}/status`, { status: 'A_CAMINHO' });
  if (aRes.status === 200 && aRes.data?.status === 'A_CAMINHO') {
    batchOrders.push(oRes.data);
  }
}
check('Entregador aceita e gerencia com sucesso exatamente 5 pedidos ativos simultâneos em A_CAMINHO [R4]',
  batchOrders.length === 5,
  `batchCount=${batchOrders.length}`, 'r4_batch');

const courier5Active = await aparecimentoB.call('GET', '/orders/courier/active');
check('Lista de entregas ativas do entregador retorna exatamente 5 pedidos em rota [R4]',
  courier5Active.status === 200 && courier5Active.data?.length === 5,
  `activeCount=${courier5Active.data?.length}`, 'r4_batch');

// 5. Teste de Telemetria Agregada do Entregador (PATCH /orders/courier/location) [R3]
const aggregatedGpsRes = await aparecimentoB.call('PATCH', '/orders/courier/location', {
  latitude: PIN.latitude + 0.0003,
  longitude: PIN.longitude + 0.0001,
});
check('Entregador atualiza telemetria GPS agregada para todos os pedidos ativos via PATCH /orders/courier/location (200) [R3]',
  aggregatedGpsRes.status === 200 && Array.isArray(aggregatedGpsRes.data) && aggregatedGpsRes.data.length === 5 &&
  aggregatedGpsRes.data.every(o => o.localizacaoEntregador?.coordinates != null && o.codigoEntrega == null),
  `status=${aggregatedGpsRes.status} updatedOrders=${aggregatedGpsRes.data?.length}`, 'r3_track');

// 6. Tentativa de aceitar o 6º Pedido ativo (Excedendo o limite de 5)
const order6Res = await aparecimentoA.call('POST', '/orders', {
  ...baseOrder,
  kioskId: KIOSK_ID,
  descricaoLocal: 'Pedido excedente 6',
  itens: [{ menuItemId: 'agua-coco', quantidade: 2 }],
});
const order6Id = order6Res.data?.id;
await fetch(BASE + '/webhooks/pix', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json', 'X-Pix-Webhook-Token': 'dev-pix-webhook-token-secret-12345' },
  body: JSON.stringify({ txId: order6Res.data?.pixTxId, orderId: order6Id, status: 'CONCLUIDA' }),
});
await aparelhoOp.call('PATCH', `/orders/${order6Id}/status`, { status: 'PRONTO_ENTREGA' });

const reject6thRes = await aparecimentoB.call('PATCH', `/orders/${order6Id}/status`, { status: 'A_CAMINHO' });
check('Aceite do 6º pedido simultâneo é REJEITADO com HTTP 422 (Limite máximo de 5 excedido) [R4]',
  reject6thRes.status === 422 && (reject6thRes.data?.mensagem || reject6thRes.data?.detail || '').includes('Limite máximo de 5 pedidos'),
  `status=${reject6thRes.status} body=${JSON.stringify(reject6thRes.data)}`, 'r4_batch');

// 7. Finaliza a primeira entrega do lote: como ainda restam 4 pedidos ativos, entregador DEVE permanecer EM_ROTA
const firstBatchOrder = batchOrders[0];
const confirmBatch1 = await aparecimentoB.call('POST', `/orders/${firstBatchOrder.id}/confirm-delivery`, {
  courierId: regCourier.data.userId,
  codigoEntrega: firstBatchOrder.codigoEntrega,
  courierLocation: { lat: PIN.latitude + 0.00005, lng: PIN.longitude },
});
check('Entrega do 1º pedido do lote confirmada com sucesso (200) [R4]', confirmBatch1.status === 200, '', 'r4_batch');

const courierStillActive = await aparecimentoB.call('GET', '/orders/courier/active');
check('Entregador permanece EM_ROTA com os 4 pedidos restantes do lote [R4]',
  courierStillActive.status === 200 && courierStillActive.data?.length === 4,
  `remainingCount=${courierStillActive.data?.length}`, 'r4_batch');

// 8. Finaliza os 4 pedidos restantes do lote (incluindo o do quiosque vizinho)
for (let i = 1; i < 5; i++) {
  await aparecimentoB.call('POST', `/orders/${batchOrders[i].id}/confirm-delivery`, {
    courierId: regCourier.data.userId,
    codigoEntrega: batchOrders[i].codigoEntrega,
    courierLocation: { lat: PIN.latitude + 0.00005, lng: PIN.longitude },
  });
}
// Cancela o 6º pedido que não foi aceito
await aparecimentoA.call('PATCH', `/orders/${order6Id}/status`, { status: 'CANCELADO' });

const courierFinalActive = await aparecimentoB.call('GET', '/orders/courier/active');
check('Todas as 5 entregas do lote concluídas: entregador volta a ter 0 pedidos ativos [R4]',
  courierFinalActive.status === 200 && courierFinalActive.data?.length === 0,
  `finalCount=${courierFinalActive.data?.length}`, 'r4_batch');

console.log('\n\x1b[1m\x1b[36m== it_12 Avaliação Pós-Entrega pelo Cliente (1 a 5 estrelas) ==\x1b[0m');
const reviewRes = await aparecimentoA.call('POST', `/orders/${orderId}/review`, {
  estrelas: 5,
  comentario: 'Entrega rápida na areia com água de coco bem gelada! O farol ajudou muito.',
});
check('Cliente registra avaliação 5 estrelas do pedido e do entregador (200)',
  reviewRes.status === 200 && reviewRes.data?.avaliacao?.estrelas === 5,
  JSON.stringify(reviewRes.data?.avaliacao));

console.log('\n\x1b[1m\x1b[36m== it_13 CRUD de Cardápio com Foto pelo Operador do Quiosque (Web) ==\x1b[0m');
const uploadMenuPhoto = await aparelhoOp.uploadFile('/uploads/menu-item-photo', 'acai.png', validPngBuffer, 'image/png');
check('Operador faz upload de foto do produto no Cloudinary Mock (200)',
  uploadMenuPhoto.status === 200 && uploadMenuPhoto.data?.secureUrl?.includes('pe-na-areia/cardapio'));

const createItem = await aparelhoOp.call('POST', '/kiosk/me/menu', {
  nome: 'Açaí Especial Praia 500ml', descricao: 'Com banana, morango e granola',
  preco: 28.9, disponivel: true, category: 'Açaí & Gelados', returnablePackaging: true,
  fotoUrl: uploadMenuPhoto.data.secureUrl, destaque: true,
});
check('Operador cadastra novo item com foto e destaque=true no cardápio (201)',
  createItem.status === 201 && createItem.data?.destaque === true);

const deleteItem = await aparelhoOp.call('DELETE', `/kiosk/me/menu/${createItem.data?.id}`);
check('Operador remove item de teste do cardápio (204)', deleteItem.status === 204);

console.log('\n\x1b[1m\x1b[36m== it_14 Limpeza Automática de Massa de Testes no MongoDB ==\x1b[0m');
const cleanupScript = `
  const e2eUsers = db.users.find({ email: /@(exemplo|example)\\.com$/i }, { _id: 1 }).toArray().map(u => u._id.toString());
  const e2eKiosks = db.kiosks.find({ $or: [{ _id: "${KIOSK_ID}" }, { _id: "${KIOSK_VIZINHO_ID}" }, { _id: "${KIOSK_DISTANT_ID}" }, { nome: "Restaurante Orla do Gonzaga" }] }, { _id: 1 }).toArray().map(k => k._id.toString());
  db.orders.deleteMany({
    $or: [
      { kioskId: { $in: e2eKiosks } },
      { userId: { $in: e2eUsers } }
    ]
  });
  db.kiosk_partnerships.deleteMany({ kioskId: { $in: e2eKiosks } });
  db.kiosks.deleteMany({ _id: { $in: e2eKiosks } });
  db.users.deleteMany({ email: /@(exemplo|example)\\.com$/i });
  db.couriers.deleteMany({ email: /@(exemplo|example)\\.com$/i });
  db.couriers.updateMany({ status: { $ne: "DISPONIVEL" } }, { $set: { status: "DISPONIVEL" } });
`;
runMongoScript(cleanupScript);
console.log('  \x1b[32m✔ OK\x1b[0m Base do MongoDB sanitizada após testes regressivos.');

// -----------------------------------------------------------------------------
// Relatório e Sumário Final Consolidado
// -----------------------------------------------------------------------------
console.log('\n\x1b[1m\x1b[36m========================================================================\x1b[0m');
console.log('\x1b[1m\x1b[36m==                 RESULTADO CONSOLIDADO DA SUÍTE E2E                 ==\x1b[0m');
console.log('\x1b[1m\x1b[36m========================================================================\x1b[0m');
console.log(`\x1b[1mR1. PIN & Sequencial Diário (#0001):\x1b[0m   PASS: ${metrics.r1_pin.pass}   FAIL: ${metrics.r1_pin.fail}`);
console.log(`\x1b[1mR2. Chat em Tempo Real & Expiração:\x1b[0m    PASS: ${metrics.r2_chat.pass}   FAIL: ${metrics.r2_chat.fail}`);
console.log(`\x1b[1mR3. Live Tracking Rota & Proximidade:\x1b[0m  PASS: ${metrics.r3_track.pass}   FAIL: ${metrics.r3_track.fail}`);
console.log(`\x1b[1mR4. Coleta Múltipla (até 5 pedidos):\x1b[0m   PASS: ${metrics.r4_batch.pass}   FAIL: ${metrics.r4_batch.fail}`);
console.log(`\x1b[1mContratos Web, Pix & Cloudinary:\x1b[0m       PASS: ${metrics.outros.pass}   FAIL: ${metrics.outros.fail}`);
console.log('------------------------------------------------------------------------');
console.log(`\x1b[1mTOTAL GERAL:\x1b[0m PASS: \x1b[32m${pass}\x1b[0m  |  FAIL: \x1b[${fail > 0 ? '31m' : '32m'}${fail}\x1b[0m`);

if (failures.length > 0) {
  console.log('\n\x1b[31mFalhas Registradas:\x1b[0m');
  failures.forEach(f => console.log(` - ${f}`));
}

process.exit(fail === 0 ? 0 : 1);
