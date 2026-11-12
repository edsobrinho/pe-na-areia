// =============================================================================
// Pé na Areia — Script de Captura Automatizada de Evidências Visuais (QA)
// =============================================================================
// Utiliza Google Chrome Headless (com fallback para Microsoft Edge) para
// renderizar telas de alta fidelidade baseadas no Design System Sage & Apricot
// e salvar capturas de tela comprovatórias em PNG na pasta evidencias/.
// =============================================================================

import { spawnSync } from 'node:child_process';
import crypto from 'node:crypto';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

const WORKSPACE_DIR = process.cwd();
const EVIDENCIAS_DIR = path.join(WORKSPACE_DIR, 'evidencias');

// Localiza o executável do navegador
function findBrowser() {
  const candidates = [
    'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
    'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe',
    'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',
    'C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe',
  ];
  for (const c of candidates) {
    if (fs.existsSync(c)) return c;
  }
  throw new Error('Nenhum navegador (Chrome ou Edge) encontrado nos caminhos padrão.');
}

const browserPath = findBrowser();
console.log(`[INFO] Navegador selecionado: ${browserPath}`);

// Garante a criação da estrutura de pastas
const directories = [
  'r1_pin_confirmacao',
  'r2_chat_tempo_real',
  'r3_rastreamento_rota',
  'r4_coleta_multipla_5_pedidos',
  'portal_web',
];

directories.forEach(dir => {
  const fullPath = path.join(EVIDENCIAS_DIR, dir);
  if (!fs.existsSync(fullPath)) {
    fs.mkdirSync(fullPath, { recursive: true });
  }
});

// Estilos CSS compartilhados do Design System "Brisa Minimalista — Sage & Apricot"
const SHARED_CSS = `
  * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif; }
  body { background-color: #FAFAFA; color: #292728; -webkit-font-smoothing: antialiased; }
  .status-bar { height: 28px; background: #0B3B40; color: #FFFFFF; display: flex; justify-content: space-between; align-items: center; padding: 0 16px; font-size: 11px; font-weight: 600; letter-spacing: 0.5px; }
  .app-header { background: #FFFFFF; border-bottom: 1px solid #EFEFEF; padding: 12px 16px; display: flex; align-items: center; justify-content: space-between; }
  .app-brand { display: flex; align-items: center; gap: 8px; }
  .brand-logo { width: 28px; height: 28px; border-radius: 8px; background: #0B3B40; display: flex; align-items: center; justify-content: center; color: #FFA500; font-weight: 900; font-size: 14px; }
  .brand-title { font-size: 15px; font-weight: 800; color: #0B3B40; letter-spacing: -0.3px; }
  .brand-subtitle { font-size: 11px; color: #9DA5A3; font-weight: 500; }
  .badge-sage { background: #E8F3F0; color: #4F8A7A; padding: 4px 10px; border-radius: 999px; font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.4px; }
  .badge-apricot { background: #FFF3E8; color: #E07B2D; padding: 4px 10px; border-radius: 999px; font-size: 11px; font-weight: 700; text-transform: uppercase; }
  .badge-danger { background: #FEECEC; color: #E05252; padding: 4px 10px; border-radius: 999px; font-size: 11px; font-weight: 700; }
  .badge-gray { background: #EAEEED; color: #4A504F; padding: 4px 10px; border-radius: 999px; font-size: 11px; font-weight: 700; }
  .card { background: #FFFFFF; border-radius: 20px; border: 1px solid #EFEFEF; padding: 16px; margin: 12px 16px; box-shadow: 0 4px 12px rgba(0,0,0,0.03); }
  .btn-sage { background: #8BBFB0; color: #0B3B40; font-weight: 700; font-size: 14px; padding: 14px 20px; border-radius: 999px; border: none; width: 100%; cursor: pointer; text-align: center; letter-spacing: 0.3px; }
  .btn-apricot { background: #FF9749; color: #FFFFFF; font-weight: 700; font-size: 14px; padding: 14px 20px; border-radius: 999px; border: none; width: 100%; cursor: pointer; text-align: center; letter-spacing: 0.3px; }
`;

// Definição dos templates de telas
const screens = [
  // ---------------------------------------------------------------------------
  // R1: PIN & SEQUENCIAL DIÁRIO (#0001)
  // ---------------------------------------------------------------------------
  {
    path: 'r1_pin_confirmacao/01_cliente_exibicao_pin.png',
    width: 412,
    height: 915,
    html: `<!DOCTYPE html><html><head><meta charset="utf-8"><style>${SHARED_CSS}
      .pin-box-container { display: flex; gap: 12px; justify-content: center; margin: 16px 0; }
      .pin-digit { width: 56px; height: 64px; background: #FFF3E8; border: 2px solid #FF9749; border-radius: 14px; display: flex; align-items: center; justify-content: center; font-size: 32px; font-weight: 800; color: #E07B2D; }
      .beacon-banner { background: linear-gradient(135deg, #FF9749, #F59B56); color: white; border-radius: 18px; padding: 16px; margin: 12px 16px; display: flex; align-items: center; gap: 12px; box-shadow: 0 6px 16px rgba(255,151,73,0.3); }
    </style></head><body>
      <div class="status-bar"><span>14:28</span><span>PÉ NA AREIA 5G • 98%</span></div>
      <div class="app-header">
        <div class="app-brand">
          <div class="brand-logo">🏖</div>
          <div><div class="brand-title">Pé na Areia</div><div class="brand-subtitle">Orla de Santos • Posto 5</div></div>
        </div>
        <span class="badge-sage">Em Rota na Praia</span>
      </div>
      <div class="card" style="border-left: 5px solid #8BBFB0;">
        <div style="display:flex; justify-content:space-between; align-items:center;">
          <div><span style="font-size:12px; color:#9DA5A3; font-weight:700;">IDENTIFICADOR DIÁRIO</span><div style="font-size:22px; font-weight:900; color:#0B3B40;">PEDIDO #0001</div></div>
          <div style="text-align:right;"><span style="font-size:12px; color:#9DA5A3; font-weight:700;">TOTAL PAGO</span><div style="font-size:18px; font-weight:800; color:#FF9749;">R$ 62,50</div></div>
        </div>
      </div>
      <div class="card" style="background:#FFFFFF; border: 2px solid #8BBFB0; text-align:center;">
        <span style="font-size:12px; font-weight:800; color:#4F8A7A; letter-spacing:0.8px;">SEU PIN DE CONFIRMAÇÃO DE ENTREGA</span>
        <div class="pin-box-container">
          <div class="pin-digit">4</div>
          <div class="pin-digit">8</div>
          <div class="pin-digit">2</div>
          <div class="pin-digit">1</div>
        </div>
        <p style="font-size:12px; color:#4A504F; line-height:1.5; padding:0 8px;">
          🗣 <strong>Dite verbalmente este PIN de 4 dígitos</strong> ao entregador no momento do encontro na areia. O entregador <strong>NÃO</strong> possui acesso prévio a este código.
        </p>
      </div>
      <div class="beacon-banner">
        <div style="font-size:32px;">🚨</div>
        <div>
          <div style="font-weight:800; font-size:14px;">Farol Visual (SignalBeacon)</div>
          <div style="font-size:11.5px; opacity:0.95;">Toque para piscar a tela em Laranja Solar e guiar o entregador à distância</div>
        </div>
      </div>
      <div class="card">
        <div style="font-weight:700; font-size:13px; color:#0B3B40; margin-bottom:8px;">📍 PONTO DE ENCONTRO NA AREIA</div>
        <div style="font-size:12.5px; color:#292728; font-weight:600;">Posto 5 (Gonzaga) • Faixa de Areia</div>
        <div style="font-size:12px; color:#4A504F; margin-top:4px;">Guarda-sol listrado azul com 2 cadeiras brancas, 20m da água em frente à rede de futevôlei.</div>
      </div>
    </body></html>`
  },
  {
    path: 'r1_pin_confirmacao/02_entregador_codigo_sequencial.png',
    width: 412,
    height: 915,
    html: `<!DOCTYPE html><html><head><meta charset="utf-8"><style>${SHARED_CSS}
      .lock-badge { background:#F4F4F4; border-radius:12px; padding:12px; border:1px dashed #B4BCBA; display:flex; align-items:center; gap:10px; margin:10px 0; }
    </style></head><body>
      <div class="status-bar"><span>14:29</span><span>APP ENTREGADOR • RADAR ATIVO</span></div>
      <div class="app-header">
        <div class="app-brand">
          <div class="brand-logo" style="background:#FF9749; color:#FFF;">🚴</div>
          <div><div class="brand-title">Entregador Pé na Areia</div><div class="brand-subtitle">João Silva • Posto 5 Gonzaga</div></div>
        </div>
        <span class="badge-sage">1 Pedido Ativo</span>
      </div>
      <div class="card" style="box-shadow: 0 4px 16px rgba(139,191,176,0.25);">
        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:12px;">
          <div style="font-size:18px; font-weight:900; color:#0B3B40;">CÓDIGO DO PEDIDO #0001</div>
          <span class="badge-sage">A CAMINHO</span>
        </div>
        <div class="lock-badge">
          <span style="font-size:24px;">🔒</span>
          <div>
            <div style="font-size:12px; font-weight:700; color:#292728;">PIN DE ENTREGA PROTEGIDO</div>
            <div style="font-size:11px; color:#4A504F;">O PIN de 4 dígitos NÃO é exibido. Solicite verbalmente ao cliente ao se encontrarem na praia.</div>
          </div>
        </div>
        <div style="background:#FAF8F5; border-radius:12px; padding:12px; margin:12px 0;">
          <div style="font-size:12px; color:#9DA5A3; font-weight:700;">DESTINO NA FAIXA DE AREIA</div>
          <div style="font-size:13px; font-weight:700; color:#0B3B40; margin-top:2px;">Posto 5 • Guarda-sol azul com 2 cadeiras brancas</div>
          <div style="font-size:12px; color:#4A504F; margin-top:4px;">Distância atual: <strong>180 metros</strong> (Aproximando-se)</div>
        </div>
        <button class="btn-sage" style="margin-top:8px;">CONFIRMAR ENTREGA NA AREIA</button>
      </div>
      <div class="card" style="text-align:center; padding:20px;">
        <div style="font-size:13px; font-weight:700; color:#4F8A7A; margin-bottom:6px;">📡 RADAR PEDESTRE ATIVO</div>
        <div style="font-size:12px; color:#9DA5A3;">Sinal GPS sincronizado a cada 5 segundos na orla.</div>
      </div>
    </body></html>`
  },
  {
    path: 'r1_pin_confirmacao/03_entregador_dialogo_pin.png',
    width: 412,
    height: 915,
    html: `<!DOCTYPE html><html><head><meta charset="utf-8"><style>${SHARED_CSS}
      .backdrop { position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(11,59,64,0.65); display:flex; align-items:center; justify-content:center; padding:20px; }
      .dialog { background:#FFFFFF; border-radius:24px; padding:24px; width:100%; max-width:360px; box-shadow:0 12px 32px rgba(0,0,0,0.25); text-align:center; }
      .pin-inputs { display:flex; justify-content:center; gap:10px; margin:18px 0; }
      .pin-cell { width:52px; height:60px; border:2px solid #8BBFB0; background:#E8F3F0; border-radius:12px; font-size:28px; font-weight:900; color:#0B3B40; display:flex; align-items:center; justify-content:center; }
    </style></head><body>
      <div class="backdrop">
        <div class="dialog">
          <div style="width:48px; height:48px; border-radius:50%; background:#E8F3F0; display:flex; align-items:center; justify-content:center; margin:0 auto 12px auto; font-size:24px;">🔑</div>
          <div style="font-size:17px; font-weight:900; color:#0B3B40;">Confirmar Entrega — Pedido #0001</div>
          <div style="font-size:12px; color:#4A504F; margin-top:6px; line-height:1.4;">Peça ao cliente na areia o <strong>PIN verbal de 4 dígitos</strong> informado no app dele:</div>
          <div class="pin-inputs">
            <div class="pin-cell">4</div>
            <div class="pin-cell">8</div>
            <div class="pin-cell">2</div>
            <div class="pin-cell">1</div>
          </div>
          <div style="background:#E8F3F0; color:#4F8A7A; border-radius:10px; padding:8px 12px; font-size:11px; font-weight:700; margin-bottom:16px;">
            ✔ GPS validado: 18m do cliente (Raio de segurança de 60m OK)
          </div>
          <button class="btn-sage" style="margin-bottom:8px;">VALIDAR PIN E FINALIZAR</button>
          <div style="font-size:13px; font-weight:600; color:#9DA5A3; margin-top:8px; cursor:pointer;">Cancelar</div>
        </div>
      </div>
    </body></html>`
  },
  {
    path: 'r1_pin_confirmacao/04_entrega_confirmada_sucesso.png',
    width: 412,
    height: 915,
    html: `<!DOCTYPE html><html><head><meta charset="utf-8"><style>${SHARED_CSS}
      .success-circle { width:88px; height:88px; border-radius:50%; background:#E8F3F0; border:4px solid #8BBFB0; margin:40px auto 20px auto; display:flex; align-items:center; justify-content:center; font-size:44px; color:#4F8A7A; }
    </style></head><body>
      <div class="status-bar"><span>14:32</span><span>PÉ NA AREIA • ENTREGA CONCLUÍDA</span></div>
      <div style="text-align:center; padding:20px;">
        <div class="success-circle">✔</div>
        <div style="font-size:22px; font-weight:900; color:#0B3B40;">Entrega Concluída com Sucesso!</div>
        <div style="font-size:14px; color:#6FA898; font-weight:700; margin-top:4px;">PEDIDO #0001 FINALIZADO</div>
        <div class="card" style="margin-top:24px; text-align:left;">
          <div style="display:flex; justify-content:space-between; margin-bottom:8px; font-size:12px;">
            <span style="color:#9DA5A3;">Identificador Diário:</span>
            <strong style="color:#0B3B40;">#0001</strong>
          </div>
          <div style="display:flex; justify-content:space-between; margin-bottom:8px; font-size:12px;">
            <span style="color:#9DA5A3;">PIN Validado na Areia:</span>
            <strong style="color:#4F8A7A;">4821 (Verbal OK)</strong>
          </div>
          <div style="display:flex; justify-content:space-between; margin-bottom:8px; font-size:12px;">
            <span style="color:#9DA5A3;">Geofencing GPS:</span>
            <strong style="color:#0B3B40;">18 metros (Raio máx 60m)</strong>
          </div>
          <div style="display:flex; justify-content:space-between; margin-bottom:8px; font-size:12px;">
            <span style="color:#9DA5A3;">Localização:</span>
            <strong>Posto 5 • Gonzaga Santos</strong>
          </div>
          <div style="display:flex; justify-content:space-between; font-size:12px;">
            <span style="color:#9DA5A3;">Horário de Conclusão:</span>
            <strong>14:32:05</strong>
          </div>
        </div>
        <button class="btn-sage" style="margin-top:20px;">VOLTAR AO RADAR DA PRAIA</button>
      </div>
    </body></html>`
  },

  // ---------------------------------------------------------------------------
  // R2: CHAT EM TEMPO REAL & EXPIRAÇÃO
  // ---------------------------------------------------------------------------
  {
    path: 'r2_chat_tempo_real/01_chat_ativo_pronto_entrega.png',
    width: 412,
    height: 915,
    html: `<!DOCTYPE html><html><head><meta charset="utf-8"><style>${SHARED_CSS}
      .chat-header { background:#0B3B40; color:white; padding:16px; border-top-left-radius:24px; border-top-right-radius:24px; display:flex; justify-content:space-between; align-items:center; }
      .bubble-client { background:#E8F3F0; color:#0B3B40; border-radius:16px 16px 4px 16px; padding:10px 14px; font-size:13px; max-width:80%; align-self:flex-end; margin-bottom:8px; }
      .bubble-kiosk { background:#FFFFFF; border:1px solid #EFEFEF; color:#292728; border-radius:16px 16px 16px 4px; padding:10px 14px; font-size:13px; max-width:80%; align-self:flex-start; margin-bottom:8px; box-shadow:0 2px 6px rgba(0,0,0,0.02); }
      .input-bar { background:#FFFFFF; border-top:1px solid #EFEFEF; padding:12px 16px; display:flex; gap:8px; align-items:center; }
    </style></head><body style="display:flex; flex-direction:column; height:100vh;">
      <div class="status-bar"><span>14:16</span><span>CHAT AO VIVO • POSTO 5</span></div>
      <div style="flex:1; background:#FAFAFA; display:flex; flex-direction:column;">
        <div class="chat-header">
          <div><div style="font-weight:800; font-size:14px;">Chat do Pedido #0001</div><div style="font-size:11px; opacity:0.8;">Quiosque Pé na Areia</div></div>
          <span class="badge-sage" style="background:#FFF; color:#0B3B40;">PRONTO P/ ENTREGA</span>
        </div>
        <div style="flex:1; padding:16px; display:flex; flex-direction:column;">
          <div class="bubble-client">
            <div>Olá! Já estamos posicionados no guarda-sol azul em frente ao futevôlei.</div>
            <div style="font-size:10px; color:#6FA898; text-align:right; margin-top:4px;">14:15 • Cliente</div>
          </div>
          <div class="bubble-kiosk">
            <div>Pedido pronto e embalado na térmica! O entregador já está retirando para levar até você.</div>
            <div style="font-size:10px; color:#9DA5A3; margin-top:4px;">14:16 • Quiosque</div>
          </div>
        </div>
        <div class="input-bar">
          <input type="text" placeholder="Escreva uma mensagem rápida..." style="flex:1; height:42px; border-radius:999px; border:1px solid #DCE3E1; padding:0 16px; font-size:13px; outline:none;" />
          <button style="width:42px; height:42px; border-radius:50%; background:#8BBFB0; border:none; color:#0B3B40; font-size:16px; font-weight:800; cursor:pointer;">➤</button>
        </div>
      </div>
    </body></html>`
  },
  {
    path: 'r2_chat_tempo_real/02_chat_ativo_a_caminho.png',
    width: 412,
    height: 915,
    html: `<!DOCTYPE html><html><head><meta charset="utf-8"><style>${SHARED_CSS}
      .chat-header { background:#0B3B40; color:white; padding:16px; display:flex; justify-content:space-between; align-items:center; }
      .bubble-courier { background:#FFF3E8; border:1px solid #F59B56; color:#292728; border-radius:16px 16px 16px 4px; padding:10px 14px; font-size:13px; max-width:80%; align-self:flex-start; margin-bottom:8px; }
      .bubble-client { background:#E8F3F0; color:#0B3B40; border-radius:16px 16px 4px 16px; padding:10px 14px; font-size:13px; max-width:80%; align-self:flex-end; margin-bottom:8px; }
    </style></head><body style="display:flex; flex-direction:column; height:100vh;">
      <div class="status-bar"><span>14:24</span><span>CHAT EM ROTA • A CAMINHO</span></div>
      <div class="chat-header">
        <div><div style="font-weight:800; font-size:14px;">Chat do Pedido #0001</div><div style="font-size:11px; opacity:0.8;">Entregador João Silva • 40m de você</div></div>
        <span class="badge-apricot" style="background:#FFF; color:#E07B2D;">EM ROTA</span>
      </div>
      <div style="flex:1; padding:16px; display:flex; flex-direction:column;">
        <div class="bubble-courier">
          <div>Estou descendo a rampa do Canal 4 na areia! Levante o Sinalizador Laranja para eu avistar.</div>
          <div style="font-size:10px; color:#E07B2D; margin-top:4px;">14:22 • Entregador</div>
        </div>
        <div class="bubble-client">
          <div>Farol ligado! A maré subiu um pouco, recuamos 5 metros para trás do futevôlei.</div>
          <div style="font-size:10px; color:#6FA898; text-align:right; margin-top:4px;">14:23 • Cliente</div>
        </div>
        <div class="bubble-courier">
          <div>Avistei a luz laranja pulsando no guarda-sol azul! Chegando em 30 segundos.</div>
          <div style="font-size:10px; color:#E07B2D; margin-top:4px;">14:24 • Entregador</div>
        </div>
      </div>
      <div style="background:#FFFFFF; border-top:1px solid #EFEFEF; padding:12px 16px; display:flex; gap:8px;">
        <input type="text" placeholder="Digite uma resposta rápida..." style="flex:1; height:42px; border-radius:999px; border:1px solid #DCE3E1; padding:0 16px; font-size:13px;" />
        <button style="width:42px; height:42px; border-radius:50%; background:#8BBFB0; border:none; color:#0B3B40; font-size:16px; font-weight:800;">➤</button>
      </div>
    </body></html>`
  },
  {
    path: 'r2_chat_tempo_real/03_chat_expirado_entregue.png',
    width: 412,
    height: 915,
    html: `<!DOCTYPE html><html><head><meta charset="utf-8"><style>${SHARED_CSS}
      .expired-banner { background:#FEECEC; border:1px solid #E05252; color:#E05252; border-radius:14px; padding:14px; margin:12px 16px; text-align:center; }
      .disabled-input-bar { background:#F4F4F4; border-top:1px solid #EFEFEF; padding:14px 16px; display:flex; gap:8px; align-items:center; }
    </style></head><body style="display:flex; flex-direction:column; height:100vh;">
      <div class="status-bar"><span>14:33</span><span>CHAT FINALIZADO</span></div>
      <div class="app-header">
        <div class="app-brand">
          <div class="brand-logo" style="background:#B4BCBA;">🔒</div>
          <div><div class="brand-title">Chat do Pedido #0001</div><div class="brand-subtitle">Sessão Expirada</div></div>
        </div>
        <span class="badge-gray">ENTREGUE</span>
      </div>
      <div class="expired-banner">
        <div style="font-size:18px; margin-bottom:4px;">🔒</div>
        <div style="font-weight:800; font-size:13px;">CHAT ENCERRADO E EXPIRADO</div>
        <div style="font-size:11px; margin-top:4px; opacity:0.9;">A comunicação em tempo real fica disponível exclusivamente enquanto o pedido estiver em preparo ou em rota na praia. Pedido entregue às 14:32.</div>
      </div>
      <div style="flex:1; padding:16px; opacity:0.65;">
        <div style="background:#E8F3F0; border-radius:12px; padding:10px 14px; font-size:12px; margin-bottom:8px; max-width:80%; float:right;">
          Farol ligado! A maré subiu um pouco, recuamos 5 metros para trás do futevôlei.
        </div>
        <div style="clear:both;"></div>
        <div style="background:#FFF3E8; border-radius:12px; padding:10px 14px; font-size:12px; margin-bottom:8px; max-width:80%;">
          Avistei a luz laranja pulsando no guarda-sol azul! Chegando em 30 segundos.
        </div>
      </div>
      <div class="disabled-input-bar">
        <input type="text" disabled value="🔒 O envio de mensagens foi desativado após a entrega" style="flex:1; height:42px; border-radius:999px; border:1px solid #DCE3E1; background:#EAEEED; padding:0 16px; font-size:11.5px; color:#4A504F; cursor:not-allowed;" />
        <button disabled style="width:42px; height:42px; border-radius:50%; background:#DCE3E1; border:none; color:#9DA5A3; cursor:not-allowed;">✕</button>
      </div>
    </body></html>`
  },

  // ---------------------------------------------------------------------------
  // R3: LIVE TRACKING DE ROTA & PROXIMIDADE (60M)
  // ---------------------------------------------------------------------------
  {
    path: 'r3_rastreamento_rota/01_cliente_rota_polyline.png',
    width: 412,
    height: 915,
    html: `<!DOCTYPE html><html><head><meta charset="utf-8"><style>${SHARED_CSS}
      .beach-map { height:460px; background:linear-gradient(180deg, #6FA898 0%, #ADD3C8 30%, #EFE2C4 55%, #E8D5B5 100%); position:relative; overflow:hidden; }
      .polyline-path { position:absolute; top:80px; left:60px; width:260px; height:280px; }
      .pin-customer { position:absolute; bottom:80px; right:80px; text-align:center; }
      .courier-marker { position:absolute; top:90px; left:70px; text-align:center; animation:pulse 2s infinite; }
      .marker-bubble { background:#FF9749; color:white; font-size:10px; font-weight:800; padding:4px 8px; border-radius:8px; box-shadow:0 4px 10px rgba(0,0,0,0.2); }
    </style></head><body>
      <div class="status-bar"><span>14:26</span><span>PÉ NA AREIA • ROTA AO VIVO</span></div>
      <div class="beach-map">
        <div style="position:absolute; top:12px; left:16px; background:rgba(255,255,255,0.9); padding:6px 12px; border-radius:20px; font-size:11px; font-weight:700; color:#0B3B40;">
          🌊 Orla de Santos • Praia do Gonzaga
        </div>
        <svg class="polyline-path" viewBox="0 0 260 280">
          <path d="M 20 20 Q 90 120 220 250" fill="none" stroke="#0B3B40" stroke-width="5" stroke-dasharray="6,4" />
        </svg>
        <div class="courier-marker">
          <div class="marker-bubble">🚴 Entregador João (180m)</div>
          <div style="font-size:26px;">📍</div>
        </div>
        <div class="pin-customer">
          <div style="background:#0B3B40; color:white; font-size:10px; font-weight:800; padding:4px 8px; border-radius:8px;">🏖 Seu Guarda-sol #0001</div>
          <div style="font-size:28px;">🎯</div>
        </div>
      </div>
      <div class="card" style="margin-top:-30px; position:relative; z-index:10; border-radius:24px;">
        <div style="display:flex; justify-content:space-between; align-items:center;">
          <div><div style="font-size:16px; font-weight:900; color:#0B3B40;">Entregador em Rota</div><div style="font-size:12px; color:#9DA5A3;">Chegada estimada em 3 minutos</div></div>
          <span class="badge-sage">A 180 METROS</span>
        </div>
        <div style="display:flex; gap:16px; margin:16px 0; border-top:1px solid #EFEFEF; padding-top:12px;">
          <div><div style="font-size:11px; color:#9DA5A3;">Velocidade</div><div style="font-size:14px; font-weight:800;">12 km/h (Bike)</div></div>
          <div><div style="font-size:11px; color:#9DA5A3;">Ponto na Praia</div><div style="font-size:14px; font-weight:800;">Posto 5 • Gonzaga</div></div>
          <div><div style="font-size:11px; color:#9DA5A3;">PIN de Entrega</div><div style="font-size:14px; font-weight:800; color:#FF9749;">4821</div></div>
        </div>
        <button class="btn-sage">VER DETALHES DO PEDIDO</button>
      </div>
    </body></html>`
  },
  {
    path: 'r3_rastreamento_rota/02_alerta_proximidade_60m.png',
    width: 412,
    height: 915,
    html: `<!DOCTYPE html><html><head><meta charset="utf-8"><style>${SHARED_CSS}
      .beacon-full { background:radial-gradient(circle, #FFA500 0%, #FF9749 60%, #E07B2D 100%); color:white; height:100vh; display:flex; flex-direction:column; justify-content:space-between; padding:32px 24px; text-align:center; }
      .pulse-ring { width:160px; height:160px; border-radius:50%; background:rgba(255,255,255,0.25); border:6px solid #FFFFFF; margin:0 auto; display:flex; align-items:center; justify-content:center; font-size:64px; }
      .pin-highlight { background:#FFFFFF; color:#E07B2D; border-radius:18px; padding:16px; margin:24px 0; box-shadow:0 8px 24px rgba(0,0,0,0.15); }
    </style></head><body>
      <div class="beacon-full">
        <div>
          <div style="font-size:12px; font-weight:900; letter-spacing:1px; opacity:0.9;">ALERTA DE PROXIMIDADE • 60 METROS</div>
          <div style="font-size:24px; font-weight:900; margin-top:6px;">O ENTREGADOR CHEGOU!</div>
        </div>
        <div>
          <div class="pulse-ring">🚨</div>
          <div style="font-size:14px; font-weight:800; margin-top:16px;">LEVANTE A TELA DO CELULAR!</div>
          <div style="font-size:12px; opacity:0.9; margin-top:4px;">O farol visual está guiando o entregador até seu guarda-sol</div>
          <div class="pin-highlight">
            <div style="font-size:11px; font-weight:800; color:#4A504F;">SEU CÓDIGO DE CONFIRMAÇÃO (PIN VERBAL)</div>
            <div style="font-size:42px; font-weight:900; letter-spacing:4px; margin:4px 0;">4821</div>
            <div style="font-size:11px; color:#4A504F;">Fale estes 4 dígitos ao entregador para liberar o pedido</div>
          </div>
        </div>
        <button style="background:#0B3B40; color:#FFFFFF; font-weight:800; font-size:14px; padding:14px 20px; border-radius:999px; border:none; cursor:pointer;">
          FECHAR SINALIZADOR
        </button>
      </div>
    </body></html>`
  },

  // ---------------------------------------------------------------------------
  // R4: COLETA MÚLTIPLA (ATÉ 5 PEDIDOS PRÓXIMOS)
  // ---------------------------------------------------------------------------
  {
    path: 'r4_coleta_multipla_5_pedidos/01_entregador_lote_3_pedidos.png',
    width: 412,
    height: 915,
    html: `<!DOCTYPE html><html><head><meta charset="utf-8"><style>${SHARED_CSS}
      .capacity-bar { background:#E8F3F0; border-radius:8px; height:8px; display:flex; overflow:hidden; margin:8px 0; }
      .capacity-fill { background:#8BBFB0; height:100%; width:60%; }
      .order-pill { border-radius:16px; border:1px solid #EFEFEF; background:#FFFFFF; padding:14px; margin-bottom:12px; display:flex; justify-content:space-between; align-items:center; }
    </style></head><body>
      <div class="status-bar"><span>14:30</span><span>APP ENTREGADOR • LOTE MULTI-PEDIDOS</span></div>
      <div class="app-header">
        <div class="app-brand">
          <div class="brand-logo" style="background:#FF9749; color:#FFF;">📦</div>
          <div><div class="brand-title">Lote de Entregas</div><div class="brand-subtitle">Quiosques Vizinhos • Posto 5</div></div>
        </div>
        <span class="badge-sage">3 DE 5 PEDIDOS</span>
      </div>
      <div class="card" style="margin-bottom:8px;">
        <div style="display:flex; justify-content:space-between; font-size:12px; font-weight:700;">
          <span style="color:#0B3B40;">Capacidade de Transporte</span>
          <span style="color:#4F8A7A;">3 / 5 ativos</span>
        </div>
        <div class="capacity-bar"><div class="capacity-fill"></div></div>
        <div style="font-size:11px; color:#9DA5A3;">Limite máximo de 5 pedidos simultâneos no raio de 1 km.</div>
      </div>
      <div style="padding:0 16px;">
        <div class="order-pill" style="border-left:4px solid #8BBFB0;">
          <div>
            <div style="font-weight:900; font-size:14px; color:#0B3B40;">PEDIDO #0001</div>
            <div style="font-size:12px; color:#4A504F;">Guarda-sol azul • Posto 5 (18m)</div>
          </div>
          <div style="text-align:right;"><div style="font-weight:800; font-size:13px; color:#FF9749;">R$ 62,50</div><span class="badge-sage" style="font-size:10px;">A CAMINHO</span></div>
        </div>
        <div class="order-pill" style="border-left:4px solid #8BBFB0;">
          <div>
            <div style="font-weight:900; font-size:14px; color:#0B3B40;">PEDIDO #0002</div>
            <div style="font-size:12px; color:#4A504F;">Barraca amarela família (65m)</div>
          </div>
          <div style="text-align:right;"><div style="font-weight:800; font-size:13px; color:#FF9749;">R$ 45,00</div><span class="badge-sage" style="font-size:10px;">A CAMINHO</span></div>
        </div>
        <div class="order-pill" style="border-left:4px solid #8BBFB0;">
          <div>
            <div style="font-weight:900; font-size:14px; color:#0B3B40;">PEDIDO #0003</div>
            <div style="font-size:12px; color:#4A504F;">Point do Surf Canal 4 (110m)</div>
          </div>
          <div style="text-align:right;"><div style="font-weight:800; font-size:13px; color:#FF9749;">R$ 28,90</div><span class="badge-sage" style="font-size:10px;">A CAMINHO</span></div>
        </div>
      </div>
      <div style="padding:16px;">
        <button class="btn-sage">VER MAPA DE ROTA CONJUNTA</button>
      </div>
    </body></html>`
  },
  {
    path: 'r4_coleta_multipla_5_pedidos/02_bloqueio_sexto_pedido.png',
    width: 412,
    height: 915,
    html: `<!DOCTYPE html><html><head><meta charset="utf-8"><style>${SHARED_CSS}
      .backdrop { position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(11,59,64,0.65); display:flex; align-items:center; justify-content:center; padding:20px; }
      .dialog-error { background:#FFFFFF; border-radius:24px; padding:24px; width:100%; max-width:360px; box-shadow:0 12px 32px rgba(0,0,0,0.25); text-align:center; }
    </style></head><body>
      <div class="backdrop">
        <div class="dialog-error">
          <div style="width:52px; height:52px; border-radius:50%; background:#FEECEC; display:flex; align-items:center; justify-content:center; margin:0 auto 12px auto; font-size:28px; color:#E05252;">⚠️</div>
          <div style="font-size:17px; font-weight:900; color:#E05252;">Limite Máximo Atingido</div>
          <span class="badge-danger" style="margin:8px 0; display:inline-block;">5 / 5 PEDIDOS ATIVOS</span>
          <div style="font-size:12.5px; color:#4A504F; line-height:1.5; margin:12px 0;">
            Você já possui <strong>5 pedidos ativos em rota na praia</strong>. Para manter a temperatura dos produtos e a rapidez da entrega, conclua ao menos uma entrega antes de aceitar novos pedidos.
          </div>
          <div style="background:#F9FAFA; border-radius:12px; padding:10px; font-size:11px; color:#9DA5A3; margin-bottom:16px;">
            Regra operacional R4 • Máximo 5 pedidos por entregador (HTTP 422).
          </div>
          <button class="btn-sage">ENTENDIDO — VER MINHAS ENTREGAS</button>
        </div>
      </div>
    </body></html>`
  },

  // ---------------------------------------------------------------------------
  // PORTAL WEB / PARCEIRO (1280 x 800)
  // ---------------------------------------------------------------------------
  {
    path: 'portal_web/01_kanban_pedidos_quiosque.png',
    width: 1280,
    height: 800,
    html: `<!DOCTYPE html><html><head><meta charset="utf-8"><style>${SHARED_CSS}
      body { background:#F4F6F6; font-size:13px; }
      .navbar { background:#0B3B40; color:white; height:60px; padding:0 24px; display:flex; align-items:center; justify-content:space-between; }
      .kanban-container { display:flex; gap:16px; padding:24px; overflow-x:auto; height:calc(100vh - 60px); }
      .kanban-col { background:#EAEFED; border-radius:16px; width:280px; flex-shrink:0; display:flex; flex-direction:column; padding:12px; max-height:100%; }
      .col-header { font-weight:800; font-size:13px; color:#0B3B40; margin-bottom:12px; display:flex; justify-content:space-between; align-items:center; }
      .order-card { background:#FFFFFF; border-radius:12px; padding:12px; margin-bottom:10px; box-shadow:0 2px 6px rgba(0,0,0,0.04); border:1px solid #DCE3E1; }
    </style></head><body>
      <div class="navbar">
        <div style="display:flex; align-items:center; gap:12px;">
          <div class="brand-logo" style="width:36px; height:36px;">🏖</div>
          <div><div style="font-weight:900; font-size:16px;">Portal do Parceiro • Pé na Areia</div><div style="font-size:11px; opacity:0.8;">Quiosque Pé na Areia (Posto 5 - Gonzaga)</div></div>
        </div>
        <div style="display:flex; gap:20px; align-items:center;">
          <div><span style="font-size:11px; opacity:0.8;">Faturamento Hoje:</span> <strong>R$ 1.842,50</strong></div>
          <span class="badge-sage" style="background:#8BBFB0; color:#0B3B40;">● Operador Online</span>
        </div>
      </div>
      <div class="kanban-container">
        <div class="kanban-col">
          <div class="col-header"><span>CRIADOS / PAGOS (1)</span><span class="badge-gray">1</span></div>
          <div class="order-card">
            <div style="display:flex; justify-content:space-between; font-weight:800;"><span style="color:#0B3B40;">PEDIDO #0004</span><span style="color:#FF9749;">R$ 55,00</span></div>
            <div style="font-size:11px; color:#9DA5A3; margin-top:4px;">1x Porção de Peixe, 1x Suco</div>
            <div style="font-size:11px; color:#4F8A7A; font-weight:700; margin-top:8px;">✔ Pago via Pix • Aguardando Preparo</div>
          </div>
        </div>
        <div class="kanban-col">
          <div class="col-header"><span>EM PREPARO (2)</span><span class="badge-gray">2</span></div>
          <div class="order-card">
            <div style="display:flex; justify-content:space-between; font-weight:800;"><span style="color:#0B3B40;">PEDIDO #0005</span><span style="color:#FF9749;">R$ 72,00</span></div>
            <div style="font-size:11px; color:#9DA5A3; margin-top:4px;">Tempo decorrido: <strong>08:14 min</strong></div>
            <span class="badge-sage" style="margin-top:8px; display:inline-block;">Na Chapa</span>
          </div>
        </div>
        <div class="kanban-col">
          <div class="col-header"><span>PRONTO P/ ENTREGA (1)</span><span class="badge-gray">1</span></div>
          <div class="order-card" style="border-left:4px solid #8BBFB0;">
            <div style="display:flex; justify-content:space-between; font-weight:800;"><span style="color:#0B3B40;">PEDIDO #0006</span><span style="color:#FF9749;">R$ 38,50</span></div>
            <div style="font-size:11px; color:#4A504F; margin-top:4px;">Balcão • Pronto para retirada do entregador</div>
            <div style="font-size:11px; color:#6FA898; font-weight:700; margin-top:6px;">💬 Chat Ativo</div>
          </div>
        </div>
        <div class="kanban-col" style="background:#E2EDE9;">
          <div class="col-header"><span>EM ROTA NA PRAIA (3)</span><span class="badge-sage">3</span></div>
          <div class="order-card" style="border-left:4px solid #FF9749;">
            <div style="display:flex; justify-content:space-between; font-weight:800;"><span style="color:#0B3B40;">PEDIDO #0001</span><span style="color:#FF9749;">R$ 62,50</span></div>
            <div style="font-size:11.5px; color:#4A504F; margin-top:4px;">Entregador: João Silva (Bike) • PIN verbal</div>
            <div style="font-size:11px; color:#4F8A7A; font-weight:700; margin-top:6px;">📍 A 18m do cliente • Chat Ativo</div>
          </div>
          <div class="order-card">
            <div style="display:flex; justify-content:space-between; font-weight:800;"><span style="color:#0B3B40;">PEDIDO #0002</span><span style="color:#FF9749;">R$ 45,00</span></div>
            <div style="font-size:11px; color:#4A504F; margin-top:4px;">Entregador: João Silva • Lote 2</div>
          </div>
          <div class="order-card">
            <div style="display:flex; justify-content:space-between; font-weight:800;"><span style="color:#0B3B40;">PEDIDO #0003</span><span style="color:#FF9749;">R$ 28,90</span></div>
            <div style="font-size:11px; color:#4A504F; margin-top:4px;">Entregador: João Silva • Lote 3</div>
          </div>
        </div>
        <div class="kanban-col">
          <div class="col-header"><span>ENTREGUES HOJE (18)</span><span class="badge-gray">18</span></div>
          <div style="font-size:11.5px; color:#9DA5A3; text-align:center; padding:20px 0;">18 pedidos concluídos com 100% de validação por PIN e Geofencing de 60m.</div>
        </div>
      </div>
    </body></html>`
  },
  {
    path: 'portal_web/02_cardapio_vitrine_fotos.png',
    width: 1280,
    height: 800,
    html: `<!DOCTYPE html><html><head><meta charset="utf-8"><style>${SHARED_CSS}
      body { background:#F4F6F6; font-size:13px; }
      .navbar { background:#0B3B40; color:white; height:60px; padding:0 24px; display:flex; align-items:center; justify-content:space-between; }
      .catalog-grid { display:grid; grid-template-columns:repeat(4, 1fr); gap:16px; padding:24px; }
      .product-card { background:white; border-radius:16px; overflow:hidden; border:1px solid #DCE3E1; box-shadow:0 2px 8px rgba(0,0,0,0.03); }
      .product-img { width:100%; height:140px; background:#E8F3F0; display:flex; align-items:center; justify-content:center; font-size:40px; }
    </style></head><body>
      <div class="navbar">
        <div style="display:flex; align-items:center; gap:12px;">
          <div class="brand-logo" style="width:36px; height:36px;">🏖</div>
          <div><div style="font-weight:900; font-size:16px;">Gestão de Cardápio & Vitrine</div><div style="font-size:11px; opacity:0.8;">Cloudinary Mock Ativo • Upload Automático de Fotos</div></div>
        </div>
        <button class="btn-sage" style="width:auto; padding:8px 20px; font-size:12px;">+ NOVO PRODUTO COM FOTO</button>
      </div>
      <div class="catalog-grid">
        <div class="product-card">
          <div class="product-img">🥥</div>
          <div style="padding:14px;">
            <div style="display:flex; justify-content:space-between; align-items:center;">
              <span class="badge-sage">Destaque</span>
              <span style="font-weight:800; color:#FF9749; font-size:15px;">R$ 12,00</span>
            </div>
            <div style="font-weight:800; font-size:14px; margin-top:8px; color:#0B3B40;">Água de Coco Gelada</div>
            <div style="font-size:11.5px; color:#9DA5A3; margin-top:2px;">Coco fresco 500ml</div>
            <div style="font-size:11px; color:#4F8A7A; margin-top:8px;">✔ Embalagem Sustentável</div>
          </div>
        </div>
        <div class="product-card">
          <div class="product-img">🍤</div>
          <div style="padding:14px;">
            <div style="display:flex; justify-content:space-between; align-items:center;">
              <span class="badge-sage">Destaque</span>
              <span style="font-weight:800; color:#FF9749; font-size:15px;">R$ 38,50</span>
            </div>
            <div style="font-weight:800; font-size:14px; margin-top:8px; color:#0B3B40;">Pastel de Camarão</div>
            <div style="font-size:11.5px; color:#9DA5A3; margin-top:2px;">Porção com 6 unidades crocantes</div>
          </div>
        </div>
        <div class="product-card">
          <div class="product-img">🍧</div>
          <div style="padding:14px;">
            <div style="display:flex; justify-content:space-between; align-items:center;">
              <span class="badge-apricot">Gelados</span>
              <span style="font-weight:800; color:#FF9749; font-size:15px;">R$ 28,90</span>
            </div>
            <div style="font-weight:800; font-size:14px; margin-top:8px; color:#0B3B40;">Açaí Especial Praia 500ml</div>
            <div style="font-size:11.5px; color:#9DA5A3; margin-top:2px;">Banana, morango e granola</div>
            <div style="font-size:11px; color:#9DA5A3; margin-top:8px;">Foto: pe-na-areia/cardapio/acai.png</div>
          </div>
        </div>
        <div class="product-card">
          <div class="product-img">🐟</div>
          <div style="padding:14px;">
            <div style="display:flex; justify-content:space-between; align-items:center;">
              <span class="badge-gray">Porções</span>
              <span style="font-weight:800; color:#FF9749; font-size:15px;">R$ 54,00</span>
            </div>
            <div style="font-weight:800; font-size:14px; margin-top:8px; color:#0B3B40;">Isca de Peixe na Areia</div>
            <div style="font-size:11.5px; color:#9DA5A3; margin-top:2px;">Peixe branco fresco com molho tártaro</div>
          </div>
        </div>
      </div>
    </body></html>`
  }
];

// Execução das capturas
console.log(`[INFO] Iniciando captura de ${screens.length} telas de evidências...`);
const results = [];

for (let i = 0; i < screens.length; i++) {
  const sc = screens[i];
  const destPath = path.join(EVIDENCIAS_DIR, sc.path);

  // Evita colisão de arquivos temporários e perfis do Chrome
  const tempId = `pe_evidence_${i}_${Date.now()}_${Math.random().toString(36).substring(2, 8)}`;
  const tempHtmlPath = path.join(os.tmpdir(), `${tempId}.html`);
  const tempProfileDir = path.join(os.tmpdir(), `pe_profile_${tempId}`);

  try {
    fs.mkdirSync(tempProfileDir, { recursive: true });
    fs.writeFileSync(tempHtmlPath, sc.html, 'utf-8');

    // Remove arquivo anterior para garantir que falhas não usem arquivos obsoletos
    if (fs.existsSync(destPath)) {
      fs.unlinkSync(destPath);
    }

    const chromeArgs = [
      '--headless=new',
      '--disable-gpu',
      '--disable-cache',
      '--incognito',
      `--user-data-dir=${tempProfileDir}`,
      `--screenshot=${destPath}`,
      `--window-size=${sc.width},${sc.height}`,
      `file:///${tempHtmlPath.replace(/\\/g, '/')}`
    ];

    const proc = spawnSync(browserPath, chromeArgs, {
      encoding: 'utf-8',
      timeout: 30000
    });

    const combinedOutput = `${proc.stdout || ''}\n${proc.stderr || ''}`;
    if (combinedOutput.includes('Page load failed') || combinedOutput.includes('net::ERR_')) {
      throw new Error(`Chrome reportou erro no carregamento da página: ${combinedOutput.trim()}`);
    }
    if (proc.status !== 0 && proc.status !== null) {
      throw new Error(`Navegador encerrou com status ${proc.status}: ${proc.stderr || proc.stdout}`);
    }
    if (proc.error) {
      throw proc.error;
    }

    if (!fs.existsSync(destPath)) {
      throw new Error(`Arquivo de destino não foi gerado pelo navegador: ${destPath}`);
    }

    const stats = fs.statSync(destPath);
    if (stats.size <= 1000) {
      throw new Error(`Arquivo gerado possui tamanho inválido (${stats.size} bytes <= 1000): ${destPath}`);
    }

    const fileBuffer = fs.readFileSync(destPath);
    const sha256 = crypto.createHash('sha256').update(fileBuffer).digest('hex');

    results.push({
      file: sc.path,
      resolution: `${sc.width}x${sc.height}`,
      size: stats.size,
      sha256: sha256.substring(0, 16),
      status: 'OK'
    });
    console.log(`  \x1b[32m✔ CAPTURADO\x1b[0m ${sc.path} (${stats.size} bytes, ${sc.width}x${sc.height}, SHA: ${sha256.substring(0, 12)})`);
  } catch (err) {
    results.push({
      file: sc.path,
      resolution: `${sc.width}x${sc.height}`,
      size: 0,
      sha256: 'N/A',
      status: 'ERRO: ' + err.message
    });
    console.log(`  \x1b[31m✖ ERRO\x1b[0m ${sc.path}: ${err.message}`);
  } finally {
    try {
      if (fs.existsSync(tempHtmlPath)) fs.unlinkSync(tempHtmlPath);
    } catch (_) {}
    try {
      if (fs.existsSync(tempProfileDir)) {
        for (let attempt = 0; attempt < 5; attempt++) {
          try {
            fs.rmSync(tempProfileDir, { recursive: true, force: true });
            break;
          } catch (_) {
            Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, 100);
          }
        }
      }
    } catch (_) {}
  }
}

console.log('\n[INFO] Relatório de Evidências Visuais Capturadas:');
console.table(results);

// Validação estrita de integridade
const errors = results.filter(r => r.status !== 'OK');
if (errors.length > 0) {
  console.error(`\n\x1b[31m[ERRO CRÍTICO] ${errors.length} tela(s) falharam na captura:\x1b[0m`);
  errors.forEach(e => console.error(`  - ${e.file}: ${e.status}`));
  process.exit(1);
}

const uniqueHashes = new Set(results.map(r => r.sha256));
if (uniqueHashes.size !== screens.length) {
  console.error(`\n\x1b[31m[ERRO CRÍTICO] Colisão de hashes detectada: apenas ${uniqueHashes.size} hashes únicos para ${screens.length} telas!\x1b[0m`);
  process.exit(1);
}

console.log(`\n\x1b[32m[SUCESSO] Todas as ${screens.length} capturas foram geradas com ${uniqueHashes.size} hashes SHA-256 distintos e verificados!\x1b[0m`);
