"""
Awaaz long-document translation (English -> Hindi, Marathi).

Uses the local Ollama GPU endpoint (gemma4) to translate the curated
Wikipedia long-documents into Hindi and Marathi, so Indic queries retrieve
in-language evidence and generate in-language answers. No external API keys.

Output: data/processed/{hi,mr}_longdocs.jsonl (schema: text, doc_id, title, source_lang)
"""
from __future__ import annotations

import argparse
import json
import logging
import os
import time
from pathlib import Path

import requests

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "data" / "raw" / "longdocs_en.jsonl"
OLLAMA_BASE = os.getenv("OLLAMA_BASE", "http://localhost:11434")
MODEL = os.getenv("OLLAMA_MODEL", "gemma4:e4b")

PROMPT = """You are a careful technical translator. Translate the encyclopedia article below into natural, fluent {lang}. Keep all technical terms accurate; keep it as prose (no markdown, no commentary, no preamble). Output ONLY the translation.

ARTICLE TITLE: {title}

ARTICLE:
{text}"""


def translate(text: str, title: str, lang: str) -> str:
    payload = {
        "model": MODEL,
        "messages": [
            {"role": "system", "content": "You are a precise technical translator. Output only the translation."},
            {"role": "user", "content": PROMPT.format(lang=lang, title=title, text=text)},
        ],
        "stream": False,
        "options": {"temperature": 0.2, "num_predict": 600},
    }
    r = requests.post(f"{OLLAMA_BASE}/api/chat", json=payload, timeout=300)
    r.raise_for_status()
    out = r.json().get("message", {}).get("content", "").strip()
    # strip accidental code fences
    if out.startswith("```"):
        parts = out.split("\n", 1)
        out = parts[1] if len(parts) > 1 else out
        out = out.rsplit("```", 1)[0].strip()
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--langs", nargs="+", default=["hi", "mr"])
    ap.add_argument("--max-docs", type=int, default=0, help="0 = all")
    args = ap.parse_args()

    docs = []
    with open(SRC, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line:
                docs.append(json.loads(line))

    if args.max_docs:
        docs = docs[: args.max_docs]

    out_dir = ROOT / "data" / "processed"
    out_dir.mkdir(parents=True, exist_ok=True)

    for lang in args.langs:
        out_file = out_dir / f"{lang}_longdocs.jsonl"
        entries = []
        ok = 0
        for i, doc in enumerate(docs, 1):
            translated = translate(doc["text"], doc["title"], "Hindi" if lang == "hi" else "Marathi")
            if not translated or len(translated) < 300:
                logger.warning("short/empty translation for %s skipping (%s) len=%d", doc["title"], lang, len(translated))
                continue
            entries.append({
                "doc_id": f"{lang}_{doc['doc_id']}",
                "title": doc["title"],
                "source_lang": lang,
                "text": translated,
            })
            ok += 1
            if ok % 5 == 0:
                logger.info("%s: %d/%d docs translated", lang, ok, len(docs))
                out_file.write_text("\n".join(json.dumps(e, ensure_ascii=False) for e in entries), encoding="utf-8")  # incremental save

        with open(out_file, "w", encoding="utf-8") as f:
            for e in entries:
                f.write(json.dumps(e, ensure_ascii=False) + "\n")
        logger.info("Wrote %d translated docs (of %d) to %s", len(entries), len(docs), out_file.name)


if __name__ == "__main__":
    main()
