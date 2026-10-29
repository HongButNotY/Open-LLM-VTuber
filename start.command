#!/bin/zsh
# Double-click to start the server (and the optional VOICEVOX engine). Keep this window open while you use the app.
cd "${0:A:h}"
[[ -f keys.env ]] || { echo "keys.env not found: copy keys.env.example to keys.env and add your key first."; read -k1; exit 1; }
set -a; source ./keys.env; set +a
export PATH="$HOME/.local/bin:$PATH"

# Map PROVIDER in keys.env to the app's settings.
case "${PROVIDER:l}" in
  grok)     export LLM_PROVIDER=openai_compatible_llm LLM_VISION=true  KEY_NAME=XAI_API_KEY ;;
  deepseek) export LLM_PROVIDER=deepseek_llm          LLM_VISION=false KEY_NAME=DEEPSEEK_API_KEY ;;
  claude)   export LLM_PROVIDER=claude_llm            LLM_VISION=true  KEY_NAME=ANTHROPIC_API_KEY ;;
  *) echo "PROVIDER in keys.env must be grok, deepseek or claude (it is '$PROVIDER')."; read -k1; exit 1 ;;
esac
if [[ -z "${(P)KEY_NAME}" ]]; then
  echo "No key found: paste your key after $KEY_NAME= in keys.env, save, and start again."
  read -k1; exit 1
fi
echo "Starting with $PROVIDER..."

# Optional: start the VOICEVOX engine if you put it in ./voicevox and it isn't running;
# stop it again when this window closes.
if [[ -x voicevox/run ]] && ! curl -s -o /dev/null http://127.0.0.1:50021/version; then
  ./voicevox/run --host 127.0.0.1 --port 50021 > voicevox/engine.log 2>&1 &
  VOICEVOX_PID=$!
  trap 'kill $VOICEVOX_PID 2>/dev/null' EXIT
  echo "Starting voice engine..."
  for i in {1..60}; do curl -s -o /dev/null http://127.0.0.1:50021/version && break; sleep 1; done
fi

[[ -f conf.yaml ]] || cp conf.companion.yaml conf.yaml
uv run run_server.py
