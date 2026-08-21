#!/usr/bin/env bash
# Deploy Awaaz to a Hugging Face Space (Docker SDK).
#
# Prereqs (one-time, user-side):
#   1. Create an HF account + access token at https://huggingface.co/settings/tokens
#      (token type: "write"). Export it:  export HF_TOKEN=hf_...
#   2. Create the Space (Docker SDK) at https://huggingface.co/new-space
#      (SDK: Docker, hardware: CPU basic or better).
#      Or create it here:  huggingface-cli repo create awaaz-rag --type space -s docker
#
# Usage:  HF_USER=<username> ./scripts/deploy_hf.sh
#
# What it does:
#   - pushes ALL repo files (code, corpus, benchmarks...) to the Space repo
#   - ALSO pushes data/indexes/ (built locally) to the Space repo — HF's
#     server stores large files; this saves the pipeline the CPU self-rebuild
#     on first boot (the FastAPI lifespan self-heals if they're absent).
set -euo pipefail

HF_USER="${HF_USER:?set HF_USER to your Hugging Face username}"
SPACE="${SPACE:-awaaz-rag}"
REPO="https://user:${HF_TOKEN:?set HF_TOKEN (write token)}@huggingface.co/spaces/${HF_USER}/${SPACE}"

cd "$(dirname "${BASH_SOURCE[0]}")/.."

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo ">> cloning Space repo ${HF_USER}/${SPACE}"
git clone "$REPO" "$TMP/space" 2>/dev/null || {
  echo ">> Space not found — creating (docker SDK)..."
  pip install -q huggingface_hub
  HF_USER="$HF_USER" HF_TOKEN="$HF_TOKEN" python - <<'PY'
import os
from huggingface_hub import HfApi
api = HfApi(token=os.environ["HF_TOKEN"])
api.create_repo(repo_id=f"{os.environ['HF_USER']}/awaaz-rag", repo_type="space", space_sdk="docker", exist_ok=True)
print("space created")
PY
  git clone "$REPO" "$TMP/space"
}

echo ">> copying repo files into Space clone"
rsync -a --exclude '.git' --exclude '.venv' \
  --exclude 'data/raw/*.parquet' \
  --exclude 'data/onnx_models' --exclude 'data/hf_cache' \
  ./ "$TMP/space/"

echo ">> pushing (large files land on HF storage; first push may take a while)"
cd "$TMP/space"
git add -A
git -c user.name="fev" -c user.email="fev@localhost" commit -m "deploy: Awaaz voice Indic RAG" || true
git push origin main

echo "✅ pushed to https://huggingface.co/spaces/${HF_USER}/${SPACE}"
echo "   The Space will now build the Docker image (several minutes);"
echo "   watch it at https://huggingface.co/spaces/${HF_USER}/${SPACE}/settings"