// Teste E2E do fluxo completo Pé na Areia
// Dois "aparelhos" simulados com sessões JWT totalmente independentes:
//   Aparelho A = Cliente, Aparelho B = Entregador principal, Aparelho C = outro Entregador
// Pré-requisitos: API em http://localhost:8080 e kiosk-santos-1 semeado no MongoDB (Posto 5 = id 6acfd917f737c71df923a343).
// Executar: node e2e/e2e_delivery_flow.mjs

const BASE = process.env.API_BASE_URL || 'http://localhost:8080';
const POSTO5_ID = '6acfd917f737c71df923a343';
const KIOSK_ID = 'kiosk-santos-1';
// Posto 5: lat -23.9689, lng -46.3336
const PIN = { latitude: -23.9691, longitude: -46.3334 }; // ~30 m do Posto 5 (dentro de 500 m)

let pass = 0, fail = 0;
const failures = [];
function check(name, cond, detail = '') {
  if (cond) { pass++; console.log(`  PASS ${name}`); }
  else { fail++; failures.push(`${name}${detail ? ' -> ' + detail : ''}`); console.log(`  FAIL ${name}${detail ? ' -> ' + detail : ''}`); }
}

// Cada "aparelho" guarda o próprio token JWT: sessões independentes.
function device(label) {
  let token = null;
  return {
    get role() { return null; },
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

console.log('== it_01 Cadastro e sessão de cada aparelho ==');
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

console.log('== it_02 Catálogo no aparelho do cliente ==');
const kiosks = await aparecimentoA.call('GET', '/kiosks');
check('GET /kiosks 200 na sessão do cliente', kiosks.status === 200 && Array.isArray(kiosks.data) && kiosks.data.length > 0);
const kiosk = kiosks.data.find(k => k.id === KIOSK_ID);
check('quiosque semeado visível no catálogo', !!kiosk);
check('cardápio tem itens id/availáveis', kiosk?.cardapio?.every(i => i.id && typeof i.disponivel === 'boolean'));

console.log('== it_03 Validations de criação de pedido ==');
const baseOrder = {
  userId: regCliente.data.userId,
  kioskId: KIOSK_ID,
  formaPagamento: 'PIX',
  embalagemSustentavel: true,
  pinCliente: PIN,
  pontoReferenciaId: POSTO5_ID,
  descricaoLocal: 'Guarda-sol listrado azul, 20 m da faixa de água',
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
check('item fora do cardápio é negado', unknownItem.status === 404, JSON.stringify(unknownItem.data));

const farPin = await aparecimentoA.call('POST', '/orders', {
  ...baseOrder,
  itens: [{ menuItemId: 'agua-coco', quantidade: 2 }],
  pinCliente: { latitude: -23.9642, longitude: -46.3330 }, // ~520 m do Posto 5
});
check('pin a mais de 500 m do posto é negado (422)', farPin.status === 422, JSON.stringify(farPin.data));

const availableDenied = await aparecimentoA.call('GET', '/orders/available');
check('cliente não pode listar pedidos disponíveis (422)', availableDenied.status === 422, JSON.stringify(availableDenied.data));

console.log('== it_04 Criação do pedido no aparelho do cliente ==');
const createOrder = await aparecimentoA.call('POST', '/orders', {
  ...baseOrder,
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
check('preço dos itens vem do cardápio do servidor', order.itens?.[0]?.precoUnitario === 12 && order.itens?.[1]?.precoUnitario === 38.5, JSON.stringify(order.itens));
check('sem entregador atribuído ainda', !order.courierId);
check('pin geográfico correto ([lng,lat])', Array.isArray(order.pinCliente?.coordinates) && order.pinCliente.coordinates[0] === PIN.longitude && order.pinCliente.coordinates[1] === PIN.latitude, JSON.stringify(order.pinCliente));
check('postId de referência e descrição persistidos', order.pontoReferenciaId === POSTO5_ID && order.descricaoLocal === baseOrder.descricaoLocal);
check('timeline pagoEm/emPreparo preenchidos', !!order.timeline?.pagoEm && !!order.timeline?.emPreparoEm);

console.log('== it_05 Segurança de acesso antes do aceite ==');
const clientFetchCourier = await aparecimentoA.call('GET', '/orders/courier/active');
check('cliente não acessa rota de entregador (422)', clientFetchCourier.status === 422, JSON.stringify(clientFetchCourier.data));

const noAuth = await device('aparelho-anonimo').call('GET', '/orders');
check('requisição sem token é 401', noAuth.status === 401, String(noAuth.status));

const courierCView = await aparelhoC.call('GET', `/orders/${orderId}`);
check('entrevistador C não vê pedido de terceiros antes do aceite (422)', courierCView.status === 422, JSON.stringify(courierCView.data));

// it_06 raio de confirmação (negativo controlado):
// mesmo estrutura do it_09, mas executado aqui para não depender de estado novo.
// O teste na API valida o limite com o pin a mais de 60 m.

console.log('== it_06 Criação de pedido 2 para cancelamento ==');
const order2Res = await aparecimentoA.call('POST', '/orders', {
  ...baseOrder,
  itemIdCancelBugfix: undefined,
  itens: [{ menuItemId: 'sundae', quantidade: 1 }],
  descricaoLocal: 'Quiosque de roda amarela',
});
check('pedido 2 criado', order2Res.status === 201, JSON.stringify(order2Res.data?.id));
const order2 = order2Res.data || {};
const cancel = await aparecimentoA.call('PATCH', `/orders/${order2.id}/status`, { status: 'CANCELADO' });
check('cliente cancela antes de sair para entrega', cancel.status === 200 && cancel.data?.status === 'CANCELADO', JSON.stringify(cancel.data));
const cancelAgain = await aparecimentoA.call('PATCH', `/orders/${order2.id}/status`, { status: 'CANCELADO' });
check('transição CANCELADO -> CANCELADO é negada (422)', cancelAgain.status === 422, JSON.stringify(cancelAgain.data));

console.log('== it_07 Entregador consulta disponíveis e aceita (A_CAMINHO) ==');
const courierLists = await aparecimentoB.call('GET', '/orders/available');
check('entregador lista pedidos EM_PREPARO disponíveis', courierLists.status === 200 && Array.isArray(courierLists.data) && courierLists.data.some(o => o.id === orderId), JSON.stringify(courierLists.status));
const availableView = courierLists.data.find(o => o.id === orderId);
check('lista de disponíveis mostra o destino do pedido (pin amarelo)', !!availableView && Array.isArray(availableView.pinCliente?.coordinates), JSON.stringify(availableView?.pinCliente));

const clientStartsDelivery = await aparecimentoA.call('PATCH', `/orders/${orderId}/status`, { status: 'A_CAMINHO' });
check('cliente não pode iniciar a entrega (422)', clientStartsDelivery.status === 422, JSON.stringify(clientStartsDelivery.data));

const accept = await aparecimentoB.call('PATCH', `/orders/${orderId}/status`, { status: 'A_CAMINHO' });
check('entregador aceita e fica A_CAMINHO com courierId dele', accept.status === 200 && accept.data?.status === 'A_CAMINHO' && accept.data?.courierId === regCourier.data.userId, JSON.stringify({ status: accept.status, courierId: accept.data?.courierId }));

const acceptC = await aparelhoC.call('PATCH', `/orders/${orderId}/status`, { status: 'A_CAMINHO' });
check('outro entregador não pode assumir pedido já aceito (422)', acceptC.status === 422, JSON.stringify(acceptC.data));

console.log('== it_08 Chegada no local ==');
const arrive = await aparecimentoB.call('PATCH', `/orders/${orderId}/status`, { status: 'CHEGOU_NO_LOCAL' });
check('entregador marca CHEGOU_NO_LOCAL', arrive.status === 200 && arrive.data?.status === 'CHEGOU_NO_LOCAL', JSON.stringify(arrive.data));
check('timeline aCaminhoEm preenchida', !!(arrive.data?.timeline?.acaminhoEm ?? arrive.data?.timeline?.aCaminhoEm), JSON.stringify(arrive.data?.timeline));

console.log('== it_09 Confirmação de entrega validada por GPS (raio 60 m)==');
const wrongSelf = await aparecimentoB.call('POST', `/orders/${orderId}/confirm-delivery`, {
  courierId: 'id-falso',
  courierLocation: { lat: PIN.latitude, lng: PIN.longitude },
});
check('courierId divergente do token é negado (422)', wrongSelf.status === 422, JSON.stringify(wrongSelf.data));

const tooFar = await aparecimentoB.call('POST', `/orders/${orderId}/confirm-delivery`, {
  courierId: regCourier.data.userId,
  courierLocation: { lat: PIN.latitude + 0.0012, lng: PIN.longitude }, // ~135 m do pin
});
check('confirmação a ~135 m do pin é negada (422)', tooFar.status === 422 && /pin do cliente|máximo/.test(String(tooFar.data?.mensagem || '')), JSON.stringify(tooFar.data));

const clientConfirms = await aparecimentoA.call('POST', `/orders/${orderId}/confirm-delivery`, {
  courierId: regCliente.data.userId,
  courierLocation: { lat: PIN.latitude, lng: PIN.longitude },
});
check('cliente não pode confirmar entrega (422)', clientConfirms.status === 422, JSON.stringify(clientConfirms.data));

const confirm = await aparecimentoB.call('POST', `/orders/${orderId}/confirm-delivery`, {
  courierId: regCourier.data.userId,
  courierLocation: { lat: PIN.latitude + 0.00005, lng: PIN.longitude }, // ~5 m do pin
});
check('confirmação a ~5 m do pin é aceita e vira ENTREGUE', confirm.status === 200 && confirm.data?.status === 'ENTREGUE', JSON.stringify(confirm.data?.status));
check('timeline entregueEm preenchida', !!confirm.data?.timeline?.entregueEm);

console.log('== it_10 Cliente consulta o pedido atualizado ==');
const clientView = await aparecimentoA.call('GET', `/orders/${orderId}`);
check('aparelho do cliente vê o mesmo pedido', clientView.status === 200 && clientView.data?.id === orderId);
check('status visto pelo cliente é ENTREGUE', clientView.data?.status === 'ENTREGUE');
check('timeline completa (pagoEm, aCaminhoEm, entregueEm)', !!clientView.data?.timeline?.pagoEm && !!(clientView.data?.timeline?.acaminhoEm ?? clientView.data?.timeline?.aCaminhoEm) && !!clientView.data?.timeline?.entregueEm, JSON.stringify(clientView.data?.timeline));

const courierCView2 = await aparelhoC.call('GET', `/orders/${orderId}`);
check('entregador C ainda não vê o pedido alheio (422)', courierCView2.status === 422, JSON.stringify(courierCView2.data));

console.log('== it_11 Entregador liberado após a entrega ==');
const courierActive = await aparecimentoB.call('GET', '/orders/courier/active');
check('rota ativa fica vazia após ENTREGUE', courierActive.status === 200 && Array.isArray(courierActive.data) && courierActive.data.length === 0, JSON.stringify(courierActive.data));

const order3Res = await aparecimentoA.call('POST', '/orders', {
  ...baseOrder,
  itens: [{ menuItemId: 'agua-coco', quantidade: 1 }],
  descricaoLocal: 'Perto do poste 12',
});
check('pedido 3 criado para validar liberacao do entregador', order3Res.status === 201, JSON.stringify(order3Res.data?.id));
const reAccept = await aparecimentoB.call('PATCH', `/orders/${order3Res.data.id}/status`, { status: 'A_CAMINHO' });
check('entregador DISPONIVEL volta a aceitar novo pedido', reAccept.status === 200 && reAccept.data?.courierId === regCourier.data.userId, JSON.stringify(reAccept.data?.courierId));
// devolve pedido 3 para EM_PREPARO? não há transição inversa; encerramos com cancelamento negativo e deixamos em A_CAMINHO.
const farCancel = await aparecimentoA.call('PATCH', `/orders/${order3Res.data.id}/status`, { status: 'CANCELADO' });
check('após A_CAMINHO não pode cancelar (422)', farCancel.status === 422, JSON.stringify(farCancel.data));

console.log('\n===== RESULTADO =====');
console.log(`PASS: ${pass}  FAIL: ${fail}`);
if (failures.length) { console.log('Falhas:\n - ' + failures.join('\n - ')); }
process.exit(fail === 0 ? 0 : 1);
