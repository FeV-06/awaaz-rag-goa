#!/usr/bin/env bash
# Deploy a redirect page to the Awaaz HF static Space.
#
# Rationale: the static Space cannot fetch the backend directly — Chrome's PNA
# needs a header (we have it), but Firefox's Local Network Access auto-denies
# cross-origin fetches to Tailscale CGNAT addresses (100.x) with no server-side
# override, and private windows deny even with a prompt. Instead of fighting
# browser security, the Space simply redirects to the same-origin funnel URL,
# which serves the full UI with no CORS at all.
#
# Usage:
#   HF_USER=<name> HF_TOKEN=hf_xxx ./scripts/deploy_redirect_hf.sh <funnel-ui-url>
#   e.g. ... ./scripts/deploy_redirect_hf.sh https://archfev.tailfcb4d3.ts.net/awaaz/
set -euo pipefail

TARGET="${1:?usage: deploy_redirect_hf.sh <funnel-ui-url>  (e.g. https://archfev.tailfcb4d3.ts.net/awaaz/)}"
cd "$(dirname "${BASH_SOURCE[0]}")/.."
PY="$(pwd)/.venv/bin/python"
[ -x "$PY" ] || PY="python3"

if [ -z "${HF_USER:-}" ]; then read -r -p "Hugging Face username: " HF_USER; fi
if [ -z "${HF_TOKEN:-}" ]; then read -r -s -p "Hugging Face write token (hf_...): " HF_TOKEN; echo; fi
SPACE="${SPACE:-awaaz-rag-ui}"

# validate the target funnel UI answers
echo ">> checking target ${TARGET} ..."
if ! curl -fsS --max-time 15 "${TARGET}" -o /dev/null 2>/dev/null; then
  echo "   ✗ target unreachable — start the backend + funnel first."
  exit 1
fi
echo "   target reachable ✓"

# build landing page from the template
OUT="build/redirect"
mkdir -p "$OUT"
sed "s|__TARGET_URL__|${TARGET}|g" "$(dirname "${BASH_SOURCE[0]}")/landing_template.html" > "$OUT/index.html"

cat > "$OUT/README.md" <<MD
---
title: Awaaz — Voice-Enabled Indic RAG
emoji: 🗣️
colorFrom: gray
colorTo: yellow
sdk: static
pinned: false
---
Redirects to the live AWAAZ demo at \`${TARGET}\` (same-origin UI — no CORS).

The landing page uses a user-initiated link (click) so Firefox's Local Network
Access does not block it (auto-redirects from public pages to local-network
addresses are blocked; a click is always allowed).
MD

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

REPO="https://user:${HF_TOKEN}@huggingface.co/spaces/${HF_USER}/${SPACE}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP" build/redirect' EXIT

echo ">> cloning + pushing redirect to ${HF_USER}/${SPACE}"
git clone "$REPO" "$TMP/space" 2>/dev/null || { echo "   ✗ clone failed"; exit 1; }
rsync -a "$OUT/" "$TMP/space/"
cd "$TMP/space"
git add -A
git -c user.name="awaaz-deploy" -c user.email="deploy@awaaz.local" commit -m "deploy: redirect → ${TARGET}" || true
git push origin HEAD:main 2>push.err || { git pull --rebase origin main; git push origin HEAD:main; }

echo ""
echo "✅ https://huggingface.co/spaces/${HF_USER}/${SPACE} now redirects to ${TARGET}"
