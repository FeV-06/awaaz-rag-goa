# Awaaz — Voice-Enabled Indic RAG (Hacker House Goa 2026 Task 2)
# Multi-stage: builder bakes ONNX/Prompt-Guard model artifacts, runtime is lean and fast-booting.

FROM python:3.11-slim AS builder

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    HF_HOME=/build/.cache/huggingface

WORKDIR /build

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential curl ffmpeg libsndfile1 \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --upgrade pip && pip install -r requirements.txt

# Source (indexes + processed corpus come from the build context)
COPY config.py .
COPY api/ api/
COPY stt/ stt/
COPY retrieval/ retrieval/
COPY guardrails/ guardrails/
COPY chunking/ chunking/
COPY generation/ generation/
COPY pipeline/ pipeline/
COPY data/processed/ data/processed/

# Bake model artifacts now so first boot is instant:
#   - export multilingual-e5-small to ONNX
#   - download Meta Prompt-Guard-86M ONNX weights and quantize to INT8
# (Indexes are NOT baked here: data/indexes is gitignored for GitHub's size
# limit; the FastAPI lifespan self-heals by rebuilding from corpus JSONL if
# indexes are missing — or they are pushed to the HF Space directly.)
RUN python - <<'PY'
import config
from retrieval.embed import get_embedder
e = get_embedder()
print("ONNX embedder baked:", type(e).__name__)
from guardrails.prompt_guard import get_prompt_guard_detector
d = get_prompt_guard_detector()
print("Prompt-Guard engine baked:", d.engine_type)
from pathlib import Path
import onnxruntime
from onnxruntime.quantization import quantize_dynamic, QuantType
fp32 = config.ONNX_MODELS_DIR / "prompt_guard_86m.onnx"
q8 = config.ONNX_MODELS_DIR / "prompt_guard_86m_int8.onnx"
if fp32.exists() and not q8.exists():
    quantize_dynamic(str(fp32), str(q8), weight_type=QuantType.QInt8)
    print("Prompt-Guard INT8 baked:", q8.stat().st_size)
PY

# ---------------- runtime ----------------
FROM python:3.11-slim AS runtime

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PORT=7860 \
    HOST=0.0.0.0 \
    DATA_DIR=/app/data \
    HF_HOME=/app/.cache/huggingface

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg libsndfile1 curl \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -m -u 1000 user

# Fully baked python environment from builder
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Application source, indexes, processed corpus from build context
COPY . /app

# Baked ONNX / Prompt-Guard artifacts from builder
COPY --from=builder /build/data/onnx_models /app/data/onnx_models

RUN chown -R user:user /app
USER user

EXPOSE 7860

CMD ["uvicorn", "api.main:app", "--host", "0.0.0.0", "--port", "7860"]
