#!/usr/bin/env bash
# Prepara o provedor de IA local (Ollama) com os modelos usados pelo GowienHelper.
# Uso:
#   bash scripts/setup_ai.sh            # usa o Ollama em http://localhost:11434
#   OLLAMA_HOST=http://host:11434 bash scripts/setup_ai.sh
#
# Requer o Ollama em execução (nativo: `ollama serve`, ou via docker-compose:
# `docker compose up -d ollama`).
set -euo pipefail

LLM_MODEL="${OLLAMA_MODEL:-qwen3:8b}"
EMBED_MODEL="${OLLAMA_EMBED_MODEL:-nomic-embed-text}"
HOST="${OLLAMA_HOST:-http://localhost:11434}"

echo "==> Ollama em: $HOST"
echo "==> Modelo LLM:   $LLM_MODEL"
echo "==> Modelo embed: $EMBED_MODEL"

pull() {
  local model="$1"
  echo "==> Baixando $model ..."
  # Tenta via API HTTP (funciona com o container do docker-compose);
  # cai para o CLI `ollama` se estiver instalado nativamente.
  if command -v ollama >/dev/null 2>&1; then
    ollama pull "$model"
  else
    curl -fsSL "$HOST/api/pull" -d "{\"model\":\"$model\"}" \
      | tail -n 1
  fi
}

pull "$LLM_MODEL"
pull "$EMBED_MODEL"

echo "==> Modelos prontos. Teste rápido:"
curl -fsSL "$HOST/api/generate" \
  -d "{\"model\":\"$LLM_MODEL\",\"prompt\":\"responda apenas: ok\",\"stream\":false,\"think\":false}" \
  | sed -n 's/.*"response":"\([^"]*\)".*/resposta: \1/p' || true
echo "==> Concluído."
