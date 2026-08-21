#!/usr/bin/env bash
# Awaaz dev runner.
#
# Clears the ambient PYTHONPATH if one is set (e.g. an agent/desktop-shell venv
# that would otherwise shadow this project's .venv), then execs the project
# interpreter with whatever args follow.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
export PYTHONPATH=
exec .venv/bin/python "$@"
