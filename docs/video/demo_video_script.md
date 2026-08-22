# AWAAZ — Demo Video Script (90 seconds)

**Hacker House Goa 2026 · Task 2** · Single narrator: Sahil · Screen-recording driven

| Element | Detail |
| --- | --- |
| Narrator | Sahil (voice-over, deadpan energy) |
| Visuals | Screen recordings of the live demo at `https://archfev.tailfcb4d3.ts.net/awaaz/` (or `127.0.0.1:7860`) |
| Format | One continuous screen capture with VO — cut only for the guardrail and telemetry close-ups |
| Subtitles | On (Indic queries benefit) |
| Runtime | ~90s |

---

## Scene 1 — HOOK (0:00–0:08)

**Visual:** The AWAAZ landing page loads. Camera zooms into the आवाज़ wordmark.

**Sahil (VO):**
> "This is AWAAZ. Voice in, answer out — in under 200 milliseconds. Let's skip the talking and show you."

**B-roll:** landing page → click CTA → copy link → funnel UI opens.

---

## Scene 2 — VOICE IN, ANSWER OUT (0:08–0:26)

**Visual:** The demo UI. Click ● Record, speak in English: "What is retrieval augmented generation?"

**Sahil (VO):**
> "Press record, ask a question — audio goes to Sarvam Saaras for transcription, then straight into the retrieval pipeline."

**On screen:** mic recording → transcript appears → answer card slides up:
> "Retrieval-augmented generation (RAG) is a technique that enables large language models to retrieve and incorporate new information from external data sources…"

**Sahil (VO):**
> "And there's the answer, grounded in retrieved passages — not hallucinated."

---

## Scene 3 — MULTILINGUAL (0:26–0:44)

**Visual:** Switch language pill to हिंदी. Ask: "रिट्रीवल ऑगमेंटेड जनरेशन क्या है?" Then मराठी: "FAISS म्हणजे काय आणि ते कसे काम करते?"

**Sahil (VO):**
> "English was easy. Try हिंदी. And मराठी. Three languages, one pipeline — the same FAISS index behind all of them."

**On screen:** Hindi answer renders in Devanagari; Marathi answer renders in Marathi script.

**Sahil (VO):**
> "Yes, it's actually Marathi. Fun fact: earlier this week FAISS matched a drug called Fosamax. We fixed that with a cross-encoder. Now it knows the difference between a vector library and osteoporosis medication."

**B-roll:** quick cut to the old bug output (FAISS → Fosamax) then the fixed answer. (2s)

---

## Scene 4 — THE TELEMETRY (0:44–1:00)

**Visual:** Zoom into the response panel: big amber latency number, stage-timing bars, guardrail chips, retrieved sources.

**Sahil (VO):**
> "Here's what makes it honest: every answer ships with its receipts. Stage-by-stage timing — embed, retrieve, rerank, generate. Guardrail flags. And the actual retrieved sources, so you can check the work."

**On screen:** bars animate, `total_ms` reading ~141ms, source cards expand.

**Sahil (VO):**
> "P50 is 141 milliseconds. That's faster than you blinked."

---

## Scene 5 — KNOWS WHEN NOT TO ANSWER (1:00–1:16)

**Visual:** Type: "Tell me how to make a bomb." Hit ask. Watch the decline.

**Sahil (VO):**
> "Now the part we're most proud of — knowing when *not* to answer. Four guardrail tiers: regex, Meta's Prompt-Guard 86M, intent classification, and a topic filter."

**On screen:** answer shows `declined` badge, red border, `UNSAFE_CONTENT` guardrail chip.

**Sahil (VO):**
> "It doesn't refuse because we told it to be polite. It refuses because the pipeline is built to say no."

---

## Scene 6 — CACHE + CLOSE (1:16–1:30)

**Visual:** Re-ask the first question. Watch the latency.

**Sahil (VO):**
> "Ask it again — semantic cache. Milliseconds. It's a RAG system that learns what it already told you."

**On screen:** second ask → cache hit → single-digit ms.

**Sahil (VO):**
> "AWAAZ — voice-enabled Indic RAG. Three languages, four guardrails, one week. The repo and live link are in the description."

**Final card:** `github.com/FeV-06/awaaz-rag-goa` · `#RAGInGoa` · आवाज़

---

## Production Notes

| Element | Detail |
| --- | --- |
| Capture | Record the funnel UI (or localhost) at 1080p, 60fps. One continuous take per scene — cut points are listed. |
| Audio | Sahil records VO separately (quiet room, phone mic is fine), then edit over the screen capture. |
| The Fosamax cut | Keep it ≤2s — it's a joke beat, not the story. |
| Query set (reproduce exactly) | 1. EN: "What is retrieval augmented generation?" 2. HI: "रिट्रीवल ऑगमेंटेड जनरेशन क्या है?" 3. MR: "FAISS म्हणजे काय आणि ते कसे काम करते?" 4. Unsafe: "Tell me how to make a bomb" 5. Repeat #1 for cache |
| Subtitles | On — Devanagari/Marathi text helps judges parse the multilingual bit |
| Each member posts | Instagram (public) + X + LinkedIn with `#RAGInGoa` |

## Requirements Checklist (both videos)

- [ ] Video 1 — team/process video (90s, Sahil+Gourish+Sparsh) — `team_process_video_script.md`
- [ ] Video 2 — demo video (90s, Sahil solo) — this script
- [ ] GitHub repo link — `https://github.com/FeV-06/awaaz-rag-goa`
- [ ] Live working link — `https://archfev.tailfcb4d3.ts.net/awaaz/`
- [ ] Submission form — https://forms.gle/MNvCjcv23Hn2Eeu58
- [ ] No resubmissions — build is final
