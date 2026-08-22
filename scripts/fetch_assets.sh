#!/usr/bin/env bash
# Download prebuilt Awaaz assets (indexes + ONNX models) from the GitHub
# release. Run once after cloning — no GPU / no model downloads needed.
set -euo pipefail

REPO="FeV-06/awaaz-rag-goa"
TAG="assets-v1"
BASE="https://github.com/${REPO}/releases/download/${TAG}"
DEST="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$DEST"

mkdir -p data/indexes data/onnx_models

for f in awaaz-indexes.tar.gz awaaz-onnx.tar.gz; do
  if [ -f "/tmp/$f" ]; then
    echo ">> using cached /tmp/$f"
    cp "/tmp/$f" .
  else
    echo ">> downloading ${BASE}/${f} …"
    curl -fL --retry 3 -o "$f" "${BASE}/${f}"
  fi
done

echo ">> extracting …"
tar -xzf awaaz-indexes.tar.gz -C data
tar -xzf awaaz-onnx.tar.gz -C data
rm -f awaaz-indexes.tar.gz awaaz-onnx.tar.gz

echo "✅ assets ready:"
ls -la data/indexes/ | tail -5
ls -la data/onnx_models/ | tail -5
