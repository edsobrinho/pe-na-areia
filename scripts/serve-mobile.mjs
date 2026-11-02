import http from 'http';
import fs from 'fs';
import path from 'path';
import os from 'os';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const rootDir = path.resolve(__dirname, '..');
const apkPath = path.join(rootDir, 'dist-mobile', 'pe-na-areia.apk');

// Detect active LAN/Wi-Fi IPv4 address
function getLanIp() {
  const nets = os.networkInterfaces();
  let wifiIp = null;
  let fallbackIp = null;

  for (const name of Object.keys(nets)) {
    for (const net of nets[name]) {
      // Skip over non-IPv4 and internal (i.e. 127.0.0.1) addresses
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
  return wifiIp || fallbackIp || '192.168.0.4';
}

const lanIp = process.env.LAN_IP || getLanIp();
const port = parseInt(process.env.DOWNLOAD_PORT || '8088', 10);
const backendUrl = `http://${lanIp}:8080`;

function renderHtml(apkSizeMb) {
  return `<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>Pé na Areia · Download do App Android</title>
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
      background: linear-gradient(180deg, #0C383F 0%, #0E5C63 45%, #F8F6F0 45%, #F8F6F0 100%);
      min-height: 100vh;
      color: var(--ink);
      padding: 24px 16px 40px;
    }
    .container {
      max-width: 480px;
      margin: 0 auto;
    }
    .header {
      text-align: center;
      color: #FFFFFF;
      padding-bottom: 24px;
    }
    .logo-badge {
      width: 72px;
      height: 72px;
      background: #FFFFFF;
      border-radius: 24px;
      margin: 0 auto 16px;
      display: flex;
      align-items: center;
      justify-content: center;
      box-shadow: 0 10px 25px rgba(0,0,0,0.25);
    }
    .logo-badge svg { width: 50px; height: 50px; }
    .title {
      font-size: 26px;
      font-weight: 800;
      letter-spacing: -0.5px;
      margin-bottom: 6px;
    }
    .subtitle {
      font-size: 13.5px;
      color: rgba(255,255,255,0.85);
      line-height: 1.4;
    }
    .card {
      background: var(--surface);
      border-radius: 24px;
      padding: 24px 20px;
      box-shadow: 0 12px 36px rgba(12, 56, 63, 0.12);
      border: 1px solid rgba(0,0,0,0.06);
      margin-bottom: 20px;
    }
    .status-badge {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      background: var(--sage-100);
      color: #0E5C63;
      padding: 6px 14px;
      border-radius: 999px;
      font-size: 12px;
      font-weight: 700;
      margin-bottom: 16px;
    }
    .pulse-dot {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background: #10B981;
      box-shadow: 0 0 0 3px rgba(16, 185, 129, 0.25);
    }
    .btn-download {
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 10px;
      background: #FF9749;
      color: #FFFFFF;
      text-decoration: none;
      font-size: 18px;
      font-weight: 800;
      padding: 16px 20px;
      border-radius: 999px;
      box-shadow: 0 8px 24px rgba(255, 151, 73, 0.4);
      transition: transform 0.1s ease;
      text-align: center;
    }
    .btn-download:active {
      transform: scale(0.98);
    }
    .btn-meta {
      display: block;
      text-align: center;
      font-size: 12px;
      color: var(--ink-muted);
      margin-top: 10px;
    }
    .steps {
      margin-top: 24px;
      border-top: 1px solid #ECECEC;
      padding-top: 20px;
    }
    .steps-title {
      font-size: 14px;
      font-weight: 800;
      text-transform: uppercase;
      letter-spacing: 0.8px;
      color: var(--ocean-800);
      margin-bottom: 14px;
    }
    .step-item {
      display: flex;
      gap: 12px;
      margin-bottom: 14px;
    }
    .step-num {
      width: 28px;
      height: 28px;
      border-radius: 50%;
      background: #E8F3F0;
      color: #0E5C63;
      font-size: 13px;
      font-weight: 800;
      display: flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
    }
    .step-text {
      font-size: 13.5px;
      line-height: 1.4;
      color: var(--ink);
    }
    .step-text strong {
      color: var(--ocean-800);
    }
    .server-card {
      background: #FFFFFF;
      border-radius: 18px;
      padding: 16px;
      border: 1px solid #ECECEC;
      font-size: 12.5px;
    }
    .server-row {
      display: flex;
      justify-content: space-between;
      margin-bottom: 8px;
    }
    .server-row:last-child { margin-bottom: 0; }
    .label { color: var(--ink-muted); font-weight: 600; }
    .val { font-family: monospace; font-weight: 700; color: var(--ocean-800); word-break: break-all; }
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
      <p class="subtitle">Instalação direta no celular · Orla de Santos</p>
    </div>

    <div class="card">
      <div class="status-badge" id="status-badge">
        <span class="pulse-dot"></span>
        <span id="status-text">Backend Wi-Fi Conectado (${lanIp}:8080)</span>
      </div>

      <a href="/pe-na-areia.apk" class="btn-download" download="pe-na-areia.apk">
        <span>📥</span>
        <span>Baixar Aplicativo (.apk)</span>
      </a>
      <span class="btn-meta">Tamanho: ~${apkSizeMb} MB · Android 7.0+ (Release Build)</span>

      <div class="steps">
        <div class="steps-title">3 Passos para Instalar</div>
        <div class="step-item">
          <div class="step-num">1</div>
          <div class="step-text">Toque no botão laranja acima para <strong>baixar o arquivo pe-na-areia.apk</strong>.</div>
        </div>
        <div class="step-item">
          <div class="step-num">2</div>
          <div class="step-text">Abra o arquivo baixado nas notificações e, se solicitado, autorize <strong>"Instalar aplicativos de fontes desconhecidas"</strong> no navegador.</div>
        </div>
        <div class="step-item">
          <div class="step-num">3</div>
          <div class="step-text">Abra o app <strong>Pé na Areia</strong>! Ele já se conectará automaticamente à API rodando no computador.</div>
        </div>
      </div>
    </div>

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
        <span class="label">Teste Rápido:</span>
        <a class="val" href="${backendUrl}/reference-points" target="_blank" style="text-decoration: underline;">Abrir /reference-points</a>
      </div>
    </div>
  </div>
</body>
</html>`;
}

const server = http.createServer((req, res) => {
  const url = req.url || '/';

  if (url === '/' || url === '/index.html') {
    let apkSizeMb = '49.6';
    if (fs.existsSync(apkPath)) {
      const stats = fs.statSync(apkPath);
      apkSizeMb = (stats.size / (1024 * 1024)).toFixed(1);
    }
    res.writeHead(200, {
      'Content-Type': 'text/html; charset=utf-8',
      'Cache-Control': 'no-cache',
    });
    res.end(renderHtml(apkSizeMb));
    return;
  }

  if (url === '/pe-na-areia.apk' || url === '/app.apk') {
    if (!fs.existsSync(apkPath)) {
      res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end('APK não encontrado. Execute: flutter build apk --release');
      return;
    }

    const stats = fs.statSync(apkPath);
    res.writeHead(200, {
      'Content-Type': 'application/vnd.android.package-archive',
      'Content-Length': stats.size,
      'Content-Disposition': 'attachment; filename="pe-na-areia.apk"',
      'Cache-Control': 'no-cache',
    });

    const stream = fs.createReadStream(apkPath);
    stream.pipe(res);
    return;
  }

  res.writeHead(404, { 'Content-Type': 'text/plain' });
  res.end('404 Not Found');
});

server.listen(port, '0.0.0.0', () => {
  console.log('\n================================================================');
  console.log('🏖️  PÉ NA AREIA — SERVIDOR DE DOWNLOAD DO APP NO CELULAR');
  console.log('================================================================');
  console.log(`\n📱 No navegador do seu celular (conectado ao mesmo Wi-Fi), acesse:`);
  console.log(`\n👉  http://${lanIp}:${port}\n`);
  console.log(`🔗 Link direto do arquivo APK:`);
  console.log(`    http://${lanIp}:${port}/pe-na-areia.apk\n`);
  console.log(`⚙️  API Backend configurada:`);
  console.log(`    ${backendUrl}`);
  console.log('================================================================\n');
});

