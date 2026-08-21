---
title: Awaaz — Voice-Enabled Indic RAG
emoji: 🗣️
colorFrom: indigo
colorTo: pink
sdk: docker
app_port: 7860
pinned: false
license: mit
short_description: Voice-enabled multilingual Indic RAG (en/hi/mr) with sub-200ms retrieval.
---

# आवाज़ AWAAZ — Voice-Enabled Multilingual Indic RAG

**Hacker House Goa 2026 · Task 2** — a voice-enabled Retrieval-Augmented Generation system for **English, हिंदी and मराठी**, targeting **sub‑200 ms** end-to-end latency with a strict "know when *not* to answer" guardrail posture.

> Voice → Sarvam Saaras v3 STT → multi-strategy chunking & FAISS HNSW retrieval → cascaded guardrails → grounded generation (deterministic extractive fast-path, optional local-LLM synthesis).

Built from scratch — **no LangChain, no LlamaIndex**. Every stage is explicit, instrumented, and explainable.

---

## Why it hits &lt;200 ms

| Strategy | Detail |
| :--- | :--- |
| Embeddings | `intfloat/multilingual-e5-small` exported to **ONNX** (external-weight graph), fast CPU runtime with warmup |
| Retrieval | FAISS **HNSW** (`M=32, efC=200, efS=64`), cosine on normalized vectors |
| Merging | Reciprocal Rank Fusion (`k=60`) across 4 chunking strategies + script-aware BM25 |
| Eval-free fast path | Embedding alone ≈ **6.3 ms**; graph traversal ≈ **0.7 ms** (p95) |
| Caching | Semantic gold-answer cache (sim ≥ 0.93) + dynamic vector LRU (2048) |
| Generation | Default = **deterministic extractive** TextRank+SVD synthesis (sub-ms, no network); optional local **Ollama** GGUF synthesis when enabled |

## One-liner architecture

```
Sarvam STT  →  language router  →  guardrails (regex + Prompt-Guard + intent + centroid)
                                      │
              text/audio ─────────────┤
                                      ▼
        multilingual-e5 ONNX  →  FAISS HNSW  →  RRF + BM25 rescore  →  context IPI scan
                                      ▼
        extractive TextRank+SVD  /  Ollama LLM  →  grounding gate (≥30% overlap) → JSON telemetry
```

Every request returns **full stage timing + guardrail audit** so the pipeline is observable end-to-end.

## Corpus

- Source: **AI4Bharat MSMARCO-XI** (MS MARCO translated to Indic languages).
- Active languages: `en`, `hi`, `mr` — **~98.8k deduplicated passages each (~296k total)**.
- Long-document augmentation (my own): 25 Wikipedia source documents on retrieval/RAG/NLP topics, chunked by sentence-window and semantic strategies.
- Extensible to all **15 languages** in the registry by editing one list: `config.LANGUAGES`.

## Guardrails

4-tier pre-retrieval safety (regex blocklist → **Meta Prompt-Guard 86M** ONNX DPI/IPI classification → query-intent taxonomy → corpus-centroid off-topic gate), a **context-chunk indirect-prompt-injection scan**, and a **post-generation grounding gate** — declining instead of hallucinating.

## Quickstart (local)

```bash
python -m venv .venv && .venv/bin/pip install -r requirements.txt
# build corpora (downloads ~7.5 GB of parquets once)
.venv/bin/python data/build_corpus.py --langs en hi mr --max-queries 10000
# GPU index build (needs CUDA; falls back to CPU)
.venv/bin/python retrieval/build_indexes_gpu.py
# run the API
.venv/bin/uvicorn api.main:app --host 0.0.0.0 --port 7860
```

Optional local LLM synthesis (privacy-first, via Ollama):

```bash
AWAZ_ENABLE_LLM=true LLM_BASE_URL=http://localhost:11434/v1 LLM_MODEL=gemma4:e4b \
  .venv/bin/uvicorn api.main:app --port 7860
```

## API

| Endpoint | Purpose |
| :--- | :--- |
| `GET /health` | readiness, active languages, index vector counts |
| `GET /languages` | active-language metadata from `config.LANGUAGES` |
| `POST /query` | text (`text`) or audio (`file`) → `QueryResponse` (JSON telemetry) |
| `POST /tts` | Sarvam Bulbul v2 speech synthesis |
| `GET /` | the AWAAZ web UI |

See [`docs/API_REFERENCE.md`](docs/API_REFERENCE.md) and [`docs/TASK_REQUIREMENTS.md`](docs/TASK_REQUIREMENTS.md).

## Benchmark results (measured on Arch Linux · 6c/12t · Ryzen-class 4.0GHz · 31GB RAM · CPU-only)

Commits under `benchmark/results/`. All runs use the shipped configuration (ONNX-CPU runtime, cross-encoder ON, cache enabled unless stated).

### End-to-end latency (99 queries, en+hi+mr, `benchmark/run_latency_bench.py`)

| Quantile | ms |
| :--- | ---: |
| P50 | **141.2** |
| P70 | **184.7** |
| P90 | 212.3 |
| P99 | 288.1 |
| Mean | 129.9 |

Cached repeat queries resolve in **< 1 ms** (semantic answer cache + dynamic LRU).

### Throughput suite (150 queries = 50 × 3 languages, `benchmark/run_speed_bench_50.py`)

| Metric | Value |
| :--- | :--- |
| Total latency P50 / P70 / P90 | **189.0 / 205.2 / 231.3 ms** |
| Retrieval-only (embed+FAISS+rerank) P50 | ~105 ms |
| End-to-end QPS | ~5.5 (single worker, CPU) |

### Cold-start SLA (15 cache-bypassed cases, `benchmark/run_cold_start_bench.py`)

**SLA (≤200 ms) pass rate: 93.3%** · mean 183.4 ms · P50 177.3 ms · P90 191.0 ms

> Honest reading: on pure-CPU ONNX inference the *first-ever* uncached query runs ~140–200 ms (median), with a long tail to ~280 ms on the coldest paths (Prompt-Guard + cross-encoder + synthesis all cold). Repeat queries are sub-millisecond. On a GPU box (or with the optional Ollama tier on GPU) everything below the generation stage drops further.
