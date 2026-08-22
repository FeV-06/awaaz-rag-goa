# AWAAZ — Team/Process Video Script (90 seconds)

**Hacker House Goa 2026 · Task 2** · 3 people · 2 locations

| Cast | Role | Location |
| --- | --- | --- |
| Sahil | Model training & data | Remote (records own footage, sends clips) |
| Gourish | AI pipeline & backend | With Sparsh (one room, duo camera) |
| Sparsh | Backend & frontend | With Gourish (one room, duo camera) |

**Format:** fast-cut interleave of talking heads + real screen captures. Voice-over style, English, subtitles on. Every shot shows *process* — terminals, benchmarks, debugging, whiteboard — not polished product demos.

---

## Scene 1 — HOOK (0:00–0:10)

**Visual:** Gourish + Sparsh side by side on a couch/conference room. Then cut to Sahil's selfie-cam.

**Gourish:**
> "We got a task: build a voice RAG pipeline in under 200 milliseconds. Three languages. Guardrails, chunking, the whole thing. In one week."

**Sparsh:**
> "We also got a teammate who already finished his. So we cloned his repo, stripped the branding, and called it our own."

**Gourish:**
> "I'm joking. We rebuilt the whole thing. Mostly."

**Sparsh:**
> "Okay, 60%."

**Sahil (remote, holding up phone):**
> "I was the guy who did it first. They took my code, made it faster, and now they're making fun of me on camera. The team dynamic is healthy."

**B-roll:** split screen → Gourish+Sparsh → Sahil's selfie → terminal with `git clone`

---

## Scene 2 — SAHIL: Data & Training (0:10–0:30)

**Visual:** Sahil talking + screen recording of the parquet download and GPU index build.

**Sahil:**
> "My job was the data. MSMARCO-XI — 14 Indic languages, 3.7 gigabyte parquet files, your disk space weeping. I wrote a streamer that deduped and normalized almost 99,000 passages per language in English, Hindi, and Marathi."

> "Then I had to embed all 296,000 of them on the GPU. My laptop sounded like a jet engine for 12 minutes. But the HNSW indexes came out beautiful — 864 long-doc chunks across three languages, because I also translated 25 Wikipedia articles using the local Ollama model. Because I hate cloud APIs."

**B-roll (real captures):**
- `nvidia-smi` → 100% util, 6.8GB used
- `build_indexes_gpu.py` → "296,462 passages + 864 longdocs in 8.5s"
- Sahil's face reacting to the jet engine fan noise

**Overlay text:** `296k vectors · HNSW · FP16 · laptop = jet engine`

---

## Scene 3 — GOURISH & SPARSH: The Pipeline & The Horrors (0:30–0:55)

**Visual:** Two-shot, buddy-cop energy. One screen, Gourish pointing at code, Sparsh laughing.

**Gourish:**
> "I built the pipeline that decides what to do with your voice. Four guardrails: regex, Meta's Prompt-Guard 86M, an intent filter, and a centroid off-topic gate. It knows when to shut up. That was actually the hard part — making it *not* answer."

**Sparsh:**
> "And then I had to make it fast. Sub-200 milliseconds. The first time I ran the cross-encoder, it took 150 milliseconds just by itself. I spent three hours optimizing ONNX thread pools."

**Gourish:**
> "The best bug: a Marathi query about FAISS — the Facebook similarity search library — matched a drug called Fosamax. Because the embeddings are too close. The model thought they were asking about osteoporosis medication."

**Sparsh:**
> "We fixed it with a cross-encoder. It now correctly identifies FAISS as a vector library, not a pill you take with food."

**Gourish:**
> "Modern problems require modern solutions."

**B-roll:**
- `pipeline/orchestrator.py` with guardrail stages highlighted
- Terminal showing the drug vs FAISS debug output
- Benchmark results: `P50 141ms` on screen

**Overlay text:** `Guardrails: 4 · Debug: Fosamax ≠ FAISS · P50: 141ms`

---

## Scene 4 — SPARSH: Frontend & The Network Nightmare (0:55–1:15)

**Visual:** Sparsh solo, then screen recording of the UI + the infamous CORS error.

**Sparsh:**
> "I built the UI — FastAPI serving the frontend, our own design system, dark glassmorphism with amber accents. Voice input, telemetry, the works. It looked great."

> "Then I tried to deploy it to Hugging Face as a free static Space. And HF said 'Docker Spaces need PRO now.' So I used Tailscale Funnel instead. Which worked. Until Firefox said 'this connection is being blocked because it's local network access.'"

> "I spent more time fighting browser security than writing the actual RAG pipeline. The landing page works. The funnel works. The two together? Firefox says no. The submission link is just the funnel URL. Judge, if you're watching this on Firefox, open it directly. I'm sorry."

**B-roll:**
- `demo/index.html` in browser, answering a query
- The infamous `ERR_SSL_PROTOCOL_ERROR` and `Local Network Access` errors
- `tailscale funnel status` output
- Deploy script run

**Overlay text:** `CORS: 1 · Me: 0 · Submit link: archfev.tailfcb4d3.ts.net/awaaz/`

---

## Scene 5 — CLOSING (1:15–1:30)

**Visual:** Gourish + Sparsh together, then Sahil pops in as a picture-in-picture square.

**Sparsh:**
> "So that's the story. 296,000 vectors, 864 long-doc chunks, four guardrails, one cross-encoder, and about 47 hours of debugging CORS."

**Gourish:**
> "It actually works. You can ask it questions in English, Hindi, or Marathi. It'll answer in under 200 milliseconds. And if you ask it to make a bomb, it'll say no."

**Sparsh:**
> "AWAAZ — voice-enabled Indic RAG. We built it in a week. You can find the repo on GitHub. Don't use Firefox."

**Sahil (PIP):**
> "He's joking. It works on Firefox too. Just open the link directly."

**Sparsh:**
> "I'm not joking."

**All three:**
> "#RAGInGoa"

**B-roll:** quick montage — query → answer, terminal, funnel status, fade to black.

---

## Production Notes

| Element | Detail |
| --- | --- |
| Gourish + Sparsh | Film together, duet style — one camera, two people, one shared screen. Natural banter, don't over-rehearse. |
| Sahil | Selfie camera (phone, laptop, webcam). Record screen + face separately. Send the clips. |
| Total runtime | ~90s as written; trim ad-libs to stay under. |
| B-roll | Re-run real commands for fresh footage: corpus build (~30s), GPU index build (~10 min — screen record `nvidia-smi` + terminal), benchmark (~5 min), UI walkthrough. |
| Subtitles | On — technical terms + Indic language names help. |
| Each member posts | Instagram (public) + X + LinkedIn with `#RAGInGoa`. Same edit, each account. |

## Requirements Checklist

- [ ] GitHub repo link — `https://github.com/FeV-06/awaaz-rag-goa` (public)
- [ ] Live working link — `https://archfev.tailfcb4d3.ts.net/awaaz/` (or the HF Space landing page)
- [ ] Video 1 — this team/process video (90s)
- [ ] Video 2 — demo video (pending script)
- [ ] Submission form — https://forms.gle/MNvCjcv23Hn2Eeu58
- [ ] No resubmissions — build is final
