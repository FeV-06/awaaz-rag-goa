#!/usr/bin/env bash
# Deploy Awaaz to a Hugging Face Space (Docker SDK).
#
# Usage:
#   ./scripts/deploy_hf.sh                          # prompts for username + token
#   HF_USER=<name> HF_TOKEN=hf_xxx ./scripts/deploy_hf.sh
#
# What it does:
#   1. validates your HF write token against the API
#   2. creates the Space (docker SDK) if it doesn't exist
#   3. pushes the whole repo + built indexes (data/indexes) to the Space
#      (HF stores large files server-side; this avoids a slow CPU rebuild at boot)
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
PY="$(pwd)/.venv/bin/python"
[ -x "$PY" ] || PY="python3"

# ── 1. credentials ────────────────────────────────────────────────────────────
if [ -z "${HF_USER:-}" ]; then
  read -r -p "Hugging Face username: " HF_USER
fi
if [ -z "${HF_TOKEN:-}" ]; then
  read -r -s -p "Hugging Face write token (hf_...): " HF_TOKEN
  echo
fi
SPACE="${SPACE:-awaaz-rag}"

echo ">> validating token for user '${HF_USER}'..."
VALID="$("$PY" - "$HF_USER" "$HF_TOKEN" <<'PY'
import sys
from huggingface_hub import HfApi
try:
    api = HfApi(token=sys.argv[2])
    who = api.whoami()
    name = who.get("name") or who.get("username") or "?"
    print("OK" if name.lower() == sys.argv[1].lower() else f"MISMATCH:{name}")
except Exception as e:
    print(f"ERROR:{type(e).__name__}: {e}")
PY
)"
case "$VALID" in
  OK) echo "   token valid ✓" ;;
  MISMATCH:*) echo "   ⚠ token belongs to '${VALID#MISMATCH:}', not '${HF_USER}' — continuing anyway (only matters for repo ownership)";;
  ERROR:*) echo "   ✗ token rejected: ${VALID#ERROR:}"; echo "   Get a write token at https://huggingface.co/settings/tokens"; exit 1;;
esac

REPO="https://user:${HF_TOKEN}@huggingface.co/spaces/${HF_USER}/${SPACE}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# ── 2. create space if missing ────────────────────────────────────────────────
if ! git ls-remote "$REPO" >/dev/null 2>&1; then
  echo ">> Space ${HF_USER}/${SPACE} not found — creating (Docker SDK)..."
  CREATE_MSG="$("$PY" - "$HF_USER" "$HF_TOKEN" "$SPACE" <<'PY' 2>&1 || true
import sys
from huggingface_hub import HfApi
try:
    api = HfApi(token=sys.argv[2])
    api.create_repo(
        repo_id=f"{sys.argv[1]}/{sys.argv[3]}",
        repo_type="space",
        space_sdk="docker",
        exist_ok=True,
    )
    print("OK")
except Exception as e:
    print(f"FAIL: {e}")
PY
)"
  if [[ "$CREATE_MSG" == OK ]]; then
    echo "   space created ✓"
  elif [[ "$CREATE_MSG" == *402* || "$CREATE_MSG" == *Payment* ]]; then
    echo "   ✗ HF now charges PRO for Docker/Gradio Spaces (402 Payment Required)."
    echo "     Options:"
    echo "       A) use your already-running Tailscale Funnel as the live link:"
    echo "            tailscale funnel 8000 7860"
    echo "       B) free HF STATIC space (UI only) + funnel API backend"
    echo "       C) subscribe at https://huggingface.co/pro"
    exit 1
  else
    echo "   ✗ space creation failed: $CREATE_MSG"
    exit 1
  fi
fi

echo ">> cloning Space repo ${HF_USER}/${SPACE}"
git clone "$REPO" "$TMP/space" 2>/dev/null || { echo "   ✗ clone failed — check username/token"; exit 1; }

# ── 3. copy repo files (keep indexes, drop big rebuildable artifacts) ─────────
echo ">> copying repo files into Space clone"
rsync -a --exclude '.git' --exclude '.venv' \
  --exclude 'data/raw/*.parquet' \
  --exclude 'data/onnx_models' --exclude 'data/hf_cache' \
  ./ "$TMP/space/"

# ── 4. commit + push (handle existing remote history) ─────────────────────────
cd "$TMP/space"
git add -A
if git diff --cached --quiet; then
  echo ">> nothing new to commit"
else
  git -c user.name="awaaz-deploy" -c user.email="deploy@awaaz.local" \
      commit -m "deploy: Awaaz voice Indic RAG"
fi

echo ">> pushing (first push ≈1.2GB of indexes; be patient)…"
if ! git push origin HEAD:main 2>push.err; then
  echo ">> remote has unrelated history — rebasing onto it…"
  git pull --rebase origin main 2>>push.err || true
  git push origin HEAD:main
fi

echo ""
echo "✅ pushed → https://huggingface.co/spaces/${HF_USER}/${SPACE}"
echo "   Docker build starts automatically (≈15–25 min)."
echo "   Add SARVAM_API_KEY as a Space secret afterwards:"
echo "   https://huggingface.co/spaces/${HF_USER}/${SPACE}/settings"
