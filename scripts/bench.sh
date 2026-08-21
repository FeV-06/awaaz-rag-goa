#!/usr/bin/env bash
# Awaaz benchmark suite: latency → speed (P50/P70/P100 across langs) → cold-start.
# Results land in benchmark/results/.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
export PYTHONPATH=

echo "== run_latency_bench =="
.venv/bin/python benchmark/run_latency_bench.py
echo "== run_speed_bench_50 =="
.venv/bin/python benchmark/run_speed_bench_50.py
echo "== run_cold_start_bench =="
.venv/bin/python benchmark/run_cold_start_bench.py
echo "== quick_eval =="
.venv/bin/python benchmark/quick_eval.py || true
echo "=== results ==="
ls -la benchmark/results/
