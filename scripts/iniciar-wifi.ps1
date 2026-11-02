# ==============================================================================
# 🏖️ Pé na Areia — Iniciar Backend na Rede Wi-Fi & Servidor de Download Mobile
# ==============================================================================
# Execução: .\scripts\iniciar-wifi.ps1

Write-Host "`n🔍 Detectando endereço IPv4 da rede Wi-Fi..." -ForegroundColor Cyan

$wifiIp = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
    $_.InterfaceAlias -like "*Wi-Fi*" -or $_.InterfaceAlias -like "*WLAN*" -or $_.InterfaceAlias -like "*Wireless*" 
} | Select-Object -ExpandProperty IPAddress -First 1)

if (-not $wifiIp) {
    # Fallback para IP de rede local privada
    $wifiIp = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
        $_.IPAddress -like "192.168.*" -or $_.IPAddress -like "10.*" 
    } | Select-Object -ExpandProperty IPAddress -First 1)
}

if (-not $wifiIp) {
    $wifiIp = "192.168.0.4"
}

Write-Host "✅ IP Wi-Fi identificado: $wifiIp" -ForegroundColor Green
$downloadPort = 8088
$backendUrl = "http://${wifiIp}:8080"
$cdnUrl = "http://${wifiIp}:8099"

# 1. Regra de Firewall do Windows
Write-Host "`n🛡️  Verificando regras de entrada no Firewall do Windows..." -ForegroundColor Cyan
try {
    $rule = Get-NetFirewallRule -DisplayName "*Pe na Areia LAN*" -ErrorAction SilentlyContinue
    if (-not $rule) {
        New-NetFirewallRule -DisplayName "Pe na Areia LAN" -Direction Inbound -LocalPort 8080,8099,$downloadPort -Protocol TCP -Action Allow -ErrorAction SilentlyContinue | Out-Null
    }
} catch {
    # Caso não esteja rodando como admin, continua normalmente
}

# 2. Verificar o arquivo APK em dist-mobile/
$apkDest = "dist-mobile\pe-na-areia.apk"
$flutterApk = "frontend\build\app\outputs\flutter-apk\app-release.apk"

if (-not (Test-Path $apkDest)) {
    if (Test-Path $flutterApk) {
        New-Item -ItemType Directory -Force -Path "dist-mobile" | Out-Null
        Copy-Item $flutterApk $apkDest -Force
    } else {
        Write-Host "`n📦 Compilando APK do Flutter apontando para $backendUrl..." -ForegroundColor Yellow
        Push-Location frontend
        flutter build apk --release --dart-define=API_BASE_URL=$backendUrl
        Pop-Location
        New-Item -ItemType Directory -Force -Path "dist-mobile" | Out-Null
        Copy-Item $flutterApk $apkDest -Force
    }
}

# 3. Subir containers Docker do Backend na rede local
Write-Host "`n🐳 Iniciando containers Docker (MongoDB, Cloudinary Mock e Backend Spring Boot)..." -ForegroundColor Cyan
$env:CLOUDINARY_PUBLIC_BASE_URL = $cdnUrl
$env:APP_CORS_ORIGINS = "http://localhost:*,http://127.0.0.1:*,http://192.168.*:*,http://10.*:*,http://*.sslip.io:*"
docker compose -f infrastructure/docker-compose.yml up -d

Write-Host "`n⏳ Aguardando inicialização da API..." -ForegroundColor Cyan
Start-Sleep -Seconds 3

# 4. Iniciar servidor de download do aplicativo
Write-Host "`n📱 Iniciando servidor de download para o seu celular..." -ForegroundColor Green
$env:LAN_IP = $wifiIp
$env:DOWNLOAD_PORT = "$downloadPort"
node scripts/serve-mobile.mjs

