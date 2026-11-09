# ==============================================================================
# Pe na Areia - Compilador Multi-App (Cliente, Entregador e Prototipo)
# ==============================================================================
param(
    [ValidateSet("all", "cliente", "entregador", "prototipo")]
    [string]$Target = "all",

    [string]$ApiBaseUrl = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

if (-not $ApiBaseUrl) {
    $wifiIp = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
        $_.InterfaceAlias -like "*Wi-Fi*" -or $_.InterfaceAlias -like "*WLAN*" -or $_.InterfaceAlias -like "*Wireless*" 
    } | Select-Object -ExpandProperty IPAddress -First 1)

    if (-not $wifiIp) {
        $wifiIp = "192.168.0.4"
    }
    $ApiBaseUrl = "http://${wifiIp}:8080"
}

Write-Host "INICIANDO COMPILACAO DOS APLICATIVOS PE NA AREIA" -ForegroundColor Cyan
Write-Host "API Base URL: $ApiBaseUrl" -ForegroundColor Yellow

$appsToBuild = @()
if ($Target -eq "all" -or $Target -eq "cliente") {
    $appsToBuild += [PSCustomObject]@{
        Name = "Cliente"
        Path = "apps/app_cliente"
        OutDir = "dist-mobile/cliente"
        OutApk = "pe-na-areia-cliente.apk"
        WithApi = $true
    }
}
if ($Target -eq "all" -or $Target -eq "entregador") {
    $appsToBuild += [PSCustomObject]@{
        Name = "Entregador"
        Path = "apps/app_entregador"
        OutDir = "dist-mobile/entregador"
        OutApk = "pe-na-areia-entregador.apk"
        WithApi = $true
    }
}
if ($Target -eq "all" -or $Target -eq "prototipo") {
    $appsToBuild += [PSCustomObject]@{
        Name = "Prototipo"
        Path = "apps/app_prototipo"
        OutDir = "dist-mobile/prototipo"
        OutApk = "pe-na-areia-prototipo.apk"
        WithApi = $false
    }
}

foreach ($app in $appsToBuild) {
    Write-Host "Compilando App do $($app.Name)..." -ForegroundColor Cyan
    $appFolder = Join-Path $root $app.Path
    $targetDir = Join-Path $root $app.OutDir
    New-Item -ItemType Directory -Force -Path $targetDir | Out-Null

    Push-Location $appFolder
    try {
        if ($app.WithApi) {
            flutter build apk --release --dart-define=API_BASE_URL=$ApiBaseUrl
        } else {
            flutter build apk --release
        }

        $builtApk = Join-Path $appFolder "build/app/outputs/flutter-apk/app-release.apk"
        $destFile = Join-Path $targetDir $app.OutApk
        Copy-Item $builtApk $destFile -Force

        Write-Host "   [OK] $($app.Name) gerado em: $($app.OutDir)/$($app.OutApk)" -ForegroundColor Green
    } finally {
        Pop-Location
    }
}

Write-Host "COMPILACAO FINALIZADA COM SUCESSO!" -ForegroundColor Green
