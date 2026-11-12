# =============================================================================
# Pé na Areia — Script de Captura Automatizada de Evidências Visuais (PowerShell)
# =============================================================================
# Executa a geração de capturas de tela das 13 telas do Pé na Areia
# utilizando Google Chrome Headless ou Microsoft Edge fallback.
# =============================================================================

param(
    [string]$NodeExe = "node"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host " Pé na Areia — Captura Automatizada de Evidências Visuais (QA) " -ForegroundColor Cyan
Write-Host "========================================================================" -ForegroundColor Cyan

$scriptMjs = Join-Path $PSScriptRoot "capture-evidence.mjs"

if (-not (Test-Path $scriptMjs)) {
    Write-Error "Arquivo capture-evidence.mjs não encontrado em: $scriptMjs"
    exit 1
}

Write-Host "[INFO] Executando captura visual com Node.js..." -ForegroundColor Yellow
& $NodeExe $scriptMjs

if ($LASTEXITCODE -ne 0) {
    Write-Error "Falha na captura de evidências visuais."
    exit $LASTEXITCODE
}

Write-Host "`n[SUCESSO] Todas as evidências visuais foram geradas em evidencias/ com sucesso!" -ForegroundColor Green
