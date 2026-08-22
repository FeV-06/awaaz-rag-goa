#!/usr/bin/env bash
# Deploy the Awaaz static UI to a FREE Hugging Face Static Space.
# The backend stays on your machine behind Tailscale Funnel.
#
# Usage:
#   ./scripts/deploy_static_hf.sh <api-base-url>
#   HF_USER=<name> HF_TOKEN=hf_xxx ./scripts/deploy_static_hf.sh https://host:port
set -euo pipefail

API_BASE="${1:?usage: deploy_static_hf.sh <api-base-url>  (e.g. https://archfev.tailfcb4d3.ts.net:8443)}"
cd "$(dirname "${BASH_SOURCE[0]}")/.."
PY="$(pwd)/.venv/bin/python"
[ -x "$PY" ] || PY="python3"

if [ -z "${HF_USER:-}" ]; then read -r -p "Hugging Face username: " HF_USER; fi
if [ -z "${HF_TOKEN:-}" ]; then read -r -s -p "Hugging Face write token (hf_...): " HF_TOKEN; echo; fi
SPACE="${SPACE:-awaaz-rag-ui}"

echo ">> validating token..."
"$PY" - "$HF_USER" "$HF_TOKEN" <<'PY' || exit 1
import sys
from huggingface_hub import HfApi
try:
    HfApi(token=sys.argv[2]).whoami()
    print("   token valid ✓")
except Exception as e:
    print(f"   ✗ token rejected: {e}")
    sys.exit(1)
PY

echo ">> building static UI (API base: ${API_BASE})"
./scripts/build_static_ui.sh "$API_BASE" build/static

REPO="https://user:${HF_TOKEN}@huggingface.co/spaces/${HF_USER}/${SPACE}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP" build/static' EXIT

if ! git ls-remote "$REPO" >/dev/null 2>&1; then
  echo ">> creating static Space ${HF_USER}/${SPACE}..."
  CREATE_MSG="$("$PY" - "$HF_USER" "$HF_TOKEN" "$SPACE" <<'PY' 2>&1 || true
import sys
from huggingface_hub import HfApi
try:
    HfApi(token=sys.argv[2]).create_repo(
        repo_id=f"{sys.argv[1]}/{sys.argv[3]}",
        repo_type="space",
        space_sdk="static",
        exist_ok=True,
    )
    print("OK")
except Exception as e:
    print(f"FAIL: {e}")
PY
)"
  if [[ "$CREATE_MSG" == OK ]]; then echo "   space created ✓";
  else echo "   ✗ $CREATE_MSG"; exit 1; fi
fi

echo ">> cloning + pushing"
git clone "$REPO" "$TMP/space"
rsync -a build/static/ "$TMP/space/"
cd "$TMP/space"
git add -A
git -c user.name="awaaz-deploy" -c user.email="deploy@awaaz.local" commit -m "deploy: Awaaz static UI" || true
git push origin HEAD:main 2>push.err || { git pull --rebase origin main; git push origin HEAD:main; }

echo ""
echo "✅ UI live → https://huggingface.co/spaces/${HF_USER}/${SPACE}"
echo "   (backend: ${API_BASE})"
