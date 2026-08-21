#!/usr/bin/env bash
# Awaaz API server launcher (default port 7860).
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
export PYTHONPATH=
exec .venv/bin/uvicorn api.main:app --host "${HOST:-0.0.0.0}" --port "${PORT:-7860}" "$@"
