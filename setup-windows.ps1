<#
.SYNOPSIS
  Atelier Wildcard — setup per Windows.
  Verifica il PC, installa Ollama se manca, scarica il modello, chiede la cartella di export.
.EXAMPLE
  powershell -ExecutionPolicy Bypass -File setup-windows.ps1
  powershell -ExecutionPolicy Bypass -File setup-windows.ps1 -Model "qwen3:14b" -ExportDir "D:\ComfyUI\custom_nodes\comfyui-impact-pack\custom_wildcards" -Yes
#>
param(
  [string]$Model = "qwen3.5:9b",
  [string]$ExportDir = "",
  [switch]$Yes
)
if ($env:MODEL -and $Model -eq "qwen3.5:9b") { $Model = $env:MODEL }
if ($env:EXPORT_DIR -and $ExportDir -eq "") { $ExportDir = $env:EXPORT_DIR }

$ErrorActionPreference = "Stop"
if ([string]::IsNullOrWhiteSpace($Model)) { Write-Err "Parametro -Model vuoto. Esempio: -Model 'qwen3.5:9b'"; exit 1 }

function Write-Ok($m)   { Write-Host "✅ $m" -ForegroundColor Green }
function Write-Warn($m) { Write-Host "⚠️  $m" -ForegroundColor Yellow }
function Write-Info($m) { Write-Host "▸ $m" -ForegroundColor Cyan }
function Write-Err($m)  { Write-Host "❌ $m" -ForegroundColor Red }

function Ask-Default($question, $default) {
  if ($Yes) { return $default }
  $ans = Read-Host "$question [$default]"
  if ([string]::IsNullOrWhiteSpace($ans)) { return $default }
  return $ans.Trim()
}

function Test-OllamaUp() {
  try {
    $r = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 3
    return $true
  } catch { return $false }
}

Write-Host "=============================================="
Write-Host " 🎭 ATELIER WILDCARD — setup WINDOWS"
Write-Host " ComfyUI Impact Pack + Ollama ($Model)"
Write-Host "=============================================="

# 1. Requisiti base
$os = (Get-CimInstance Win32_OperatingSystem).Caption
$ramGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
$diskFree = (Get-PSDrive C).Free / 1GB
Write-Info "Sistema: $os"
Write-Host "   RAM: $ramGB GB  |  Disco C libero: $([math]::Round($diskFree,1)) GB"
if ($ramGB -lt 8) { Write-Warn "Meno di 8 GB di RAM: $Model (~6.6 GB) potrebbe faticare. Valuta un modello più piccolo." }
try {
  $gpu = (Get-CimInstance Win32_VideoController | Select-Object -ExpandProperty Name) -join ", "
  Write-Host "   GPU: $gpu"
} catch { Write-Info "GPU non rilevata: Ollama girerà su CPU (più lento, ma funziona)." }

# 2. Trova ComfyUI-Impact-Pack (percorsi tipici su Windows)
Write-Info "Cerco ComfyUI-Impact-Pack..."
$found = ""
$candidates = @(
  "$HOME\ComfyUI\custom_nodes\comfyui-impact-pack\custom_wildcards",
  "$HOME\ComfyUI\custom_nodes\ComfyUI-Impact-Pack\custom_wildcards",
  "$HOME\Documents\ComfyUI\custom_nodes\comfyui-impact-pack\custom_wildcards",
  "C:\ComfyUI\custom_nodes\comfyui-impact-pack\custom_wildcards",
  "D:\ComfyUI\custom_nodes\comfyui-impact-pack\custom_wildcards"
)
foreach ($c in $candidates) { if (Test-Path $c) { $found = $c; break } }
if (-not $found) {
  foreach ($root in @("$HOME\ComfyUI", "$HOME\Documents\ComfyUI", "C:\ComfyUI", "D:\ComfyUI")) {
    if (Test-Path $root) {
      $hit = Get-ChildItem -Path $root -Directory -Recurse -Depth 4 -Filter "custom_wildcards" -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -match "impact-pack" } | Select-Object -First 1
      if ($hit) { $found = $hit.FullName; break }
    }
  }
}
if ($found) { Write-Ok "Impact Pack trovato: $found" } else { Write-Warn "custom_wildcards non trovato in automatico. Lo chiederò tra poco." }

# 3. Ollama installato?
$ollama = Get-Command ollama -ErrorAction SilentlyContinue
if ($ollama) {
  try { $v = (ollama --version 2>$null) } catch { $v = "ok" }
  Write-Ok "Ollama già installato: $v"
} else {
  Write-Warn "Ollama non trovato. Lo installo ora."
  $winget = Get-Command winget -ErrorAction SilentlyContinue
  if ($winget) {
    winget install --id Ollama.Ollama -e --accept-source-agreements --accept-package-agreements
  } else {
    $installer = "$env:TEMP\OllamaSetup.exe"
    Write-Info "Scarico installer da ollama.com..."
    Invoke-WebRequest -Uri "https://ollama.com/download/OllamaSetup.exe" -OutFile $installer
    Start-Process -FilePath $installer -Wait
  }
  $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
  $ollama = Get-Command ollama -ErrorAction SilentlyContinue
  if ($ollama) { Write-Ok "Ollama installato." }
  else { Write-Err "Installazione non riuscita. Scarica a mano da https://ollama.com/download e rilancia."; exit 1 }
}

# 4. Ollama in esecuzione? (con CORS per il browser)
if (Test-OllamaUp) {
  Write-Ok "Ollama risponde su localhost:11434."
} else {
  Write-Warn "Ollama non risponde: lo avvio con OLLAMA_ORIGINS=* (serve al browser)."
  $env:OLLAMA_ORIGINS = "*"
  try { setx OLLAMA_ORIGINS "*" | Out-Null } catch { }
  Start-Process -FilePath "ollama" -ArgumentList "serve" -WindowStyle Hidden
  $up = $false
  for ($i = 0; $i -lt 20; $i++) { Start-Sleep 1; if (Test-OllamaUp) { $up = $true; break } }
  if ($up) { Write-Ok "Ollama avviato." }
  else { Write-Err "Ollama non parte. Aprilo dal menu Start e rilancia."; exit 1 }
}

# 5. Scarica modello
Write-Info "Modello richiesto: $Model"
$base = ($Model -split ":")[0]
$list = ""
try { $list = (ollama list 2>$null) } catch { $list = "" }
if ($list -match [regex]::Escape($base)) { Write-Ok "Modello già presente localmente." }
else {
  Write-Host "   Download $Model (~6-7 GB, una tantum)..."
  ollama pull $Model
  Write-Ok "Modello scaricato."
}
Write-Info "Test rapidissimo del modello..."
try {
  $body = @{ model = $Model; prompt = "Reply with exactly: OK"; stream = $false } | ConvertTo-Json
  $t = Invoke-RestMethod -Uri "http://localhost:11434/api/generate" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 120
  if ($t.response -match "OK") { Write-Ok "Il modello risponde." } else { Write-Warn "Test saltato, ma il pull è riuscito." }
} catch { Write-Warn "Test saltato, ma il pull è riuscito." }

# 6. UNICA DOMANDA: dove esportare i .txt?
if ([string]::IsNullOrWhiteSpace($found)) { $defaultExport = "$HOME\ComfyUI\custom_nodes\comfyui-impact-pack\custom_wildcards" }
else { $defaultExport = $found }
Write-Host ""
Write-Host "──────────────────────────────────────────────"
Write-Host " 📁 DOVE ESPORTARE LE WILDCARD?"
Write-Host "    Default: $defaultExport"
Write-Host "──────────────────────────────────────────────"
if ([string]::IsNullOrWhiteSpace($ExportDir)) { $ExportDir = Ask-Default "Cartella di export" $defaultExport }
New-Item -ItemType Directory -Force -Path $ExportDir | Out-Null
Write-Ok "Cartella export: $ExportDir"

# 7. Config letta dalla pagina HTML (UTF-8 SENZA BOM: il BOM romperebbe JSON.parse nel browser)
$config = [ordered]@{
  export_dir = $ExportDir
  model      = $Model
  ollama_url = "http://localhost:11434"
}
$cfgPath = Join-Path $PSScriptRoot "atelier-config.json"
[System.IO.File]::WriteAllText($cfgPath, ($config | ConvertTo-Json), (New-Object System.Text.UTF8Encoding $false))
Write-Ok "Scritto atelier-config.json."

Write-Host ""
Write-Host "=============================================="
Write-Host " 🎉 TUTTO PRONTO (Windows)"
Write-Host "  • Ollama:  attivo (http://localhost:11434)"
Write-Host "  • Modello: $Model"
Write-Host "  • Export:  $ExportDir"
Write-Host "  • Pagina:  $PSScriptRoot\atelier-wildcard.html"
Write-Host "=============================================="
Write-Host " 1. Apri atelier-wildcard.html con Chrome/Edge"
Write-Host " 2. Premi 📁 e scegli: $ExportDir"
Write-Host " 3. Titolo → Genera visioni → Salva"
