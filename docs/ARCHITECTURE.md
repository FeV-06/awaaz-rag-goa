# Architecture — Awaaz Voice RAG

```
                 ┌─────────────────────────────────────────────────────────────┐
                 │                       client (web UI / API)                  │
                 └───────────────┬───────────────────────────┬─────────────────┘
                                 │ audio (webm/wav)          │ text
                                 ▼                           ▼
                        ┌─ Sarvam Saaras v3 STT ──┐   ┌──────────────┐
                        │ 16kHz normalize, retry  │   │ text bypass  │
                        └────────────┬────────────┘   └──────┬───────┘
                                     ▼                        │
                        ┌──────────────────────────────┐      │
                        │  language routing (config.   │◄─────┘
                        │  LANGUAGES single source)    │
                        └────────────┬─────────────────┘
                                     ▼
        ┌───────────────────  PRE-RETRIEVAL GUARDRAILS  ───────────────────┐
        │ 1. Regex tier-1 safety                  4. Centroid off-topic    │
        │ 2. Meta Prompt-Guard 86M (ONNX)            distance filter       │
        │ 3. Query-intent taxonomy                (per-lang + global)      │
        └────────────────────────────┬─────────────────────────────────────┘
                                     ▼
                     embed: multilingual-e5-small ONNX INT8 (query: prefix)
                                     ▼
              ┌──────────────── FAISS HNSW  ────────────────┐
              │ passage_native (~296k)   semantic_longdoc   │
              └────────────────────┬────────────────────────┘
                                   ▼  RRF k=60 fuses strategies
                       script-aware BM25 + optional cross-encoder rescore
                                   ▼
                        context-chunk IPI scan (batched ONNX)
                                   ▼
                 ┌──────────── GENERATION ────────────┐
                 │ extractive (TextRank+SVD, no net)  │
                 │  OR  Ollama GGUF synthesis (opt-in)│
                 └────────────────⎸────────────────────┘
                                   ▼
                       post-generation grounding gate (≥30%)
                                   ▼
                 grounded JSON response + full stage telemetry
```

## Key modules

| Path | Responsibility |
| :--- | :--- |
| `api/main.py` | FastAPI serving layer: `/query`, `/tts`, `/health`, `/languages`, web UI |
| `pipeline/orchestrator.py` | Async stage-graph orchestrator with per-stage `StageTiming` |
| `pipeline/schemas.py` | Pydantic v2 request/response contracts |
| `retrieval/embed.py` | ONNX INT8 e5 embedder (PyTorch fallback) |
| `retrieval/index_faiss.py` | FAISS HNSW index manager, centroids, auto-rebuild |
| `retrieval/build_indexes_gpu.py` | CUDA FP16 batch index builder |
| `chunking/` | passage-native / sentence-window / semantic / metadata strategies + RRF merge |
| `guardrails/` | pre_retrieval, prompt_guard (Prompt-Guard 86M), post_generation, fail_safe |
| `generation/` | extractive TextRank+SVD, answer cache, LLM (Ollama) adapter, local SLM |
| `stt/` | Sarvam Saaras v3 transcribe, Sarvam Bulbul v2 TTS |
| `data/` | corpus builder (`build_corpus.py`), long-doc fetch, benchmark query exporter |

## Design principles

1. **Latency budget first.** The 200 ms target shapes every decision: ONNX over PyTorch, HNSW over flat, batched guard inference over per-chunk, extractive-first generation, cache tiers.
2. **Explainable by default.** Every response carries stage timings and guardrail flags — a judge (or a logline) can see *why* an answer was declined.
3. **Single configuration source.** `config.LANGUAGES` drives routing, indexing, and extension.
4. **Fail closed.** If a safety model is unavailable, the pipeline declines rather than answering unguarded.
