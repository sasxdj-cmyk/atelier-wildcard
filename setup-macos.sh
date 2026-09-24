#!/usr/bin/env bash
# Atelier Wildcard — setup per macOS
# Verifica Mac, installa Ollama se manca (via brew), scarica il modello, chiede la cartella di export.
# Uso:  bash setup-macos.sh [--model qwen3.5:9b] [--export /percorso/custom_wildcards] [--yes]
# (Su Linux usa setup-linux.sh, su Windows setup-windows.ps1 — oppure bash setup.sh che sceglie da solo.)
set -euo pipefail

MODEL="${MODEL:-qwen3.5:9b}"
EXPORT_DIR="${EXPORT_DIR:-}"
ASSUME_YES=0
C_RED='\033[0;31m'; C_GRN='\033[0;32m'; C_YEL='\033[0;33m'; C_BLU='\033[0;34m'; C_RST='\033[0m'
ok()   { echo -e "${C_GRN}✅ $*${C_RST}"; }
warn() { echo -e "${C_YEL}⚠️  $*${C_RST}"; }
err()  { echo -e "${C_RED}❌ $*${C_RST}" >&2; }
info() { echo -e "${C_BLU}▸ $*${C_RST}"; }
ask()  {
  local q="$1" d="$2" ans
  if [ "$ASSUME_YES" = 1 ]; then echo "$d"; return; fi
  read -r -p "$q [$d]: " ans || true
  echo "${ans:-$d}"
}
for a in "$@"; do
  case "$a" in
    --model=*) MODEL="${a#--model=}"; shift;;
    --model) [ $# -ge 2 ] || { err "Opzione --model senza valore. Esempio: --model qwen3.5:9b"; exit 1; }; MODEL="$2"; shift 2;;
    --export=*) EXPORT_DIR="${a#--export=}"; shift;;
    --export) [ $# -ge 2 ] || { err "Opzione --export senza valore. Esempio: --export /percorso/custom_wildcards"; exit 1; }; EXPORT_DIR="$2"; shift 2;;
    --yes|-y) ASSUME_YES=1; shift;;
    --help|-h) echo "Uso: bash setup-macos.sh [--model NOME] [--export PATH] [--yes]"; exit 0;;
  esac
done
[ -n "$MODEL" ] || { err "Opzione --model senza valore. Esempio: --model qwen3.5:9b"; exit 1; }

echo "=============================================="
echo " 🎭 ATELIER WILDCARD — setup macOS"
echo " ComfyUI Impact Pack + Ollama ($MODEL)"
echo "=============================================="

# 1. Requisiti base
command -v curl >/dev/null || { err "manca 'curl' (strano su Mac). Installa Xcode Command Line Tools e rilancia."; exit 1; }
MEM_GB=$(($(sysctl -n hw.memsize 2>/dev/null || echo 0) / 1073741824))
DISK_AV=$(df -h . 2>/dev/null | awk 'NR==2{print $4}' || echo "?")
CHIP=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || sysctl -n hw.model 2>/dev/null || echo "?")
echo "   Chip: $CHIP  |  RAM: ${MEM_GB} GB  |  Disco libero qui: $DISK_AV"
if [ "$MEM_GB" -lt 8 ] 2>/dev/null; then
  warn "Meno di 8 GB di RAM: $MODEL (~6.6 GB) potrebbe faticare. Valuta un modello più piccolo."
fi
info "Su Apple Silicon Ollama usa Metal: funziona bene anche senza NVIDIA."

# 2. Trova ComfyUI-Impact-Pack (percorsi tipici su Mac)
info "Cerco ComfyUI-Impact-Pack..."
FOUND=""
for c in \
  "$HOME/ComfyUI/custom_nodes/comfyui-impact-pack/custom_wildcards" \
  "$HOME/ComfyUI/custom_nodes/ComfyUI-Impact-Pack/custom_wildcards" \
  "$HOME/Documents/ComfyUI/custom_nodes/comfyui-impact-pack/custom_wildcards" \
  "/Applications/ComfyUI/custom_nodes/comfyui-impact-pack/custom_wildcards" \
  "$(pwd)/../ComfyUI/custom_nodes/comfyui-impact-pack/custom_wildcards" ; do
  [ -d "$c" ] && { FOUND="$c"; break; }
done
if [ -z "$FOUND" ]; then
  DEEP=$(find "$HOME" -maxdepth 6 -type d -path "*impact-pack/custom_wildcards" 2>/dev/null | head -1 || true)
  [ -n "$DEEP" ] && FOUND="$DEEP"
fi
if [ -n "$FOUND" ]; then ok "Impact Pack trovato: $FOUND"
else warn "custom_wildcards non trovato in automatico. Lo chiederò tra poco."; fi

# 3. Ollama installato?
if command -v ollama >/dev/null; then ok "Ollama già installato: $(ollama --version 2>/dev/null || echo ok)"
elif [ -d "/Applications/Ollama.app" ]; then ok "Ollama.app trovato nelle Applicazioni."
else
  warn "Ollama non trovato. Lo installo ora."
  if command -v brew >/dev/null; then
    brew install ollama
    ok "Ollama installato via brew."
  else
    err "Serve Homebrew. Installalo da https://brew.sh poi rilancia. Oppure installa Ollama.app da https://ollama.com/download"
    exit 1
  fi
fi

# 4. Ollama in esecuzione? (con CORS per il browser)
if curl -s --max-time 3 http://localhost:11434/api/tags >/dev/null; then
  ok "Ollama risponde su localhost:11434."
else
  warn "Ollama non risponde: lo avvio con OLLAMA_ORIGINS=* (serve al browser)."
  export OLLAMA_ORIGINS="*"
  if command -v brew >/dev/null && brew services list 2>/dev/null | grep -qi "ollama.*started"; then
    brew services restart ollama || true
  else
    nohup env OLLAMA_ORIGINS="*" ollama serve >/tmp/ollama-atelier.log 2>&1 &
    echo $! > /tmp/ollama-atelier.pid || true
  fi
  for i in $(seq 1 20); do sleep 1; curl -s --max-time 2 http://localhost:11434/api/tags >/dev/null && break; done
  if curl -s --max-time 3 http://localhost:11434/api/tags >/dev/null; then ok "Ollama avviato."
  else
    warn "Non riesco ad avviarlo da terminale. Apri Ollama.app a mano e rilancia questo script."
    warn "Nota: con Ollama.app il CORS del browser potrebbe bloccare la pagina: se succede, avvia da terminale con  OLLAMA_ORIGINS=* ollama serve"
    exit 1
  fi
fi

# 5. Scarica modello
info "Modello richiesto: $MODEL"
if ollama list 2>/dev/null | grep -q "${MODEL%%:*}"; then ok "Modello già presente localmente."
else
  echo "   Download $MODEL (~6-7 GB, una tantum)..."
  ollama pull "$MODEL"
  ok "Modello scaricato."
fi
info "Test rapidissimo del modello (max ${OLLAMA_TEST_TIMEOUT:-60}s, saltabile con OLLAMA_TEST_TIMEOUT=0)..."
if [ "${OLLAMA_TEST_TIMEOUT:-60}" = "0" ] || curl -s --max-time "${OLLAMA_TEST_TIMEOUT:-60}" http://localhost:11434/api/generate -d "{\"model\":\"$MODEL\",\"prompt\":\"Reply with exactly: OK\",\"stream\":false}" | grep -qi "OK"; then
  ok "Il modello risponde."
else warn "Test saltato, ma il pull è riuscito."; fi

# 6. UNICA DOMANDA: dove esportare i .txt?
DEFAULT_EXPORT="${FOUND:-$HOME/ComfyUI/custom_nodes/comfyui-impact-pack/custom_wildcards}"
echo
echo "──────────────────────────────────────────────"
echo " 📁 DOVE ESPORTARE LE WILDCARD?"
echo "    Default: $DEFAULT_EXPORT"
echo "──────────────────────────────────────────────"
if [ -z "$EXPORT_DIR" ]; then
  EXPORT_DIR="$(ask "Cartella di export" "$DEFAULT_EXPORT")"
fi
mkdir -p "$EXPORT_DIR"
ok "Cartella export: $EXPORT_DIR"

# 7. Config letta dalla pagina HTML (via python3: escaping JSON sempre valido)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if command -v python3 >/dev/null; then
  EXPORT_DIR="$EXPORT_DIR" MODEL="$MODEL" python3 -c 'import json,os; json.dump({"export_dir":os.environ["EXPORT_DIR"],"model":os.environ["MODEL"],"ollama_url":"http://localhost:11434"}, open("'"$SCRIPT_DIR"'/atelier-config.json","w"), ensure_ascii=False, indent=2)'
else
  warn "python3 assente: scrivo la config senza escaping (evita \" e \\ nel percorso)."
  cat > "$SCRIPT_DIR/atelier-config.json" <<EOF
{
  "export_dir": "$EXPORT_DIR",
  "model": "$MODEL",
  "ollama_url": "http://localhost:11434"
}
EOF
fi
ok "Scritto atelier-config.json."

echo
echo "=============================================="
echo " 🎉 TUTTO PRONTO (macOS)"
echo "  • Ollama:  attivo (http://localhost:11434)"
echo "  • Modello: $MODEL"
echo "  • Export:  $EXPORT_DIR"
echo "  • Pagina:  $SCRIPT_DIR/atelier-wildcard.html"
echo "=============================================="
echo " 1. Apri atelier-wildcard.html con Chrome/Edge"
echo " 2. Premi 📁 e scegli: $EXPORT_DIR"
echo " 3. Titolo → ✨ Genera visioni → 💾 Salva"
