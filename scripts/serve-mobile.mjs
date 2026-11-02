import http from 'http';
import fs from 'fs';
import path from 'path';
import os from 'os';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const rootDir = path.resolve(__dirname, '..');

const apks = {
  cliente: {
    name: 'App do Cliente (Banista)',
    badge: 'Pedidos & Farol Visual',
    icon: '🏖️',
    path: path.join(rootDir, 'dist-mobile', 'cliente', 'pe-na-areia-cliente.apk'),
    route: '/cliente.apk',
    fallbackPath: path.join(rootDir, 'apps', 'app_cliente', 'build', 'app', 'outputs', 'flutter-apk', 'app-release.apk'),
    desc: 'Catálogo de quiosques, pin do guarda-sol, pagamento Pix, Farol de Tela Cheia e Live Tracking.'
  },
  entregador: {
    name: 'App do Entregador (Courier)',
    badge: 'Radar & Bússola na Areia',
    icon: '🧭',
    path: path.join(rootDir, 'dist-mobile', 'entregador', 'pe-na-areia-entregador.apk'),
    route: '/entregador.apk',
    fallbackPath: path.join(rootDir, 'apps', 'app_entregador', 'build', 'app', 'outputs', 'flutter-apk', 'app-release.apk'),
    desc: 'Modo Bússola / Radar Pedestre na areia, telemetria GPS contínua e confirmação de entrega a 60m.'
  },
  prototipo: {
    name: 'Protótipo Interativo',
    badge: 'Showcase & Demonstração',
    icon: '📱',
    path: path.join(rootDir, 'dist-mobile', 'prototipo', 'pe-na-areia-prototipo.apk'),
    route: '/prototipo.apk',
    fallbackPath: path.join(rootDir, 'apps', 'app_prototipo', 'build', 'app', 'outputs', 'flutter-apk', 'app-release.apk'),
    desc: 'Showcase completo com mapa de fluxos, simulação lado a lado e tela de Splash de Santos.'
  }
};

function getLanIp() {
  const nets = os.networkInterfaces();
  let fallbackIp = null;

  for (const name of Object.keys(nets)) {
    for (const net of nets[name]) {
      if (net.family === 'IPv4' && !net.internal) {
        if (/wi-fi|wlan|wireless/i.test(name)) {
          return net.address;
        }
        if (!fallbackIp && (net.address.startsWith('192.168.') || net.address.startsWith('10.'))) {
          fallbackIp = net.address;
        }
      }
    }
  }
  return fallbackIp || '192.168.0.4';
}

const lanIp = process.env.LAN_IP || getLanIp();
const port = parseInt(process.env.DOWNLOAD_PORT || '8088', 10);
const backendUrl = `http://${lanIp}:8080`;

function getApkFilePath(key) {
  const apk = apks[key];
  if (!apk) return null;
  if (fs.existsSync(apk.path)) return apk.path;
  if (fs.existsSync(apk.fallbackPath)) return apk.fallbackPath;
  return null;
}

function renderHtml() {
  const cardsHtml = Object.entries(apks).map(([key, item]) => {
    const targetFile = getApkFilePath(key);
    let sizeText = 'Disponível para compilação';
    let isReady = false;

    if (targetFile) {
      isReady = true;
      const stats = fs.statSync(targetFile);
      sizeText = `${(stats.size / (1024 * 1024)).toFixed(1)} MB · Pronto`;
    }

    return `
      <div class="app-card ${isReady ? 'ready' : 'pending'}">
        <div class="card-head">
          <span class="app-icon">${item.icon}</span>
          <div>
            <h3 class="app-title">${item.name}</h3>
            <span class="badge">${item.badge}</span>
          </div>
        </div>
        <p class="app-desc">${item.desc}</p>
        <div class="card-action">
          <a href="${item.route}" class="btn-download ${isReady ? '' : 'disabled'}" download>
            <span>📥</span>
            <span>${isReady ? 'Baixar APK' : 'Gerando build...'}</span>
          </a>
          <span class="apk-size">${sizeText}</span>
        </div>
      </div>
    `;
  }).join('');

  return `<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>Pé na Areia · Central de Aplicativos Mobile</title>
  <style>
    :root {
      --ocean-900: #092C32;
      --ocean-800: #0C383F;
      --ocean-700: #0E5C63;
      --sage-500: #8BBFB0;
      --sage-100: #E8F3F0;
      --sand-50: #F8F6F0;
      --apricot-500: #FF9749;
      --surface: #FFFFFF;
      --ink: #1C2E35;
      --ink-muted: #5A6D72;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      background: linear-gradient(180deg, #0C383F 0%, #0E5C63 320px, #F8F6F0 320px, #F8F6F0 100%);
      min-height: 100vh;
      color: var(--ink);
      padding: 24px 16px 40px;
    }
    .container { max-width: 520px; margin: 0 auto; }
    .header { text-align: center; color: #FFFFFF; padding-bottom: 24px; }
    .logo-badge {
      width: 72px; height: 72px; background: #FFFFFF; border-radius: 24px;
      margin: 0 auto 16px; display: flex; align-items: center; justify-content: center;
      box-shadow: 0 10px 25px rgba(0,0,0,0.25);
    }
    .logo-badge svg { width: 50px; height: 50px; }
    .title { font-size: 26px; font-weight: 800; letter-spacing: -0.5px; margin-bottom: 6px; }
    .subtitle { font-size: 13.5px; color: rgba(255,255,255,0.85); }
    .status-badge {
      display: inline-flex; align-items: center; gap: 8px;
      background: rgba(255,255,255,0.15); color: #FFFFFF;
      padding: 6px 14px; border-radius: 999px; font-size: 12px; font-weight: 700;
      margin-top: 12px; border: 1px solid rgba(255,255,255,0.25);
    }
    .pulse-dot {
      width: 8px; height: 8px; border-radius: 50%; background: #10B981;
      box-shadow: 0 0 0 3px rgba(16, 185, 129, 0.35);
    }
    .app-card {
      background: var(--surface); border-radius: 22px; padding: 20px;
      box-shadow: 0 8px 28px rgba(12, 56, 63, 0.08); border: 1px solid rgba(0,0,0,0.06);
      margin-bottom: 18px;
    }
    .card-head { display: flex; gap: 14px; align-items: center; margin-bottom: 10px; }
    .app-icon { font-size: 32px; line-height: 1; }
    .app-title { font-size: 18px; font-weight: 800; color: var(--ocean-800); }
    .badge {
      display: inline-block; font-size: 11px; font-weight: 700;
      background: var(--sage-100); color: var(--ocean-700);
      padding: 2px 8px; border-radius: 6px; margin-top: 2px;
    }
    .app-desc { font-size: 13px; color: var(--ink-muted); line-height: 1.45; margin-bottom: 14px; }
    .card-action { display: flex; align-items: center; justify-content: space-between; gap: 10px; }
    .btn-download {
      display: inline-flex; align-items: center; justify-content: center; gap: 8px;
      background: var(--apricot-500); color: #FFFFFF; text-decoration: none;
      font-size: 14.5px; font-weight: 800; padding: 12px 20px; border-radius: 999px;
      box-shadow: 0 6px 18px rgba(255, 151, 73, 0.35); flex: 1; text-align: center;
    }
    .btn-download.disabled {
      background: #D1D5DB; box-shadow: none; pointer-events: none;
    }
    .apk-size { font-size: 11.5px; color: var(--ink-muted); font-weight: 600; white-space: nowrap; }
    .server-card {
      background: #FFFFFF; border-radius: 18px; padding: 16px;
      border: 1px solid #ECECEC; font-size: 12px; margin-top: 10px;
    }
    .server-row { display: flex; justify-content: space-between; margin-bottom: 6px; }
    .server-row:last-child { margin-bottom: 0; }
    .label { color: var(--ink-muted); font-weight: 600; }
    .val { font-family: monospace; font-weight: 700; color: var(--ocean-800); }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo-badge">
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 240 240">
          <circle cx="172" cy="62" r="32" fill="#FFA500" />
          <rect x="50" y="180" width="140" height="26" rx="13" fill="#E8D5B5" />
          <line x1="118" y1="108" x2="134" y2="190" stroke="#1C2E35" stroke-width="7" stroke-linecap="round" />
          <circle cx="106" cy="46" r="4.5" fill="#1C2E35" />
          <path d="M 106,46 C 88,52 64,74 42,126 C 40,131 43,138 48,138 C 55,138 64,136 70,131 C 78,88 95,58 106,46 Z" fill="#E52E2D" />
          <path d="M 106,46 C 95,58 78,88 70,131 C 76,135 86,136 94,136 C 99,96 104,64 106,46 Z" fill="#FFFFFF" />
          <path d="M 106,46 C 104,64 99,96 94,136 C 104,136 122,134 134,130 C 128,90 118,62 106,46 Z" fill="#E52E2D" />
          <path d="M 106,46 C 118,62 128,90 134,130 C 144,126 156,122 164,116 C 150,80 132,58 106,46 Z" fill="#FFFFFF" />
          <path d="M 106,46 C 132,58 150,80 164,116 C 172,110 184,102 188,96 C 188,94 186,90 182,82 C 166,60 140,48 106,46 Z" fill="#E52E2D" />
          <path d="M 46,136 Q 58,137 70,131 Q 82,136 94,136 Q 114,135 134,130 Q 149,124 164,116 Q 176,106 188,96" 
                fill="none" stroke="#FFFFFF" stroke-width="4.5" stroke-linecap="round" stroke-linejoin="round" />
        </svg>
      </div>
      <h1 class="title">Pé na Areia</h1>
      <p class="subtitle">Central de Aplicativos Mobile · Orla de Santos</p>
      <div class="status-badge">
        <span class="pulse-dot"></span>
        <span>Backend Wi-Fi Conectado (${lanIp}:8080)</span>
      </div>
    </div>

    ${cardsHtml}

    <div class="server-card">
      <div class="server-row">
        <span class="label">API Backend:</span>
        <span class="val">${backendUrl}</span>
      </div>
      <div class="server-row">
        <span class="label">Rede Wi-Fi:</span>
        <span class="val">${lanIp}</span>
      </div>
      <div class="server-row">
        <span class="label">Status:</span>
        <a class="val" href="${backendUrl}/reference-points" target="_blank" style="text-decoration: underline;">Testar /reference-points</a>
      </div>
    </div>
  </div>
</body>
</html>`;
}

const server = http.createServer((req, res) => {
  const url = req.url || '/';

  if (url === '/' || url === '/index.html') {
    res.writeHead(200, {
      'Content-Type': 'text/html; charset=utf-8',
      'Cache-Control': 'no-cache',
    });
    res.end(renderHtml());
    return;
  }

  // Route matches
  for (const [key, item] of Object.entries(apks)) {
    if (url === item.route || (url === '/pe-na-areia.apk' && key === 'cliente')) {
      const filePath = getApkFilePath(key);
      if (!filePath || !fs.existsSync(filePath)) {
        res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
        res.end(`APK ${item.name} não encontrado. Execute: .\\scripts\\build-all.ps1 -Target ${key}`);
        return;
      }

      const stats = fs.statSync(filePath);
      res.writeHead(200, {
        'Content-Type': 'application/vnd.android.package-archive',
        'Content-Length': stats.size,
        'Content-Disposition': `attachment; filename="${path.basename(filePath)}"`,
        'Cache-Control': 'no-cache',
      });

      fs.createReadStream(filePath).pipe(res);
      return;
    }
  }

  res.writeHead(404, { 'Content-Type': 'text/plain' });
  res.end('404 Not Found');
});

server.listen(port, '0.0.0.0', () => {
  console.log('\n================================================================');
  console.log('🏖️  PÉ NA AREIA — CENTRAL DE APLICATIVOS MOBILE NA REDE WI-FI');
  console.log('================================================================');
  console.log(`\n📱 Acesse no navegador do seu smartphone:`);
  console.log(`\n👉  http://${lanIp}:${port}\n`);
  console.log(`📦 Aplicativos disponíveis para download:`);
  console.log(`    🏖️  Cliente:    http://${lanIp}:${port}/cliente.apk`);
  console.log(`    🧭  Entregador: http://${lanIp}:${port}/entregador.apk`);
  console.log(`    📱  Protótipo:  http://${lanIp}:${port}/prototipo.apk\n`);
  console.log(`⚙️  API Backend: ${backendUrl}`);
  console.log('================================================================\n');
});
