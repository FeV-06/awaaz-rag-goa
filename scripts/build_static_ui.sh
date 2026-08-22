#!/usr/bin/env bash
# Build the static UI bundle for a free HF Static Space.
#
# Usage:  ./scripts/build_static_ui.sh <api-base-url> [out-dir]
#   <api-base-url>  e.g. https://archfev.tailfcb4d3.ts.net:8443  (no trailing slash)
#   [out-dir]       default: build/static
set -euo pipefail

API_BASE="${1:?usage: build_static_ui.sh <api-base-url> [out-dir]}"
OUT="${2:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/build/static}"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/demo/index.html"

mkdir -p "$OUT"

# inject window.AWAAZ_API_BASE before the main script, so the UI calls the
# funnel backend instead of same-origin /query
sed "s|<script>|<script>window.AWAAZ_API_BASE = \"${API_BASE}\";</script>\n<script>|" "$SRC" > "$OUT/index.html"

# minimal HF static-space metadata (kept tiny; index.html is the app)
# NOTE: colorFrom/colorTo must be from HF's allowed set:
# [red, yellow, green, blue, indigo, purple, pink, gray]
cat > "$OUT/README.md" <<MD
---
title: Awaaz — Voice-Enabled Indic RAG
emoji: 🗣️
colorFrom: gray
colorTo: yellow
sdk: static
pinned: false
---
UI for AWAAZ (Voice-Enabled Indic RAG). API calls go to \`${API_BASE}\`.
MD

echo "✅ static UI built → $OUT (API base: ${API_BASE})"
