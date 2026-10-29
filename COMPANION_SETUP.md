# Desktop companion features (Open-LLM-VTuber mod)

A set of changes that turn Open-LLM-VTuber into a desktop companion: it sees your screen, speaks
up on its own at random times, chats in casual Japanese (with readings and English, for Japanese
learners), and keeps its memory when you switch AI providers. It uses the project's own default
character (Mao) and Microsoft's Edge voice, so nothing extra has to be downloaded.

This is a fork of [Open-LLM-VTuber](https://github.com/Open-LLM-VTuber/Open-LLM-VTuber) by
Yi-Ting Chiu and the Open-LLM-VTuber contributors. All credit for the app goes to them; this branch
only adds the changes listed below. The desktop app changes live in the companion fork
[HongButNotY/Open-LLM-VTuber-Web](https://github.com/HongButNotY/Open-LLM-VTuber-Web/tree/companion-features).

## What this branch adds

Server (this repo):
- **Switch AI without losing memory**: choose `grok`, `deepseek` or `claude` in `keys.env`; chat history
  is kept per character, not per provider.
- **Cheaper requests**: only the last `MAX_MEMORY_MESSAGES` messages are sent (full history stays on disk);
  `LLM_VISION=false` skips screenshots for models that can't read images (set automatically for DeepSeek).
- **Companion persona** (`conf.companion.yaml`): a cheerful friend who talks in casual Japanese with kana
  readings and English, and reacts to what's on your screen.
- **Edge TTS pitch and rate options**, plus an optional **VOICEVOX** voice engine (`tts_model: 'voicevox_tts'`).

Desktop app ([companion fork](https://github.com/HongButNotY/Open-LLM-VTuber-Web/tree/companion-features)):
- **Speaks up on its own at random times** (30 s to 8 min) while screen capture is on, with a fresh screenshot each time.
- **Small subtitle under the character in pet mode**, following it when dragged (toggle in Settings → General).
- **Voice volume up to 300%, mic on/off at startup, and a saved pet-mode size** (Settings → General and ASR).
- **Reliable pet-mode click-through**: clicks pass through empty space but not the character or open panels.
  "Click Through Everything" (tray or right-click menu) can be switched off with ⌥⇧⌘M.
- **Electron 45**: the prebuilt v1.2.1 app (Electron 31) is blocked by macOS as "malware" because Apple
  revoked that Electron runtime; building on Electron 45 fixes it.

## Setup (macOS)

You need [uv](https://docs.astral.sh/uv/) and ffmpeg (e.g. `brew install ffmpeg`).

1. Clone this branch and install:
   ```bash
   git clone -b companion-features --recursive https://github.com/HongButNotY/Open-LLM-VTuber.git
   cd Open-LLM-VTuber
   uv sync
   uv pip install -U edge-tts
   cp keys.env.example keys.env
   ```
   (The locked edge-tts version is rejected by Microsoft's service, hence the upgrade.)
2. Put your API key in `keys.env` and choose `PROVIDER=` (`grok`, `deepseek` or `claude`).
3. Build the desktop app from the companion fork (needs Node.js 22):
   ```bash
   git clone -b companion-features https://github.com/HongButNotY/Open-LLM-VTuber-Web.git
   cd Open-LLM-VTuber-Web
   npm ci
   npm run build && CSC_IDENTITY_AUTO_DISCOVERY=false npx electron-builder --mac dir
   ```
   Copy `release/1.2.1/mac-*/open-llm-vtuber-electron.app` to Applications.
4. Double-click `start.command` (it creates `conf.yaml` from `conf.companion.yaml` the first time and
   starts the server), open the app, switch to Pet mode and turn on Screen capture.

To use a different character, put its Live2D model in `live2d-models/`, add it to `model_dict.json` and
set `live2d_model_name` in `conf.yaml`.

## Credits and licenses

- **Open-LLM-VTuber** (server): MIT License, © 2025 Yi-Ting Chiu. See [LICENSE](LICENSE).
- **Open-LLM-VTuber-Web** (desktop app): Open-LLM-VTuber License 1.0, © 2025 Open LLM Vtuber
  (Apache 2.0 with additional conditions; free for non-commercial use).
- **Live2D models** bundled with Open-LLM-VTuber: see [LICENSE-Live2D.md](LICENSE-Live2D.md).
- **VOICEVOX** (optional): not included; if you use it, follow the terms of the voice you pick.

Changes in this branch were made with help from Claude Code.
