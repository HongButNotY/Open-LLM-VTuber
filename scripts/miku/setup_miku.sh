#!/bin/zsh
# One-time setup for the Miku desktop pet (macOS).
# Downloads the parts this repo can't include (Live2D's Miku model, the VOICEVOX engine),
# then prepares the config files. Run from the repository root:
#   zsh scripts/miku/setup_miku.sh
set -e
cd "${0:A:h}/../.."
ROOT="$PWD"
VOICEVOX_VERSION="0.26.0"

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing '$1'. $2"; exit 1; } }
need uv "Install it: curl -LsSf https://astral.sh/uv/install.sh | sh"
need ffmpeg "Install it, e.g. brew install ffmpeg"
SEVENZ=$(command -v 7zz || command -v 7z || true)
[[ -n "$SEVENZ" ]] || { echo "Missing 7-Zip. Install it, e.g. brew install sevenzip"; exit 1; }

# 1. Config files (never overwrites yours)
[[ -f conf.yaml ]] || { cp conf.miku.yaml conf.yaml; echo "Created conf.yaml from conf.miku.yaml"; }
[[ -f keys.env ]] || { cp keys.env.example keys.env; chmod 600 keys.env; echo "Created keys.env: paste your API key into it."; }

# 2. Hatsune Miku Live2D model (Live2D official sample, PRO version)
if [[ ! -f live2d-models/miku/runtime/miku_sample_t04.moc3 ]]; then
  echo
  echo "Downloading Live2D's official Hatsune Miku sample model."
  echo "By continuing you agree to Live2D's Free Material License Agreement and Sample Data Terms"
  echo "(https://www.live2d.com/en/learn/sample/hatsune-miku/) and Crypton's Piapro Character License"
  echo "(https://piapro.jp/license/pcl/summary): personal, non-commercial use."
  read "answer?Continue? [y/N] "
  [[ "$answer" == [yY]* ]] || { echo "Skipped the Miku model."; exit 1; }
  TMP=$(mktemp -d)
  curl -fL --progress-bar -o "$TMP/miku.zip" https://cubism.live2d.com/sample-data/bin/miku/miku_ja.zip
  unzip -q "$TMP/miku.zip" -d "$TMP/x"
  mkdir -p live2d-models/miku
  rm -rf live2d-models/miku/runtime
  cp -R "$TMP/x/miku_pro/runtime" live2d-models/miku/runtime
  rm -rf "$TMP"
  uv run --no-project python scripts/miku/patch_miku_model.py live2d-models/miku/runtime
fi

# 3. VOICEVOX engine (Miku's voice: VOICEVOX:春日部つむぎ)
if [[ ! -x voicevox/run ]]; then
  ARCH=$([[ "$(uname -m)" == "arm64" ]] && echo arm64 || echo x64)
  FILE="voicevox_engine-macos-${ARCH}-${VOICEVOX_VERSION}.7z.001"
  echo
  echo "Downloading the VOICEVOX engine ($FILE, about 1.7 GB) from its official GitHub release..."
  mkdir -p voicevox
  curl -fL --progress-bar -o "voicevox/$FILE" \
    "https://github.com/VOICEVOX/voicevox_engine/releases/download/${VOICEVOX_VERSION}/${FILE}"
  EXPECTED=$(curl -fsSL "https://api.github.com/repos/VOICEVOX/voicevox_engine/releases/tags/${VOICEVOX_VERSION}" \
    | uv run --no-project python -c "import json,sys; print(next(a['digest'] for a in json.load(sys.stdin)['assets'] if a['name']=='$FILE').split(':')[1])")
  ACTUAL=$(shasum -a 256 "voicevox/$FILE" | cut -d' ' -f1)
  [[ "$EXPECTED" == "$ACTUAL" ]] || { echo "Checksum mismatch for $FILE. Delete voicevox/ and try again."; exit 1; }
  echo "Checksum OK."
  "$SEVENZ" x -y -bso0 -bsp0 -o"voicevox/tmp" "voicevox/$FILE"
  mv voicevox/tmp/macos-${ARCH}/* voicevox/ && rm -rf voicevox/tmp "voicevox/$FILE"
fi

# 4. Python dependencies
uv sync

echo
echo "Done. Next:"
echo "  1. Put your API key in keys.env (and choose PROVIDER=grok, deepseek or claude)."
echo "  2. Double-click start_miku.command (or run: zsh start_miku.command)."
echo "  3. Open the desktop app (see MIKU_SETUP.md) and switch to Pet mode."
