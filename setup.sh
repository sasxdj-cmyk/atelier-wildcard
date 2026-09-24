#!/usr/bin/env bash
# Atelier Wildcard — setup dispatcher
# Sceglie da solo lo script giusto: Linux -> setup-linux.sh, macOS -> setup-macos.sh.
# Su Windows: doppio click su setup-windows.bat (oppure: powershell -ExecutionPolicy Bypass -File setup-windows.ps1)
# Uso:  bash setup.sh [--model qwen3.5:9b] [--export /percorso/custom_wildcards] [--yes]
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
case "$(uname -s)" in
  Linux*)  exec bash "$HERE/setup-linux.sh" "$@";;
  Darwin*) exec bash "$HERE/setup-macos.sh" "$@";;
  MINGW*|MSYS*|CYGWIN*) echo "Su Windows usa: setup-windows.bat (doppio click)"; exit 1;;
  *) echo "OS non riconosciuto: $(uname -s). Linux -> setup-linux.sh, Mac -> setup-macos.sh, Windows -> setup-windows.bat"; exit 1;;
esac
