# 🎭 Atelier Wildcard — Generative Art for ComfyUI Impact Pack

**A single HTML file** to create `__name__` wildcards with the help of local **Ollama**,
plus **a single `setup.sh` script** that prepares everything: checks your machine, installs Ollama if missing,
pulls the model and asks you **where to export** the `.txt` files.

> 🇮🇹 *Versione italiana: [README.it.md](README.it.md).*

---

## ✨ What it does

- **Act I — The Name:** type `flowers` → you will use `__flowers__` in `ImpactWildcardProcessor / ImpactWildcardEncode` nodes.
- **Act II — The Matter:** type a title (e.g. *photorealistic flowers*), press **✨ Generate visions** and Ollama fills the list. Or write by hand.
- **Act III — The Exhibition:** draw a random fate, then **💾 Save to the export folder** (pick the folder once) or download the `.txt`.
- Extras: ⏹ Stop generation, 🧠 free VRAM **without closing Ollama** (`keep_alive: 0`), 🔌 disconnect/reconnect oracle, 🗑 destroy list, word counter per line (red if >8 words).
- 🌍 **5 languages**: 🇮🇹 Italian, 🇬🇧 English, 🇪🇸 Spanish, 🇨🇳 Chinese, 🇮🇳 Hindi — flag selector on top, choice remembered. Examples and messages follow the language.

File format 100% Impact Pack compatible: **one line = one choice**, `#` = comment, `__cat/sub__` for subfolders.

## 🖥️ Requirements

| Need | Details |
|---|---|
| OS | Linux (tested), macOS or WSL2 |
| RAM | **8 GB+** recommended (`qwen3.5:9b` is ~6.6 GB) |
| Disk | ~8 GB free for the model |
| ComfyUI | already installed and working |
| Impact Pack | `custom_nodes/comfyui-impact-pack` (or `ComfyUI-Impact-Pack`) with `custom_wildcards/` folder |
| Browser | Chrome / Edge (for direct folder save; Firefox = download only) |
| GPU | optional (NVIDIA = faster, CPU = works anyway) |

## 🚀 Installation (pick your system)

All scripts do the same magic, in order:
1. Check the machine (RAM, disk, GPU).
2. Look for Impact Pack `custom_wildcards/` in typical system paths.
3. Check `ollama`; **install it if missing**.
4. Start the server with `OLLAMA_ORIGINS=*` if down (needed by the browser for CORS).
5. Pull `qwen3.5:9b` (starter model).
6. **Ask you ONE thing only: the export folder** and write `atelier-config.json`, shown by the page as the suggested path.

### 🐧 Linux

```bash
git clone https://github.com/sasxdj-cmyk/atelier-wildcard.git
cd atelier-wildcard
bash setup.sh
# or directly: bash setup-linux.sh
```

### 🍎 macOS

```bash
git clone https://github.com/sasxdj-cmyk/atelier-wildcard.git
cd atelier-wildcard
bash setup.sh
# or directly: bash setup-macos.sh
```

[Homebrew](https://brew.sh) is required for Ollama auto-install (otherwise get [Ollama.app](https://ollama.com/download)). On Apple Silicon Ollama uses Metal: fast even without NVIDIA.

### 🪟 Windows

Double-click **`setup-windows.bat`**, or from PowerShell:

```powershell
git clone https://github.com/sasxdj-cmyk/atelier-wildcard.git
cd atelier-wildcard
powershell -ExecutionPolicy Bypass -File setup-windows.ps1
```

Ollama is installed via `winget` (if available) or via the official installer. The server is started in background and `OLLAMA_ORIGINS=*` is stored with `setx`.

Options (all systems):

```bash
bash setup.sh --model qwen3:14b --export /my/path/custom_wildcards --yes
```

```powershell
.\setup-windows.ps1 -Model "qwen3:14b" -ExportDir "D:\ComfyUI\custom_nodes\comfyui-impact-pack\custom_wildcards" -Yes
```

## 🎨 Usage

1. Open `atelier-wildcard.html` with Chrome/Edge (double-click, no server needed).
2. Press **📁 Choose folder** and point to the one given at setup (e.g. `.../comfyui-impact-pack/custom_wildcards`).
3. Act I: name → Act II: title → **✨ Generate visions** → remove bad ones with `×`.
4. **💾 Save to folder** (also creates subfolders like `obj/person.txt` automatically).
5. In ComfyUI: `__flowers__` / `__obj/person__` in Impact Wildcard nodes → Queue → magic.

## 🧠 Models

Default: **`qwen3.5:9b`** — good quality/VRAM balance for English prompt lists.
Light alternatives: `qwen3:4b`, `granite4.2:8b`. Strong alternatives: `qwen3:14b`, `gpt-oss:20b`.
Switch from the page menu or re-run `bash setup.sh --model name:tag`.

Free VRAM without closing Ollama: **🧠 Free the mind** button (= `POST /api/generate {keep_alive: 0}`). Check with `curl localhost:11434/api/ps` → `[]` but server alive.

Generator prompt: asks Ollama for max 5 words per line (simple keywords, no sentences), each line shows a word count badge (red if >8).

## 🔒 Privacy

Everything runs locally: offline HTML page with no telemetry, Ollama on `localhost`, saves only where you choose. Zero accounts, zero cloud.

## 🧪 Test status

- ✅ Linux: setup really tested (Ollama 0.32.14, model present, config written and validated).
- ⚠️ Windows/macOS: scripts syntax-checked only — if you try them on real hardware, feel free to open an issue/PR.

## 🔧 Troubleshooting

- **Browser can't talk to Ollama / CORS:** restart with `OLLAMA_ORIGINS=* ollama serve` (the script already does it).
- **Firefox doesn't save to folder:** expected, use **⬇ Download .txt** and move manually.
- **`custom_wildcards` not found:** put `.txt` files in `ComfyUI/custom_nodes/ComfyUI-Impact-Pack/custom_wildcards/` and restart ComfyUI.
- **Low RAM:** use a smaller model or close other apps; the 🧠 button frees VRAM between generations.
- **Long lines?** Impact reads lines of any length (one line = one choice, no truncation): brevity matters for CLIP/prompts, not for the parser. The generator asks Ollama for max 5 words and each line shows the count (red if >8).

## 📁 Structure

```
atelier-wildcard/
├── atelier-wildcard.html       # the artwork (single file, offline, zero deps — same on all systems)
├── setup.sh                    # dispatcher: picks the right script (Linux/Mac)
├── setup-linux.sh              # the wizard for Linux
├── setup-macos.sh              # the wizard for macOS
├── setup-windows.ps1           # the wizard for Windows (PowerShell)
├── setup-windows.bat           # double-click for Windows
├── atelier-config.json         # generated by setup (git-ignored)
├── atelier-config.example.json # example
├── README.md                   # this file (English)
├── README.it.md                # Italian version
└── LICENSE (MIT)
```

## 📤 Publish to GitHub

```bash
cd atelier-wildcard
git init && git add . && git commit -m "Atelier Wildcard: generative art for Impact Pack + Ollama"
gh repo create atelier-wildcard --public --source=. --push
```

`atelier-config.json` is in `.gitignore`: each user generates their own via setup.

---

*Painted with **Ollama** · exhibited with **ComfyUI** · signed **Atelier Wildcard*** 🎭
