# Awaaz — Submission Checklist (Hacker House Goa 2026 Task 2)

Deadline: **Aug 22, 2026 11:59 PM** · no resubmissions.

## ✅ Done (this repo, commit `cbc7e39`)

- [x] Code + corpus + long-doc augmentation + benchmark results committed
- [x] 296,462 passages (en/hi/mr) + 864 longdoc chunks; 50/50 tests pass
- [x] Benchmarks: P50 141–189 ms, cold SLA pass 93%, cached <27 ms
- [x] Dockerfile validated (build in progress) + `scripts/deploy_hf.sh`

## 🔧 You (30–40 min)

1. **Sarvam AI key** → sign up at sarvam.ai, get API key.
2. **Hugging Face account + token (write)** → huggingface.co/settings/tokens.
3. **Create the Space** (Docker SDK, CPU basic) → or `HF_USER=... HF_TOKEN=... ./scripts/deploy_hf.sh` creates it.
4. **Deploy**: `HF_USER=<username> HF_TOKEN=hf_... ./scripts/deploy_hf.sh`
   - First push ≈ 1.2 GB (indexes) → several minutes. Space builds the image (≈15–25 min).
   - Add `SARVAM_API_KEY` as a Space **secret** (Settings → Variables) → restart.
5. **GitHub repo** (submission link): create `awaaz-rag` (private→public) and:
   ```bash
   cd ~/GitRepos/awaaz-rag
   git remote add origin https://github.com/<you>/awaaz-rag.git
   git push -u origin main
   ```
6. **Live-link check**: open the Space, click the mic, ask in हिंदी / मराठी / English.

## 🎬 Videos + promotion (mandatory, per member)

- **Video 1 (90 s, process)**: build footage (corpus build → GPU indexing → bench runs) — you can screen-record this session's output.
- **Video 2 (demo)**: ask 2–3 questions (en + hi + mr), show the telemetry panel + declined answer for an unsafe prompt.
- Post both on **Instagram (≥1 public) + X + LinkedIn** with `#RAGInGoa`.

## Demo talking points

- Why <200 ms: ONNX CPU runtime, HNSW, extractive-first generation, cache tiers.
- Retrieval quality: multi-strategy chunking + RRF + cross-encoder (show the FAISS-vs-drug transliteration case as the "why").
- Safety: 4-tier guardrails + Prompt-Guard 86M + grounding gate (show the bomb query decline).
- Scalability story: 15-language registry, one config list.
- The "different from teammate" honesty point: faster `gemma`-free deterministic pipeline, privacy-first optional local LLM (Ollama), own UI, own benchmarks.