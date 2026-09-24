# 🎭 Atelier Wildcard — arte generativa per ComfyUI Impact Pack

**Un solo file HTML** per creare wildcard `__nome__` con l'aiuto di **Ollama** in locale,
più **un solo script `setup.sh`** che prepara tutto: verifica il PC, installa Ollama se manca,
scarica il modello e ti chiede **in quale cartella esportare** i `.txt`.

> 🇬🇧 *Short English summary at the bottom.*

---

## ✨ Cosa fa

- **Atto I — Il Nome:** scrivi `fiori` → userai `__fiori__` nei nodi `ImpactWildcardProcessor / ImpactWildcardEncode`.
- **Atto II — La Materia:** scrivi un titolo (es. *fiori fotorealistici*), premi **✨ Genera visioni** e Ollama riempie la lista. Oppure scrivi a mano.
- **Atto III — L'Esposizione:** estrai un destino a caso, poi **💾 Salva nella cartella di export** (scegli la cartella una volta sola) oppure scarica il `.txt`.
- Extra: ⏹ STOP generazione, 🧠 libera VRAM **senza chiudere Ollama** (`keep_alive: 0`), 🔌 scollega/ricollega oracolo, 🗑 distruggi lista.
- 🌍 **5 lingue**: 🇮🇹 italiano, 🇬🇧 inglese, 🇪🇸 spagnolo, 🇨🇳 cinese, 🇮🇳 hindi — selettore a bandierine in alto, scelta ricordata. Anche esempi e messaggi seguono la lingua.

Formato file 100% compatibile Impact Pack: **una riga = una scelta**, `#` = commento, `__cat/sub__` per sottocartelle.

## 🖥️ Requisiti del PC

| Serve | Dettagli |
|---|---|
| OS | Linux (testato), macOS o WSL2 |
| RAM | **8 GB+** consigliati (`qwen3.5:9b` pesa ~6.6 GB) |
| Disco | ~8 GB liberi per il modello |
| ComfyUI | già installato e funzionante |
| Impact Pack | `custom_nodes/comfyui-impact-pack` (o `ComfyUI-Impact-Pack`) con cartella `custom_wildcards/` |
| Browser | Chrome / Edge (per salvataggio diretto in cartella; Firefox = solo download) |
| GPU | facoltativa (NVIDIA = più veloce, CPU = funziona lo stesso) |

## 🚀 Installazione (scegli il tuo sistema)

Tutti gli script fanno le stesse magie, in ordine:
1. Controllano il PC (RAM, disco, GPU).
2. Cercano `custom_wildcards/` di Impact Pack nei percorsi tipici del sistema.
3. Verificano `ollama`; **se manca lo installano**.
4. Avviano il server con `OLLAMA_ORIGINS=*` se spento (serve al browser per il CORS).
5. Scaricano `qwen3.5:9b` (modello di partenza).
6. **Ti chiedono UNA cosa sola: la cartella di export** e scrivono `atelier-config.json`, mostrato dalla pagina come percorso consigliato.

### 🐧 Linux

```bash
git clone <tuo-repo> atelier-wildcard
cd atelier-wildcard
bash setup.sh
# oppure diretto: bash setup-linux.sh
```

### 🍎 macOS

```bash
git clone <tuo-repo> atelier-wildcard
cd atelier-wildcard
bash setup.sh
# oppure diretto: bash setup-macos.sh
```

Serve [Homebrew](https://brew.sh) per l'auto-installazione di Ollama (altrimenti scarica [Ollama.app](https://ollama.com/download)). Su Apple Silicon Ollama usa Metal: va forte anche senza NVIDIA.

### 🪟 Windows

Doppio click su **`setup-windows.bat`**, oppure da PowerShell:

```powershell
git clone <tuo-repo> atelier-wildcard
cd atelier-wildcard
powershell -ExecutionPolicy Bypass -File setup-windows.ps1
```

Ollama viene installato via `winget` (se presente) oppure scaricando l'installer ufficiale. Il server viene avviato in background e `OLLAMA_ORIGINS=*` viene memorizzato con `setx`.

Opzioni (tutti i sistemi):

```bash
bash setup.sh --model qwen3:14b --export /mio/percorso/custom_wildcards --yes
```

```powershell
.\setup-windows.ps1 -Model "qwen3:14b" -ExportDir "D:\ComfyUI\custom_nodes\comfyui-impact-pack\custom_wildcards" -Yes
```

## 🎨 Uso

1. Apri `atelier-wildcard.html` con Chrome/Edge (doppio click, nessun server richiesto).
2. Premi **📁 Scegli cartella** e indica quella detta al setup (es. `.../comfyui-impact-pack/custom_wildcards`).
3. Atto I: nome → Atto II: titolo → **✨ Genera visioni** → togli le brutte con `×`.
4. **💾 Salva nella cartella** (crea anche sottocartelle tipo `obj/person.txt` da solo).
5. In ComfyUI: `__fiori__` / `__obj/person__` nei nodi Impact Wildcard → Queue → meraviglia.

## 🧠 Modelli

Default: **`qwen3.5:9b`** — buon equilibrio qualità/VRAM per liste di prompt in inglese.
Alternative leggere: `qwen3:4b`, `granite4.2:8b`. Alternative forti: `qwen3:14b`, `gpt-oss:20b`.
Cambia dal menu nella pagina o rilancia `bash setup.sh --model nome:tag`.

Liberare VRAM senza chiudere Ollama: bottone **🧠 Libera la mente** (= `POST /api/generate {keep_alive: 0}`). Verifica con `curl localhost:11434/api/ps` → `[]` ma server vivo.

## 🔒 Privacy

Tutto gira in locale: pagina HTML offline senza telemetria, Ollama su `localhost`, salvataggi solo dove scegli tu. Zero account, zero cloud.

## 🧪 Stato dei test

- ✅ Linux: setup provato davvero (Ollama 0.32.14, modello presente, config scritta e validata).
- ⚠️ Windows/macOS: script verificati solo a livello sintattico — se li provi su hardware reale, apri pure una issue/PR.

## 🔧 Problemi comuni

- **Browser non parla con Ollama / CORS:** riavvia con `OLLAMA_ORIGINS=* ollama serve` (lo script lo fa già).
- **Firefox non salva in cartella:** normale, usa **⬇ Scarica .txt** e sposta a mano.
- **`custom_wildcards` non trovata:** metti i `.txt` in `ComfyUI/custom_nodes/ComfyUI-Impact-Pack/custom_wildcards/` e riavvia ComfyUI.
- **Poca RAM:** usa un modello più piccolo o chiudi altro; il bottone 🧠 libera la VRAM tra una generazione e l'altra.

## 📁 Struttura

```
atelier-wildcard/
├── atelier-wildcard.html       # l'opera (singolo file, offline, zero dipendenze — uguale su tutti i sistemi)
├── setup.sh                    # dispatcher: sceglie lo script giusto (Linux/Mac)
├── setup-linux.sh              # il mago per Linux
├── setup-macos.sh              # il mago per macOS
├── setup-windows.ps1           # il mago per Windows (PowerShell)
├── setup-windows.bat           # doppio click per Windows
├── atelier-config.json         # generato dal setup (ignorato da git)
├── atelier-config.example.json # esempio
├── README.md
└── LICENSE (MIT)
```

## 📤 Pubblicare su GitHub

```bash
cd atelier-wildcard
git init && git add . && git commit -m "Atelier Wildcard: arte generativa per Impact Pack + Ollama"
gh repo create atelier-wildcard --public --source=. --push
```

`atelier-config.json` è nel `.gitignore`: ogni utente genera il suo col setup.

---

### 🇬🇧 English (short)

Single-file HTML atelier to author ComfyUI Impact Pack wildcards with local Ollama.
`setup.sh` (Linux/macOS dispatcher → `setup-linux.sh` / `setup-macos.sh`) and `setup-windows.ps1` (+ double-click `.bat`) check the machine, install Ollama if missing, pull `qwen3.5:9b`,
asks for the export folder (your `custom_wildcards/`), and writes `atelier-config.json`
consumed by the page. Open the HTML in Chrome/Edge, pick the folder once, type a title,
generate, save straight into `custom_wildcards/`, use `__name__` in Impact nodes.
