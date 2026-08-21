# Hacker House Goa 2026 — Task 2: Requirements Compliance Matrix

Every requirement from the shortlisting Task 2 (see [`task 2_ hhg.md`](task%202_%20hhg.md)) mapped against the **Awaaz** implementation.

| # | Requirement | Awaaz implementation | Status |
| :-: | :--- | :--- | :-: |
| 1 | **Speech-to-text** — Sarvam or ElevenLabs | **Sarvam Saaras v3** (`saaras:v3`) via `stt/sarvam_client.py` (16 kHz normalization, retries, timeout), plus text bypass for deterministic eval | ✅ |
| 2 | **Vast chunking** — no naive fixed-size | **4 strategies**: passage-native, sentence-window (±1 sentence, ≥15% overlap), semantic cosine-spike, metadata-aware; fused by **RRF k=60** + script-aware BM25 | ✅ |
| 3 | **Latency < 200 ms** end-to-end | Extractive default path (no network): ONNX INT8 embedder + HNSW + non-LLM generation. See `benchmark/results/` for P50/P70/P100 | ✅ |
| 4 | **Latency analytics** — P50/P70/P100 across a suite | Committed distributions from `benchmark/run_latency_bench.py` / `run_speed_bench_50.py` / `run_cold_start_bench.py` over en+hi+mr query sets | ✅ |
| 5 | **Harnessed model** — orchestration, retries, structured I/O, error recovery | Hand-rolled async orchestrator (`pipeline/orchestrator.py`), Pydantic v2 schemas on every stage boundary, STT/LLM retry + cascade, deadline timeout → HTTP 504, warm-up + self-healing index rebuild | ✅ |
| 6 | **Guardrails** — off-topic, unsafe, hallucination, know-when-not-to-answer | 4-tier pre-retrieval (regex → Meta Prompt-Guard 86M → intent taxonomy → centroid off-topic), context-chunk IPI scan, post-generation grounding gate (≥30% lexical+semantic overlap), declined responses with reason codes | ✅ |
| 7 | **Dataset** — AI4Bharat MSMARCO-XI | `data/build_corpus.py` streams MSMARCO-XI parquets → ~98.8k deduplicated passages per active language (en/hi/mr) + own Wikipedia long-doc augmentation | ✅ |
| — | **Submission**: repo + live link + 2 videos + `#RAGInGoa` promotion | Live HF Space; demo video & process video recorded from this build | ✅ |

## Active runtime vs. full extensibility

- Active: **`en`, `hi`, `mr`** — ~296,000 in-memory vectors (98.8k passages × 3 langs) + long-doc chunks.
- The full 15-language registry (`as, bn, en, gu, hi, kn, ml, mr, ne, or, pa, sa, ta, te, ur`) is available in `config.SUPPORTED_LANGUAGE_REGISTRY`; adding a language = add one entry to `config.LANGUAGES` and re-run the index build.
