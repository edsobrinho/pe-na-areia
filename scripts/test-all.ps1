# ==============================================================================
# Pe na Areia - Executar Todos os Testes do Monorepo
# ==============================================================================
param(
    [switch]$SkipAnalyze = $false
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

$projects = @(
    "packages/core_shared",
    "apps/app_cliente",
    "apps/app_entregador",
    "apps/app_prototipo"
)

Write-Host "INICIANDO SUITE COMPLETA DE TESTES DO ECOSSISTEMA MOBILE..." -ForegroundColor Cyan

foreach ($proj in $projects) {
    $fullPath = Join-Path $root $proj
    Write-Host "Testando projeto: $proj" -ForegroundColor Yellow
    Push-Location $fullPath
    try {
        if (-not $SkipAnalyze) {
            Write-Host "   flutter analyze..." -ForegroundColor Gray
            flutter analyze
            if ($LASTEXITCODE -ne 0) {
                throw "flutter analyze falhou em $proj (exit code $LASTEXITCODE)"
            }
        }
        Write-Host "   flutter test..." -ForegroundColor Gray
        flutter test
        if ($LASTEXITCODE -ne 0) {
            throw "flutter test falhou em $proj (exit code $LASTEXITCODE)"
        }
        Write-Host "   [OK] $($proj) - Todos os testes passaram com sucesso!" -ForegroundColor Green
    } finally {
        Pop-Location
    }
}

Write-Host "TODOS OS TESTES DOS 4 MODULOS PASSARAM COM SUCESSO!" -ForegroundColor Green
