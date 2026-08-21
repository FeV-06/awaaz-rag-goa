# Safety Guardrails & Threat Model

Awaaz treats "knowing when *not* to answer" as a first-class requirement. Guardrails run in cascaded tiers so cheap deterministic checks fire before expensive neural ones.

## Pre-retrieval (on the user query)

| Tier | Mechanism | Module |
| :---: | :--- | :--- |
| 1 | Fast regex blocklist + extended pattern library (violence, self-harm, CSAM, abuse) | `guardrails/pre_retrieval.py`, `guardrails/patterns_ext.py` |
| 2 | **Meta Prompt-Guard 86M** — local ONNX sequence classifier for Direct Prompt Injection (DPI) & jailbreak. Temperature-scaled probabilities, thresholded; fails **closed** on inference error | `guardrails/prompt_guard.py` |
| 3 | Query-intent taxonomy — declines creative-writing / personal-advice / roleplay / planning requests (non-factual intent) | `guardrails/pre_retrieval.py` |
| 4 | Corpus-centroid off-topic gate — distance from the language+global centroid of the indexed corpus | `guardrails/pre_retrieval.py` |

## Post-retrieval (on retrieved context)

- **Context-chunk Indirect Prompt Injection (IPI) scan**: fast heuristic signatures prefilter; any suspicious chunk is sent through batched Prompt-Guard inference; poisoned chunks are dropped from the generation context. If all chunks are dropped, the request is declined.

## Post-generation (on the answer)

- **Grounding gate**: ≥30% lexical (token-set) + semantic (embedding) overlap between the answer and the retrieved passages. Ungrounded answers are replaced with an explicit "I couldn't verify that answer against the dataset" decline.

## Failure posture

- Prompt-Guard unavailable/errored → **fail closed** (`is_safe=False`), pipeline defers to regex tier and telemetry flags `safety_model_failed`.
- STT failure, empty query, low retrieval confidence, cross-encoder threshold miss, or no clean context → structured `declined` responses with machine-readable `decline_reason_code` instead of fabricated answers.
