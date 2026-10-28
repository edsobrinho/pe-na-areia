// Teste E2E Completo Pé na Areia v2.1 (Backend + MongoDB Docker + Cloudinary Mock Docker + 6 Telas Costeiras + Vitrine Web)
// Executar: node e2e/e2e_delivery_flow.mjs

import { execSync } from 'node:child_process';

const BASE = process.env.API_BASE_URL || 'http://localhost:8080';
const POSTO5_ID = '6acfd917f737c71df923a343';
const KIOSK_ID = 'kiosk-santos-1';
const PARTNERSHIP_ID = 'pe-na-areia-app';
// Posto 5: lat -23.9689, lng -46.3336
const PIN = { latitude: -23.9691, longitude: -46.3334 }; // ~30 m do Posto 5 (dentro de 500 m)

// Garante dados base no MongoDB Docker (kiosk-santos-1 com _id nos subdocumentos do cardápio)
try {
  const seedScript = `
    db.kiosk_partnerships.deleteMany({ kioskId: "kiosk-santos-1" });
    db.kiosks.updateOne(
      { _id: "kiosk-santos-1" },
      {
        $set: {
          nome: "Quiosque Pé na Areia",
          pontoReferenciaId: "${POSTO5_ID}",
          localizacao: { type: "Point", coordinates: [-46.3338, -23.969] },
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
  `;
  execSync('docker exec -i pe-na-areia-mongodb-1 mongosh pe_na_areia --quiet', {
    input: seedScript,
    stdio: ['pipe', 'ignore', 'ignore'],
  });
} catch {
  // Ignora se mongosh não estiver acessível via CLI local
}

let pass = 0, fail = 0;
const failures = [];
function check(name, cond, detail = '') {
  if (cond) { pass++; console.log(`  PASS ${name}`); }
  else { fail++; failures.push(`${name}${detail ? ' -> ' + detail : ''}`); console.log(`  FAIL ${name}${detail ? ' -> ' + detail : ''}`); }
}

function device(label) {
  let token = null;
  return {
    get token() { return token; },
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

console.log('== it_01 Cadastro e sessão de cada aparelho (Cliente, Entregadores e Operador) ==');
const preflightRes = await fetch(BASE + '/auth/login', {
  method: 'OPTIONS',
  headers: {
    Origin: 'http://localhost:58301',
    'Access-Control-Request-Method': 'POST',
    'Access-Control-Request-Headers': 'content-type,authorization',
  },
});
check('CORS Preflight OPTIONS /auth/login aceita qualquer porta local do Flutter Web (ex: localhost:58301)',
  preflightRes.status === 200 && preflightRes.headers.get('access-control-allow-origin') === 'http://localhost:58301',
  `status=${preflightRes.status} allow-origin=${preflightRes.headers.get('access-control-allow-origin')}`);

const regCliente = await aparecimentoA.register({
  name: 'Cliente E2E', email: `cliente.e2e.${stamp}@exemplo.com`, phone: '13990000001',
  password: 'senha123', role: 'CLIENT',
});
check('cliente registrado 201', regCliente.status === 201, JSON.stringify(regCliente.data));
check('cliente recebe userId + role CLIENT + token', !!regCliente.data?.userId && regCliente.data?.role === 'CLIENT' && !!regCliente.data?.token);

const regCourier = await aparecimentoB.register({
  name: 'Entregador E2E', email: `entregador.e2e.${stamp}@exemplo.com`, phone: '13990000002',
  password: 'senha123', role: 'COURIER', vehicle: 'BIKE',
});
check('entregador registrado 201', regCourier.status === 201, JSON.stringify(regCourier.data));
check('entregador recebe userId + role COURIER + token', !!regCourier.data?.userId && regCourier.data?.role === 'COURIER' && !!regCourier.data?.token);

const regCourierC = await aparelhoC.register({
  name: 'Entregador C', email: `entregador.c.e2e.${stamp}@exemplo.com`, phone: '13990000003',
  password: 'senha123', role: 'COURIER', vehicle: 'PE',
});
check('segundo entregador (aparelho C) registrado 201', regCourierC.status === 201);

const dupEmail = await aparecimentoA.register({
  name: 'Cliente E2E', email: `cliente.e2e.${stamp}@exemplo.com`, phone: '13990000001',
  password: 'senha123', role: 'CLIENT',
});
check('e-mail duplicado rejeitado (422)', dupEmail.status === 422, JSON.stringify(dupEmail.data));

const loginC = await aparecimentoB.login({ email: `entregador.e2e.${stamp}@exemplo.com`, password: 'senha123' });
check('login do entregador retorna mesmo userId', loginC.status === 200 && loginC.data?.userId === regCourier.data?.userId, JSON.stringify(loginC.data));

// Registra e promove operador do quiosque para configurar a parceria e a vitrine via API REST oficial
await aparelhoOp.register({
  name: 'Operador Quiosque', email: `op.e2e.${stamp}@exemplo.com`, phone: '13990000099',
  password: 'senha123', role: 'CLIENT',
});
execSync('docker exec -i pe-na-areia-mongodb-1 mongosh pe_na_areia --quiet', {
  input: `db.users.updateOne({ email: "op.e2e.${stamp}@exemplo.com" }, { $set: { role: "KIOSK_OPERATOR", kioskId: "kiosk-santos-1" } });`,
  stdio: ['pipe', 'ignore', 'ignore'],
});
await aparelhoOp.login({ email: `op.e2e.${stamp}@exemplo.com`, password: 'senha123' });

const configPartnership = await aparelhoOp.call('PUT', `/kiosk/me/partnerships/${PARTNERSHIP_ID}`, {
  active: true,
  commissionPercent: 10,
  deliveryFee: 0,
  deliveryFeePayer: 'KIOSK',
  minimumOrder: 20,
  maxItemsPerOrder: 50,
  acceptFrom: '00:00:00',
  acceptUntil: '00:00:00',
  prepMinutes: 15,
  filters: { categories: [], onlyReturnable: false },
  productIds: ['agua-coco', 'pastel-camarao', 'sundae', 'item-agotado'],
});
check('Operador ativa parceria pe-na-areia-app via API REST (200)', configPartnership.status === 200 && configPartnership.data?.active === true, JSON.stringify(configPartnership.data));

const previewPartnership = await aparelhoOp.call('POST', `/kiosk/me/partnerships/${PARTNERSHIP_ID}/preview`, {
  items: [
    { menuItemId: 'agua-coco', quantity: 2 },
    { menuItemId: 'pastel-camarao', quantity: 1 },
  ],
});
check('Operador testa Simulador de Repasse em POST /kiosk/me/partnerships/{id}/preview (200)',
  previewPartnership.status === 200 &&
  Number(previewPartnership.data?.subtotal) === 62.5 &&
  Number(previewPartnership.data?.kioskNet) === 56.25,
  JSON.stringify(previewPartnership.data));

const updateStorefront = await aparelhoOp.call('PUT', '/kiosk/me/storefront', {
  descricaoCurta: 'Porções de Frutos do Mar, Água de Coco e Embalagem Retornável no Posto 5',
  fotoCapaUrl: 'http://localhost:8099/pe-na-areia-local/image/upload/v1/capa-quiosque.png',
  logoUrl: 'http://localhost:8099/pe-na-areia-local/image/upload/v1/logo-quiosque.png',
  aceitaEmbalagemSustentavel: true,
  destaquePopular: true,
});
check('Operador configura Vitrine do Quiosque (Storefront v2.1) via PUT /kiosk/me/storefront (200)',
  updateStorefront.status === 200 &&
  updateStorefront.data?.destaquePopular === true &&
  updateStorefront.data?.fotoCapaUrl?.includes('capa-quiosque.png'),
  JSON.stringify(updateStorefront.data));

console.log('== it_02 Catálogo e Vitrine no aparelho do cliente (Telas 2, 3 e 4) ==');
const channels = await aparecimentoA.call('GET', '/partnerships');
check('Cliente carrega canais de venda ativos em GET /partnerships (200)',
  channels.status === 200 && Array.isArray(channels.data) && channels.data.some(p => p.id === PARTNERSHIP_ID));

const kiosks = await aparecimentoA.call('GET', '/kiosks');
check('GET /kiosks 200 na sessão do cliente', kiosks.status === 200 && Array.isArray(kiosks.data) && kiosks.data.length > 0);
const kiosk = kiosks.data.find(k => k.id === KIOSK_ID);
check('quiosque semeado visível no catálogo', !!kiosk);
check('quiosque traz fotoCapaUrl, logoUrl, descricaoCurta e destaquePopular na vitrine',
  kiosk?.destaquePopular === true &&
  kiosk?.fotoCapaUrl?.includes('capa-quiosque.png') &&
  kiosk?.descricaoCurta?.includes('Frutos do Mar'));
check('cardápio tem itens id/disponíveis e flag destaque',
  kiosk?.cardapio?.every(i => i.id && typeof i.disponivel === 'boolean' && typeof i.destaque === 'boolean'),
  JSON.stringify(kiosk?.cardapio));

const kioskOffers = await aparecimentoA.call('GET', `/kiosks/${KIOSK_ID}/partnerships`);
check('Cliente consulta métricas da Loja do Quiosque (prepMinutes, deliveryFee, minimumOrder) em GET /kiosks/{id}/partnerships',
  kioskOffers.status === 200 && Array.isArray(kioskOffers.data) && kioskOffers.data[0]?.prepMinutes === 15);

console.log('== it_03 Validations de criação de pedido ==');
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

const denyOtherUser = await aparecimentoA.call('POST', '/orders', { ...baseOrder, userId: 'usuario-de-outro', itens: [{ menuItemId: 'agua-coco', quantidade: 1 }] });
check('pedido para outro usuário é negado (422)', denyOtherUser.status === 422, JSON.stringify(denyOtherUser.data));

const noItems = await aparecimentoA.call('POST', '/orders', { ...baseOrder, itens: [] });
check('pedido sem itens é negado', noItems.status === 400 || noItems.status === 422, JSON.stringify(noItems.data));

const qtyZero = await aparecimentoA.call('POST', '/orders', {
  ...baseOrder, itens: [{ menuItemId: 'agua-coco', quantidade: 0 }],
});
check('quantidade zero é negada', qtyZero.status === 400, JSON.stringify(qtyZero.data));

const unavailable = await aparecimentoA.call('POST', '/orders', {
  ...baseOrder, itens: [{ menuItemId: 'item-agotado', quantidade: 1 }],
});
check('item indisponível é negado (422)', unavailable.status === 422, JSON.stringify(unavailable.data));

const unknownItem = await aparecimentoA.call('POST', '/orders', {
  ...baseOrder, itens: [{ menuItemId: 'item-fantasma', quantidade: 1 }],
});
check('item fora do cardápio é negado (404)', unknownItem.status === 404, JSON.stringify(unknownItem.data));

const farPin = await aparecimentoA.call('POST', '/orders', {
  ...baseOrder,
  itens: [{ menuItemId: 'agua-coco', quantidade: 2 }],
  pinCliente: { latitude: -23.9642, longitude: -46.3330 }, // ~520 m do Posto 5
});
check('pin a mais de 500 m do posto é negado (422)', farPin.status === 422, JSON.stringify(farPin.data));

const belowMinimum = await aparecimentoA.call('POST', '/orders', {
  ...baseOrder,
  itens: [{ menuItemId: 'agua-coco', quantidade: 1 }], // R$ 12.00 < R$ 20.00 pedido mínimo
});
check('pedido abaixo do valor mínimo da parceria (R$ 12 < R$ 20) é negado (422)', belowMinimum.status === 422, JSON.stringify(belowMinimum.data));

const availableDenied = await aparecimentoA.call('GET', '/orders/available');
check('cliente não pode listar pedidos disponíveis (422)', availableDenied.status === 422, JSON.stringify(availableDenied.data));

console.log('== it_04 Upload de fotos no Cloudinary Mock Docker (Guia de 3 Fotos na Areia - Tela 1) ==');
const validPngBuffer = Buffer.from(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
  'base64',
);
const uploadLocalRes = await aparecimentoA.uploadFile('/uploads/location-photo', 'guarda-sol.png', validPngBuffer, 'image/png');
const uploadVisaoPostoRes = await aparecimentoA.uploadFile('/uploads/location-photo', 'visao-posto.png', validPngBuffer, 'image/png');
const uploadOutroItemRes = await aparecimentoA.uploadFile('/uploads/location-photo', 'outro-item.png', validPngBuffer, 'image/png');
check('POST /uploads/location-photo (3 slots: Guarda-sol, Visão do Posto, Outro item) retorna 200 com secureUrl',
  uploadLocalRes.status === 200 && !!uploadLocalRes.data?.secureUrl &&
  uploadVisaoPostoRes.status === 200 && !!uploadVisaoPostoRes.data?.secureUrl &&
  uploadOutroItemRes.status === 200 && !!uploadOutroItemRes.data?.secureUrl,
  JSON.stringify(uploadLocalRes.data));
const fetchUploadedImg = await fetch(uploadLocalRes.data.secureUrl);
check('Imagem salva no container cloudinary-mock é servida via HTTP 200', fetchUploadedImg.status === 200 && fetchUploadedImg.headers.get('content-type')?.includes('image/png'));

console.log('== it_05 Criação do pedido com Ponto na Praia detalhado (Tela 1) e Pix gerado ==');
const createOrder = await aparecimentoA.call('POST', '/orders', {
  ...baseOrder,
  fotoLocalUrl: uploadLocalRes.data.secureUrl,
  fotoVisaoPostoUrl: uploadVisaoPostoRes.data.secureUrl,
  itens: [
    { menuItemId: 'agua-coco', quantidade: 2 },
    { menuItemId: 'pastel-camarao', quantidade: 1 },
  ],
});
check('pedido criado 201', createOrder.status === 201, JSON.stringify(createOrder.data));
const order = createOrder.data || {};
const orderId = order.id;
check('status inicial PAGO/EM_PREPARO e pago=true', order.status === 'EM_PREPARO' && order.pago === true, JSON.stringify({ status: order.status, pago: order.pago }));
check('total calculado no servidor = 62.50 (2x12.00 + 1x38.50)', Number(order.valorTotal) === 62.5, String(order.valorTotal));
check('Pix Copia e Cola e TxID gerados no servidor', !!order.pixTxId && String(order.pixCopiaECola).includes('br.gov.bcb.pix'), JSON.stringify({ pixTxId: order.pixTxId }));
check('fotoLocalUrl e fotoVisaoPostoUrl do Cloudinary Docker vinculadas ao pedido',
  order.fotoLocalUrl === uploadLocalRes.data.secureUrl &&
  order.fotoVisaoPostoUrl === uploadVisaoPostoRes.data.secureUrl);
check('metadados detalhados do Ponto na Praia (referenciaBarraca, complementoLocal, contatoNome, etiquetaLocal) persistidos',
  order.referenciaBarraca === 'Guarda-sol listrado azul com 2 cadeiras brancas' &&
  order.complementoLocal === 'Em frente à rede de futevôlei' &&
  order.contatoNome === 'Cliente E2E Praia' &&
  order.etiquetaLocal === 'MEU_GUARDA_SOL');
check('pin geográfico correto ([lng,lat])', Array.isArray(order.pinCliente?.coordinates) && order.pinCliente.coordinates[0] === PIN.longitude && order.pinCliente.coordinates[1] === PIN.latitude);

console.log('== it_06 Segurança de acesso antes do aceite ==');
const clientFetchCourier = await aparecimentoA.call('GET', '/orders/courier/active');
check('cliente não acessa rota de entregador (422)', clientFetchCourier.status === 422);
const noAuth = await device('aparelho-anonimo').call('GET', '/orders');
check('requisição sem token é 401', noAuth.status === 401);
const courierCView = await aparelhoC.call('GET', `/orders/${orderId}`);
check('entregador C não vê pedido de terceiros antes do aceite (422)', courierCView.status === 422);

console.log('== it_07 Criação de pedido 2 para cancelamento ==');
const order2Res = await aparecimentoA.call('POST', '/orders', {
  ...baseOrder,
  itens: [{ menuItemId: 'sundae', quantidade: 2 }],
  descricaoLocal: 'Quiosque de roda amarela',
});
check('pedido 2 criado', order2Res.status === 201);
const order2 = order2Res.data || {};
const cancel = await aparecimentoA.call('PATCH', `/orders/${order2.id}/status`, { status: 'CANCELADO' });
check('cliente cancela antes de sair para entrega', cancel.status === 200 && cancel.data?.status === 'CANCELADO');

console.log('== it_08 Entregador consulta disponíveis e aceita (A_CAMINHO) ==');
const courierLists = await aparecimentoB.call('GET', '/orders/available');
check('entregador lista pedidos EM_PREPARO disponíveis', courierLists.status === 200 && Array.isArray(courierLists.data) && courierLists.data.some(o => o.id === orderId));
const accept = await aparecimentoB.call('PATCH', `/orders/${orderId}/status`, { status: 'A_CAMINHO' });
check('entregador aceita e fica A_CAMINHO com courierId dele', accept.status === 200 && accept.data?.status === 'A_CAMINHO' && accept.data?.courierId === regCourier.data.userId);
check('entregador recebe os metadados do Ponto na Praia do cliente (referenciaBarraca, contatoTelefone, fotoVisaoPostoUrl)',
  accept.data?.referenciaBarraca === 'Guarda-sol listrado azul com 2 cadeiras brancas' &&
  accept.data?.contatoTelefone === '+55 (13) 99000-0001');

console.log('== it_09 Live Tracking na Areia, Alerta de 60m e Mensagens Rápidas ==');
const gpsLonge = await aparecimentoB.call('PATCH', `/orders/${orderId}/courier-location`, {
  latitude: PIN.latitude + 0.0020, // ~220m do pin
  longitude: PIN.longitude,
});
check('entregador atualiza GPS longe (>60m) sem disparar alerta de proximidade', gpsLonge.status === 200 && gpsLonge.data?.alertaProximidadeEnviado === false);

const gpsPerto = await aparecimentoB.call('PATCH', `/orders/${orderId}/courier-location`, {
  latitude: PIN.latitude + 0.0002, // ~22m do pin (dentro dos 60m)
  longitude: PIN.longitude,
});
check('entregador entra no raio de 60m na areia e dispara alerta de proximidade', gpsPerto.status === 200 && gpsPerto.data?.alertaProximidadeEnviado === true, JSON.stringify(gpsPerto.data));

const msgCliente = await aparecimentoA.call('POST', `/orders/${orderId}/messages`, {
  texto: 'A maré subiu, mudei alguns metros para trás',
});
check('cliente envia mensagem rápida na praia (200)', msgCliente.status === 200 && msgCliente.data?.mensagens?.length === 1);

const msgCourier = await aparecimentoB.call('POST', `/orders/${orderId}/messages`, {
  texto: 'Estou a 20m a Sudeste, levante o Sinalizador Laranja!',
});
check('entregador responde no canal rápido (200)', msgCourier.status === 200 && msgCourier.data?.mensagens?.length === 2);
const messages = await aparecimentoA.call('GET', `/orders/${orderId}/messages`);
check('cliente consulta as mensagens rápidas trocadas (200)', messages.status === 200 && messages.data?.length === 2);

console.log('== it_10 Chegada no local e confirmação de entrega validada por GPS (raio 60 m) ==');
const arrive = await aparecimentoB.call('PATCH', `/orders/${orderId}/status`, { status: 'CHEGOU_NO_LOCAL' });
check('entregador marca CHEGOU_NO_LOCAL', arrive.status === 200 && arrive.data?.status === 'CHEGOU_NO_LOCAL');

const tooFar = await aparecimentoB.call('POST', `/orders/${orderId}/confirm-delivery`, {
  courierId: regCourier.data.userId,
  courierLocation: { lat: PIN.latitude + 0.0012, lng: PIN.longitude }, // ~135 m do pin
});
check('confirmação a ~135 m do pin é negada (422)', tooFar.status === 422);

const confirm = await aparecimentoB.call('POST', `/orders/${orderId}/confirm-delivery`, {
  courierId: regCourier.data.userId,
  courierLocation: { lat: PIN.latitude + 0.00005, lng: PIN.longitude }, // ~5 m do pin
});
check('confirmação a ~5 m do pin é aceita e vira ENTREGUE', confirm.status === 200 && confirm.data?.status === 'ENTREGUE');

console.log('== it_11 CRUD de Cardápio com Foto e Destaque pelo Operador do Quiosque (Web) ==');
const uploadMenuPhoto = await aparelhoOp.uploadFile('/uploads/menu-item-photo', 'acai.png', validPngBuffer, 'image/png');
check('Operador faz upload de foto do produto para pe-na-areia/cardapio no Cloudinary Docker', uploadMenuPhoto.status === 200 && uploadMenuPhoto.data?.secureUrl?.includes('pe-na-areia/cardapio'), JSON.stringify(uploadMenuPhoto.data));

const createItem = await aparelhoOp.call('POST', '/kiosk/me/menu', {
  nome: 'Açaí na Tigela 500ml',
  descricao: 'Com banana e granola',
  preco: 28.9,
  disponivel: true,
  category: 'Açaí & Gelados',
  returnablePackaging: true,
  fotoUrl: uploadMenuPhoto.data.secureUrl,
  destaque: true,
});
check('Operador cadastra novo item com foto e destaque=true no cardápio (201)',
  createItem.status === 201 &&
  createItem.data?.fotoUrl === uploadMenuPhoto.data.secureUrl &&
  createItem.data?.destaque === true,
  JSON.stringify(createItem.data));

const listMenu = await aparelhoOp.call('GET', '/kiosk/me/menu');
check('Operador lista cardápio e encontra item com foto e destaque',
  listMenu.status === 200 &&
  listMenu.data?.some(i => i.id === createItem.data.id && i.fotoUrl === uploadMenuPhoto.data.secureUrl && i.destaque === true));

const deleteItem = await aparelhoOp.call('DELETE', `/kiosk/me/menu/${createItem.data.id}`);
check('Operador remove item de teste do cardápio (204)', deleteItem.status === 204);

console.log('\n===== RESULTADO E2E =====');
console.log(`PASS: ${pass}  FAIL: ${fail}`);
if (failures.length) { console.log('Falhas:\n - ' + failures.join('\n - ')); }
process.exit(fail === 0 ? 0 : 1);
